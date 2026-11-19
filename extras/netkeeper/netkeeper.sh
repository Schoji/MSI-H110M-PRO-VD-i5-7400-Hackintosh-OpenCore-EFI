#!/bin/bash
# netkeeper - keeps the onboard RTL8111H link up.
#
# Only needed if your switch or cable cannot do gigabit. With a 10/100 switch the
# RealtekRTL8111 driver in autoselect mode never brings the link up on this board,
# while a forced 100baseTX full-duplex link works.
#
# Logic (checks en0 every 10 s):
#  - autoselect and link active: do nothing (normal gigabit case),
#  - autoselect and no link for ~20 s: force 100baseTX full-duplex and renew DHCP,
#  - forced 100 Mbit and no link: go back to autoselect.
# Does nothing inside a virtual machine.

[ "$(ioreg -l | grep -c -i QEMU)" -gt 0 ] && exit 0

down=0
while true; do
  if ifconfig en0 >/dev/null 2>&1; then
    m=$(ifconfig en0 | grep -E "media:")
    if ifconfig en0 | grep -q "status: active"; then
      down=0
    else
      down=$((down + 1))
      if echo "$m" | grep -q autoselect; then
        if [ $down -ge 2 ]; then
          ifconfig en0 media 100baseTX mediaopt full-duplex 2>/dev/null
          sleep 5; ipconfig set en0 DHCP; down=0
        fi
      else
        ifconfig en0 media autoselect 2>/dev/null
        sleep 10; ipconfig set en0 DHCP; down=0
      fi
    fi
  fi
  sleep 10
done
