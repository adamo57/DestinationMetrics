
// debugging    
function output(inp) {
    document.body.appendChild(document.createElement('pre')).innerHTML = inp;
}

var units = "Visits";

var margin = {top: 10, right: 10, bottom: 10, left: 10},
    width = 840 - margin.left - margin.right,
    height = 300 - margin.top - margin.bottom;

var formatNumber = d3.format(",.0f"),    // zero decimal places
    format = function(d) { return formatNumber(d) + " " + units; },
    color = d3.scale.category20();

// append the svg canvas to the page
var svg = d3.select(".sankey").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", 
          "translate(" + margin.left + "," + margin.top + ")");

// Set the sankey diagram properties
var sankey = d3.sankey()
    .nodeWidth(36)
    .nodePadding(10)
    .size([width, height]);

var path = sankey.link();

var visits = {};
var dates = [];
var maxdayvisits = 0;

// load the data (using the timelyportfolio csv method)
d3.csv("sankeydata.csv", function(error, data) {

    re = /^zzz_/;
    graph = {
        "nodes": [],
        "links": []
    };

    datetotals = d3.nest()
        .key(function(d) {return d.date})
        .rollup(function(values) {
            return d3.sum(values, function(d) {return +d.value; }) })
        .entries(data);

    daymax = d3.max(datetotals, function(d) {return +d.values});

//    output(JSON.stringify(daymax,null,4));
  //  output(JSON.stringify(datetotals,null,4));


    //set up graph in same style as original example but empty
    data.forEach(function (d,i) {

        // The source and target nodes will have the same names (since
        // this is bi-directional visit data between different
        // sites). So we need to make the target node names unique
        // temporarily or the sankey stuff will have a cow.  Then we
        // put the names back as we found them.

        visitlinks = visits[d.date] || (dates.push(d.date), visits[d.date] = []);
        graph.nodes.push({ "name": d.source });
        graph.nodes.push({ "name": 'zzz_' + d.target });
        visitlinks.push({ "source": d.source,
                           "target": 'zzz_' + d.target,
                           "value": +d.value });
    });

    

    // return only the distinct / unique nodes
    graph.nodes = d3.keys(d3.nest()
                          .key(function (d) { return d.name; })
                          .map(graph.nodes));

    graph.nodes.sort(function (a,b) {
        if (a.name > b.name) {
            return 1;
        }
        if (a.name < b.name) {
            return -1;
        }
        // a must be equal to b
        return 0;
    });

    dates.forEach(function(k) {
        visitlinks = visits[k];
        // loop through each link replacing the text with its index from node
        visitlinks.forEach(function (d, i) {
            visitlinks[i].source = graph.nodes.indexOf(visitlinks[i].source);
            visitlinks[i].target = graph.nodes.indexOf(visitlinks[i].target);
        });

    });

    //now loop through each nodes to make nodes an array of objects
    // rather than an array of strings, and fix up the names
    graph.nodes.forEach(function (d, i) {
        graph.nodes[i] = { "name": d.replace(re,'') };
    });

    
    // update the slider max value to the max date index we can use
    d3.select("#nRadius").property("max", dates.length - 1);


    // 
    function redraw(index) {

        graph.links = visits[dates[index]];

        sankey
            .range(daymax)
            .nodes(graph.nodes)
            .links(graph.links)
            .layout(0);

        // add in the links
        svg.selectAll("g").remove();

        var link = svg.append("g").selectAll(".link")
            .data(graph.links)
            .enter().append("path")
            .attr("class", "link")
            .attr("d", path)
            .style("stroke-width", function(d) { return Math.max(1, d.dy); })
            .sort(function(a, b) { return b.dy - a.dy; })
            .style("visibility", function() {
                if (this.__data__.value == 0) {
                    return "hidden";
                } else {
                    return "visible";
                }
            });

        // add the link titles
        link.append("title")
            .text(function(d) {
    	        return d.source.name + "to " + 
                    d.target.name + "\n" + format(d.value); });

        // add in the nodes
        var node = svg.append("g").selectAll(".node")
            .data(graph.nodes)
            .enter().append("g")
            .attr("class", "node")
            .attr("transform", function(d) { 
	        return "translate(" + d.x + "," + d.y + ")"; })
            .call(d3.behavior.drag()
                  .origin(function(d) { return d; })
                  .on("dragstart", function() { 
		      this.parentNode.appendChild(this); })
                  .on("drag", dragmove))
            .style("visibility", function() {
                if (this.__data__.value == 0) {
                    return "hidden";
                } else {
                    return "visible";
                }
            });

        // add the rectangles for the nodes
        node.append("rect")
            .attr("height", function(d) { return d.dy; })
            .attr("width", sankey.nodeWidth())
            .style("fill", function(d) { 
	        return d.color = color(d.name.replace(/ .*/, "")); })
            .style("stroke", function(d) { 
	        return d3.rgb(d.color).darker(2); })
            .append("title")
            .text(function(d) { 
	        return d.name + "\n" + format(d.value); });

        // add in the title for the nodes
        node.append("text")
            .attr("x", -6)
            .attr("y", function(d) { return d.dy / 2; })
            .attr("dy", ".35em")
            .attr("text-anchor", "end")
            .attr("transform", null)
            .text(function(d) { return d.name; })
            .filter(function(d) { return d.x < width / 2; })
            .attr("x", 6 + sankey.nodeWidth())
            .attr("text-anchor", "start");
        // the function for moving the nodes
        function dragmove(d) {
            d3.select(this).attr("transform", 
                                 "translate(" + d.x + "," + (
                                     d.y = Math.max(0, Math.min(height - d.dy, d3.event.y))
                                 ) + ")");
            sankey.relayout();
            link.attr("d", path);
        }


    };

//    d3.select("#nRadius").on("input", function() {
//        update(+this.value);
//    });

    // Initial starting radius of the circle 

    // update the elements
    function update(nRadius) {

        // adjust the text on the range slider
        d3.select("#nRadius-value").text(dates[nRadius]);
        d3.select("#nRadius").property("value", nRadius);

        // update the circle radius
            redraw(nRadius);
    }


    // Nav Chart
    var navWidth = width,
        navHeight = 100 - margin.top - margin.bottom;

    var navChart = d3.select('.navchart').classed('chart', true).append('svg')
        .classed('navigator', true)
        .attr('width', navWidth + margin.left + margin.right)
        .attr('height', navHeight + margin.top + margin.bottom)
        .append('g')
        .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

    var navXScale = d3.scale.linear()
        .domain([0, dates.length - 1])
        .range([0, navWidth])
        .clamp(true),
        navYScale = d3.scale.linear()
        .domain([0, daymax])
        .range([navHeight, 0]);


    var navData = d3.svg.area()
        .x(function (d,i) { return navXScale(i); })
        .y0(navHeight)
        .y1(function (d) { return navYScale(d.values); });

    var navLine = d3.svg.line()
        .x(function (d,i) { return navXScale(i); })
        .y(function (d) { return navYScale(d.values); });

    navChart.append('path')
        .attr('class', 'data')
        .attr('d', navData(datetotals));

    navChart.append('path')
        .attr('class', 'line')
        .attr('d', navLine(datetotals));
//    output(JSON.stringify(visits,null,4));

    // Slider
    var brush = d3.svg.brush()
        .x(navXScale)
        .extent([0, 0])
        .on("brush", brushed);

    var slider = navChart.append("g")
        .attr("class", "slider")
        .call(brush);
      //  .selectAll("rect")
        // .attr("height", navHeight);

    slider.selectAll(".extent,.resize")
        .remove();

   slider.select(".background")
      .attr("height", height);

    var handle = slider.append("line")
        .attr("class", "handle")
        .attr("transform", "translate(0,0)")
        .attr("x1", 0)
        .attr("y1", 0)
        .attr("x2", 0)
        .attr("y2", navHeight);

    slider
        .call(brush.extent([0,0]))
        .call(brush.event);

    function brushed() {
        var value = brush.extent()[0];

//         output(JSON.stringify(value,null,4));
     
       if (d3.event.sourceEvent) { // not a programmatic event
            value = navXScale.invert(d3.mouse(this)[0]);
            brush.extent([value, value]);
       }

        handle.attr("x1", navXScale(value));
        handle.attr("x2", navXScale(value));
        update(Math.round(value));
    }


//    update(0);
});
