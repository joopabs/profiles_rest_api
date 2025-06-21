#!/usr/bin/env bash

set -e

PROJECT_GIT_URL='https://github.com/joopabs/profiles_rest_api.git'

PROJECT_BASE_PATH='/usr/local/apps/profiles-rest-api'

# Set Ubuntu Language
locale-gen en_GB.UTF-8

# Install Python 3.11, SQLite and pip
echo "Installing dependencies..."
apt-get update

# Add deadsnakes PPA for Python 3.11 (if needed)
apt-get install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update

# Install Python 3.11 specifically
apt-get install -y python3.11 python3.11-dev python3.11-venv python3.11-distutils sqlite3 supervisor nginx git build-essential gcc

# Install pip for Python 3.11
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

mkdir -p $PROJECT_BASE_PATH
git clone $PROJECT_GIT_URL $PROJECT_BASE_PATH

# Create virtual environment with Python 3.11
python3.11 -m venv $PROJECT_BASE_PATH/env

# Install requirements with Python 3.11
$PROJECT_BASE_PATH/env/bin/pip install -r $PROJECT_BASE_PATH/requirements.txt uwsgi

# Run migrations
$PROJECT_BASE_PATH/env/bin/python $PROJECT_BASE_PATH/manage.py migrate

# Setup Supervisor to run our uwsgi process.
cp $PROJECT_BASE_PATH/deploy/supervisor_profiles_api.conf /etc/supervisor/conf.d/profiles_api.conf
supervisorctl reread
supervisorctl update
supervisorctl restart profiles_api

# Setup nginx to make our application accessible.
cp $PROJECT_BASE_PATH/deploy/nginx_profiles_api.conf /etc/nginx/sites-available/profiles_api.conf
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/profiles_api.conf /etc/nginx/sites-enabled/profiles_api.conf
systemctl restart nginx.service

echo "DONE! :)"