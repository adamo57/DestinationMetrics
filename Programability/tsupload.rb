require './utils.rb'

lastpos = 0

#get path to the tshark file

while true
	#check to see if the file needs to be truncated
	testfilesize(@tsfile)

	len = filesize(@tsfile)

	if len > lastpos #if the file is longer than before
		puts "There is new stuff!"
		f = File.open(@tsfile, 'r') #open the file with read permissions
		if f == FALSE
			abort("Could not open the file") #kills program if there was an error opening the file
		else
			f.seek(lastpos, IO::SEEK_END) #find the last position that the iterator was at in the file
			while !f.EOF?
				f.each do |line| #reads the file line by line, starting from the last position recorded
				  if !f.EOF?
				  	month_date, year_time, mac, db = line.split(',')
				  	time = parse_my_date(month_date, year_time)

				  	@db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

				  	while !@db
				  		@db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

				  		puts "Failed to Connect to MySQL"

				  		logFile = ""

				  		ff = File.open(logFile, 'a')
				  		current = get_time() + "Failed to connect to MySQL"
				  		File.write(logFile, current)
				  		File.close(logFile)
				  		sleep(30)
				  	end
				  end
				end
			end
			f.close #close the file
		end
	else
		puts "There is nothing new in here"
	end
end