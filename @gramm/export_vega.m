function export_vega(g, varargin)
%EXPORT_VEGA Export gramm plot to Vega interactive visualization
%   EXPORT_VEGA(g, ...) exports the gramm plot g to an interactive Vega visualization
%   with the following optional parameters:
%       'file_name' - Name of the output files (default: 'untitled')
%       'export_path' - Path where to save the files (default: './')
%       'x' - X-axis label (default: 'x-axis')
%       'y' - Y-axis label (default: 'y-axis')
%       'title' - Plot title (default: 'Untitled')
%       'width' - Width of the plot in pixels (default: figure width)
%       'height' - Height of the plot in pixels (default: figure height)
%       'interactive' - Enable interactive legend ('true' or 'false', default: 'false')
%
%   Example:
%       g = gramm('x', x, 'y', y);
%       g.geom_line();
%       g.draw();
%       export_vega(g, 'file_name', 'my_plot', 'export_path', './output');

% Parse input parameters
params = parseInputParameters(g, varargin);

% Analyze gramm object
gramm_analysis = analyzeGrammObject(g);

% Detect chart types and layers
chart_spec = detectAllChartTypes(gramm_analysis);

% Extract and process data
vega_data = extractVegaData(gramm_analysis);

% Generate Vega specification
vega_spec = generateVegaSpecification(chart_spec, vega_data, params);

% Write output files
writeVegaFiles(vega_spec, params);

end

%% ===== CORE ANALYSIS FUNCTIONS =====

function params = parseInputParameters(g, varargin)
    % Get figure dimensions
    h_fig = g(1).parent;
    fig_pos = getpixelposition(h_fig);
    if fig_pos(3) == 0
        width_fig = '500';
    else
        width_fig = num2str(fig_pos(3));
    end
    if fig_pos(4) == 0
        height_fig = '500';
    else
        height_fig = num2str(fig_pos(4));
    end
    
    % Default parameters
    params = struct();
    params.file_name = 'untitled';
    params.export_path = './';
    params.x_label = 'x-axis';
    params.y_label = 'y-axis';
    params.title = 'Untitled';
    params.width = width_fig;
    params.height = height_fig;
    params.interactive = 'false';
    
    % Parse input arguments
    args = varargin{1}; % varargin is a cell containing the arguments
    for i = 1:2:length(args)
        if i <= length(args)
            param_name = args{i};
            
            
            % Ensure parameter name is a string/char and convert to char
            if ischar(param_name)
                param_str = param_name;
            elseif isstring(param_name)
                param_str = char(param_name);
            else
                error('Parameter name at position %d must be a string or char array, got %s', i, class(param_name));
            end
            
            switch param_str
                case 'file_name'
                    params.file_name = args{i+1};
                case 'export_path'
                    params.export_path = args{i+1};
                case 'x'
                    params.x_label = args{i+1};
                case 'y'
                    params.y_label = args{i+1};
                case 'title'
                    params.title = args{i+1};
                case 'width'
                    params.width = args{i+1};
                case 'height'
                    params.height = args{i+1};
                case 'interactive'
                    params.interactive = args{i+1};
            end
        end
    end
end

function analysis = analyzeGrammObject(g)
    analysis = struct();
    
    % Extract aesthetic mappings
    analysis.aes = extractAesthetics(g);
    
    % Analyze g.results to detect all geom_* and stat_* handles
    analysis.geoms = detectGeomHandles(g.results);
    analysis.stats = detectStatHandles(g.results);
    
    % Extract data and handle complex formats
    analysis.data = extractComplexData(g);
    
    % Detect grouping variables and color scales
    analysis.grouping = extractGroupingInfo(g);
end

function aes = extractAesthetics(g)
    aes = struct();
    aes.x = g.aes.x;
    aes.y = g.aes.y;
    
    % Extract additional aesthetics if present
    if isfield(g.aes, 'color')
        aes.color = g.aes.color;
    end
    if isfield(g.aes, 'size')
        aes.size = g.aes.size;
    end
    if isfield(g.aes, 'shape')
        aes.shape = g.aes.shape;
    end
end

function geoms = detectGeomHandles(results)
    geoms = struct();
    
    % Check for all possible geom handles - both _handle and direct field names
    geom_types = {'geom_point_handle', 'geom_line_handle', 'geom_bar_handle', ...
                  'geom_jitter_handle', 'geom_swarm_handle', 'geom_raster_handle', ...
                  'geom_interval_handle', 'geom_abline_handle', 'geom_vline_handle', ...
                  'geom_hline_handle', 'geom_polygon_handle'};
    
    % Also check for direct geom field names (without _handle suffix)
    geom_types_direct = {'geom_point', 'geom_line', 'geom_bar', ...
                        'geom_jitter', 'geom_swarm', 'geom_raster', ...
                        'geom_interval', 'geom_abline', 'geom_vline', ...
                        'geom_hline', 'geom_polygon'};
    
    % Check for _handle versions first
    for i = 1:length(geom_types)
        if isfield(results, geom_types{i})
            geoms.(geom_types{i}) = results.(geom_types{i});
        end
    end
    
    % Check for direct field names and convert to _handle format
    for i = 1:length(geom_types_direct)
        if isfield(results, geom_types_direct{i}) && ~isempty(results.(geom_types_direct{i}))
            handle_name = [geom_types_direct{i} '_handle'];
            geoms.(handle_name) = results.(geom_types_direct{i});
        end
    end
end

function stats = detectStatHandles(results)
    stats = struct();
    
    % Check for all possible stat handles
    stat_types = {'stat_glm_handle', 'stat_smooth_handle', 'stat_fit_handle', ...
                  'stat_bin_handle', 'stat_density_handle', 'stat_violin_handle', ...
                  'stat_boxplot_handle', 'stat_summary_handle', 'stat_bin2d_handle', ...
                  'stat_ellipse_handle', 'stat_qq_handle', 'stat_cornerhist_handle'};
    
    % Check for _handle versions first
    for i = 1:length(stat_types)
        if isfield(results, stat_types{i})
            stats.(stat_types{i}) = results.(stat_types{i});
        end
    end
    
    % Also check for direct field names (without _handle suffix) in results
    stat_types_direct = {'stat_glm', 'stat_smooth', 'stat_fit', ...
                        'stat_bin', 'stat_density', 'stat_violin', ...
                        'stat_boxplot', 'stat_summary', 'stat_bin2d', ...
                        'stat_ellipse', 'stat_qq', 'stat_cornerhist'};
    
    for i = 1:length(stat_types_direct)
        if isfield(results, stat_types_direct{i}) && ~isempty(results.(stat_types_direct{i}))
            handle_name = [stat_types_direct{i} '_handle'];
            if ~isfield(stats, handle_name)  % Don't overwrite if _handle version already exists
                stats.(handle_name) = results.(stat_types_direct{i});
            end
        end
    end
end

function data = extractComplexData(g)
    data = struct();
    data.x = g.aes.x;
    data.y = g.aes.y;
    
    % Handle complex data formats (2D arrays, cell arrays) - placeholder for now
    % This will be expanded in later phases
end

function grouping = extractGroupingInfo(g)
    grouping = struct();
    grouping.hasColorGroup = false;
    grouping.colorData = [];
    
    % Check for color grouping - more comprehensive detection
    if isfield(g.aes, 'color') && ~isempty(g.aes.color)
        % Check if color data has multiple unique values
        unique_colors = unique(g.aes.color);
        if length(unique_colors) > 1
            grouping.hasColorGroup = true;
            grouping.colorData = g.aes.color;
        else
            grouping.colorData = g.aes.color;
        end
    elseif isfield(g.results, 'color') && ~isempty(g.results.color) && length(g.results.color) > 1
        grouping.hasColorGroup = true;
        grouping.colorData = g.aes.color;
    else
        % No color grouping, use default color
        grouping.colorData = repmat('#ff4565', length(g.aes.x), 1);
    end
end

%% ===== CHART TYPE DETECTION =====

