# opnsense-action-netcup-ddns
Dynamic DNS for opnsense for the netcup api as cronjob action

This repository contains the cron job action for opnsense and a shell script to use the ddns api of netcup. 
With this you can update multiple dns records on different domains via opnsense cron jobs.

# Installation
Clone this repo on your opnsense installation
```bash
git clone https://github.com/lubbyhst/opnsense-action-netcup-ddns.git
cd opnsense-action-netcup-ddns
```

Run install script
```bash
chmod +x ./install.sh && ./install.sh
```

# Optain Dns record id
If your DNS Type A record does not exists. Create it via the CCP Gui. After that you can optain the id via this script.
You need to modify the parameters for your account. After executing the script you find you dns record and use the id of your record in the cron job.

```bash
DOMAIN_NAME="test.com"
NC_Apikey="apikey"
NC_Apipw="apipw"
NC_CID="customer_id"
NC_ENDPOINT='https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON'

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
curl -X POST \
    $NC_ENDPOINT \
    --header 'Accept: */*' \
    --header 'Content-Type: application/json' \
    --data-raw '{
    "action":"infoDnsRecords",
    "param":{
        "apikey": "'$NC_Apikey'",
        "apisessionid": "'$sid'",
        "customernumber": "'$NC_CID'",
        "clientrequestid": "",
        "domainname": "'$DOMAIN_NAME'"        
    }
}'
```

Example output
```
{
  "serverrequestid": "dgZmd0p4j=YFhdsdo",
  "clientrequestid": "",
  "action": "infoDnsRecords",
  "status": "success",
  "statuscode": 2000,
  "shortmessage": "DNS records found",
  "longmessage": "DNS Records for this zone were found.",
  "responsedata": {
    "dnsrecords": [
      {
        "id": "54356783",
        "hostname": "testserver",
        "type": "A",
        "priority": "0",
        "destination": "82.66.268.178",
        "deleterecord": false,
        "state": "yes"
      }
    ]
  }
}
```

The ID of the dns record is "54356783".

# Configure cron job

1. Open opnsense webui
2. go to System -> Settings -> Cron
3. Click on [+] to add a new cron task
4. Define the cron interval eg. * * * * * for every minute
5. Select the command "Netcup DDNS update"
6. Set the parameters in the following order [DOMAIN_NAME DNS_RECORD_ID NC_ApiKey NC_Apipw NC_CID]
7. Define a description
8. Click save
9. Click Confirm to activate the cron task

After a successfull run, you should see the correct external ip in your ccp dns view.