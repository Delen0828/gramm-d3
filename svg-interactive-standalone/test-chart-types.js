/**
 * Test Script for SVG Interactive Chart Types
 * Tests tooltip functionality across different chart types
 */

console.log('🎯 Starting Chart Types Test...');

// Test configuration
const testConfig = {
    charts: [
        { file: 'r4-1.svg', name: 'Scatter Plot 1', expectedElements: 'circles' },
        { file: 'r4-2.svg', name: 'Scatter Plot 2', expectedElements: 'circles' },
        { file: 'line-chart.svg', name: 'Line Chart', expectedElements: 'polylines' },
        { file: 'bars.svg', name: 'Bar Chart', expectedElements: 'rectangles' }
    ],
    tooltipStyles: ['basic', 'enhanced', 'detailed']
};

// Test results
const testResults = {
    chartsLoaded: 0,
    totalInteractiveElements: 0,
    tooltipTests: [],
    errors: []
};

async function loadAndTestChart(chartConfig) {
    try {
        console.log(`📊 Testing ${chartConfig.name}...`);
        
        // Fetch SVG content
        const response = await fetch(`examples/${chartConfig.file}`);
        const svgText = await response.text();
        
        // Create temporary container
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = svgText;
        const svg = tempDiv.querySelector('svg');
        
        if (!svg) {
            throw new Error('SVG not found in content');
        }
        
        // Initialize interactive features
        const interactive = new SVGInteractive(svg, {
            tooltipStyle: 'enhanced',
            enableDetailOnDemand: true,
            showDataContext: true,
            showStatistics: true,
            onSelect: (selectedData, point) => {
                console.log(`✅ ${chartConfig.name}: Selected ${point.type} #${point.id}`);
            },
            onHover: (point, action) => {
                if (action === 'enter') {
                    console.log(`👆 ${chartConfig.name}: Hovering ${point.type} #${point.id}`);
                }
            }
        });
        
        const dataPoints = interactive.getDataPoints();
        const elementCount = dataPoints.length;
        
        // Test coordinate mapping
        const coordinateMapper = interactive.coordinateMapper;
        const debugInfo = coordinateMapper.getDebugInfo();
        
        console.log(`✅ ${chartConfig.name}: ${elementCount} interactive elements found`);
        console.log(`   Axis ticks: X=${debugInfo.xAxisTicks.length}, Y=${debugInfo.yAxisTicks.length}`);
        
        // Test different tooltip styles
        for (const style of testConfig.tooltipStyles) {
            interactive.options.tooltipStyle = style;
            
            if (dataPoints.length > 0) {
                const testPoint = dataPoints[0];
                const context = interactive.getDataContext(testPoint);
                const tooltipContent = interactive.defaultTooltipFormat(testPoint, context);
                
                console.log(`📋 ${chartConfig.name} - ${style} tooltip: ${tooltipContent.length} chars`);
                
                testResults.tooltipTests.push({
                    chart: chartConfig.name,
                    style: style,
                    contentLength: tooltipContent.length,
                    hasContext: Object.keys(context).length > 0
                });
            }
        }
        
        // Test element types
        const elementTypes = {};
        dataPoints.forEach(point => {
            elementTypes[point.type] = (elementTypes[point.type] || 0) + 1;
        });
        
        console.log(`   Element types:`, elementTypes);
        
        // Update test results
        testResults.chartsLoaded++;
        testResults.totalInteractiveElements += elementCount;
        
        // Cleanup
        interactive.destroy();
        
        return {
            success: true,
            chartName: chartConfig.name,
            elementCount: elementCount,
            elementTypes: elementTypes,
            axisInfo: debugInfo
        };
        
    } catch (error) {
        console.error(`❌ Error testing ${chartConfig.name}:`, error);
        testResults.errors.push({
            chart: chartConfig.name,
            error: error.message
        });
        
        return {
            success: false,
            chartName: chartConfig.name,
            error: error.message
        };
    }
}

async function runAllTests() {
    console.log('🚀 Running comprehensive chart type tests...');
    
    const results = [];
    
    for (const chartConfig of testConfig.charts) {
        const result = await loadAndTestChart(chartConfig);
        results.push(result);
        
        // Small delay between tests
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    // Print summary
    console.log('\n📊 Test Summary:');
    console.log(`Charts successfully loaded: ${testResults.chartsLoaded}/${testConfig.charts.length}`);
    console.log(`Total interactive elements: ${testResults.totalInteractiveElements}`);
    console.log(`Tooltip tests completed: ${testResults.tooltipTests.length}`);
    
    if (testResults.errors.length > 0) {
        console.log(`\n❌ Errors encountered:`);
        testResults.errors.forEach(error => {
            console.log(`   ${error.chart}: ${error.error}`);
        });
    }
    
    console.log('\n📋 Tooltip Test Results:');
    testResults.tooltipTests.forEach(test => {
        console.log(`   ${test.chart} (${test.style}): ${test.contentLength} chars, context: ${test.hasContext}`);
    });
    
    return results;
}

// Export for use in browser console
if (typeof window !== 'undefined') {
    window.chartTypeTests = {
        runAllTests,
        loadAndTestChart,
        testConfig,
        testResults
    };
    
    console.log('📝 Chart type tests loaded. Run window.chartTypeTests.runAllTests() to start testing.');
}

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        runAllTests,
        loadAndTestChart,
        testConfig,
        testResults
    };
}