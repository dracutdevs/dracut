#!/bin/sh

. /etc/crypt-ssh.conf

[ -f /tmp/dropbear.pid ] && kill -0 $(cat /tmp/dropbear.pid) 2>/dev/null || {
  info "sshd port: ${dropbear_port}"
  for keyType in $keyTypes; do
    eval fingerprint=\$dropbear_${keyType}_fingerprint
    eval bubble=\$dropbear_${keyType}_bubble
    info "Boot SSH ${keyType} key parameters: "
    info "  fingerprint: ${fingerprint}"
    info "  bubblebabble: ${bubble}"
  done

  /sbin/dropbear -m -s -j -k -p ${dropbear_port} -P /tmp/dropbear.pid
  [ $? -gt 0 ] && info 'Dropbear sshd failed to start'
}
