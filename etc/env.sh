#!/usr/bin/env bash

export PYTHON_EGG_CACHE="/home/angus/.python-eggs"
export VIRTUAL_ENV="/home/angus/angus-env"
export PATH="/home/angus/angus-env/bin:$PATH"
export SERVICE_FILE="/home/angus/services.json"
export HTPASSWD="/home/angus/htpasswd"
export DATABASE="sqlite:///home/angus/client.db"

exec $*
