nior

  GNU nano 8.4                                                                                             /home/sidscri/to_niorfnio.sh                                                                                                       
#!/usr/bin/env bash
set -e
JACKET="FC:58:FA:6D:13:EC"
NIOR="15:9C:A5:F0:8D:56"

bluetoothctl disconnect "$JACKET" >/dev/null 2>&1 || true
sleep 1

bluetoothctl connect "$NIOR" >/dev/null 2>&1 || true
sleep 2

if ! pactl list sinks short | grep -q "bluez_output\.15_9C_A5_F0_8D_56"; then
  systemctl --user restart wireplumber pipewire pipewire-pulse
  sleep 2
  bluetoothctl disconnect "$NIOR" >/dev/null 2>&1 || true
  sleep 1
  bluetoothctl connect "$NIOR" >/dev/null 2>&1 || true
  sleep 2
fi

SINK_ID="$(wpctl status | awk '
/Sinks:/{in=1; next}
/Sources:/{in=0}
in && /NIORFNIO/ {
  if (match($0, /([0-9]+)\./, a)) { print a[1]; exit }
}')"

if [ -z "$SINK_ID" ]; then
  echo "NIORFNIO sink not found."
  echo "--- bluetoothctl info ---"
  bluetoothctl info "$NIOR" | egrep "Name|Connected|Paired|Trusted|ServicesResolved" || true
  echo "--- pactl sinks ---"
  pactl list sinks short | egrep "bluez_output|hdmi" || true
  echo "--- wpctl sinks ---"
  wpctl status | sed -n '/Sinks:/,/Sources:/p' || true
  exit 1
fi

wpctl set-default "$SINK_ID"
echo "Default output set to NIORFNIO (sink $SINK_ID)"


jacket


  GNU nano 8.4                                                                                              /home/sidscri/to_jacket.sh                                                                                                        
#!/usr/bin/env bash
set -e
JACKET="FC:58:FA:6D:13:EC"
NIOR="15:9C:A5:F0:8D:56"

# Avoid two-device fight
bluetoothctl disconnect "$NIOR" >/dev/null 2>&1 || true
sleep 1

bluetoothctl connect "$JACKET" >/dev/null 2>&1 || true
sleep 2

# If PipeWire didn't create the bluez sink yet, recover once
if ! pactl list sinks short | grep -q "bluez_output\.FC_58_FA_6D_13_EC"; then
  systemctl --user restart wireplumber pipewire pipewire-pulse
  sleep 2
  bluetoothctl disconnect "$JACKET" >/dev/null 2>&1 || true
  sleep 1
  bluetoothctl connect "$JACKET" >/dev/null 2>&1 || true
  sleep 2
fi

SINK_ID="$(wpctl status | awk '
/Sinks:/{in=1; next}
/Sources:/{in=0}
in && /Jacket H20 4/ {
  if (match($0, /([0-9]+)\./, a)) { print a[1]; exit }
}')"

if [ -z "$SINK_ID" ]; then
  echo "Jacket sink not found."
  echo "--- bluetoothctl info ---"
  bluetoothctl info "$JACKET" | egrep "Name|Connected|Paired|Trusted|ServicesResolved" || true
  echo "--- pactl sinks ---"
  pactl list sinks short | egrep "bluez_output|hdmi" || true
  echo "--- wpctl sinks ---"
  wpctl status | sed -n '/Sinks:/,/Sources:/p' || true
  exit 1
fi

wpctl set-default "$SINK_ID"
echo "Default output set to Jacket (sink $SINK_ID)"


hdmi

  GNU nano 8.4                                                                                               /home/sidscri/to_hdmi.sh                                                                                                         
#!/usr/bin/env bash
set -e

HDMI_ID="$(wpctl status | awk '
/Sinks:/{in=1; next}
/Sources:/{in=0}
in && /HDMI/ {
  if (match($0, /([0-9]+)\./, a)) { print a[1]; exit }
}')"

if [ -z "$HDMI_ID" ]; then
  echo "HDMI sink not found. Current sinks:"
  wpctl status | sed -n '/Sinks:/,/Sources:/p'
  exit 1
fi

wpctl set-default "$HDMI_ID"
echo "Default output set to HDMI (sink $HDMI_ID)"


