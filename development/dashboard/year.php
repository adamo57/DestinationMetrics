<?php
    include 'connect.php';

    $myquery = "
                SELECT LOCATION_NAME AS LOCATION, VISIT_DATE AS DATE, COUNT(DISTINCT DEVICE_ID) AS COUNT
                FROM PAST_CLEAN
                WHERE LOCATION_NAME='mass moca, north adams'
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