/**
 * SVG Interactive Library
 * Standalone library for making static SVG visualizations interactive
 * No external dependencies - pure JavaScript
 * Designed for MATLAB integration
 */

class SVGInteractive {
    constructor(svgElement, options = {}) {
        this.svg = svgElement;
        this.options = {
            tooltipFormat: options.tooltipFormat || this.defaultTooltipFormat.bind(this),
            onSelect: options.onSelect || (() => {}),
            onHover: options.onHover || (() => {}),
            enableMultiSelect: options.enableMultiSelect !== false,
            enableTooltips: options.enableTooltips !== false,
            enableDetailOnDemand: options.enableDetailOnDemand !== false,
            tooltipStyle: options.tooltipStyle || 'enhanced', // 'basic', 'enhanced', 'detailed'
            tooltipDelay: options.tooltipDelay || 300, // ms delay before showing
            showDataContext: options.showDataContext !== false,
            showStatistics: options.showStatistics !== false,
            selectionColor: options.selectionColor || '#ff6b35',
            hoverColor: options.hoverColor || '#2196f3',
            ...options
        };
        
        this.coordinateMapper = new CoordinateMapper(svgElement);
        this.dataPoints = [];
        this.selectedPoints = new Set();
        this.tooltip = null;
        
        this.init();
    }

    /**
     * Initialize the interactive features
     */
    init() {
        this.extractDataPoints();
        this.setupTooltip();
        this.addEventListeners();
        
        console.log(`SVG Interactive initialized with ${this.dataPoints.length} data points`);
    }

    /**
     * Extract data points from SVG elements
     */
    extractDataPoints() {
        let totalProcessed = 0;
        
        // Extract circles (scatter plots)
        const circles = this.svg.querySelectorAll('circle');
        circles.forEach((circle, index) => {
            this.processElement(circle, 'circle', totalProcessed + index);
        });
        totalProcessed += circles.length;

        // Extract rectangles (bar charts)
        const rects = this.svg.querySelectorAll('rect');
        rects.forEach((rect, index) => {
            // Skip background/grid rectangles
            if (this.isBackgroundElement(rect)) return;
            this.processElement(rect, 'rect', totalProcessed + index);
        });
        totalProcessed += rects.length;

        // Extract paths (lines, custom shapes)
        const paths = this.svg.querySelectorAll('path');
        paths.forEach((path, index) => {
            // Skip background/grid paths
            if (this.isBackgroundElement(path)) return;
            this.processElement(path, 'path', totalProcessed + index);
        });
        totalProcessed += paths.length;

        // Extract polylines (line charts, time series)
        const polylines = this.svg.querySelectorAll('polyline');
        polylines.forEach((polyline, index) => {
            // Skip background/grid polylines
            if (this.isBackgroundElement(polyline)) return;
            this.processElement(polyline, 'polyline', totalProcessed + index);
        });
    }

