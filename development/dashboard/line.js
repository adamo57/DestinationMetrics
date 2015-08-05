var w = 1200,
    h = 300,
    padding = 50;

var formatTime = d3.time.format("%b %d");
var formatCount = d3.format("0,000");

var xScale = d3.time.scale()
    .range([padding, w - padding * 2]);

var yScale = d3.scale.linear()
    .range([h - padding, padding]);

var lineGen = d3.svg.line()
    .x(function(d){return xScale(d.DATE);})
    .y(function(d){return yScale(d.COUNT);})
    .interpolate("linear");

var xAxis = d3.svg.axis()
    .orient("bottom")
    .scale(xScale)
    .ticks(d3.time.day.utc, 1)
    .tickSize(10)
    .tickFormat(d3.time.format.utc('%b %d'));
    
var yAxis = d3.svg.axis()
    .orient("left")
    .scale(yScale);

var svg = d3.select(".line")
    .append("svg")
    .attr("width", w)
    .attr("height", h);

d3.json("week.php", function(error, data) {
    data.forEach(function(d) {
        d.LOCATION = d.LOCATION;
        d.DATE = new Date(d.DATE);
        d.COUNT = d.COUNT;
    });

    xScale.domain([d3.min(data,function(d) {return d.DATE;}), d3.max(data,function(d) {return d.DATE;})])
    yScale.domain([0,d3.max(data,function(d) {return +d.COUNT;})])

    svg.append('svg:path')
        .style("stroke", "blue")
        .attr('stroke-width', 2)
        .attr("class", "dline")
        .attr('fill', 'none')
        .attr('d', lineGen(data));

    /*svg.selectAll("dot")
        .data(data)
        .enter()
        .append("circle")
        .attr("class", "dot")

        .attr("cx", function(d) {
            return xScale(d.DATE);
        })
        .attr("cy", function (d) {
            return yScale(d.COUNT);
        })
        .attr("r", 5);*/

    svg.append("g")
        .attr("class", "y axis")
        .attr("transform", "translate(" + padding + ",0)")
        .call(yAxis);

    svg.append("text")
          .attr("transform", "rotate(-90)")
          .attr("y", -50)
          .attr("x", -(h / 2) + padding)
          .attr("dy", ".71em")
          .style("text-anchor", "end")
          .text("# of Unique Visitors");

    svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + (h - padding) + ")")
        .call(xAxis)
        .selectAll("text")  
            .style("text-anchor", "end")
            .attr("dx", "-.8em")
            .attr("dy", ".15em")
            .attr("transform", function(d) {
                return "rotate(-65)" 
            });
});

function redraw(data)
{
    var minDate = d3.min(data,function(d) {return d.DATE;});
    var maxDate = d3.max(data,function(d) {return d.DATE;});
    xScale.domain([minDate, maxDate]);
    yScale.domain([0,d3.max(data,function(d) {return +d.COUNT;})])

    /*var content = svg.selectAll(".dot")
        .data(data);

    content.enter()
        .append("circle")
        .attr("class", "dot")
        .attr("cx", function(d) {
            return xScale(d.DATE);
        })
        .attr("cy", function (d) {
            return yScale(d.COUNT);
        })
        .attr("r", 5);

        content.exit().remove();*/

    svg.select(".dline")
        .transition()
        .duration(750)
        .attr("d", lineGen(data));
    svg.select(".x.axis")
        .transition()
        .duration(750)
        .call(xAxis)
        .selectAll("text")  
            .style("text-anchor", "end")
            .attr("dx", "-.8em")
            .attr("dy", ".15em")
            .attr("transform", function(d) {
                return "rotate(-65)" 
            });
    svg.select(".y.axis")
        .call(yAxis);
}

function getWeek()
{
    d3.json("week.php", function(error, data) {
    data.forEach(function(d) {
        d.LOCATION = d.LOCATION;
        d.DATE = new Date(d.DATE);
        d.COUNT = d.COUNT;
        });
        xAxis.ticks(d3.time.day.utc, 1).tickFormat(d3.time.format.utc('%b %d'));
        redraw(data);
    });
}

function getMonth()
{
    d3.json("month.php", function(error, data) {
    data.forEach(function(d) {
        d.LOCATION = d.LOCATION;
        d.DATE = new Date(d.DATE);
        d.COUNT = d.COUNT;
        });
        xAxis.ticks(d3.time.day.utc, 1).tickFormat(d3.time.format.utc('%b %d'));
        redraw(data);
    });
}

function getYear()
{
    d3.json("year.php", function(error, data) {
    data.forEach(function(d) {
        d.LOCATION = d.LOCATION;
        d.DATE = new Date(d.DATE);
        d.COUNT = d.COUNT;
        });
        xAxis.ticks(d3.time.months.utc, 1).tickFormat(d3.time.format.utc('%b'));
        redraw(data);
    });
}