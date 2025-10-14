#!/bin/bash

# PMTiles統合スクリプト
# 使用方法: ./merge_pmtiles.sh [output_filename]

# 引数で出力ファイル名を指定可能（デフォルト: terrain22.pmtiles）
OUTPUT_FILE="${1:-terrain22.pmtiles}"

# 処理対象の region 配列（run.sh/run_batch.shと同じ）
REGIONS=(
    11 12 13 14 15 16 17 18
    21 22 23 24 25 26 27 28 29
    31 32 33 34 35 36
    41 42 43 44 45 46 47 48 49
    51 52 53 54 55 56_1 56_2 57
    61 62 63 64 65 66 67
    71 72 73 74 75 76 77 78
    81 82 83 84 85 86
    91
    101 102 103 104 105 106
)

echo "====================================="
echo "MERGING PMTILES"
echo "====================================="
echo "Merging all regional PMTiles into $OUTPUT_FILE..."

# 成功した地域のPMTilesファイルを収集
PMTILES_FILES=()
for region in "${REGIONS[@]}"; do
    if [ -f "terrain22_$region.pmtiles" ]; then
        PMTILES_FILES+=("terrain22_$region.pmtiles")
    fi
done

if [ ${#PMTILES_FILES[@]} -eq 0 ]; then
    echo "No PMTiles files found to merge."
    echo "Make sure you have run the conversion process first."
    exit 1
fi

echo "Found ${#PMTILES_FILES[@]} PMTiles files to merge..."

# tile-joinで統合（PMTilesの場合は一度MBTilesに変換してから統合）
echo "Converting PMTiles to MBTiles for merging..."
MBTILES_FILES=()
for pmtiles_file in "${PMTILES_FILES[@]}"; do
    mbtiles_file="${pmtiles_file%.pmtiles}.mbtiles"
    echo "Converting $pmtiles_file to $mbtiles_file..."
    
    if ! pmtiles convert "$pmtiles_file" "$mbtiles_file"; then
        echo "Error: Failed to convert $pmtiles_file to MBTiles"
        # クリーンアップ
        for cleanup_file in "${MBTILES_FILES[@]}"; do
            rm -f "$cleanup_file"
        done
        exit 1
    fi
    
    MBTILES_FILES+=("$mbtiles_file")
done

echo "Joining MBTiles files..."
if ! tile-join --force --no-tile-size-limit -o "${OUTPUT_FILE%.pmtiles}_merged.mbtiles" "${MBTILES_FILES[@]}"; then
    echo "Error: Failed to join MBTiles files"
    # クリーンアップ
    for mbtiles_file in "${MBTILES_FILES[@]}"; do
        rm -f "$mbtiles_file"
    done
    exit 1
fi

echo "Converting merged MBTiles to PMTiles..."
if ! pmtiles convert "${OUTPUT_FILE%.pmtiles}_merged.mbtiles" "$OUTPUT_FILE"; then
    echo "Error: Failed to convert merged MBTiles to PMTiles"
    # クリーンアップ
    rm -f "${OUTPUT_FILE%.pmtiles}_merged.mbtiles"
    for mbtiles_file in "${MBTILES_FILES[@]}"; do
        rm -f "$mbtiles_file"
    done
    exit 1
fi

# 中間ファイルをクリーンアップ
echo "Cleaning up temporary files..."
rm -f "${OUTPUT_FILE%.pmtiles}_merged.mbtiles"
for mbtiles_file in "${MBTILES_FILES[@]}"; do
    rm -f "$mbtiles_file"
done

echo "✓ Successfully created $OUTPUT_FILE!"
echo "  Final output: $OUTPUT_FILE"
echo "  Merged regions: ${#PMTILES_FILES[@]}"