function chart_spec = detectAllChartTypes(analysis)
    chart_spec = struct();
    chart_spec.layers = {};
    
    % Get geom field names and handle empty case
    if isempty(analysis.geoms) || ~isstruct(analysis.geoms)
        geom_fields = {};
    else
        geom_fields = fieldnames(analysis.geoms);
    end
    
    % Get stat field names and handle empty case
    if isempty(analysis.stats) || ~isstruct(analysis.stats)
        stat_fields = {};
    else
        stat_fields = fieldnames(analysis.stats);
    end
    
    % Process each geom type
    for i = 1:length(geom_fields)
        geom_type = geom_fields{i};
        switch geom_type
            case 'geom_point_handle'
                chart_spec.layers{end+1} = createPointLayer(analysis);
            case 'geom_line_handle'
                chart_spec.layers{end+1} = createLineLayer(analysis);
            case 'geom_bar_handle'
                chart_spec.layers{end+1} = createBarLayer(analysis);
            case 'geom_jitter_handle'
                chart_spec.layers{end+1} = createJitterLayer(analysis);
            case 'geom_swarm_handle'
                chart_spec.layers{end+1} = createSwarmLayer(analysis);
            case 'geom_raster_handle'
                chart_spec.layers{end+1} = createRasterLayer(analysis);
            case 'geom_interval_handle'
                chart_spec.layers{end+1} = createIntervalLayer(analysis);
            case 'geom_abline_handle'
                chart_spec.layers{end+1} = createAblineLayer(analysis);
            case 'geom_vline_handle'
                chart_spec.layers{end+1} = createVlineLayer(analysis);
            case 'geom_hline_handle'
                chart_spec.layers{end+1} = createHlineLayer(analysis);
            case 'geom_polygon_handle'
                chart_spec.layers{end+1} = createPolygonLayer(analysis);
        end
    end
    
    % Process each stat type
    for i = 1:length(stat_fields)
        stat_type = stat_fields{i};
        switch stat_type
            case 'stat_glm_handle'
                chart_spec.layers{end+1} = createStatGlmLayer(analysis);
            case 'stat_smooth_handle'
                chart_spec.layers{end+1} = createStatSmoothLayer(analysis);
            case 'stat_bin_handle'
                chart_spec.layers{end+1} = createStatBinLayer(analysis);
            case 'stat_summary_handle'
                chart_spec.layers{end+1} = createStatSummaryLayer(analysis);
            case 'stat_density_handle'
                chart_spec.layers{end+1} = createStatDensityLayer(analysis);
            case 'stat_violin_handle'
                chart_spec.layers{end+1} = createStatViolinLayer(analysis);
            case 'stat_boxplot_handle'
                chart_spec.layers{end+1} = createStatBoxplotLayer(analysis);
            case 'stat_qq_handle'
                chart_spec.layers{end+1} = createStatQqLayer(analysis);
            case 'stat_fit_handle'
                chart_spec.layers{end+1} = createStatFitLayer(analysis);
            case 'stat_bin2d_handle'
                chart_spec.layers{end+1} = createStatBin2dLayer(analysis);
            case 'stat_ellipse_handle'
                chart_spec.layers{end+1} = createStatEllipseLayer(analysis);
            case 'stat_cornerhist_handle'
                chart_spec.layers{end+1} = createStatCornerhist(analysis);
        end
    end
    
    % If no geom or stat detected, default to point
    if isempty(chart_spec.layers)
        chart_spec.layers{1} = createPointLayer(analysis);
        disp('No geom or stat type detected, defaulting to point chart');
    end
end

%% ===== GEOMETRIC OBJECT IMPLEMENTATIONS =====

function layer = createPointLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for points
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks
    marks = struct();
    marks.name = 'points';
    marks.type = 'symbol';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.size = struct('value', 60);
    marks.encode.enter.stroke = struct('value', 'white');
    marks.encode.enter.strokeWidth = struct('value', 1);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createLineLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for lines
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks with proper grouping for multiple lines
    if analysis.grouping.hasColorGroup
        % For multi-color lines, use group with facet
        marks = struct();
        marks.name = 'lines';
        marks.type = 'group';
        marks.from = struct('facet', struct('name', 'series', 'data', 'table', 'groupby', 'color'));
        
        % Define the line mark within the group
        line_mark = struct();
        line_mark.type = 'line';
        line_mark.from = struct('data', 'series');
        line_mark.sort = struct('field', 'x'); % Sort by x-value within each color group
        line_mark.encode = struct();
        line_mark.encode.enter = struct();
        line_mark.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
        line_mark.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
        line_mark.encode.enter.strokeWidth = struct('value', 2);
        line_mark.encode.enter.stroke = struct('scale', 'color', 'field', 'color');
        
        marks.marks = {line_mark};
    else
        % For single-color lines, use simple line mark directly
        marks = struct();
        marks.name = 'lines';
        marks.type = 'line';
        marks.from = struct('data', 'table');
        marks.encode = struct();
        marks.encode.enter = struct();
        marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
        marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
        marks.encode.enter.strokeWidth = struct('value', 2);
        marks.encode.enter.stroke = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createBarLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for bars following official grouped bar pattern
    layer.vegaSpec = createBaseVegaSpec();
    
    % Create scales following the official example pattern (adapted for vertical bars)
    layer.vegaSpec.scales = {};
    
    % X scale (categorical - for bar groups)
    xscale = struct();
    xscale.name = 'xscale';
    xscale.type = 'band';
    xscale.domain = struct('data', 'table', 'field', 'x', 'sort', true);
    xscale.range = 'width';
    xscale.padding = 0.2;
    layer.vegaSpec.scales{end+1} = xscale;
    
    % Y scale (quantitative - for bar heights)
    yscale = struct();
    yscale.name = 'yscale';
    yscale.type = 'linear';
    yscale.domain = struct('data', 'table', 'field', 'y');
    yscale.range = 'height';
    yscale.round = true;
    yscale.zero = true;
    yscale.nice = true;
    layer.vegaSpec.scales{end+1} = yscale;
    
    % Color scale if grouping exists
    if analysis.grouping.hasColorGroup
        colorscale = struct();
        colorscale.name = 'color';
        colorscale.type = 'ordinal';
        colorscale.domain = struct('data', 'table', 'field', 'color');
        colorscale.range = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
        layer.vegaSpec.scales{end+1} = colorscale;
    end
    
    % Add axes
    layer.vegaSpec.axes = {
        struct('orient', 'bottom', 'scale', 'xscale', 'tickSize', 0, 'labelPadding', 4, 'zindex', 1);
        struct('orient', 'left', 'scale', 'yscale')
    };
    
    if analysis.grouping.hasColorGroup
        % For grouped bars, use the official nested group structure
        marks = struct();
        marks.type = 'group';
        marks.from = struct('facet', struct('data', 'table', 'name', 'facet', 'groupby', 'x'));
        
        % Positioning for each group
        marks.encode = struct();
        marks.encode.enter = struct();
        marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
        
        % Add signal for width calculation
        marks.signals = {struct('name', 'width', 'update', 'bandwidth(''xscale'')')};
        
        % Add inner scale for positioning bars within each group
        pos_scale = struct();
        pos_scale.name = 'pos';
        pos_scale.type = 'band';
        pos_scale.range = 'width';
        pos_scale.domain = struct('data', 'facet', 'field', 'color');
        marks.scales = {pos_scale};
        
        % Create the individual bar mark within each group
        bar_mark = struct();
        bar_mark.name = 'bars';
        bar_mark.from = struct('data', 'facet');
        bar_mark.type = 'rect';
        bar_mark.encode = struct();
        bar_mark.encode.enter = struct();
        bar_mark.encode.enter.x = struct('scale', 'pos', 'field', 'color');
        bar_mark.encode.enter.width = struct('scale', 'pos', 'band', 1);
        bar_mark.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
        bar_mark.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
        bar_mark.encode.enter.fill = struct('scale', 'color', 'field', 'color');
        
        marks.marks = {bar_mark};
    else
        % Single bars can use simple rect mark
        marks = struct();
        marks.name = 'bars';
        marks.type = 'rect';
        marks.from = struct('data', 'table');
        
        marks.encode = struct();
        marks.encode.enter = struct();
        marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
        marks.encode.enter.width = struct('scale', 'xscale', 'band', 1);
        marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
        marks.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createJitterLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for jittered points
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks with jitter transform
    marks = struct();
    marks.name = 'jitteredPoints';
    marks.type = 'symbol';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.update = struct();
    marks.encode.update.x = struct('signal', 'scale(''xscale'', datum.x) + bandwidth(''xscale'')/2 + (random() - 0.5) * bandwidth(''xscale'') * 0.8');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.size = struct('value', 60);
    marks.encode.enter.stroke = struct('value', 'white');
    marks.encode.enter.strokeWidth = struct('value', 1);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createSwarmLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for beeswarm plot using jitter-based approach
    % This preserves Y-value accuracy while creating swarm visual effect
    layer.vegaSpec = createBaseVegaSpec();
    
    % Create scales - force band scale for swarm plots
    scales = {};
    
    % X scale - always use band scale for swarm plots to create discrete groups
    xscale = struct();
    xscale.name = 'xscale';
    xscale.type = 'band';
    xscale.domain = struct('data', 'table', 'field', 'x', 'sort', true);
    xscale.range = 'width';
    scales{end+1} = xscale;
    
    % Y scale - preserves exact Y values from data
    yscale = struct();
    yscale.name = 'yscale';
    yscale.type = 'linear';
    yscale.domain = struct('data', 'table', 'field', 'y');
    yscale.range = 'height';
    yscale.nice = true;
    yscale.zero = true;
    scales{end+1} = yscale;
    
    % Color scale if grouping exists
    if analysis.grouping.hasColorGroup
        colorscale = struct();
        colorscale.name = 'color';
        colorscale.type = 'ordinal';
        colorscale.domain = struct('data', 'table', 'field', 'color');
        colorscale.range = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
        scales{end+1} = colorscale;
    end
    
    layer.vegaSpec.scales = scales;
    
    % Add axes - both X and Y for proper scaling
    layer.vegaSpec.axes = {
        struct('orient', 'bottom', 'scale', 'xscale', 'labelAngle', 0, 'labelFontSize', 12);
        struct('orient', 'left', 'scale', 'yscale')
    };
    
    % Create swarm marks using jitter-based approach that preserves Y values
    marks = struct();
    marks.name = 'swarmPoints';
    marks.type = 'symbol';
    marks.from = struct('data', 'table');
    
    % Encode properties
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.stroke = struct('value', 'white');
    marks.encode.enter.strokeWidth = struct('value', 1);
    marks.encode.enter.size = struct('value', 80);
    
    % CRITICAL: Preserve exact Y values from data - no transformation applied
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    
    % Set color based on grouping
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    % X positioning with simple jitter calculation (same as jitter implementation)
    marks.encode.update = struct();
    marks.encode.update.x = struct('signal', 'scale(''xscale'', datum.x) + bandwidth(''xscale'')/2 + (random() - 0.5) * bandwidth(''xscale'') * 0.8');
    
    layer.vegaSpec.marks = {marks};
