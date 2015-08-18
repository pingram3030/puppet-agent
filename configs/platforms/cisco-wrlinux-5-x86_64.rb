platform "cisco-wrlinux-5-x86_64" do |plat|
  plat.servicedir "/etc/init.d"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "sysv"
  # curl the repo because the OS image doesn't include any yum repos by default - thus initial vanagon yum install would fail
  plat.provision_with "rpm -e libgmp-dev libmpc-dev libmpfr-dev; curl -o /etc/yum/repos.d/pl-build-tools-cisco-wrlinux-5.repo http://pl-build-tools.delivery.puppetlabs.net/yum/cisco-wrlinux/5/pl-build-tools-cisco-wrlinux-5.repo;yum install -y autoconf automake createrepo rsync gcc make rpm-build rpm-libs yum-utils;yum update -y pkgconfig"
  plat.install_build_dependencies_with "yum install -y"

  plat.vcloud_name "cisco-wrlinux-5-x86_64"

end
