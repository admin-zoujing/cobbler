#!/bin/bash
#Cobbler安装脚本
#Cobbler全自动批量安装部署Linux系统说明：Cobbler服务器系统：CentOS 7.4 64位
#IP地址：192.168.8.52
#需要安装部署的Linux系统：
#IP地址段：192.168.8.240-192.168.8.250
#网关：192.168.8.2
#DNS：202.103.24.68  114.114.114.114
#1、准备安装包下载
ntpdate cn.pool.ntp.org
hwclock --systohc
hostname cobbler
sed -i 's|HOSTNAME=.*|HOSTNAME=cobbler|' /etc/sysconfig/network
sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/selinux/config  
sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/selinux/config 
systemctl stop firewalld.service && systemctl disable firewalld.service 
setenforce 0

#2、安装EPEL
yum install -y epel-release 

#3、安装cobbler组件
yum -y install cobbler cobbler-web dhcp tftp-server rsyncd pykickstart httpd debmirror

#4、配置DHCP
sed -i 's|subnet 192.168.1.0|subnet 192.168.8.0|' /etc/cobbler/dhcp.template
sed -i 's|option routers             192.168.1.5;|option routers             192.168.8.52;|' /etc/cobbler/dhcp.template
sed -i 's|option domain-name-servers 192.168.1.1;|option domain-name-servers 192.168.8.2;|' /etc/cobbler/dhcp.template
sed -i 's|range dynamic-bootp        192.168.1.100 192.168.1.254;|range dynamic-bootp        192.168.8.100 192.168.8.254;|' /etc/cobbler/dhcp.template

#5、cobbler check命令检查存的问题
sed -i 's|next_server:.*|next_server: 192.168.8.52|' /etc/cobbler/settings
sed -i 's|server:.*|server: 192.168.8.52|' /etc/cobbler/settings
sed -i 's|manage_dhcp: 0|manage_dhcp: 1|' /etc/cobbler/settings
salta=`openssl rand -hex 4` && sed -i "s|default_password_crypted:.*|default_password_crypted: \"`openssl passwd -1 -salt $salta '123456'`\"|" /etc/cobbler/settings
sed -i 's|@dists=.*|#@dists="sid";|' /etc/debmirror.conf
sed -i 's|@arches=.*|#@arches="i386"|' /etc/debmirror.conf
sed -i 's|disable.*|disable                 = no|' /etc/xinetd.d/tftp 
#sed -i 's|disable.*|disable         = no|' /etc/xinetd.d/rsync
sed -i 's|#ServerName www.*|ServerName www.cobbler.com:80|' /etc/httpd/conf/httpd.conf
chown -R apache:apache /var/www/
yum install -y cman fence-agents
cobbler get-loaders
systemctl enable rsyncd.service 
systemctl enable httpd.service 
systemctl enable tftp.socket 
systemctl enable dhcpd.service 
systemctl enable cobblerd.service 
cobbler sync
systemctl restart httpd.service 
systemctl restart cobblerd.service 


#cat >> /etc/cobbler/users.digest <<EOF
#cblradmin:Cobbler:876ca48b9eb67e18810a5fe7e690da40
#EOF

#https://192.168.8.52/cobbler_web 账号密码默认均为cobbler
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install Django==1.8.9
python -c "import django; print(django.get_version())"
cobbler sync
systemctl restart httpd.service 
systemctl restart cobblerd.service 

#6、创建 PXE 菜单密码11223300
sed -i "/TIMEOUT 200/i\MENU MASTER PASSWD `openssl passwd -1 -salt sXiKzkus '11223300'`" /etc/cobbler/pxe/pxedefault.template
sed -i '/kernel $kernel_path/i\        MENU PASSWD' /etc/cobbler/pxe/pxeprofile.template
cobbler sync
systemctl restart httpd.service 
systemctl restart cobblerd.service 

