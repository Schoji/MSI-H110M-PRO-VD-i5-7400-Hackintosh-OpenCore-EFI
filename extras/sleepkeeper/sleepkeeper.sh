#!/bin/bash
# sleepkeeper - puts the machine to sleep with "pmset sleepnow" after IDLE_MIN minutes of inactivity.
#
# Used instead of the built-in idle sleep (pmset sleep 0) because on this build:
#  - the first automatic idle sleep after boot does not arm Wake-on-LAN in RealtekRTL8111
#    (pmset sleepnow does),
#  - the built-in idle sleep ignores SSH sessions and puts the machine to sleep during remote work.
#
# "Idle" means all of these:
#  - no keyboard/mouse input (HIDIdleTime) for IDLE_MIN minutes,
#  - no established SSH connection (port 22),
#  - no PreventUserIdleSystemSleep / PreventSystemSleep assertion (e.g. caffeinate),
#    ignoring bluetoothd and powerd,
#  - at least IDLE_MIN minutes since boot and since the last wake.
#
# Configuration: /usr/local/etc/sleepkeeper.conf (IDLE_MIN=30; IDLE_MIN=0 disables it).
# Log: log show --predicate 'eventMessage CONTAINS "sleepkeeper"'

# Do nothing inside a virtual machine.
[ "$(ioreg -l | grep -c -i QEMU)" -gt 0 ] && exit 0

CONF=/usr/local/etc/sleepkeeper.conf
log() { logger -t sleepkeeper "$*"; }

while true; do
  sleep 60
  IDLE_MIN=30; [ -f "$CONF" ] && . "$CONF"
  [ "${IDLE_MIN:-0}" -gt 0 ] 2>/dev/null || continue          # IDLE_MIN=0 -> disabled
  lim=$((IDLE_MIN * 60)); now=$(date +%s)

  hid=$(( $(ioreg -c IOHIDSystem | awk '/HIDIdleTime/{print $NF; exit}') / 1000000000 ))
  [ "$hid" -lt "$lim" ] && continue

  boot=$(sysctl -n kern.boottime | sed -E 's/.*sec = ([0-9]+).*/\1/')
  wake=$(sysctl -n kern.waketime 2>/dev/null | sed -E 's/.*sec = ([0-9]+).*/\1/'); [ -n "$wake" ] || wake=0
  [ $((now - boot)) -lt "$lim" ] && continue
  [ $((now - wake)) -lt "$lim" ] && continue

  netstat -an -p tcp | awk '$4 ~ /\.22$/ && $6 == "ESTABLISHED" {f=1} END {exit !f}' && continue

  pmset -g assertions | awk '/Listed by owning process/,0' \
    | grep -E 'PreventUserIdleSystemSleep|PreventSystemSleep|NoIdleSleepAssertion' \
    | grep -vE 'bluetoothd|powerd' | grep -q . && continue

  log "idle for ${hid}s (limit ${lim}s) -> pmset sleepnow"
  pmset sleepnow
  sleep 120
done
