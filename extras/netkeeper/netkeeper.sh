#!/bin/bash
# netkeeper - keeps the onboard RTL8111H link up.
#
# Only needed if your switch or cable cannot do gigabit. With a 10/100 switch the
# RealtekRTL8111 driver in autoselect mode never brings the link up on this board,
# while a forced 100baseTX full-duplex link works.
#
# Logic (checks en0 every 10 s):
#  - autoselect and link active: do nothing (normal gigabit case),
#  - autoselect and no link for 60 s: force 100baseTX full-duplex and renew DHCP,
#  - forced 100 Mbit and no link: go back to autoselect,
#  - forced 100 Mbit and link active: once an hour, try autoselect again; if there is
#    no link after 30 s, force 100 Mbit again. So a short cable or switch outage never
#    leaves a gigabit link stuck at 100 Mbit for more than an hour.
# Does nothing inside a virtual machine.

[ "$(ioreg -l | grep -c -i QEMU)" -gt 0 ] && exit 0

AUTO_GRACE=6        # checks (x10 s) without link in autoselect before forcing 100
RETRY_AUTO=360      # checks (x10 s) on forced 100 before trying autoselect again
log() { logger -t netkeeper "$*"; }
active() { ifconfig en0 | grep -q "status: active"; }

force100() {
  log "no link in autoselect -> forcing 100baseTX full-duplex"
  ifconfig en0 media 100baseTX mediaopt full-duplex 2>/dev/null
  sleep 5; ipconfig set en0 DHCP
}

down=0; forced=0
while true; do
  if ifconfig en0 >/dev/null 2>&1; then
    if ifconfig en0 | grep -q "media: autoselect"; then
      forced=0
      if active; then down=0; else
        down=$((down + 1))
        [ $down -ge $AUTO_GRACE ] && { force100; down=0; }
      fi
    else
      forced=$((forced + 1))
      if ! active; then
        log "no link on forced 100 -> back to autoselect"
        ifconfig en0 media autoselect 2>/dev/null; sleep 10; ipconfig set en0 DHCP; forced=0; down=0
      elif [ $forced -ge $RETRY_AUTO ]; then
        log "retrying autoselect"
        ifconfig en0 media autoselect 2>/dev/null; sleep 30
        if active; then ipconfig set en0 DHCP; log "autoselect link: $(ifconfig en0 | grep media:)"; else force100; fi
        forced=0; down=0
      fi
    fi
  fi
  sleep 10
done