end

function layer = createRasterLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for raster/tick plots
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales (only x-scale needed for raster)
    scales = createVegaScales(analysis);
    layer.vegaSpec.scales = scales(1); % Only keep x-scale
    
    % Add axes (only x-axis)
    layer.vegaSpec.axes = {struct('orient', 'bottom', 'scale', 'xscale')};
    
    % Create marks
    marks = struct();
    marks.name = 'ticks';
    marks.type = 'rect';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.width = struct('value', 2);
    marks.encode.enter.y = struct('value', 0);
    marks.encode.enter.height = struct('signal', 'height');
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createIntervalLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for error bars/intervals
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks for error bars
    marks = struct();
    marks.name = 'errorbars';
    marks.type = 'rule';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'ymin');
    marks.encode.enter.y2 = struct('scale', 'yscale', 'field', 'ymax');
    marks.encode.enter.strokeWidth = struct('value', 2);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.stroke = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.stroke = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createAblineLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for diagonal reference lines
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks for diagonal line
    marks = struct();
    marks.name = 'abline';
    marks.type = 'line';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.stroke = struct('value', '#808080');
    marks.encode.enter.strokeWidth = struct('value', 2);
    marks.encode.enter.strokeDash = struct('value', [5, 5]);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createVlineLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for vertical reference lines
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks for vertical lines
    marks = struct();
    marks.name = 'vlines';
    marks.type = 'rule';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('value', 0);
    marks.encode.enter.y2 = struct('signal', 'height');
    marks.encode.enter.stroke = struct('value', '#808080');
    marks.encode.enter.strokeWidth = struct('value', 1);
    marks.encode.enter.strokeDash = struct('value', [3, 3]);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createHlineLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for horizontal reference lines
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks for horizontal lines
    marks = struct();
    marks.name = 'hlines';
    marks.type = 'rule';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('value', 0);
    marks.encode.enter.x2 = struct('signal', 'width');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.stroke = struct('value', '#808080');
    marks.encode.enter.strokeWidth = struct('value', 1);
    marks.encode.enter.strokeDash = struct('value', [3, 3]);
    
    layer.vegaSpec.marks = {marks};
end

function layer = createPolygonLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for polygon/area plots
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks for polygon
    marks = struct();
    marks.name = 'polygons';
    marks.type = 'area';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
    marks.encode.enter.fill = struct('value', '#cccccc');
    marks.encode.enter.fillOpacity = struct('value', 0.3);
    
    layer.vegaSpec.marks = {marks};
end

%% ===== STATISTICAL TRANSFORMATION IMPLEMENTATIONS =====

function layer = createStatGlmLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for GLM fits with confidence intervals
    layer.vegaSpec = createBaseVegaSpec();
    
    % Create two data sources like working example
    % 1. Points data (raw data)
    points_data = struct();
    points_data.name = 'points';
    points_data.values = extractVegaData(analysis);  % Use existing function
    
    % 2. Regression data (references points with transform)
    regression_data = struct();
    regression_data.name = 'regression';
    regression_data.source = 'points';  % Key: reference the points data
    
    % Add regression transform
    reg_transform = struct();
    reg_transform.type = 'regression';
    reg_transform.method = 'linear';
    reg_transform.x = 'x';
    reg_transform.y = 'y';
    reg_transform.as = {'reg_x', 'reg_y'};
    
    % Add groupby if color grouping exists  
    if analysis.grouping.hasColorGroup
        reg_transform.groupby = {'color'};
    end
    
    regression_data.transform = {reg_transform};
    
    % Set both data sources
    layer.vegaSpec.data = {points_data, regression_data};
    
    % Add scales (reference points data for domain)
    layer.vegaSpec.scales = createVegaScales(analysis, false, 'points');
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create marks for both points and regression line
    marks = {};
    
    % 1. Symbol marks for data points
    symbol_marks = struct();
    symbol_marks.type = 'symbol';
    symbol_marks.from = struct('data', 'points');
    symbol_marks.encode = struct();
    symbol_marks.encode.enter = struct();
    symbol_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    symbol_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    symbol_marks.encode.enter.size = struct('value', 50);
    
    % Set symbol color
    if analysis.grouping.hasColorGroup
        symbol_marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        symbol_marks.encode.enter.fill = struct('value', 'steelblue');
    end
    
    marks{1} = symbol_marks;
    
    % 2. Line marks for regression
    if analysis.grouping.hasColorGroup
        % Use faceted group approach for multi-color regression (like working example)
        group_marks = struct();
        group_marks.type = 'group';
        group_marks.from = struct();
        group_marks.from.facet = struct();
        group_marks.from.facet.name = 'facet_lines';
        group_marks.from.facet.data = 'regression';
        group_marks.from.facet.groupby = 'color';
        
        % Create inner line mark
        inner_line = struct();
        inner_line.type = 'line';
        inner_line.from = struct('data', 'facet_lines');
        inner_line.encode = struct();
        inner_line.encode.enter = struct();
        inner_line.encode.enter.x = struct('scale', 'xscale', 'field', 'reg_x');
        inner_line.encode.enter.y = struct('scale', 'yscale', 'field', 'reg_y');
        inner_line.encode.enter.strokeWidth = struct('value', 2);
        inner_line.encode.enter.stroke = struct('scale', 'color', 'field', 'color');
        
        group_marks.marks = {inner_line};
        marks{2} = group_marks;
    else
        % Use simple line approach for single-color regression
        line_marks = struct();
        line_marks.type = 'line';
        line_marks.from = struct('data', 'regression');
        line_marks.encode = struct();
        line_marks.encode.enter = struct();
        line_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'reg_x');
        line_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'reg_y');
        line_marks.encode.enter.strokeWidth = struct('value', 2);
        line_marks.encode.enter.stroke = struct('value', '#ff4565');
        
        marks{2} = line_marks;
    end
    
    layer.vegaSpec.marks = marks;
