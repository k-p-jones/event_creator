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
  PREFIXES = ['HTD', 'GC'].freeze
  def initialize(time_interval)
    @time_interval = time_interval
    @calendar = CalendarService.new.calendar
    @gmail = Gmail.connect!(Config::UNAME, Config::PWORD)
    @emails = []
  end

  def run
    STDERR.puts("[#{timestamp}] Preparing to scan emails")
    collect_mail
    scan_emails(@emails) if @emails
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

  def scan_emails(emails)
    @emails.each do |mail|
      process_gig(mail)
    end
  end

  def timestamp
    DateTime.now.to_s
  end

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
      exists =  true if event.summary.include?(band) && uid[1].to_i == data.uid
    end
    if exists
      STDERR.puts("[#{timestamp}] Not creating event #{data.uid} as it already exists")
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
      begin
        resource = Google::Apis::CalendarV3::Event.new({
            summary: data.summary,
            location: data.location.force_encoding('UTF-8'),
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
        STDERR.puts("[#{timestamp}] Event created for #{band} on #{date.to_s} #{result.html_link}")
        STDERR.puts("[#{timestamp}] #{data.summary}")
      rescue Exception
        STDERR.puts("[#{timestamp}] Failed to create gig at date!")
        STDERR.puts("[#{timestamp}] ERROR: #{$!.to_s}")
        STDERR.puts($!.backtrace)
      end
    end
  end
end