    /**
     * Check if element is likely a background/grid element
     * @param {Element} element - SVG element
     * @returns {boolean} True if background element
     */
    isBackgroundElement(element) {
        const style = window.getComputedStyle(element);
        const fill = style.fill;
        const stroke = style.stroke;
        const strokeWidth = style.strokeWidth;
        
        // Check for data attributes that indicate interactive content FIRST
        // If element has data attributes, it's definitely interactive regardless of appearance
        if (element.hasAttribute('data-id') || element.hasAttribute('title')) {
            return false; // Definitely not a background element
        }
        
        // Skip grid lines (usually have specific stroke colors)
        if (stroke === 'rgb(235, 235, 235)' || stroke === '#EBEBEB' || stroke === '#b0b0b0' || 
            stroke === 'rgb(176, 176, 176)' || stroke.includes('235, 235, 235') || stroke.includes('176, 176, 176')) {
            return true;
        }
        
        // For polylines specifically, check for additional grid characteristics
        if (element.tagName.toLowerCase() === 'polyline') {
            // Grid lines are usually straight horizontal or vertical lines
            const points = element.getAttribute('points');
            if (points) {
                const coords = points.trim().split(/\s+|,/);
                if (coords.length === 4) { // Only two points = straight line
                    const x1 = parseFloat(coords[0]);
                    const y1 = parseFloat(coords[1]);
                    const x2 = parseFloat(coords[2]);
                    const y2 = parseFloat(coords[3]);
                    
                    // Check if it's horizontal or vertical
                    if (Math.abs(x1 - x2) < 1 || Math.abs(y1 - y2) < 1) {
                        return true; // Likely a grid line
                    }
                }
            }
            
            // Grid lines often have thin stroke widths and neutral colors
            const strokeWidthNum = parseFloat(strokeWidth);
            if (strokeWidthNum <= 1.2 && (stroke.includes('235, 235, 235') || stroke.includes('176, 176, 176'))) {
                return true;
            }
        }
        
        // Skip white fills, transparent elements (but not for polylines which typically have fill=none)
        if (element.tagName.toLowerCase() !== 'polyline' && 
            (fill === 'rgb(255, 255, 255)' || fill === 'white')) {
            return true;
        }
        
        // Check size - very large elements are likely backgrounds
        try {
            const bbox = element.getBBox();
            const svgBbox = this.svg.getBBox();
            if (bbox.width > svgBbox.width * 0.8 || bbox.height > svgBbox.height * 0.8) {
                return true;
            }
        } catch (error) {
            // If getBBox fails, continue with other checks
        }
        
        return false;
    }

    /**
     * Process an SVG element to create a data point
     * @param {Element} element - SVG element
     * @param {string} type - Element type
     * @param {number} index - Element index
     */
    processElement(element, type, index) {
        let svgX, svgY, width, height, additionalData = {};
        
        // Extract coordinates based on element type
        switch (type) {
            case 'circle':
                svgX = parseFloat(element.getAttribute('cx'));
                svgY = parseFloat(element.getAttribute('cy'));
                width = height = parseFloat(element.getAttribute('r')) * 2;
                break;
            case 'rect':
                svgX = parseFloat(element.getAttribute('x')) + parseFloat(element.getAttribute('width')) / 2;
                svgY = parseFloat(element.getAttribute('y')) + parseFloat(element.getAttribute('height')) / 2;
                width = parseFloat(element.getAttribute('width'));
                height = parseFloat(element.getAttribute('height'));
                break;
            case 'path':
                // For paths, use the center of bounding box
                const bbox = element.getBBox();
                svgX = bbox.x + bbox.width / 2;
                svgY = bbox.y + bbox.height / 2;
                width = bbox.width;
                height = bbox.height;
                break;
            case 'polyline':
                // For polylines, extract points and use centroid or meaningful points
                const points = element.getAttribute('points');
                if (points) {
                    const coords = this.parsePolylinePoints(points);
                    if (coords.length > 0) {
                        // Use centroid of the polyline for main coordinates
                        const centroid = this.calculateCentroid(coords);
                        svgX = centroid.x;
                        svgY = centroid.y;
                        
                        // Calculate bounding box
                        const minX = Math.min(...coords.map(p => p.x));
                        const maxX = Math.max(...coords.map(p => p.x));
                        const minY = Math.min(...coords.map(p => p.y));
                        const maxY = Math.max(...coords.map(p => p.y));
                        
                        width = maxX - minX;
                        height = maxY - minY;
                        
                        // Store additional data for polylines
                        additionalData.points = coords;
                        additionalData.startPoint = coords[0];
                        additionalData.endPoint = coords[coords.length - 1];
                        additionalData.pointCount = coords.length;
                    } else {
                        return; // Skip if no valid points
                    }
                } else {
                    return; // Skip if no points attribute
                }
                break;
            default:
                return; // Skip unsupported elements
        }
        
        // Convert to data coordinates
        const dataX = this.coordinateMapper.mapSVGToDataX(svgX);
        const dataY = this.coordinateMapper.mapSVGToDataY(svgY);
        
        const dataPoint = {
            id: index,
            element: element,
            type: type,
            svgX: svgX,
            svgY: svgY,
            dataX: dataX,
            dataY: dataY,
            width: width,
            height: height,
            originalStyle: {
                fill: element.style.fill || window.getComputedStyle(element).fill,
                stroke: element.style.stroke || window.getComputedStyle(element).stroke,
                strokeWidth: element.style.strokeWidth || window.getComputedStyle(element).strokeWidth
            },
            ...additionalData
        };
        
        this.dataPoints.push(dataPoint);
    }

