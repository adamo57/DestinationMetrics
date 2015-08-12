require '../Pi/Device.rb'
require '../Pi/Connect.rb'
require '../utils.rb'
require 'date'
require 'json'

messages_arr = Array.new

#Read data from the queue
#write raw data to the visits table
#then clean and push to besuch
recieved_message = @queue.receive_messages(wait_time_seconds: 15, num_messages: 10, visibility_timeout: 10)
message = JSON.parse(recieved_message.body)

puts "Recieved Message: #{recieved_message.id}"
@queue.poll(idle_timeout: 15) do |msg|
	puts "Got message: #{msg.id}"
	messages_arr.push(msg.body)
end

puts "Got all of the messages\n"

messages_arr.each do |raw|
  #Parse the message into a readable string
  data = JSON.parse(raw)
	#Scrub Scrub Scrub
  #Make a new Device of all of the elements that we have gotten from the JSON parsed SQS message

  insert_device = Device.new(data["Device_ID"], data["MAC_Prefix"],data["Location_Name"], data["visit_time"])

  #Break the visit_time down to get visit_date, start/end_time, and max/min_signal
  visit_date, start_time, max_signal = data["visit_time"].split(' ')

  #Setting variables that will be later adjusted by MySQL
  count = 0
  end_time = start_time
  min_signal = max_signal

  #Insert the clean data to the clean table
  @db.query("
    INSERT INTO BESUCH
    (DEVICE_ID, MAC_PREFIX, LOC_NAME, VISIT_DATE, START_TIME, END_TIME, COUNT, MIN_SIGNAL, MAX_SIGNAL)
    VALUES
    ('#{insert_device.device_id}', '#{insert_device.mac_prefix}', '#{insert_device.location_id}', '#{visit_date}', '#{start_time}', '#{end_time}', '#{count}', '#{min_signal}', '#{max_signal}')
    ON DUPLICATE KEY UPDATE
    END_TIME = GREATEST(END_TIME, VALUES(END_TIME)),
    START_TIME = LEAST(START_TIME, VALUES(START_TIME)),
    MAX_SIGNAL = GREATEST(MAX_SIGNAL, VALUES(MAX_SIGNAL)),
    MIN_SIGNAL = LEAST(MIN_SIGNAL, VALUES(MIN_SIGNAL)),
    COUNT = COUNT+1
  ")
  puts "INSERTING"
end