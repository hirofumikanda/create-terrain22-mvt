# Terrain22 MVT 変換ツール

日本の国土地理院（GSI）が提供する地形分類データ（terrain2021）をMVTに変換するための地理空間データ処理パイプラインです。

## 概要

このツールは、国土地理院が提供する[地形分類データ](https://gisstar.gsi.go.jp/terrain2021/)を地域別にダウンロードし、ウェブマッピングアプリケーション用のベクタータイル（MVT形式）に変換します。

### データフロー
```
Shapefileデータ → GPKG → GeoJSON → MBTiles → PMTiles
```

## 機能

- **地域別処理**: 全世界を67の地域に分けて処理
- **バッチ処理**: 複数地域の一括処理に対応
- **並列処理**: 複数地域の同時処理で高速化
- **PMTiles統合**: 地域別PMTilesを全世界統合ファイルに結合
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

※地域番号は[国土地理院サイト](https://gisstar.gsi.go.jp/terrain2021/)を参照してください。

### 2. バッチ処理（高機能版）

```bash
# 67地域すべてを順番に処理（統合なし）
./run.sh

# 67地域すべてを処理して統合
./run.sh --merge

# 既存PMTilesの統合のみ
./run.sh --merge-only

# 特定地域のみ処理
./run.sh 41 42 43

# 特定地域を処理して統合
./run.sh --merge 41 42 43

# 並列処理（4つのジョブで全地域を同時実行）
./run.sh --parallel 4

# 並列処理で全地域を処理して統合
./run.sh --parallel 4 --merge

# 並列処理で特定地域を処理
./run.sh --parallel 2 41 42 43

# ヘルプ表示
./run.sh --help
```

### 3. PMTiles統合処理

```bash
# 既存の地域別PMTilesを統合
./merge_pmtiles.sh

# カスタムファイル名で統合
./merge_pmtiles.sh custom_terrain.pmtiles
```

## 出力データ

### ファイル形式
- **地域別出力**: `terrain22_{地域番号}.pmtiles`（個別地域データ）
- **統合出力**: `terrain22.pmtiles`（全地域統合データ）
- **中間ファイル**: 処理中に自動的に削除されます

### データ構造
各PMTilesファイルには `layer:terrain22` に以下のフィールドが含まれます：
- `geom`: ポリゴンジオメトリ
- `polyID`: ポリゴン識別子
- `Sinks`: ((Filled DEM) - (Original DEM)) > 0の地域は1
- `GCLUSTER15`: グローバルクラスタ15
- `GCLUSTER40`: グローバルクラスタ40

### ズームレベル
- **Z6-8**: 簡略化されたジオメトリ（広域表示用）
- **Z9-10**: 詳細なジオメトリ（詳細表示用）

### 統合処理の詳細
- **統合対象**: 正常に処理された地域のPMTilesファイル
- **統合方法**: PMTiles → MBTiles → tile-join → PMTiles の流れで統合
- **エラー処理**: 統合失敗時は中間ファイルを自動クリーンアップ
- **出力サイズ**: 全67地域統合時は数GB程度のファイルサイズ

## 処理の詳細

### データ処理パイプライン

1. **ダウンロード**: GSIサーバーからZIPファイルを取得
2. **解凍**: ShapefileとDBFファイルを展開
3. **GPKG変換**: 空間インデックス付きでGeoPackageに変換
4. **データ結合**: ポリゴンデータとクラスタデータをJOIN
5. **ジオメトリ簡略化**: Mapshaperで形状を保持しつつ簡略化
6. **タイル生成**: Tippecanoeでズームレベル別にタイル化
7. **PMTiles変換**: 最終的なPMTiles形式に変換
8. **統合処理**（オプション）: 地域別PMTilesを全国統合ファイルに結合

### 推奨ワークフロー

#### 段階的処理（推奨）
```bash
# 1. テスト用に数地域を処理
./run.sh 41 42 43

# 2. 結果確認後、全地域を並列処理
./run.sh --parallel 4

# 3. 処理完了後に統合
./merge_pmtiles.sh
```

#### 一括処理
```bash
# 全工程を一度に実行
./run.sh --parallel 4 --merge
```

## ライセンス

このツールは国土地理院の地形分類データを使用しています。データの利用については[国土地理院の公開ページ](https://gisstar.gsi.go.jp/terrain2021/)に従ってください。

## 関連リンク

- [国土地理院 地形分類データ](https://gisstar.gsi.go.jp/terrain2021/)
- [PMTiles仕様](https://github.com/protomaps/PMTiles)
- [Tippecanoe](https://github.com/felt/tippecanoe)
- [Mapshaper](https://github.com/mbloch/mapshaper)