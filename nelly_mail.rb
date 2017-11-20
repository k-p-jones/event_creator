require_relative 'lib/task_runner.rb'
require_relative 'lib/time_interval.rb'

twenty_days_ago = TimeInterval.new(20, 'days').modifier
TaskRunner.new(twenty_days_ago).run
