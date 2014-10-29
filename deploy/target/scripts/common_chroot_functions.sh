# Support the read-only configuration that
# is shared between development and release filesystems
# Only the release filesystem is actually read-only but as much as possible
# of the configuration is shared with the development filesystem
# This function makes the corresponding changes in the chroot jail to support
# the shared configuration
configure_readonly() {
  echo "Log: (chroot) updating configuration to support shared read-only configuration"

  # Set the correct path to gem installation directory for shell environment
  echo "export GEM_HOME=/usr/local/lib/gems/1.9.1" >> /etc/profile

  # /etc/adjtime is modified on boot, see: https://wiki.debian.org/ReadonlyRoot#adjtime
  ln -s /var/local/adjtime /etc/adjtime

  # /etc/mtab is written to by mount, see: https://wiki.debian.org/ReadonlyRoot#mtab
  ln -s /proc/self/mounts /etc/mtab

  # Enable misc services to start on boot
  # Normally this is done automatically by the debian-enable-units service unit but that service is disabled
  # since it can't run due to the read-only filesystem
  systemctl enable acpid.service || true
  systemctl enable wpa_supplicant.service || true

  # Disable service that by default enable units and create symlinks on boot
  # The actions normally carried out by these services are taken care of explicitly above
  systemctl mask debian-fixup.service || true
  systemctl mask debian-enable-units.service || true
}

# Configure various services to start on boot
configure_startup_services() {
  echo "Log: (chroot) configuring common startup services"

  # Remove the default script put in place by chroot script
  rm -rf /etc/init.d/generic-boot-script.sh

  # Start the cape manager service on boot
  if [ -f /etc/init.d/capemgr.sh ] ; then
    chown root:root /etc/init.d/capemgr.sh
    chown root:root /etc/default/capemgr
    chmod +x /etc/init.d/capemgr.sh
    insserv capemgr.sh || true
  fi

  # systemctl enable returns non-zero exit code (actually the number of symlinks affected) when run in chroot even if successful
  # This is a bug in systemd that appears to have been fixed but the fixed version is not used in debian 7
  # For now, always exit with true

  # Start the local web server on boot
  systemctl enable smith-server.service || true

  # Enable access point mode on boot
  systemctl enable ap-mode.service || true

  # Restore system date from timestamp file on boot
  systemctl enable restore-date.service || true

  # Start dnsmasq (DHCP server) on boot
  systemctl enable dnsmasq.service || true

  # Mount owfs on boot
  systemctl enable owfs.service || true
}

# Allow root login over ssh and remove the root password
unsecure_root () {
  echo "Log: (chroot) unsecuring root"

  # Clear the root password
  root_password=$(cat /etc/shadow | grep root | awk -F ':' '{print $2}')
  sed -i -e 's:'$root_password'::g' /etc/shadow

  if [ -f /etc/ssh/sshd_config ] ; then
    # Allow ssh login with empty password
    # Make ssh root@beaglebone work
    sed -i -e 's:PermitEmptyPasswords no:PermitEmptyPasswords yes:g' /etc/ssh/sshd_config
    sed -i -e 's:UsePAM yes:UsePAM no:g' /etc/ssh/sshd_config
  fi

  if [ -f /etc/sudoers ] ; then
    #Don't require password for sudo access
    echo "${rfs_username}  ALL=NOPASSWD: ALL" >>/etc/sudoers
  fi
}

# Miscellaneous system-level setup tasks
setup_system() {
  # Create the mount point for owfs
  mkdir -pv /mnt/1wire

  if [ -f /etc/ssh/sshd_config ] ; then
    # Dont print motd and last login on ssh login
    sed -i -e 's:PrintMotd yes:PrintMotd no:g' /etc/ssh/sshd_config
    sed -i -e 's:PrintLastLog yes:PrintLastLog no:g' /etc/ssh/sshd_config
  fi
}
