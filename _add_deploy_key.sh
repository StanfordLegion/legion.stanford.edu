#!/bin/bash

set -e

if [[ -z "$GIT_DEPLOY_KEY" ]]; then
    echo "No deploy key found in environment"
    exit 1
fi

ssh-add - <<< "$GIT_DEPLOY_KEY"
