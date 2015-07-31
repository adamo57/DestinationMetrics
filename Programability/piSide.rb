require './Device.rb'
require './Connect.rb'
require './utils.rb'
require 'json'

results = @db.query("SELECT * FROM VISITS LIMIT 2")

#Pull info from the VISITS TABLE in database
if results.count == 0
	puts "Theres nothing in here!"
else
	encrypted_data = Array.new

	results.each do |row|

		d = Device.new(row['VISIT_ID'], encrypt_addr(row['DEVICE_MAC']), row['LOCATION_ID'], row['VISIT_TIME'])

		puts "#{d}"
=begin

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
=end
		encrypted_json = d.to_json
		puts "JSON: #{encrypted_json}"
		encrypted_data.push(encrypted_json)
	end

	# Send the data obtained in a message to the queue

	msgs = @queue.batch_send(encrypted_data)
	puts "Sent all of the messages"
end