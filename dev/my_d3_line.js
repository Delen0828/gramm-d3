const x = ['0','0.10101','0.20202','0.30303','0.40404','0.50505','0.60606','0.70707','0.80808','0.90909','1.0101','1.1111','1.2121','1.3131','1.4141','1.5152','1.6162','1.7172','1.8182','1.9192','2.0202','2.1212','2.2222','2.3232','2.4242','2.5253','2.6263','2.7273','2.8283','2.9293','3.0303','3.1313','3.2323','3.3333','3.4343','3.5354','3.6364','3.7374','3.8384','3.9394','4.0404','4.1414','4.2424','4.3434','4.4444','4.5455','4.6465','4.7475','4.8485','4.9495','5.0505','5.1515','5.2525','5.3535','5.4545','5.5556','5.6566','5.7576','5.8586','5.9596','6.0606','6.1616','6.2626','6.3636','6.4646','6.5657','6.6667','6.7677','6.8687','6.9697','7.0707','7.1717','7.2727','7.3737','7.4747','7.5758','7.6768','7.7778','7.8788','7.9798','8.0808','8.1818','8.2828','8.3838','8.4848','8.5859','8.6869','8.7879','8.8889','8.9899','9.0909','9.1919','9.2929','9.3939','9.4949','9.596','9.697','9.798','9.899','10'];
const y = [0.000000,0.100838,0.200649,0.298414,0.393137,0.483852,0.569634,0.649610,0.722963,0.788945,0.846886,0.896192,0.936363,0.966988,0.987755,0.998452,0.998971,0.989306,0.969556,0.939922,0.900705,0.852307,0.795220,0.730026,0.657390,0.578053,0.492822,0.402567,0.308209,0.210709,0.111060,0.010279,-0.090606,-0.190568,-0.288587,-0.383664,-0.474830,-0.561155,-0.641760,-0.715822,-0.782588,-0.841375,-0.891584,-0.932705,-0.964317,-0.986099,-0.997828,-0.999385,-0.990753,-0.972022,-0.943381,-0.905124,-0.857639,-0.801411,-0.737013,-0.665102,-0.586410,-0.501740,-0.411956,-0.317972,-0.220746,-0.121270,-0.020558,0.080364,0.180467,0.278730,0.374151,0.465758,0.552617,0.633843,0.708607,0.776147,0.835775,0.886882,0.928948,0.961545,0.984339,0.997098,0.999692,0.992096,0.974385,0.946741,0.909446,0.862879,0.807517,0.743921,0.672743,0.594705,0.510606,0.421301,0.327701,0.230760,0.131467,0.030834,-0.070114,-0.170347,-0.268843,-0.364599,-0.456637,-0.544021];
const data = x.map((d, i) => ({ x: d, y: y[i] }));

const width = 800, height = 600;
    const margin = { 
        top: height * 0.1, 
        right: width * 0.05, 
        bottom: height * 0.15, 
        left: width * 0.1 
    };

const svg = d3.select("#chart")
    .append("svg")
    .attr("width", width)
    .attr("height", height);

// 添加提示框
const tooltip = d3.select("body")
    .append("div")
    .style("position", "absolute")
    .style("visibility", "hidden")
    .style("background-color", "white")
    .style("border", "1px solid #ccc")
    .style("padding", "5px")
    .style("border-radius", "5px")
    .style("font-size", "12px");

const xScale = d3.scaleLinear()
    .domain([d3.min(data, d => d.x) - (d3.max(data, d => d.x) - d3.min(data, d => d.x)) * 0.05, d3.max(data, d => d.x)])
    .range([margin.left, width - margin.right]);

const yScale = d3.scaleLinear()
    .domain([d3.min(data, d => d.y), d3.max(data, d => d.y)])
    .range([height - margin.bottom, margin.top]);

const line = d3.line()
    .x(d => xScale(d.x))
    .y(d => yScale(d.y));

// 绘制折线
svg.append("path")
    .datum(data)
    .attr("fill", "none")
    .attr("stroke", "#ff4565")
    .attr("stroke-width", 2)
    .attr("d", line);

// 添加不可见的悬停区域
const hoverArea = svg.append("rect")
    .attr("width", width)
    .attr("height", height)
    .attr("fill", "transparent")
    .style("cursor", "crosshair");

// 添加悬停点
const hoverDot = svg.append("circle")
    .attr("r", 4)
    .attr("fill", "#808080")
    .style("visibility", "hidden");

// 添加悬停事件
hoverArea.on("mousemove", function(event) {
    const mouseX = d3.pointer(event)[0];
    const mouseY = d3.pointer(event)[1];
    
    // 找到最近的数据点
    const xValue = xScale.invert(mouseX);
    const closestPoint = data.reduce((prev, curr) => {
        return (Math.abs(curr.x - xValue) < Math.abs(prev.x - xValue) ? curr : prev);
    });
    
    // 更新提示框和点的位置
    tooltip
        .style("visibility", "visible")
        .html(`x: ${closestPoint.x}<br>y: ${closestPoint.y}`)
        .style("left", (event.pageX + 10) + "px")
        .style("top", (event.pageY - 28) + "px");
    
    hoverDot
        .attr("cx", xScale(closestPoint.x))
        .attr("cy", yScale(closestPoint.y))
        .style("visibility", "visible");
})
.on("mouseout", function() {
    tooltip.style("visibility", "hidden");
    hoverDot.style("visibility", "hidden");
});

svg.append("g")
    .attr("transform", `translate(0,${height - margin.bottom})`)
    .call(d3.axisBottom(xScale));

svg.append("g")
    .attr("transform", `translate(${margin.left},0)`)
    .call(d3.axisLeft(yScale));
// X-axis label
svg.append("text")
    .attr("x", width / 2)
    .attr("y", height - 10)
    .attr("text-anchor", "middle")
    .style("font-size", "14px")
    .text("X-Axis");

// Y-axis label
svg.append("text")
    .attr("transform", "rotate(-90)")
    .attr("x", -height / 2)
    .attr("y", 15)
    .attr("text-anchor", "middle")
    .style("font-size", "14px")
    .text("Y-Axis");

// Plot title
svg.append("text")
    .attr("x", width / 2)
    .attr("y", 20)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .style("font-weight", "bold")
    .text("Plot of sin(x)");
