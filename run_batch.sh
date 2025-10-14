#!/bin/bash

# エントリスクリプト - 指定された region または全ての region を処理
# 使用方法:
#   ./run_batch.sh                    # 全ての region を順次処理
#   ./run_batch.sh 41 42 43          # 指定した region のみ処理
#   ./run_batch.sh --parallel 4      # 4つの並列処理で全 region を処理
#   ./run_batch.sh --parallel 2 41 42 43  # 2つの並列処理で指定 region を処理

# デフォルトの処理対象 region 配列
DEFAULT_REGIONS=(
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

# 引数解析
PARALLEL_JOBS=1
REGIONS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --parallel)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--parallel N] [regions...]"
            echo ""
            echo "Options:"
            echo "  --parallel N    Process N regions in parallel (default: 1)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                        # Process all regions sequentially"
            echo "  $0 41 42 43              # Process only regions 41, 42, 43"
            echo "  $0 --parallel 4          # Process all regions with 4 parallel jobs"
            echo "  $0 --parallel 2 41 42    # Process regions 41, 42 with 2 parallel jobs"
            exit 0
            ;;
        *)
            REGIONS+=("$1")
            shift
            ;;
    esac
done

# region が指定されていない場合はデフォルトを使用
if [ ${#REGIONS[@]} -eq 0 ]; then
    REGIONS=("${DEFAULT_REGIONS[@]}")
fi

echo "Starting terrain22 MVT conversion..."
echo "Regions to process: ${REGIONS[*]}"
echo "Parallel jobs: $PARALLEL_JOBS"
echo ""

# 並列処理関数
process_region() {
    local region=$1
    echo "Processing region: $region (PID: $$)"
    
    if ./convert.sh "$region"; then
        echo "✓ Region $region completed successfully! (Output: terrain22_$region.pmtiles)"
        return 0
    else
        echo "✗ Region $region failed!"
        return 1
    fi
}

export -f process_region
export SCRIPT_DIR

# 結果追跡用の一時ディレクトリ
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# 並列処理または順次処理
if [ "$PARALLEL_JOBS" -eq 1 ]; then
    # 順次処理
    SUCCESS_COUNT=0
    FAILED_REGIONS=()
    
    for region in "${REGIONS[@]}"; do
        echo "====================================="
        if process_region "$region"; then
            ((SUCCESS_COUNT++))
        else
            FAILED_REGIONS+=("$region")
        fi
        echo ""
    done
    
    FAILURE_COUNT=${#FAILED_REGIONS[@]}
else
    # 並列処理
    echo "Using parallel processing with $PARALLEL_JOBS jobs..."
    printf '%s\n' "${REGIONS[@]}" | xargs -n 1 -P "$PARALLEL_JOBS" -I {} bash -c 'process_region "$@"' _ {}
    
    # 結果ファイルから成功・失敗を集計（簡易版）
    SUCCESS_COUNT=0
    FAILURE_COUNT=0
    FAILED_REGIONS=()
    
    # 出力ファイルの存在で成功判定（簡易的）
    for region in "${REGIONS[@]}"; do
        if [ -f "terrain22_$region.pmtiles" ]; then
            ((SUCCESS_COUNT++))
        else
            ((FAILURE_COUNT++))
            FAILED_REGIONS+=("$region")
        fi
    done
fi

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