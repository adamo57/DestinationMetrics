<?php
    function db_connect()
    {
        static $connection;
        if(!isset($connection))
        {
            $config = parse_ini_file('../config.ini'); 
            $connection = mysqli_connect($config['server'], $config['username'], $config['password'], $config['database']);
        }
        if($connection === false)
        {
            return mysqli_connect_error(); 
        }
        return $connection;
    }

    $server = db_connect();

    $myquery = "
                SELECT LOCATION_NAME AS LOCATION, VISIT_DATE AS DATE, COUNT(DISTINCT DEVICE_ID) AS COUNT
                FROM PAST_CLEAN
                WHERE LOCATION_NAME='Lever Office, North Adams'
                    AND YEAR(VISIT_DATE)='2015'
                GROUP BY VISIT_DATE, LOCATION_NAME
                ORDER BY VISIT_DATE;
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