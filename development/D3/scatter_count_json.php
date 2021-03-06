<!DOCTYPE HTML>
<html>
    <head>
        <meta charset="utf-8">
    <title>D3 Scatterplot</title>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.5/d3.min.js"></script>
        <style type="text/css">
            .axis path,
            .axis line
            {
                fill: none;
                stroke: black;
                shape-rendering: crispEdges;
            }
            .axis text
            {
                font-family: sans-serif;
                font-size: 11px;
            }
            .dot
            {

            }
            .tooltip
            {
              position: absolute;
              pointer-events: none;
              font-family: sans-serif;
              font-size: 14px;
            }
        </style>
    </head>
    <body>
        <script type="text/javascript">
            
            var w = 1500,
                h = 600,
                padding = 50;

            var svg = d3.select("body")
            .append("svg")
            .attr("width", w)
            .attr("height", h);

            d3.json("data.php", function(error, data) {
                data.forEach(function(d) {
                    d.LOCATION = d.LOCATION;
                    d.DATE = new Date(d.DATE);
                    d.COUNT = d.COUNT;
                });

            var minDate = d3.min(data,function(d) {return d.DATE;});
            var maxDate = d3.max(data,function(d) {return d.DATE;})
            var formatTime = d3.time.format("%A, %B %e, %Y");
            
            var xScale = d3.time.scale()
                .domain([d3.time.day.offset(minDate, -1), maxDate])
                .range([padding, w - padding * 2]);
            
            var yScale = d3.scale.linear()
                .domain([0,d3.max(data,function(d) {
                                return +d.COUNT;
                            })])
                .range([h - padding, padding]);

            var rScale = d3.scale.linear()
                .domain([0, d3.max(data, function(d){
                    return d.COUNT;
                })])
                .range([4,7]);
                
            var xAxis = d3.svg.axis()
                .orient("bottom")
                .scale(xScale)
                .ticks(d3.time.months, 1)
                .tickFormat(d3.time.format('%b'));
                
            var yAxis = d3.svg.axis()
                .orient("left")
                .scale(yScale);

            var tooltip = d3.select("body").append("div")
                .attr("class", "tooltip")
                .style("opacity", 0);

            svg.selectAll("dot")
                .data(data)
                .enter()
                .append("circle")
                .attr("class", "dot")
                .style("fill", function(d){
                        if(d.LOCATION == "Lever Office, North Adams"){return "#33ccff";}
                        else if(d.LOCATION == "Spring Street, Williamstown"){return "#66FF33";}
                        else if(d.LOCATION == "MASS MoCa, North Adams"){return "#FF6699";}
                        else{return "#000"}
                    })
                .style("opacity", .5)
                .attr("cx", function(d) {
                    return xScale(d.DATE);
                })
                .attr("cy", function (d) {
                    return yScale(d.COUNT);
                })
                .attr("r", function (d) {
                    return rScale(d.COUNT);
                })
                .on("mouseover", function(d) {
                    d3.select(this)
                        .transition()
                        .duration(500)
                        .attr("r", function (d) {
                            return (rScale(d.COUNT) + 3);
                        })
                        .style("opacity", .9);
                    tooltip.transition()
                       .duration(400)
                        .style("opacity", .9);
                    tooltip.html("Location: " + d.LOCATION + "<br>" +
                        "Date: " + formatTime(d.DATE) + "<br>" +
                        "Unique Visitors: " + d.COUNT + "<br>" +
                        "Avg. Signal Strength: ")
                       .style("left", (padding) + "px")
                       .style("top", (h + padding) + "px");
                    })
                .on("mouseout", function(d) {
                    d3.select(this)
                    .transition()
                    .duration(400)
                    .attr("r", function (d) {
                        return rScale(d.COUNT);
                    })
                    .style("opacity", .5);
                    tooltip.transition()
                       .duration(1000)
                       .style("opacity", 0);
                       });
                
            svg.append("g")
                .attr("class", "axis")
                .attr("transform", "translate(" + padding + ",0)")
                .call(yAxis)
                .append("text")
                .style("text-anchor", "end")
                .text("# of Unique Visits");

            svg.append("g")
                .attr("class", "axis")
                .attr("transform", "translate(0," + (h - padding) + ")")
                .call(xAxis);
            });
        </script>
    </body>
</html>