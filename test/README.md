
# ruote testing

getting a test environment (in an rvm world)

    $ cp Gemfile.template Gemfile

    $ bundle install

running all the tests

    $ ruby test/test.rb

running a specific test

    $ ruby test/functional/ft_1_process_status.rb

running a test with file persistence :

    $ RUOTE_STORAGE=fs ruby test/functional/eft_2_sequence.rb

