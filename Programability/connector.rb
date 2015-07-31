require 'aws-sdk-v1'
require 'mysql2'
require 'date'
require 'openssl'
require 'digest/sha1'

require 'daemons'
require './environment'

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
  return loc_name
end

def blacklist(addr)
  puts "BLACKLISTING #{addr}"
  @db.query("
    INSERT INTO BLACKLIST
    (BLACKLIST_DEVICE)
    VALUES('#{addr}')
    ")
end

loop do
  begin
    @db_host = ENV['db_host']
    @db_user = ENV['db_user']
    @db_pass = ENV['db_password']
    @db_name = ENV['db_name']
    @db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)
  rescue Mysql2::Error => e
    puts "There was an Error Connecting"
    puts "#{e}"
  else
    @runThrough = 0
    @offset = 10

    # create the cipher for encrypting
    @cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    @cipher.encrypt

    # you will need to store these for later, in order to decrypt your data
    key = Digest::SHA1.hexdigest("yourpass")
    iv = @cipher.random_iv

    # load them into the cipher
    @cipher.key = key
    @cipher.iv = iv

    results = @db.query("SELECT * FROM VISITS LIMIT 10")

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
    @queue = sqs.queues[url]

    encrypted_data = Array.new
    messages_arr = Array.new

    #Pull info from the VISITS TABLE in database
    if results.count == 0
    	puts "Theres nothing in here!"
    else
    	results.each do |row|
    		visit_id_fix = row['VISIT_ID'] #Stored as int
    		mac_addr = row['DEVICE_MAC'] #Stored as array (use .to_a)
        encrypted_MAC = @cipher.update("#{mac_addr}") #Encrypt the MAC Addresses for some reason
        encrypted_MAC.force_encoding('ISO-8859-1')
    		location_id_fix = row['LOCATION_ID'] #Stored as int
    		visit_time = row['VISIT_TIME'] #Stored as a new datetime (use .to_datetime)
    		mac_time_nil = row['MAC_Time'] #Stored as new datetime?
    		loc_mac_time_nil = row['Loc_MAC_Time'] #Stored as int

        @db.query("CREATE TABLE IF NOT EXISTS `BLACKLIST` (
        `BLACKLIST_ID` BIGINT(20) NOT NULL AUTO_INCREMENT,
        `BLACKLIST_DEVICE` VARCHAR(128) DEFAULT NULL,
        PRIMARY KEY(`BLACKLIST_ID`)
        ) ENGINE=innodb;")

        #@db.query("ALTER TABLE BLACKLIST
        #ADD INDEX (BLACKLIST_DEVICE)
        #USING BTREE")

        @db.query("SET collation_connection = 'utf8_general_ci'")
        if @db.query("
          SELECT EXISTS( 
                  SELECT DEVICE_MAC
                  FROM VISITS 
                  WHERE DEVICE_MAC = '#{mac_addr}'
                    AND TIMEDIFF(START_TIME, END_TIME) > 15
                  HAVING COUNT(DISTINCT(VISIT_DATE)) = 1)"
        ) == 0  
          blacklist(mac_addr)
          next
        elsif @db.query("
          SELECT EXISTS (
                    SELECT DEVICE_MAC
                    FROM VISITS
                    WHERE DEVICE_MAC = '#{mac_addr}' 
                    AND TIMEDIFF(START_TIME, END_TIME) < 3 
                    HAVING COUNT(DISTINCT(VISIT_DATE)) = 3
                      AND FLOOR(COUNT(DISTINCT(VISIT_DATE))/7) > 1)
        ") == 0
          blacklist(mac_addr)
          next
        else
          puts "This really isn't here at all..."
        end


    		#Raw data dump
    		puts "\nVISIT_ID\tDEVICE_MAC\tLOCATION_ID\tVISIT_TIME\tMAC_Time\tLoc_MAC_Time"
    		puts "#{visit_id_fix},\t #{encrypted_MAC},\t #{location_id_fix},\t #{visit_time},\t #{mac_time_nil},\t #{loc_mac_time_nil}\n\n"

    		raw_row = ["#{visit_id_fix}", "#{encrypted_MAC}", "#{location_id_fix}", "#{visit_time}", "#{mac_time_nil}", "#{loc_mac_time_nil}"]
    		encrypted_json = raw_row.to_json
        puts "#{encrypted_json}"
    		encrypted_data.push(encrypted_json)
    	end

    	# Send the data obtained in a message to the queue

    	msgs = @queue.batch_send(encrypted_data)
    	puts "Sent all of the messages"

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
      @db.query("DROP TABLE BESUCH")
      @db.query("DROP TABLE BLACKLIST")
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

        if(!mac_addr.nil?)
          #DEVICE_ID
          device_id = mac_addr
          puts "device_id: #{device_id}"

          #DEVICE_MAC
          mac_addr_tmp = mac_addr.split(':')
          mac_prefix = [mac_addr_tmp[0], mac_addr_tmp[1], mac_addr_tmp[2]].join(":")
          puts "mac_prefix: #{mac_prefix}"
        end


  			#LOCATION_ID
        if(!location_id_fix.nil?)
          location_name = findLocation(location_id_fix.to_i)
          puts "location_name: #{location_name}"
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
        if @db.query("
            SELECT DEVICE_MAC
            FROM VISITS
            LEFT JOIN BLACKLIST ON VISITS.DEVICE_MAC = BLACKLIST.BLACKLIST_DEVICE
            WHERE BLACKLIST.BLACKLIST_DEVICE IS NULL
            AND DEVICE_MAC = '#{mac_addr}'
            ") == mac_addr
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
        else
          puts "That device is being blacklisted..."
        end
        
      end
    end
    
    @runThrough++
    sleep(10)
  end
end
