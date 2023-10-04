#!/bin/bash
#

# Configuration
DROPSITEURL="https://TENANT.sharepoint.com/:f:/s/SITENAME/UNIQUEID"
NAME="jose"
SURNAME="maria"
FILEPATH="./"
FILENAME="test.jpg"
SCRIPTLOCATON=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

timestamp=$(date +%Y%m%d_%H%M%S)

# Start
echo "Starting Upload" >> $FILEPATH/result.txt
echo "Date and time: "$timestamp >> $FILEPATH/result.txt

#First request need to have <DROP_SITE_URL> replaced and returns the real URL via a 302 redirect
raw_req=$(<$SCRIPTLOCATON/templates/get_real_URL.req)
req=${raw_req/<DROP_SITE_URL>/"$DROPSITEURL"}
buff=$(eval "$req")
echo $buff >> $FILEPATH/result.txt
URL=$(echo $buff | sed -e 's/.*href="\(.*\)">here.*/\1/')

#Second request need to have <TENANT_URL> replaced and returns the Badger Token
TENANTURL=$(echo $URL | sed -e 's/\(.*\)\/sites.*/\1/')
raw_req=$(<$SCRIPTLOCATON/templates/Badger-init.req)
req=${raw_req/<TENANT_URL>/"$TENANTURL"}
buff=$(eval "$req")
echo $buff >> $FILEPATH/result.txt
BADGERTOKEN=$(echo $buff | sed -e 's/.*token":"\(.*\)","expiry.*/\1/')

#Third request need to have <SITE_URL>, <SHARE_ID>, <BADGER_TOKEN> and <REAL_URL> replaced and the return can be ignored
SITEURL=$(echo $URL | sed -e 's/\(.*\)_layouts.*/\1/')
SHAREID=$(echo $URL | sed -e 's/.*amp;s=\(.*\).*/\1/')
raw_req=$(<$SCRIPTLOCATON/templates/Request_permission.req)
req=${raw_req/<SITE_URL>/"$SITEURL"}
req=${req/<SHARE_ID>/"$SHAREID"}
req=${req/<BADGER_TOKEN>/"$BADGERTOKEN"}
req=${req/<REAL_URL>/"$URL"}
buff=$(eval "$req")
echo $buff >> $FILEPATH/result.txt

#Fourth request need to have <TENANT_URL>, <BADGER_TOKEN>, <NAME> and <SURNAME> replaced and returns the User Token
raw_req=$(<$SCRIPTLOCATON/templates/Request_user_token.req)
req=${raw_req/<BADGER_TOKEN>/"$BADGERTOKEN"}
req=${req/<TENANT_URL>/"$TENANTURL"}
req=${req/<TENANT_URL>/"$TENANTURL"}
req=${req/<NAME>/"$NAME"}
req=${req/<SURNAME>/"$SURNAME"}
buff=$(eval "$req")
echo $buff >> $FILEPATH/result.txt
USERTOKEN=$(echo $buff | sed -e 's/.*token":"\(.*\)","expiry.*/\1/')

#fifth request need to have <SITE_URL>, <SHARE_ID>, <NAME>, <SURNAME>, <FILENAME>, <USER_TOKEN>, <TENANT_URL> and <REAL_URL> replaced and the returns the upload url
raw_req=$(<$SCRIPTLOCATON/templates/Request_upload_url.req)
req=${raw_req/<SITE_URL>/"$SITEURL"}
req=${req/<SHARE_ID>/"$SHAREID"}
req=${req/<NAME>/"$NAME"}
req=${req/<SURNAME>/"$SURNAME"}
req=${req/<FILENAME>/"$FILENAME"}
req=${req/<USER_TOKEN>/"$USERTOKEN"}
req=${req/<TENANT_URL>/"$TENANTURL"}
req=${req/<REAL_URL>/"$URL"}
buff=$(eval "$req")
echo $buff >> $FILEPATH/result.txt
UPLOADURL=$(echo $buff | sed -e 's/.*uploadUrl":"\(.*\)"}.*/\1/')

#sixth request need to have <SITE_URL>, <SHARE_ID>, <NAME>, <SURNAME>, <FILENAME>, <USER_TOKEN>, <CONTENT_RANGE>, <TENANT_URL> and <REAL_URL> replaced and the returns if the upload was completed
#TODO: Allow bigger file transfers, this implementation attempts to upload all the file at once and may break because of Content-Range always being full size
raw_req=$(<$SCRIPTLOCATON/templates/Upload_session.req)
req=${raw_req/<UPLOAD_URL>/"$UPLOADURL"}
req=${req/<TENANT_URL>/"$TENANTURL"}
req=${req/<REAL_URL>/"$URL"}
req=${req/<PAYLOAD>/"$FILEPATH$FILENAME"}
#Content-Range 0-17/18
filename=$FILEPATH$FILENAME
# Check if the file exists
if [ -f "$filename" ]; then
  # Get the length of the file
  filesize=$(wc -c <"$filename")
else
  echo "Given file does not exist."
fi
CONTENTRANGE="0-"$((filesize-1))"/"$filesize
req=${req/<CONTENT_RANGE>/"$CONTENTRANGE"}
#echo $req
buff=$(eval "$req")
echo $buff >> $FILEPATH/result.txt