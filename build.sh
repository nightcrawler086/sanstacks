#!/bin/bash

ARTIFACTORY_DEV_REPO=""
VENDOR_REPO="ftp.box.com"
WORKING_DIR=/var/jenkins/workspace/build/working
RPM_ROOT="${HOME}/rpmbuild/SOURCES/opt"
RPM_RELEASE="1.citi.A0"
SOURCE_URL="http://192.168.1.213/files/emulex"
## FUNCTIONS ##
function extract_from_zip () {
	local PKG=$1
	local PATTERN=$2
	local DIR=$3
	local REV_PATTERN=$4
	if [ -z "$REV_PATTERN" ]; then
		FILE=`unzip -l $PKG | grep "$PATTERN" | awk '{print $4}'`
	else
		FILE=`unzip -l $PKG | grep "$PATTERN" | grep -v "$REV_PATTERN" | awk '{print $4}'`
	fi
	unzip $PKG $FILE -d $DIR
	echo ${DIR}/${FILE}
}

function extract_rpms_by_version () {
	local TARFILE=$1
	local VERSION=$2
	RPMS=(`tar -zxvf $TARFILE "*rhel-${VERSION}/*.rpm"`)
	echo "${RPMS[@]}"
}

## MAIN ##
# Should make sure it's not installed before we install it
yum install rpmdevtools
# can this be set up somewhere other than home? nope
rpmdev-setuptree
[ -d $RPM_ROOT ] && rm -rf $RPM_ROOT && mkdir -p $RPM_ROOT
[ -d $WORKING_DIR ] && rm -rf $WORKING_DIR && mkdir -p $WORKING_DIR
# This just gets the latest available package, doesn't compare them
WEB_DIR_LIST=(`wget -q -O - $SOURCE_URL |grep zip | awk -F '"' '{print $6}' | sort -r`)
PACKAGE_URL=${WEB_DIR_LIST[0]}
echo $PACKAGE_URL
wget ${SOURCE_URL}/${PACKAGE_URL} -P $WORKING_DIR
ELXFLASH=`unzip -l ${WORKING_DIR}/${WEB_DIR_LIST[0]} | grep elxflashStandalone-linux | awk '{print $4}'`
unzip -o -j ${WORKING_DIR}/${WEB_DIR_LIST[0]} $ELXFLASH -d $WORKING_DIR
unzip ${WORKING_DIR}/$(basename $ELXFLASH) -d ${HOME}/rpmbuild/SOURCES/opt
ELXFLASH_DIR=`basename $ELXFLASH`
mv ${HOME}/rpmbuild/SOURCES/opt/${ELXFLASH_DIR%.*} ${HOME}/rpmbuild/SOURCES/opt/elxflashStandalone
#u="bh53965"
#p="password"
#cd $WORKING_DIR
#git clone https://$u:$p@cedt-bitbucket.nam.nsroot.net/bitbucket/scm/ss/elxflash-standalone
cp ${WORKING_DIR}/elxflash-standalone/elxflashStandalone.spec ${HOME}/rpmbuild/SPECS
cp ${WORKING_DIR}/elxflash-standalone/launch.sh ${HOME}/rpmbuild/SOURCES/opt/elxflashStandalone/lx
cp -a ${WORKING_DIR}/elxflash-standalone/firmware/* ${HOME}/rpmbuild/SOURCES/opt/elxflashStandalone/lx/x86_64/rhel-7/firmware
cd ${HOME}/rpmbuild/SPECS
VERSION=`echo ${WEB_DIR_LIST[0]} | awk -F_ '{print $2}'`
sed -i 's/^Version.*/Version:\ \ \ \ \ \ \ '"$VERSION"'/g' ./elxflashStandalone.spec
sed -i 's/^Provides.*/Provides:\ \ \ \ \ \ \ \ elxflashStandalone\ =\ "${VERSION}-${RELEASE}/g' ./elxflashStandalone.spec
cd ../SOURCES
tar -czvf elxflashStandalone-${VERSION}-${RELEASE}.tar.gz opt -C ${HOME}/rpmbuild/SOURCES/
rpmbuild -bb ../SPECS/elxflashStandalone.spec

## OCMCORE

cd $WORKING_DIR
OCMCORE=`unzip -l $PACKAGE | grep ocmcore-rhel | grep -v power | awk '{print $4}'`
unzip -o -j $PACKAGE $OCMCORE -d $WORKING_DIR
OCMCORE_TAR=`basename $OCMCORE`
RHEL7_RPMS=`extract_rpms_by_version $OCMCORE_TAR 7`
RHEL8_RPMS=`extract_rpms_by_version $OCMCORE_TAR 8`

for i in ${RHEL7_RPMS[@]}; do
	RPM=`basename $i`
	curl -i -k -u 'user:pass' -x PUT $ARTIFACTORY_DEV_REPO -T $RPM
done

for i in ${RHEL8_RPMS[@]}; do
	RPM=`basename $i`
	curl -i -k -u 'user:pass' -x PUT $ARTIFACTORY_DEV_REPO -T $RPM
done
