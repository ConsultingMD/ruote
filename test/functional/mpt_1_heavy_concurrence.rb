
#
# Recoding ct_3_heavy_concurrence using new MultiProcessBase
#
# in order to test with Sequel storage and mysql
#
# Fri Apr 17 12:54:41 PDT 2015
#
# By Rick Cobb (cobbr2@)
#

require File.expand_path('../multiprocess_base', __FILE__)

require 'ruote/participant'

class MptHeavyConcurrence < Test::Unit::TestCase
  include MultiprocessBase

  class FooParticipant < Ruote::StorageParticipant
  end

  def register_participants(dashboard)
    dashboard.register_participant :foo, FooParticipant
  end

  def test_fast_concurrence_completion

    n = 10
    max_wait = 35
    volume = 10000      # Characters listed workitem (initial workitem size roughly n * volume)

    assert_equal(@dashboard.worker, nil, '/!\ parent process should not have a worker /!\ ')

    pdef = Ruote.process_definition do
      citerator :on_field => 'list', :to_f => 'element', :merge_type => 'stack' do
        set 'f:ii' => '${v:ii}'
        cursor :if => '${v:ii} == -1' do # Change to zero to get something that waits if we need it
          foo
        end
      end
    end

    # Test requires the Grnds patch for sequel that supports > 64K documents.
    wfid = @dashboard.launch(pdef, { :count => n, :list => [{ :enormous_crap => " " * volume}] * n })

    # Wait for it to launch before checking whether it stops
    count = 0
    loop do
      ps = @dashboard.process(wfid)

      break unless ps.nil?

      sleep 0.1

      count += 1

      assert_equal(true, false, '/!\ process never spawned or finished too quickly to watch /!\ ') if count > max_wait
    end

    count = 0
    loop do

      ps = @dashboard.process(wfid)

      if ps == nil # success, process has terminated

        break

      elsif count < max_wait

        sleep 0.1

        count += 1

      else

        ps.expressions.each do |exp|
          p [ exp.class, exp.fei.sid, exp.state ]
          if exp.is_a?(Ruote::Exp::ConcurrenceExpression)
            p [ :expecting, exp.h.children.collect { |i| i['expid'] } ]
          end
        end

        ps.errors.each do |error|
          p [ error.message, error.trace ]
        end

        assert_equal(true, false, '/!\ process is stuck /!\ ')

      end

    end

    assert_equal true, true
  end

  # Repeat of ct_3_xxx to verify we have storage
  # set up correctly. 1 fail in 1492 trials in first run.
  def test_cancel_concurrence

    n = 10
    max_wait = 35 # 0.1 second per wait at least

    pdef = Ruote.process_definition do
      concurrence do
        n.times do |i|
          foo
        end
      end
    end

    wfid = @dashboard.launch(pdef)

    # wait_for is useless in multiprocess context
    count = 0
    loop do
      s = @dashboard.storage.get_many('workitems').size
      break if s == n

      sleep 0.1

      count += 1

      assert_equal(true, false, '/!\ did not schedule all workitems /!\ ') if count > max_wait
    end

    # The cancel should trigger the bug ct_3... was written for.
    @dashboard.cancel_process(wfid)

    count = 0
    loop do

      ps = @dashboard.process(wfid)

      break if ps == nil # success, process has terminated

      ps.expressions.each do |exp|
        p [ exp.class, exp.fei.sid, exp.state ]
        if exp.is_a?(Ruote::Exp::ConcurrenceExpression)
          p [ :expecting, exp.h.children.collect { |i| i['expid'] } ]
        end
      end if count > max_wait - 1

      sleep 0.1

      count += 1

      assert_equal(true, false, '/!\ process is stuck /!\ ') if count > max_wait
    end

    assert_equal true, true
  end

end
