#!/bin/sh

# This script will update given netcup domain dns record with the actual ip of the calling service
# Parameters:
# DOMAIN_NAME, the zone name eg. test.com
# DNS_RECORD_ID, the id of the dns record that should be updated
# NC_Apikey, Api Key from your netcup account
# NC_Apipw, Api password from your netcup account
# NC_CID, Customer ID from your netcup account

DOMAIN_NAME=$1
DNS_RECORD_ID=$2
NC_Apikey=$3
NC_Apipw=$4
NC_CID=$5
NC_ENDPOINT='https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON'

# Our current IP address and path to our IP cache file
#IP_ADDRESS=`dig +short myip.opendns.com @resolver1.opendns.com`
IP_ADDRESS=`drill myip.opendns.com @resolver1.opendns.com | grep myip.opendns.com | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])'`
CACHE_PATH="/tmp/ddns_cache_$DOMAIN_NAME.txt"

# Fetch last value of IP address sent to server or create cache file
if [ ! -f $CACHE_PATH ]; then touch $CACHE_PATH; fi
CURRENT=$(<$CACHE_PATH)

# If IP address hasn't changed, exit, otherwise save the new IP
if [ "$IP_ADDRESS" == "$CURRENT" ]; then exit 0; fi
echo $IP_ADDRESS > $CACHE_PATH
echo "Try logging in"
tmp=$(curl -X POST \
    $NC_ENDPOINT \
    --header 'Accept: */*' \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "action":"login",
    "param":{
        "apikey": "'$NC_Apikey'",
        "apipassword": "'$NC_Apipw'",
        "customernumber": "'$NC_CID'"
    }
}')

sid=$(echo "$tmp" | tr '{}' '\n' | grep apisessionid | cut -d '"' -f 4)
if [ "$sid" = "" ]; then
    echo "SID was empty. Login failed."
    exit 1
fi
echo "Successfully logged in"
echo "Try registering new ip $IP_ADDRESS for domain $DOMAIN_NAME"
tmp=$(curl -X POST \
    $NC_ENDPOINT \
    --header 'Accept: */*' \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "action":"updateDnsRecords",
    "param":{
        "apikey": "'$NC_Apikey'",
        "apisessionid": "'$sid'",
        "customernumber": "'$NC_CID'",
        "clientrequestid": "",
        "domainname": "'$DOMAIN_NAME'",
        "dnsrecordset": {
        "dnsrecords": [
            {
              "id": "'$DNS_RECORD_ID'",
              "hostname": "homeserver",
              "type": "A",
              "destination": "'$IP_ADDRESS'"
            }
          ]
      }
    }
}')
echo $tmp
echo "Finished updating domain $DOMAIN_NAME"
