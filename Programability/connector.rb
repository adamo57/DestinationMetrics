require 'aws-sdk-v1'
require 'mysql2'
require 'date'
require 'digest'
require 'text-table'
require 'json'
require 'daemons'
require './environment'

loop do
  @db_host = ENV['db_host']
  @db_user = ENV['db_user']
  @db_pass = ENV['db_pass']
  @db_name = ENV['db_name']
  @db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

  @runThrough = 0
  @offset = 10

  class String
    def rchomp(sep = $/)
      self.start_with?(sep) ? self[sep.size..-1] : self
    end
  end

  def findLocation(loc_id)
  	if loc_id == 202481595345319
  		loc_name = "Lever Office, North Adams"
  	elsif loc_id == 202481600165262
  		loc_name = "Spring Street, Williamstown"
  	elsif loc_id == 202481601997564
  		loc_name = "MASS MoCa, North Adams"
  	else
  		loc_name = "Location not found"
  	end
  	return loc_name;
  end

  def checkSameDay(addr, date)
  	ret = false
  	count = @db.query("SELECT COUNT(*) FROM BESUCH WHERE START_TIME=#{visit_time} && DEVICE_MAC =#{mac_addr}")
  	if (count == 0)
  		ret = false
  	else
  		ret = true
  	end
  	return ret
  end

  def iso8601_to_mysql_datetime(date)
    DateTime.parse(date).to_time.strftime("%F %T")
  end

  # Connect to the database
  if @runThrough == 0
  	results = @db.query("SELECT * FROM VISITS LIMIT 10")
  else
  	results = @db.query("SELECT * FROM VISITS LIMIT 10 OFFSET #{@offset}")
  	@offset += 10
  end

  visit_id_fix = nil
  mac_addr = nil
  location_id_fix = nil
  visit_time = nil
  mac_time_nil = nil
  loc_mac_time_nil = nil

  #Connect to the queue
  AWS.config(:access_key_id => ENV['access_key_id'], :secret_access_key => ENV['secret_access_key'])
  sqs = AWS::SQS.new
  url = ENV['sqs-url']
  queue = sqs.queues[url]

  system "clear" or system "cls"

  raw_data = Array.new
  messages_arr = Array.new

  #Pull info from the VISITS TABLE in database
  if results.count == 0
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
  	#sleep(10)

  	#Read data from the queue
  	recieved_message = queue.receive_messages(wait_time_seconds: 15, num_messages: 10, visibility_timeout: 10)
  	message = JSON.parse(recieved_message.body)

  	puts "Recieved Message: #{recieved_message.id}"
  	queue.poll(idle_timeout: 15) do |msg|
  		puts "Got message: #{msg.id}"
  		messages_arr.push(msg.body)
  	end

  	puts "Got all of the messages\n"
  	#Clear the database first
  	#puts "Dropping table...."
  	#sleep(10)


    @db.query("DROP TABLE BESUCH")
  	#puts "Dropped."

  	messages_arr.each do |raw|
  		#Scrub Scrub Scrub
  			#...
  		#Should we send out a new message to a different queue?
  		#Anyways, we are going to put the new 'scrubbed' data into a new table
  		raw_arr = raw.split(',')
  		mac_addr = raw_arr[1].rchomp('"').chomp('"')
  		location_id = raw_arr[2]
  		visit_time = raw_arr[3].split(' ')

  		@db.query("CREATE TABLE IF NOT EXISTS `BESUCH` (
      `BESUCH_ID` bigint NOT NULL AUTO_INCREMENT,
      `DEVICE_ID` varchar(128) DEFAULT NULL,
      `MAC_PREFIX` varchar(8) NOT NULL,
      `LOC_NAME` varchar(255) DEFAULT NULL,
      `VISIT_DATE` date DEFAULT NULL,
      `START_TIME` time DEFAULT NULL,
      `END_TIME` time DEFAULT NULL,
      `COUNT` INT DEFAULT NULL,
      `MIN_SIGNAL` SMALLINT DEFAULT NULL,
      `MAX_SIGNAL` SMALLINT DEFAULT NULL,
      PRIMARY KEY (`BESUCH_ID`),
      UNIQUE KEY `BESUCH_ID` (`BESUCH_ID`),
      KEY DEVICE (`DEVICE_ID`, `LOC_NAME`, `VISIT_DATE`, `START_TIME`)
      ) ENGINE=innodb;")

      @db.query("CREATE TABLE IF NOT EXISTS `BLACKLIST` (
      `BLACKLIST_ID` BIGINT(20) NOT NULL AUTO_INCREMENT,
      `BLACKLIST_DEVICE` VARCHAR(128) DEFAULT NULL,
      PRIMARY KEY(`BLACKLIST_ID`)
      ) ENGINE=innodb;")

      #@db.query("ALTER TABLE BLACKLIST
      #ADD INDEX (BLACKLIST_DEVICE)
      #USING BTREE")

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
  			location_name = findLocation(location_id_fix.to_i)
  			puts "location_name: #{location_name}"


        #VISIT DATE
        visit_date = visit_time[0].rchomp('"').chomp('"')

        puts "visit_date: #{visit_date}"

  			#START_TIME / END TIME

        start_time = visit_time[1].rchomp('"').chomp('"')
  			puts "start_time: #{start_time}"

  			#everytime there is a new ping to the device on the same day, update the end time to the current time

  			# If it doesn't exist, INSERT, otherwise, UPDATE

      end_time = start_time
  			puts "end_time: #{end_time}"

  			#COUNT
  			#Every time a new ping of the same device occurs, increment the count val

  			# If it doesn't exist, INSERT, otherwise, UPDATE
  			count = 1
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

  			#END TIME needs to be the captured datetime from tshark


        @db.query("INSERT INTO BESUCH
        (DEVICE_ID, MAC_PREFIX, LOC_NAME, VISIT_DATE, START_TIME, END_TIME, COUNT, MIN_SIGNAL, MAX_SIGNAL)
        VALUES
        ('#{device_id}', '#{mac_prefix}', '#{location_name}', '#{visit_date}', '#{start_time}', '#{end_time}', '#{count}', '#{min_signal}', '#{max_signal}')
        ON DUPLICATE KEY UPDATE
        END_TIME = GREATEST(END_TIME, VALUES(END_TIME)),
        START_TIME = LEAST(START_TIME, VALUES(START_TIME)),
        MAX_SIGNAL = GREATEST(MAX_SIGNAL, VALUES(MAX_SIGNAL)),
        MIN_SIGNAL = LEAST(MIN_SIGNAL, VALUES(MIN_SIGNAL)),
        COUNT = COUNT+1")
  	end
  end
  @runThrough++
  sleep(10)
end
