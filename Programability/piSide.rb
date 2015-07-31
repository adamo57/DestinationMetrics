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

		encrypted_json = d.to_json
		puts "JSON: #{encrypted_json}"
		encrypted_data.push(encrypted_json)
	end

	# Send the data obtained in a message to the queue

	msgs = @queue.batch_send(encrypted_data)
	puts "Sent all of the messages"
end