    /**
     * Parse polyline points string into coordinate array
     * @param {string} pointsStr - Points attribute string
     * @returns {Array} Array of {x, y} coordinates
     */
    parsePolylinePoints(pointsStr) {
        try {
            const coords = [];
            const points = pointsStr.trim().split(/[\s,]+/);
            
            for (let i = 0; i < points.length; i += 2) {
                if (i + 1 < points.length) {
                    const x = parseFloat(points[i]);
                    const y = parseFloat(points[i + 1]);
                    
                    if (!isNaN(x) && !isNaN(y)) {
                        coords.push({ x, y });
                    }
                }
            }
            
            return coords;
        } catch (error) {
            console.warn('Error parsing polyline points:', error);
            return [];
        }
    }

    /**
     * Calculate centroid of polyline points
     * @param {Array} coords - Array of {x, y} coordinates
     * @returns {Object} Centroid {x, y}
     */
    calculateCentroid(coords) {
        if (coords.length === 0) return { x: 0, y: 0 };
        
        const sum = coords.reduce((acc, point) => ({
            x: acc.x + point.x,
            y: acc.y + point.y
        }), { x: 0, y: 0 });
        
        return {
            x: sum.x / coords.length,
            y: sum.y / coords.length
        };
    }

    /**
     * Setup tooltip element
     */
    setupTooltip() {
        if (!this.options.enableTooltips && !this.options.enableDetailOnDemand) return;
        
        this.tooltip = document.createElement('div');
        this.tooltip.className = 'svg-interactive-tooltip';
        
        // Enhanced styling based on tooltip style
        const baseStyle = `
            position: absolute;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            pointer-events: none;
            z-index: 10000;
            opacity: 0;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
            border-radius: 8px;
            backdrop-filter: blur(10px);
            word-wrap: break-word;
            line-height: 1.4;
        `;
        
        let styleVariant = '';
        switch (this.options.tooltipStyle) {
            case 'basic':
                styleVariant = `
                    background: rgba(0, 0, 0, 0.9);
                    color: white;
                    padding: 8px 12px;
                    font-size: 12px;
                    max-width: 200px;
                `;
                break;
            case 'enhanced':
                styleVariant = `
                    background: rgba(255, 255, 255, 0.95);
                    color: #333;
                    padding: 12px 16px;
                    font-size: 13px;
                    max-width: 280px;
                    border: 1px solid rgba(0, 0, 0, 0.1);
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                `;
                break;
            case 'detailed':
                styleVariant = `
                    background: linear-gradient(135deg, rgba(255, 255, 255, 0.98), rgba(248, 249, 250, 0.98));
                    color: #2c3e50;
                    padding: 16px 20px;
                    font-size: 14px;
                    max-width: 350px;
                    border: 1px solid rgba(52, 152, 219, 0.2);
                    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.12);
                `;
                break;
        }
        
        this.tooltip.style.cssText = baseStyle + styleVariant;
        document.body.appendChild(this.tooltip);
        
        // Add tooltip hover delay timer
        this.tooltipTimer = null;
    }

