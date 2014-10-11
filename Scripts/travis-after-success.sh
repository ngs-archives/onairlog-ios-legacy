#!/bin/sh
set -eu
bundle exec rake ipa:build
bundle exec rake ipa:distribute:s3

