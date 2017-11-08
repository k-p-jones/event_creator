class EventData
	attr_reader :load_in, :curfew, :location, :date, :uid
	def initialize(date, message)
		@date = date
		@message = message
		@load_in = fetch_load_in
		@curfew = fetch_curfew
		@location = fetch_location
		@uid = fetch_uid
	end
		
	private

	def fetch_load_in 
		match = @message.match(/Arrival Time:\r\n(\d{2}:\d{2})/)
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
		@date.to_time.to_i + Date.parse(@load_in).to_time.to_i + Date.parse(@curfew).to_time.to_i
	end

	def create_datetime(date, modifier)
		(date.to_time + seconds_since_midnight(modifier)).to_datetime.to_s
	end

	def seconds_since_midnight(time_string)
		time = Time.parse(time_string)
		(time.hour * 60 * 60) + (time.min * 60) + (time.sec)
	end
end