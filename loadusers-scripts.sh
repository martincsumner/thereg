#!/bin/bash

################################################################################
# --------- DESCRIPTION  ----------
#
# - script for generatign users in RH-SSO.
# - outputs usernames/passwords to a csv file for consumption in a load test.



######################################
# ----- PARAMS TO BE CONFIGURED -----

PROTOCOL='http'
HOST='localhost'
PORT='8080'
REALM='testrealm'
USERNAME='testuser' #user's username
PASSWORD='testpass' #user's etc.
CLIENT_ID='testclient'   #name of the sso 'client'
SECRET='4b607ab0-6df9-46e9-853f-34aea0c939c1' #key from credentials
NO_USERS=2 #how many users to you want to create?


######################################
# ----- script - you should not need to touch this (hopefully :-) -----


TOKEN_URL="${PROTOCOL}://${HOST}:${PORT}/auth/realms/${REALM}/protocol/openid-connect/token"
USER_URL="${PROTOCOL}://${HOST}:${PORT}/auth/admin/realms/${REALM}/users"

GRANT=$(curl --silent -k -X POST "${TOKEN_URL}" \
 -H "Content-Type: application/x-www-form-urlencoded" \
 -H "Host: ${HOST}:${PORT}" \
 -d "username=${USERNAME}" \
 -d "password=${PASSWORD}" \
 -d 'grant_type=password' \
 -d "client_id=${CLIENT_ID}" \
 -d 'scope=openid' \
 -d "client_secret=${SECRET}" \
);

OUTPUTCSVSTR=""

# now get the access token
ACCESS_TOKEN=`echo $GRANT | jq -r '.access_token'`
#echo "Retrieved access token: $ACCESS_TOKEN"

for j in `seq 1 $NO_USERS`;

do

  USERNAME="User$j"
  PASSWORD="pass$j"
  FIRSTNAME="firstname$j"
  SURNAMENAME="surname$j"
  EMAIL="$USERNAME@blah.com"

  JSON_STRING=$( jq -n \
                    --arg un "$USERNAME" \
                    --arg pa "$PASSWORD" \
                    --arg fn "$FIRSTNAME" \
                    --arg sn "$SURNAMENAME" \
                    --arg em "$EMAIL" \
                    '{username: $un, firstName: $fn, lastName: $sn, email: $em, enabled: true, credentials: [{type: "password",temporary: false, value: $pa}]}')

  curl -v -X POST $USER_URL -H "Content-Type: application/json" -H "Authorization: bearer $ACCESS_TOKEN"  \
  -d "$JSON_STRING"

 CSVLINE='%s,%s,%s,%s,%s,%s,%s,%s\n'
 printf -v TEMPSTR "$CSVLINE" "$USERNAME" "$PASSWORD" "$CLIENT_ID" "$SECRET" "$PROTOCOL" "$HOST" "$PORT" "$REALM"

 OUTPUTCSVSTR="${OUTPUTCSVSTR}${TEMPSTR}"

done

printf "%s" "$OUTPUTCSVSTR" > users.csv