end

function layer = createStatSmoothLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for smoothed estimates using LOESS
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add LOESS smoothing transform
    if analysis.grouping.hasColorGroup
        % Group by color for separate smoothing
        loess_transform = struct();
        loess_transform.type = 'loess';
        loess_transform.groupby = {'color'};
        loess_transform.x = 'x';
        loess_transform.y = 'y';
        loess_transform.bandwidth = 0.3;  % Default bandwidth
        loess_transform.as = {'smooth_x', 'smooth_y'};
        
        layer.vegaSpec.data{1}.transform = {loess_transform};
        
        % Create custom scales that reference the transformed fields
        scales = {};
        
        % X scale for smoothed data
        xscale = struct();
        xscale.name = 'xscale';
        xscale.type = 'linear';
        xscale.domain = struct('data', 'table', 'field', 'smooth_x');
        xscale.range = 'width';
        scales{end+1} = xscale;
        
        % Y scale for smoothed data
        yscale = struct();
        yscale.name = 'yscale';
        yscale.type = 'linear';
        yscale.domain = struct('data', 'table', 'field', 'smooth_y');
        yscale.range = 'height';
        yscale.nice = true;
        scales{end+1} = yscale;
        
        % Color scale for grouping
        colorscale = struct();
        colorscale.name = 'color';
        colorscale.type = 'ordinal';
        colorscale.domain = struct('data', 'table', 'field', 'color');
        colorscale.range = 'category';
        scales{end+1} = colorscale;
        
        layer.vegaSpec.scales = scales;
        
        % Create marks for smooth lines
        line_marks = struct();
        line_marks.name = 'smooth_lines';
        line_marks.type = 'line';
        line_marks.from = struct('data', 'table');
        line_marks.encode = struct();
        line_marks.encode.enter = struct();
        line_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'smooth_x');
        line_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'smooth_y');
        line_marks.encode.enter.strokeWidth = struct('value', 3);
        line_marks.encode.enter.stroke = struct('scale', 'color', 'field', 'color');
        
        layer.vegaSpec.marks = {line_marks};
    else
        % Single smooth line
        loess_transform = struct();
        loess_transform.type = 'loess';
        loess_transform.x = 'x';
        loess_transform.y = 'y';
        loess_transform.bandwidth = 0.3;
        loess_transform.as = {'smooth_x', 'smooth_y'};
        
        layer.vegaSpec.data{1}.transform = {loess_transform};
        
        % Create custom scales that reference the transformed fields
        scales = {};
        
        % X scale for smoothed data
        xscale = struct();
        xscale.name = 'xscale';
        xscale.type = 'linear';
        xscale.domain = struct('data', 'table', 'field', 'smooth_x');
        xscale.range = 'width';
        scales{end+1} = xscale;
        
        % Y scale for smoothed data
        yscale = struct();
        yscale.name = 'yscale';
        yscale.type = 'linear';
        yscale.domain = struct('data', 'table', 'field', 'smooth_y');
        yscale.range = 'height';
        yscale.nice = true;
        scales{end+1} = yscale;
        
        layer.vegaSpec.scales = scales;
        
        % Create marks for smooth line
        line_marks = struct();
        line_marks.name = 'smooth_line';
        line_marks.type = 'line';
        line_marks.from = struct('data', 'table');
        line_marks.encode = struct();
        line_marks.encode.enter = struct();
        line_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'smooth_x');
        line_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'smooth_y');
        line_marks.encode.enter.strokeWidth = struct('value', 3);
        line_marks.encode.enter.stroke = struct('value', '#ff4565');
        
        layer.vegaSpec.marks = {line_marks};
    end
    
    % Add axes that reference the transformed fields
    layer.vegaSpec.axes = createVegaAxes(analysis);
end

function layer = createStatBinLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for histograms
    layer.vegaSpec = createBaseVegaSpec();
    
    % Create scales for histogram
    scales = {};
    
    % X scale for bins
    xscale = struct();
    xscale.name = 'xscale';
    xscale.type = 'linear';
    xscale.domain = struct('data', 'binned', 'field', 'x0');
    xscale.range = 'width';
    scales{end+1} = xscale;
    
    % Y scale for counts
    yscale = struct();
    yscale.name = 'yscale';
    yscale.type = 'linear';
    yscale.domain = struct('data', 'binned', 'field', 'count');
    yscale.range = 'height';
    yscale.nice = true;
    yscale.zero = true;
    scales{end+1} = yscale;
    
    % Color scale if grouping exists
    if analysis.grouping.hasColorGroup
        colorscale = struct();
        colorscale.name = 'color';
        colorscale.type = 'ordinal';
        colorscale.domain = struct('data', 'binned', 'field', 'color');
        colorscale.range = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
        scales{end+1} = colorscale;
    end
    
    layer.vegaSpec.scales = scales;
    
    % Add axes
    layer.vegaSpec.axes = {
        struct('orient', 'bottom', 'scale', 'xscale', 'title', 'x-axis');
        struct('orient', 'left', 'scale', 'yscale', 'title', 'Count')
    };
    
    % Add binning transform and create new data source
    binned_data = struct();
    binned_data.name = 'binned';
    binned_data.source = 'table';
    binned_data.transform = {};
    
    if analysis.grouping.hasColorGroup
        % Bin with grouping
        bin_transform = struct();
        bin_transform.type = 'bin';
        bin_transform.field = 'x';
        bin_transform.extent = struct('signal', 'extent(data(''table''), ''x'')');
        bin_transform.maxbins = 30;
        bin_transform.as = {'x0', 'x1'};
        
        aggregate_transform = struct();
        aggregate_transform.type = 'aggregate';
        aggregate_transform.groupby = {'x0', 'x1', 'color'};
        aggregate_transform.fields = {};
        aggregate_transform.ops = {'count'};
        aggregate_transform.as = {'count'};
        
        binned_data.transform = {bin_transform, aggregate_transform};
    else
        % Simple binning
        bin_transform = struct();
        bin_transform.type = 'bin';
        bin_transform.field = 'x';
        bin_transform.maxbins = 30;
        bin_transform.as = {'x0', 'x1'};
        
        aggregate_transform = struct();
        aggregate_transform.type = 'aggregate';
        aggregate_transform.groupby = {'x0', 'x1'};
        aggregate_transform.fields = {};
        aggregate_transform.ops = {'count'};
        aggregate_transform.as = {'count'};
        
        binned_data.transform = {bin_transform, aggregate_transform};
    end
    
    layer.vegaSpec.data = {struct('name', 'table'), binned_data};
    
    % Create histogram marks
    if analysis.grouping.hasColorGroup
        % Grouped/stacked bars
        marks = struct();
        marks.name = 'bars';
        marks.type = 'rect';
        marks.from = struct('data', 'binned');
        
        marks.encode = struct();
        marks.encode.enter = struct();
        marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x0');
        marks.encode.enter.x2 = struct('scale', 'xscale', 'field', 'x1');
        marks.encode.enter.y = struct('scale', 'yscale', 'field', 'count');
        marks.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
        
        layer.vegaSpec.marks = {marks};
    else
        % Simple bars
        marks = struct();
        marks.name = 'bars';
        marks.type = 'rect';
        marks.from = struct('data', 'binned');
        
        marks.encode = struct();
        marks.encode.enter = struct();
        marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x0');
        marks.encode.enter.x2 = struct('scale', 'xscale', 'field', 'x1');
        marks.encode.enter.y = struct('scale', 'yscale', 'field', 'count');
        marks.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
        marks.encode.enter.fill = struct('value', '#ff4565');
        
        layer.vegaSpec.marks = {marks};
    end
end

