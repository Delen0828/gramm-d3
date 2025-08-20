/**
 * SVG Coordinate Mapper
 * Maps SVG pixel coordinates to data values using axis information
 * Standalone utility with no external dependencies
 */

class CoordinateMapper {
    constructor(svg) {
        this.svg = svg;
        this.axisInfo = this.extractAxisInfo();
    }

    /**
     * Extract axis information from SVG text elements
     * @returns {Object} Axis information with scales and bounds
     */
    extractAxisInfo() {
        const textElements = this.svg.querySelectorAll('text');
        const xAxisTicks = [];
        const yAxisTicks = [];
        const plotBounds = this.estimatePlotBounds();
        
        // Parse text elements to find axis ticks
        textElements.forEach(text => {
            const content = text.textContent.trim();
            const x = parseFloat(text.getAttribute('x'));
            const y = parseFloat(text.getAttribute('y'));
            
            // Try to parse as number (axis tick)
            const numValue = parseFloat(content);
            if (!isNaN(numValue) && isFinite(numValue)) {
                // Determine if it's x-axis or y-axis based on position
                if (y > plotBounds.bottom - 50) { // Bottom area - likely x-axis
                    xAxisTicks.push({ value: numValue, svgX: x });
                } else if (x < plotBounds.left + 50) { // Left area - likely y-axis
                    yAxisTicks.push({ value: numValue, svgY: y });
                }
            }
        });
        
        // Sort ticks
        xAxisTicks.sort((a, b) => a.svgX - b.svgX);
        yAxisTicks.sort((a, b) => b.svgY - a.svgY); // Y is inverted in SVG
        
        return {
            xAxis: xAxisTicks,
            yAxis: yAxisTicks,
            plotBounds: plotBounds
        };
    }

    /**
     * Estimate plot bounds from SVG structure
     * @returns {Object} Plot area bounds
     */
    estimatePlotBounds() {
        const svgWidth = parseFloat(this.svg.getAttribute('width') || this.svg.viewBox?.baseVal?.width || 400);
        const svgHeight = parseFloat(this.svg.getAttribute('height') || this.svg.viewBox?.baseVal?.height || 300);
        
        // Default plot area (can be refined based on actual grid lines)
        return {
            left: svgWidth * 0.1,
            right: svgWidth * 0.9,
            top: svgHeight * 0.1,
            bottom: svgHeight * 0.9
        };
    }

    /**
     * Map SVG X coordinate to data value
     * @param {number} svgX - SVG x coordinate
     * @returns {number} Data value
     */
    mapSVGToDataX(svgX) {
        const { xAxis } = this.axisInfo;
        
        if (xAxis.length < 2) {
            // Fallback: linear interpolation based on plot bounds
            const { plotBounds } = this.axisInfo;
            return ((svgX - plotBounds.left) / (plotBounds.right - plotBounds.left)) * 10; // Assume 0-10 range
        }
        
        const firstTick = xAxis[0];
        const lastTick = xAxis[xAxis.length - 1];
        
        const svgRange = lastTick.svgX - firstTick.svgX;
        const dataRange = lastTick.value - firstTick.value;
        
        if (svgRange === 0) return firstTick.value;
        
        const ratio = (svgX - firstTick.svgX) / svgRange;
        return firstTick.value + (ratio * dataRange);
    }

    /**
     * Map SVG Y coordinate to data value
     * @param {number} svgY - SVG y coordinate
     * @returns {number} Data value
     */
    mapSVGToDataY(svgY) {
        const { yAxis } = this.axisInfo;
        
        if (yAxis.length < 2) {
            // Fallback: linear interpolation based on plot bounds
            const { plotBounds } = this.axisInfo;
            return ((plotBounds.bottom - svgY) / (plotBounds.bottom - plotBounds.top)) * 50; // Assume 0-50 range
        }
        
        const firstTick = yAxis[0]; // Top tick (highest value)
        const lastTick = yAxis[yAxis.length - 1]; // Bottom tick (lowest value)
        
        const svgRange = lastTick.svgY - firstTick.svgY;
        const dataRange = lastTick.value - firstTick.value;
        
        if (svgRange === 0) return firstTick.value;
        
        const ratio = (svgY - firstTick.svgY) / svgRange;
        return firstTick.value + (ratio * dataRange);
    }

    /**
     * Get axis labels from SVG
     * @returns {Object} Axis labels
     */
    getAxisLabels() {
        const textElements = this.svg.querySelectorAll('text');
        let xLabel = 'X';
        let yLabel = 'Y';
        
        // Look for potential axis labels (longer text, positioned at edges)
        textElements.forEach(text => {
            const content = text.textContent.trim();
            const x = parseFloat(text.getAttribute('x'));
            const y = parseFloat(text.getAttribute('y'));
            
            // Skip if it's a number (likely a tick)
            if (!isNaN(parseFloat(content))) return;
            
            // Look for text that might be axis labels
            if (content.length > 3) {
                if (y > this.axisInfo.plotBounds.bottom - 30) {
                    xLabel = content;
                } else if (x < this.axisInfo.plotBounds.left + 30) {
                    yLabel = content;
                }
            }
        });
        
        return { xLabel, yLabel };
    }

    /**
     * Get debug information about the mapping
     * @returns {Object} Debug info
     */
    getDebugInfo() {
        return {
            xAxisTicks: this.axisInfo.xAxis,
            yAxisTicks: this.axisInfo.yAxis,
            plotBounds: this.axisInfo.plotBounds,
            axisLabels: this.getAxisLabels()
        };
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CoordinateMapper;
} else if (typeof window !== 'undefined') {
    window.CoordinateMapper = CoordinateMapper;
}