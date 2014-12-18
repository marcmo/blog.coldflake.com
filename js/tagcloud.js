var bleed = 30,
    tagcloud_width = 700,
    tagcloud_height = 500;

var pack = d3.layout.pack()
    .sort(null)
    .size([tagcloud_width, tagcloud_height + bleed * 2])
    .padding(2);

var tagcloud_svg = d3.selectAll("#tagcloud").append("svg")
    .attr("width", tagcloud_width)
    .attr("height", tagcloud_height)
  .append("g")
    .attr("transform", "translate(0," + -bleed + ")");

d3.json("tags.json", function(error, json) {
  var node = tagcloud_svg.selectAll(".node")
      .data(pack.nodes(json)
        .filter(function(d) { return !d.children; }))
    .enter().append("a")
      .attr("class", "node")
      .attr("xlink:href", function(d) { return d.name;})
      .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

  node.append("circle")
      .attr("r", function(d) { return d.r; });

  node.append("text")
      .text(function(d) { return d.name; })
      .style("font-size", function(d) { return Math.min(2 * d.r, (2 * d.r - 8) / this.getComputedTextLength() * 24) + "px"; })
      .attr("dy", ".35em");
});
