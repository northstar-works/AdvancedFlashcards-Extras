package com.northstarworks.streamvault;

import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.net.ConnectivityManager;
import android.net.wifi.WifiManager;
import android.os.PowerManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.GestureDetector;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.WebView;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.OptIn;
import androidx.documentfile.provider.DocumentFile;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MimeTypes;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.Tracks;
import androidx.media3.common.VideoSize;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.hls.HlsMediaSource;
import androidx.media3.exoplayer.rtsp.RtspMediaSource;
import androidx.media3.exoplayer.source.MediaSource;
import androidx.media3.exoplayer.source.ProgressiveMediaSource;
import androidx.media3.extractor.DefaultExtractorsFactory;
import androidx.media3.extractor.ts.DefaultTsPayloadReaderFactory;
import androidx.media3.ui.PlayerView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Date;
import java.util.Deque;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

@OptIn(markerClass = UnstableApi.class)
public class PlayerActivity extends Activity {

    public static final String EXTRA_URL            = "stream_url";
    public static final String EXTRA_TITLE          = "stream_title";
    public static final String EXTRA_CATEGORY       = "stream_category";
    public static final String EXTRA_FAILOVER_JSON  = "failover_json";
    public static final String EXTRA_NOW_NEXT       = "now_next";
    public static final String EXTRA_FO_TIMEOUT     = "fo_timeout";
    public static final String EXTRA_FO_AUTO        = "fo_auto";
    public static final String EXTRA_SAVE_PATH      = "save_path";
    public static final String EXTRA_ITEM_ID        = "item_id";
    public static final String EXTRA_SEEK_MS        = "seek_ms";

    // ─── State ───────────────────────────────────────────────────────────────
    private static final String TAG = "StreamVaultPlayer";

    private ExoPlayer   player;
    private PlayerView  playerView;
    private View        loadingView, errorContainer;
    private View        overlayTop, overlayCenter, overlayBottom;
    private TextView    titleText, statusText, nowNextText, strengthText,
                        errorText, recStatusText, sourceInfoText, groupInfoText, timeshiftText;
    private SeekBar     timeshiftBar;
    // VOD progress overlay
    private SeekBar     vodSeekBar;
    private TextView    vodElapsed, vodRemaining;
    private TextView    vodMetaText;    // b230
    private TextView    vodTitleText;   // b231
    private android.widget.Button vodWlBtn; // b230
    private android.widget.LinearLayout vodProgressRow;
    private Runnable    progressUpdater;
    private ImageButton playPauseBtn, lockBtn, recordBtn, prevBtn, nextBtn,
                        timeshiftPauseBtn, timeshiftLiveBtn;
    private Handler     handler;
    private Runnable    hideOverlayRunnable, failoverTimeoutRunnable, strengthUpdater, positionReporter;
    private boolean     overlayVisible = false, locked = false, networkAvailable = true;
    private volatile boolean recording  = false;
    private String      lastSuccessUrl  = null, savePath = null;
    private long        playbackStartTime = 0, foTimeoutMs = 15000, recordingStartTime = 0;
    private long        seekOnReadyMs   = 0;    // seek to this position after STATE_READY
    private boolean     userExplicitPause = false; // true only when user pressed pause
    private TextView    seekRew30, seekRew10, seekFwd10, seekFwd30;
    private boolean     timeshiftUserEnabled = true;  // from settings/intent
    private String      itemId          = null; // for Plex progress reporting
    private boolean     foAuto          = true;
    private String      streamCategory  = "";
    private String      streamTitle     = "";
    private ConnectivityManager.NetworkCallback networkCallback;
    private WifiManager.WifiLock wifiLock;
    private Runnable liveKeepAlive;
    private Thread      recordThread;
    private WebView     parentWebView   = null; // set by MainActivity if available

    // Timeshift (live TV pause)
    private volatile boolean timeshiftEnabled  = false;
    private volatile boolean timeshiftPaused   = false;
    private volatile long    timeshiftBufMs    = 0;   // ms of buffer accumulated
    private volatile long    timeshiftPausedAt = 0;
    private volatile long    timeshiftPausedPos = 0;  // player ms position when paused
    private volatile int     timeshiftMaxMin   = 30;  // buffer window from settings
    private volatile long    timeshiftOffset   = 0;   // ms behind live
    private static final long TS_MAX_BUF_MS   = 3600_000L; // 1 hour max
    private Thread      timeshiftThread;

    private final List<Variant> variants = new ArrayList<>();
    private int currentIdx = 0;

    // ─── Data classes ────────────────────────────────────────────────────────
    static class RecordingTarget {
        final OutputStream out;
        final String       displayPath;
        RecordingTarget(OutputStream out, String displayPath) { this.out=out; this.displayPath=displayPath; }
    }

