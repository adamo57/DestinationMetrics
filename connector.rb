require 'mysql2'
require 'date'
require 'digest'
require 'text-table'

@db_host = 'localhost'
@db_user = 'root'
@db_pass = 'laJ1Bu3E'
@db_name = 'test'

system "clear" or system "cls"

#Create new connection to database
db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

results = db.query("SELECT * FROM VISITS LIMIT 1000")


if(results.count == 0)
	puts "Theres nothing in here!"
else
	#here we are going to take in all of the data and convert all of the data accordingly
	puts "\n\n\n\n"
	
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

		#begin data conversion

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
		device_id = Digest::SHA256.hexdigest "#{row['DEVICE_MAC']}"
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

		################################################################
		## Maybe we could just call this Duration and                 ##
		## get the actual time that they were there in total that day ##
		################################################################

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
	end
		besuch_results = db.query("SELECT * FROM BESUCH LIMIT 1000")

		besuch_results.each do |r|
			puts "\n\n\n\n"
			puts "BESUCH_ID\tDEVICE_ID\tMAC_PREFIX\tLOCATION_ID\tSTART_TIME\tEND_TIME\tCOUNT\tMIN_SIGNAL\tMAX_SIGNAL"
			puts "#{r['BESUCH_ID']}\t#{r['DEVICE_ID']}\t#{r['MAC_PREFIX']}\t#{r['LOCATION_ID']}\t#{r['START_TIME']}\t
			#{r['END_TIME']}\t#{r['COUNT']}\t#{r['MIN_SIGNAL']}\t#{r['MAX_SIGNAL']}\t"
		end
end