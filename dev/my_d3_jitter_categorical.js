const x = ['A','A','A','A','A','A','A','A','A','A','B','B','B','B','B','B','B','B','B','B','C','C','C','C','C','C','C','C','C','C','D','D','D','D','D','D','D','D','D','D','E','E','E','E','E','E','E','E','E','E'];
const y = [21.980494,17.404734,16.956063,21.242023,16.984955,16.641196,21.577952,18.691435,22.489806,17.415471,18.771295,20.483390,21.098698,20.935269,20.382914,19.540390,18.841566,20.960962,19.226335,20.843231,22.175412,15.501336,23.608960,18.735879,22.632916,23.103184,17.062184,20.353877,26.932520,19.570747,20.972565,20.661770,22.535804,22.181028,18.107099,19.123002,20.686441,19.883193,25.069949,20.877291,20.875035,18.324648,17.384995,21.588285,19.605472,21.298306,18.337051,21.791908,16.373027,23.133367];
const data = x.map((d, i) => ({ x: d, y: y[i] }));

const width = 800, height = 600;
    const margin = { 
        top: height * 0.1, 
        right: width * 0.05, 
        bottom: height * 0.15, 
        left: width * 0.1 
    };

const svg = d3.select("#my_d3_jitter_categorical_chart")
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
    .domain(d3.extent(data, d => d.y))
    .range([height - margin.bottom, margin.top]);

// 添加抖动效果
const jitterWidth = xIsNumeric ? 20 : xScale.bandwidth() * 0.3;
const jitterHeight = (yScale.domain()[1] - yScale.domain()[0]) * 0.02;

// 绘制抖动点
svg.selectAll("circle")
    .data(data)
    .enter()
    .append("circle")
    .attr("cx", d => {
        const baseX = xIsNumeric ? xScale(d.x) : xScale(d.x) + xScale.bandwidth()/2;
        return baseX + (Math.random() - 0.5) * jitterWidth;
    })
    .attr("cy", d => yScale(d.y) + (Math.random() - 0.5) * jitterHeight)
    .attr("r", 4)
    .attr("fill", "#ff4565")
    .attr("opacity", 0.6)
    .style("cursor", "pointer")
    .on("mouseover", function(event, d) {
        tooltip
            .style("visibility", "visible")
            .html(`x: ${d.x}<br>y: ${d.y}`)
            .style("left", (event.pageX + 10) + "px")
            .style("top", (event.pageY - 28) + "px");
        d3.select(this)
            .attr("fill", "#808080")
            .attr("opacity", 1);
    })
    .on("mouseout", function() {
        tooltip.style("visibility", "hidden");
        d3.select(this)
            .attr("fill", "#ff4565")
            .attr("opacity", 0.6);
    });

// 添加不可见的检测区域
svg.selectAll("circle")
    .data(data)
    .enter()
    .append("circle")
    .attr("cx", d => {
        const baseX = xIsNumeric ? xScale(d.x) : xScale(d.x) + xScale.bandwidth()/2;
        return baseX + (Math.random() - 0.5) * jitterWidth;
    })
    .attr("cy", d => yScale(d.y) + (Math.random() - 0.5) * jitterHeight)
    .attr("r", 20)
    .attr("fill", "transparent")
    .style("cursor", "pointer")
    .on("mouseover", function(event, d) {
        tooltip
            .style("visibility", "visible")
            .html(`x: ${d.x}<br>y: ${d.y}`)
            .style("left", (event.pageX + 10) + "px")
            .style("top", (event.pageY - 28) + "px");
        // 找到对应的可见点并改变其颜色
        svg.selectAll("circle")
            .filter(function() {
                return d3.select(this).attr("fill") === "#ff4565";
            })
            .filter(function() {
                const cx = d3.select(this).attr("cx");
                const cy = d3.select(this).attr("cy");
                return Math.abs(cx - d3.select(this.parentNode).select("circle[fill=transparent]").attr("cx")) < 0.1 &&
                       Math.abs(cy - d3.select(this.parentNode).select("circle[fill=transparent]").attr("cy")) < 0.1;
            })
            .attr("fill", "#808080")
            .attr("opacity", 1);
    })
    .on("mouseout", function() {
        tooltip.style("visibility", "hidden");
        // 恢复所有可见点的颜色
        svg.selectAll("circle")
            .filter(function() {
                return d3.select(this).attr("fill") === "#808080";
            })
            .attr("fill", "#ff4565")
            .attr("opacity", 0.6);
    });

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
    .text("Jitter Plot Example (Categorical)");
