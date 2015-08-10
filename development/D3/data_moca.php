<?php
    $username = "root";
    $password = "banana";
    $host = "localhost:3306";
    $database = "test";

    $server = mysqli_connect($host, $username, $password, $database);
    $connection = mysqli_select_db($server, $database);

    $myquery = "SELECT LOCATION_NAME AS LOCATION, VISIT_DATE AS DATE, COUNT(*) AS COUNT FROM PAST_CLEAN WHERE LOCATION_NAME='MASS MoCa, North Adams' ORDER BY VISIT_DATE";
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