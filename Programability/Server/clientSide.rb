require '../Pi/Device.rb'
require '../Pi/Connect.rb'
require '../utils.rb'
require 'date'
require 'json'

messages_arr = Array.new

#puts "Recieved Message: #{recieved_message.id}"
@queue.poll(idle_timeout: 15) do |msg|
	puts "Got message: #{msg.id}"
	messages_arr.push(msg.body)
end

messages_arr.each do |raw|
  #Parse the message into a readable string
  data = JSON.parse(raw)

  puts "DATA: #{data}"

  #Make a Device from the raw data and insert it to the VISITS table
  raw_device = Device.new(data["Device_ID"], data["MAC_Prefix"],data["Location_Name"], data["visit_time"], data["visit_db"])

  puts "#{raw_device.show}"

  @db.query("SET collation_connection = 'utf8_general_ci'")

  @db.query("
    INSERT INTO VISITS 
    (`VISIT_ID`, `DEVICE_MAC`, `LOCATION_ID`, `VISIT_TIME`, `VISIT_DB`)
    VALUES
    ('', '#{raw_device.mac_prefix}', '#{raw_device.location_id}', '#{raw_device.visit_time}', '#{raw_device.visit_db}')")
  
  #Make a new Device of all of the elements that we have gotten from the JSON parsed SQS message

  clean_device = Device.new(data["Device_ID"], data["MAC_Prefix"],data["Location_Name"], data["visit_time"], data["visit_db"])

  #Break the visit_time down to get visit_date, start/end_time, and max/min_signal
  visit_date, start_time = clean_device.visit_time.split(' ')

  #Setting variables that will be later adjusted by MySQL
  count = 0
  end_time = start_time
  min_signal = clean_device.visit_db

  #Insert the clean data to the clean table
  @db.query("
    INSERT INTO BESUCH
    (BESUCH_ID, DEVICE_ID, MAC_PREFIX, LOC_NAME, VISIT_DATE, START_TIME, END_TIME, COUNT, MIN_SIGNAL, MAX_SIGNAL)
    VALUES
    ('', '#{clean_device.device_id}', '#{clean_device.mac_prefix}', '#{clean_device.location_id}', '#{visit_date}', '#{start_time}', '#{end_time}', '#{count}', '#{min_signal}', '#{clean_device.visit_db}')
    ON DUPLICATE KEY UPDATE
    END_TIME = GREATEST(END_TIME, VALUES(END_TIME)),
    START_TIME = LEAST(START_TIME, VALUES(START_TIME)),
    MAX_SIGNAL = GREATEST(MAX_SIGNAL, VALUES(MAX_SIGNAL)),
    MIN_SIGNAL = LEAST(MIN_SIGNAL, VALUES(MIN_SIGNAL)),
    COUNT = COUNT+1
  ")
  puts "INSERTING"
end

=begin
DATA: {"Device_ID"=>"", "MAC_Prefix"=>"¢¶ç$V'Ï\u0091\ttÄs\vÁn8", "Location_Name"=>"Location not found", "visit_time"=>"\n2015-08-19 09:33:52", "visit_db"=>"-73\n"}
¢¶ç$V'Ï  tÄs
                   Án8
Instance method show invoked for
    Device ID: , MAC Prefix: o�@Z_����Jl�, Location Name: Location not found, Visit Time:
2015-08-19 09:33:52, Signal: -73

clientSide.rb:26:in `query': You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'Ï  tÄs
                                                           Án8', 'Location not found', ' (Mysql2::Error)
2015-08-19 09:33:52', '-73
')' at line 4
  from clientSide.rb:26:in `block in <main>'
  from clientSide.rb:15:in `each'
  from clientSide.rb:15:in `<main>'
=end