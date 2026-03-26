#!/usr/bin/env bash
set -o errexit

bundle install
npm install
npm run build
npm run build:css
bundle exec rails assets:precompile
bundle exec rails db:migrate
