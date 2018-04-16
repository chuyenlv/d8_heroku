#!/bin/bash

JSON=composer.json
EXE=composer

# CI options
export COMPOSER_DISCARD_CHANGES=1
export COMPOSER_NO_INTERACTION=1

if [ ! -f "$JSON" ]
then
  echo ${txtred}Error: No $JSON found ${txtrst}
  exit 1
fi

FOUND=`which $EXE`
COMPOSER_PARMS="--no-ansi --no-dev --no-interaction --optimize-autoloader --no-progress"

# Install Composer dependencies
echo -e "\n${txtylw}Invoking: $FOUND install $COMPOSER_PARMS ${txtrst}"
$FOUND install $COMPOSER_PARMS
