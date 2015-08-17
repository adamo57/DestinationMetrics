require './Connect.rb'
require './tsupload.rb'

# Send the data obtained in a message to the queue
@json_array.each do |device|
	@queue.send_message(device)
	puts "Sent the message"
end