#
# Similar to concurrent_base, but forks workers instead of staying in threads
#
# Fri Apr 17 12:57:01 PDT 2015
#
# Rick Cobb (cobbr2@)
#

require File.expand_path('../base', __FILE__)

module ColorMyPuts
  def write_with_color(s)
    write("[#{@color}m#{s}[0m")
  end

  def puts(*args)

    eol = false

    args.each do |arg|
      eol = false
      write_with_color(arg)

      unless arg[-1] == "\n"
        write("\n")
        eol = true
      end
    end

    write("\n") unless eol
  end

  def color=(ansi_thing)
    @color = ansi_thing
  end
end

STDOUT.extend(ColorMyPuts)
$stderr.extend(ColorMyPuts)

module HandleStepErrorWithAbort

  def handle_step_error(err, msg)
    $stderr.puts "=========== step_error! aborting!!!"
    $stderr.puts 'error class/message/backtrace:'
    $stderr.puts err.class.name
    $stderr.puts err.message.inspect
    $stderr.puts *err.backtrace
    $stderr.puts err.details if err.respond_to?(:details)
    $stderr.puts
    $stderr.puts 'msg:'
    if msg && msg.is_a?(Hash)
      $stderr.puts msg.select { |k, v|
        %w[ action wfid fei ].include?(k)
      }.inspect
    else
      $stderr.puts msg.inspect
    end
    $stderr.puts
    $stderr.puts '=' * 80

    abort # Avoid infinite loops
  end

end

module MultiprocessBase

  def register_participants(dashboard)
  end

  def setup
    if ARGV.include?('-T') || ARGV.include?('-N') || ENV['NOISY'] == 'true'
      p self.class
    end

    # from ANSI terminal colors via fancy_printing.rb; leave yellow for the parent
    colors = [
      '34', # blue
      '35', # magenta
      '36', # cyan
      '32', # green     (last since Minitest uses it)
      ]


    nworkers = ENV['RUOTE_WORKERS'] || '2'
    raise "RUOTE_WORKERS must be a decimal integer (is '#{nworkers}')" unless nworkers =~ /^\d+$/
    nworkers = nworkers.to_i

    @storage = determine_storage({})

    @workers = (0...nworkers).map do |index|
      color = colors[index % colors.length]

      pid = fork do
        $stderr.sync = STDOUT.sync = true
        $stderr.color = STDOUT.color = color

        # TODO: Move this to the storage test implementation as 'storage = forked_connection':
        $sequel = nil
        sequel = Sequel.connect(ENV['RUOTE_STORAGE_DB'])
        storage = Ruote::Sequel::Storage.new(sequel)

        storage.context.logger.color = color
        storage.context.logger.noisy = true

        worker = Ruote::Worker.new(storage)
        dashboard = Ruote::Engine.new(worker, false)

        dashboard.context.logger.color = color
        dashboard.noisy = true

        worker.extend(HandleStepErrorWithAbort)

        dashboard.worker.run
        dashboard.join
      end
    end

    @dashboard = Ruote::Dashboard.new(@storage)

    @dashboard.noisy = ENV['NOISY'] == 'true'

    register_participants(@dashboard)

    sleep 2 # Allow the workers time to initialize themselves
  end

  def teardown
    @workers.each {|pid| Process.kill("HUP",pid) }
    Process.wait
    @storage.purge!
  end
end

