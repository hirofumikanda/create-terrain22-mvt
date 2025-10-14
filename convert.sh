#!/bin/bash

# ダウンロードと解凍
echo "Downloading and extracting data..."
wget https://gisstar.gsi.go.jp/terrain2021/Poly_41.zip
unzip Poly_41.zip
rm -f Poly_41.zip

# GPKGに変換
echo "Converting Poly_41.shp to GPKG..."
ogr2ogr -progress -f GPKG work.gpkg Poly_41/Poly_41.shp \
  -s_srs Poly_41/Poly_41.prj -t_srs EPSG:4326 \
  -nln poly_41 -nlt PROMOTE_TO_MULTI -dim 2 -overwrite

echo "Converting GlobalCluster_41.dbf to GPKG..."
ogr2ogr -progress -f GPKG work.gpkg Poly_41/GlobalCluster_41.dbf \
  -nln globalcluster_41 -update

rm -rf Poly_41

# インデックス作成
echo "Creating indexes..."
ogrinfo work.gpkg -sql "CREATE INDEX IF NOT EXISTS idx_p_polyid ON poly_41(polyID)" -dialect SQLite
ogrinfo work.gpkg -sql "CREATE INDEX IF NOT EXISTS idx_gc_polyid ON globalcluster_41(polyID)" -dialect SQLite

# JOIN結果をGPKG内に物理テーブル化
echo "Joining tables and creating new layer..."
ogr2ogr -f GPKG work.gpkg work.gpkg \
  -nln poly_41_joined -overwrite \
  -dialect SQLite \
  -sql "SELECT p.geom AS geom,
               p.polyID, p.COMID, p.CONVEXITY, p.lnHAND, p.lnSLOPE, p.Sinks, p.TEXTURE, p.area,
               gc.Gcluster15, gc.Gcluster40
        FROM poly_41 p
        LEFT JOIN globalcluster_41 gc ON p.polyID = gc.polyID"

# GeoJSONでエクスポート
echo "Exporting joined data to GeoJSONSeq..."
ogr2ogr -progress -f GeoJSONSeq Poly_41.geojson work.gpkg poly_41_joined \
  -select geom,polyID,Sinks,Gcluster15,Gcluster40

rm -f work.gpkg

# 簡略化してGeoJSONでエクスポート
echo "Simplifying and exporting to GeoJSON..."
mapshaper Poly_41.geojson \
  -simplify dp 0.003 keep-shapes \
  -o format=geojson Poly_41_z6_8.geojson

# タイル化
echo "Creating terrain22_41_z6_8.mbtiles..."
tippecanoe -f -Q -o terrain22_41_z6_8.mbtiles \
  --no-simplification \
  --no-tiny-polygon-reduction \
  --no-feature-limit \
  --no-tile-size-limit \
  -l terrain22 \
  -Z 6 -z 8 Poly_41_z6_8.geojson

rm -f Poly_41_z6_8.geojson

echo "Creating terrain22_41_z9_10.mbtiles..."
tippecanoe -f -Q -o terrain22_41_z9_10.mbtiles \
  --no-simplification \
  --no-tiny-polygon-reduction \
  --no-feature-limit \
  --no-tile-size-limit \
  -l terrain22 \
  -Z 9 -z 10 Poly_41.geojson

rm -f Poly_41.geojson

echo "Joining mbtiles into terrain22_41.pmtiles..."
tile-join --force --no-tile-size-limit -o terrain22_41.pmtiles \
  terrain22_41_z6_8.mbtiles \
  terrain22_41_z9_10.mbtiles

rm -f terrain22_41_z6_8.mbtiles terrain22_41_z9_10.mbtiles