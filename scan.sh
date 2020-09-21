#!/bin/bash -x

USER=${FTP_CREDS%:*}
PASS=${FTP_CREDS#*:}

MANIFEST=(`curl -1 -v --disable-epsv --ftp-skip-pasv-ip -u ${USER}:${PASS} --ftp-ssl ftp://ftp.box.com/COMPLETE.TXT`)

MD5=${MANIFEST[0]}
FILE=${MANIFEST[1]}
cd /var/jenkins/workspace/build
LOCAL_FILES=(`curl http://web/files/emulex/ | grep zip | awk -F'"' '{print $6}'`)
if [[ " ${LOCAL_FILES[@]} " =~ " ${FILE} " ]]; then
	echo "The file ${FILE} already exists in local repo"
	exit 0
else
	echo "Found new file from vendor repository.  Downloading..."
	curl -1 -v --disable-epsv --ftp-skip-pasv-ip -u ${USER}:${PASS} --ftp-ssl ftp://ftp.box.com/${FILE} -O
	echo "Verifying file...."
	LOCAL_MD5=`openssl md5 "$FILE" | awk '{print $2}'`
	if [ "$MD5" = "$LOCAL_MD5" ]; then
		echo "Package verifcation completed."
		echo "Remote MD5: ${MD5} | Local MD5: ${LOCAL_MD5}"
		echo "Uploading file to local web server"
		scp ${FILE} web:/var/www/files/emulex
		curl http://web/files/emulex/ | grep ${FILE}
		[ $? = 0 ] && echo "File uploaded successfully"	
	else
		echo "The MD5 checksum of the downloaded file does not match the remote file."
		exit 1
	fi
fi