function layer = createStatSummaryLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for statistical summaries with error bars
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Add summary transform
    summary_data = struct();
    summary_data.name = 'summary';
    summary_data.source = 'table';
    
    if analysis.grouping.hasColorGroup
        % Group by x and color
        summary_transform = struct();
        summary_transform.type = 'aggregate';
        summary_transform.groupby = {'x', 'color'};
        summary_transform.fields = {'y', 'y', 'y'};
        summary_transform.ops = {'mean', 'stdev', 'count'};
        summary_transform.as = {'mean_y', 'stdev_y', 'count_y'};
        
        summary_data.transform = {summary_transform};
        
        % Calculate confidence intervals
        ci_transform = struct();
        ci_transform.type = 'formula';
        ci_transform.expr = 'datum.mean_y - 1.96 * datum.stdev_y / sqrt(datum.count_y)';
        ci_transform.as = 'ci_lower';
        
        ci_transform2 = struct();
        ci_transform2.type = 'formula';
        ci_transform2.expr = 'datum.mean_y + 1.96 * datum.stdev_y / sqrt(datum.count_y)';
        ci_transform2.as = 'ci_upper';
        
        summary_data.transform = {summary_transform, ci_transform, ci_transform2};
    else
        % Simple summary
        summary_transform = struct();
        summary_transform.type = 'aggregate';
        summary_transform.groupby = {'x'};
        summary_transform.fields = {'y', 'y', 'y'};
        summary_transform.ops = {'mean', 'stdev', 'count'};
        summary_transform.as = {'mean_y', 'stdev_y', 'count_y'};
        
        % Calculate confidence intervals
        ci_transform = struct();
        ci_transform.type = 'formula';
        ci_transform.expr = 'datum.mean_y - 1.96 * datum.stdev_y / sqrt(datum.count_y)';
        ci_transform.as = 'ci_lower';
        
        ci_transform2 = struct();
        ci_transform2.type = 'formula';
        ci_transform2.expr = 'datum.mean_y + 1.96 * datum.stdev_y / sqrt(datum.count_y)';
        ci_transform2.as = 'ci_upper';
        
        summary_data.transform = {summary_transform, ci_transform, ci_transform2};
    end
    
    layer.vegaSpec.data = {struct('name', 'table'), summary_data};
    
    % Create marks for means (points) and error bars
    marks = {};
    
    % Error bars
    error_marks = struct();
    error_marks.name = 'errorbars';
    error_marks.type = 'rule';
    error_marks.from = struct('data', 'summary');
    error_marks.encode = struct();
    error_marks.encode.enter = struct();
    error_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    error_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'ci_lower');
    error_marks.encode.enter.y2 = struct('scale', 'yscale', 'field', 'ci_upper');
    error_marks.encode.enter.strokeWidth = struct('value', 2);
    
    % Mean points
    point_marks = struct();
    point_marks.name = 'means';
    point_marks.type = 'symbol';
    point_marks.from = struct('data', 'summary');
    point_marks.encode = struct();
    point_marks.encode.enter = struct();
    point_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    point_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'mean_y');
    point_marks.encode.enter.size = struct('value', 100);
    point_marks.encode.enter.stroke = struct('value', 'white');
    point_marks.encode.enter.strokeWidth = struct('value', 2);
    
    if analysis.grouping.hasColorGroup
        error_marks.encode.enter.stroke = struct('scale', 'color', 'field', 'color');
        point_marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        error_marks.encode.enter.stroke = struct('value', '#ff4565');
        point_marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {error_marks, point_marks};
end

function layer = createStatDensityLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for kernel density estimation
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Add density transform
    density_data = struct();
    density_data.name = 'density';
    density_data.source = 'table';
    
    if analysis.grouping.hasColorGroup
        % Group by color for separate densities
        density_transform = struct();
        density_transform.type = 'kde';
        density_transform.field = 'x';
        density_transform.groupby = {'color'};
        density_transform.bandwidth = 0.4;  % Default bandwidth
        density_transform.extent = struct('signal', 'extent(data(''table''), ''x'')');
        density_transform.as = {'value', 'density'};
        
        density_data.transform = {density_transform};
    else
        % Single density
        density_transform = struct();
        density_transform.type = 'kde';
        density_transform.field = 'x';
        density_transform.bandwidth = 0.4;
        density_transform.extent = struct('signal', 'extent(data(''table''), ''x'')');
        density_transform.as = {'value', 'density'};
        
        density_data.transform = {density_transform};
    end
    
    layer.vegaSpec.data = {struct('name', 'table'), density_data};
    
    % Create area marks for density curves
    marks = struct();
    marks.name = 'density_curves';
    marks.type = 'area';
    marks.from = struct('data', 'density');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'value');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'density');
    marks.encode.enter.y2 = struct('scale', 'yscale', 'value', 0);
    marks.encode.enter.fillOpacity = struct('value', 0.7);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createStatViolinLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for violin plots (simplified)
    layer.vegaSpec = createBaseVegaSpec();
    
    % For now, create a simplified violin using density + boxplot approach
    % In a full implementation, this would use more complex transforms
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create violin approximation using area marks
    marks = struct();
    marks.name = 'violin_approximation';
    marks.type = 'rect';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.width = struct('value', 40);
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.height = struct('value', 3);
    marks.encode.enter.fillOpacity = struct('value', 0.6);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createStatBoxplotLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for box plots
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Add boxplot transform
    boxplot_data = struct();
    boxplot_data.name = 'boxplot';
    boxplot_data.source = 'table';
    
    if analysis.grouping.hasColorGroup
        % Group by x and color
        boxplot_transform = struct();
        boxplot_transform.type = 'aggregate';
        boxplot_transform.groupby = {'x', 'color'};
        boxplot_transform.fields = {'y', 'y', 'y', 'y', 'y'};
        boxplot_transform.ops = {'q1', 'median', 'q3', 'min', 'max'};
        boxplot_transform.as = {'q1', 'median', 'q3', 'min', 'max'};
        
        boxplot_data.transform = {boxplot_transform};
    else
        % Simple boxplot
        boxplot_transform = struct();
        boxplot_transform.type = 'aggregate';
        boxplot_transform.groupby = {'x'};
        boxplot_transform.fields = {'y', 'y', 'y', 'y', 'y'};
        boxplot_transform.ops = {'q1', 'median', 'q3', 'min', 'max'};
        boxplot_transform.as = {'q1', 'median', 'q3', 'min', 'max'};
        
        boxplot_data.transform = {boxplot_transform};
    end
    
    layer.vegaSpec.data = {struct('name', 'table'), boxplot_data};
    
    % Create box marks (simplified implementation)
    box_marks = struct();
    box_marks.name = 'boxes';
    box_marks.type = 'rect';
    box_marks.from = struct('data', 'boxplot');
    
    box_marks.encode = struct();
    box_marks.encode.enter = struct();
    box_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    box_marks.encode.enter.width = struct('value', 40);
    box_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'q1');
    box_marks.encode.enter.y2 = struct('scale', 'yscale', 'field', 'q3');
    box_marks.encode.enter.stroke = struct('value', 'black');
    box_marks.encode.enter.strokeWidth = struct('value', 1);
    
    if analysis.grouping.hasColorGroup
        box_marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        box_marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {box_marks};
end

