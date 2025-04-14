# gramm-beta

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=piermorel/gramm&project=gramm.prj&file=doc/GettingStarted.mlx)

> This is a beta version of [Gramm](https://github.com/piermorel/gramm) with enhanced export capabilities using d3.js.

## Overview

This beta version extends the original Gramm toolbox with additional export functionality powered by d3.js. It maintains all the core features of Gramm while adding the ability to export interactive visualizations that can be embedded in web applications.

## Key Features

- All original Gramm plotting capabilities
- Enhanced export options with d3.js integration
- Interactive web-based visualizations
- Seamless integration with existing Gramm workflows

## Installation

1. Clone this repository
2. Add the toolbox folder to your MATLAB path
3. Install required dependencies (see below)

## Dependencies

- MATLAB R2018b or later
- Statistics and Machine Learning Toolbox
- d3.js (for export functionality)

## Usage

The usage remains the same as the original Gramm toolbox, with additional export options:

```matlab
websave('example_data','https://github.com/piermorel/gramm/raw/master/sample_data/example_data.mat'); %Download data from repository
load example_data;
g=gramm('x',cars.Model_Year,'y',cars.MPG,'color',cars.Cylinders, ...
    'subset',cars.Cylinders~=3 & cars.Cylinders~=5); %Select cars that are not 3 or 5 cylinders;
g.stat_glm();
g.geom_point("dodge",0.5); 
g.draw();
g.export_d3('file_name','github','export_path','dev/','x', 'Model_Year', 'y', 'MPG', 'title','Cars Plot');

```

## Export Options

- `export_d3()`: Export to interactive d3.js visualization

## Contributing

This is a beta version and we welcome feedback and contributions. Please report any issues or suggestions through the GitHub issue tracker.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

This project is based on the original [Gramm](https://github.com/piermorel/gramm) toolbox by Pierre Morel.