<?php
    $username = "root";
    $password = "banana";
    $host = "localhost:3306";
    $database = "test";

    $server = mysqli_connect($host, $username, $password, $database);
    $connection = mysqli_select_db($server, $database);

    $myquery = "SELECT VISIT_DATE AS DATE, HOUR(START_TIME) AS HOUR, COUNT(DEVICE_ID) AS COUNT FROM WILCO GROUP BY VISIT_DATE, HOUR(START_TIME)";
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