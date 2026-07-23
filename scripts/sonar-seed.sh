#!/bin/sh
# Sets the SonarQube admin password on first start.
#
# SonarQube keeps its data in a Docker volume, which is not part of the
# project folder, so a fresh "docker compose up" starts from the built-in
# admin/admin. This applies the password the practical requires. Idempotent:
# it exits early if that password already works.
set -e

apk add --no-cache curl >/dev/null 2>&1

SONAR=http://sonarqube:9000
PASSWORD='2400639@SIT.singaporetech.edu.sg'
JAR=/tmp/cookies

echo "[sonar-seed] waiting for SonarQube (first start takes a minute or two)"
i=0
while [ "$i" -lt 120 ]; do
  if curl -s "$SONAR/api/system/status" 2>/dev/null | grep -q '"status":"UP"'; then
    break
  fi
  i=$((i + 1))
  sleep 5
done

if ! curl -s "$SONAR/api/system/status" 2>/dev/null | grep -q '"status":"UP"'; then
  echo "[sonar-seed] SonarQube did not reach UP in time" >&2
  exit 1
fi

if curl -s -u "admin:$PASSWORD" "$SONAR/api/authentication/validate" \
    | grep -q '"valid":true'; then
  echo "[sonar-seed] password already set, nothing to do"
  exit 0
fi

# This SonarQube version refuses basic auth on write endpoints, so log in for a
# session cookie and send the matching XSRF token with the change.
echo "[sonar-seed] setting the admin password"
rm -f "$JAR"
curl -s -c "$JAR" -o /dev/null -X POST "$SONAR/api/authentication/login" \
  --data-urlencode "login=admin" --data-urlencode "password=admin"

XSRF=$(grep -i XSRF "$JAR" | awk '{print $7}')
curl -s -b "$JAR" -H "X-XSRF-TOKEN: $XSRF" -o /dev/null \
  -X POST "$SONAR/api/users/change_password" \
  --data-urlencode "login=admin" \
  --data-urlencode "previousPassword=admin" \
  --data-urlencode "password=$PASSWORD"

if curl -s -u "admin:$PASSWORD" "$SONAR/api/authentication/validate" \
    | grep -q '"valid":true'; then
  echo "[sonar-seed] done - log in at http://127.0.0.1:9000 as admin"
else
  echo "[sonar-seed] password change did not take effect" >&2
  exit 1
fi
