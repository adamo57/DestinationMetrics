require './Connect.rb'

# Send the data obtained in a message to the queue
@queue.send_message(@message_device_json)
puts "Sent the message"