    /**
     * Add event listeners to data points
     */
    addEventListeners() {
        this.dataPoints.forEach(point => {
            const element = point.element;
            
            // Make element interactive
            element.style.cursor = 'pointer';
            
            // Mouse enter (hover start)
            element.addEventListener('mouseenter', (event) => {
                this.handleMouseEnter(event, point);
            });
            
            // Mouse move (tooltip positioning)
            element.addEventListener('mousemove', (event) => {
                this.handleMouseMove(event, point);
            });
            
            // Mouse leave (hover end)
            element.addEventListener('mouseleave', (event) => {
                this.handleMouseLeave(event, point);
            });
            
            // Click (selection)
            element.addEventListener('click', (event) => {
                this.handleClick(event, point);
            });
        });
    }

    /**
     * Handle mouse enter event
     * @param {Event} event - Mouse event
     * @param {Object} point - Data point
     */
    handleMouseEnter(event, point) {
        // Apply hover styling immediately
        this.applyHoverStyle(point);
        
        // Show tooltip with delay
        if ((this.options.enableTooltips || this.options.enableDetailOnDemand) && this.tooltip) {
            // Clear any existing timer
            if (this.tooltipTimer) {
                clearTimeout(this.tooltipTimer);
            }
            
            // Set delay before showing tooltip
            this.tooltipTimer = setTimeout(() => {
                const content = this.options.tooltipFormat(point, this.getDataContext(point));
                this.tooltip.innerHTML = content;
                this.showTooltip();
            }, this.options.tooltipDelay);
        }
        
        // Call user callback
        this.options.onHover(point, 'enter');
    }

    /**
     * Handle mouse move event
     * @param {Event} event - Mouse event
     * @param {Object} point - Data point
     */
    handleMouseMove(event, point) {
        if (this.tooltip && this.options.enableTooltips) {
            this.tooltip.style.left = (event.pageX + 10) + 'px';
            this.tooltip.style.top = (event.pageY - 10) + 'px';
        }
    }

    /**
     * Handle mouse leave event
     * @param {Event} event - Mouse event
     * @param {Object} point - Data point
     */
    handleMouseLeave(event, point) {
        // Remove hover styling (if not selected)
        if (!this.selectedPoints.has(point.id)) {
            this.resetStyle(point);
        }
        
        // Clear tooltip timer and hide tooltip
        if (this.tooltipTimer) {
            clearTimeout(this.tooltipTimer);
            this.tooltipTimer = null;
        }
        
        if (this.tooltip) {
            this.hideTooltip();
        }
        
        // Call user callback
        this.options.onHover(point, 'leave');
    }

    /**
     * Handle click event
     * @param {Event} event - Mouse event
     * @param {Object} point - Data point
     */
    handleClick(event, point) {
        const isMultiSelect = this.options.enableMultiSelect && (event.ctrlKey || event.metaKey);
        
        // Handle selection
        if (this.selectedPoints.has(point.id)) {
            // Deselect
            this.selectedPoints.delete(point.id);
            this.resetStyle(point);
        } else {
            // Select
            if (!isMultiSelect) {
                // Clear other selections
                this.clearSelection();
            }
            this.selectedPoints.add(point.id);
            this.applySelectionStyle(point);
        }
        
        // Get selected points data
        const selectedData = this.getSelectedData();
        
        // Call user callback
        this.options.onSelect(selectedData, point);
    }

    /**
     * Apply hover styling to element
     * @param {Object} point - Data point
     */
    applyHoverStyle(point) {
        const element = point.element;
        
        if (point.type === 'polyline') {
            // For polylines, keep original color and just enhance visibility
            element.style.strokeWidth = '2.5px'; // Slightly thicker
            element.style.filter = 'drop-shadow(1px 1px 3px rgba(0,0,0,0.4))'; // Subtle highlight
            // Keep original stroke color
        } else {
            // For other elements, apply blue hover color
            element.style.stroke = this.options.hoverColor;
            element.style.strokeWidth = '2px';
            element.style.filter = 'drop-shadow(2px 2px 4px rgba(0,0,0,0.3))';
        }
    }

