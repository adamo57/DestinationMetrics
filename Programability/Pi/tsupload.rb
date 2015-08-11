require '../utils.rb'
require '../environment.rb'
require 'mysql2'
require 'aws-sdk-v1'

#Uploads files form the tshark dump file to RDS

@db_host = ENV['db_host']
@db_user = ENV['db_user']
@db_pass = ENV['db_password']
@db_name = ENV['db_name']

@db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

@tsfile = '/var/www/tshark.log' # location of tshark dump file
dm_mac_file = '/var/www/mac.log' # location of device mac address 
nothingCount = 0
lastpos = 0

loc = File.open(dm_mac_file, 'r')
dm_mac = loc.gets #Get the location of the mac address from the file
loc.close

visits_array = Array.new
#get path to the tshark file

while true
	#check to see if the file needs to be truncated
	testfilesize(@tsfile)
	puts "Going to sleep for 30 seconds\n"
	sleep(10)

	if !visits_array.empty?
		visits_array.clear
		visits_array = Array.new
	else
		visits_array = Array.new
	end
	puts "Clearing the visits_array"

	len = filesize(@tsfile)

	if len > lastpos #if the file is longer than before
		puts "There is new stuff!"
		f = File.open(File.expand_path(@tsfile), 'r') #open the file with read permissions
		if f == FALSE
			abort("Could not open the file") #kills program if there was an error opening the file
		else
			puts "We in here"
			f.tell
			f.seek(lastpos) #find the last position that the iterator was at in the file
			f.each do |line| #reads the file line by line, starting from the last position recorded
			  if !f.eof?
			  	puts "aggregating the data"
			  	month_date, year_time, mac, signal = line.split(',')
			  	time = parse_my_date(month_date, year_time)

			  	while !@db #if there is no connection, keep retrying the connection and write the errors to the logfile
			  		@db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

			  		puts "Failed to Connect to MySQL"

			  		logFile = "/var/www/log.log"

			  		ff = File.open(logFile, 'a')
			  		current = get_time() + "Failed to connect to MySQL"
			  		File.write(logFile, current)
			  		File.close(logFile)
			  		sleep(30)
			  	end
			  	puts "Connected to db"
			  	#Make array that will be pushed into VISITS table
			  	if !visits_array.empty?
			  		if !visits_array.include?(mac)
			  			puts "The mac is not in here"
			  			visits_array.push(mac)
			  			puts "pushing the mac into visits array"
			  			manufacturer = get_device_manufacturer(mac)
			  			puts "#{mac} , #{manufacturer} -- #{visits_array.count}\n"
			  			if manufacturer != ""
			  				okay = @db.query("INSERT INTO VISITS (VISIT_ID, DEVICE_MAC, MAC_MANUFACTURE, LOCATION_ID, VISIT_TIME, VISIT_DB) VALUES('', '#{mac}', '#{manufacturer}', '#{dm_mac}', '#{time}', '#{signal}')")
			  			else
			  				okay = @db.query("INSERT INTO VISITS (VISIT_ID, DEVICE_MAC, MAC_MANUFACTURE, LOCATION_ID, VISIT_TIME, VISIT_DB) VALUES('', '#{mac}', '', '#{dm_mac}', '#{time}', '#{signal}')")
			  			end

			  			if visits_array.count >= 20
			  				visits_array.clear
			  				visits_array = Array.new
			  				puts "Had to delete the visits_array"
			  			end
			  		else
			  			puts"#{mac} was already recently uploaded - #{time} \n"
			  		end
			  	else
			  		visits_array.push(mac)
			  		manufacturer = get_device_manufacturer(mac)
			  		puts "#{mac} , #{manufacturer} #{visits_array.count}\n"
			  		if manufacturer != ""
			  			okay = @db.query("INSERT INTO VISITS (VISIT_ID, DEVICE_MAC, MAC_MANUFACTURE, LOCATION_ID, VISIT_TIME, VISIT_DB) VALUES('', '#{mac}', '#{manufacturer}', '#{dm_mac}', '#{time}', '#{signal}')")
			  		else
			  			okay = @db.query("INSERT INTO VISITS (VISIT_ID, DEVICE_MAC, MAC_MANUFACTURE, LOCATION_ID, VISIT_TIME, VISIT_DB) VALUES('', '#{mac}', '', '#{dm_mac}', '#{time}', '#{signal}')")
			  		end
			  	end
			  	if !okay
			  		puts "Query Error"
			  	end
			  end
			end
			lastpos = f.tell #records the last read position in the file 
			f.close #close the file
		end
	else
		puts "There is nothing new in here"
		testfilesize(@tsfile)
		nothingCount += 1
	end
end
