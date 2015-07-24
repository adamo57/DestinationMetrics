<?php
    $username = "root";
    $password = "banana";
    $host = "localhost:3306";
    $database = "test";

    $server = mysqli_connect($host, $username, $password, $database);
    $connection = mysqli_select_db($server, $database);

    $myquery = "SELECT DATE, COUNT FROM scrub WHERE LOCATION='Lever Office, North Adams' GROUP BY DATE ASC";
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