    /**
     * Apply selection styling to element
     * @param {Object} point - Data point
     */
    applySelectionStyle(point) {
        const element = point.element;
        
        if (point.type === 'polyline') {
            // For polylines (line charts), only enhance the stroke without changing color
            element.style.strokeWidth = '3px'; // Make line thicker
            element.style.filter = 'drop-shadow(0 0 4px rgba(0,0,0,0.3))'; // Subtle shadow
            // Keep original stroke color, don't change to orange
        } else {
            // For other elements (circles, rects), apply the original orange selection
            element.style.fill = this.options.selectionColor;
            element.style.stroke = this.options.selectionColor;
            element.style.strokeWidth = '2px';
            element.style.filter = 'drop-shadow(0 0 8px ' + this.options.selectionColor + ')';
        }
    }

    /**
     * Reset element styling
     * @param {Object} point - Data point
     */
    resetStyle(point) {
        const element = point.element;
        const original = point.originalStyle;
        element.style.fill = original.fill;
        element.style.stroke = original.stroke;
        element.style.strokeWidth = original.strokeWidth;
        element.style.filter = '';
    }

    /**
     * Clear all selections
     */
    clearSelection() {
        this.selectedPoints.forEach(id => {
            const point = this.dataPoints.find(p => p.id === id);
            if (point) {
                this.resetStyle(point);
            }
        });
        this.selectedPoints.clear();
    }

    /**
     * Get selected data points
     * @returns {Array} Array of selected data points
     */
    getSelectedData() {
        return this.dataPoints.filter(point => this.selectedPoints.has(point.id));
    }

    /**
     * Show tooltip with animation
     */
    showTooltip() {
        if (this.tooltip) {
            this.tooltip.style.opacity = '1';
            this.tooltip.style.transform = 'translateY(0) scale(1)';
        }
    }
    
    /**
     * Hide tooltip with animation
     */
    hideTooltip() {
        if (this.tooltip) {
            this.tooltip.style.opacity = '0';
            this.tooltip.style.transform = 'translateY(-5px) scale(0.95)';
        }
    }
    
    /**
     * Get data context for enhanced tooltips
     * @param {Object} point - Data point
     * @returns {Object} Context information
     */
    getDataContext(point) {
        if (!this.options.showDataContext && !this.options.showStatistics) {
            return {};
        }
        
        const allPoints = this.dataPoints;
        const xValues = allPoints.map(p => p.dataX);
        const yValues = allPoints.map(p => p.dataY);
        
        // Calculate statistics
        const xStats = this.calculateStats(xValues);
        const yStats = this.calculateStats(yValues);
        
        // Find nearest neighbors
        const neighbors = this.findNearestNeighbors(point, 3);
        
        // Calculate percentiles
        const xPercentile = this.calculatePercentile(point.dataX, xValues);
        const yPercentile = this.calculatePercentile(point.dataY, yValues);
        
        return {
            stats: { x: xStats, y: yStats },
            neighbors: neighbors,
            percentiles: { x: xPercentile, y: yPercentile },
            totalPoints: allPoints.length,
            selectedCount: this.selectedPoints.size
        };
    }
    
    /**
     * Calculate basic statistics for a dataset
     * @param {Array} values - Numeric values
     * @returns {Object} Statistics
     */
    calculateStats(values) {
        const sorted = [...values].sort((a, b) => a - b);
        const sum = values.reduce((a, b) => a + b, 0);
        const mean = sum / values.length;
        
        return {
            min: Math.min(...values),
            max: Math.max(...values),
            mean: mean,
            median: sorted[Math.floor(sorted.length / 2)],
            count: values.length
        };
    }
    
    /**
     * Calculate percentile rank of a value
     * @param {number} value - Value to rank
     * @param {Array} dataset - All values
     * @returns {number} Percentile (0-100)
     */
    calculatePercentile(value, dataset) {
        const sorted = [...dataset].sort((a, b) => a - b);
        const index = sorted.findIndex(v => v >= value);
        return Math.round((index / sorted.length) * 100);
    }
    
