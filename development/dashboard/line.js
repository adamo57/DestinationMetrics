var w = 1200;
var h = 300;
var padding = 50;

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

d3.json("week.php", function(error, data)
    {
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

function donut()
{
    var dataset = {
      apples: [388,1433],
    };

    var width = 100,
        height = 150,
        radius = Math.min(width, height) / 2;

    var percent = (dataset.apples[0] / (dataset.apples[0] + dataset.apples[1])) * 100;
    percent = Math.round(percent * 10) / 10;

    var color = d3.scale.category20();

    var pie = d3.layout.pie()
        .sort(null);

    var arc = d3.svg.arc()
        .innerRadius(radius)
        .outerRadius(radius - 20);

    var donut_svg = d3.select(".traffic")
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

    var path = donut_svg.selectAll("path")
        .data(pie(dataset.apples))
        .enter()
        .append("path")
        .attr("fill", function(d, i) { return color(i); })
        .attr("d", arc);

    var label = donut_svg.append("g")
        .attr("height", 100)
        .attr("width", 100)
        .attr("transform", "translate(-" + ((width / 3) - 3) + "," + (radius + 20) + ")");

    label.append("text")
        .attr("x", 10)
        .attr("y", -65)
        .text(percent + "%")
        .attr("fill", "black")
        .attr("font-size", "14px")
        .attr("font-weight", "bold");

    label.append("text")
        .attr("x", 0)
        .attr("y", 0)
        .text("new visitors")
        .attr("fill", "black")
        .attr("font-size", "12px");
}

function donut2()
{
    var dataset = {
      apples: [600,1],
    };

    var width = 100,
        height = 150,
        radius = Math.min(width, height) / 2;

    var percent = (dataset.apples[0] / (dataset.apples[0] + dataset.apples[1])) * 100;
    percent = Math.round(percent * 10) / 10;

    var color = d3.scale.category20();

    var pie = d3.layout.pie()
        .sort(null);

    var arc = d3.svg.arc()
        .innerRadius(radius)
        .outerRadius(radius - 20);

    var donut_svg = d3.select(".traffic2")
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

    var path = donut_svg.selectAll("path")
        .data(pie(dataset.apples))
        .enter()
        .append("path")
        .attr("fill", function(d, i) { return color(i); })
        .attr("d", arc);

    var label = donut_svg.append("g")
        .attr("height", 100)
        .attr("width", 100)
        .attr("transform", "translate(-" + ((width / 3) - 3) + "," + (radius + 20) + ")");

    label.append("text")
        .attr("x", 10)
        .attr("y", -65)
        .text(percent + "%")
        .attr("fill", "black")
        .attr("font-size", "14px")
        .attr("font-weight", "bold");

    label.append("text")
        .attr("x", 0)
        .attr("y", 0)
        .text("from MoCA")
        .attr("fill", "black")
        .attr("font-size", "12px");
}

donut();
donut2();

function redraw(data)
{
    var minDate = d3.min(data,function(d) {return d.DATE;});
    var maxDate = d3.max(data,function(d) {return d.DATE;});
    xScale.domain([minDate, maxDate]);
    yScale.domain([0,d3.max(data,function(d) {return +d.COUNT;})])

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
