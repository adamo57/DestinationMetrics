require 'openssl'
require 'digest/sha1'
require 'open-uri'
require 'json'

class String
  def rchomp(sep = $/)
    self.start_with?(sep) ? self[sep.size..-1] : self
  end
end

def get_location_name(location_id)
	if location_id == 202481595345319
		loc_name = "Lever Office, North Adams"
	elsif location_id == 202481600165262
		loc_name = "Spring Street, Williamstown"
	elsif location_id == 202481601997564
		loc_name = "MASS MoCa, North Adams"
	else
		loc_name = "Location not found"
	end
	return loc_name
end

def encrypt_addr(mac)
	# create the cipher for encrypting
	puts "#{mac}"
	@cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
	@cipher.encrypt

	# you will need to store these for later, in order to decrypt your data
	key = Digest::SHA1.hexdigest("yourpass")
	iv = @cipher.random_iv

	# load them into the cipher
	@cipher.key = key
	@cipher.iv = iv

	encrypted_MAC = @cipher.update("#{mac}") #Encrypt the MAC Addresses for some reason
	encrypted_MAC.force_encoding('ISO-8859-1')

	return encrypted_MAC
end

def blacklist(addr)
  puts "BLACKLISTING #{addr}"
  @db.query("
    INSERT INTO BLACKLIST
    (BLACKLIST_DEVICE)
    VALUES('#{addr}')
    ")
end

def get_device_manufacturer(mac_addr)
	vendorString = "http://www.macvendorlookup.com/api/v2/#{mac_addr}/pipe"

	arr = open(vendorString).string

	list = arr.split('|')
	startHex, endHex, startDec, endDec, company, addressl1, addressl2, addressl3, country, type = list

	return company
end

def filesize(testfile)
	if File.exists?(testfile)
		if File.zero?(testfile) != TRUE
			ret = File.size(testfile)
			return ret
		else
			puts "Error: File is empty"
		end	
	else
		puts "Error: File does not exist"
	end
end

def testfilesize()
	if filesize(@tsfile) >= 1000000000
		puts "This file needs to be truncated"
		f = File.open(@tsfile, 'w')
		File.close(f)
	end
end