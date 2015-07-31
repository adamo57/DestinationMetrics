require 'json'
require './utils.rb'


class Device
	attr_accessor :device_id, :mac_prefix, :location_id, :visit_time, :visit_date

	def initialize(device_id, mac_prefix, location_id, visit_time)
		@device_id = device_id
		@mac_prefix = mac_prefix
		@location_id = location_id
		@visit_time = visit_time
	end

	def show
		puts "Instance method show invoked for 
		#{self}"
	end

	def to_s
		"Device ID: #{device_id}, MAC Prefix: #{encrypt_addr(mac_prefix)}, Location Name: #{get_location_name(location_id)}, Visit Time: #{visit_time}"
	end

	def to_json
		{'Device_ID' => device_id, 'MAC_Prefix' => encrypt_addr(mac_prefix), 'Location_Name' => get_location_name(location_id), 'visit_time' => visit_time}.to_json
	end
end