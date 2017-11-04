require_relative 'lib/mr_meseeks.rb'


# could potentially create duplicates if someone responds to the email 
# so we need to handle that.
MrMeseeks.new.scan_emails