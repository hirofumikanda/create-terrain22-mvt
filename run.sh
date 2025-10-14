#!/bin/bash

# エントリスクリプト - 全ての指定された region のデータを処理
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
fi