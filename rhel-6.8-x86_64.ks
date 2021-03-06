#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
# System bootloader configuration
bootloader --location=mbr 
# Partition clearing information
clearpart all --initlabel 
#Partition information
part biosboot --fstype=biosboot --size=1024
part /boot --fstype="ext4" --ondisk=sda --size=500 
part pv.100 --fstype="lvmpv" --ondisk=sda --size=4096 --grow 
volgroup VolGroup pv.100 
logvol swap --fstype="swap" --name=lv_swap --vgname=VolGroup --size=4096 
logvol / --fstype="ext4" --name=lv_root --vgname=VolGroup --size=30000 
logvol /home --fstype="ext4" --name=lv_home --vgname=VolGroup --size=1024 --grow 
#Use text mode install
text
# Use graphical install
#graphical
# key
key --skip
# Firewall configuration
#firewall --disable
firewall --enabled --http --ftp --ssh --smtp
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang zh_CN
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
#$SNIPPET('network_config')
network --bootproto=dhcp   --device=eth0 --onboot=on
#network  --bootproto=static --device=eth0 --gateway=192.168.40.1 --ip=192.168.40.235 --nameserver=202.103.24.68 --netmask=255.255.255.0 --onboot=on
# Reboot after installation
reboot
#Root password
rootpw --iscrypted $default_password_crypted
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone   Asia/Shanghai
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr

%packages
@additional-devel
@base
@basic-desktop
@chinese-support
@compat-libraries
@console-internet
@debugging
@desktop-debugging
@development
@fonts
@general-desktop
@graphical-admin-tools
@hardware-monitoring
@identity-management-server
@infiniband
@input-methods
@internet-browser
@kde-desktop
@large-systems
@legacy-unix
@legacy-x
@mainframe-access
@network-tools
@performance
@security-tools
@server-platform-devel
@smart-card
@storage-client-fcoe
@storage-client-iscsi
@storage-client-multipath
@system-management-snmp
@x11
gcc
hmaccalc
wget
unzip
ntp
ftp
telnet
kexec-tools
net-tools
vim
%end
  
%pre
parted -s /dev/sda mklabel gpt
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps
sed -i 's|id:3:initdefault:|id:5:initdefault:|' /etc/inittab 
%end