    static class Variant {
        final String url, title, region, tag;
        final long   seekMs;
        Variant(String url, String title, String region, String tag, long seekMs) {
            this.url    = url    != null ? url    : "";
            this.title  = title  != null ? title  : "";
            this.region = region != null ? region : "";
            this.tag    = tag    != null ? tag    : "";
            this.seekMs = seekMs;
        }
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                             WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getWindow().setStatusBarColor(Color.TRANSPARENT);
            getWindow().setNavigationBarColor(Color.BLACK);
        }
        handler = new Handler(Looper.getMainLooper());
        hideOverlayRunnable     = () -> setOverlayVisible(false);
        failoverTimeoutRunnable = () -> {};
        parseIntent();
        if (variants.isEmpty()) { finish(); return; }
        buildUI();
        registerNetworkCallback();
        startStrengthMonitor();
        playVariant(0);
        hideSystemUI();
    }

    // ─── Intent ──────────────────────────────────────────────────────────────
    private void parseIntent() {
        foTimeoutMs = getIntent().getIntExtra(EXTRA_FO_TIMEOUT, 15) * 1000L;
        foAuto      = getIntent().getBooleanExtra(EXTRA_FO_AUTO, true);
        savePath    = getIntent().getStringExtra(EXTRA_SAVE_PATH);
        itemId      = getIntent().getStringExtra(EXTRA_ITEM_ID);
        streamCategory = String.valueOf(getIntent().getStringExtra(EXTRA_CATEGORY) != null ? getIntent().getStringExtra(EXTRA_CATEGORY) : "");
        streamTitle    = String.valueOf(getIntent().getStringExtra(EXTRA_TITLE) != null ? getIntent().getStringExtra(EXTRA_TITLE) : "");
        long globalSeek = getIntent().getLongExtra(EXTRA_SEEK_MS, 0);
        timeshiftUserEnabled = getIntent().getBooleanExtra("ts_enabled", true);
        timeshiftMaxMin      = getIntent().getIntExtra("ts_max_min", 30);

        String json = getIntent().getStringExtra(EXTRA_FAILOVER_JSON);
        if (json != null && !json.isEmpty()) {
            try {
                JSONArray arr = new JSONArray(json);
                for (int i = 0; i < arr.length(); i++) {
                    JSONObject o = arr.getJSONObject(i);
                    long sk = o.has("seekMs") ? o.getLong("seekMs") : (i==0 ? globalSeek : 0);
                    variants.add(new Variant(
                        o.optString("url",""), o.optString("title",""),
                        o.optString("region",""), o.optString("tag",""), sk));
                }
            } catch (Exception ignored) {}
        }
        if (variants.isEmpty()) {
            String url   = getIntent().getStringExtra(EXTRA_URL);
            String title = getIntent().getStringExtra(EXTRA_TITLE);
            if (url != null && !url.isEmpty())
                variants.add(new Variant(url, title!=null?title:"Stream", "", "", globalSeek));
        }
    }

    private String getScheme(String raw) {
        if (raw==null) return "";
        int i=raw.indexOf(':'); return i>0 ? raw.substring(0,i).toLowerCase(Locale.US) : "";
    }
    private boolean isLikelyHls(String raw) {
        if (raw==null) return false;
        String v=raw.toLowerCase(Locale.US);
        return v.contains(".m3u8")||v.contains("m3u_plus")||v.contains("type=m3u")||v.contains("output=m3u8");
    }
    private boolean isIptvItem() {
        // ITV items don't have itemId set (only Plex items do)
        return itemId == null || itemId.isEmpty();
    }

    private boolean isLikelyHdhrTs(String rawUrl) {
        String url = rawUrl != null ? rawUrl.toLowerCase(Locale.US) : "";
        String cat = streamCategory != null ? streamCategory.toLowerCase(Locale.US) : "";
        String ttl = streamTitle != null ? streamTitle.toLowerCase(Locale.US) : "";
        return cat.contains("hdhr")
            || ttl.contains("hdhomerun")
            || url.contains("/auto/v")
            || url.contains("/proxy/v")   // hdhr-xmltv ffmpeg proxy endpoint
            || url.contains("/tuner")
            || url.contains("hdhomerun")
            || url.contains("/lineup.m3u");
    }

    private boolean isHdhrProxyUrl(String rawUrl) {
        // True when the URL is our ffmpeg proxy — outputs H.264/AAC so
        // we still use ProgressiveMediaSource but skip the ?transcode hack.
        String url = rawUrl != null ? rawUrl.toLowerCase(Locale.US) : "";
        return url.contains("/proxy/v");
    }

    private String buildTrackSummary(Tracks tracks) {
        if (tracks == null) return "tracks=null";
        StringBuilder sb = new StringBuilder();
        for (Tracks.Group group : tracks.getGroups()) {
            for (int i = 0; i < group.length; i++) {
                if (!group.isTrackSupported(i)) continue;
                Format f = group.getTrackFormat(i);
                if (f == null) continue;
                if (sb.length() > 0) sb.append(" | ");
                String sampleMime = f.sampleMimeType != null ? f.sampleMimeType : "?";
                String containerMime = f.containerMimeType != null ? f.containerMimeType : "?";
                String codecs = f.codecs != null ? f.codecs : "";
                sb.append(sampleMime).append(" @ ").append(containerMime);
                if (!codecs.isEmpty()) sb.append(" [").append(codecs).append("]");
                if (f.width > 0 || f.height > 0) sb.append(" ").append(f.width).append("x").append(f.height);
                if (f.channelCount > 0) sb.append(" ").append(f.channelCount).append("ch");
            }
        }
        return sb.length() == 0 ? "no-supported-tracks" : sb.toString();
    }

    // ─── UI ──────────────────────────────────────────────────────────────────
    private void buildUI() {
        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);
        playerView = new PlayerView(this);
        playerView.setUseController(false);
        playerView.setKeepScreenOn(true);
        root.addView(playerView, matchParent());

        loadingView = new ProgressBar(this, null, android.R.attr.progressBarStyleLarge);
        root.addView(loadingView, centered(dp(38), dp(38)));

        errorContainer = buildErrorView();
        root.addView(errorContainer, centered(-2, -2));

        GestureDetector gd = new GestureDetector(this,
            new GestureDetector.SimpleOnGestureListener() {
                @Override public boolean onSingleTapConfirmed(MotionEvent e) { toggleOverlay(); return true; }
                @Override public boolean onDoubleTap(MotionEvent e) {
                    if (player!=null) { if (player.isPlaying()) player.pause(); else player.play(); updatePlayPauseIcon(); }
                    return true;
                }
            });
        View tc = new View(this);
        tc.setBackgroundColor(Color.TRANSPARENT);
        tc.setOnTouchListener((v,e)->{ gd.onTouchEvent(e); return true; });
        root.addView(tc, matchParent());

        overlayTop    = buildTopOverlay();
        overlayCenter = buildCenterOverlay();
        overlayBottom = buildBottomOverlay();
        root.addView(overlayTop,    new FrameLayout.LayoutParams(-1,-2,Gravity.TOP));
        root.addView(overlayCenter, centered(-2,-2));
        root.addView(overlayBottom, new FrameLayout.LayoutParams(-1,-2,Gravity.BOTTOM));
        setOverlayVisible(false);
        setContentView(root);
    }

    private View buildTopOverlay() {
        // sv-plex: minimal ghost bar — back button left, utility buttons right
        LinearLayout top = new LinearLayout(this);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        top.setPadding(dp(8), dp(30), dp(8), dp(10));
        android.graphics.drawable.GradientDrawable _topGrad =
            new android.graphics.drawable.GradientDrawable(
                android.graphics.drawable.GradientDrawable.Orientation.TOP_BOTTOM,
                new int[]{ 0xCC000000, 0x00000000 });
        top.setBackground(_topGrad);

        ImageButton backBtn = makeButton(android.R.drawable.ic_media_previous);
        backBtn.setOnClickListener(v -> finish());
        top.addView(backBtn);

        // Spacer
        android.widget.Space sp = new android.widget.Space(this);
        top.addView(sp, new LinearLayout.LayoutParams(0, -2, 1f));

        recordBtn = makeButton(android.R.drawable.ic_btn_speak_now);
        recordBtn.setColorFilter(Color.parseColor("#80ffffff"));
        recordBtn.setOnClickListener(v -> toggleRecording());
        top.addView(recordBtn);

        if (isIptvItem()) {
            timeshiftPauseBtn = makeButton(android.R.drawable.ic_media_pause);
            timeshiftPauseBtn.setColorFilter(Color.parseColor("#80ffffff"));
            timeshiftPauseBtn.setOnClickListener(v -> toggleTimeshiftPause());
            top.addView(timeshiftPauseBtn);
        }

        lockBtn = makeButton(android.R.drawable.ic_lock_idle_lock);
        lockBtn.setColorFilter(Color.parseColor("#80ffffff"));
        lockBtn.setOnClickListener(v -> {
            locked = !locked;
            lockBtn.setColorFilter(locked ? Color.parseColor("#ffa502") : Color.parseColor("#80ffffff"));
            showMsg(locked ? "🔒 Locked to this source" : "🔓 Auto-failover enabled");
            scheduleHideOverlay();
        });
        top.addView(lockBtn);
        return top;
    }

    private View buildCenterOverlay() {
        // sv-plex: center overlay is empty — all controls live in the bottom bar
        android.widget.FrameLayout empty = new android.widget.FrameLayout(this);
        empty.setBackgroundColor(Color.TRANSPARENT);
        // seekRew/Fwd fields left null — null-checked at all call sites
        return empty;
    }

    private TextView makeSeekLabel(String text) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextColor(Color.WHITE);
        tv.setTextSize(10);
        tv.setTypeface(null, android.graphics.Typeface.BOLD);
        tv.setGravity(android.view.Gravity.CENTER);
        tv.setBackgroundColor(Color.parseColor("#44000000"));
        tv.setPadding(dp(10), dp(8), dp(10), dp(8));
        android.widget.LinearLayout.LayoutParams lp = new android.widget.LinearLayout.LayoutParams(-2,-2);
        lp.leftMargin = dp(3); lp.rightMargin = dp(3);
        tv.setLayoutParams(lp);
        return tv;
    }

    private boolean isSeekable() {
        if (player == null) return false;
        long dur = player.getDuration();
        return dur > 0 && dur != Long.MIN_VALUE;
    }

    private String formatTime(long ms) {
        if (ms < 0) ms = 0;
        long tot = ms / 1000;
        long h = tot / 3600, m2 = (tot % 3600) / 60, s = tot % 60;
        return h > 0 ? String.format(Locale.US, "%d:%02d:%02d", h, m2, s)
                     : String.format(Locale.US, "%d:%02d", m2, s);
    }

    // b230: populate VOD meta label — called when player becomes ready
    // JS passes: nowNext = "year|mpaa|runtime_min|rating"
    private void populateVodMeta() {
        if (isIptvItem() || vodMetaText == null) return;
        // sv-plex: titleText already holds the stream title (set in updateDisplay)
        String raw = getIntent().getStringExtra(EXTRA_NOW_NEXT);
        StringBuilder sb = new StringBuilder();
        if (raw != null && !raw.isEmpty()) {
            String[] p = raw.split("[|]", -1);
            String yr  = p.length > 0 ? p[0].trim() : "";
            String mp  = p.length > 1 ? p[1].trim() : "";
            String rt  = p.length > 2 ? p[2].trim() : "";
            String rat = p.length > 3 ? p[3].trim() : "";
            if (!yr.isEmpty()  && !yr.equals("0"))   { sb.append(yr); }
            if (!mp.isEmpty())                        { if(sb.length()>0)sb.append("  \u00b7  "); sb.append(mp); }
            if (!rt.isEmpty()  && !rt.equals("0"))   { try { int r=Integer.parseInt(rt); if(r>0){ if(sb.length()>0)sb.append("  \u00b7  "); sb.append(r/60).append("h ").append(r%60).append("m"); } } catch(Exception ign){} }
            if (!rat.isEmpty() && !rat.equals("0.0")){ try { double r=Double.parseDouble(rat); if(r>0){ if(sb.length()>0)sb.append("  \u00b7  "); sb.append("\u2605 ").append(String.format(java.util.Locale.US,"%.1f",r)); } } catch(Exception ign){} }
        }
        if (sb.length() == 0) sb.append(streamTitle);
        final String meta = sb.toString();
        runOnUiThread(() -> { if (vodMetaText != null) vodMetaText.setText(meta); });
    }

    private void seekRelative(long offsetMs) {
        if (player == null) return;
        long dur = player.getDuration();
        long pos = player.getCurrentPosition();
        long target = Math.max(0, pos + offsetMs);
        if (dur > 0) target = Math.min(target, dur);
        player.seekTo(target);
        updatePlayPauseIcon();
    }




    private View buildBottomOverlay() {
        // sv-plex: unified Plex-style bottom panel for ALL stream types
        // Layout (bottom-up gradient):
        //  Row 1 — title (large, left) + quality badge (right)
        //  Row 2 — status / EPG / VOD meta line
        //  Row 3 — progress bar (shown only when seekable)
        //  Row 4 — [elapsed] [⏮/src-prev] [⏸/▶] [⏭/src-next] [remaining]
        //  Row 5 — watchlist pill + source/group info

        LinearLayout bot = new LinearLayout(this);
        bot.setOrientation(LinearLayout.VERTICAL);
        // Tall top-padding so the gradient fade zone is visible above content
        bot.setPadding(dp(16), dp(50), dp(16), dp(18));
        android.graphics.drawable.GradientDrawable _botGrad =
            new android.graphics.drawable.GradientDrawable(
                android.graphics.drawable.GradientDrawable.Orientation.BOTTOM_TOP,
                new int[]{ 0xF2000000, 0xBB000000, 0x00000000 });
        bot.setBackground(_botGrad);

        // ── Row 1: Title + quality badge ─────────────────────────────────────
        LinearLayout titleRow = new LinearLayout(this);
        titleRow.setOrientation(LinearLayout.HORIZONTAL);
        titleRow.setGravity(Gravity.BOTTOM);

        titleText = makeLabel(22, Color.WHITE, true);
        titleText.setSingleLine(false);
        titleText.setMaxLines(2);
        titleText.setEllipsize(android.text.TextUtils.TruncateAt.END);
        LinearLayout.LayoutParams titleLp = new LinearLayout.LayoutParams(0, -2, 1f);
        titleLp.rightMargin = dp(8);
        titleRow.addView(titleText, titleLp);

        // Quality badge — right side (shows signal level, resolution, or LIVE)
        strengthText = makeLabel(9, Color.WHITE, true);
        android.graphics.drawable.GradientDrawable _qBg = new android.graphics.drawable.GradientDrawable();
        _qBg.setShape(android.graphics.drawable.GradientDrawable.RECTANGLE);
        _qBg.setColor(0x88000000);
        _qBg.setStroke(dp(1), 0x66ffffff);
        _qBg.setCornerRadius(dp(4));
        strengthText.setBackground(_qBg);
        strengthText.setPadding(dp(6), dp(3), dp(6), dp(3));
        strengthText.setText(isIptvItem() ? "LIVE" : "");
        titleRow.addView(strengthText);

        bot.addView(titleRow, new LinearLayout.LayoutParams(-1, -2));

        // ── Row 2: Status / meta lines ────────────────────────────────────────
        // Primary status line (source info, EPG episode, etc.)
        statusText = makeLabel(11, Color.parseColor("#ccffffff"), false);
        statusText.setSingleLine(false);
        statusText.setMaxLines(2);
        statusText.setPadding(0, dp(2), 0, dp(1));
        bot.addView(statusText, new LinearLayout.LayoutParams(-1, -2));

        // EPG now/next (ITV — shown in accent colour)
        nowNextText = makeLabel(10, Color.parseColor("#a29bfe"), false);
        nowNextText.setPadding(0, 0, 0, dp(2));
        String nn = getIntent().getStringExtra(EXTRA_NOW_NEXT);
        if (nn != null && !nn.isEmpty()) nowNextText.setText(nn);
        bot.addView(nowNextText, new LinearLayout.LayoutParams(-1, -2));

        // VOD meta (year · MPAA · runtime · rating) + recording/timeshift badges
        LinearLayout metaBadgeRow = new LinearLayout(this);
        metaBadgeRow.setOrientation(LinearLayout.HORIZONTAL);
        metaBadgeRow.setGravity(Gravity.CENTER_VERTICAL);
        metaBadgeRow.setPadding(0, 0, 0, dp(2));

        vodMetaText = makeLabel(10, Color.parseColor("#b0b0d0"), false);
        vodMetaText.setVisibility(isIptvItem() ? View.GONE : View.VISIBLE);
        LinearLayout.LayoutParams vmLp = new LinearLayout.LayoutParams(0, -2, 1f);
        metaBadgeRow.addView(vodMetaText, vmLp);

        recStatusText  = makeLabel(7, Color.parseColor("#ff4757"), true);
        timeshiftText  = makeLabel(7, Color.parseColor("#ffa502"), false);
        metaBadgeRow.addView(recStatusText);
        metaBadgeRow.addView(timeshiftText);
        bot.addView(metaBadgeRow, new LinearLayout.LayoutParams(-1, -2));

        // ── Row 3: Seek / progress bar ────────────────────────────────────────
        vodProgressRow = new android.widget.LinearLayout(this);
        vodProgressRow.setOrientation(android.widget.LinearLayout.VERTICAL);
        vodProgressRow.setVisibility(View.GONE);
        vodProgressRow.setPadding(0, dp(6), 0, 0);

        vodSeekBar = new SeekBar(this);
        vodSeekBar.setMax(1000);
        // Plex-amber progress bar
        vodSeekBar.getProgressDrawable().setColorFilter(
            Color.parseColor("#f9ca24"), android.graphics.PorterDuff.Mode.SRC_IN);
        vodSeekBar.getThumb().setColorFilter(
            Color.parseColor("#f9ca24"), android.graphics.PorterDuff.Mode.SRC_IN);
        vodSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar sb, int prog, boolean fromUser) {
                if (fromUser && player != null && isSeekable()) {
                    player.seekTo((long) prog * 1000L);
                }
            }
            @Override public void onStartTrackingTouch(SeekBar sb) {
                handler.removeCallbacks(hideOverlayRunnable);
            }
            @Override public void onStopTrackingTouch(SeekBar sb) { scheduleHideOverlay(); }
        });
        android.widget.LinearLayout.LayoutParams seekLp =
            new android.widget.LinearLayout.LayoutParams(-1, -2);
        vodProgressRow.addView(vodSeekBar, seekLp);
        bot.addView(vodProgressRow, new android.widget.LinearLayout.LayoutParams(-1, -2));

        // ── Row 4: Transport controls ─────────────────────────────────────────
        LinearLayout ctrlRow = new LinearLayout(this);
        ctrlRow.setOrientation(LinearLayout.HORIZONTAL);
        ctrlRow.setGravity(Gravity.CENTER_VERTICAL);
        ctrlRow.setPadding(0, dp(8), 0, 0);

        // Elapsed time (left)
        vodElapsed = makeLabel(10, Color.parseColor("#e0ffffff"), true);
        vodElapsed.setMinWidth(dp(55));
        ctrlRow.addView(vodElapsed);

        android.widget.Space spL = new android.widget.Space(this);
        ctrlRow.addView(spL, new LinearLayout.LayoutParams(0, -2, 1f));

        // ⏮  — ITV: prev source  |  VOD: seek -30s
        prevBtn = new ImageButton(this);
        prevBtn.setImageResource(android.R.drawable.ic_media_rew);
        prevBtn.setColorFilter(Color.WHITE);
        prevBtn.setBackgroundColor(Color.TRANSPARENT);
        prevBtn.setPadding(dp(12), dp(10), dp(12), dp(10));
        prevBtn.setAlpha(variants.size() > 1 ? 1f : 0.45f);
        prevBtn.setOnClickListener(v -> {
            if (isIptvItem()) { playPreviousVariant(); }
            else { seekRelative(-30000); scheduleHideOverlay(); }
        });
        android.widget.LinearLayout.LayoutParams rwLp =
            new android.widget.LinearLayout.LayoutParams(-2, -2);
        rwLp.rightMargin = dp(4);
        ctrlRow.addView(prevBtn, rwLp);

        // ⏸/▶  — play / pause (white oval, larger)
        playPauseBtn = new ImageButton(this);
        playPauseBtn.setImageResource(android.R.drawable.ic_media_pause);
        playPauseBtn.setColorFilter(Color.BLACK);
        android.graphics.drawable.GradientDrawable _ppBg =
            new android.graphics.drawable.GradientDrawable();
        _ppBg.setShape(android.graphics.drawable.GradientDrawable.OVAL);
        _ppBg.setColor(0xFFFFFFFF);
        playPauseBtn.setBackground(_ppBg);
        playPauseBtn.setPadding(dp(16), dp(16), dp(16), dp(16));
        playPauseBtn.setOnClickListener(v -> {
            if (timeshiftPaused) { resumeTimeshift(); userExplicitPause = false; }
            else if (player != null) {
                if (player.isPlaying()) { player.pause(); userExplicitPause = true; }
                else { player.play(); userExplicitPause = false; }
                updatePlayPauseIcon();
            }
            scheduleHideOverlay();
        });
        android.widget.LinearLayout.LayoutParams ppLp =
            new android.widget.LinearLayout.LayoutParams(-2, -2);
        ppLp.leftMargin = dp(16); ppLp.rightMargin = dp(16);
        ctrlRow.addView(playPauseBtn, ppLp);

        // ⏭  — ITV: next source  |  VOD: seek +30s
        nextBtn = new ImageButton(this);
        nextBtn.setImageResource(android.R.drawable.ic_media_ff);
        nextBtn.setColorFilter(Color.WHITE);
        nextBtn.setBackgroundColor(Color.TRANSPARENT);
        nextBtn.setPadding(dp(12), dp(10), dp(12), dp(10));
        nextBtn.setAlpha(variants.size() > 1 ? 1f : 0.45f);
        nextBtn.setOnClickListener(v -> {
            if (isIptvItem()) { playNextVariant(); }
            else { seekRelative(30000); scheduleHideOverlay(); }
        });
        android.widget.LinearLayout.LayoutParams ffLp =
            new android.widget.LinearLayout.LayoutParams(-2, -2);
        ffLp.leftMargin = dp(4);
        ctrlRow.addView(nextBtn, ffLp);

        android.widget.Space spR = new android.widget.Space(this);
        ctrlRow.addView(spR, new LinearLayout.LayoutParams(0, -2, 1f));

        // Remaining time (right)
        vodRemaining = makeLabel(10, Color.parseColor("#80ffffff"), false);
        vodRemaining.setMinWidth(dp(55));
        vodRemaining.setGravity(android.view.Gravity.END);
        ctrlRow.addView(vodRemaining);

        bot.addView(ctrlRow, new LinearLayout.LayoutParams(-1, -2));

        // ── Row 5: Watchlist pill + source/group info ─────────────────────────
        LinearLayout infoRow = new LinearLayout(this);
        infoRow.setOrientation(LinearLayout.HORIZONTAL);
        infoRow.setGravity(Gravity.CENTER_VERTICAL);
        infoRow.setPadding(0, dp(8), 0, 0);

        vodWlBtn = new android.widget.Button(this);
        vodWlBtn.setText("♡ Watchlist");
        vodWlBtn.setTextColor(Color.WHITE);
        vodWlBtn.setTextSize(10);
        android.graphics.drawable.GradientDrawable _wlBg =
            new android.graphics.drawable.GradientDrawable();
        _wlBg.setShape(android.graphics.drawable.GradientDrawable.RECTANGLE);
        _wlBg.setColor(0x28ffffff);
        _wlBg.setStroke(dp(1), 0x66ffffff);
        _wlBg.setCornerRadius(dp(16));
        vodWlBtn.setBackground(_wlBg);
        vodWlBtn.setPadding(dp(14), dp(5), dp(14), dp(5));
        vodWlBtn.setVisibility(isIptvItem() ? View.GONE : View.VISIBLE);
        vodWlBtn.setOnClickListener(v -> {
            if (itemId != null && !itemId.isEmpty()) {
                String st = streamTitle.replace("'", " ");
                reportToJs("window._vodNativeToggleWL&&window._vodNativeToggleWL('" + itemId + "','" + st + "')");
            }
        });
        infoRow.addView(vodWlBtn);

        android.widget.Space infoSp = new android.widget.Space(this);
        infoRow.addView(infoSp, new LinearLayout.LayoutParams(0, -2, 1f));

        sourceInfoText = makeLabel(8, Color.parseColor("#50ffffff"), false);
        sourceInfoText.setText("Source 1/" + variants.size());
        infoRow.addView(sourceInfoText);

        groupInfoText = makeLabel(7, Color.parseColor("#30ffffff"), false);
        groupInfoText.setPadding(dp(6), 0, 0, 0);
        if (streamCategory != null && !streamCategory.isEmpty()) {
            groupInfoText.setText(streamCategory);
        }
        infoRow.addView(groupInfoText);
        bot.addView(infoRow, new LinearLayout.LayoutParams(-1, -2));

        // ── Timeshift controls (ITV only) ─────────────────────────────────────
        if (isIptvItem()) {
            timeshiftBar = new SeekBar(this);
            timeshiftBar.setVisibility(View.GONE);
            timeshiftBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override public void onProgressChanged(SeekBar s, int prog, boolean user) {
                    if (user && player != null) {
                        long live = player.getDuration();
                        if (live > 0) player.seekTo((long)(prog / 100.0 * live));
                    }
                }
                @Override public void onStartTrackingTouch(SeekBar s) {}
                @Override public void onStopTrackingTouch(SeekBar s) {}
            });
            android.widget.LinearLayout.LayoutParams tsLp =
                new android.widget.LinearLayout.LayoutParams(-1, -2);
            tsLp.topMargin = dp(6);
            bot.addView(timeshiftBar, tsLp);

            timeshiftLiveBtn = makeButton(android.R.drawable.ic_media_next);
            timeshiftLiveBtn.setVisibility(View.GONE);
            timeshiftLiveBtn.setColorFilter(Color.parseColor("#ff4757"));
            timeshiftLiveBtn.setOnClickListener(v -> jumpToLive());
            LinearLayout liveRow = new LinearLayout(this);
            liveRow.setGravity(Gravity.CENTER);
            TextView liveLabel = makeLabel(8, Color.parseColor("#ff4757"), false);
            liveLabel.setText("► LIVE  ");
            liveRow.addView(liveLabel);
            liveRow.addView(timeshiftLiveBtn);
            bot.addView(liveRow);
        }

        return bot;
    }

    private View buildErrorView() {
        LinearLayout c = new LinearLayout(this);
        c.setOrientation(LinearLayout.VERTICAL);
        c.setGravity(Gravity.CENTER);
        c.setVisibility(View.GONE);
        errorText = makeLabel(12,Color.parseColor("#aaaaaa"),false);
        errorText.setGravity(Gravity.CENTER);
        errorText.setPadding(dp(20),0,dp(20),dp(10));
        c.addView(errorText);
        TextView retry = makeLabel(13,Color.parseColor("#6c5ce7"),false);
        retry.setText("Tap to Retry");
        retry.setPadding(dp(16),dp(8),dp(16),dp(8));
        retry.setBackgroundColor(Color.parseColor("#1a1a2e"));
        retry.setOnClickListener(v->{ errorContainer.setVisibility(View.GONE); loadingView.setVisibility(View.VISIBLE); playVariant(currentIdx); });
        c.addView(retry);
        return c;
    }

    // ─── Playback ────────────────────────────────────────────────────────────
    private void playVariant(int idx) {
        // On channel change, clear timeshift buffer
        stopTimeshiftBuffer();
        stopLiveKeepAlive();
        releaseWifiLock();

        if (idx<0||idx>=variants.size()) { if (lastSuccessUrl!=null) { for(int i=0;i<variants.size();i++) if(lastSuccessUrl.equals(variants.get(i).url)){playVariant(i);return;} } showAllFailed(); return; }
        currentIdx = idx;
        Variant v  = variants.get(idx);
        seekOnReadyMs = v.seekMs;
        releasePlayer();
        loadingView.setVisibility(View.VISIBLE);
        errorContainer.setVisibility(View.GONE);

        String display = v.title.isEmpty()?"Source "+(idx+1):v.title;
        if (!v.tag.isEmpty()) display+=" ("+v.tag+")";
        titleText.setText(display);
        statusText.setText("Source "+(idx+1)+"/"+variants.size()+(locked?" · 🔒":""));
        if (sourceInfoText!=null) sourceInfoText.setText("Source "+(idx+1)+"/"+variants.size()+" · ◀▶ prev/next");
        if (groupInfoText!=null && streamCategory!=null && !streamCategory.isEmpty()) groupInfoText.setText(streamCategory);
        if (prevBtn!=null) prevBtn.setAlpha(variants.size()>1?1f:0.45f);
        if (nextBtn!=null) nextBtn.setAlpha(variants.size()>1?1f:0.45f);
        strengthText.setText("");
        if (idx>0) showMsg("Trying: "+display);

        DataSource.Factory httpFactory = new DefaultHttpDataSource.Factory()
            .setUserAgent("StreamVault/5.7 ExoPlayer")
            .setConnectTimeoutMs(30000).setReadTimeoutMs(30000)
            .setAllowCrossProtocolRedirects(true)
            .setContentTypePredicate(value -> true);
        // Wake lock keeps CPU alive during HLS segment downloads
        long tsBufferMs = (long) timeshiftMaxMin * 60 * 1000L;
        if (tsBufferMs <= 0) tsBufferMs = 30 * 60 * 1000L;
        // Relay streams (hdhr-xmltv ffmpeg proxy) need a small buffer — the encoder
        // produces data in real time at a fixed rate. A large minBuffer (30s) means
        // ExoPlayer tries to stay 30s ahead of live, causing it to drain unevenly
        // when ffmpeg output has any variance, producing visible jitter/stutter.
        // For relay URLs use a 4s min buffer (enough to absorb network variance
        // without falling behind live). For all other streams keep the large buffer
        // so timeshift and VOD work correctly.
        boolean isRelayStream = v.url != null && v.url.contains("/proxy/");
        int minBuf  = isRelayStream ?  4_000 : 30_000;
        int maxBuf  = isRelayStream ? 15_000 : (int) Math.min(tsBufferMs, 3_600_000);
        int playBuf = isRelayStream ?  1_500 :  5_000;
        int rebufBuf= isRelayStream ?  2_500 :  7_500;
        androidx.media3.exoplayer.DefaultLoadControl loadControl =
            new androidx.media3.exoplayer.DefaultLoadControl.Builder()
                .setBufferDurationsMs(minBuf, maxBuf, playBuf, rebufBuf)
                .setPrioritizeTimeOverSizeThresholds(true)
                .build();
        // On mobile: prefer the ffmpeg extension decoder so MPEG-2 streams from
        // HDHomeRun CONNECT play with video (phones lack hardware MPEG-2 decoders).
        // EXTENSION_RENDERER_MODE_PREFER uses software decoder when hardware can't handle
        // the codec, then falls back to hardware for codecs it can handle (H.264 etc).
        // TV build: hardware decoders handle everything so leave mode at default.
        boolean isMobileForRenderer = "mobile".equals(BuildConfig.DEVICE_FLAVOR);
        DefaultRenderersFactory renderersFactory = new DefaultRenderersFactory(this)
            .setEnableDecoderFallback(true)
            .setExtensionRendererMode(
                isMobileForRenderer
                    ? DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER
                    : DefaultRenderersFactory.EXTENSION_RENDERER_MODE_OFF
            );
        player = new ExoPlayer.Builder(this, renderersFactory).setLoadControl(loadControl).build();
        acquireWifiLock();
        playerView.setPlayer(player);
        playbackStartTime = System.currentTimeMillis();

        String scheme = getScheme(v.url);
        boolean useRtsp      = "rtsp".equals(scheme) || "rtsps".equals(scheme);
        boolean preferHls    = !useRtsp && isLikelyHls(v.url);
        boolean preferHdhrTs = !useRtsp && !preferHls && isLikelyHdhrTs(v.url);

        // HDHR CONNECT streams MPEG-2 video in MPEG-TS. The mobile APK includes the
        // media3-decoder-ffmpeg extension which provides a software MPEG-2 decoder,
        // so ExoPlayer can decode it without any proxy or server-side transcoding.
        // EXTENSION_RENDERER_MODE_PREFER (set in renderersFactory above) activates it.
        boolean isMobileFlavor = "mobile".equals(BuildConfig.DEVICE_FLAVOR);
        String playUrl = v.url;

        MediaItem mediaItem = preferHdhrTs
            ? new MediaItem.Builder().setUri(Uri.parse(playUrl)).setMimeType(MimeTypes.VIDEO_MP2T).build()
            : MediaItem.fromUri(Uri.parse(playUrl));
        DefaultExtractorsFactory extractorsFactory = new DefaultExtractorsFactory()
            .setTsExtractorFlags(DefaultTsPayloadReaderFactory.FLAG_DETECT_ACCESS_UNITS
                | DefaultTsPayloadReaderFactory.FLAG_ALLOW_NON_IDR_KEYFRAMES);
        MediaSource src = useRtsp
            ? new RtspMediaSource.Factory().createMediaSource(mediaItem)
            : (preferHls
                ? new HlsMediaSource.Factory(httpFactory).setAllowChunklessPreparation(true).createMediaSource(mediaItem)
                : new ProgressiveMediaSource.Factory(httpFactory, extractorsFactory).createMediaSource(mediaItem));

        Log.d(TAG, "playVariant url=" + playUrl + " scheme=" + scheme + " hls=" + preferHls + " hdhrTs=" + preferHdhrTs + " mobileFlavor=" + isMobileFlavor + " category=" + streamCategory);
        String _hdhrModeLabel = isMobileFlavor ? "HDHR" : "HDHR TS";
        if (statusText != null && preferHdhrTs) statusText.setText("Source " + (idx+1) + "/" + variants.size() + " · " + _hdhrModeLabel + (locked ? " · 🔒" : ""));

        final boolean[] primaryFailed = {false};
        final DataSource.Factory hf2 = httpFactory;
        final boolean hdhrTs = preferHdhrTs;
        player.addListener(new Player.Listener() {
            @Override public void onPlaybackStateChanged(int state) {
                Log.d(TAG, "state=" + state + " hdhrTs=" + hdhrTs + " url=" + v.url);
                if (state==Player.STATE_READY) {
                    loadingView.setVisibility(View.GONE);
                    errorContainer.setVisibility(View.GONE);
                    lastSuccessUrl = v.url;
                    cancelFailoverTimeout();
                    // Show seek buttons only for seekable VOD content (duration known, not ITV live)
                    handler.postDelayed(() -> {
                        if (player == null) return;
                        boolean seekable = !isIptvItem()
                            && player.isCurrentMediaItemSeekable()
                            && player.getDuration() > 0;
                        int sv = seekable ? View.VISIBLE : View.GONE;
                        if (seekRew30 != null) seekRew30.setVisibility(sv);
                        if (seekRew10 != null) seekRew10.setVisibility(sv);
                        if (seekFwd10 != null) seekFwd10.setVisibility(sv);
                        if (seekFwd30 != null) seekFwd30.setVisibility(sv);
                        if (vodProgressRow != null) vodProgressRow.setVisibility(sv);
                        if (!isIptvItem()) populateVodMeta(); // b230
                    }, 1500); // small delay to let ExoPlayer report seekability
                    // Seek to resume position (Plex resume)
                    if (seekOnReadyMs>0) {
                        player.seekTo(seekOnReadyMs);
                        seekOnReadyMs=0;
                    }
                    // Start timeshift buffer for live TV (if enabled in settings)
                    if (isIptvItem() && timeshiftUserEnabled) startTimeshiftBuffer();
                    // Start keep-alive for live streams
                    if (isIptvItem()) startLiveKeepAlive();
                    // Start Plex position reporter
                    if (!isIptvItem()) startPositionReporter();
                } else if (state==Player.STATE_BUFFERING) {
                    loadingView.setVisibility(View.VISIBLE);
                    if (!locked&&foAuto) startFailoverTimeout();
                } else if (state==Player.STATE_ENDED) {
                    // Plex playback complete — clear resume position
                    if (itemId!=null&&!itemId.isEmpty()) {
                        reportToJs("window.onPlexPlaybackComplete && window.onPlexPlaybackComplete('"+itemId+"')");
                    }
                }
            }
            @Override public void onTracksChanged(Tracks tracks) {
                Log.d(TAG, "tracks=" + buildTrackSummary(tracks));
            }
            @Override public void onVideoSizeChanged(VideoSize videoSize) {
                Log.d(TAG, "videoSize=" + videoSize.width + "x" + videoSize.height + " ratio=" + videoSize.pixelWidthHeightRatio);
            }
            @Override public void onRenderedFirstFrame() {
                Log.d(TAG, "firstVideoFrameRendered url=" + v.url);
            }
            @Override public void onPlayerError(PlaybackException error) {
                Log.e(TAG, "playerError code=" + error.errorCode + " msg=" + error.getMessage(), error);
                cancelFailoverTimeout();
                if (!primaryFailed[0]&&preferHls) {
                    primaryFailed[0]=true;
                    try {
                        player.stop();
                        MediaItem fallbackItem = hdhrTs
                            ? new MediaItem.Builder().setUri(Uri.parse(v.url)).setMimeType(MimeTypes.VIDEO_MP2T).build()
                            : MediaItem.fromUri(Uri.parse(v.url));
                        DefaultExtractorsFactory fallbackExtractors = new DefaultExtractorsFactory()
                            .setTsExtractorFlags(DefaultTsPayloadReaderFactory.FLAG_DETECT_ACCESS_UNITS
                                | DefaultTsPayloadReaderFactory.FLAG_ALLOW_NON_IDR_KEYFRAMES);
                        MediaSource progressive = new ProgressiveMediaSource.Factory(hf2, fallbackExtractors).createMediaSource(fallbackItem);
                        player.setMediaSource(progressive); player.prepare(); player.setPlayWhenReady(true);
                    } catch (Exception e) { tryNextVariant(); }
                    return;
                }
                if (!locked&&foAuto&&networkAvailable) tryNextVariant();
                else if (!networkAvailable) { showMsg("Network lost — waiting…"); loadingView.setVisibility(View.VISIBLE); }
                else showStreamFailed("code "+error.errorCode);
            }
        });
        player.setMediaSource(src);
        player.setPlayWhenReady(true);
        player.prepare();
        showOverlayBriefly();
    }

    // ─── Plex Position Reporting ─────────────────────────────────────────────
    private void startPositionReporter() {
        stopPositionReporter();
        if (itemId==null||itemId.isEmpty()) return;
        positionReporter = new Runnable() {
            @Override public void run() {
                if (player!=null&&player.isPlaying()) {
                    long pos = player.getCurrentPosition();
                    long dur = player.getDuration();
                    String js = "window.onPlexPositionUpdate && window.onPlexPositionUpdate('"
                        +itemId+"',"+pos+","+dur+",'')";
                    reportToJs(js);
                }
                handler.postDelayed(this, 10000); // report every 10s
            }
        };
        handler.postDelayed(positionReporter, 15000); // first report after 15s
    }
    private void stopPositionReporter() {
        if (positionReporter!=null) { handler.removeCallbacks(positionReporter); positionReporter=null; }
    }
    private void reportToJs(String js) {
        // Try to reach MainActivity's WebView
        try { MainActivity.webViewRef.loadUrl("javascript:"+js); } catch (Exception ignored) {}
    }

    // ─── Live TV Timeshift ────────────────────────────────────────────────────
    // Strategy: when paused, ExoPlayer's internal HLS buffer grows naturally.
    // We just track the offset and let ExoPlayer handle the buffer.
    // For raw streams we can't buffer, so timeshift is only meaningful for HLS.
    private void startTimeshiftBuffer() {
        timeshiftEnabled  = true;
        timeshiftPaused   = false;
        timeshiftOffset   = 0;
        timeshiftBufMs    = 0;
        updateTimeshiftUI();
    }
    private void stopTimeshiftBuffer() {
        timeshiftEnabled  = false;
        timeshiftPaused   = false;
        timeshiftOffset   = 0;
        timeshiftBufMs    = 0;
        if (timeshiftText!=null) timeshiftText.setText("");
        if (timeshiftBar!=null)  timeshiftBar.setVisibility(View.GONE);
        if (timeshiftLiveBtn!=null) timeshiftLiveBtn.setVisibility(View.GONE);
    }
    private void toggleTimeshiftPause() {
        if (!timeshiftEnabled) return;
        if (timeshiftPaused) { resumeTimeshift(); }
        else { pauseTimeshift(); }
        scheduleHideOverlay();
    }
    private void pauseTimeshift() {
        if (player==null||!timeshiftEnabled) return;
        timeshiftPaused   = true;
        timeshiftPausedAt = System.currentTimeMillis();
        timeshiftPausedPos = player.getCurrentPosition();
        player.pause();
        updatePlayPauseIcon();
        updateTimeshiftUI();
        showMsg("⏸ Live TV paused — buffer growing");
    }
    private void resumeTimeshift() {
        if (player==null) return;
        timeshiftPaused = false;
        timeshiftOffset = System.currentTimeMillis() - timeshiftPausedAt;
        // Seek to exact paused position — ExoPlayer live streams jump to live edge
        // on play() by default; seekTo() keeps us at the buffered pause point.
        if (timeshiftPausedPos > 0) {
            try { player.seekTo(timeshiftPausedPos); } catch (Exception ignored) {}
        }
        player.play();
        updatePlayPauseIcon();
        updateTimeshiftUI();
        showMsg("▶ Resuming — " + (timeshiftOffset / 1000) + "s behind live");
    }
    private void jumpToLive() {
        if (player==null) return;
        timeshiftPaused = false;
        timeshiftOffset = 0;
        // Seek to end of buffer (live edge)
        long dur = player.getDuration();
        if (dur>0) player.seekTo(dur);
        player.play();
        updatePlayPauseIcon();
        updateTimeshiftUI();
        showMsg("● Back to live");
    }
    private void updateTimeshiftUI() {
        handler.post(()->{
            if (!timeshiftEnabled) return;
            long offsetSec = timeshiftOffset/1000;
            if (timeshiftPaused) {
                timeshiftText.setText("⏸ PAUSED — press ▶ to resume (buffers while paused)");
                timeshiftText.setTextColor(Color.parseColor("#ffa502"));
            } else if (offsetSec>5) {
                timeshiftText.setText("⏪ "+offsetSec+"s behind live  —  tap ▶▶ for live");
                timeshiftText.setTextColor(Color.parseColor("#ffa502"));
            } else {
                timeshiftText.setText("● LIVE");
                timeshiftText.setTextColor(Color.parseColor("#2ed573"));
            }
            if (timeshiftBar!=null) timeshiftBar.setVisibility(timeshiftOffset>5000?View.VISIBLE:View.GONE);
            if (timeshiftLiveBtn!=null) timeshiftLiveBtn.setVisibility(timeshiftOffset>5000?View.VISIBLE:View.GONE);
        });
    }

    // ─── Recording (HLS-aware, fixed) ────────────────────────────────────────
    private void toggleRecording() {
        if (recording) stopRecording(); else startRecording();
    }

    private void startRecording() {
        if (currentIdx>=variants.size()) return;
        recording = true;
        recordingStartTime = System.currentTimeMillis();
        recordBtn.setColorFilter(Color.parseColor("#ff4757"));
        showMsg("⏺ Recording started");
        scheduleHideOverlay();

        final String streamUrl = variants.get(currentIdx).url;
        final String safeName  = variants.get(currentIdx).title.replaceAll("[^a-zA-Z0-9_-]","_");
        final String ts        = new SimpleDateFormat("yyyyMMdd_HHmmss",Locale.US).format(new Date());

        recordThread = new Thread(()->{
            OutputStream fos = null;
            String outPath = null;
            try {
                RecordingTarget target = openRecordingTarget("SV_"+safeName+"_"+ts+".ts");
                fos    = target.out;
                outPath = target.displayPath;
                long totalBytes = 0;

                // Open connection and follow redirects to get the FINAL URL
                HttpURLConnection probe = (HttpURLConnection) new URL(streamUrl).openConnection();
                probe.setRequestProperty("User-Agent","StreamVault/4.6");
                probe.setConnectTimeout(12000);
                probe.setReadTimeout(15000);
                probe.setInstanceFollowRedirects(true);
                probe.connect();

                // The final URL after any redirects
                String finalUrl = probe.getURL().toString();
                String finalBase = finalUrl.contains("/")
                    ? finalUrl.substring(0, finalUrl.lastIndexOf('/')+1) : finalUrl;

                // Read first chunk to detect HLS vs raw
                InputStream probeIn = probe.getInputStream();
                byte[] peek = new byte[8192];
                int peekLen = 0, read;
                // Read up to 8KB for detection
                while (peekLen < peek.length && (read=probeIn.read(peek,peekLen,peek.length-peekLen))!=-1) {
                    peekLen+=read;
                }
                String peekStr = new String(peek,0,peekLen,"UTF-8");

                boolean isHls = peekStr.contains("#EXTM3U") || peekStr.contains("#EXT-X-")
                    || finalUrl.contains(".m3u8") || streamUrl.contains(".m3u8");

                if (!isHls) {
                    // Raw stream — write peek then pipe rest
                    if (peekLen>0) { fos.write(peek,0,peekLen); totalBytes+=peekLen; }
                    byte[] buf = new byte[65536];
                    int n;
                    while (recording && (n=probeIn.read(buf))!=-1) {
                        fos.write(buf,0,n);
                        totalBytes+=n;
                    }
                    probeIn.close();
                } else {
                    // HLS — parse the M3U8 content we already have
                    probeIn.close();
                    probe.disconnect();

                    Set<String> downloaded = new HashSet<>();
                    while (recording) {
                        try {
                            // Re-fetch the playlist
                            HttpURLConnection pc = (HttpURLConnection) new URL(finalUrl).openConnection();
                            pc.setRequestProperty("User-Agent","StreamVault/4.6");
                            pc.setConnectTimeout(10000);
                            pc.setInstanceFollowRedirects(true);
                            InputStream pis = pc.getInputStream();
                            String actualFinal = pc.getURL().toString();
                            String actualBase  = actualFinal.contains("/")
                                ? actualFinal.substring(0,actualFinal.lastIndexOf('/')+1) : actualFinal;

                            BufferedReader br = new BufferedReader(new InputStreamReader(pis,"UTF-8"));
                            List<String> segs = new ArrayList<>();
                            String mediaList = null;
                            String line;
                            boolean nextSeg = false;
                            while ((line=br.readLine())!=null) {
                                line=line.trim();
                                if (line.startsWith("#EXTINF:")) { nextSeg=true; continue; }
                                if (line.startsWith("#EXT-X-STREAM-INF")) { nextSeg=true; continue; }
                                if (line.startsWith("#")||line.isEmpty()) { nextSeg=false; continue; }
                                // It's a URI line
                                String resolved = resolveUrl(actualBase, line);
                                if (line.endsWith(".m3u8")||line.endsWith(".m3u")) {
                                    if (mediaList==null) mediaList=resolved;
                                } else {
                                    // Any non-M3U URI after EXTINF or without recognizable extension is a segment
                                    if (nextSeg) segs.add(resolved);
                                    // Also add if it looks like a segment URL (ts, aac, fmp4, no extension)
                                    else if (!line.contains(".m3u")) segs.add(resolved);
                                }
                                nextSeg=false;
                            }
                            br.close(); pc.disconnect();

                            // If this was a master playlist, resolve media playlist
                            if (segs.isEmpty()&&mediaList!=null) {
                                String mBase=mediaList.contains("/")?mediaList.substring(0,mediaList.lastIndexOf('/')+1):mediaList;
                                HttpURLConnection mc=(HttpURLConnection)new URL(mediaList).openConnection();
                                mc.setRequestProperty("User-Agent","StreamVault/4.6");
                                mc.setInstanceFollowRedirects(true);
                                BufferedReader mr=new BufferedReader(new InputStreamReader(mc.getInputStream(),"UTF-8"));
                                nextSeg=false;
                                while((line=mr.readLine())!=null){
                                    line=line.trim();
                                    if(line.startsWith("#EXTINF:")){nextSeg=true;continue;}
                                    if(line.startsWith("#")||line.isEmpty()){nextSeg=false;continue;}
                                    if(!line.contains(".m3u")) segs.add(resolveUrl(mBase,line));
                                    nextSeg=false;
                                }
                                mr.close(); mc.disconnect();
                            }

                            // Download new segments
                            for (String seg:segs) {
                                if (!recording) break;
                                if (downloaded.contains(seg)) continue;
                                downloaded.add(seg);
                                try {
                                    HttpURLConnection sc=(HttpURLConnection)new URL(seg).openConnection();
                                    sc.setRequestProperty("User-Agent","StreamVault/4.6");
                                    sc.setConnectTimeout(10000);
                                    sc.setReadTimeout(20000);
                                    sc.setInstanceFollowRedirects(true);
                                    InputStream si=sc.getInputStream();
                                    byte[] buf=new byte[65536]; int n;
                                    while(recording&&(n=si.read(buf))!=-1){fos.write(buf,0,n);totalBytes+=n;}
                                    si.close(); sc.disconnect();
                                } catch(Exception se){/* skip bad segment */}
                            }
                            if (recording) Thread.sleep(3000);
                        } catch(Exception le){if(recording)try{Thread.sleep(3000);}catch(Exception ignored){}}
                    }
                }

                // Flush and close
                fos.flush();
                fos.close();
                fos=null;
                final long fb=totalBytes;
                final String fp=outPath;
                handler.post(()->showMsg("⏹ Saved: "+fp+" ("+(fb>1048576?fb/1048576+" MB":fb/1024+" KB")+")"));
            } catch(Exception e) {
                if (fos!=null) try{fos.close();}catch(Exception x){}
                handler.post(()->showMsg("Record error: "+e.getMessage()));
            }
            handler.post(()->{recording=false;recordingStartTime=0;recordBtn.setColorFilter(Color.parseColor("#80ffffff"));recStatusText.setText("");});
        });
        recordThread.setName("sv-record");
        recordThread.start();
    }

    private String resolveUrl(String base, String rel) {
        if (rel.startsWith("http://")||rel.startsWith("https://")) return rel;
        if (rel.startsWith("//")) return "https:"+rel;
        if (rel.startsWith("/")) {
            try { URL u=new URL(base); return u.getProtocol()+"://"+u.getHost()+(u.getPort()>0?":"+u.getPort():"")+rel; }
            catch(Exception e){ return base+rel; }
        }
        return base+rel;
    }

    private RecordingTarget openRecordingTarget(String filename) throws Exception {
        if (savePath!=null&&savePath.startsWith("content://")) {
            Uri treeUri = Uri.parse(savePath);
            DocumentFile tree = DocumentFile.fromTreeUri(this,treeUri);
            if (tree==null) throw new IllegalStateException("Recording folder unavailable");
            DocumentFile out  = tree.createFile("video/mp2t",filename);
            if (out==null)  throw new IllegalStateException("Cannot create recording file");
            OutputStream os = getContentResolver().openOutputStream(out.getUri(),"w");
            if (os==null)   throw new IllegalStateException("Cannot open recording file for write");
            return new RecordingTarget(os, describeTreeUri(treeUri)+"/"+filename);
        }
        File dir = savePath!=null&&!savePath.isEmpty()
            ? new File(savePath)
            : Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
        if (!dir.exists()&&!dir.mkdirs()) throw new IllegalStateException("Cannot create recording folder");
        File outFile = new File(dir, filename);
        return new RecordingTarget(new FileOutputStream(outFile), outFile.getAbsolutePath());
    }

    private String describeTreeUri(Uri u) {
        try {
            String docId = android.provider.DocumentsContract.getTreeDocumentId(u);
            if (docId==null||docId.isEmpty()) return "Selected folder";
            int i=docId.indexOf(':');
            String vol=i>=0?docId.substring(0,i):docId, path=i>=0?docId.substring(i+1):"";
            String base="primary".equalsIgnoreCase(vol)?"Internal storage":vol;
            return path.isEmpty()?base:(base+"/"+path);
        } catch(Exception e){ return "Selected folder"; }
    }

    private void stopRecording() {
        if (!recording) return;   // no toast if not actually recording
        recording=false;
        recordBtn.setColorFilter(Color.parseColor("#80ffffff"));
        showMsg("⏹ Stopping recording…");
    }

    // ─── Failover ────────────────────────────────────────────────────────────
    private void playPreviousVariant() { if(variants.isEmpty())return; int n=currentIdx-1; if(n<0)n=variants.size()-1; playVariant(n); }
    private void playNextVariant()     { if(variants.isEmpty())return; int n=currentIdx+1; if(n>=variants.size())n=0; playVariant(n); }
    private void tryNextVariant() {
        if (locked) return;
        if (currentIdx+1<variants.size()) { playVariant(currentIdx+1); return; }
        if (lastSuccessUrl!=null) { for(int i=0;i<variants.size();i++) if(lastSuccessUrl.equals(variants.get(i).url)){playVariant(i);return;} }
        showAllFailed();
    }
    private void showAllFailed()    { showAllFailed(""); }
    private void showAllFailed(String detail) { loadingView.setVisibility(View.GONE); errorContainer.setVisibility(View.VISIBLE); errorText.setText("All "+variants.size()+" source(s) failed"+(detail.isEmpty()?"":" · "+detail)); }
    private void showStreamFailed() { showStreamFailed(""); }
    private void showStreamFailed(String detail) { loadingView.setVisibility(View.GONE); errorContainer.setVisibility(View.VISIBLE); errorText.setText("Stream failed"+(detail.isEmpty()?"":" · "+detail)); }
    private void startFailoverTimeout() {
        cancelFailoverTimeout();
        failoverTimeoutRunnable = ()->{
            if(player!=null&&player.getPlaybackState()==Player.STATE_BUFFERING&&!locked&&foAuto&&networkAvailable&&System.currentTimeMillis()-playbackStartTime>8000) {
                showMsg("Buffering too long — trying next source"); tryNextVariant();
            }
        };
        handler.postDelayed(failoverTimeoutRunnable,foTimeoutMs);
    }
    private void cancelFailoverTimeout() { if(failoverTimeoutRunnable!=null) handler.removeCallbacks(failoverTimeoutRunnable); }

    // ─── Strength Monitor ────────────────────────────────────────────────────
    private void startStrengthMonitor() {
        strengthUpdater = new Runnable() {
            @Override public void run() {
                if (player!=null&&player.getPlaybackState()==Player.STATE_READY) {
                    long bitrate=0; Format vf=player.getVideoFormat();
                    if (vf!=null&&vf.bitrate>0) bitrate=vf.bitrate;
                    long buffMs=player.getBufferedPosition()-player.getCurrentPosition();
                    String bps=bitrate>0?(bitrate/1000)+"kbps":"";
                    String buf=buffMs>0?(buffMs/1000)+"s buf":"";
                    String label; int color;
                    if (buffMs>10000&&bitrate>2000000){label="●●●● Excellent";color=Color.parseColor("#2ed573");}
                    else if(buffMs>5000&&bitrate>1000000){label="●●●○ Good";color=Color.parseColor("#2ed573");}
                    else if(buffMs>2000){label="●●○○ Fair";color=Color.parseColor("#ffa502");}
                    else {label="●○○○ Weak";color=Color.parseColor("#ff4757");}
                    String disp=label; if(!bps.isEmpty())disp+=" · "+bps; if(!buf.isEmpty())disp+=" · "+buf;
                    strengthText.setText(disp); strengthText.setTextColor(color);

                    // Update timeshift offset
                    if (timeshiftPaused) {
                        timeshiftOffset=System.currentTimeMillis()-timeshiftPausedAt;
                        updateTimeshiftUI();
                    }
                }
                if (recording&&recordingStartTime>0) {
                    long el=(System.currentTimeMillis()-recordingStartTime)/1000;
                    recStatusText.setText("⏺ REC "+String.format(Locale.US,"%02d:%02d",el/60,el%60));
                } else recStatusText.setText("");
                handler.postDelayed(this,2000);
            }
        };
        handler.postDelayed(strengthUpdater,3000);
    }

    // ─── WiFi Lock & Live Keep-Alive ─────────────────────────────────────────
    private void acquireWifiLock() {
        try {
            if (wifiLock == null) {
                WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
                if (wm != null) {
                    wifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "StreamVault:stream");
                }
            }
            if (wifiLock != null && !wifiLock.isHeld()) wifiLock.acquire();
        } catch (Exception ignored) {}
    }
    private void releaseWifiLock() {
        try { if (wifiLock != null && wifiLock.isHeld()) wifiLock.release(); } catch (Exception ignored) {}
    }
    /** Periodic keep-alive: for live ITV, nudge ExoPlayer every 8 min to prevent
     *  Android network idle timeout from stalling the connection silently. */
    private void startLiveKeepAlive() {
        stopLiveKeepAlive();
        if (!isIptvItem()) return;
        liveKeepAlive = new Runnable() {
            @Override public void run() {
                if (player != null && player.getPlaybackState() == Player.STATE_READY && player.isPlaying()) {
                    // Poke ExoPlayer — get buffered position to force internal activity check
                    long buf = player.getBufferedPosition();
                    long pos = player.getCurrentPosition();
                    // If buffered position hasn't advanced beyond current in a stuck window, retry
                    if (buf > 0 && pos > 0 && buf <= pos + 500) {
                        // Looks stalled despite STATE_READY — soft reconnect
                        if (!locked && foAuto && networkAvailable) {
                            showMsg("Auto-recovering stalled stream…");
                            tryNextVariant();
                            return;
                        }
                    }
                    acquireWifiLock();
                }
                handler.postDelayed(this, 8 * 60 * 1000L); // every 8 minutes
            }
        };
        handler.postDelayed(liveKeepAlive, 8 * 60 * 1000L);
    }
    private void stopLiveKeepAlive() {
        if (liveKeepAlive != null) { handler.removeCallbacks(liveKeepAlive); liveKeepAlive = null; }
    }

    // ─── Network ─────────────────────────────────────────────────────────────
    private void registerNetworkCallback() {
        if (Build.VERSION.SDK_INT>=Build.VERSION_CODES.N) {
            try {
                ConnectivityManager cm=(ConnectivityManager)getSystemService(Context.CONNECTIVITY_SERVICE);
                networkCallback=new ConnectivityManager.NetworkCallback(){
                    @Override public void onAvailable(Network n){handler.post(()->{boolean was=!networkAvailable;networkAvailable=true;if(was&&player!=null&&player.getPlaybackState()==Player.STATE_IDLE){showMsg("Network restored");playVariant(currentIdx);}});}
                    @Override public void onLost(Network n){handler.post(()->{networkAvailable=false;cancelFailoverTimeout();showMsg("Network lost");});}
                };
                cm.registerNetworkCallback(new NetworkRequest.Builder().addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET).build(),networkCallback);
            } catch(Exception ignored){}
        }
    }

    // ─── UI helpers ──────────────────────────────────────────────────────────
    private void updatePlayPauseIcon() {
        // sv-plex: black icon on white oval button
        if (playPauseBtn == null) return;
        boolean playing = (player != null && player.isPlaying()) || timeshiftPaused;
        playPauseBtn.setImageResource(playing
            ? android.R.drawable.ic_media_pause
            : android.R.drawable.ic_media_play);
        playPauseBtn.setColorFilter(android.graphics.Color.BLACK);
    }
    private void toggleOverlay()    { setOverlayVisible(!overlayVisible); if(overlayVisible)scheduleHideOverlay(); }
    private void showOverlayBriefly(){ setOverlayVisible(true); scheduleHideOverlay(); }
    private void setOverlayVisible(boolean v) {
        overlayVisible = v;
        float a = v ? 1f : 0f;
        overlayTop.animate().alpha(a).setDuration(200).start();
        overlayCenter.animate().alpha(a).setDuration(200).start();
        overlayBottom.animate().alpha(a).setDuration(200).start();
        if (v) startProgressUpdater();
        else   handler.removeCallbacks(progressUpdater != null ? progressUpdater : ()->{});
    }

    private void startProgressUpdater() {
        if (progressUpdater == null) {
            progressUpdater = new Runnable() {
                @Override public void run() {
                    if (player != null && vodSeekBar != null && overlayVisible && isSeekable()) {
                        long pos = player.getCurrentPosition();
                        long dur = player.getDuration();
                        int maxSec = (int)(dur / 1000);
                        vodSeekBar.setMax(maxSec > 0 ? maxSec : 1);
                        vodSeekBar.setProgress((int)(pos / 1000));
                        if (vodElapsed   != null) vodElapsed.setText(formatTime(pos));
                        if (vodRemaining != null) vodRemaining.setText("-" + formatTime(dur - pos));
                        if (vodProgressRow != null) vodProgressRow.setVisibility(View.VISIBLE);
                    } else if (vodProgressRow != null && !isSeekable()) {
                        vodProgressRow.setVisibility(View.GONE);
                    }
                    if (overlayVisible) handler.postDelayed(this, 500);
                }
            };
        }
        handler.removeCallbacks(progressUpdater);
        handler.post(progressUpdater);
    }
    private void scheduleHideOverlay(){ handler.removeCallbacks(hideOverlayRunnable); handler.postDelayed(hideOverlayRunnable,4000); }
    private void showMsg(String msg) { runOnUiThread(()->Toast.makeText(this,msg,Toast.LENGTH_SHORT).show()); }
    private void hideSystemUI() {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE|View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION|
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN|View.SYSTEM_UI_FLAG_HIDE_NAVIGATION|
            View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    }
    private void releasePlayer() { if(player!=null){player.stop();player.release();player=null;} }
    private int dp(int v) { return (int)(v*getResources().getDisplayMetrics().density); }
    private FrameLayout.LayoutParams matchParent() { return new FrameLayout.LayoutParams(-1,-1); }
    private FrameLayout.LayoutParams centered(int w,int h) { return new FrameLayout.LayoutParams(w,h,Gravity.CENTER); }
    private ImageButton makeButton(int res) { ImageButton b=new ImageButton(this); b.setImageResource(res); b.setColorFilter(Color.WHITE); b.setBackgroundColor(Color.TRANSPARENT); b.setPadding(dp(8),dp(8),dp(8),dp(8)); return b; }
    private TextView makeLabel(int sp, int color, boolean bold) { TextView t=new TextView(this); t.setTextColor(color); t.setTextSize(sp); t.setSingleLine(true); if(bold)t.setTypeface(null,Typeface.BOLD); return t; }

    // ─── Lifecycle ───────────────────────────────────────────────────────────
    @Override public void onBackPressed() { recording=false; finish(); }
    @Override protected void onResume() {
        super.onResume();
        hideSystemUI();
        // Resume playback unless user explicitly paused or timeshift is paused
        if (player != null && !userExplicitPause && !timeshiftPaused) {
            player.play();
            updatePlayPauseIcon();
        }
    }
    @Override protected void onPause() {
        // For ITV live streams, don't auto-pause on activity focus loss (notifications, overlays etc.)
        // Only pause if user explicitly pressed pause, or if it's a VOD/Plex item
        if (player != null && (!isIptvItem() || userExplicitPause)) {
            player.pause();
        }
        super.onPause();
    }
    @Override protected void onDestroy() {
        recording=false; stopTimeshiftBuffer(); stopLiveKeepAlive(); stopPositionReporter(); releaseWifiLock();
        if(handler!=null) handler.removeCallbacksAndMessages(null);
        releasePlayer();
        if (Build.VERSION.SDK_INT>=Build.VERSION_CODES.N&&networkCallback!=null) {
            try { ConnectivityManager cm=(ConnectivityManager)getSystemService(Context.CONNECTIVITY_SERVICE); cm.unregisterNetworkCallback(networkCallback); } catch(Exception ignored){}
        }
        super.onDestroy();
    }

    private void doPlayPause() {
        if (timeshiftPaused) { resumeTimeshift(); userExplicitPause=false; }
        else if (player!=null) {
            if (player.isPlaying()) { player.pause(); userExplicitPause=true; }
            else                    { player.play();  userExplicitPause=false; }
            updatePlayPauseIcon();
        }
    }

    @Override public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getAction() != KeyEvent.ACTION_DOWN) return super.dispatchKeyEvent(event);
        int kc = event.getKeyCode();
        boolean seekable = isSeekable();
        boolean itv = isIptvItem();

        switch (kc) {
            case KeyEvent.KEYCODE_BACK: finish(); return true;

            case KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE:
                doPlayPause(); return true;

            case KeyEvent.KEYCODE_MEDIA_RECORD: case 183:
                toggleRecording(); return true;

            // Hardware FF/RW — seek for VOD/Plex; for ITV these switch sources (existing behavior kept)
            case KeyEvent.KEYCODE_MEDIA_FAST_FORWARD:
                if (seekable) { seekRelative(30000); setOverlayVisible(true); scheduleHideOverlay(); }
                else if (itv)  { playNextVariant(); }
                return true;
            case KeyEvent.KEYCODE_MEDIA_REWIND:
                if (seekable) { seekRelative(-30000); setOverlayVisible(true); scheduleHideOverlay(); }
                else if (itv)  { playPreviousVariant(); }
                return true;

            case KeyEvent.KEYCODE_DPAD_CENTER: case KeyEvent.KEYCODE_ENTER: case KeyEvent.KEYCODE_NUMPAD_ENTER:
                if (!overlayVisible) {
                    // First press — show overlay only
                    setOverlayVisible(true); scheduleHideOverlay();
                } else {
                    // Already visible — play/pause
                    doPlayPause(); scheduleHideOverlay();
                }
                return true;

            case KeyEvent.KEYCODE_DPAD_LEFT:
                if (!overlayVisible) { setOverlayVisible(true); scheduleHideOverlay(); return true; }
                if (seekable)        { seekRelative(-10000); scheduleHideOverlay(); }
                else if (itv)        { playPreviousVariant(); scheduleHideOverlay(); }
                return true;

            case KeyEvent.KEYCODE_DPAD_RIGHT:
                if (!overlayVisible) { setOverlayVisible(true); scheduleHideOverlay(); return true; }
                if (seekable)        { seekRelative(10000); scheduleHideOverlay(); }
                else if (itv)        { playNextVariant(); scheduleHideOverlay(); }
                return true;

            case KeyEvent.KEYCODE_DPAD_UP:
                if (!overlayVisible) { setOverlayVisible(true); scheduleHideOverlay(); return true; }
                if (seekable)        { seekRelative(-30000); scheduleHideOverlay(); }
                else if (itv && timeshiftEnabled && !timeshiftPaused) { pauseTimeshift(); }
                else                 { setOverlayVisible(false); }
                return true;

            case KeyEvent.KEYCODE_DPAD_DOWN:
                if (!overlayVisible) { setOverlayVisible(true); scheduleHideOverlay(); return true; }
                if (seekable)        { seekRelative(30000); scheduleHideOverlay(); }
                else if (itv && timeshiftPaused) { jumpToLive(); }
                else                 { setOverlayVisible(false); }
                return true;
        }
        return super.dispatchKeyEvent(event);
    }
}
