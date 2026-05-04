#!/usr/bin/env bash

set -e

DB_NAME="fortnite_festival"

echo "Running EXPLAIN ANALYZE reports..."
sudo -n runuser -u postgres -- psql -d "${DB_NAME}" -f sql/04_explain_analysis.sql