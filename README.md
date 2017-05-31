# Advanced deployment workflow Drupal 8.

## Purpose
This repository is an advanced deployment workflow on Pantheon integrating tools such as:
* Docksal.
* Dependency management with Composer
* Build process on Circle CI

## Circle CI Setup
The following sensitive variables will need to be stored in Circle CI as environment variables
* GIT_EMAIL
    * Email address of the account used to make Git commits to the Heroku repository
* GIT_USERNAME
    * Username of the account used to make Git commits to the Heroku repository
* GIT_TOKEN
    * A Github token with read access to the source repository
* GIT_BRANCH_DEPLOY
    * Branch name used to deploy to branch master on Pantheon
* GIT_SKIP_BRANCH
    * List branch skip build multidev. Example: `staging|production`, this will skip branch staging and production.
* PANTHEON_SITE_UUID
    * The Pantheon UUID of the site to deploy to
* PANTHEON_GIT_URL
    * The SSH URL of the Pantheon Git repository for the above site
* PANTHEON_MACHINE_TOKEN
    * A Pantheon machine token for a user with access to the above repository
* PANTHEON_FROM_ENV
    * The env will clone database and files when create new multidev, default is `dev` env.

Deploy to pantheon requirement ssh for access repo from pantheon, so you have to add private key in tab `SSH Permissions` on page settings. And public key added to account in dashboard pantheon.

## See also
* [Docksal](http://docksal.readthedocs.io/en/master/)
* [Composer](https://getcomposer.org/)
* [CircleCI](https://circleci.com/)
* [Terminus](https://pantheon.io/docs/terminus/)
