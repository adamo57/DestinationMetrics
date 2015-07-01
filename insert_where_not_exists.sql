SELECT * 
FROM BESUCH
WHERE NOT EXISTS(
	SELECT besuch_id 
	FROM BESUCH
	WHERE device_id = #{device_id}
		AND LOC_NAME = #{location_name}
		AND datediff(start_time, getdate()) <= 45
	)
