#!/bin/sh

#  (The MIT License)
#
#  Copyright (c) 2013 Mamadou Babaei
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.


#  Original Project : https://gitlab.com/NuLL3rr0r/babaei.net/-/tree/master/2013-03-09-getting-real-ip-addresses-using-nginx-and-cloudflare
#  Reference: https://www.babaei.net/blog/getting-real-ip-addresses-using-nginx-and-cloudflare/
#  Updated By: https://github.com/uf1y/get-real-ip-addresses-using-nginx-and-cloudflare-ips-list

CLOUDFLARE_IP_RANGES_FILE_PATH="/etc/nginx/cloudflare/cloudflare-ips"

# Nginx running user
WWW_GROUP="www-data"
WWW_USER="www-data"

CLOUDFLARE_IPSV4_REMOTE_FILE="https://www.cloudflare.com/ips-v4"
CLOUDFLARE_IPSV6_REMOTE_FILE="https://www.cloudflare.com/ips-v6"
CLOUDFLARE_IPSV4_LOCAL_FILE="/var/tmp/cloudflare-ips-v4"
CLOUDFLARE_IPSV6_LOCAL_FILE="/var/tmp/cloudflare-ips-v6"

if [ -f /usr/bin/fetch ];
then
    fetch $CLOUDFLARE_IPSV4_REMOTE_FILE --no-verify-hostname --no-verify-peer -o $CLOUDFLARE_IPSV4_LOCAL_FILE --quiet
    fetch $CLOUDFLARE_IPSV6_REMOTE_FILE --no-verify-hostname --no-verify-peer -o $CLOUDFLARE_IPSV6_LOCAL_FILE --quiet
else
    wget -q $CLOUDFLARE_IPSV4_REMOTE_FILE -O $CLOUDFLARE_IPSV4_LOCAL_FILE --no-check-certificate
    wget -q $CLOUDFLARE_IPSV6_REMOTE_FILE -O $CLOUDFLARE_IPSV6_LOCAL_FILE --no-check-certificate
fi

IPV4_SUCCEED=0
IPV6_SUCCEED=0

# Verify IPv4 address in file content
grep "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/[0-9]\+$" $CLOUDFLARE_IPSV4_LOCAL_FILE
if [ 0 -eq $? ]; then
    IPV4_SUCCEED=1
fi
# Verify IPv6 address in file content
grep "^[a-f0-9]\+:[0-9a-f:]\+/[0-9]\+" $CLOUDFLARE_IPSV6_LOCAL_FILE
if [ 0 -eq $? ]; then
    IPV6_SUCCEED=1
fi

# Create new cloudflare-ips file
if [ 1 -eq $IPV4_SUCCEED ] ||  [ 1 -eq $IPV6_SUCCEED ]; then
    echo "# CloudFlare IP Ranges" > $CLOUDFLARE_IP_RANGES_FILE_PATH
    echo "# Generated at $(date) by $0" >> $CLOUDFLARE_IP_RANGES_FILE_PATH
fi

# Add IPv4 ips to cloudflare-ips file
if [ 1 -eq $IPV4_SUCCEED ]; then
    echo "" >> $CLOUDFLARE_IP_RANGES_FILE_PATH
    awk '{ print "set_real_ip_from " $0 ";" }' $CLOUDFLARE_IPSV4_LOCAL_FILE >> $CLOUDFLARE_IP_RANGES_FILE_PATH
fi

# Add IPv6 ips to cloudflare-ips file
if [ 1 -eq $IPV6_SUCCEED ]; then
    echo "" >> $CLOUDFLARE_IP_RANGES_FILE_PATH
    awk '{ print "set_real_ip_from " $0 ";" }' $CLOUDFLARE_IPSV6_LOCAL_FILE >> $CLOUDFLARE_IP_RANGES_FILE_PATH
fi

if [ 1 -eq $IPV4_SUCCEED ] ||  [ 1 -eq $IPV6_SUCCEED ]; then
    echo "" >> $CLOUDFLARE_IP_RANGES_FILE_PATH
    echo "real_ip_header CF-Connecting-IP;" >> $CLOUDFLARE_IP_RANGES_FILE_PATH
    echo "" >> $CLOUDFLARE_IP_RANGES_FILE_PATH
fi

chown $WWW_USER:$WWW_GROUP $CLOUDFLARE_IP_RANGES_FILE_PATH

rm -rf $CLOUDFLARE_IPSV4_LOCAL_FILE
rm -rf $CLOUDFLARE_IPSV6_LOCAL_FILE
