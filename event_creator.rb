require_relative 'lib/task_runner.rb'
require_relative 'lib/time_interval.rb'

amount = ARGV[0].to_i
unit = ARGV[1]

time_between_scans = TimeInterval.new(amount, unit).modifier
TaskRunner.new(time_between_scans).run
