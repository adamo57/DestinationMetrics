<?php
    $username = "dm_master";
    $password = "5vYpDRwhAQK6*qPD";
    $host = "dmetrics.cmccpzrxo386.us-east-1.rds.amazonaws.com";
    $database = "past";

    $server = mysqli_connect($host, $username, $password, $database);
    $connection = mysqli_select_db($server, $database);

    $myquery = "

    SELECT m1.DATE date, m1.COUNT moca, COUNT(DISTINCT v1.DEVICE_ID) dm
    FROM massmoca m1, past_clean v1
    WHERE m1.DATE = v1.VISIT_DATE
        AND v1.LOCATION_NAME='mass moca, north adams'
    GROUP BY 1
    ORDER BY 1;

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