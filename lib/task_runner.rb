require 'gmail'
require 'date'
require 'json'
require 'fileutils'
require_relative 'config.rb'
require_relative 'event_data.rb'
require_relative 'calendar_service.rb'
require_relative 'patches/object.rb'

class TaskRunner
  SUBJECTS = ['hold the date:', 'gig confirmation:', 'not proceeding:'].freeze

  def initialize(time_interval)
    @time_interval = time_interval
    @calendar = CalendarService.new.calendar
    @gmail = Gmail.connect!(Config::UNAME, Config::PWORD)
    @emails = []
  end

  def run
    STDERR.puts("[#{timestamp}] Preparing to scan emails")
    collect_mail
    process_emails if @emails
    STDERR.puts("[#{timestamp}] Finished scan")
  end

  private

  def collect_mail
    @gmail.inbox.emails(:after => DateTime.now - @time_interval) do |mail|
      subject = mail.message.subject
      next unless valid_subject?(subject.downcase)
      @emails << mail
    end
    @gmail.logout
  end

  def valid_subject?(mail_subject)
    SUBJECTS.each do |subject|
      return true if mail_subject.start_with?(subject)
    end
    false
  end

  def process_emails
    @emails.each do |mail|
      gig_data = create_gig(mail)
      process_event(gig_data)
    end
  end

  def timestamp
    DateTime.now.to_s
  end

  def create_gig(mail)
    array = mail.message.subject.sub(',', '').split(':')
    band = array[1]
    date = Date.parse(array[2].split[0...4].join(' '))
    EventData.new(date, mail, band)
  end

  def fetch_events_by_day(data)
    date = data.date
    events = @calendar.list_events(Config::CALENDAR_ID,
      max_results: 10,
      single_events: true,
      order_by: 'startTime',
      time_min: date.to_time.iso8601,
      time_max: (date + 1).to_time.iso8601
     ).items
    events.select { |event| event.summary.include?(data.band) && event.summary.include?(data.uid.to_s) }
  end

  def process_event(data)
    events_on_date = fetch_events_by_day(data)
    if events_on_date.empty?
      insert_event(data)
    else
      update_event(events_on_date, data)
    end
  end

  def update_event(events, data)
    resource = Google::Apis::CalendarV3::Event.new(data.to_hash)
    events.each do |event|
      result = @calendar.update_event(Config::CALENDAR_ID, event.id, resource)
      STDERR.puts("[#{timestamp}] Updating event for #{data.band} on #{data.date.to_s} #{result.html_link}")
    end
  rescue Exception
    STDERR.puts("[#{timestamp}] Failed to create gig!")
    STDERR.puts("[#{timestamp}] ERROR: #{$!.to_s}")
    STDERR.puts($!.backtrace)
  end

  def insert_event(data)
    resource = Google::Apis::CalendarV3::Event.new(data.to_hash)
    result = @calendar.insert_event(Config::CALENDAR_ID, resource)
    STDERR.puts("[#{timestamp}] Event created for #{data.band} on #{data.date.to_s} #{result.html_link}")
    STDERR.puts("[#{timestamp}] #{data.summary}")
  rescue Exception
    STDERR.puts("[#{timestamp}] Failed to create gig!")
    STDERR.puts("[#{timestamp}] ERROR: #{$!.to_s}")
    STDERR.puts($!.backtrace)
  end
end
