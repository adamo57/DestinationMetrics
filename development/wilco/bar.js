var margin = {top: 20, right: 20, bottom: 30, left: 50},
    width = 650 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

var x0 = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

var x1 = d3.scale.ordinal();

var y = d3.scale.linear()
    .range([height, 0]);

var color = d3.scale.ordinal()
    .range(["#ffae00", "#de00ff"]);

var color2 = d3.scale.category20b()
    .range(["#ffd478", "#fab9a0", "#f393d7", "#de00ff",
            "#d992e7", "#bbb7c3", "#9ddc9f", "#20ed1b"]);

var xAxis = d3.svg.axis()
    .scale(x0)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

var svg = d3.select(".avg").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.csv("weekends_avg.csv", function(error, data) {
  if (error) throw error;

  var weekDate = d3.keys(data[0]).filter(function(key) { return key !== "day"; });

  data.forEach(function(d) {
    d.weekend = weekDate.map(function(name) { return {name: name, value: +d[name]}; });
  });

  x0.domain(data.map(function(d) { return d.day; }));
  x1.domain(weekDate).rangeRoundBands([1, x0.rangeBand()],.03,0);
  y.domain([0, d3.max(data, function(d) { return d3.max(d.weekend, function(d) { return d.value; }); })]);

  svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

  svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("# of Unique Visitors");

  var state = svg.selectAll(".state")
      .data(data)
    .enter().append("g")
      .attr("class", "g")
      .attr("transform", function(d) { return "translate(" + x0(d.day) + ",0)"; });

  state.selectAll("rect")
      .data(function(d) { return d.weekend; })
    .enter().append("rect")
      .attr("width", x1.rangeBand())
      .attr("x", function(d) { return x1(d.name); })
      .attr("y", function(d) { return y(d.value); })
      .attr("height", function(d) { return height - y(d.value); })
      .style("fill", function(d)
        {
          return color(d.name);
        });

    state.selectAll("text")
      .data(function(d) { return d.weekend; })
      .enter()
      .append("text")
      .text(function(d)
      {
        return d.value;
      })
      .attr("text-anchor", "middle")
      .attr("x", function(d) { return x1(d.name) + (x1.rangeBand() / 2.1); })
      .attr("y", function(d) { return y(d.value) - 3; })
      .style("fill", "black");

  var legend = svg.selectAll(".legend")
      .data(weekDate.slice())
    .enter().append("g")
      .attr("class", "legend")
      .attr("transform", function(d, i) { return "translate(0," + i * 15 + ")"; });

  legend.append("rect")
      .attr("x", width - 18)
      .attr("width", 8)
      .attr("height", 8)
      .style("fill", color);

  legend.append("text")
      .attr("x", width - 24)
      .attr("y", 4)
      .attr("dy", ".35em")
      .attr("class", "legend")
      .style("text-anchor", "end")
      .text(function(d) { return d; });
});

var spec = d3.select(".spec").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.csv("weekends.csv", function(error, data) {
  if (error) throw error;

  var weekDate = d3.keys(data[0]).filter(function(key) { return key !== "day"; });

  data.forEach(function(d) {
    d.weekend = weekDate.map(function(name) { return {name: name, value: +d[name]}; });
  });

  x0.domain(data.map(function(d) { return d.day; }));
  x1.domain(weekDate).rangeRoundBands([1, x0.rangeBand()],.03,0);
  y.domain([0, d3.max(data, function(d) { return d3.max(d.weekend, function(d) { return d.value; }); })]);

  spec.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

  spec.append("g")
      .attr("class", "y axis")
      .call(yAxis)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("# of Unique Visitors");

  var state = spec.selectAll(".state")
      .data(data)
    .enter().append("g")
      .attr("class", "g")
      .attr("transform", function(d) { return "translate(" + x0(d.day) + ",0)"; });

  state.selectAll("rect")
      .data(function(d) { return d.weekend; })
    .enter().append("rect")
      .attr("width", x1.rangeBand())
      .attr("x", function(d) { return x1(d.name); })
      .attr("y", function(d) { return y(d.value); })
      .attr("height", function(d) { return height - y(d.value); })
      .style("fill", function(d)
        {
          return color2(d.name);
        });

    state.selectAll("text")
      .data(function(d) { return d.weekend; })
      .enter()
      .append("text")
      .text(function(d)
      {
        return d.value;
      })
      .attr("text-anchor", "middle")
      .attr("x", function(d) { return x1(d.name) + (x1.rangeBand() / 2.1); })
      .attr("y", function(d) { return y(d.value) - 3; })
      .style("fill", "black")
      .attr("font-size", "9px")
      .attr("letter-spacing", "-1px");

  var legend = spec.selectAll(".legend")
      .data(weekDate.slice())
    .enter().append("g")
      .attr("class", "legend")
      .attr("transform", function(d, i) { return "translate(0," + i * 15 + ")"; });

  legend.append("rect")
      .attr("x", width - 18)
      .attr("width", 8)
      .attr("height", 8)
      .style("fill", color2);

  legend.append("text")
      .attr("x", width - 24)
      .attr("y", 4)
      .attr("dy", ".35em")
      .attr("class", "legend")
      .style("text-anchor", "end")
      .text(function(d) { return d; });
});