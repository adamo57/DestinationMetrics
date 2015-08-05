<!DOCTYPE HTML>
<html>
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
    <head>
        <meta charset="utf-8">
		<title>Dashboard</title>
		<link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
		<link rel="stylesheet" href="style.css">
		<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
		<script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
		<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.5/d3.min.js"></script>
    </head>
    <body>
    	<div class="container">
	        <div class="jumbotron">
	        	<h1>DASHBOARD</h1>
	        </div>

	        <div class="col-md-12 line">
	        	<div class="radio">
	        		<label class="radio-inline"><input name="week" type="radio" onClick="getWeek()" checked="checked">This Week</label>
	        		<label class="radio-inline"><input name="week" type="radio" onClick="getMonth()">This Month</label>
	        		<label class="radio-inline"><input name="week" type="radio" onClick="getYear()">This Year</label>
	        	</div>
	        	<script type="text/javascript" src="line.js"></script>
    		</div>

    		<div class="col-md-12">
    			<h3>Traffic Overview</h3>
    			<table style="width: 100%">
    				<tr>

    					<td><span id="spark01">
    						<?php
    						$query = "SELECT COUNT(DISTINCT DEVICE_ID)
    									FROM PAST_CLEAN
    									WHERE LOCATION_NAME='lever office, north adams'
    										AND VISIT_DATE BETWEEN '2015-03-31' - INTERVAL 7 DAY AND '2015-03-31'";
    						$exec_query = mysqli_query($server, $query);
						    echo mysqli_result($exec_query) . " unique visitors";
    					?>
    						</span></td>
    					<td><span id="spark03">20% new visitors</span></td>
    				</tr>
    				<tr>
    					<td><span id="spark02">2:00:00 Avg. Visit Duration</span></td>
    					<td><span id="spark04">30% been here more than twice</span></td>
    				</tr>
    			</table>
    		</div>

    		<div class="col-md-12">
    			<h3>Traffic Sources</h3>
    			<p>Let's throw in some pie charts, kids</p>
    		</div>
		</div>
    </body>
</html>
