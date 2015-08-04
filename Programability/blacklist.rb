require './utils.rb'
require 'Connect.rb'

#Goes through the entire BESUCH table and blacklists the MACs on the fly
#should run once a day automatically

@db.query("CREATE TABLE IF NOT EXISTS `BLACKLIST` (
`BLACKLIST_ID` BIGINT(20) NOT NULL AUTO_INCREMENT,
`BLACKLIST_DEVICE` VARCHAR(128) DEFAULT NULL,
PRIMARY KEY(`BLACKLIST_ID`)
) ENGINE=innodb;")

#@db.query("ALTER TABLE BLACKLIST
#ADD INDEX (BLACKLIST_DEVICE)
#USING BTREE")

@db.query("SET collation_connection = 'utf8_general_ci'")
if @db.query("
  SELECT EXISTS( 
          SELECT DEVICE_MAC
          FROM VISITS 
          WHERE DEVICE_MAC = '#{mac_addr}'
            AND TIMEDIFF(START_TIME, END_TIME) > 15
          HAVING COUNT(DISTINCT(VISIT_DATE)/7) = 1)"
) == 0  
  blacklist(mac_addr)
  next
elsif @db.query("
  SELECT EXISTS (
            SELECT DEVICE_MAC
            FROM VISITS
            WHERE DEVICE_MAC = '#{mac_addr}' 
            AND TIMEDIFF(START_TIME, END_TIME) < 3 
            HAVING COUNT(DISTINCT(VISIT_DATE)) = 3
              AND FLOOR(COUNT(DISTINCT(VISIT_DATE))/7) > 1)
") == 0
  blacklist(mac_addr)
  next
else
  puts "This really isn't here at all..."
end

if @db.query("
    SELECT DEVICE_MAC
    FROM VISITS
    LEFT JOIN BLACKLIST ON VISITS.DEVICE_MAC = BLACKLIST.BLACKLIST_DEVICE
    WHERE BLACKLIST.BLACKLIST_DEVICE IS NULL
    AND DEVICE_MAC = '#{mac_addr}'
    ") == mac_addr
  @db.query("
    INSERT INTO BESUCH
    (DEVICE_ID, MAC_PREFIX, LOC_NAME, VISIT_DATE, START_TIME, END_TIME, COUNT, MIN_SIGNAL, MAX_SIGNAL)
    VALUES
    ('#{device_id}', '#{mac_prefix}', '#{location_name}', '#{visit_date}', '#{start_time}', '#{end_time}', '#{count}', '#{min_signal}', '#{max_signal}')
    ON DUPLICATE KEY UPDATE
    END_TIME = GREATEST(END_TIME, VALUES(END_TIME)),
    START_TIME = LEAST(START_TIME, VALUES(START_TIME)),
    MAX_SIGNAL = GREATEST(MAX_SIGNAL, VALUES(MAX_SIGNAL)),
    MIN_SIGNAL = LEAST(MIN_SIGNAL, VALUES(MIN_SIGNAL)),
    COUNT = COUNT+1
  ")
  puts "INSERTING"
else
  puts "That device is being blacklisted..."
end