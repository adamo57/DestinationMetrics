require 'json'
require '../utils.rb'

#Class file for the devices stored in the database


class Device

	#Makes device attributes changable
	attr_accessor :device_id, :mac_prefix, :location_id, :visit_time, :visit_db

	def initialize(device_id, mac_prefix, location_id, visit_time, visit_db)
		@device_id = device_id
		@mac_prefix = mac_prefix
		@location_id = location_id
		@visit_time = visit_time
		@visit_db = visit_db
	end

	def show
		puts "#{self}"
	end

	def to_s
		"Device ID: #{device_id}, MAC Prefix: #{encrypt_addr(mac_prefix)}, Location Name: #{get_location_name(location_id)}, Visit Time: #{visit_time}, Signal: #{visit_db}"
	end

	def to_json
		{'Device_ID' => device_id, 'MAC_Prefix' => encrypt_addr(mac_prefix), 'Location_Name' => get_location_name(location_id), 'visit_time' => visit_time, 'visit_db' => visit_db}.to_json
	end
end