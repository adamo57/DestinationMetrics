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
                SELECT LOCATION_NAME AS LOCATION, TIMESTAMP(VISIT_DATE,STR_TO_DATE(HOUR(END_TIME), '%I%p')) AS HOUR, COUNT(*) AS COUNT
    FROM PAST_CLEAN
    WHERE VISIT_DATE='2015-03-30'
        AND LOCATION_NAME='Lever Office, North Adams'
    GROUP BY HOUR(END_TIME);
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