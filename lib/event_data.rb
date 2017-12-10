class EventData
  attr_reader :load_in, :curfew, :location, 
              :date, :uid, :band, :summary,
              :prefix
  def initialize(date, mail, band)
    @date = date
    @band = band
    @subject = mail.message.subject.to_s
    @message = mail.message.body.to_s
    @load_in = fetch_load_in
    @curfew = fetch_curfew
    @location = fetch_location
    @uid = fetch_uid
    @prefix = fetch_prefix
    @summary = fetch_summary
  end

  def to_hash
    {
      summary: @summary,
      location: @location.force_encoding('UTF-8'),
      start: {
        date_time: @load_in,
        time_zone: 'Europe/London',
      },
      end: {
        date_time: @curfew,
        time_zone: 'Europe/London',
      }
    }
  end
    
  private

  def fetch_load_in 
    match = nil
    duo_regex = Regexp.new(/Arrival Time:\r\n.+(\d{2}:\d{2})/)
    gig_regex = Regexp.new(/Arrival Time:\r\n(\d{2}:\d{2})/)
    match = @message.match(duo_regex) || @message.match(gig_regex)
    if match
      result = create_datetime(@date, match[1])
    else
      result = create_datetime(@date, "17:00")
    end
  end

  def fetch_curfew
    match = @message.match(/Curfew:\r\n(\d{2}:\d{2})/)
    if match
      if match[1] < @load_in
        result = create_datetime((@date + 1), match[1])
      else
        result = create_datetime(@date, match[1])       
      end
    else
      result = create_datetime((@date + 1), "00:00")
    end
  end

  def fetch_location
    match = @message.match(/Venue:\r\n(.+)/)
    if match
      result = match[1].sub("\r", "")
    else
      result = "TBC"
    end
  end

  def fetch_uid
    @date.to_time.to_i
  end

  def create_datetime(date, modifier)
    (date.to_time + seconds_since_midnight(modifier)).to_datetime.to_s
  end

  def seconds_since_midnight(time_string)
    time = Time.parse(time_string)
    (time.hour * 60 * 60) + (time.min * 60) + (time.sec)
  end

  def fetch_prefix
    return 'HTD' if @subject.downcase.start_with?('hold the date:')
    return 'GC' if @subject.downcase.start_with?('gig confirmation:')
  end

  def fetch_summary
    str = "#{@prefix} for Band: #{@band}"
    if @subject.downcase.include?('dj')
      str += " + DJ"
    end
    if @subject.downcase.include?('acoustic')
      str += " + ACOUSTIC"
    end
    str += " UID:#{@uid}"
  end
end