    /**
     * Find nearest neighbors to a point
     * @param {Object} point - Target point
     * @param {number} count - Number of neighbors to find
     * @returns {Array} Nearest neighbor points
     */
    findNearestNeighbors(point, count = 3) {
        const distances = this.dataPoints
            .filter(p => p.id !== point.id)
            .map(p => ({
                point: p,
                distance: Math.sqrt(
                    Math.pow(p.dataX - point.dataX, 2) + 
                    Math.pow(p.dataY - point.dataY, 2)
                )
            }))
            .sort((a, b) => a.distance - b.distance)
            .slice(0, count);
        
        return distances.map(d => d.point);
    }
    
    /**
     * Default tooltip format function
     * @param {Object} point - Data point
     * @param {Object} context - Data context
     * @returns {string} Tooltip HTML content
     */
    defaultTooltipFormat(point, context = {}) {
        const labels = this.coordinateMapper.getAxisLabels();
        
        // Get element-specific info
        let elementInfo = '';
        let dataInfo = '';
        
        if (point.type === 'polyline') {
            elementInfo = `${point.pointCount || 0} data points`;
            dataInfo = point.element.getAttribute('data-id') || point.element.getAttribute('title') || 'Time series';
        } else {
            elementInfo = `${point.type} element`;
            dataInfo = `Point ${point.id}`;
        }
        
        switch (this.options.tooltipStyle) {
            case 'basic':
                if (point.type === 'polyline') {
                    return `
                        <strong>${dataInfo}</strong><br>
                        <small>Time series with ${elementInfo}</small><br>
                        Author: ${point.element.getAttribute('title') || 'Unknown'}
                    `;
                } else {
                    return `
                        <strong>${dataInfo}</strong><br>
                        ${labels.xLabel}: ${point.dataX.toFixed(2)}<br>
                        ${labels.yLabel}: ${point.dataY.toFixed(2)}
                    `;
                }
                
            case 'enhanced':
                if (point.type === 'polyline') {
                    return `
                        <div style="border-bottom: 1px solid #eee; padding-bottom: 8px; margin-bottom: 8px;">
                            <strong style="color: #2c3e50; font-size: 14px;">${dataInfo}</strong>
                            <div style="font-size: 10px; color: #7f8c8d;">${elementInfo}</div>
                        </div>
                        <div style="font-size: 12px;">
                            <div style="margin-bottom: 6px;"><strong>Author:</strong> <span style="color: #3498db;">${point.element.getAttribute('title') || 'Unknown'}</span></div>
                            <div style="margin-bottom: 6px;"><strong>Species:</strong> <span style="color: #e74c3c;">${point.element.getAttribute('data-id') || 'Unknown'}</span></div>
                            <div><strong>Data Range:</strong> <span style="color: #27ae60;">${labels.xLabel} time series</span></div>
                        </div>
                        ${context.stats ? `
                            <div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid #eee; font-size: 11px; color: #7f8c8d;">
                                Dataset: ${context.totalPoints || 'N/A'} series total
                            </div>
                        ` : ''}
                    `;
                } else {
                    return `
                        <div style="border-bottom: 1px solid #eee; padding-bottom: 8px; margin-bottom: 8px;">
                            <strong style="color: #2c3e50; font-size: 14px;">${dataInfo}</strong>
                        </div>
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; font-size: 12px;">
                            <div><strong>${labels.xLabel}:</strong><br><span style="color: #3498db;">${point.dataX.toFixed(3)}</span></div>
                            <div><strong>${labels.yLabel}:</strong><br><span style="color: #e74c3c;">${point.dataY.toFixed(3)}</span></div>
                        </div>
                        ${context.percentiles ? `
                            <div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid #eee; font-size: 11px; color: #7f8c8d;">
                                Percentiles: ${context.percentiles.x}th (X), ${context.percentiles.y}th (Y)
                            </div>
                        ` : ''}
                    `;
                }
                
            case 'detailed':
                if (point.type === 'polyline') {
                    return `
                        <div style="border-bottom: 2px solid #3498db; padding-bottom: 10px; margin-bottom: 12px;">
                            <h4 style="margin: 0; color: #2c3e50; font-size: 16px;">📈 ${dataInfo}</h4>
                            <div style="font-size: 11px; color: #7f8c8d; margin-top: 2px;">
                                Time series with ${elementInfo}
                            </div>
                        </div>
                        
                        <div style="background: #f8f9fa; padding: 12px; border-radius: 8px; margin-bottom: 12px;">
                            <div style="font-weight: bold; color: #2c3e50; font-size: 14px; margin-bottom: 8px;">📋 Legend Information</div>
                            <div style="display: grid; grid-template-columns: 1fr; gap: 8px;">
                                <div style="background: #fff; padding: 8px; border-radius: 4px; border-left: 4px solid #3498db;">
                                    <div style="font-weight: bold; color: #3498db; font-size: 12px;">Species</div>
                                    <div style="font-size: 14px; color: #2c3e50;">${point.element.getAttribute('data-id') || 'Unknown'}</div>
                                </div>
                                <div style="background: #fff; padding: 8px; border-radius: 4px; border-left: 4px solid #e74c3c;">
                                    <div style="font-weight: bold; color: #e74c3c; font-size: 12px;">Author</div>
                                    <div style="font-size: 14px; color: #2c3e50;">${point.element.getAttribute('title') || 'Unknown'}</div>
                                </div>
                                <div style="background: #fff; padding: 8px; border-radius: 4px; border-left: 4px solid #27ae60;">
                                    <div style="font-weight: bold; color: #27ae60; font-size: 12px;">Data Type</div>
                                    <div style="font-size: 14px; color: #2c3e50;">${labels.xLabel} vs ${labels.yLabel} time series</div>
                                </div>
                            </div>
                        </div>
                        
                        <div style="background: #e8f5e8; padding: 8px; border-radius: 4px; margin-bottom: 8px;">
                            <div style="font-weight: bold; font-size: 11px; color: #27ae60; margin-bottom: 4px;">📊 Series Statistics</div>
                            <div style="font-size: 10px; color: #2c3e50; line-height: 1.3;">
                                Data points: ${point.pointCount || 'N/A'}<br>
                                Line color: ${window.getComputedStyle(point.element).stroke}<br>
                                Series ID: #${point.id}
                            </div>
                        </div>
                        
                        ${context.stats ? `
                            <div style="background: #fff3cd; padding: 8px; border-radius: 4px; margin-bottom: 8px;">
                                <div style="font-weight: bold; font-size: 11px; color: #856404; margin-bottom: 4px;">📈 Dataset Overview</div>
                                <div style="font-size: 10px; color: #856404; line-height: 1.3;">
                                    Total data series: ${context.totalPoints || 'N/A'}<br>
                                    Selected series: ${context.selectedCount || 0}
                                </div>
                            </div>
                        ` : ''}
                        
                        <div style="text-align: center; font-size: 9px; color: #bdc3c7; margin-top: 8px;">
                            Hover over different lines to explore the dataset
                        </div>
                    `;
                } else {
                    return `
                        <div style="border-bottom: 2px solid #3498db; padding-bottom: 10px; margin-bottom: 12px;">
                            <h4 style="margin: 0; color: #2c3e50; font-size: 16px;">📊 ${dataInfo}</h4>
                            <div style="font-size: 11px; color: #7f8c8d; margin-top: 2px;">
                                ${elementInfo}
                            </div>
                        </div>
                        
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px;">
                            <div style="background: #ecf0f1; padding: 8px; border-radius: 4px;">
                                <div style="font-weight: bold; color: #3498db; font-size: 12px;">${labels.xLabel}</div>
                                <div style="font-size: 14px; color: #2c3e50;">${point.dataX.toFixed(3)}</div>
                                ${context.percentiles ? `<div style="font-size: 10px; color: #7f8c8d;">${context.percentiles.x}th percentile</div>` : ''}
                            </div>
                            <div style="background: #ecf0f1; padding: 8px; border-radius: 4px;">
                                <div style="font-weight: bold; color: #e74c3c; font-size: 12px;">${labels.yLabel}</div>
                                <div style="font-size: 14px; color: #2c3e50;">${point.dataY.toFixed(3)}</div>
                                ${context.percentiles ? `<div style="font-size: 10px; color: #7f8c8d;">${context.percentiles.y}th percentile</div>` : ''}
                            </div>
                        </div>
                        
                        ${context.stats ? `
                            <div style="background: #f8f9fa; padding: 8px; border-radius: 4px; margin-bottom: 8px;">
                                <div style="font-weight: bold; font-size: 11px; color: #2c3e50; margin-bottom: 4px;">📈 Dataset Overview</div>
                                <div style="font-size: 10px; color: #7f8c8d; line-height: 1.3;">
                                    ${labels.xLabel}: ${context.stats.x.min.toFixed(2)} - ${context.stats.x.max.toFixed(2)} (μ: ${context.stats.x.mean.toFixed(2)})<br>
                                    ${labels.yLabel}: ${context.stats.y.min.toFixed(2)} - ${context.stats.y.max.toFixed(2)} (μ: ${context.stats.y.mean.toFixed(2)})
                                </div>
                            </div>
                        ` : ''}
                        
                        ${context.neighbors && context.neighbors.length > 0 ? `
                            <div style="background: #f1c40f; background: linear-gradient(45deg, #f39c12, #f1c40f); color: white; padding: 6px 8px; border-radius: 4px; margin-bottom: 8px;">
                                <div style="font-weight: bold; font-size: 10px; margin-bottom: 2px;">🎯 Nearest Neighbors</div>
                                <div style="font-size: 9px;">
                                    ${context.neighbors.slice(0, 2).map(n => 
                                        `${n.type === 'polyline' ? 'Line' : 'Point'} ${n.id}: (${n.dataX.toFixed(1)}, ${n.dataY.toFixed(1)})`
                                    ).join('<br>')}
                                </div>
                            </div>
                        ` : ''}
                        
                        <div style="text-align: center; font-size: 9px; color: #bdc3c7; margin-top: 8px;">
                            ${context.selectedCount || 0} of ${context.totalPoints || 0} points selected
                        </div>
                    `;
                }
                
            default:
                return this.defaultTooltipFormat(point, context);
        }
    }

