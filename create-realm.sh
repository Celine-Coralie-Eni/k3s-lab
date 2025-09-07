#!/bin/bash
set -e

echo "Waiting for Keycloak..."
until /opt/keycloak/bin/kcadm.sh config credentials --server http://keycloak.keycloak.svc.cluster.local \
  --realm master --user admin --password admin123; do
  echo "Keycloak not ready yet, retrying..."
  sleep 5
done

echo "Authenticated to Keycloak. Creating realm..."

# Create realm
/opt/keycloak/bin/kcadm.sh create realms -s realm=lab -s enabled=true

# Create client
/opt/keycloak/bin/kcadm.sh create clients -r lab \
  -s clientId=lab-api -s enabled=true -s protocol=openid-connect \
  -s standardFlowEnabled=true -s directAccessGrantsEnabled=true -s serviceAccountsEnabled=false \
  -s publicClient=true -s redirectUris='["http://localhost:8080/*","http://keycloak.local/*"]'

# Create test user
/opt/keycloak/bin/kcadm.sh create users -r lab -s username=tester -s enabled=true
USER_ID=$(/opt/keycloak/bin/kcadm.sh get users -r lab -q username=tester --fields id | sed -n 's/.*"id" *: *"\([^"]*\)".*/\1/p' | head -n1)
if [ -n "${USER_ID}" ]; then
  /opt/keycloak/bin/kcadm.sh set-password -r lab --userid ${USER_ID} --new-password tester123
else
  echo "Failed to determine user id for tester" >&2
  exit 1
fi

echo "Realm creation complete."