function layer = createStatQqLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for Q-Q plots
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create Q-Q plot marks (simplified implementation)
    marks = struct();
    marks.name = 'qq_points';
    marks.type = 'symbol';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.size = struct('value', 60);
    marks.encode.enter.stroke = struct('value', 'white');
    marks.encode.enter.strokeWidth = struct('value', 1);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createStatFitLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for custom function fits
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % For custom fits, we'll use polynomial regression as default
    % Add polynomial regression transform
    if analysis.grouping.hasColorGroup
        % Group by color for separate fits
        fit_transform = struct();
        fit_transform.type = 'regression';
        fit_transform.groupby = {'color'};
        fit_transform.method = 'poly';
        fit_transform.order = 2;  % Quadratic by default
        fit_transform.x = 'x';
        fit_transform.y = 'y';
        fit_transform.as = {'fit_x', 'fit_y'};
        
        layer.vegaSpec.data{1}.transform = {fit_transform};
        
        % Create marks for fit lines
        line_marks = struct();
        line_marks.name = 'fit_lines';
        line_marks.type = 'line';
        line_marks.from = struct('data', 'table');
        line_marks.encode = struct();
        line_marks.encode.enter = struct();
        line_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'fit_x');
        line_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'fit_y');
        line_marks.encode.enter.strokeWidth = struct('value', 3);
        line_marks.encode.enter.stroke = struct('scale', 'color', 'field', 'color');
        line_marks.encode.enter.strokeDash = struct('value', [5, 5]);
        
        layer.vegaSpec.marks = {line_marks};
    else
        % Single fit
        fit_transform = struct();
        fit_transform.type = 'regression';
        fit_transform.method = 'poly';
        fit_transform.order = 2;
        fit_transform.x = 'x';
        fit_transform.y = 'y';
        fit_transform.as = {'fit_x', 'fit_y'};
        
        layer.vegaSpec.data{1}.transform = {fit_transform};
        
        % Create marks for fit line
        line_marks = struct();
        line_marks.name = 'fit_line';
        line_marks.type = 'line';
        line_marks.from = struct('data', 'table');
        line_marks.encode = struct();
        line_marks.encode.enter = struct();
        line_marks.encode.enter.x = struct('scale', 'xscale', 'field', 'fit_x');
        line_marks.encode.enter.y = struct('scale', 'yscale', 'field', 'fit_y');
        line_marks.encode.enter.strokeWidth = struct('value', 3);
        line_marks.encode.enter.stroke = struct('value', '#ff4565');
        line_marks.encode.enter.strokeDash = struct('value', [5, 5]);
        
        layer.vegaSpec.marks = {line_marks};
    end
end

function layer = createStatBin2dLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for 2D histograms/heatmaps
    layer.vegaSpec = createBaseVegaSpec();
    
    % Create scales for 2D binning
    scales = {};
    
    % X scale
    xscale = struct();
    xscale.name = 'xscale';
    xscale.type = 'linear';
    xscale.domain = struct('data', 'binned2d', 'field', 'x');
    xscale.range = 'width';
    scales{end+1} = xscale;
    
    % Y scale
    yscale = struct();
    yscale.name = 'yscale';
    yscale.type = 'linear';
    yscale.domain = struct('data', 'binned2d', 'field', 'y');
    yscale.range = 'height';
    scales{end+1} = yscale;
    
    % Color scale for density
    colorscale = struct();
    colorscale.name = 'color';
    colorscale.type = 'linear';
    colorscale.domain = struct('data', 'binned2d', 'field', 'count');
    colorscale.range = {'#f7f7f7', '#ff4565'};
    scales{end+1} = colorscale;
    
    layer.vegaSpec.scales = scales;
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Add 2D binning transform
    binned2d_data = struct();
    binned2d_data.name = 'binned2d';
    binned2d_data.source = 'table';
    
    % Simplified 2D binning - in practice would need more complex transforms
    bin2d_transform = struct();
    bin2d_transform.type = 'aggregate';
    bin2d_transform.groupby = {'x', 'y'};  % Simplified
    bin2d_transform.fields = {};
    bin2d_transform.ops = {'count'};
    bin2d_transform.as = {'count'};
    
    binned2d_data.transform = {bin2d_transform};
    layer.vegaSpec.data = {struct('name', 'table'), binned2d_data};
    
    % Create heatmap marks
    marks = struct();
    marks.name = 'heatmap';
    marks.type = 'rect';
    marks.from = struct('data', 'binned2d');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.width = struct('value', 10);
    marks.encode.enter.height = struct('value', 10);
    marks.encode.enter.fill = struct('scale', 'color', 'field', 'count');
    
    layer.vegaSpec.marks = {marks};
end

