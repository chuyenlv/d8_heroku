#!/bin/bash
PHPCS_RESULT="$(phpcs --standard=Drupal web)"

echo "${PHPCS_RESULT}"

STR_ERROR="ERROR"

if echo "$PHPCS_RESULT" | grep -q "$STR_ERROR"; then
  curl -d '{ "body": "'"$PHPCS_RESULT"'" }' -X POST https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/commits/$CIRCLE_SHA1/comments?access_token=$GIT_TOKEN
  exit 0
fi
