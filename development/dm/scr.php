<?php
ini_set('memory_limit', '-1');
set_time_limit(0);
ini_set('mysql.connect_timeout', 300);
ini_set('default_socket_timeout', 300);
//gotta comment my code
function db_connect()
{
    static $connection;
    if(!isset($connection))
    {
        $config = parse_ini_file('config.ini'); 
        $connection = mysqli_connect($config['server'], $config['username'], $config['password'], $config['database']);
    }
    if($connection === false)
    {
        return mysqli_connect_error(); 
    }
    return $connection;
}

$db_handle = db_connect();

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

echo "beginning...";
$select = "

    SELECT * FROM past WHERE CAST(VISIT_TIME AS DATE)='2015-07-31' && 
    CAST(VISIT_TIME AS TIME) >= '00:00:00' && CAST(VISIT_TIME AS TIME) < '24:00:00'

";
$load_data = mysqli_query($db_handle, $select);

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
$key = array("ON", "DUPLICATE", "KEY", "UPDATE", "END_TIME", "=", "GREATEST(END_TIME,", "VALUES(END_TIME)),", 
            "START_TIME", "=", "LEAST(START_TIME,", "VALUES(START_TIME)),", "MAX_SIGNAL", "=", "GREATEST(MAX_SIGNAL,",
                "VALUES(MAX_SIGNAL)),", "MIN_SIGNAL", "=", "LEAST(MIN_SIGNAL,", "VALUES(MIN_SIGNAL)),", "COUNT", "=", "COUNT+1");
$values = array();

echo "setting implode... ";
foreach($rowset as $row)
{
    $values[] = "('" . 
                mysqli_real_escape_string($db_handle, ($row['DEVICE_MAC'])) . "','" . 
                mysqli_real_escape_string($db_handle, substr($row['DEVICE_MAC'],0,8)) . "','" . 
                mysqli_real_escape_string($db_handle, ($row['MAC_MANUFACTURE'])) . "','" . 
                mysqli_real_escape_string($db_handle, findLocation($row['LOCATION_ID'])) . "','" . 
                mysqli_real_escape_string($db_handle, date('Y-m-d', strtotime($row['VISIT_TIME']))) . "','" . 
                mysqli_real_escape_string($db_handle, date('H:i:s', strtotime($row['VISIT_TIME']))) . "','" . 
                mysqli_real_escape_string($db_handle, date('H:i:s', strtotime($row['VISIT_TIME']))) . 
                "',1," . 
                ($row['VISIT_DB']) . "," . 
                ($row['VISIT_DB']) . ")";
}

echo "upserting... \n";
$ins = "INSERT INTO past_clean " . implode(',', $into) . " VALUES " . implode(',', $values) . implode(' ', $key);

//echo $ins . "<br>";
mysqli_query($db_handle, $ins) or die(mysqli_error($db_handle));

$time_elapsed_secs = microtime(true) - $start;

echo "total time elapsed for " . sizeof($values) . " rows: " . round($time_elapsed_secs,2) . " seconds\n";
mysqli_close($db_handle);
?>