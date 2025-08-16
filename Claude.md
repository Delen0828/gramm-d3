# Gramm to Vega Translator - Complete Implementation Plan

## Project Overview

**Goal**: Create a comprehensive translator that takes gramm() information (e.g., g.results()) and translates it to Vega specifications. The ultimate objective is to support **ALL examples in @html/examples.html**.

**Key Insight**: @@gramm/export_d3.m is NOT a complete implementation - it only supports 4 basic chart types. The true scope is the entire gramm ecosystem with 30+ chart types and statistical transformations.

## Complete Gramm Feature Scope

### Geometric Objects (geom_*)
- **geom_point** - Scatter plots with size, color, alpha mappings
- **geom_line** - Line plots with multiple series and grouping
- **geom_bar** - Bar charts (stacked, dodged, grouped)
- **geom_jitter** - Jittered points with width/height control
- **geom_swarm** - Beeswarm plots (fan, hex, square methods)
- **geom_raster** - Strip/raster plots for continuous data
- **geom_interval** - Custom confidence intervals (errorbar, area, lines)
- **geom_label** - Text labels and annotations
- **geom_abline** - Diagonal reference lines
- **geom_vline/geom_hline** - Vertical/horizontal reference lines
- **geom_funline** - Custom function lines
- **geom_polygon** - Background polygons and decorations

### Statistical Transformations (stat_*)
- **stat_glm** - Generalized linear models with confidence intervals
- **stat_smooth** - Data smoothing (Savitzky-Golay, LOESS, moving average)
- **stat_fit** - Custom function fitting
- **stat_bin** - Histograms with multiple normalization options
- **stat_density** - Kernel density estimation
- **stat_violin** - Violin plots with normalization options
- **stat_boxplot** - Box plots with notch support
- **stat_summary** - Summary statistics with multiple geoms
- **stat_bin2d** - 2D histograms and heatmaps
- **stat_ellipse** - Confidence ellipses
- **stat_qq** - Q-Q plots for distribution analysis
- **stat_cornerhist** - Corner histograms

### Layout and Grouping
- **facet_grid** - Grid-based subplots with scaling options
- **facet_wrap** - Wrapped subplots
- **Visual grouping**: color, lightness, size, marker, linestyle
- **update()** - Superimposed plots with different groupings

### Customization
- **set_color_options** - Custom color maps and legends
- **set_order_options** - Element ordering control
- **set_point_options** - Point styling
- **set_line_options** - Line styling
- **axe_property** - Axis customization

## Architecture Design

### Core Translator Functions

```matlab
function export_vega(g, varargin)
    % Main entry point - maintains exact same API as export_d3
    
    % 1. Parse input parameters (same as export_d3)
    params = parseInputParameters(varargin);
    
    % 2. Analyze gramm object completely
    gramm_analysis = analyzeGrammObject(g);
    
    % 3. Detect all chart types and layers
    chart_spec = detectAllChartTypes(gramm_analysis);
    
    % 4. Extract and process data
    vega_data = extractVegaData(gramm_analysis);
    
    % 5. Generate Vega specification
    vega_spec = generateVegaSpecification(chart_spec, vega_data, params);
    
    % 6. Write output files
    writeVegaFiles(vega_spec, params);
end
```

### 1. Gramm Object Analysis (`analyzeGrammObject`)

```matlab
function analysis = analyzeGrammObject(g)
    analysis = struct();
    
    % Extract aesthetic mappings
    analysis.aes = extractAesthetics(g);
    
    % Analyze g.results to detect all geom_* and stat_* handles
    analysis.geoms = detectGeomHandles(g.results);
    analysis.stats = detectStatHandles(g.results);
    
    % Extract faceting information
    analysis.facets = extractFacetInfo(g);
    
    % Get data and handle complex formats (2D arrays, cells)
    analysis.data = extractComplexData(g);
    
    % Detect grouping variables and color scales
    analysis.grouping = extractGroupingInfo(g);
end
```

### 2. Chart Type Detection (`detectAllChartTypes`)

```matlab
function chart_spec = detectAllChartTypes(analysis)
    chart_spec = struct();
    chart_spec.layers = {};
    
    % Check for all possible geom handles
    geom_types = fieldnames(analysis.geoms);
    for i = 1:length(geom_types)
        switch geom_types{i}
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
            % ... continue for all 12 geom types
        end
    end
    
    % Check for all stat handles and add statistical layers
    stat_types = fieldnames(analysis.stats);
    for i = 1:length(stat_types)
        switch stat_types{i}
            case 'stat_glm_handle'
                chart_spec.layers{end+1} = createGLMLayer(analysis);
            case 'stat_smooth_handle'
                chart_spec.layers{end+1} = createSmoothLayer(analysis);
            case 'stat_bin_handle'
                chart_spec.layers{end+1} = createHistogramLayer(analysis);
            case 'stat_density_handle'
                chart_spec.layers{end+1} = createDensityLayer(analysis);
            % ... continue for all 12 stat types
        end
    end
    
    % Handle faceting
    if ~isempty(analysis.facets)
        chart_spec.facet = createFacetSpec(analysis.facets);
    end
end
```

