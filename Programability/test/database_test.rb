require './Pi/Connect.rb'

if !@db
	puts "Error"

else 
	puts "Connected"
	rs = @db.query("SHOW TABLES")
	rs.each do |x|
		puts x
	end
	@db.close
	puts "Closed"
end