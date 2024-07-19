#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# # Run database migrations
# bundle exec rake db:migrate
# Prepare the database (create, migrate, and seed if necessary)
bundle exec rake db:prepare
# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"


