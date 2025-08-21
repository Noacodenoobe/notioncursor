#!/bin/bash

set -e

BRANCH="${1:-main}"

git push origin "$BRANCH"

