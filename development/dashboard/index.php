<!DOCTYPE HTML>
<html>
<?php include 'connect.php';?>
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
                <span class="traffic"></span>
                <span class="traffic2"></span>
    		</div>
            <script type="text/javascript" src="line.js"></script>
		</div>
    </body>
</html>
