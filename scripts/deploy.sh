#!/bin/bash

# Variables
BUILD_DIR=$(pwd)
txtred=$(tput setaf 1) # Red
txtgrn=$(tput setaf 2) # Green
txtylw=$(tput setaf 3) # Yellow
txtblu=$(tput setaf 4) # Blue
txtpur=$(tput setaf 5) # Purple
txtcyn=$(tput setaf 6) # Cyan
txtwht=$(tput setaf 7) # White
txtrst=$(tput sgr0) # Text reset.

COMMIT_MESSAGE="$(git show --name-only --decorate)"
GITHUB_API_URL="https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"

if [ -z "${GIT_BRANCH_DEPLOY+1}" ]
then
  # variable is not defined, use default
  GIT_BRANCH_DEPLOY="master"
fi

# If we are not and the master branch and this isn't a pull request, don't deploy to Pantheon
if [[ "${CIRCLE_BRANCH}" != "${GIT_BRANCH_DEPLOY}" && -z "$CI_PULL_REQUEST" ]]
then
  echo -e "\n${txtred}Skipping deployment to Pantheon - not on the $GIT_BRANCH_DEPLOY branch and not a pull request.\nOpen a pull request to deploy to a multidev on Pantheon. ${txtrst}"
  exit 0
fi

BASE_SKIP="dev|test|live"
if [ -n "${GIT_SKIP_BRANCH+1}" ]
then
  GIT_SKIP_BRANCH="$GIT_SKIP_BRANCH|$BASE_SKIP"
else
  GIT_SKIP_BRANCH="dev|test|live"
fi

# Don't deploy to Pantheon with some branch skip
for name in $GIT_SKIP_BRANCH; do
  if [[ "${name}" == "${CIRCLE_BRANCH}" ]]
  then
    echo "Skip: Branch $CIRCLE_BRANCH skip to build multidev."
    exit 0
  fi
done

if [ -z "${PANTHEON_FROM_ENV+1}" ]
then
  # variable is not defined, use default
  PANTHEON_FROM_ENV="dev"
fi

cd $HOME

# If the Pantheon directory does not exist
if [ ! -d "$HOME/pantheon" ]
then
  # Clone the Pantheon repo
  echo -e "\n${txtylw}Cloning Pantheon repository into $HOME/pantheon  ${txtrst}"
  git clone $PANTHEON_GIT_URL pantheon
fi

cd pantheon
git fetch

# Log into terminus.
echo -e "\n${txtylw}Logging into Terminus ${txtrst}"
terminus auth:login --machine-token=$PANTHEON_MACHINE_TOKEN

# Get a list of all environments
PANTHEON_ENVS="$(terminus multidev:list $PANTHEON_SITE_UUID --format=list --field=Name)"

