#!/usr/bin/env bash

set -e

echo "Starting PostgreSQL..."
sudo service postgresql start

echo
echo "Launching Fortnite Festival Database CLI..."
python3 -m app.cli