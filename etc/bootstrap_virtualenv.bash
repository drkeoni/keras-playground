#!/bin/bash

#
# from http://stackoverflow.com/questions/4324558/whats-the-proper-way-to-install-pip-virtualenv-and-distribute-for-python
#

# Select current version of virtualenv:
VERSION=15.2.0
# Name your first "bootstrap" environment:
INITIAL_ENV=py-env0
# Options for your first environment:
ENV_OPTS='--no-site-packages --distribute'
# Set to whatever python interpreter you want for your first environment:
PYTHON=/usr/local/bin/python3
URL_BASE=https://pypi.python.org/packages/source/v/virtualenv

# --- Real work starts here ---
# 05.10.18 -- needed to add "follow redirects".  This recipe is probably outdated...
curl -L -O $URL_BASE/virtualenv-$VERSION.tar.gz
tar xzf virtualenv-$VERSION.tar.gz
# Create the first "bootstrap" environment.
$PYTHON virtualenv-$VERSION/virtualenv.py $ENV_OPTS $INITIAL_ENV
# Don't need this anymore.
rm -rf virtualenv-$VERSION
# Install virtualenv into the environment.
$INITIAL_ENV/bin/pip3 install virtualenv-$VERSION.tar.gz
# clean up
rm -f virtualenv-$VERSION.tar.gz
