# SVG Interactive - Standalone Library

A lightweight, dependency-free JavaScript library for making static SVG visualizations interactive. Perfect for MATLAB integration and web applications.

## Features

- **🚀 Zero Dependencies**: Pure JavaScript with no external libraries
- **🎯 Smart Coordinate Mapping**: Automatically maps SVG pixels to data values
- **💡 Intelligent Element Detection**: Identifies data points and ignores backgrounds
- **🎨 Customizable Styling**: Configurable colors, tooltips, and behaviors
- **📊 Multiple Chart Types**: Supports scatter plots, bar charts, line charts
- **🔧 MATLAB Ready**: Designed for easy MATLAB web component integration

## Quick Start

### Basic Usage

```html
<!DOCTYPE html>
<html>
<head>
    <title>SVG Interactive Demo</title>
</head>
<body>
    <div id="chart-container">
        <!-- Your SVG content here -->
        <svg><!-- ... --></svg>
    </div>

    <!-- Include the library -->
    <script src="lib/coordinate-mapper.js"></script>
    <script src="lib/svg-interactive.js"></script>
    
    <script>
        // Make your SVG interactive
        const svg = document.querySelector('svg');
        const interactive = new SVGInteractive(svg, {
            onSelect: (selectedData) => {
                console.log('Selected points:', selectedData);
            }
        });
    </script>
</body>
</html>
```

### Advanced Configuration

```javascript
const interactive = new SVGInteractive(svgElement, {
    // Tooltip customization
    tooltipFormat: (point) => `
        <strong>Data Point</strong><br>
        X: ${point.dataX.toFixed(2)}<br>
        Y: ${point.dataY.toFixed(2)}
    `,
    
    // Event callbacks
    onSelect: (selectedData, point) => {
        console.log('Selection changed:', selectedData);
    },
    
    onHover: (point, action) => {
        if (action === 'enter') {
            console.log('Hovering over:', point.id);
        }
    },
    
    // Interaction options
    enableMultiSelect: true,
    enableTooltips: true,
    
    // Styling
    selectionColor: '#ff6b35',
    hoverColor: '#2196f3'
});
```

## API Reference

### Constructor Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `tooltipFormat` | Function | Built-in format | Custom tooltip content function |
| `onSelect` | Function | `() => {}` | Called when points are selected |
| `onHover` | Function | `() => {}` | Called on hover events |
| `enableMultiSelect` | Boolean | `true` | Allow Ctrl/Cmd+click multi-selection |
| `enableTooltips` | Boolean | `true` | Show hover tooltips |
| `selectionColor` | String | `'#ff6b35'` | Color for selected points |
| `hoverColor` | String | `'#2196f3'` | Color for hovered points |

### Methods

#### `getDataPoints()`
Returns all extracted data points.

```javascript
const points = interactive.getDataPoints();
console.log(`Found ${points.length} data points`);
```

#### `getSelectedData()`
Returns currently selected data points.

```javascript
const selected = interactive.getSelectedData();
console.log(`${selected.length} points selected`);
```

#### `selectPoints(pointIds)`
Programmatically select points by their IDs.

```javascript
interactive.selectPoints([0, 1, 2]); // Select first three points
```

#### `clearSelection()`
Clear all selections.

```javascript
interactive.clearSelection();
```

#### `exportData()`
Export all data and selections as JSON.

```javascript
const data = interactive.exportData();
// Returns: { dataPoints, selectedPoints, axisLabels, axisInfo }
```

#### `destroy()`
Clean up the interactive instance.

```javascript
interactive.destroy();
```

## MATLAB Integration

### Step 1: Prepare HTML Template

Create an HTML template for your MATLAB app:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Interactive Chart</title>
    <script src="lib/coordinate-mapper.js"></script>
    <script src="lib/svg-interactive.js"></script>
</head>
<body>
    <div id="chart-container"></div>
    
    <script>
        let interactiveInstance = null;
        
        // Function to be called from MATLAB
        function loadSVG(svgContent) {
            const container = document.getElementById('chart-container');
            container.innerHTML = svgContent;
            
            const svg = container.querySelector('svg');
            if (svg) {
                interactiveInstance = new SVGInteractive(svg, {
                    onSelect: (selectedData) => {
                        // Send data back to MATLAB
                        if (window.matlabCallback) {
                            window.matlabCallback(selectedData);
                        }
                    }
                });
            }
        }
        
        // Function to get selection data for MATLAB
        function getSelectionData() {
            return interactiveInstance ? 
                interactiveInstance.exportData() : null;
        }
    </script>
</body>
</html>
```

### Step 2: MATLAB Code Example

```matlab
% Create HTML UI component
htmlComponent = uihtml(figure, 'HTMLSource', 'interactive-chart.html');

% Load SVG content
svgContent = fileread('your-chart.svg');
executejs(htmlComponent, sprintf('loadSVG(`%s`)', svgContent));

% Set up callback for selections
htmlComponent.HTMLEventReceivedFcn = @(src, event) handleSelection(event);

function handleSelection(event)
    if strcmp(event.HTMLEventName, 'selection')
        selectedData = event.HTMLEventData;
        fprintf('Selected %d points\n', length(selectedData));
        % Process selection data...
    end
end
```

## File Structure

```
svg-interactive-standalone/
├── index.html              # Demo page
├── lib/
│   ├── coordinate-mapper.js # Coordinate mapping utilities
│   └── svg-interactive.js  # Main interactive library
├── examples/
│   ├── r4-1.svg            # Example scatter plot 1
│   ├── r4-2.svg            # Example scatter plot 2
│   └── demo.html           # Additional demo
└── README.md               # This file
```

## Supported SVG Elements

The library automatically detects and makes interactive:

- **Circles** (`<circle>`) - Scatter plot points
- **Rectangles** (`<rect>`) - Bar chart bars, heatmap cells
- **Paths** (`<path>`) - Custom shapes, line segments

Background elements (grids, axes, large containers) are automatically ignored.

## Browser Compatibility

- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## Troubleshooting

### "No data points found"

- Check that your SVG contains `<circle>`, `<rect>`, or `<path>` elements
- Verify elements aren't being filtered as background (very large or white-filled)
- Use `interactive.coordinateMapper.getDebugInfo()` to inspect axis detection

### "Coordinate mapping not working"

- Ensure your SVG has text elements with numeric values (axis ticks)
- Check that axis labels are positioned correctly (bottom for x-axis, left for y-axis)
- Manual coordinate bounds can be set if needed

### "Tooltips not showing"

- Verify `enableTooltips` is not set to `false`
- Check for CSS z-index conflicts
- Ensure tooltip container is added to document body

## Performance

- Tested with 1000+ data points
- Smooth interactions on modern browsers
- Memory efficient with automatic cleanup

## License

This library is extracted and simplified from the DIVI project (BSD-3-Clause).
Standalone version created for educational and integration purposes.