# Check if we are NOT on the branch deploy
if [ -n "$CI_PULL_REQUEST" ]
then
  # Get PR number
  PR_NUMBER=${CI_PULL_REQUEST##*/}
  echo -e "\n${txtylw}Processing pull request #$PR_NUMBER ${txtrst}"

  # Multidev name is the pull request
  normalize_branch="pr$PR_NUMBER"

  echo -e "\n${txtylw}Checking for the multidev environment ${normalize_branch} via Terminus ${txtrst}"

  MULTIDEV_FOUND=0

  while read -r line; do
      if [[ "${line}" == "${normalize_branch}" ]]
      then
        MULTIDEV_FOUND=1
      fi
  done <<< "$PANTHEON_ENVS"

  # If the multidev for this branch is found
  if [[ "$MULTIDEV_FOUND" -eq 1 ]]
  then
    # Send a message
    echo -e "\n${txtylw}Multidev found! ${txtrst}"
  else
    # otherwise, create the multidev branch
    echo -e "\n${txtylw}Multidev not found, creating the multidev branch ${normalize_branch} via Terminus ${txtrst}"
    terminus multidev:create $PANTHEON_SITE_UUID.$PANTHEON_FROM_ENV $normalize_branch
    git fetch
  fi

  # Checkout the correct branch
  GIT_BRANCHES="git show-ref --verify refs/heads/$normalize_branch"
  if [[ ${GIT_BRANCHES} == *"${normalize_branch}"* ]]
  then
    echo -e "\n${txtylw}Branch ${normalize_branch} found, checking it out ${txtrst}"
    git checkout $normalize_branch
  else
    echo -e "\n${txtylw}Branch ${normalize_branch} not found, creating it ${txtrst}"
    git checkout -b $normalize_branch
  fi
fi

# Delete the web and vendor subdirectories if they exist
if [ -d "$HOME/pantheon/web" ]
then
  # Remove it without folder sites.
  echo -e "\n${txtylw}Removing $HOME/pantheon/web ${txtrst}"
  find web/* -maxdepth 1 -type 'f' delete
  find web/* -maxdepth 1 -type 'd' | grep -v "sites" | xargs rm -rf
fi
if [ -d "$HOME/pantheon/vendor" ]
then
  # Remove it
  echo -e "\n${txtylw}Removing $HOME/pantheon/vendor ${txtrst}"
  rm -rf $HOME/pantheon/vendor
fi

mkdir -p web
mkdir -p vendor

echo -e "\n${txtylw}Rsyncing $BUILD_DIR/web ${txtrst}"
rsync -a $BUILD_DIR/web/* ./web/

# Delete file settings.local.php if they exist
if [ -e "$HOME/pantheon/web/sites/default/settings.local.php" ]
then
  echo -e "\n${txtylw}Removing settings.local.php ${txtrst}"
  rm $HOME/pantheon/web/sites/default/settings.local.php
fi

echo -e "\n${txtylw}Copying $BUILD_DIR/pantheon.yml ${txtrst}"
cp $BUILD_DIR/pantheon.yml .

echo -e "\n${txtylw}Rsyncing $BUILD_DIR/vendor ${txtrst}"
rsync -a $BUILD_DIR/vendor/* ./vendor/

echo -e "\n${txtylw}Rsyncing $BUILD_DIR/config ${txtrst}"
rsync -a $BUILD_DIR/config/* ./config/

echo -e "\n${txtylw}Copying $BUILD_DIR/composer.json and $BUILD_DIR/composer.lock ${txtrst}"
cp $BUILD_DIR/composer.* .

if [ -n "${SLACK_HOOK_URL+1}" ]
then
  echo -e "\n${txtylw}Create/Update the secret Webhook URL into a file called secrets.json ${txtrst}"
  echo "{\"slack_url\": \"$SLACK_HOOK_URL\"}" > secrets.json
fi

echo -e "\n${txtylw}Forcibly adding all files and committing${txtrst}"
git add -A --force .
git commit -m "Circle CI build $CIRCLE_BUILD_NUM by $CIRCLE_PROJECT_USERNAME" -m "$COMMIT_MESSAGE"

# Force push to Pantheon
if [ $CIRCLE_BRANCH != $GIT_BRANCH_DEPLOY ]
then
  echo -e "\n${txtgrn}Pushing the ${normalize_branch} branch to Pantheon ${txtrst}"
  git push -u origin $normalize_branch --force
else
  echo -e "\n${txtgrn}Pushing the master branch to Pantheon ${txtrst}"
  git push -u origin master --force

  if [[ "$DEPLOY_CLONE_CONTENT_FROM_ENV" == "test" || "$DEPLOY_CLONE_CONTENT_FROM_ENV" == "live" ]]; then
    terminus env:clone-content $PANTHEON_SITE_UUID.$DEPLOY_CLONE_CONTENT_FROM_ENV dev -y
  fi
fi

echo -e "\n${txtylw}Cleaning up multidevs from closed pull requests...${txtrst}"
cd $BUILD_DIR
while read -r b; do
  if [[ $b =~ ^pr[0-9]+ ]]
  then
    PR_NUMBER=${b#pr}
  else
    echo -e "\n${txtylw}NOT deleting the multidev '$b' since it was created manually ${txtrst}"
    continue
  fi
  echo -e "\n${txtylw}Analyzing the multidev: $b...${txtrst}"
  PR_RESPONSE="$(curl --write-out %{http_code} --silent --output /dev/null $GITHUB_API_URL/pulls/$PR_NUMBER)"
  if [ $PR_RESPONSE -eq 200 ]
  then
    PR_STATE="$(curl $GITHUB_API_URL/pulls/$PR_NUMBER | jq -r '.state')"
    if [ "open" == "$PR_STATE"  ]
    then
      echo -e "\n${txtylw}NOT deleting the multidev '$b' since the pull request is still open ${txtrst}"
    else
      echo -e "\n${txtred}Deleting the multidev for closed pull request #$PR_NUMBER...${txtrst}"
      terminus multidev:delete $PANTHEON_SITE_UUID.$b --delete-branch --yes
    fi
  else
    echo -e "\n${txtred}Invalid pull request number: $PR_NUMBER...${txtrst}"
  fi
done <<< "$PANTHEON_ENVS"
