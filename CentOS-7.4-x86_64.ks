# Cobbler for Kickstart Configurator for CentOS 7 by clsn
install
url --url=$tree
# Use graphical install
#graphical
text
lang en_US.UTF-8
keyboard 'us'
zerombr
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
#Network information
network --bootproto=dhcp --device=ens33 --onboot=yes --hostname=CentOS7 --activate 
timezone Asia/Shanghai
auth  --useshadow  --passalgo=sha512
rootpw  --iscrypted $default_password_crypted
clearpart --all --initlabel
 
#part biosboot --fstype=biosboot --size=1024
part /boot --fstype="xfs" --ondisk=sda --size=1024
part pv.194 --fstype="lvmpv" --ondisk=sda --size=1024 --grow
volgroup centos  pv.194
logvol swap --fstype="swap" --size=4096 --name=swap --vgname=centos
logvol / --fstype="xfs" --size=30000 --name=root --vgname=centos
logvol /data --fstype="xfs" --size=4096 --name=data --vgname=centos --grow

firstboot --disable
selinux --disabled
#firewall --disabled
firewall --enabled --http --ftp --ssh --smtp
logging --level=info
reboot

%pre
parted -s /dev/sda mklabel gpt
('log_ks_pre')
('kickstart_start')
('pre_install_network_config')
# Enable installation monitoring
('pre_anamon')
%end

%packages
@additional-devel
@base
@compat-libraries
@development
@infiniband
@internet-browser
@large-systems
@mainframe-access
@network-tools
@performance
@platform-devel
@remote-system-management
@security-tools
@desktop-debugging
@fonts
@graphical-admin-tools
@input-methods
@kde-desktop
@legacy-x
@x11
hmaccalc
%end

%end
%post
systemctl disable postfix.service
%end