    /**
     * Get all data points
     * @returns {Array} Array of all data points
     */
    getDataPoints() {
        return this.dataPoints;
    }

    /**
     * Select points programmatically
     * @param {Array} pointIds - Array of point IDs to select
     */
    selectPoints(pointIds) {
        this.clearSelection();
        pointIds.forEach(id => {
            const point = this.dataPoints.find(p => p.id === id);
            if (point) {
                this.selectedPoints.add(id);
                this.applySelectionStyle(point);
            }
        });
    }

    /**
     * Export data as JSON
     * @returns {Object} Data and selection information
     */
    exportData() {
        return {
            dataPoints: this.dataPoints.map(point => ({
                id: point.id,
                type: point.type,
                dataX: point.dataX,
                dataY: point.dataY,
                svgX: point.svgX,
                svgY: point.svgY
            })),
            selectedPoints: Array.from(this.selectedPoints),
            axisLabels: this.coordinateMapper.getAxisLabels(),
            axisInfo: this.coordinateMapper.getDebugInfo()
        };
    }

    /**
     * Destroy the interactive instance
     */
    destroy() {
        // Remove tooltip
        if (this.tooltip && this.tooltip.parentNode) {
            this.tooltip.parentNode.removeChild(this.tooltip);
        }
        
        // Reset all styles
        this.dataPoints.forEach(point => {
            this.resetStyle(point);
            point.element.style.cursor = '';
        });
        
        // Clear data
        this.dataPoints = [];
        this.selectedPoints.clear();
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SVGInteractive;
} else if (typeof window !== 'undefined') {
    window.SVGInteractive = SVGInteractive;
}