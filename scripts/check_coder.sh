#!/bin/bash
postReviewComment() {
  file=$1
  line=$2
  comment=$3
  url=$4

  curl -H "Authorization: token ${GIT_TOKEN}" --request POST --data '{"body": "${comment}", "commit_id": "${CIRCLE_SHA1}", "path": "${file}", "position": "${line}"}' $url
}

PHPCS_RESULT="$(phpcs --standard=Drupal --extensions=php,module,inc,install,test,profile,theme,css,info,txt,md web/modules/ web/themes/ web/profiles/)"

echo "${PHPCS_RESULT}"

STR_ERROR="ERROR"

if echo "$PHPCS_RESULT" | grep -q "$STR_ERROR"; then
  if [ -z "${CI_PULL_REQUEST+1}" ]
  then
    exit 0
  fi

  PR_NUMBER=${CI_PULL_REQUEST##*/}

  PHPCS_CSV="$(phpcs --standard=Drupal --extensions=php,module,inc,install,test,profile,theme,css,info,txt,md web/modules/ web/themes/ web/profiles/ --report=csv)"
  CURRENT_DIR=$(pwd)
  POST_URL="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/pulls/$PR_NUMBER/comments"
  while IFS=',' read -r f1 f2 f3 f4 f5 f6 f7 f8; do
    if [ "File" == "$f1"  ]; then
      continue
    fi

    temp="${f1%\"}"
    temp="${temp#\"}"
    file="${temp#$CURRENT_DIR/}"

    postReviewComment $file $2 $f5 $POST_URL
  done <<< "$PHPCS_CSV"
  exit 1
fi
