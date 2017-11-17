require 'gmail'
require 'date'
require 'json'
require 'fileutils'
require 'pry'
require_relative 'config.rb'
require_relative 'event_data.rb'
require_relative 'calendar_service.rb'
require_relative 'patches/object.rb'

class MrMeseeks
	def initialize
		@calendar = CalendarService.new.calendar
	end

	def scan_emails
		gmail = Gmail.connect!(Config::UNAME, Config::PWORD)
		gmail.inbox.emails(:after => DateTime.now - 20) do |mail|
		  subject = mail.message.subject
			next unless subject.downcase.start_with?("hold the date:") || subject.downcase.start_with?("gig confirmation")
			process_gig(mail)
		end
		gmail.logout
	end

	private

	def process_gig(mail)
		array = mail.message.subject.sub(',', '').split(':')
    band = array[1]
    date = Date.parse(array[2].split[0...4].join(' '))
    make_event(date, band, mail)
	end

	def event_exists?(data, band)
		exists = false
		events = fetch_events_by_day(data.date)
		events.each do |event|
			uid = event.summary.match(/UID:(\d+)/)
			next unless uid
			# BUG, uid makes use of curfew and load in times when in fact these can change between 
			# hold the date and confirmation emails.
			exists =  true if event.summary.include?(band) && uid[1].to_i == data.uid
		end
		if exists
			STDERR.puts("Not creating event #{data.uid} as it already exists")
		end
		exists
	end

	def fetch_events_by_day(date)
		@calendar.list_events(Config::CALENDAR_ID,
		  max_results: 10,
		  single_events: true,
		  order_by: 'startTime',
		  time_min: date.to_time.iso8601,
		  time_max: (date + 1).to_time.iso8601
		 ).items
	end

	def make_event(date, band, mail)
	  data = EventData.new(date, mail, band)
	  unless event_exists?(data, band)
		  resource = Google::Apis::CalendarV3::Event.new({
		      summary: data.summary,
		      location: data.location,
		      start: {
		        date_time: data.load_in,
		        time_zone: 'Europe/London',
		      },
		      end: {
		        date_time: data.curfew,
		        time_zone: 'Europe/London',
		      }
		  })
		  result = @calendar.insert_event(Config::CALENDAR_ID, resource)
		  puts "Event created for #{band} on #{date.to_s} #{result.html_link}"
		  puts data.summary
		end
	end
end
