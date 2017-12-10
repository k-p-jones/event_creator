# NOTE: no support for singulars so
# 1 hour will have to be -> 1 hours

class TimeInterval
  MOD_TABLE = { 
    days: 1,
    hours: 24,
    minutes: 24*60,
    seconds: 24*60*60
  }

  def initialize(value, interval)
    @value = value.to_f
    @interval = interval
  end

  def modifier
    @value / MOD_TABLE[@interval.to_sym]
  end
end
