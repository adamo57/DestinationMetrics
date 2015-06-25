require 'aws-sdk-v1'
require 'mysql2'
require 'date'
require 'digest'
require 'text-table'
require 'json'

@db_host = 'localhost'
@db_user = 'root'
@db_pass = 'laJ1Bu3E'
@db_name = 'test'

# Connect to the database
db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)
results = db.query("SELECT * FROM VISITS LIMIT 10")

visit_id_fix = nil
mac_addr = nil
location_id_fix = nil
visit_time = nil
mac_time_nil = nil
loc_mac_time_nil = nil

#Connect to the queue
AWS.config(:access_key_id => ENV['AWS_ACCESS_KEY_ID'], :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
sqs = AWS::SQS.new
url = "https://sqs.us-east-1.amazonaws.com/308871452314/destination-metrics-dummy"
queue = sqs.queues[url]

system "clear" or system "cls"

raw_data = Array.new
messages_arr = Array.new

#Pull info from the VISITS TABLE in database
if(results.count == 0)
	puts "Theres nothing in here!"
else
	results.each do |row|
		visit_id_fix = row['VISIT_ID'] #Stored as int
		mac_addr = row['DEVICE_MAC'] #Stored as array (use .to_a)
		location_id_fix = row['LOCATION_ID'] #Stored as int
		visit_time = row['VISIT_TIME'] #Stored as a new datetime (use .to_datetime)
		mac_time_nil = row['MAC_Time'] #Stored as new datetime?
		loc_mac_time_nil = row['Loc_MAC_Time'] #Stored as int

		#Raw data dump
		puts "\nVISIT_ID\tDEVICE_MAC\tLOCATION_ID\tVISIT_TIME\tMAC_Time\tLoc_MAC_Time"
		puts "#{visit_id_fix},\t #{mac_addr},\t #{location_id_fix},\t #{visit_time},\t #{mac_time_nil},\t #{loc_mac_time_nil}\n\n"

		raw_row = ["#{visit_id_fix}", "#{mac_addr}", "#{location_id_fix}", "#{visit_time}", "#{mac_time_nil}", "#{loc_mac_time_nil}"]
		raw_json = raw_row.to_json
		raw_data.push(raw_json)
	end

	# Send the data obtained in a message to the queue
	msgs = queue.batch_send(raw_data)
	puts "Sent all of the messages"

	#Read data from the queue
	recieved_message = queue.receive_message(wait_time_seconds: 10)
	message = JSON.parse(recieved_message.body)

	puts "Recieved Message: #{recieved_message.id}"
	queue.poll(idle_timeout: 15) do |msg|
		puts "Got message: #{msg.id}"
		messages_arr.push(msg)
	end

	#Clear the database first
	puts "Dropping table...."
	sleep(10)
	db.query("DROP TABLE IF EXISTS BESUCH")
	puts "Dropped."

	messages_arr.each do |x|
		#Scrub Scrub Scrub
			#...
		#Should we send out a new message to a different queue?
		#Anyways, we are going to put the new 'scrubbed' data into a new table

		db.query("CREATE TABLE IF NOT EXISTS `BESUCH` (
			`BESUCH_ID` bigint(20) NOT NULL AUTO_INCREMENT,
			`DEVICE_ID` varchar(128) DEFAULT NULL,
			`MAC_PREFIX` varchar(8) NOT NULL,
			`LOCATION_ID` bigint(20) DEFAULT NULL,
			`START_TIME` datetime DEFAULT NULL,
			`END_TIME` datetime DEFAULT NULL,
			`COUNT` INT DEFAULT NULL,
			`MIN_SIGNAL` SMALLINT DEFAULT NULL,
			`MAX_SIGNAL` SMALLINT DEFAULT NULL,
			PRIMARY KEY (`BESUCH_ID`),
			UNIQUE KEY `BESUCH_ID` (`BESUCH_ID`),
			KEY `LOCATION_START` (`LOCATION_ID`, `START_TIME`),
			KEY `Device_Start` (`DEVICE_ID`,`START_TIME`),
			KEY `LOCATION_END` (`LOCATION_ID`, `END_TIME`),
			KEY `Device_End` (`DEVICE_ID`,`END_TIME`),
			KEY `Loc_Device_Start` (`LOCATION_ID`,`DEVICE_ID`,`START_TIME`)
			) ENGINE=innodb;")

			#DEVICE_ID
			# INSERT if doesnt already exist. else ignore
			device_id = Digest::SHA256.hexdigest "#{mac_addr}"
			puts "device_id: #{device_id}"


			#DEVICE_MAC
			# INSERT if doesnt already exist. else ignore
			mac_addr_tmp = mac_addr.split(':')
			mac_prefix = [mac_addr_tmp[0], mac_addr_tmp[1], mac_addr_tmp[2]].join(":")
			puts "mac_prefix: #{mac_prefix}"

			#LOCATION_ID
			# If it doesn't exist, INSERT, otherwise, UPDATE
			location_id = location_id_fix.to_i
			puts "location_id: #{location_id}"

			#START_TIME / END TIME

			start_time = visit_time.to_datetime
			puts "start_time: #{start_time}"

			#everytime there is a new ping to the device on the same day, update the end time to the current time

			# If it doesn't exist, INSERT, otherwise, UPDATE
			time = Time.now
			end_time = time.to_datetime


			puts "end_time: #{end_time}"

			#COUNT
			#Every time a new ping of the same device occurs, increment the count val

			# If it doesn't exist, INSERT, otherwise, UPDATE
			count = 0
			#if new ping occurs
			# => count += 1
			puts "count: #{count}"

			#MAX_SIGNAL / MIN_SIGNAL
			#Every time a new ping occurs, the current max and min signal strength will be tested against 
			#the signal strength passed in, and if it is higher than the max, or lower than the min
			#update accordingly

			max_signal = 0
			min_signal = 0
			mac_time = mac_time_nil.to_i

			if mac_time > max_signal
				max_signal = mac_time
			elsif mac_time < min_signal
				min_signal = mac_time
			end

			if db.query("SELECT 1 FROM BESUCH WHERE DEVICE_ID = '#{device_id}'") != ""
				puts "INSERTING"
				db.query("INSERT INTO BESUCH (`DEVICE_ID`, `MAC_PREFIX`,
				`LOCATION_ID`, `START_TIME`, `END_TIME`, `COUNT`, `MIN_SIGNAL`, `MAX_SIGNAL`)
				VALUES('#{device_id}', '#{mac_prefix}', NULL, NULL, NULL, #{count}, NULL, NULL)")
			end
			besuch_results = db.query("SELECT * FROM BESUCH LIMIT 1000")

			besuch_results.each do |r|
				puts "\n\n\n\n"
				puts "BESUCH_ID\tDEVICE_ID\tMAC_PREFIX\tLOCATION_ID\tSTART_TIME\tEND_TIME\tCOUNT\tMIN_SIGNAL\tMAX_SIGNAL"
				puts "#{r['BESUCH_ID']}\t#{r['DEVICE_ID']}\t#{r['MAC_PREFIX']}\t#{r['LOCATION_ID']}\t#{r['START_TIME']}\t
				#{r['END_TIME']}\t#{r['COUNT']}\t#{r['MIN_SIGNAL']}\t#{r['MAX_SIGNAL']}\t"
			end
	end
end