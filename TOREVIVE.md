## Goal

* Ruby 2.0 and above only
* ruote_sequel with Aurora & MySQL only
* ability to test and patch either ruote or ruote-sequel gem

## Followup goals

* Integrate with Grand Rounds CI environment ("honesty")
* Find & fix heisenspecs (identified two during initial round of revivification)
* Enhance concurrency tests:
  * Verify / fix races with monitors
  * Verify / fix race on rapid concurrence subexpression completion
* Upgrade / replace underlying gems (ruby2ruby in particular looks hairy, old, and wrong)

## Non-goals

* Running or testing without bundler

## Approach

* Fix what is easy
* Deprecate what is hard and not necessary for GR

## Tasks
* [x] get rid of the distraction of supporting rubygems in addition to bundler in the tests
* [x] include modern debugger (byebug)

* [x] ut_22_filter.rb: 50 problems; first guess: json version dependency
  * Not used in GR workflows: timebox 1 hour

* [x] ft_2_errors.rb: error_in_error test. Original fault can't be reproduced. Make sure nested error is in the error logged, make sure that exceptions in handler are still caught correctly.

## Other stuff to do as we go

[ ] Run all tests by default (do not stop if unit tests fail)
[ ]