function layer = createStatEllipseLayer(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for confidence ellipses
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create ellipse marks (simplified implementation)
    marks = struct();
    marks.name = 'ellipses';
    marks.type = 'arc';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.startAngle = struct('value', 0);
    marks.encode.enter.endAngle = struct('value', 6.28);  % 2*pi
    marks.encode.enter.innerRadius = struct('value', 0);
    marks.encode.enter.outerRadius = struct('value', 20);
    marks.encode.enter.fillOpacity = struct('value', 0.3);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

function layer = createStatCornerhist(analysis)
    layer = struct();
    layer.isVegaChart = true;
    
    % Create Vega specification for corner histograms
    layer.vegaSpec = createBaseVegaSpec();
    
    % Add scales
    layer.vegaSpec.scales = createVegaScales(analysis);
    
    % Add axes
    layer.vegaSpec.axes = createVegaAxes(analysis);
    
    % Create corner histogram marks (simplified)
    marks = struct();
    marks.name = 'corner_hist';
    marks.type = 'rect';
    marks.from = struct('data', 'table');
    
    marks.encode = struct();
    marks.encode.enter = struct();
    marks.encode.enter.x = struct('scale', 'xscale', 'field', 'x');
    marks.encode.enter.y = struct('scale', 'yscale', 'field', 'y');
    marks.encode.enter.width = struct('value', 5);
    marks.encode.enter.height = struct('value', 5);
    marks.encode.enter.fillOpacity = struct('value', 0.7);
    
    if analysis.grouping.hasColorGroup
        marks.encode.enter.fill = struct('scale', 'color', 'field', 'color');
    else
        marks.encode.enter.fill = struct('value', '#ff4565');
    end
    
    layer.vegaSpec.marks = {marks};
end

%% ===== VEGA HELPER FUNCTIONS =====

function baseSpec = createBaseVegaSpec()
    baseSpec = struct();
    baseSpec.schema = 'https://vega.github.io/schema/vega/v6.json';
    baseSpec.width = 600;
    baseSpec.height = 400;
    baseSpec.padding = struct('left', 60, 'right', 20, 'top', 20, 'bottom', 60);
    baseSpec.autosize = 'none';
    baseSpec.data = {struct('name', 'table')};
end

function scales = createVegaScales(analysis, forceBandScale, dataSource)
    if nargin < 2
        forceBandScale = false;
    end
    if nargin < 3
        dataSource = 'table';  % Default to 'table' for backward compatibility
    end
    
    scales = {};
    
    % X scale
    xscale = struct();
    xscale.name = 'xscale';
    if forceBandScale || ~isnumeric(analysis.data.x)
        xscale.type = 'band';
        xscale.domain = struct('data', dataSource, 'field', 'x', 'sort', true);
        xscale.padding = 0.1;
    else
        xscale.type = 'linear';
        xscale.domain = struct('data', dataSource, 'field', 'x');
    end
    xscale.range = 'width';
    scales{end+1} = xscale;
    
    % Y scale
    yscale = struct();
    yscale.name = 'yscale';
    if isnumeric(analysis.data.y)
        yscale.type = 'linear';
        yscale.domain = struct('data', dataSource, 'field', 'y');
    else
        yscale.type = 'band';
        yscale.domain = struct('data', dataSource, 'field', 'y', 'sort', true);
        yscale.padding = 0.1;
    end
    yscale.range = 'height';
    yscale.nice = true;
    yscale.zero = true;
    scales{end+1} = yscale;
    
    % Color scale if grouping exists
    if analysis.grouping.hasColorGroup
        colorscale = struct();
        colorscale.name = 'color';
        colorscale.type = 'ordinal';
        colorscale.domain = struct('data', dataSource, 'field', 'color');
        colorscale.range = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
        scales{end+1} = colorscale;
    end
end

function axes = createVegaAxes(analysis)
    axes = {};
    
    % X axis
    xaxis = struct();
    xaxis.orient = 'bottom';
    xaxis.scale = 'xscale';
    xaxis.title = 'x-axis';
    axes{end+1} = xaxis;
    
    % Y axis
    yaxis = struct();
    yaxis.orient = 'left';
    yaxis.scale = 'yscale';
    yaxis.title = 'y-axis';
    axes{end+1} = yaxis;
end

%% ===== ENCODING HELPERS =====

function encoding = createBasicEncoding(analysis)
    encoding = struct();
    
    % X encoding
    encoding.x = struct();
    encoding.x.field = 'x';
    if isnumeric(analysis.data.x)
        encoding.x.type = 'quantitative';
    else
        encoding.x.type = 'nominal';
    end
    
    % Y encoding
    encoding.y = struct();
    encoding.y.field = 'y';
    if isnumeric(analysis.data.y)
        encoding.y.type = 'quantitative';
    else
        encoding.y.type = 'nominal';
    end
end

function color_encoding = createColorEncoding(grouping)
    color_encoding = struct();
    color_encoding.field = 'color';
    color_encoding.type = 'nominal';
    
    % Create color scale based on actual data
    color_encoding.scale = struct();
    
    % Get unique color values and convert to strings
    if isnumeric(grouping.colorData)
        unique_colors = unique(grouping.colorData);
        color_encoding.scale.domain = arrayfun(@num2str, unique_colors, 'UniformOutput', false);
    else
        unique_colors = unique(grouping.colorData);
        color_encoding.scale.domain = cellstr(unique_colors);
    end
    
    % Default color palette - extend if needed
    default_colors = {'#fc4464', '#08bc4d', '#04b0fc', '#ff9500', '#9b59b6', '#e74c3c', '#2ecc71', '#3498db'};
    num_colors = length(color_encoding.scale.domain);
    color_encoding.scale.range = default_colors(1:min(num_colors, length(default_colors)));
end

%% ===== DATA PROCESSING =====

function vega_data = extractVegaData(analysis)
    x = analysis.data.x;
    y = analysis.data.y;
    colorData = analysis.grouping.colorData;
    hasColorGroup = analysis.grouping.hasColorGroup;
    
    % Handle different data types and clean data
    [x, y, colorData] = cleanAndProcessData(x, y, colorData, hasColorGroup);
    
    % Convert to Vega data format
    vega_data = [];
    for i = 1:length(x)
        dataPoint = struct();
        
        % Handle x values
        if isnumeric(x(i))
            dataPoint.x = x(i);
        else
            dataPoint.x = char(x(i));
        end
        
        % Handle y values
        if isnumeric(y(i))
            dataPoint.y = y(i);
        else
            dataPoint.y = char(y(i));
        end
        
        % Handle color grouping
        if hasColorGroup
            if isnumeric(colorData(i))
                dataPoint.color = num2str(colorData(i));
            else
                dataPoint.color = char(colorData(i));
            end
        end
        
        vega_data = [vega_data; dataPoint];
    end
end

function [x_clean, y_clean, color_clean] = cleanAndProcessData(x, y, colorData, hasColorGroup)
    % Handle different data types
    if isnumeric(x) && isnumeric(y)
        % Remove NaN and infinite values for numeric data
        validIndices = ~isnan(x) & ~isnan(y) & isfinite(x) & isfinite(y);
        
        % Check if any data was filtered out and warn user
        originalCount = length(x);
        filteredCount = sum(validIndices);
        if filteredCount < originalCount
            warning('gramm:VegaExport:InvalidData', ...
                'Removed %d data points containing NaN or infinite values (%d remaining)', ...
                originalCount - filteredCount, filteredCount);
        end
        
        x_clean = x(validIndices);
        y_clean = y(validIndices);
        if hasColorGroup
            color_clean = colorData(validIndices);
        else
            color_clean = colorData;
        end
    else
        % Convert non-numeric data to strings
        if ~isnumeric(x)
            x = string(x);
        end
        if ~isnumeric(y)
            y = string(y);
        end
        
        % Remove missing values
        validIndices = ~ismissing(x) & ~ismissing(y);
        x_clean = x(validIndices);
        y_clean = y(validIndices);
        if hasColorGroup
            color_clean = colorData(validIndices);
        else
            color_clean = colorData;
        end
    end
end

%% ===== VEGA SPECIFICATION GENERATION =====

function vega_spec = generateVegaSpecification(chart_spec, vega_data, params)
    % All chart layers now use Vega format
    if isempty(chart_spec.layers)
        error('No chart layers found');
    end
    
    % Use the first layer's Vega specification as base
    vega_spec = chart_spec.layers{1}.vegaSpec;
    
    % Update dimensions from params
    vega_spec.width = str2double(params.width);
    vega_spec.height = str2double(params.height);
    
    % Add the actual data to the Vega specification
    vega_spec.data{1}.values = vega_data;
    
    % Add title if specified
    if ~strcmp(params.title, 'Untitled')
        vega_spec.title = params.title;
    end
    
    % Update axis titles
    for i = 1:length(vega_spec.axes)
        if strcmp(vega_spec.axes{i}.orient, 'bottom')
            vega_spec.axes{i}.title = params.x_label;
        elseif strcmp(vega_spec.axes{i}.orient, 'left')
            vega_spec.axes{i}.title = params.y_label;
        end
    end
    
    % Handle multi-layer visualizations by combining marks
    if length(chart_spec.layers) > 1
        combined_marks = {};
        combined_scales = {};
        
        for i = 1:length(chart_spec.layers)
            layer_spec = chart_spec.layers{i}.vegaSpec;
            
            % Combine marks from all layers
            if isfield(layer_spec, 'marks')
                for j = 1:length(layer_spec.marks)
                    combined_marks{end+1} = layer_spec.marks{j};
                end
            end
            
            % Combine scales (avoiding duplicates)
            if isfield(layer_spec, 'scales')
                for j = 1:length(layer_spec.scales)
                    scale_name = layer_spec.scales{j}.name;
                    exists = false;
                    for k = 1:length(combined_scales)
                        if strcmp(combined_scales{k}.name, scale_name)
                            exists = true;
                            break;
                        end
                    end
                    if ~exists
                        combined_scales{end+1} = layer_spec.scales{j};
                    end
                end
            end
        end
        
        vega_spec.marks = combined_marks;
        vega_spec.scales = combined_scales;
    end
    
    % Add legend if color scale exists (multiple colors in data)
    vega_spec = addLegendIfNeeded(vega_spec, vega_data, params);
    
    % Store flag to indicate this is a Vega chart
    vega_spec.isVegaChart = true;
end


function vega_spec = addLegendIfNeeded(vega_spec, vega_data, params)
    % Check if there are multiple colors in the data
    hasMultipleColors = false;
    hasColorScale = false;
    
    % Check if there's a color scale defined
    if isfield(vega_spec, 'scales')
        for i = 1:length(vega_spec.scales)
            if strcmp(vega_spec.scales{i}.name, 'color')
                hasColorScale = true;
                break;
            end
        end
    end
    
    % Check if there are multiple unique color values in the data
    if ~isempty(vega_data) && isstruct(vega_data)
        if length(vega_data) > 1 && isfield(vega_data, 'color')
            % Extract all color values from struct array
            color_values = {vega_data.color};
            % Remove empty values
            color_values = color_values(~cellfun(@isempty, color_values));
            unique_colors = unique(color_values);
            hasMultipleColors = length(unique_colors) > 1;
        elseif isfield(vega_data, 'color') && iscell(vega_data.color)
            % Handle case where color is a cell array
            unique_colors = unique(vega_data.color);
            hasMultipleColors = length(unique_colors) > 1;
        end
    end
    
    % Add legend if we have both a color scale and multiple colors
    if hasColorScale && hasMultipleColors
        % Check if interactive legend is requested
        isInteractive = strcmpi(params.interactive, 'true');
        
        if isInteractive
            % Add interactive legend with signals and data
            vega_spec = addInteractiveLegend(vega_spec);
        else
            % Create standard legend specification
            legend = struct();
            legend.fill = 'color';
            legend.orient = 'right';
            legend.padding = 10;
            legend.cornerRadius = 5;
            legend.strokeColor = '#ddd';
            legend.fillColor = '#fff';
            legend.title = 'Color';
            legend.titlePadding = 5;
            legend.titleFontSize = 12;
            legend.titleFontWeight = 'bold';
            legend.labelFontSize = 11;
            legend.symbolSize = 100;
            legend.symbolType = 'circle';
            
            % Add legend to specification
            vega_spec.legends = {legend};
        end
        
        % Adjust padding to accommodate legend
        if isfield(vega_spec, 'padding')
            vega_spec.padding.right = 120; % Increase right padding for legend
        else
            vega_spec.padding = struct('left', 60, 'right', 120, 'top', 20, 'bottom', 60);
        end
    end
end

function vega_spec = addInteractiveLegend(vega_spec)
    % Add interactive legend functionality based on official Vega pattern
    
    % Add signals for interactive legend
    if ~isfield(vega_spec, 'signals')
        vega_spec.signals = {};
    end
    
    % Clear signal - resets selection when clicking empty space
    clear_signal = struct();
    clear_signal.name = 'clear';
    clear_signal.value = true;
    clear_signal.on = {struct('events', 'pointerup[!event.item]', 'update', 'true', 'force', true)};
    vega_spec.signals{end+1} = clear_signal;
    
    % Shift signal - detects if shift key is held during click
    shift_signal = struct();
    shift_signal.name = 'shift';
    shift_signal.value = false;
    shift_signal.on = {struct('events', '@legendSymbol:click, @legendLabel:click', 'update', 'event.shiftKey', 'force', true)};
    vega_spec.signals{end+1} = shift_signal;
    
    % Clicked signal - captures clicked legend item
    clicked_signal = struct();
    clicked_signal.name = 'clicked';
    clicked_signal.value = [];
    clicked_signal.on = {struct('events', '@legendSymbol:click, @legendLabel:click', 'update', '{value: datum.value}', 'force', true)};
    vega_spec.signals{end+1} = clicked_signal;
    
    % Add selected data for tracking clicked items
    if ~isfield(vega_spec, 'data')
        vega_spec.data = {};
    end
    
    selected_data = struct();
    selected_data.name = 'selected';
    selected_data.on = {
        struct('trigger', 'clear', 'remove', true);
        struct('trigger', '!shift', 'remove', true);
        struct('trigger', '!shift && clicked', 'insert', 'clicked');
        struct('trigger', 'shift && clicked', 'toggle', 'clicked')
    };
    vega_spec.data{end+1} = selected_data;
    
    % Create interactive legend
    legend = struct();
    legend.fill = 'color';
    legend.title = 'Color';
    legend.orient = 'right';
    legend.padding = 10;
    
    % Interactive legend encoding
    legend.encode = struct();
    
    % Interactive symbols
    legend.encode.symbols = struct();
    legend.encode.symbols.name = 'legendSymbol';
    legend.encode.symbols.interactive = true;
    legend.encode.symbols.update = struct();
    legend.encode.symbols.update.fill = struct('value', 'transparent');
    legend.encode.symbols.update.strokeWidth = struct('value', 2);
    legend.encode.symbols.update.opacity = {
        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.value)', 'value', 0.7);
        struct('value', 0.15)
    };
    legend.encode.symbols.update.size = struct('value', 64);
    
    % Interactive labels
    legend.encode.labels = struct();
    legend.encode.labels.name = 'legendLabel';
    legend.encode.labels.interactive = true;
    legend.encode.labels.update = struct();
    legend.encode.labels.update.opacity = {
        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.value)', 'value', 1);
        struct('value', 0.25)
    };
    
    vega_spec.legends = {legend};
    
    % Update marks to be interactive - modify existing marks
    if isfield(vega_spec, 'marks')
        for i = 1:length(vega_spec.marks)
            mark = vega_spec.marks{i};
            
            % Add interactivity to marks that use color encoding
            if isfield(mark, 'encode') && isfield(mark.encode, 'enter')
                if isfield(mark.encode.enter, 'fill') && isfield(mark.encode.enter.fill, 'scale') && strcmp(mark.encode.enter.fill.scale, 'color')
                    % Update fill encoding for interactivity
                    if ~isfield(mark.encode, 'update')
                        mark.encode.update = struct();
                    end
                    
                    mark.encode.update.opacity = {
                        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'value', 0.7);
                        struct('value', 0.15)
                    };
                    
                    mark.encode.update.fill = {
                        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'scale', 'color', 'field', 'color');
                        struct('value', '#ccc')
                    };
                    
                elseif isfield(mark.encode.enter, 'stroke') && isfield(mark.encode.enter.stroke, 'scale') && strcmp(mark.encode.enter.stroke.scale, 'color')
                    % Update stroke encoding for interactivity
                    if ~isfield(mark.encode, 'update')
                        mark.encode.update = struct();
                    end
                    
                    mark.encode.update.opacity = {
                        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'value', 0.7);
                        struct('value', 0.15)
                    };
                    
                    mark.encode.update.stroke = {
                        struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'scale', 'color', 'field', 'color');
                        struct('value', '#ccc')
                    };
                end
            end
            
            % Handle nested marks (for grouped charts like bars and lines)
            if isfield(mark, 'marks')
                for j = 1:length(mark.marks)
                    nested_mark = mark.marks{j};
                    if isfield(nested_mark, 'encode') && isfield(nested_mark.encode, 'enter')
                        if ~isfield(nested_mark.encode, 'update')
                            nested_mark.encode.update = struct();
                        end
                        
                        % Handle fill encoding (for bars)
                        if isfield(nested_mark.encode.enter, 'fill') && isfield(nested_mark.encode.enter.fill, 'scale') && strcmp(nested_mark.encode.enter.fill.scale, 'color')
                            nested_mark.encode.update.opacity = {
                                struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'value', 0.7);
                                struct('value', 0.15)
                            };
                            
                            nested_mark.encode.update.fill = {
                                struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'scale', 'color', 'field', 'color');
                                struct('value', '#ccc')
                            };
                        end
                        
                        % Handle stroke encoding (for lines)
                        if isfield(nested_mark.encode.enter, 'stroke') && isfield(nested_mark.encode.enter.stroke, 'scale') && strcmp(nested_mark.encode.enter.stroke.scale, 'color')
                            nested_mark.encode.update.opacity = {
                                struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'value', 0.7);
                                struct('value', 0.15)
                            };
                            
                            nested_mark.encode.update.stroke = {
                                struct('test', '!length(data(''selected'')) || indata(''selected'', ''value'', datum.color)', 'scale', 'color', 'field', 'color');
                                struct('value', '#ccc')
                            };
                        end
                        
                        mark.marks{j} = nested_mark;
                    end
                end
            end
            
            vega_spec.marks{i} = mark;
        end
    end
