# Gramm to Vega Translator

**Goal**: Complete translator supporting ALL examples in @html/examples.html - full gramm ecosystem with 30+ chart types and statistical transformations.

## Architecture Status

### ✅ Phase 1 Complete (Session 1)
- **Core geometric objects**: point, line, bar, jitter, raster, swarm
- **Modular architecture**: Complete export_vega.m with all planned functions  
- **Comprehensive testing**: 15 test cases with HTML index browser
- **Production fixes**: Resolved MATLAB parameter/color encoding issues

### 🔄 Next Phases
- **Phase 2**: Statistical transformations (stat_glm, stat_smooth, stat_bin, etc.)
- **Phase 3**: Advanced visualizations (stat_violin, stat_boxplot, stat_bin2d)
- **Phase 4**: Layout/interactivity (facet_grid, facet_wrap, reference elements)
- **Phase 5**: Full feature parity with html/examples.html

## Key Lessons
- **MATLAB gotchas**: Use `num2str()` not `char()`, careful varargin unpacking
- **User workflow**: Complete implementations + comprehensive testing preferred
- **Validation**: HTML index pages make testing much more user-friendly

## Never-Dos
- ❌ Never modify files under `@gramm/` except `@gramm/export_vega.m`
- ❌ Never change existing API or break backward compatibility
- ❌ Never call MATLAB in console for testing