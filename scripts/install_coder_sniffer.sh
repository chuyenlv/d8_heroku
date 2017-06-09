#!/bin/bash
if [ ! -d "$HOME/coder" ]
then
  # Clone terminus if it doesn't exist
  echo -e "Installing Coder Sniffer...\n"
  git clone --branch 8.x-2.x http://git.drupal.org/project/coder.git ~/coder
  cd "$HOME/coder"
  composer install
  cd -
else
  # Otherwise make sure terminus is up to date
  cd "$HOME/coder"
  git pull
  composer install
  cd -
fi
