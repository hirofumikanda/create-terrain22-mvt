#!/bin/bash

# 引数チェック
if [ $# -ne 1 ]; then
    echo "Usage: $0 <region_number>"
    echo "Example: $0 41"
    exit 1
fi

REGION=$1

# ダウンロードと解凍
echo "Downloading and extracting data for region ${REGION}..."
wget https://gisstar.gsi.go.jp/terrain2021/Poly_${REGION}.zip
unzip Poly_${REGION}.zip
rm -f Poly_${REGION}.zip

# GPKGに変換
echo "Converting Poly_${REGION}.shp to GPKG..."
ogr2ogr -progress -f GPKG work.gpkg Poly_${REGION}/Poly_${REGION}.shp \
  -s_srs Poly_${REGION}/Poly_${REGION}.prj -t_srs EPSG:4326 \
  -nln poly_${REGION} -nlt PROMOTE_TO_MULTI -dim 2 -overwrite

echo "Converting GlobalCluster_${REGION}.dbf to GPKG..."
ogr2ogr -progress -f GPKG work.gpkg Poly_${REGION}/GlobalCluster_${REGION}.dbf \
  -nln globalcluster_${REGION} -update

rm -rf Poly_${REGION}

# インデックス作成
echo "Creating indexes..."
ogrinfo work.gpkg -sql "CREATE INDEX IF NOT EXISTS idx_p_polyid ON poly_${REGION}(polyID)" -dialect SQLite
ogrinfo work.gpkg -sql "CREATE INDEX IF NOT EXISTS idx_gc_polyid ON globalcluster_${REGION}(polyID)" -dialect SQLite

# JOIN結果をGPKG内に物理テーブル化
echo "Joining tables and creating new layer..."
ogr2ogr -f GPKG work.gpkg work.gpkg \
  -nln poly_${REGION}_joined -overwrite \
  -dialect SQLite \
  -sql "SELECT p.geom AS geom,
               p.polyID, p.COMID, p.CONVEXITY, p.lnHAND, p.lnSLOPE, p.Sinks, p.TEXTURE, p.area,
               gc.Gcluster15, gc.Gcluster40
        FROM poly_${REGION} p
        LEFT JOIN globalcluster_${REGION} gc ON p.polyID = gc.polyID"

# GeoJSONでエクスポート
echo "Exporting joined data to GeoJSONSeq..."
ogr2ogr -progress -f GeoJSONSeq Poly_${REGION}.geojson work.gpkg poly_${REGION}_joined \
  -select geom,polyID,Sinks,Gcluster15,Gcluster40

rm -f work.gpkg

# 簡略化してGeoJSONでエクスポート
echo "Simplifying and exporting to GeoJSON..."
mapshaper Poly_${REGION}.geojson \
  -simplify dp 0.003 keep-shapes \
  -o format=geojson Poly_${REGION}_z6_8.geojson

# タイル化
echo "Creating terrain22_${REGION}_z6_8.mbtiles..."
tippecanoe -f -Q -o terrain22_${REGION}_z6_8.mbtiles \
  --no-simplification \
  --no-tiny-polygon-reduction \
  --no-feature-limit \
  --no-tile-size-limit \
  -l terrain22 \
  -Z 6 -z 8 Poly_${REGION}_z6_8.geojson

rm -f Poly_${REGION}_z6_8.geojson

echo "Creating terrain22_${REGION}_z9_10.mbtiles..."
tippecanoe -f -Q -o terrain22_${REGION}_z9_10.mbtiles \
  --no-simplification \
  --no-tiny-polygon-reduction \
  --no-feature-limit \
  --no-tile-size-limit \
  -l terrain22 \
  -Z 9 -z 10 Poly_${REGION}.geojson

rm -f Poly_${REGION}.geojson

echo "Joining mbtiles into terrain22_${REGION}.mbtiles..."
tile-join --force --no-tile-size-limit -o terrain22_${REGION}.mbtiles \
  terrain22_${REGION}_z6_8.mbtiles \
  terrain22_${REGION}_z9_10.mbtiles

rm -f terrain22_${REGION}_z6_8.mbtiles terrain22_${REGION}_z9_10.mbtiles

pmtiles convert terrain22_${REGION}.mbtiles terrain22_${REGION}.pmtiles