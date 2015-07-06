INSERT INTO BESUCH 
(DEVICE_ID, MAC_PREFIX, LOC_NAME, START_TIME, END_TIME, COUNT, MIN_SIGNAL, MAX_SIGNAL)
SELECT besuch_id 
FROM BESUCH
WHERE NOT EXISTS(
	SELECT besuch_id
	FROM BESUCH
	WHERE device_id = #{device_id}
		AND LOC_NAME = #{location_name}
		AND datediff(start_time, getdate()) <= 45
	)










				               AND loc_name = #{location_name}
				               AND datediff(start_time, getdate()) <= '45'