end

%% ===== FILE OUTPUT =====

function writeVegaFiles(vega_spec, params)
    % Create export directory if it doesn't exist
    if ~isempty(params.export_path) && ~exist(params.export_path, 'dir')
        mkdir(params.export_path);
    end
    
    % Remove the flag before writing JSON (all specs are now Vega)
    if isfield(vega_spec, 'isVegaChart')
        vega_spec = rmfield(vega_spec, 'isVegaChart');
    end
    
    % Convert specification to JSON
    vegaSpecJson = jsonencode(vega_spec);
    
    % Write JSON file
    jsonFile = fullfile(params.export_path, sprintf('%s.json', params.file_name));
    fileID = fopen(jsonFile, 'w+');
    fprintf(fileID, '%s', vegaSpecJson);
    fclose(fileID);
    
    % Write HTML file (always use Vega template now)
    htmlFile = fullfile(params.export_path, sprintf('%s.html', params.file_name));
    htmlContent = createVegaHTMLTemplate(params.file_name);
    
    fileID = fopen(htmlFile, 'w+');
    fprintf(fileID, '%s', htmlContent);
    fclose(fileID);
    
    fprintf('Vega specification successfully written to %s\n', jsonFile);
    fprintf('HTML file successfully written to %s\n', htmlFile);
end

function htmlContent = createVegaHTMLTemplate(file_name)
    % Vega HTML template for all chart types
    htmlContent = sprintf([ ...
        '<!DOCTYPE html>\n', ...
        '<html lang="en">\n', ...
        '<head>\n', ...
        '    <meta charset="UTF-8">\n', ...
        '    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n', ...
        '    <title>Vega Chart</title>\n', ...
        '    <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>\n', ...
        '    <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>\n', ...
        '</head>\n', ...
        '<body>\n', ...
        '    <div id="%s_chart"></div>\n', ...
        '    <script>\n', ...
        '        fetch("%s.json")\n', ...
        '            .then(response => response.json())\n', ...
        '            .then(spec => {\n', ...
        '                vegaEmbed("#%s_chart", spec, {\n', ...
        '                    actions: true,\n', ...
        '                    theme: "default",\n', ...
        '                    renderer: "canvas"\n', ...
        '                });\n', ...
        '            })\n', ...
        '            .catch(error => console.error("Error loading chart:", error));\n', ...
        '    </script>\n', ...
        '</body>\n', ...
        '</html>\n' ...
    ], file_name, file_name, file_name);
end