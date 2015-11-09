require '../utils.rb'
require '../Pi/Connect.rb'

#Goes through the entire BESUCH table and blacklists the MACs on the fly
#should run once a day automatically

results = @db.query("SELECT * FROM BESUCH")

results.each do |row|
  mac_pre = row['MAC_PREFIX']

  #@db.query("ALTER TABLE BLACKLIST
  #ADD INDEX (BLACKLIST_DEVICE)
  #USING BTREE")

  @db.query("SET collation_connection = 'utf8_general_ci'")
  if @db.query("
    SELECT EXISTS( 
            SELECT MAC_PREFIX
            FROM BESUCH
            WHERE TIMEDIFF(START_TIME, END_TIME) > 15
            HAVING COUNT(DISTINCT(VISIT_DATE)/7) = 1)"
  ) == 0  
    blacklist(mac_pre)
    next
  elsif @db.query("
    SELECT EXISTS (
              SELECT MAC_PREFIX
              FROM BESUCH
              WHERE TIMEDIFF(START_TIME, END_TIME) < 3 
              HAVING COUNT(DISTINCT(VISIT_DATE)) = 3
                AND FLOOR(COUNT(DISTINCT(VISIT_DATE))/7) > 1)
  ") == 0
    blacklist(mac_pre)
    next
  else
    puts "This really isn't here at all..."
  end
end