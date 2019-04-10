# Cobbler for Kickstart Configurator for CentOS 7 by clsn
install
url --url=$tree
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
 
part pv.194 --fstype="lvmpv" --ondisk=sda --size=1024 --grow
part /boot --fstype="xfs" --ondisk=sda --size=1024
part biosboot --fstype=biosboot --size=1
volgroup centos pv.194
logvol swap --fstype="swap" --size=4096 --name=swap --vgname=centos
logvol / --fstype="xfs" --size=4096 --name=root --vgname=centos
logvol /data --fstype="xfs" --size=4096 --name=data --vgname=centos --grow

firstboot --disable
selinux --disabled
firewall --disabled
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
@^minimal
@compat-libraries
@core
@debugging
@development
bash-completion
chrony
dos2unix
kexec-tools
lrzsz
nmap
sysstat
telnet
tree
vim
wget
%end
  
%post
systemctl disable postfix.service
%end