#7、导入系统镜像到cobbler,命令格式：cobbler import --path=镜像路径 -- name=安装引导名 --arch=32位或64位
#mkdir -pv /iso && mkdir -pv /mnt/cdrom/CentOS-7-x86_64
#mount -o loop /iso/CentOS-7-x86_64-DVD-1708.iso /mnt/cdrom/CentOS-7-x86_64
#cobbler import --path=/mnt/cdrom/CentOS-7-x86_64  --name=CentOS-7.4-x86_64   --arch=x86_64 
#导入ESXI和Ubuntu用图形化报错，必须用命令 
#cobbler import --path=/mnt/cdrom/VMware-ESXi-6.0.0.x86_64 --name=ESXI-6.0.0 --arch=x86_64
#/var/lib/cobbler/kickstarts/sample_esxi6.ks要注销$SNIPPET('network_config')

#8、设置profile，按照操作系统版本分别关联系统镜像文件和kickstart自动安装文件,命令：cobbler profile add|edit|remove --name=安装引导名 --distro=系统镜像名 --kickstart=kickstart自动安装文件路径
#cobbler profile add --name=CentOS-7.4-x86_64 --distro=CentOS-7.4-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7.4-x86_64.ks  
#cobbler profile edit --name=CentOS-7.4-x86_64 --distro=CentOS-7.4-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7.4-x86_64.ks  

#9、创建kickstarts自动安装脚本(配置网卡一定要正确，否则找不到文件)
cat > /var/lib/cobbler/kickstarts/CentOS-7.4-x86_64.ks  <<EOF

# Cobbler for Kickstart Configurator for CentOS 7 by clsn
install
url --url=\$tree
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
rootpw  --iscrypted \$default_password_crypted
clearpart --all --initlabel
 
#part biosboot --fstype=biosboot --size=1
part /boot --fstype="xfs" --ondisk=sda --size=1024
part pv.194 --fstype="lvmpv" --ondisk=sda --size=1024 --grow
volgroup centos pv.194
logvol swap --fstype="swap" --size=4096 --name=swap --vgname=centos
logvol / --fstype="xfs" --size=30000 --name=root --vgname=centos
logvol /data --fstype="xfs" --size=4096 --name=data --vgname=centos --grow

firstboot --disable
selinux --disabled
#firewall --disable
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
  
%post
systemctl disable postfix.service
%end
EOF

#利用kickstart图形界面生成相应的kickstart.cfg文件
#挂载光盘源：mount -o loop /iso/CentOS-7-x86_64-DVD-1708.iso /mnt/cdrom/CentOS-7-x86_64
#cat > /etc/yum.repos.d/my.repo <<EOF
#[development]
#name=my-centos7
#baseurl=file:///mnt/cdrom/CentOS-7-x86_64/
#enabled=1
#gpgcheck=0
#gpgkey=file:///mnt/cdrom/CentOS-7-x86_64/RPM-GPG-KEY-CentOS-7
#EOF
#yum clean all
#yum makecache
#yum -y install system-config-kickstart
#system-config-kickstart

#centos7.4图形化安装
#yum -y upgrade
#yum -y groupinstall "GNOME Desktop" "Graphical Administration Tools"
#systemctl set-default graphical.target
#centos6.8图形化安装
#修改配置文件“/etc/inittab”,改为5的级别

#若出现license information(license not accepted)，输入1-回车-2-回车-c-回车-c回车，即可解决 

#使用 Koan 重装系统
#在重装的机器上安装 koan:  yum -y install koan 
#重新安装客户端系统:       koan -r --server=192.168.8.52 --profile=CentOS-7.4-x86_64
#重新安装指定(客户机)系统: koan -r --server=192.168.8.52 --system=host-188116


#戴尔服务器设置PXE:按F2--Device Settings--选择插网线网卡--NIC Configuration--Legacy Boot Protocol改为PXE--保存退出--按F12尝试PXE引导
#华为服务器设置PXE:按“Delete”/“F4”--Boot--PXE1 Configuration”--保存退出--按F12尝试PXE引导

#RHEL7去除注册提示:        yum -y remove subscription-manager 
#RHEL7去除管理里面注册选项:yum -y remove rhn-setup-gnome
