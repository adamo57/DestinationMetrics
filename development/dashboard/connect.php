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

    function mysqli_result($res, $row = 0 , $col = 0)
    { 
    	$numrows = mysqli_num_rows($res); 
    	if ($numrows && $row <= ($numrows-1) && $row >=0)
    	{
	        mysqli_data_seek($res,$row);
	        $resrow = (is_numeric($col)) ? mysqli_fetch_row($res) : mysqli_fetch_assoc($res);
	        if (isset($resrow[$col])){
	            return $resrow[$col];
        }
    }
    return false;
}

    $server = db_connect();
?>