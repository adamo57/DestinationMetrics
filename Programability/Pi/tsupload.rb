require '../utils.rb'
require '../environment.rb'
require 'mysql2'
require 'aws-sdk-v1'
require 'json'
require './Device.rb'
require './Connect.rb'

#Uploads files form the tshark dump file to RDS
#have tshark write to  the SQS


tsfile = '/var/www/tshark.log' # location of tshark dump file
dm_mac_file = '/var/www/mac.log' # location of device mac address
nothingCount = 0
lastpos = 0

loc = File.open(dm_mac_file, 'r')
dm_mac = loc.gets #Get the location of the mac address from the file
loc.close

visits_array = Array.new
@json_array = Array.new

while true
	#check to see if the file needs to be truncated
	testfilesize(tsfile)
	puts "Going to sleep for 30 seconds\n"
	sleep(10)

	if !visits_array.empty?
		visits_array.clear
		visits_array = Array.new
	else
		visits_array = Array.new
	end
	puts "Clearing the visits_array"

	len = filesize(tsfile)

	if len > lastpos #if the file is longer than before
		puts "There is new stuff!"
		f = File.open(File.expand_path(tsfile), 'r') #open the file with read permissions
		if f == FALSE
			abort("Could not open the file") #kills program if there was an error opening the file
		else
			f.tell
			f.seek(lastpos, IO::SEEK_SET) #find the last position that the iterator was at in the file
			f.each do |line| #reads the file line by line, starting from the last position recorded
			  if !f.eof?
			  	month_date, year_time, mac, signal = line.split(',')
			  	time = parse_my_date(month_date, year_time)

			  	#Make array that will be pushed into VISITS table
			  	if !visits_array.empty?
			  		if !visits_array.include?(mac)
			  			visits_array.push(mac)
			  			puts "#{mac} , -- #{visits_array.count}\n"
			  			if get_device_manufacturer(mac) != ""
			  				message_device = Device.new('', mac, dm_mac, time, signal)
			  				json_device = message_device.to_json
			  				@json_array.push(json_device)
			  			else
			  				message_device = Device.new('', mac, '', dm_mac, time, signal)
			  				json_device = message_device.to_json
			  				@json_array.push(json_device)
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
			  		puts "#{mac} , #{visits_array.count}, #{signal}\n"
			  		if get_device_manufacturer(mac) != ""
			  			message_device = Device.new('', mac, dm_mac, time, signal)
			  			json_device = message_device.to_json
			  			@json_array.push(json_device)
			  		else
			  			message_device = Device.new('', mac, '', dm_mac, time, signal)
			  			json_device = message_device.to_json	
			  			@json_array.push(json_device)
			  		end
			  		if !message_device
			  			puts "Query Error"
			  		end
			  	end
			  end
			end
			lastpos = f.tell #records the last read position in the file
			f.close #close the file

			# Send the data obtained in a message to the queue
			@json_array.each do |device|
				@queue.send_message(device)
				puts "Sent the message"
			end
		end
	else
		puts "There is nothing new in here"
		testfilesize(@tsfile)
		nothingCount += 1
	end
end