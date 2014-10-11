#!/bin/sh
set -eu
bundle install --path=vendor/bundle --binstubs=vendor/bin
bundle exec rake setup
bundle exec rake certificate:add
bundle exec rake certificate:install

