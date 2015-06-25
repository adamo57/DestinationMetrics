<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>DM</title>
    
    </head>
  	<body>
        <?PHP
        set_time_limit(0);
        $user_name = "root";
        $password = "banana";
        $database = "test";
        $server = "localhost:3306";
        
        $db_handle = mysqli_connect($server, $user_name, $password, $database);
        $db_found = mysqli_select_db($db_handle, $database);
        
        function findLocation($LOC_ID)
        // takes location_id and translates it into the location's name for easy reading
        {
            $LOC_NAME = "";
            if($LOC_ID == 202481595345319){$LOC_NAME = "Lever Office, North Adams";}
            elseif($LOC_ID == 202481600165262){$LOC_NAME = "Spring Street, Williamstown";}
            elseif($LOC_ID == 202481601997564){$LOC_NAME = "MASS MoCa, North Adams";}
            else{$LOC_NAME = "Location not found";}
            return $LOC_NAME;
        }
        
        function checkSameDay($MAC_ADDR, $DATE)
        //takes mac address and checks to see if it has been seen before/later that day
        //returns true if mac address exists on that date, false if it does not
        {
            $ret = false;
	    global $db_handle;
            $sql = mysqli_query($db_handle, "SELECT COUNT(*) FROM Visits_Clean WHERE VISIT_DATE='" . $DATE . "' && DEVICE_ID='" . $MAC_ADDR . "'") or die (mysql_error());
            $check_result = mysqli_fetch_assoc($sql);
            if($check_result['COUNT(*)'] == 0){$ret = false;}
            else{$ret = true;}
            return $ret;
        }
	
        function checkLocation($MAC_ADDR, $DATE, $LOCATION)
        {
	    global $db_handle;
            $ret = false;
            $sql = mysqli_query($db_handle,
	    "SELECT LOCATION_NAME FROM Visits_Clean WHERE VISIT_DATE='" . $DATE . "' && DEVICE_ID='" . $MAC_ADDR . "'") or die (mysql_error());
            while($db = mysqli_fetch_assoc($sql))
            {
                $loc = $db['LOCATION_NAME'];
                if($loc == $LOCATION){$ret = false;}
                else{$ret = true;}
            }
            return $ret;
	}
        
        function checkStartTime($MAC_ADDR, $DATE, $TIME, $LOC)
        {
	    global $db_handle;
            $ret = false;
            $sql = mysqli_query($db_handle,
	    "SELECT START_TIME FROM Visits_Clean WHERE VISIT_DATE='" . $DATE . "' && DEVICE_ID='" . $MAC_ADDR . "' && LOCATION_NAME='" . $LOC . "'") or die (mysql_error());
            while($db = mysqli_fetch_assoc($sql))
            {
                $dtime = $db['START_TIME'];
                if($dtime > $TIME){$ret = true;}
            }
            return $ret;
        }
        
        function checkEndTime($MAC_ADDR, $DATE, $TIME, $LOC)
        {
	    global $db_handle;
            $ret = false;
            $sql = mysqli_query($db_handle,
	    "SELECT END_TIME FROM Visits_Clean WHERE VISIT_DATE='" . $DATE . "' && DEVICE_ID='" . $MAC_ADDR . "' && LOCATION_NAME='" . $LOC . "'") or die (mysql_error());
            while($db = mysqli_fetch_assoc($sql))
            {
                $dtime = $db['END_TIME'];
                if($dtime < $TIME){$ret = true;}
            }
            return $ret;
        }
        
        function checkMinSignal($MAC_ADDR, $DATE, $LOC, $SIGNAL)
        {
	    global $db_handle;
            $ret = false;
            $sql = mysqli_query($db_handle,
	    "SELECT MIN_SIGNAL FROM Visits_Clean WHERE VISIT_DATE='" . $DATE . "' && DEVICE_ID='" . $MAC_ADDR . "' && LOCATION_NAME='" . $LOC . "'") or die (mysql_error());
            while($db = mysqli_fetch_assoc($sql))
            {
                $sig = $db['MIN_SIGNAL'];
                if($sig > $SIGNAL){$ret = true;}
            }
            return $ret;
        }
        
        function checkMaxSignal($MAC_ADDR, $DATE, $LOC, $SIGNAL)
        {
	    global $db_handle;
            $ret = false;
            $sql = mysqli_query($db_handle,
	    "SELECT MAX_SIGNAL FROM Visits_Clean WHERE VISIT_DATE='" . $DATE . "' && DEVICE_ID='" . $MAC_ADDR . "' && LOCATION_NAME='" . $LOC . "'") or die (mysql_error());
            while($db = mysqli_fetch_assoc($sql))
            {
                $sig = $db['MAX_SIGNAL'];
                if($sig < $SIGNAL){$ret = true;}
            }
            return $ret;
        }
        
        if ($db_found)
        {
	       echo "beginning...";
            $load_data = mysqli_query($db_handle, "SELECT * FROM VISITS") or die(mysql_error());
            //mysqli_query($db_handle, "DELETE FROM Visits_Clean") or die(mysql_error()); //deletes all values from table
            
            $i = 0;
            while ($db_field = mysqli_fetch_assoc($load_data)) // while has rows 
            {
                $MAC_ADDR = $db_field['DEVICE_MAC'];
                $MAC_ADDR_PRE = substr($MAC_ADDR, 0, 8);
                $LOCATION_ID = $db_field['LOCATION_ID'];
                $LOCATION = findLocation($LOCATION_ID);
                $VISIT_TIME = $db_field['VISIT_TIME'];
                $DATE = date('Y-m-d', strtotime($VISIT_TIME));
                $TIME = date('H:i:s', strtotime($VISIT_TIME));
                $SIGNAL = $db_field['VISIT_DB'];
		$ext = "WHERE DEVICE_ID='" . $MAC_ADDR . "' && VISIT_DATE='" . $DATE . "' && LOCATION_NAME='" . $LOCATION . "'";

                $getCount = mysqli_fetch_assoc(mysqli_query($db_handle,
		"SELECT COUNT(*) FROM VISITS WHERE DEVICE_MAC='" . $MAC_ADDR . "' && LOCATION_ID=" . $LOCATION_ID . " && CAST(VISIT_TIME AS DATE)='" . $DATE . "'"));
                $COUNT = $getCount['COUNT(*)'];
                
                $newmac_insert = "INSERT INTO Visits_Clean
		(DEVICE_ID, MAC_PREFIX, LOCATION_ID, LOCATION_NAME, VISIT_DATE, START_TIME, END_TIME, COUNT, MIN_SIGNAL, MAX_SIGNAL)
		VALUES ('$MAC_ADDR', '$MAC_ADDR_PRE', '$LOCATION_ID', '$LOCATION', '$DATE', '$TIME', '$TIME', '$COUNT', '$SIGNAL', '$SIGNAL')";
                
                $check = mysqli_fetch_assoc(mysqli_query($db_handle, "SELECT COUNT(*) FROM Visits_Clean WHERE DEVICE_ID='" . $MAC_ADDR . "'"));
                if($check['COUNT(*)'] == 0)
                {
                    mysqli_query($db_handle, $newmac_insert) or die (mysql_error());
                    //echo "new data added <br>";
                }
                else
                {
                    if(checkSameDay($MAC_ADDR, $DATE) == true)
                    {
                        if(checkLocation($MAC_ADDR, $DATE, $LOCATION) == true)
                        {mysqli_query($db_handle, $newmac_insert) or die(mysql_error());}
                        else
                        {
                            if(checkStartTime($MAC_ADDR, $DATE, $TIME, $LOCATION) == true)
                            {mysqli_query($db_handle, "UPDATE Visits_Clean SET START_TIME='" . $TIME . "' " . $ext) or die (mysql_error());}
                            elseif(checkEndTime($MAC_ADDR, $DATE, $TIME, $LOCATION) == true)
                            {mysqli_query($db_handle, "UPDATE Visits_Clean SET END_TIME='" . $TIME . "' " . $ext) or die (mysql_error());}
                            else
                            {}
			    
                            if(checkMinSignal($MAC_ADDR, $DATE, $LOCATION, $SIGNAL) == true)
                            {mysqli_query($db_handle, "UPDATE Visits_Clean SET MIN_SIGNAL=" . $SIGNAL . " " . $ext) or die (mysql_error());}
                            elseif(checkMaxSignal($MAC_ADDR, $DATE, $LOCATION, $SIGNAL) == true)
                            {mysqli_query($db_handle, "UPDATE Visits_Clean SET MAX_SIGNAL=" . $SIGNAL . " " . $ext) or die (mysql_error());}
                            else
                            {}
                        }
                    }
                    else
                    {
                        mysqli_query($db_handle, $newmac_insert) or die (mysql_error());
                    }
                }
		$i = $i + 1;
                //echo "------------------------------------------------------------------------<br>";
            }
        }
        else{print "Database NOT Found" . $db_handle;}
	
	echo "DONE!";
        ?>
	</body>
</html>