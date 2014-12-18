var tagpie_width = 600,
    tagpie_height = 200;
var svg = d3.select("#tagpie")
	.append("svg")
    .attr("width", tagpie_width)
    .attr("height", tagpie_height)
	.append("g")

svg.append("g")
	.attr("class", "slices");
svg.append("g")
	.attr("class", "labels");
svg.append("g")
	.attr("class", "lines");

var radius = Math.min(tagpie_width, tagpie_height) / 2;

var pie = d3.layout.pie()
	.sort(null)
	.value(function(d) {
		return d.value;
	});

var arc = d3.svg.arc()
	.outerRadius(radius * 0.8)
	.innerRadius(radius * 0.4);

var outerArc = d3.svg.arc()
	.innerRadius(radius * 0.9)
	.outerRadius(radius * 0.9);

svg.attr("transform", "translate(" + tagpie_width / 2 + "," + tagpie_height / 2 + ")");

var key = function(d){ return d.data.label; };

var color = d3.scale.ordinal()

  .domain(["C++", "haskell", "algorithm", "puzzle", "bash", "unix", "testing", "ruby", "lua", "git",
           "dsl", "tool", "rake", "datastructure", "structure", "ghc", "performance", "blogging", "llvm", "clang",
           "quickcheck", "gtest", "udp", "networking", "osx", "templates", "android", "concurrency", "ipc", "rant",
           "types"])
	.range ([ "#86E500",
            "#85DE07",
            "#84D70F",
            "#83D016",
            "#82C91E",
            "#81C225",
            "#80BC2D",
            "#7FB534",
            "#7FAE3C",
            "#7EA743",
            "#7DA04B",
            "#7C9A52",
            "#7B935A",
            "#7A8C61",
            "#798569",
            "#787E70",
            "#787878"]);
var colors = [
"#FF9F3D",
"#E1E1E1",
"#D2D2D2",
"#C3C3C3",
"#B4B4B4",
"#A5A5A5",
"#969696",
"#878787",
"#787878",
"#84D70F",
"#86E500"
];

d3.json("tag_ratio.json", function(error, tags) {
  change(tags);
});

var colorIndex = 0;
function colorRotate(){
  var c = colors[colorIndex];
  colorIndex += 1;
  colorIndex %= (colors.length - 1);
  return c;
}

function change(data) {

	/* ------- PIE SLICES -------*/
	var slice = svg.select(".slices").selectAll("path.slice")
		.data(pie(data), key);

	slice.enter()
		.insert("path")
		.style("fill", function(d) { return colorRotate(); })
		// .style("fill", function(d) { return color(d.data.label); })
		.attr("class", "slice");

	slice
		.transition().duration(1000)
		.attrTween("d", function(d) {
			this._current = this._current || d;
			var interpolate = d3.interpolate(this._current, d);
			this._current = interpolate(0);
			return function(t) {
				return arc(interpolate(t));
			};
		})

	slice.exit()
		.remove();

	/* ------- TEXT LABELS -------*/

	var text = svg.select(".labels").selectAll("text")
		.data(pie(data), key);

	text.enter()
		.append("text")
		.attr("dy", ".35em")
		.text(function(d) {
			return d.data.label;
		});

	function midAngle(d){
		return d.startAngle + (d.endAngle - d.startAngle)/2;
	}

	text.transition().duration(1000)
		.attrTween("transform", function(d) {
			this._current = this._current || d;
			var interpolate = d3.interpolate(this._current, d);
			this._current = interpolate(0);
			return function(t) {
				var d2 = interpolate(t);
				var pos = outerArc.centroid(d2);
				pos[0] = radius * (midAngle(d2) < Math.PI ? 1 : -1);
				return "translate("+ pos +")";
			};
		})
		.styleTween("text-anchor", function(d){
			this._current = this._current || d;
			var interpolate = d3.interpolate(this._current, d);
			this._current = interpolate(0);
			return function(t) {
				var d2 = interpolate(t);
				return midAngle(d2) < Math.PI ? "start":"end";
			};
		});

	text.exit()
		.remove();

	/* ------- SLICE TO TEXT POLYLINES -------*/

	var polyline = svg.select(".lines").selectAll("polyline")
		.data(pie(data), key);

	polyline.enter()
		.append("polyline");

	polyline.transition().duration(1000)
		.attrTween("points", function(d){
			this._current = this._current || d;
			var interpolate = d3.interpolate(this._current, d);
			this._current = interpolate(0);
			return function(t) {
				var d2 = interpolate(t);
				var pos = outerArc.centroid(d2);
				pos[0] = radius * 0.95 * (midAngle(d2) < Math.PI ? 1 : -1);
				return [arc.centroid(d2), outerArc.centroid(d2), pos];
			};
		});

	polyline.exit()
		.remove();
};

