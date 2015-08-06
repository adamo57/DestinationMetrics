require '../utils.rb'

#Uploads files form the tshark dump file to RDS

@tsfile = './test/www/tshark.log' # location of tshark dump file
dm_mac_file = './test/www/mac.log' # location of device mac address 
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
		visits_array.delete
		visits_array = Array.new
	else
		visits_array = Array.new
	end
	puts "Clearing the visits_array"

	len = filesize(@tsfile)

	if len > lastpos #if the file is longer than before
		puts "There is new stuff!"
		f = File.open(@tsfile, 'r') #open the file with read permissions
		if f == FALSE
			abort("Could not open the file") #kills program if there was an error opening the file
		else
			f.seek(lastpos, IO::SEEK_END) #find the last position that the iterator was at in the file
			while !f.eof?
				f.each do |line| #reads the file line by line, starting from the last position recorded
				  if !f.eof?
				  	month_date, year_time, mac, signal = line.split(',')
				  	time = parse_my_date(month_date, year_time)

				  	@db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

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
				  	#Make array that will be pushed into VISITS table
				  	if !visits_array.empty?
				  		if !visits_array.include?(mac)
				  			visits_array.push(mac)
				  			manufacturer = get_manufacturer(mac)
				  			puts mac + ", "+ manufacturer + "--"+ visits_array.count + "\n"
				  			if manufacturer != NULL
				  				okay = @db.query("INSERT INTO VISITS (VISIT_ID, DEVICE_MAC, MAC_MANUFACTURE, LOCATION_ID, VISIT_TIME, VISIT_DB) VALUES('', '#{mac}', '#{manufacturer}', '#{dm_mac}', '#{time}', '#{signal}')")
				  			else
				  				okay = @db.query("INSERT INTO VISITS (VISIT_ID, DEVICE_MAC, MAC_MANUFACTURE, LOCATION_ID, VISIT_TIME, VISIT_DB) VALUES('', '#{mac}', '', '#{dm_mac}', '#{time}', '#{signal}')")
				  			end

				  			if visits_array.count >= 20
				  				visits_array.delete
				  				visits_array = Array.new
				  				puts "Had to delete the visits_array"
				  			end
				  		else
				  			puts mac + " was already recently uploaded - " + time + "\n"
				  		end
				  	else
				  		visits_array.push(mac)
				  		manufacturer = get_manufacturer(mac)
				  		puts mac +", "+ manufacturer +""+ visits_array.count + "\n"
				  		if manufacturer != NULL
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
			end
			lastpos = f.tell #records the last read position in the file 
			f.close #close the file
		end
	else
		puts "There is nothing new in here"
		testfilesize(@tsfile);
		nothingCount++
	end
end