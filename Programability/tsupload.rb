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
				  puts line
				end
			end
			f.close #close the file
		end
	else
		puts "There is nothing new in here"
	end
end