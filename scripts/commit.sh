#!/bin/bash

set -e

MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Usage: scripts/commit.sh \"Commit message\""
    exit 1
fi

git add -A
git commit -m "$MESSAGE"

