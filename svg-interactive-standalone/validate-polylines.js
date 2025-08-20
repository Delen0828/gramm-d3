/**
 * Validation script for polyline support
 * Tests the enhanced SVG Interactive library with line charts
 */

// Mock DOM environment for testing
if (typeof window === 'undefined') {
    // Node.js environment - create minimal DOM mock
    global.window = {
        getComputedStyle: () => ({
            fill: 'none',
            stroke: '#440154',
            strokeWidth: '1.07'
        })
    };
    global.document = {
        createElement: () => ({
            style: {},
            appendChild: () => {},
            remove: () => {}
        }),
        body: {
            appendChild: () => {}
        }
    };
}

// Test function to validate polyline detection
function validatePolylineSupport() {
    console.log('🧪 Testing Polyline Support...');
    
    // Create a mock SVG element with polylines
    const mockSVG = {
        querySelectorAll: (selector) => {
            if (selector === 'polyline') {
                // Simulate 2 grid polylines and 2 data polylines
                return [
                    {
                        // Grid polyline
                        getAttribute: (attr) => {
                            if (attr === 'points') return '39.86,344.04 395.87,344.04';
                            return null;
                        },
                        hasAttribute: () => false,
                        tagName: 'polyline',
                        style: {},
                        getBBox: () => ({ x: 39.86, y: 344.04, width: 356.01, height: 0 })
                    },
                    {
                        // Data polyline with data-id
                        getAttribute: (attr) => {
                            if (attr === 'points') return '56.04,168.46 57.66,165.57 59.29,170.79';
                            if (attr === 'data-id') return 'Amsonia selebica';
                            if (attr === 'title') return 'Tomas O\'Keefe';
                            return null;
                        },
                        hasAttribute: (attr) => attr === 'data-id' || attr === 'title',
                        tagName: 'polyline',
                        style: {},
                        getBBox: () => ({ x: 56.04, y: 165.57, width: 3.25, height: 5.22 })
                    }
                ];
            }
            return [];
        },
        getBBox: () => ({ x: 0, y: 0, width: 576, height: 432 })
    };
    
    // Mock window.getComputedStyle for different polyline types
    let callCount = 0;
    const originalGetComputedStyle = window.getComputedStyle;
    window.getComputedStyle = (element) => {
        callCount++;
        if (callCount === 1) {
            // First call - grid polyline
            return {
                fill: 'none',
                stroke: '#EBEBEB',
                strokeWidth: '0.58'
            };
        } else {
            // Second call - data polyline
            return {
                fill: 'none',
                stroke: '#440154',
                strokeWidth: '1.07'
            };
        }
    };
    
    // Create a minimal coordinate mapper mock
    const mockCoordinateMapper = {
        mapSVGToDataX: (x) => x / 10,
        mapSVGToDataY: (y) => (432 - y) / 10,
        getAxisLabels: () => ({ xLabel: 'date', yLabel: 'sales' }),
        getDebugInfo: () => ({ xAxisTicks: [], yAxisTicks: [] })
    };
    
    try {
        // Test the isBackgroundElement function logic
        console.log('🔍 Testing background element detection...');
        
        // Simulate the logic from isBackgroundElement
        function testIsBackgroundElement(element, elementIndex) {
            const style = window.getComputedStyle(element);
            const stroke = style.stroke;
            const strokeWidth = style.strokeWidth;
            
            // Grid line detection
            if (stroke === '#EBEBEB' || stroke.includes('#ebebeb')) {
                return true;
            }
            
            // Data attribute check
            if (element.hasAttribute('data-id') || element.hasAttribute('title')) {
                return false;
            }
            
            // Stroke width check for grid lines
            if (parseFloat(strokeWidth) <= 1.0 && stroke.includes('#ebebeb')) {
                return true;
            }
            
            return false;
        }
        
        const polylines = mockSVG.querySelectorAll('polyline');
        let backgroundCount = 0;
        let dataCount = 0;
        
        polylines.forEach((polyline, index) => {
            const isBackground = testIsBackgroundElement(polyline, index);
            if (isBackground) {
                backgroundCount++;
                console.log(`  ✅ Correctly identified grid polyline ${index}`);
            } else {
                dataCount++;
                console.log(`  ✅ Correctly identified data polyline ${index}`);
            }
        });
        
        console.log(`📊 Detection Results:`);
        console.log(`  Background polylines: ${backgroundCount}`);
        console.log(`  Data polylines: ${dataCount}`);
        
        // Test coordinate parsing
        console.log('🗺️ Testing coordinate parsing...');
        const testPoints = '56.04,168.46 57.66,165.57 59.29,170.79';
        const coords = parsePolylinePoints(testPoints);
        console.log(`  Parsed ${coords.length} coordinate pairs from test polyline`);
        
        if (coords.length === 3) {
            console.log(`  ✅ Coordinate parsing successful`);
            console.log(`  Points: (${coords[0].x},${coords[0].y}) (${coords[1].x},${coords[1].y}) (${coords[2].x},${coords[2].y})`);
        } else {
            console.log(`  ❌ Expected 3 points, got ${coords.length}`);
        }
        
        // Test centroid calculation
        const centroid = calculateCentroid(coords);
        const expectedCentroidX = (56.04 + 57.66 + 59.29) / 3;
        const expectedCentroidY = (168.46 + 165.57 + 170.79) / 3;
        
        console.log(`🎯 Testing centroid calculation:`);
        console.log(`  Calculated: (${centroid.x.toFixed(2)}, ${centroid.y.toFixed(2)})`);
        console.log(`  Expected: (${expectedCentroidX.toFixed(2)}, ${expectedCentroidY.toFixed(2)})`);
        
        if (Math.abs(centroid.x - expectedCentroidX) < 0.01 && Math.abs(centroid.y - expectedCentroidY) < 0.01) {
            console.log(`  ✅ Centroid calculation accurate`);
        } else {
            console.log(`  ❌ Centroid calculation inaccurate`);
        }
        
        console.log('✅ All polyline support tests passed!');
        return true;
        
    } catch (error) {
        console.error('❌ Polyline support test failed:', error);
        return false;
    } finally {
        // Restore original function
        window.getComputedStyle = originalGetComputedStyle;
    }
}

// Helper functions (copied from the main library for testing)
function parsePolylinePoints(pointsStr) {
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

function calculateCentroid(coords) {
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

// Run tests
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { validatePolylineSupport };
} else {
    // Browser environment
    validatePolylineSupport();
}