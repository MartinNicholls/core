#!/bin/bash
# Hacky bootstrap if given the core roll iso

mount -o loop core-6.3-2.x86_64.disk1.iso /mnt
cd /mnt/core/6.3/x86_64/RedHat/RPMS
yum install createrepo rocks-devel-6.3-3.x86_64.rpm 
. /etc/profile.d/rocks-devel.sh
mkdir -p /export/home/repositories/testrpms/RPMS
cp *rpm /export/home/repositories/testrpms/RPMS
cd /export/home/repositories/testrpms
umount /mnt
cp /opt/rocks/share/devel/src/roll/template/Makefile . 
cat /opt/rocks/share/devel/src/roll/template/version.mk | sed -e 's/@template@/core/' > version.mk
make createlocalrepo
yum -c yum.conf --disablerepo='*' --enablerepo=core-roll list available | grep core-roll | awk '{print $1}' | awk -F. '{print $1}' | grep -v 'roll.*kickstart' | less | xargs yum -y -c yum.conf install
rpm --relocate=/export/profile=`pwd` -ivh RPMS/roll-core-kickstart-6.3-2.noarch.rpm 
. /etc/profile.d/rocks-binaries.sh
tmpfile=$(/bin/mktemp)
/bin/cat nodes/database.xml nodes/database-schema.xml nodes/database-sec.xml | /opt/rocks/bin/rocks report post attrs="{'hostname':'', 'HttpRoot':'/var/www/html','os':'linux'}"  > $tmpfile
if [ $? != 0 ]; then echo "FAILURE to create script for bootstrapping the Database"; exit -1; fi
/bin/sh $tmpfile
# /bin/rm $tmpfile
MYNAME=`hostname -s`
/opt/rocks/bin/rocks add distribution rocks-dist
/opt/rocks/bin/rocks add appliance bootstrap node=server
/opt/rocks/bin/rocks add host $MYNAME rack=0 rank=0 membership=bootstrap
/opt/rocks/bin/rocks add network private 127.0.0.1 netmask=255.255.255.255
/opt/rocks/bin/rocks add host interface $MYNAME lo subnet=private ip=127.0.0.1
/opt/rocks/bin/rocks add attr os `./_os` 
# 3. Add appliance types so that we can build the OS Roll
/opt/rocks/bin/rocks add attr Kickstart_DistroDir /export/rocks
/opt/rocks/bin/rocks add attr Kickstart_PrivateKickstartBasedir install
/opt/rocks/bin/rocks add attr Kickstart_PublicHostname $MYNAME 
/opt/rocks/bin/rocks add appliance compute graph=default node=compute membership=Compute public=yes
/opt/rocks/bin/rocks add attr rocks_version `/opt/rocks/bin/rocks report version`
/opt/rocks/bin/rocks add attr rocks_version_major `/opt/rocks/bin/rocks report version major=1`
