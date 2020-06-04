#!/bin/bash
CLOUDFRONT_IP_RANGES_FILE_PATH="/etc/nginx/cdn-ip/cloudfront.ip"
WWW_GROUP="www-data"
WWW_USER="www-data"

CLOUDFRONT_REMOTE_FILE="https://ip-ranges.amazonaws.com/ip-ranges.json"
CLOUDFRONT_LOCAL_FILE="/var/tmp/cloudfront-ips.json"

if [ -f /usr/bin/fetch ];
then
    fetch $CLOUDFRONT_REMOTE_FILE --no-verify-hostname --no-verify-peer -o $CLOUDFRONT_LOCAL_FILE --quiet
else
    wget -q $CLOUDFRONT_REMOTE_FILE -O $CLOUDFRONT_LOCAL_FILE --no-check-certificate
fi

echo "# Amazon CloudFront IP Ranges" > $CLOUDFRONT_IP_RANGES_FILE_PATH
echo "# Generated at $(date) by $0" >> $CLOUDFRONT_IP_RANGES_FILE_PATH
echo "" >> $CLOUDFRONT_IP_RANGES_FILE_PATH

cat $CLOUDFRONT_LOCAL_FILE  | jq -r '.prefixes[] | select(.service=="CLOUDFRONT") | .ip_prefix' | while read i; do echo "set_real_ip_from ${i};"  >> $CLOUDFRONT_IP_RANGES_FILE_PATH; done;

# echo "real_ip_header X-Forwarded-For;" >> $CLOUDFRONT_IP_RANGES_FILE_PATH
# echo "real_ip_recursive on;" >> $CLOUDFRONT_IP_RANGES_FILE_PATH
echo "" >> $CLOUDFRONT_IP_RANGES_FILE_PATH

chown $WWW_USER:$WWW_GROUP $CLOUDFRONT_IP_RANGES_FILE_PATH

rm -rf $CLOUDFRONT_LOCAL_FILE

service nginx restart
