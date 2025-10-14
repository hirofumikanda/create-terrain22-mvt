#!/bin/bash

# エントリスクリプト - 全ての指定された region のデータを処理
# 使用方法:
#   ./run.sh                      # 全地域を処理（統合なし）
#   ./run.sh --merge             # 全地域を処理して統合
#   ./run.sh --merge-only        # 統合のみ実行（変換処理はスキップ）

# 引数解析
MERGE_AFTER_CONVERSION=false
MERGE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --merge)
            MERGE_AFTER_CONVERSION=true
            shift
            ;;
        --merge-only)
            MERGE_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --merge         Process all regions and merge PMTiles"
            echo "  --merge-only    Only merge existing PMTiles (skip conversion)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Process all regions without merging"
            echo "  $0 --merge      # Process all regions and merge into terrain22.pmtiles"
            echo "  $0 --merge-only # Only merge existing PMTiles files"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [ "$MERGE_ONLY" = true ]; then
    echo "Starting PMTiles merge process only..."
    ./merge_pmtiles.sh
    exit $?
fi

echo "Starting terrain22 MVT conversion for multiple regions..."

# 処理対象の region 配列
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

# スクリプトのディレクトリに移動
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 成功・失敗カウンタ
SUCCESS_COUNT=0
FAILURE_COUNT=0
FAILED_REGIONS=()

echo "Processing ${#REGIONS[@]} regions..."
echo "Regions: ${REGIONS[*]}"
echo ""

# 各 region に対してconvert.shを実行
for region in "${REGIONS[@]}"; do
    echo "====================================="
    echo "Processing region: $region"
    echo "====================================="
    
    ./convert.sh "$region"
    
    if [ $? -eq 0 ]; then
        echo "✓ Region $region completed successfully!"
        echo "  Output file: terrain22_$region.pmtiles"
        ((SUCCESS_COUNT++))
    else
        echo "✗ Region $region failed!"
        FAILED_REGIONS+=("$region")
        ((FAILURE_COUNT++))
    fi
    echo ""
done

# 結果サマリー
echo "====================================="
echo "CONVERSION SUMMARY"
echo "====================================="
echo "Total regions processed: ${#REGIONS[@]}"
echo "Successful conversions: $SUCCESS_COUNT"
echo "Failed conversions: $FAILURE_COUNT"

if [ $FAILURE_COUNT -gt 0 ]; then
    echo "Failed regions: ${FAILED_REGIONS[*]}"
    echo ""
    echo "Some conversions failed. Please check the logs above."
    exit 1
else
    echo ""
    echo "All conversions completed successfully!"
    
    # 統合処理の実行判定
    if [ "$MERGE_AFTER_CONVERSION" = true ]; then
        echo ""
        echo "Starting PMTiles merge process..."
        ./merge_pmtiles.sh
        
        if [ $? -eq 0 ]; then
            echo "Merge process completed successfully!"
        else
            echo "Merge process failed!"
            exit 1
        fi
    else
        echo "Use './run.sh --merge' to merge all PMTiles files into terrain22.pmtiles"
        echo "Or run './merge_pmtiles.sh' separately to merge existing files"
    fi
fi