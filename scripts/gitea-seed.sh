#!/bin/sh
# Publishes the bundled git history into Gitea on first start.
#
# Gitea keeps its data in a Docker volume, which is not part of the project
# folder and so is not included when the folder is zipped. Without this, a
# fresh "docker compose up" would leave an empty Gitea. This recreates the
# account and pushes the repository from the .git directory that ships with
# the project. Idempotent: it exits early if the repository already exists.
set -e

apk add --no-cache git curl >/dev/null 2>&1

GITEA=http://gitea:3000
USER=shashank
FULL_NAME="Gangaraju Shashank"
EMAIL=2400639@sit.singaporetech.edu.sg
PASSWORD=2400639@sit.singaporetech.edu.sg
PASSWORD_ENC=2400639%40sit.singaporetech.edu.sg
REPO=ssd-practical

echo "[gitea-seed] waiting for Gitea"
i=0
while [ "$i" -lt 60 ]; do
  if curl -sf "$GITEA/api/v1/version" >/dev/null 2>&1; then
    break
  fi
  i=$((i + 1))
  sleep 3
done

if ! curl -sf "$GITEA/api/v1/version" >/dev/null 2>&1; then
  echo "[gitea-seed] Gitea did not come up in time" >&2
  exit 1
fi

if curl -sf "$GITEA/api/v1/repos/$USER/$REPO" >/dev/null 2>&1; then
  echo "[gitea-seed] repository already present, nothing to do"
  exit 0
fi

# Register the account. Gitea makes the first registered user an admin.
echo "[gitea-seed] creating the '$USER' account"
JAR=/tmp/cookies
CSRF=$(curl -s -c "$JAR" "$GITEA/user/sign_up" \
  | sed -n 's/.*name="_csrf" value="\([^"]*\)".*/\1/p' | head -1)
curl -s -b "$JAR" -c "$JAR" -o /dev/null -X POST "$GITEA/user/sign_up" \
  --data-urlencode "_csrf=$CSRF" \
  --data-urlencode "user_name=$USER" \
  --data-urlencode "email=$EMAIL" \
  --data-urlencode "password=$PASSWORD" \
  --data-urlencode "retype=$PASSWORD"

# Show the full name required by Q3 in the web UI.
curl -s -o /dev/null -u "$USER:$PASSWORD" -X PATCH \
  "$GITEA/api/v1/admin/users/$USER" -H "Content-Type: application/json" \
  -d "{\"login_name\":\"$USER\",\"source_id\":0,\"full_name\":\"$FULL_NAME\",\"email\":\"$EMAIL\"}"

echo "[gitea-seed] creating the '$REPO' repository"
curl -sf -o /dev/null -u "$USER:$PASSWORD" -X POST "$GITEA/api/v1/user/repos" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$REPO\",\"private\":false}"

echo "[gitea-seed] pushing the bundled history"
git clone --bare /repo /tmp/repo.git >/dev/null 2>&1
cd /tmp/repo.git
git push "http://$USER:$PASSWORD_ENC@gitea:3000/$USER/$REPO.git" main >/dev/null 2>&1

echo "[gitea-seed] done - browse it at http://127.0.0.1:3000/$USER/$REPO"
