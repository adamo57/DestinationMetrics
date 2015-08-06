require '../Pi/piSide.rb'
require '../utils.rb'
require 'date'
require 'json'

messages_arr = Array.new

#Read data from the queue
recieved_message = @queue.receive_messages(wait_time_seconds: 15, num_messages: 10, visibility_timeout: 10)
message = JSON.parse(recieved_message.body)

puts "Recieved Message: #{recieved_message.id}"
@queue.poll(idle_timeout: 15) do |msg|
	puts "Got message: #{msg.id}"
	messages_arr.push(msg.body)
end

puts "Got all of the messages\n"
#Clear the database first
#@db.query("DROP TABLE BESUCH")
#puts "Dropped."

messages_arr.each do |raw|
	#Scrub Scrub Scrub
	#Anyways, we are going to put the new 'scrubbed' data into a new table
	raw_arr = raw.split(',')
	mac_addr = raw_arr[1].rchomp('"').chomp('"')
	location_id = raw_arr[2]
	visit_time = raw_arr[3].split(' ')
	min_signal = raw_arr[4]
	max_signal = raw_arr[5]

  if(!mac_addr.nil?)
    #DEVICE_ID
    device_id = mac_addr
    puts "device_id: #{device_id}"

    #DEVICE_MAC
    mac_addr_tmp = mac_addr.split(':')
    mac_prefix = [mac_addr_tmp[0], mac_addr_tmp[1], mac_addr_tmp[2]].join(":")
    puts "mac_prefix: #{mac_prefix}"
  end

  if(!visit_time.any?)
    #VISIT DATE
    visit_date = visit_time[0].rchomp('"').chomp('"')

    puts "visit_date: #{visit_date}"

			#START_TIME / END TIME

    start_time = visit_time[1].rchomp('"').chomp('"')
			puts "start_time: #{start_time}"

			#everytime there is a new ping to the device on the same day, update the end time to the current time

    end_time = start_time
			puts "end_time: #{end_time}"
  end

	#COUNT
	#Every time a new ping of the same device occurs, increment the count val

	count = 1
	#if new ping occurs
	# => count += 1
	puts "count: #{count}"

  # BLACKLISTING
  ## Will change depending on clients needs
  ## example of MASS MoCA

  #if the requirements are met, blacklist the mac_addr
  # skip to the next mac_addr in db

  #this mac_addr should not be blacklisted
  # put in the clean table 
  #  if the mac_addr does not exist in the blacklist table already

  @db.query("
    INSERT INTO BESUCH
    (DEVICE_ID, MAC_PREFIX, LOC_NAME, VISIT_DATE, START_TIME, END_TIME, COUNT, MIN_SIGNAL, MAX_SIGNAL)
    VALUES
    ('#{device_id}', '#{mac_prefix}', '#{location_name}', '#{visit_date}', '#{start_time}', '#{end_time}', '#{count}', '#{min_signal}', '#{max_signal}')
    ON DUPLICATE KEY UPDATE
    END_TIME = GREATEST(END_TIME, VALUES(END_TIME)),
    START_TIME = LEAST(START_TIME, VALUES(START_TIME)),
    MAX_SIGNAL = GREATEST(MAX_SIGNAL, VALUES(MAX_SIGNAL)),
    MIN_SIGNAL = LEAST(MIN_SIGNAL, VALUES(MIN_SIGNAL)),
    COUNT = COUNT+1
  ")
  puts "INSERTING"
end