#!/bin/bash
# Prints "left|right|case" battery % of connected AirPods (empty fields if unknown).
# Prints nothing if no AirPods are connected.
# Note: macOS formats levels as "28 %" with a non-breaking space, so grab digits only.
system_profiler SPBluetoothDataType 2>/dev/null | awk '
  function num(s) { return match(s, /[0-9]+/) ? substr(s, RSTART, RLENGTH) : "" }
  /^ *Not Connected:/ { c = 0 }
  /^ *Connected:/     { c = 1; next }
  c && /Left Battery Level:/  { l = num($0); found = 1 }
  c && /Right Battery Level:/ { r = num($0); found = 1 }
  c && /Case Battery Level:/  { k = num($0) }
  END { if (found) print l "|" r "|" k }
'
