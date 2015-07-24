<?php
    $username = "root";
    $password = "banana";
    $host = "localhost:3306";
    $database = "test";

    $server = mysqli_connect($host, $username, $password, $database);
    $connection = mysqli_select_db($server, $database);

    $myquery = "
        SELECT v1.VISIT_DATE date, l1.location_name source, l2.location_name target, count(distinct v1.device_id) value
        FROM PAST_CLEAN v1, PAST_CLEAN v2, LOCATIONS l1, LOCATIONS l2
        WHERE v1.device_id = v2.device_id
        AND v1.LOCATION_NAME != V2.LOCATION_NAME
        AND v2.START_TIME > V1.END_TIME
        AND v1.LOCATION_NAME = l1.LOCATION_NAME
        AND v2.LOCATION_NAME = l2.LOCATION_NAME
        group by 1,2,3
        order by 1 asc;
                ";
    $query = mysqli_query($server, $myquery);
        
    if ( ! $query ) {
        echo mysql_error();
        die;
    }
        
    $data = array();
        
    for ($x = 0; $x < mysqli_num_rows($query); $x++) {
        $data[] = mysqli_fetch_assoc($query);
    }
        
    echo json_encode($data);     
         
    mysqli_close($server);
?>