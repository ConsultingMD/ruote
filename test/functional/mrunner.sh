#!/bin/bash
#
# TODO: Work with other storage
#
# TODO: Work with regular ruby instead of bundle

export RUOTE_WORKERS=4
export NOISY=true
export RUOTE_STORAGE=sequel
export RUOTE_STORAGE_DB=mysql2://root@localhost/ruote_test

while [ ! -f _stop ] ; do
  bundle exec ruby test/functional/mpt_1_heavy_concurrence.rb --name test_fast_concurrence_completion
done
