<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>DM</title>
    
    </head>
    <body>
        <p>Get a load of this script</p>
        <?php
        ini_set('memory_limit', '-1');
        //set_time_limit(0);
        ini_set('mysql.connect_timeout', 300);
        ini_set('default_socket_timeout', 300);
        $user_name = "root";
        $password = "banana";
        $database = "test";
        $server = "localhost:3306";
        
        $db_handle = mysqli_connect($server, $user_name, $password, $database);
        $db_found = mysqli_select_db($db_handle, $database);

        function findLocation($LOC_ID)
        {
            $LOC_NAME = "";
            if($LOC_ID == 202481595345319){$LOC_NAME = "Lever Office, North Adams";}
            elseif($LOC_ID == 202481600165262){$LOC_NAME = "Spring Street, Williamstown";}
            elseif($LOC_ID == 202481601997564){$LOC_NAME = "MASS MoCa, North Adams";}
            else{$LOC_NAME = "Location not found";}
            return $LOC_NAME;
        }

        //mysqli_query($db_handle, "DELETE FROM JUNE_SUPERCLEAN") or die(mysql_error());
        //mysqli_query($db_handle, "ALTER TABLE JUNE_SUPERCLEAN AUTO_INCREMENT = 1") or die(mysql_error());
        
        echo "beginning...<br>";
        $load_data = mysqli_query($db_handle, "

            SELECT * FROM test.MARCH WHERE CAST(VISIT_TIME AS DATE)='2015-03-17' && 
            CAST(VISIT_TIME AS TIME) >= '12:00:00' && CAST(VISIT_TIME AS TIME) < '12:30:00'

            ");
        
        $start = microtime(true);

        $i = 0;
        $total = 0;
        $rowset = array();

        echo "fetching rows... ";
        while ($db_field = mysqli_fetch_assoc($load_data))
        {
            $rowset[] = $db_field;
        }
        $into = array("(DEVICE_ID", "MAC_PREFIX", "MAC_MANUFACTURE", "LOCATION_NAME", "VISIT_DATE", 
            "START_TIME", "END_TIME", "COUNT", "MIN_SIGNAL", "MAX_SIGNAL)");
        $values = array();

        echo "setting implode... ";
        foreach($rowset as $row)
        {
            $values[] = "('" . ($row['DEVICE_MAC']) . "','" . substr($row['DEVICE_MAC'],0,8) . "','" . ($row['MAC_MANUFACTURE']) . "','" . 
                        findLocation($row['LOCATION_ID']) . "','" . date('Y-m-d', strtotime($row['VISIT_TIME'])) . "','" . 
                        date('H:i:s', strtotime($row['VISIT_TIME'])) . "','" . date('H:i:s', strtotime($row['VISIT_TIME'])) . 
                        "',1," . ($row['VISIT_DB']) . "," . ($row['VISIT_DB']) . ")";
        }
        //print_r($rowset);
        //echo implode(",", $values) . "<br>";

        echo "upserting... <br>";
        $ins = "INSERT INTO JUNE_SUPERCLEAN " . implode(',', $into) . " VALUES " . implode(',', $values) . "
                ON DUPLICATE KEY UPDATE
                END_TIME = GREATEST(END_TIME, VALUES(END_TIME)),
                START_TIME = LEAST(START_TIME, VALUES(START_TIME)),
                MAX_SIGNAL = GREATEST(MAX_SIGNAL, VALUES(MAX_SIGNAL)),
                MIN_SIGNAL = LEAST(MIN_SIGNAL, VALUES(MIN_SIGNAL)),
                COUNT = COUNT+1";
        mysqli_query($db_handle, $ins) or die(mysqli_error($db_handle));

        $time_elapsed_secs = microtime(true) - $start;

        echo "total time elapsed for " . sizeof($values) . " rows: " . round($time_elapsed_secs,2) . " seconds<br>";
        echo "GET A LOAD OF IT";
        mysqli_close($db_handle);
        ?>
    </body>
</html>