### 3. Data Processing (`extractVegaData`)

```matlab
function vega_data = extractVegaData(analysis)
    % Handle complex data formats from gramm
    raw_data = analysis.data;
    
    % Process 2D arrays and cell arrays (for repeated trajectories)
    if iscell(raw_data.x) || size(raw_data.x, 2) > 1
        vega_data = processComplexData(raw_data);
    else
        vega_data = processSimpleData(raw_data);
    end
    
    % Add statistical computations for stat_* layers
    vega_data = addStatisticalTransforms(vega_data, analysis);
    
    % Handle grouping variables
    vega_data = processGroupingVariables(vega_data, analysis.grouping);
end
```

### 4. Vega Specification Generation

```matlab
function vega_spec = generateVegaSpecification(chart_spec, vega_data, params)
    % Create base Vega specification
    vega_spec = struct();
    vega_spec.schema = 'https://vega.github.io/schema/Vega/v5.json';
    vega_spec.title = params.title;
    vega_spec.width = str2double(params.width);
    vega_spec.height = str2double(params.height);
    vega_spec.data.values = vega_data;
    
    % Handle multi-layer visualizations
    if length(chart_spec.layers) > 1
        vega_spec.layer = chart_spec.layers;
    else
        % Single layer - merge into main spec
        layer_spec = chart_spec.layers{1};
        vega_spec.mark = layer_spec.mark;
        vega_spec.encoding = layer_spec.encoding;
    end
    
    % Add faceting if needed
    if isfield(chart_spec, 'facet')
        vega_spec.facet = chart_spec.facet;
    end
    
    % Add interactive features
    vega_spec = addInteractivity(vega_spec, chart_spec);
end
```

## Detailed Implementation Functions

### Chart Type Implementations

#### 1. Basic Charts
```matlab
function layer = createPointLayer(analysis)
function layer = createLineLayer(analysis)
function layer = createBarLayer(analysis)
```

#### 2. Distribution Charts
```matlab
function layer = createJitterLayer(analysis)
function layer = createSwarmLayer(analysis)
function layer = createViolinLayer(analysis)
function layer = createBoxplotLayer(analysis)
```

#### 3. Statistical Charts
```matlab
function layer = createGLMLayer(analysis)
function layer = createSmoothLayer(analysis)
function layer = createHistogramLayer(analysis)
function layer = createDensityLayer(analysis)
function layer = create2DHistogramLayer(analysis)
```

#### 4. Reference Elements
```matlab
function layer = createReferenceLineLayer(analysis)
function layer = createIntervalLayer(analysis)
function layer = createPolygonLayer(analysis)
```

### Statistical Processing Functions

```matlab
function data = computeLinearRegression(data, grouping)
function data = computeDensityEstimate(data, bandwidth)
function data = computeHistogramBins(data, nbins, normalization)
function data = computeBoxplotStats(data)
function data = computeViolinStats(data)
function data = computeSmoothingSpline(data, method)
```

### Data Format Handlers

```matlab
function data = processRepeatedTrajectories(cell_data, grouping)
function data = process2DArrays(array_data, grouping)
function data = handleMissingData(data)
function data = processCustomIntervals(data, ymin, ymax)
```

### Faceting System

```matlab
function facet_spec = createFacetGrid(row_var, col_var, options)
function facet_spec = createFacetWrap(wrap_var, ncols, options)
```

### Aesthetic Mapping System

```matlab
function encoding = mapColorAesthetic(data, color_var, color_options)
function encoding = mapSizeAesthetic(data, size_var, size_options)
function encoding = mapShapeAesthetic(data, marker_var, marker_options)
function encoding = mapAlphaAesthetic(data, alpha_var)
```

## Implementation Priority

### Phase 1: Core Infrastructure (Week 1)
1. **analyzeGrammObject()** - Complete gramm object parsing
2. **detectAllChartTypes()** - Handle detection for all 24 chart types
3. **extractVegaData()** - Data processing pipeline
4. **Basic chart types**: point, line, bar, jitter

### Phase 2: Statistical Transformations (Week 2)
1. **stat_glm** - Linear regression with confidence intervals
2. **stat_smooth** - Data smoothing
3. **stat_bin** - Histograms with multiple options
4. **stat_density** - Kernel density estimation
5. **stat_summary** - Summary statistics

### Phase 3: Advanced Visualizations (Week 3)
1. **stat_violin** - Violin plots
2. **stat_boxplot** - Box plots
3. **stat_bin2d** - 2D histograms and heatmaps
4. **geom_swarm** - Beeswarm plots
5. **Complex data formats** - 2D arrays, cell arrays

