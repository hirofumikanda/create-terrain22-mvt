# Terrain22 MVT 変換ツール

日本の国土地理院（GSI）が提供する地形分類データ（terrain2021）をMVTに変換するための地理空間データ処理パイプラインです。

## 概要

このツールは、世界の地形分類データを地域別にダウンロードし、ウェブマッピングアプリケーション用のベクタータイル（MVT形式）に変換します。

### データフロー
```
Shapefileデータ → GPKG → GeoJSON → MBTiles → PMTiles
```

## 機能

- **地域別処理**: 全世界を67の地域に分けて処理
- **バッチ処理**: 複数地域の一括処理に対応
- **並列処理**: 複数地域の同時処理で高速化
- **自動クリーンアップ**: 中間ファイルの自動削除
- **エラー追跡**: 失敗した地域の詳細レポート

## 必要な依存関係

以下のツールがシステムにインストールされている必要があります：

```bash
# GDAL/OGR（地理空間データ変換）
sudo apt-get install gdal-bin

# Mapshaper（ジオメトリ簡略化）
npm install -g mapshaper

# Tippecanoe（ベクタータイル生成）
# https://github.com/felt/tippecanoe のインストール手順に従ってください

# PMTiles（タイル形式変換）
# https://github.com/protomaps/go-pmtiles のインストール手順に従ってください

# 標準ツール
wget unzip
```

## 使用方法

### 1. 単一地域の処理

```bash
# 地域41（例：日本）のデータを処理
./convert.sh 41
```

### 2. 全地域の順次処理

```bash
# 67地域すべてを順番に処理
./run.sh
```

### 3. バッチ処理（高機能版）

```bash
# 全地域を順次処理
./run_batch.sh

# 特定地域のみ処理
./run_batch.sh 41 42 43

# 並列処理（4つのジョブで全地域を同時実行）
./run_batch.sh --parallel 4

# 並列処理で特定地域を処理
./run_batch.sh --parallel 2 41 42 43

# ヘルプ表示
./run_batch.sh --help
```

## 出力データ

### ファイル形式
- **最終出力**: `terrain22_{地域番号}.pmtiles`
- **中間ファイル**: 処理中に自動的に削除されます

### データ構造
各PMTilesファイルには以下のフィールドが含まれます：
- `geom`: ポリゴンジオメトリ
- `polyID`: ポリゴン識別子
- `Sinks`: ((Filled DEM) - (Original DEM)) > 0の地域は1
- `GCLUSTER15`: グローバルクラスタ15
- `GCLUSTER40`: グローバルクラスタ40

### ズームレベル
- **Z6-8**: 簡略化されたジオメトリ（広域表示用）
- **Z9-10**: 詳細なジオメトリ（詳細表示用）

## 処理の詳細

### データ処理パイプライン

1. **ダウンロード**: GSIサーバーからZIPファイルを取得
2. **解凍**: ShapefileとDBFファイルを展開
3. **GPKG変換**: 空間インデックス付きでGeoPackageに変換
4. **データ結合**: ポリゴンデータとクラスタデータをJOIN
5. **ジオメトリ簡略化**: Mapshaperで形状を保持しつつ簡略化
6. **タイル生成**: Tippecanoeでズームレベル別にタイル化
7. **PMTiles変換**: 最終的なPMTiles形式に変換

## ライセンス

このツールは国土地理院の地形分類データを使用しています。データの利用については[国土地理院の公開ページ](https://gisstar.gsi.go.jp/terrain2021/)に従ってください。

## 関連リンク

- [国土地理院 地形分類データ](https://gisstar.gsi.go.jp/terrain2021/)
- [PMTiles仕様](https://github.com/protomaps/PMTiles)
- [Tippecanoe](https://github.com/felt/tippecanoe)
- [Mapshaper](https://github.com/mbloch/mapshaper)