# Feature Parity Report — 2026-02-03
## WebServer v8.6.0.2 (build 57) vs Android v6.0.0 (build 40)

### WebServer Changes Since Last Android Parity Sync

| WS Version | Feature | Android Status | Priority |
|------------|---------|----------------|----------|
| 8.6.0 | Settings → Display: **Show UI error log** toggle (default OFF). When enabled, JS... | Not implemented | Review |
| 8.6.0 | **Custom Set Settings full-page view:** Custom Set Settings converted from a mod... | Not implemented | Review |
| 8.6.0 | **Manage Cards collapsible panes:** In Custom Set → Manage Cards, both "In Custo... | Not implemented | Review |
| 8.6.0 | Faster initial load after login: settings + decks now load in parallel; counts +... | Not implemented | Review |
| 8.6.0 | **Portrait Study action row stabilized:** Prev / Speak / Custom / Next are force... | Not implemented | Review |
| 8.6.0 | **Breakdown button relocated (portrait):** breakdown action moved to the header ... | Not implemented | Review |
| 8.6.0 | **Portrait alignment tweaks:** reduced card-area side padding to the left edge i... | Not implemented | Review |
| 8.6.0 | **Confirmation visuals standardized:** **✓** for success, **✖** for error. Admin... | Not implemented | Review |
| 8.6.0 | **Custom Set study label shows filter mode:** status bar now shows "Studying: Un... | Not implemented | Review |
| 8.6.0 | Custom Sets and Saved Sets are now **deck-scoped** (no cross-deck leakage when s... | Not implemented | Review |
| 8.6.0 | Custom Set Study view uses only the active deck's Custom Set (star tab no longer... | Not implemented | Review |
| 8.6.0 | **Custom-marked cards now appear in Custom Set:** starred/custom cards are corre... | Not implemented | Review |
| 8.6.0 | **Custom Set random count input overlap fixed:** `.csRandomInput` now overrides ... | Not implemented | Review |
| 8.6.0 | **Manage Cards lists taller:** increased `.csCardList` height to show more cards... | Not implemented | Review |
| 8.6.0 | **Breakdown save closes modal:** saving a breakdown now closes the breakdown win... | Not implemented | Review |
| 8.6.0 | **Custom Set → Manage Cards responsive layout:** prevented overflow/misalignment... | Not implemented | Review |
| 8.6.0 | **Admin confirmations auto-clear:** "Access granted/denied" and "Deck transferre... | Not implemented | Review |
| 8.6.0 | **Correct icons for errors:** "Access denied" (and other error confirmations) no... | Not implemented | Review |
| 8.6.0 | **Custom Set counts showing 0/0/0:** backend API now returns `counts` object wit... | Not implemented | Review |
| 8.6.0 | **Settings tab empty on first open:** Custom Set Settings tab was blank when ope... | Not implemented | Review |
| 8.6.0 | **Custom Set modal overflow on mobile:** converted from modal overlay (which use... | Not implemented | Review |
| 8.6.0 | **Landscape accordion not triggering:** `max-width: 720px` media query missed la... | Not implemented | Review |
| 8.5.3 | **Admin User Deck Access simplified:** removed Disable/Enable Built-In for User ... | Not implemented | Review |
| 8.5.3 | **Allow/Deny preserves dropdowns:** clicking Allow or Deny no longer triggers a ... | Not implemented | Review |
| 8.5.3 | **Non-admin built-in editing off by default:** `allowNonAdminDeckEdits` now defa... | Not implemented | Review |
| 8.5.3 | **Deck Ownership blank state:** "Current owner" line is now hidden when no deck ... | Not implemented | Review |
| 8.5.3 | **Portrait card layout overhaul:** card height increased from 260px to 320px (28... | Not implemented | Review |
| 8.5.3 | **Status line inline with Card counter:** "All (flat) • Studying: X" text now ap... | Not implemented | Review |
| 8.5.3 | **Landscape controls compact:** group dropdown, All Cards, and search icon reduc... | Not implemented | Review |
| 8.5.3 | **Breakdown text overflow in portrait:** card faces now have `overflow-y: auto`,... | Not implemented | Review |
| 8.5.3 | **Built-in status showing incorrectly:** previously showed "✓ Built-in active" e... | Not implemented | Review |
| 8.5.2 | **File-based logging system:** server.log, error.log, and user_activity.log now ... | Not implemented | Review |
| 8.5.2 | **Log rotation on startup:** server.log and error.log are automatically rotated ... | Not implemented | Review |
| 8.5.2 | **Log download endpoint:** `/api/admin/logs/download` serves log files for downl... | N/A (server-only) | Skip |
| 8.5.2 | **Expandable admin stat tiles:** clicking any stat card (Users, Cards, Decks, Br... | Not implemented | Review |
| 8.5.2 | **Deck Short Answers mode:** new per-deck toggle (`⚙️ Deck AI Settings` section ... | Not implemented | Review |
| 8.5.2 | **Deck settings API:** `GET/POST /api/decks/<deck_id>/settings` for per-deck con... | Not implemented | Review |
| 8.5.2 | **AI generation context-aware:** AI no longer assumes foreign language vocabular... | Not implemented | Review |
| 8.5.2 | **Add Card pre-selects active deck:** Target Deck dropdown in "Add Cards" tab no... | Not implemented | Review |
| 8.5.2 | **Custom Set counts reflect custom status:** when studying a Custom Set, the Unl... | Not implemented | Review |
| 8.5.2 | **Random card input narrower:** "Pick random cards to add" number field reduced ... | Not implemented | Review |
| 8.5.2 | **Custom Set Manage Cards / Saved Sets tabs blank:** tabs appeared empty because... | Not implemented | Review |
| 8.5.2 | **Admin logs empty on fresh start:** logs were purely in-memory and lost on rest... | Not implemented | Review |
| 8.5.1 | **Controls row rearranged:** group dropdown + All Cards on the left, search icon... | Not implemented | Review |
| 8.5.1 | **Settings icon moved to title row:** ⚙️ button now sits directly right of User:... | Not implemented | Review |
| 8.5.1 | **Study/Group label hidden:** "Study / Group" label text removed on mobile (≤600... | Not implemented | Review |
| 8.5.1 | **Landscape group sizing:** "Select group..." dropdown matches "All Cards" butto... | Not implemented | Review |
| 8.5.1 | **Desktop search icon:** search bar replaced with 🔍 icon on all screen sizes; ex... | Not implemented | Review |
| 8.5.1 | **Portrait controls layout:** group dropdown auto-width on left, All Cards + 🔍 p... | Not implemented | Review |
| 8.5.1 | **Landscape controls right-aligned:** controls row pushed to right side of scree... | Not implemented | Review |
| 8.5.1 | **Mobile logo inline:** deck logo displays inline between Cards loaded and User ... | Not implemented | Review |
| 8.5.1 | **CSS selector fix:** corrected `.selectBtn` → `.select` to match actual HTML cl... | Not implemented | Review |
| 8.5.1 | **Removed stale `.rightControls`:** cleaned up all references to the removed rig... | Not implemented | Review |
| 8.5.1 | **Edit User deck access API:** fixed URL mismatch (`/api/admin/user/deck_access?... | Not implemented | Review |
| 8.5.1 | **Edit User field name mismatch:** JS used `userDecks`/`grantedAdminDeckIds` but... | Not implemented | Review |
| 8.5.1 | **Owned decks show 0 cards:** backend now includes `cardCount` in deck-access en... | Not implemented | Review |
| 8.5.1 | **Edit User modal wider:** max-width increased from 700px to 900px; deck columns... | Not implemented | Review |
| 8.5.1 | **Edit User deck access read-only:** removed checkboxes; shows Granted/Not grant... | Not implemented | Review |
| 8.5.1 | **renderBuiltInDecks syntax:** fixed nested function causing potential JS errors... | Not implemented | Review |
| 8.5.1 | **Allow/Deny buttons:** replaced Unlock/Lock buttons with Allow/Deny + static "A... | Not implemented | Review |
| 8.5.1 | **Live access status indicators:** selecting user + deck shows current access st... | Not implemented | Review |
| 8.5.1 | **Built-in status badge:** shows ⛔ or ✓ next to Disable/Enable Built-In buttons. | Not implemented | Review |
| 8.5.1 | **Deck Ownership section:** new Admin > Decks > Deck Ownership panel to transfer... | Not implemented | Review |
| 8.5.1 | **`/api/admin/deck-ownership` endpoint:** transfers deck cards and metadata to n... | Not implemented | Review |
| 8.5.1 | **`/api/admin/user-deck-status` endpoint:** returns access status for user+deck ... | Not implemented | Review |
| 8.5.0 | **Portrait responsive controls:** study controls (group dropdown, All Cards, sea... | Not implemented | Review |
| 8.5.0 | **Landscape responsive controls:** all controls fit in one row without wrapping ... | Not implemented | Review |
| 8.5.0 | **Settings toggle behavior:** settings button toggles open/close. Close button (... | Not implemented | Review |
| 8.5.0 | **Search bar → icon toggle:** search is now a 🔍 icon that expands an overlay inp... | Not implemented | Review |
| 8.5.0 | **Saved Breakdowns moved to More:** 🧩 Saved Breakdowns relocated from main contr... | Not implemented | Review |
| 8.5.0 | **Got it button shortened:** "Got it ✓ (mark learned)" → "Got it ✓". | Not implemented | Review |
| 8.5.0 | **Breakdown card button compact:** stays small and fixed next to Next in portrai... | Not implemented | Review |
| 8.5.0 | **Admin users table (mobile):** "Currently Studying" column hidden on ≤768px; mo... | Not implemented | Review |
| 8.5.0 | **Deck list badges (mobile):** icon-only (📦🔓👥★) on portrait. | Not implemented | Review |
| 8.5.0 | **Deck list actions (portrait):** stack vertically with top border separator. | Not implemented | Review |
| 8.5.0 | **Deck list items (portrait):** flex-wrap layout with smaller logo (28px). | Not implemented | Review |
| 8.5.0 | **Landscape card height:** reduced to 180px. | Not implemented | Review |
| 8.4.0 | **Remember me functionality**: Sessions now persist for 30 days and refresh on e... | Not implemented | Review |
| 8.4.0 | **Mobile responsive design**: Comprehensive CSS media queries for tablet (≤900px... | Not implemented | Review |
| 8.4.0 | **Admin edit built-in decks**: Administrators can now edit built-in decks (like ... | Not implemented | Review |
| 8.4.0 | **Deck logo**: Reduced size by ~15% (98px → 83px) and removed transform that cau... | Not implemented | Review |
| 8.4.0 | **Deck title**: Now truncates with ellipsis (...) when too long, preventing layo... | Not implemented | Review |
| 8.4.0 | **Edit User modal**: Increased width from 500px to 700px for better visibility o... | Not implemented | Review |
| 8.4.0 | **Admin page**: Added mobile responsive styles for tabs, stats grid, AI grid, an... | Not implemented | Review |
| 8.4.0 | **Duplicate `updateHeaderDeckLogo()` call** in postLoginInit that could cause un... | Not implemented | Review |
| 8.4.0 | **Mobile layout issues**: Controls, tabs, cards, and modals now properly stack a... | Not implemented | Review |
| 8.4.0 | **Edit User modal overflow**: Deck access lists now properly scroll and columns ... | Not implemented | Review |
| 8.3.0 | **Runtime paths module** (`runtime/app_paths.py`) to centrally control writable ... | N/A (server-only) | Skip |
| 8.3.0 | **Environment overrides** for advanced/portable setups: | Not implemented | Review |
| 8.3.0 | `KENPO_APPDATA_BASE_DIR` (override base AppData folder) | N/A (server-only) | Skip |
| 8.3.0 | `KENPO_DATA_DIR` / `KENPO_LOG_DIR` (explicit overrides) | N/A (server-only) | Skip |
| 8.3.0 | **First-run data seeding** for packaged installs: if the user’s AppData `data\` ... | N/A (server-only) | Skip |
| 8.3.0 | **Runtime import-path resiliency for frozen builds (tray/service) to reduce inst... | N/A (server-only) | Skip |
| 8.3.0 | **DATA_DIR / LOG_DIR resolution now uses the runtime module**: | N/A (server-only) | Skip |
| 8.3.0 | Dev/source run: project-local `./data` and `./logs` | Not implemented | Review |
| 8.3.0 | Packaged/frozen run: `%LOCALAPPDATA%\Advanced Flashcards WebApp Server\{data,log... | N/A (server-only) | Skip |
| 8.3.0 | **Removed/neutralized legacy duplicated `LOG_DIR`/`DATA_DIR` definitions in `app... | N/A (server-only) | Skip |
| 8.3.0 | **Permission errors when installed under `C:\Program Files\...`** by ensuring al... | N/A (server-only) | Skip |
| 8.3.0 | **Server logging reliability**: `server.log` consistently initializes in the wri... | N/A (server-only) | Skip |
| 8.3.0 | **Corrected indentation issue in internal\app.py that could prevent startup in p... | N/A (server-only) | Skip |
| 8.3.0 | **Resolved missing module error (runtime) by ensuring runtime\ is included in th... | N/A (server-only) | Skip |
| 8.3.0 | **Updated kenpo_tray.spec and kenpo_server.spec to bundle the runtime package in... | N/A (server-only) | Skip |
| 8.2.0 | Packaged install marker: include `data/install_type.txt` (set to `packaged`) so ... | N/A (server-only) | Skip |
| 8.2.0 | Admin > Decks: add built-in decks back via dropdown + **Add Built-In** action. | Not implemented | Review |
| 8.2.0 | Admin > User Deck Access: show access status for the selected user + deck and en... | Not implemented | Review |
| 8.2.0 | Login UI: show version/build on the login panel; add password-reset fields for u... | Not implemented | Review |
| 8.2.0 | Create Deck: choose an add-cards method (Keyword/Photo/Document) directly under ... | Not implemented | Review |
| 8.2.0 | Startup runner: print a clear `[READY]` line indicating the local + LAN URLs onc... | N/A (server-only) | Skip |
| 8.2.0 | Logging: write persistent logs to `logs/server.log` and `logs/error.log` under t... | Not implemented | Review |
| 8.2.0 | Create Deck (Keyword method): auto-search uses deck name + description; default ... | Not implemented | Review |
| 8.2.0 | Packaged-only display: Web Server Version appears in User menu, About, and Admin... | N/A (server-only) | Skip |
| 8.2.0 | Custom Set Randomization layout: shorter number field and renamed button to **Ad... | Not implemented | Review |
| 8.2.0 | Forced password reset: login flow communicates password-change-required and guid... | Not implemented | Review |
| 8.2.0 | Admin dashboard: fix JavaScript parse errors and show a friendly message when `l... | Not implemented | Review |
| 8.2.0 | Web UI boot: ensure the app initializes on page load so login/deck loading runs ... | Not implemented | Review |
| 8.2.0 | Web UI: fix `app.js` syntax issues that could prevent the entire UI from running... | N/A (server-only) | Skip |
| 8.2.0 | Documentation and version metadata updated for 8.2.0 (build 50). | Not implemented | Review |
| 8.1.1 | Fix: Admin deck dropdowns now populate correctly (stats includes full deck list ... | Not implemented | Review |
| 8.1.1 | Fix: Deck ownership/access logic (owned vs shared) and Edit/Delete button visibi... | Not implemented | Review |
| 8.1.1 | Fix: Forced password reset now blocks access until changed; Web UI prompts immed... | Not implemented | Review |
| 8.1.1 | Add: Create Deck flow can jump directly into adding cards (Keywords auto-generat... | Not implemented | Review |
| 8.1.1 | Fix: AI generator resets keywords + max cards (25) after adding cards. | Not implemented | Review |
| 8.1.1 | Improve: Admin Overview tiles are clickable with detail modals; System page serv... | Not implemented | Review |
| 8.1.1 | Improve: Server/App/User logging feeds Admin > Logs more reliably. | Not implemented | Review |
| 8.1.1 | (Add changes here as you work. Move them into a release when you publish.) | Not implemented | Review |
| 8.1.1 | Kenpo vocab now loads from `data/kenpo_words.json` by default (docs + config upd... | Not implemented | Review |
| 8.1.0 | **Added GEN8 Token Admin Namespace for Android | Not implemented | Review |
| 8.1.0 | **Token admin endpoints** for deck access management under `/api/sync/admin/...`... | Not implemented | Review |
| 8.1.0 | **Invite code redemption** endpoint for Android: `POST /api/sync/redeem-invite-c... | Not implemented | Review |
| 8.1.0 | **Docs updates**: README now explicitly documents the token admin namespace and ... | Not implemented | Review |
| 8.1.0 | **Admin per-user sharing controls**: in **Admin → Users → Edit User**, admins ca... | Not implemented | Review |
| 8.1.0 | **Fixed Sync → Pull returning 500 Internal Server Error when user progress data ... | Not implemented | Review |
| 8.1.0 | **Fixed Admin → Users → Edit User → Deck Access failing to load (brief “Not Foun... | Not implemented | Review |
| 8.1.0 | **GET /api/admin/user/deck_access?user_id=<id> | Not implemented | Review |
| 8.1.0 | **POST /api/admin/user/deck_access?user_id=<id> | Not implemented | Review |
| 8.1.0 | **Improved header layout stability by preventing the deck logo/user area from sh... | Not implemented | Review |
| 8.1.0 | **Optional: adjusted deck logo vertical alignment to better line up with the “Us... | Not implemented | Review |
| 8.0.2 | **Deck ownership is enforced**: user-created study decks are now unique to the c... | Not implemented | Review |
| 8.0.2 | **Admin “Reset Password” now works**: reset uses a login-compatible password has... | Not implemented | Review |
| 8.0.2 | **Deck card storage for shared decks**: cards for user-created decks are stored ... | Not implemented | Review |
| 8.0.2 | **Safety + permissions**: only the deck owner/admin can edit/delete a user-creat... | Not implemented | Review |
| 8.0.2 | This release carries forward the **v8.0.2 (build 47)** deck ownership enforcemen... | Not implemented | Review |
| 8.0.1 | **Deck icons in “Switch Study Subject”**: each deck now displays a small logo ic... | Not implemented | Review |
| 8.0.1 | **Study page header logo** is ~25% larger and spacing/placement was adjusted to ... | Not implemented | Review |
| 8.0.1 | **Default deck honored on refresh**: fixed `/api/settings` GET route registratio... | Not implemented | Review |
| 8.0.1 | **Deck header logos** now render correctly on the Study page (missing header `<i... | Not implemented | Review |
| 8.0.1 | **Per-deck logo isolation**: changing a deck’s logo (uploading an image or choos... | Not implemented | Review |
| 8.0.1 | **Refresh + deck switch correctness**: the active deck and its logo now load con... | Not implemented | Review |
| 8.0.1 | Logo refresh now runs on initial load and when switching/loading decks. | Not implemented | Review |
| 8.0.1 | Decks with no assigned logo now fall back to `/res/decklogos/advanced_flashcards... | Not implemented | Review |
| 8.0.1 | **Immediate logo updates**: added cache-busting on deck logo URLs so newly-uploa... | Not implemented | Review |
| 8.0.0 | **Major rebrand**: internal project name is now **Advanced Flashcards WebAppServ... | Not implemented | Review |
| 8.0.0 | **WebApp icons**: new dedicated path `static/res/webappicons/` with updated favi... | Not implemented | Review |
| 8.0.0 | **Deck logos (optional)**: support for per-deck logos with default fallback to t... | Not implemented | Review |
| 8.0.0 | Updated user-facing text from “Kenpo Flashcards” → “Advanced Flashcards WebApp” ... | Not implemented | Review |
| 7.3.0 | **Deck Access Management System**: | Not implemented | Review |
| 7.3.0 | Built-in decks can be disabled/enabled per user | Not implemented | Review |
| 7.3.0 | Invite codes to unlock specific decks for users | Not implemented | Review |
| 7.3.0 | Admin can manually unlock/lock decks for specific users | Not implemented | Review |
| 7.3.0 | New users can be set to start with blank app (no decks) | Not implemented | Review |
| 7.3.0 | Settings to control whether non-admins can edit built-in/unlocked decks | Not implemented | Review |
| 7.3.0 | **Admin Dashboard - Decks Tab**: | Not implemented | Review |
| 7.3.0 | Global deck settings (new users get built-in, allow non-admin edits) | Not implemented | Review |
| 7.3.0 | Built-in deck management with remove option | Not implemented | Review |
| 7.3.0 | Invite code generation and management | Not implemented | Review |
| 7.3.0 | User-specific deck access controls | Not implemented | Review |
| 7.3.0 | **Deck Access Types Displayed**: | Not implemented | Review |
| 7.3.0 | 📦 Built-in (comes with app) | Not implemented | Review |
| 7.3.0 | 🔓 Unlocked (via invite code or admin) | Not implemented | Review |
| 7.3.0 | Owned (user-created) | Not implemented | Review |
| 7.3.0 | **Clear Default Deck**: Can now remove default status from a deck (star button w... | Not implemented | Review |
| 7.3.0 | **Invite Code Redemption**: Users can enter codes in Edit Decks > Switch tab | Not implemented | Review |
| 7.3.0 | `_load_decks()` now respects user access permissions | Not implemented | Review |
| 7.3.0 | Deck list shows access type badges | Not implemented | Review |
| 7.3.0 | Admin stats use `include_all=True` to see all decks | Not implemented | Review |
| 7.3.0 | New files: `data/deck_config.json`, `data/deck_access.json` | Not implemented | Review |
| 7.3.0 | New API endpoints: | Not implemented | Review |
| 7.3.0 | `GET/POST /api/admin/deck-config` | Not implemented | Review |
| 7.3.0 | `POST /api/admin/deck-invite-code` | Not implemented | Review |
| 7.3.0 | `DELETE /api/admin/deck-invite-code/<code>` | Not implemented | Review |
| 7.3.0 | `POST /api/admin/user-deck-access` | Not implemented | Review |
| 7.3.0 | `POST /api/redeem-invite-code` | Not implemented | Review |
| 7.3.0 | `POST /api/decks/<id>/clear_default` | Not implemented | Review |
| 7.2.1 | **Custom Set Modal Redesign**: | Not implemented | Review |
| 7.2.1 | Fixed modal size (700px width, 500px min-height) - no more resizing between tabs | Not implemented | Review |
| 7.2.1 | Split-pane Manage Cards tab: "In Custom Set" on left, "Available Cards" on right | Not implemented | Review |
| 7.2.1 | Search filtering for both card lists | Not implemented | Review |
| 7.2.1 | Click cards to toggle selection, or use checkboxes | Not implemented | Review |
| 7.2.1 | Add/Remove buttons between panes for easy bulk management | Not implemented | Review |
| 7.2.1 | Saved Sets now show "Active" status with switch functionality | Not implemented | Review |
| 7.2.1 | Each saved set stores its own cards, statuses, and settings | Not implemented | Review |
| 7.2.1 | Current set name displayed in modal header | Not implemented | Review |
| 7.2.1 | **Random pick input**: Shortened to 3-digit width, aligned with other settings | Not implemented | Review |
| 7.2.1 | **Saved Sets**: Now properly switch between sets (not just load/replace) | Not implemented | Review |
| 7.2.0 | **Custom Set Management Modal**: New ⚙️ button in Custom Set toggle opens modal ... | Not implemented | Review |
| 7.2.0 | **Settings Tab**: Random order toggle, pick random N cards to add | Not implemented | Review |
| 7.2.0 | **Manage Tab**: Bulk select/edit cards, mark selected learned/unsure, remove sel... | Not implemented | Review |
| 7.2.0 | **Saved Sets Tab**: Save current Custom Set with name, load/delete saved sets | Not implemented | Review |
| 7.2.0 | **Server Activity Logs**: Admin dashboard Logs tab now shows real activity: | Not implemented | Review |
| 7.2.0 | Login/logout events tracked | Not implemented | Review |
| 7.2.0 | Filterable by type (Server, Error, User Activity) | Not implemented | Review |
| 7.2.0 | Download logs as text file | Not implemented | Review |
| 7.2.0 | Clear logs functionality | Not implemented | Review |
| 7.2.0 | **Settings Save Prompt**: When closing settings with unsaved changes, prompts us... | Not implemented | Review |
| 7.2.0 | Moved random cards picker from Custom toggle bar to Custom Set Settings modal | Not implemented | Review |
| 7.2.0 | Settings inputs now track dirty state for save prompt | Not implemented | Review |
| 7.2.0 | Added `ACTIVITY_LOG` in-memory log storage (max 500 entries) | Not implemented | Review |
| 7.2.0 | Added `log_activity()` function for server-side logging | Not implemented | Review |
| 7.2.0 | Added `GET /api/admin/logs` and `POST /api/admin/logs/clear` endpoints | Not implemented | Review |
| 7.2.0 | Added `settingsDirty` flag and `markSettingsDirty()` function | Not implemented | Review |
| 7.2.0 | Saved Custom Sets stored in localStorage under `kenpo_saved_custom_sets` | Not implemented | Review |
| 7.1.0 | **Web Sync Endpoints**: `/api/web/sync/push` and `/api/web/sync/pull` for sessio... | Not implemented | Review |
| 7.1.0 | **Breakdown Indicator**: Puzzle icon (🧩) turns blue when card has breakdown data | Not implemented | Review |
| 7.1.0 | **Breakdown IDs API**: `GET /api/breakdowns/ids` - lightweight endpoint returnin... | Not implemented | Review |
| 7.1.0 | **Enhanced User Stats**: Admin stats now include per-user progress %, current de... | Not implemented | Review |
| 7.1.0 | **Deck Stats**: Admin dashboard shows total decks and user-created count | Not implemented | Review |
| 7.1.0 | **Admin Dashboard Redesigned**: | Not implemented | Review |
| 7.1.0 | Tabbed interface: Overview, Users, System, Logs | Not implemented | Review |
| 7.1.0 | Removed About/User Guide links (accessible from main app) | Not implemented | Review |
| 7.1.0 | Users table shows progress bars, active deck, last sync | Not implemented | Review |
| 7.1.0 | Admin badge (👑) next to admin usernames | Not implemented | Review |
| 7.1.0 | **Admin Stats API**: Returns detailed per-user info (learned, unsure, active cou... | Not implemented | Review |
| 7.1.0 | **Web Sync**: Push/Pull now works with session authentication (was using Android... | Not implemented | Review |
| 7.1.0 | **Breakdown IDs**: Cards with breakdown data now properly indicated | Not implemented | Review |
| 7.0.7 | **`GET /api/vocabulary`**: Returns kenpo_words.json (canonical source for built-... | Not implemented | Review |
| 7.0.7 | **`GET /api/sync/decks`**: Pull all decks for Android sync (requires auth) | Not implemented | Review |
| 7.0.7 | **`POST /api/sync/decks`**: Push deck changes from Android (requires auth) | Not implemented | Review |
| 7.0.7 | **`GET /api/sync/user_cards`**: Pull user-created cards (requires auth, optional... | Not implemented | Review |
| 7.0.7 | **`POST /api/sync/user_cards`**: Push user cards from Android (requires auth) | Not implemented | Review |
| 7.0.7 | **`DELETE /api/sync/user_cards/<card_id>`**: Delete a user card (requires auth) | Not implemented | Review |
| 7.0.7 | **kenpo_words.json** now stored in `data/` folder as canonical source | Not implemented | Review |
| 7.0.7 | Android app can now sync decks and user cards with web server | Not implemented | Review |
| 7.0.7 | Full cross-platform deck and card sharing | Not implemented | Review |
| 7.0.6 | **Rebranded to "Study Flashcards"**: Generic app name that works for any subject | Not implemented | Review |
| 7.0.6 | **Header shows active deck**: App title now shows "Study Flashcards • [Deck Name... | Not implemented | Review |
| 7.0.6 | **Set Default Deck**: ★ button to set a deck as the default startup deck | Not implemented | Review |
| 7.0.6 | **API endpoint**: `POST /api/decks/:id/set_default` - Sets a deck as default | Not implemented | Review |
| 7.0.6 | **Groups filter respects active deck**: Group dropdown now shows groups from the... | Not implemented | Review |
| 7.0.6 | **Page title**: Changed from "Kenpo Flashcards (Web)" to "Study Flashcards" | Not implemented | Review |
| 7.0.6 | **Deck resets on page refresh**: Now properly loads saved `activeDeckId` before ... | Not implemented | Review |
| 7.0.6 | **Groups showing Kenpo for custom decks**: Groups API now accepts `deck_id` para... | Not implemented | Review |
| 7.0.6 | **Deck switching not fully reloading**: Now reloads groups, counts, cards, and h... | Not implemented | Review |
| 7.0.5 | **🤖 AI Deck Generator**: New tab in Edit Decks to generate flashcards using AI | Not implemented | Review |
| 7.0.5 | **Keywords**: Enter topic/keywords to generate cards (e.g., "Basic Spanish Words... | Not implemented | Review |
| 7.0.5 | **Photo**: Upload image of study material, AI extracts vocabulary | Not implemented | Review |
| 7.0.5 | **Document**: Upload PDF/TXT/MD files, AI creates flashcards from content | Not implemented | Review |
| 7.0.5 | Selection UI: Review generated cards, select which to add | Not implemented | Review |
| 7.0.5 | Max cards configurable 1-200 | Not implemented | Review |
| 7.0.5 | Default keywords: Uses deck name + description if no keywords entered | Not implemented | Review |
| 7.0.5 | **Edit Deck**: ✏️ button to edit deck name and description | Not implemented | Review |
| 7.0.5 | **Logout confirmation**: "Are you sure?" prompt before logging out | Not implemented | Review |
| 7.0.5 | **📖 Comprehensive User Guide**: Complete rewrite with all features documented | Not implemented | Review |
| 7.0.5 | Table of contents with jump links | Not implemented | Review |
| 7.0.5 | Step-by-step instructions for all features | Not implemented | Review |
| 7.0.5 | Tip boxes, warning boxes, and keyboard shortcuts table | Not implemented | Review |
| 7.0.5 | Sections: Getting Started, Study Tabs, Edit Decks, AI Generator, Custom Set, Bre... | Not implemented | Review |
| 7.0.5 | **📱 Interactive About Page**: New tabbed interface | Not implemented | Review |
| 7.0.5 | Overview with version card and quick start | Not implemented | Review |
| 7.0.5 | Features grid with icons | Not implemented | Review |
| 7.0.5 | Technology stack badges | Not implemented | Review |
| 7.0.5 | Changelog summary | Not implemented | Review |
| 7.0.5 | Contact section with email button | Not implemented | Review |
| 7.0.5 | **API endpoints**: | Not implemented | Review |
| 7.0.5 | `POST /api/ai/generate_deck` - Generate cards from keywords, photo, or document | Not implemented | Review |
| 7.0.5 | `POST /api/decks/:id` - Update deck name/description | Not implemented | Review |
| 7.0.5 | **Logout moved to bottom** of user menu with red styling | Not implemented | Review |
| 7.0.5 | **AI definitions context-aware**: Uses deck name/description instead of always "... | Not implemented | Review |
| 7.0.5 | **AI pronunciation**: Now generic, works for any language | Not implemented | Review |
| 7.0.5 | **AI group suggestions**: Now generic, not Kenpo-specific | Not implemented | Review |
| 7.0.5 | **Generate button**: Smaller "🔍 Generate" instead of full text | Not implemented | Review |
| 7.0.5 | **Max cards**: Increased from 50 to 200 | Not implemented | Review |
| 7.0.5 | **Header card count**: Now shows count for active deck (not always 88) | Not implemented | Review |
| 7.0.5 | **Deck switching not working**: Now passes `deck_id` explicitly in all API calls | Not implemented | Review |
| 7.0.5 | **Active deck not loading on startup**: Loads saved `activeDeckId` from settings... | Not implemented | Review |
| 7.0.5 | **Cards not appearing after adding**: Added proper refresh of counts and study d... | Not implemented | Review |
| 7.0.5 | **AI generation errors**: Added detailed server-side logging for debugging | Not implemented | Review |
| 7.0.5 | **Duplicate cards in AI results**: Filters out terms that already exist in deck | Not implemented | Review |
| 7.0.4 | **AI Deck Generator** (initial implementation): Generate flashcards from keyword... | Not implemented | Review |
| 7.0.4 | **User cards in study deck**: User-created cards now merge with built-in cards | Not implemented | Review |
| 7.0.4 | **PDF download**: Replaced with "Print User Guide" button (avoids reportlab comp... | Not implemented | Review |
| 7.0.3 | **Health check**: Now correctly reports Kenpo JSON file status (was always showi... | Not implemented | Review |
| 7.0.3 | **AI card generation**: API keys now loaded from encrypted storage at startup (w... | Not implemented | Review |
| 7.0.3 | **Custom Set random toggle**: Now properly persists when toggled (was not saving... | Not implemented | Review |
| 7.0.3 | **Reshuffle button**: Always visible and properly sized (smaller, inline with to... | Not implemented | Review |
| 7.0.3 | Reshuffle button now works anytime (not just when random is enabled) | Not implemented | Review |
| 7.0.2 | **🎲 Pick Random N**: Click dice button in Custom Set to study random subset of s... | Not implemented | Review |
| 7.0.2 | **User Management Modal**: Click "Total Users" in admin to view/edit all users | Not implemented | Review |
| 7.0.2 | **Admin User Editing**: Grant/revoke admin status, reset passwords | Not implemented | Review |
| 7.0.2 | **Password Reset**: Admins can reset user passwords to default (123456789) with ... | Not implemented | Review |
| 7.0.2 | **System Status Feed**: Activity-style status display in admin dashboard | Not implemented | Review |
| 7.0.2 | **Edit Decks Page**: Now opens correctly (added missing hideAllViews function) | Not implemented | Review |
| 7.0.2 | **PDF Download**: Fixed Internal Server Error (added send_file import) | Not implemented | Review |
| 7.0.2 | **Admin Quick Actions**: Highlight now follows active tab (Health/Sync/AI) | Not implemented | Review |
| 7.0.2 | **User Guide**: Complete redesign with better layout, feature cards, keyboard sh... | Not implemented | Review |
| 7.0.2 | **Admin Dashboard**: Removed Card Groups section, replaced with System Status fe... | Not implemented | Review |
| 7.0.2 | **Admin UI**: Cleaner quick action buttons, clickable user stats card | Not implemented | Review |
| 7.0.1 | **Reshuffle button visible**: ⟳ button now always visible on study cards (works ... | Not implemented | Review |
| 7.0.1 | **Search clear X button**: Clear search with one click | Not implemented | Review |
| 7.0.1 | **Randomize Custom Set setting**: Control random order separately for Custom Set | Not implemented | Review |
| 7.0.1 | **Speak pronunciation only toggle**: Option to speak only pronunciation instead ... | Not implemented | Review |
| 7.0.1 | Reshuffle works regardless of random toggle state (instant shuffle on demand) | Not implemented | Review |
| 7.0.0 | **Edit Decks page**: New page accessible from Settings with three tabs: | Not implemented | Review |
| 7.0.0 | **Switch tab**: View and switch between study decks, create new decks | Not implemented | Review |
| 7.0.0 | **Add Cards tab**: Manually add cards with term, definition, pronunciation, grou... | Not implemented | Review |
| 7.0.0 | **Deleted tab**: View and restore deleted cards | Not implemented | Review |
| 7.0.0 | **Deck management**: Create and delete custom study decks | Not implemented | Review |
| 7.0.0 | **User cards CRUD**: Add, edit, and delete user-created cards | Not implemented | Review |
| 7.0.0 | **AI generation buttons**: | Not implemented | Review |
| 7.0.0 | Generate Definition (3 AI options to choose from) | Not implemented | Review |
| 7.0.0 | Generate Pronunciation | Not implemented | Review |
| 7.0.0 | Generate Group suggestions (considers existing groups) | Not implemented | Review |
| 7.0.0 | **API endpoints**: | Not implemented | Review |
| 7.0.0 | `GET/POST /api/decks` - List and create decks | Not implemented | Review |
| 7.0.0 | `DELETE /api/decks/:id` - Delete a deck | Not implemented | Review |
| 7.0.0 | `GET/POST/PUT/DELETE /api/user_cards` - User cards CRUD | Not implemented | Review |
| 7.0.0 | `POST /api/ai/generate_definition` - AI definition generation | Not implemented | Review |
| 7.0.0 | `POST /api/ai/generate_pronunciation` - AI pronunciation generation | Not implemented | Review |
| 7.0.0 | `POST /api/ai/generate_group` - AI group suggestions | Not implemented | Review |
| 7.0.0 | Settings page now has "Edit Decks" button at top for quick access | Not implemented | Review |
| 6.1.0 | **Sync Progress page**: New settings section matching Android app with Push/Pull... | Not implemented | Review |
| 6.1.0 | **Settings tabbed navigation**: Quick nav tabs for Study, Display, Voice, Sync, ... | Not implemented | Review |
| 6.1.0 | **Star button on study cards**: Toggle Custom Set membership directly from study... | Not implemented | Review |
| 6.1.0 | **Sort by status dropdown**: All list can now be sorted by Unlearned, Unsure, Le... | Not implemented | Review |
| 6.1.0 | **Logout in user menu**: Moved logout option to user dropdown menu with icon | Not implemented | Review |
| 6.1.0 | Settings page completely redesigned with app-like card layout and modern buttons | Not implemented | Review |
| 6.1.0 | Buttons now use gradient backgrounds matching Android app style (primary blue, s... | Not implemented | Review |
| 6.1.0 | Removed standalone logout button from header controls | Not implemented | Review |
| 6.1.0 | More button renamed from "Show settings" to "⚙️ More" | Not implemented | Review |
| 6.0.0 | **Custom Set (Starred Cards)**: New ⭐ tab for studying a personalized set of sta... | Not implemented | Review |
| 6.0.0 | ☆/★ toggle buttons in All list to add/remove cards | Not implemented | Review |
| 6.0.0 | Internal status tracking (Active/Unsure/Learned) within custom set | Not implemented | Review |
| 6.0.0 | Filter views: All, Unsure, Learned within custom set | Not implemented | Review |
| 6.0.0 | API endpoints: `/api/custom_set`, `/api/custom_set/add`, `/api/custom_set/remove... | Not implemented | Review |
| 6.0.0 | **Show breakdown on definition toggle**: New setting to show/hide breakdown on c... | Not implemented | Review |
| 6.0.0 | **Auto-speak on card change**: Automatically speaks term when navigating prev/ne... | Not implemented | Review |
| 6.0.0 | **Speak definition on flip**: Automatically speaks definition when card flips to... | Not implemented | Review |
| 6.0.0 | **Admin Dashboard redesign**: Modern dashboard with stat cards, progress bars, A... | Not implemented | Review |
| 6.0.0 | Visual stats for Users, Cards, Breakdowns, Learning Progress | Not implemented | Review |
| 6.0.0 | AI Configuration panel with ChatGPT/Gemini status | Not implemented | Review |
| 6.0.0 | Quick Actions section for health checks | Not implemented | Review |
| 6.0.0 | Card groups display and admin users list | Not implemented | Review |
| 6.0.0 | **API endpoint**: `/api/admin/stats` for comprehensive admin statistics | Not implemented | Review |
| 6.0.0 | Cards API now includes `in_custom_set` field | Not implemented | Review |
| 6.0.0 | Admin page completely redesigned with modern UI, gradients, and animations | Not implemented | Review |
| 6.0.0 | Settings now include `show_breakdown_on_definition`, `auto_speak_on_card_change`... | Not implemented | Review |
| 5.5.3 | Sync: progress entries now include per-card `updated_at` timestamps | Not implemented | Review |
| 5.5.3 | Sync: push/pull merge uses `updated_at` (newer wins); supports offline pending q... | Not implemented | Review |
| 5.5.3 | API: /api/sync/push and /api/sync/pull accept/return object-form progress entrie... | Not implemented | Review |
| 5.5.2 | **Version/docs sync with Android App 4.4.2 (v22) | Not implemented | Review |
| 5.5.2 | No functional server code changes in this patch release. | Not implemented | Review |
| 5.5.2 | **GET /api/sync/apikeys**: New endpoint for all authenticated users to pull API ... | Not implemented | Review |
| 5.5.2 | Any logged-in user can retrieve API keys (read-only) | Not implemented | Review |
| 5.5.2 | Allows non-admin users to use AI breakdown features | Not implemented | Review |
| 5.5.2 | Admin-only `/api/admin/apikeys` POST still required for saving keys | Not implemented | Review |
| 5.5.2 | API keys are now shared with all authenticated users on login | Not implemented | Review |
| 5.5.2 | Admin access only required to modify/save API keys, not to use them | Not implemented | Review |
| 5.5.2 | **AI Access Page**: New `/ai-access.html` web page for managing API keys | Not implemented | Review |
| 5.5.2 | **Model Selection**: Choose ChatGPT and Gemini models from web UI | Not implemented | Review |
| 5.5.2 | **Startup Key Loading**: Server loads encrypted API keys from file on startup | Not implemented | Review |
| 5.5.2 | **Web API endpoints**: `/api/web/admin/apikeys` GET/POST for session-based admin... | Not implemented | Review |
| 5.5.2 | **Admin Users SoT**: `data/admin_users.json` - Source of Truth for admin usernam... | Not implemented | Review |
| 5.5.2 | **Admin Users Endpoint**: `GET /api/admin/users` - returns admin usernames list | Not implemented | Review |
| 5.5.2 | API keys now include model selection (chatGptModel, geminiModel) | Not implemented | Review |
| 5.5.2 | Keys loaded from `api_keys.enc` override environment variables | Not implemented | Review |
| 5.5.2 | Admin page now prominently links to AI Access Settings | Not implemented | Review |
| 5.5.2 | `_load_admin_usernames()` loads from JSON file with fallback | Not implemented | Review |
| 5.5.2 | Environment variable API keys no longer needed (can be removed from START_KenpoF... | Not implemented | Review |
| 5.5.2 | **Encrypted API Key Storage**: Admin can store ChatGPT and Gemini API keys encry... | Not implemented | Review |
| 5.5.2 | **POST /api/admin/apikeys**: Push encrypted API keys to server (admin only) | Not implemented | Review |
| 5.5.2 | **GET /api/admin/apikeys**: Pull decrypted API keys from server (admin only) | Not implemented | Review |
| 5.5.2 | **GET /api/admin/status**: Check if current user is admin | Not implemented | Review |
| 5.5.2 | Admin users defined in `ADMIN_USERNAMES` set (default: sidscri) | Not implemented | Review |
| 5.5.2 | API keys encrypted using XOR with HMAC integrity check | Not implemented | Review |
| 5.5.2 | Keys derived from server's secret_key.txt using SHA-256 | Not implemented | Review |
| 5.5.2 | Encrypted file (`api_keys.enc`) safe for git commits | Not implemented | Review |
| 5.5.2 | **Critical:** Fixed duplicate `/api/login` endpoint conflict — Flask was routing... | Not implemented | Review |
| 5.5.2 | Changed Android login endpoint from `/api/login` to `/api/sync/login` to avoid r... | Not implemented | Review |
| 5.5.2 | Auth tokens now correctly returned to Android app | Not implemented | Review |
| 5.5.2 | Added `.gitignore` entries for API keys and secrets (`gpt api.txt`, `START_Kenpo... | Not implemented | Review |
| 5.5.2 | Excluded `data/` directory from version control (contains user passwords and pro... | Not implemented | Review |
| 5.5.2 | `version.json` + `GET /api/version` endpoint | Not implemented | Review |
| 5.5.2 | User dropdown menu (click "User: …" to open) | Not implemented | Review |
| 5.5.2 | `/about` page with creator/contact info | Not implemented | Review |
| 5.5.2 | `/admin` diagnostics page (health/version/helper/AI status) | Not implemented | Review |
| 5.5.2 | `/user-guide` page (print-friendly) + `/user-guide.pdf` download | Not implemented | Review |
| 5.5.2 | Added dependency on `reportlab` for generating the User Guide PDF | Not implemented | Review |
| 5.5.2 | Sync regression from v5.2 — push not applying server-side changes | Not implemented | Review |
| 5.5.2 | End-to-end sync confirmed working | Not implemented | Review |
| 5.5.2 | Server-side helper mapping for stable card IDs across Android and Web | Not implemented | Review |
| 5.5.2 | `version.json` for release tracking | Not implemented | Review |
| 5.5.2 | Generic favicon (trademark-safe branding) | Not implemented | Review |
| 5.5.2 | `static/.well-known/security.txt` | Not implemented | Review |
| 5.5.2 | `robots.txt`, `sitemap.xml` to reduce 404 noise | Not implemented | Review |
| 5.5.2 | About/Admin/User Guide pages | Not implemented | Review |
| 5.5.2 | User dropdown menu with version display | Not implemented | Review |
| 5.5.2 | Admin link visible only for user 'sidscri' | Not implemented | Review |
| 5.5.2 | Added `reportlab` dependency for PDF generation | Not implemented | Review |
| 5.5.2 | Stable card ID mapping (helper.json) for cross-device sync | Not implemented | Review |
| 5.5.2 | Last known working sync baseline | Not implemented | Review |
| 5.5.2 | Settings reorganization with Apply-to-all logic | Not implemented | Review |
| 5.5.2 | Admin-only breakdown overwrite protection | Not implemented | Review |
| 5.5.2 | Definition-side breakdown display option | Not implemented | Review |
| 5.5.2 | Breakdown modal with OpenAI auto-fill | Not implemented | Review |
| 5.5.2 | Python 3.8 compatibility (replaced PEP 604 unions with `typing.Optional`) | Not implemented | Review |
| 5.5.2 | Dark theme dropdown styling | Not implemented | Review |
| 5.5.2 | Random order toggle positioning | Not implemented | Review |
| 5.5.2 | `updateRandomStudyUI` JS error | Not implemented | Review |
| 5.5.2 | Renamed "Definition first" to "Reverse the cards (Definition first)" | Not implemented | Review |
| 5.5.2 | Tighter spacing for small screens | Not implemented | Review |
| 5.5.2 | Python SyntaxError in `app.py` (invalid string escaping) | Not implemented | Review |
| 5.5.2 | Server boot and UI loading confirmed | Not implemented | Review |

### Notes
- 'Not implemented' = needs developer review to determine if applicable to Android
- 'N/A (server-only)' = Windows packaging/runtime feature, no Android action needed
- 'Skip' = feature is specific to the server environment
- Generated by sync_webserver_to_android.py v1.0.0