### Phase 4: Layout and Interactivity (Week 4)
1. **facet_grid** and **facet_wrap** - Subplot systems
2. **Advanced interactivity** - Selection, brushing, linking
3. **Reference elements** - Lines, intervals, polygons
4. **update()** method - Superimposed plots

### Phase 5: Polish and Edge Cases (Week 5)
1. **Aesthetic mapping system** - Complete color, size, shape handling
2. **Error handling** - Graceful degradation
3. **Performance optimization** - Large datasets
4. **Edge cases** - Complex examples from html/examples.html

## Success Criteria

### Functional Requirements
- **100% of examples in html/examples.html supported**
- All 12 geom_* types implemented
- All 12 stat_* types implemented
- Complete faceting system
- Full aesthetic mapping (color, size, shape, alpha, etc.)

### Technical Requirements
- Maintains exact same API as export_d3()
- Self-contained HTML+JSON output
- Vega 5.x compliance
- Performance suitable for typical gramm datasets

### Never-Dos (Unchanged)
- ❌ **NEVER modify any files under `@gramm/` except `@gramm/export_vega.m`**
- ❌ **NEVER change the existing API or function signature**
- ❌ **NEVER modify core gramm functionality**
- ❌ **NEVER break backward compatibility**
- ❌ **NEVER calls MATLAB in console to for testing**


## Timeline: 5 Weeks

This represents a significant expansion from the original scope due to the comprehensive nature of the gramm ecosystem. The translator must handle the full grammar of graphics implementation, not just the 4 basic chart types in export_d3.m.

---

# Session Experience & Lessons Learned

## Phase 1 Implementation Completed ✅ (Session 1)

### What We Accomplished
1. **✅ Complete modular architecture** - Implemented the full `export_vega.m` with all planned functions
2. **✅ Core geometric objects** - All 6 basic geom_* types working (point, line, bar, jitter, raster, swarm)
3. **✅ Comprehensive test suite** - 12 test cases covering all major functionality
4. **✅ HTML index page** - Professional test results browser with hyperlinks
5. **✅ Production-ready fixes** - Resolved all critical bugs for release

### Critical Issues Resolved

#### 1. **MATLAB Switch Statement Syntax** 
- **Problem**: `varargin` was passed as nested cell array causing "SWITCH expression must be a scalar" error
- **Root Cause**: Function signature mismatch between call and parameter parsing
- **Solution**: Fixed parameter unpacking: `args = varargin{1}; param_name = args{i};`
- **Lesson**: Always validate MATLAB function parameter handling with debug output

#### 2. **Color Data Encoding** 
- **Problem**: Numeric color values `[4,6,8]` converted to ASCII escape sequences `\u0004\u0006\u0008`
- **Root Cause**: Used `char()` instead of `num2str()` for numeric-to-string conversion
- **Solution**: Conditional conversion with type checking
- **Lesson**: MATLAB type conversion requires explicit handling for JSON output

### User Collaboration Patterns

#### Effective Communication Style
- **Concise problem reporting**: "All cases with multi color is not working" with specific error details
- **Clear validation requests**: "Can you let vega_test.m generate HTML to hyperlink all outputs?"
- **Immediate error feedback**: Direct copy-paste of JavaScript console errors
- **Practical testing**: Focus on real-world usage scenarios

#### Preferred Workflow
1. **Implement complete functionality** before testing (not incremental)
2. **Provide comprehensive test coverage** with visual validation tools
3. **Fix issues systematically** with targeted test cases
4. **Document lessons learned** for future reference

### Technical Architecture Insights

#### What Worked Well
- **Modular function design** - Easy to debug individual components
- **Comprehensive test coverage** - Caught all edge cases efficiently  
- **HTML index generation** - Made validation much more user-friendly
- **Error handling with debug output** - Enabled rapid issue identification

#### MATLAB-Specific Gotchas
1. **Cell array handling**: Always check if data is nested vs. flat
2. **Type conversion**: Use `num2str()` for numbers, `char()` for strings only
3. **JSON structure**: MATLAB structs need careful array/object distinction
4. **Function parameters**: `varargin` handling requires explicit unpacking

### Next Session Preparation
- Phase 1 complete and production-ready
- All 6 basic geometric objects fully functional
- Foundation ready for Phase 2: Statistical Transformations
- User prefers complete implementations with thorough testing

### User Instructions Understanding
- **Quality over speed**: User values working, well-tested implementations
- **Visual validation important**: Always provide easy ways to verify results
- **Real-world scenarios**: Test with actual use cases, not toy examples
- **Documentation appreciated**: Update plans and track lessons learned
- **Collaborative debugging**: User will test and provide specific error feedback