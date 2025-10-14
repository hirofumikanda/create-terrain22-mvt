# Copilot Instructions for Terrain22 MVT Project

## Project Overview
This is a geospatial data processing pipeline that converts Japanese terrain data (terrain2021) from GSI (Geospatial Information Authority of Japan) into PMTiles format for web mapping applications.

## Architecture & Data Flow

**Core Pipeline**: `Raw Shapefile → GPKG → GeoJSON → MBTiles → PMTiles`

1. **Data Source**: Downloads region-specific ZIP files from `https://gisstar.gsi.go.jp/terrain2021/Poly_{REGION}.zip`
2. **Processing Flow** (in `convert.sh`):
   - Extract shapefile and DBF files from ZIP
   - Convert to GPKG with spatial indexing using `ogr2ogr`
   - JOIN polygon data with cluster data via `polyID`
   - Export to GeoJSON with specific field selection
   - Simplify geometry using `mapshaper` (0.003 tolerance)
   - Create zoom-level specific tiles using `tippecanoe`
   - Convert final MBTiles to PMTiles format

## Key Components

### `convert.sh` - Core Processing Script
- **Single region processor**: Takes region number as argument (e.g., `./convert.sh 41`)
- **Critical dependencies**: `ogr2ogr`, `mapshaper`, `tippecanoe`, `tile-join`, `pmtiles`
- **Temporary files**: Uses `work.gpkg` as intermediate storage (always cleaned up)
- **Output naming**: `terrain22_{REGION}.pmtiles`

### Region System
- **67 supported regions**: 11-18, 21-29, 31-36, 41-49, 51-57+56_1+56_2, 61-67, 71-78, 81-86, 91, 101-106
- **Special case**: Region 56 has two variants (`56_1`, `56_2`)
- **Region array pattern**: Defined in both `run.sh` and `run_batch.sh` with identical structure

### Batch Processing Scripts
- **`run.sh`**: Sequential processing of all 67 regions with progress tracking
- **`run_batch.sh`**: Advanced batch processor with parallel execution support
  - Supports `--parallel N` for concurrent processing
  - Accepts specific region lists as arguments
  - Includes comprehensive error reporting and success/failure tracking

### PMTiles Merge Processing
- **`merge_pmtiles.sh`**: Dedicated script for consolidating regional PMTiles
  - **Input**: Individual `terrain22_{region}.pmtiles` files
  - **Output**: Single `terrain22.pmtiles` unified file
  - **Process**: PMTiles → MBTiles → tile-join → PMTiles conversion flow
  - **Error handling**: Automatic cleanup of intermediate files on failure
  - **Customizable output**: Accepts custom filename as argument

## Critical Workflows

### Single Region Processing
```bash
./convert.sh 41  # Process region 41 only
```

### Batch Processing Options
```bash
./run.sh                           # All regions sequentially
./run.sh --merge                   # All regions with post-processing merge
./run.sh --merge-only              # Merge existing PMTiles only
./run_batch.sh                     # All regions with advanced logging
./run_batch.sh 41 42 43           # Specific regions only
./run_batch.sh --parallel 4        # Parallel processing (4 jobs)
./run_batch.sh --parallel 4 --merge # Parallel with automatic merge
```

### PMTiles Merge Workflows
```bash
./merge_pmtiles.sh                 # Merge with default filename
./merge_pmtiles.sh custom.pmtiles  # Merge with custom filename
```

### Recommended Staged Processing
```bash
# 1. Test with few regions
./run_batch.sh 41 42 43
# 2. Process all regions in parallel
./run_batch.sh --parallel 4
# 3. Merge results
./merge_pmtiles.sh
```

## Project-Specific Patterns

### Error Handling Strategy
- **Fail-fast**: `convert.sh` exits on any command failure
- **Batch resilience**: Batch scripts continue processing remaining regions after failures
- **Cleanup guarantee**: Temporary files always removed, even on failure

### Tiling Strategy
- **Two zoom ranges**: Z6-8 (simplified) and Z9-10 (detailed)
- **No simplification in tippecanoe**: Geometry simplification handled by mapshaper only
- **Layer naming**: Always uses `-l terrain22` layer name
- **Size limits disabled**: `--no-tile-size-limit` and `--no-feature-limit` for large datasets

### File Management
- **Intermediate cleanup**: All temporary files (`.geojson`, `.mbtiles`, `.gpkg`) removed after processing
- **Final output**: Only `.pmtiles` files retained (regional and merged)
- **Gitignore pattern**: All processing artifacts ignored except final PMTiles
- **Merge process**: Regional PMTiles → MBTiles → tile-join → unified PMTiles

### Merge Strategy
- **Format conversion requirement**: PMTiles must be converted to MBTiles for tile-join compatibility
- **Automatic cleanup**: Intermediate MBTiles files removed after successful merge
- **Error recovery**: Failed merges trigger cleanup of partial results
- **Conditional execution**: Merge only runs if regional processing succeeds

## Key Dependencies & Tools

- **GDAL/OGR**: Primary geospatial data conversion (`ogr2ogr`, `ogrinfo`)
- **Mapshaper**: Geometry simplification with shape preservation
- **Tippecanoe**: Vector tile generation from Mapbox
- **PMTiles**: Modern tile format conversion
- **Standard Unix tools**: `wget`, `unzip`, `rm` for data handling

## Field Selection Pattern
The pipeline always selects these specific fields for final output:
- `geom`, `polyID`, `Sinks`, `Gcluster15`, `Gcluster40`

When modifying field selection, update the `-select` parameter in the `ogr2ogr` GeoJSON export command.

## Performance Considerations
- **Memory usage**: Large regions may require significant RAM for tippecanoe processing
- **Disk space**: Each region generates ~100MB+ of temporary files during processing
- **Network**: Downloads can be 10-50MB per region ZIP file
- **Parallel processing**: Use `--parallel` cautiously based on available system resources