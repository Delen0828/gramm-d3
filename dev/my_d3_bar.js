const x = [];
const y = [];
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

// 确定x轴类型
const xIsNumeric = data.every(d => !isNaN(d.x));
let xScale;
if (xIsNumeric) {
    xScale = d3.scaleLinear()
        .domain([d3.min(data, d => d.x) - (d3.max(data, d => d.x) - d3.min(data, d => d.x)) * 0.05, d3.max(data, d => d.x)])
        .range([margin.left, width - margin.right]);
} else {
    xScale = d3.scaleBand()
        .domain(data.map(d => d.x))
        .range([margin.left, width - margin.right])
        .padding(0.1);
}

const yScale = d3.scaleLinear()
    .domain([0, d3.max(data, d => d.y)])
    .range([height - margin.bottom, margin.top]);

// 绘制条形
svg.selectAll("rect")
    .data(data)
    .enter()
    .append("rect")
    .attr("x", d => xIsNumeric ? xScale(d.x) - 10 : xScale(d.x))
    .attr("y", d => yScale(d.y))
    .attr("width", xIsNumeric ? 20 : xScale.bandwidth())
    .attr("height", d => height - margin.bottom - yScale(d.y))
    .attr("fill", "#ff4565");

// 添加x轴
if (xIsNumeric) {
    svg.append("g")
        .attr("transform", `translate(0,${height - margin.bottom})`)
        .call(d3.axisBottom(xScale));
} else {
    svg.append("g")
        .attr("transform", `translate(0,${height - margin.bottom})`)
        .call(d3.axisBottom(xScale))
        .selectAll("text")
        .attr("transform", "rotate(-45)")
        .style("text-anchor", "end");
}

// 添加y轴
svg.append("g")
    .attr("transform", `translate(${margin.left},0)`)
    .call(d3.axisLeft(yScale));

// X-axis label
svg.append("text")
    .attr("x", width / 2)
    .attr("y", height - 10)
    .attr("text-anchor", "middle")
    .style("font-size", "14px")
    .text("Categories");

// Y-axis label
svg.append("text")
    .attr("transform", "rotate(-90)")
    .attr("x", -height / 2)
    .attr("y", 15)
    .attr("text-anchor", "middle")
    .style("font-size", "14px")
    .text("Values");

// Plot title
svg.append("text")
    .attr("x", width / 2)
    .attr("y", 20)
    .attr("text-anchor", "middle")
    .style("font-size", "16px")
    .style("font-weight", "bold")
    .text("Bar Chart Example");
