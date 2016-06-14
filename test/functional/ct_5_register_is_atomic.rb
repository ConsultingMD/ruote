
require File.expand_path('../concurrent_base', __FILE__)


class CtRegisterIsAtomic < Test::Unit::TestCase
  include FunctionalBase

  def setup

    @storage = determine_storage({})

    # Need a shared worker between the two dashboards; also, create @dashboard
    # so the asserts from Base work.

    @dashboard = @dashboard0 = Ruote::Engine.new(Ruote::Worker.new(@storage))
    @dashboard1 = Ruote::Engine.new(@storage, false)
  end

  def teardown

    @storage.purge!

    @dashboard0.shutdown
    @dashboard1.shutdown
  end


  # One client registers a new list of participants while
  # a worker is processing messages: either the whole list should
  # be updated, or none of it should
  #
  def test_register_is_atomic

    alpha_def = Ruote.process_definition do
      alpha
    end

    beta_def = Ruote.process_definition do
      beta
    end

    @dashboard0.register do
      participant 'alpha', Ruote::NoOpParticipant
    end

    wfid = @dashboard1.launch(alpha_def)
    @dashboard1.wait_for(wfid)

    $test_register_is_atomic_can_still_run_alpha = lambda do

      wfid = @dashboard1.launch(alpha_def)
      @dashboard1.wait_for(wfid)

      assert_no_errors(wfid)
    end

    @dashboard0.register do
      $test_register_is_atomic_can_still_run_alpha.call

      participant 'beta', Ruote::NoOpParticipant
    end

    wfid = @dashboard1.launch(beta_def)

    wait_for(wfid)

    assert_no_errors(wfid)
  end
end
