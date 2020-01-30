# 0. Roteiro

# 1. Pastas e dados preparados em
/data/ODC/ ...


## 1.2 Rede
```bash
docker network create teste-odc-net
```

## 1.3 BD
```bash
docker run -it -d \
        --name teste-odc-pg \
        --hostname teste-odc-pg \
        --network teste-odc-net \
        --restart unless-stopped \
        -p 5433:5432 \
        -v /data/ODC/pgdata:/var/lib/postgresql/data \
        -e "PGDATA=/var/lib/postgresql/data" \
        -e "POSTGRES_DB=opendatacube" \
        -e "POSTGRES_PASSWORD=senha" \
        -e "POSTGRES_USER=opendatacube" \
        postgres:10.3
```    
## 1.3 datacube-core
```
docker run -it -d\
   --name teste-odc-core-01 \
   --hostname teste-odc-core-01 \
   --network teste-odc-net \
   --restart unless-stopped \
   -v /data/ODC/data:/datacube \
   -e DB_DATABASE=opendatacube \
   -e DB_HOSTNAME=teste-odc-pg \
   -e DB_USERNAME=opendatacube \
   -e DB_PASSWORD=senha \
   -e DB_PORT=5432 \
   odc:2018-10-21
```        

### 1.3.1 Preparando dados
```
docker exec -it teste-odc-core-01 bash
```
```
datacube -v system init
```
### 1.3.2 Baixando scripts 

```
git clone https://github.com/vconrado/odc-deploy.git
```

### 1.3.3 Listando produtos


```
cat /datacube/scripts/Devel/products.py
```
```
python3 /datacube/scripts/Devel/products.py
```


### 1.3.4 Registrando o produto

```
ls -R /datacube/USGS/
```

Subindo o Produto [ls8_level1_usgs.yaml](https://github.com/vconrado/odc-deploy/blob/master/templates/product/ls8_level1_usgs.yaml)
```
datacube product add /datacube/USGS/Landsat/L8/ls8_level1_usgs.yaml
```

### 1.3.5 Inserindo Datasets

Usando o [script](https://github.com/vconrado/odc-deploy/blob/master/scripts/prepare_add.sh):
```
/home/datacube/odc-deploy/scripts/prepare_add.sh /datacube/USGS/Landsat/L8 ls8_level1_usgs
```

### 1.3.6 Criando novo produto a partir do ls_level1_usgs

Criando o produto [ls8_level1_epsg31983.yaml](https://github.com/vconrado/odc-deploy/blob/master/templates/ingest/ls8_level1_epsg31983.yaml)
```
/home/datacube/odc-deploy/scripts/ingest.sh /datacube/USGS/Landsat/L8_ingested/ls8_level1_epsg31983/ls8_level1_epsg31983.yaml 6
```

```
python3 /datacube/scripts/Devel/products.py
```

## 1.3 Jupyter

```
docker run -it -d  \
    --name teste-odc-jupyter-01 \
    --hostname teste-odc-jupyter-01 \
    --network teste-odc-net \
    --restart unless-stopped \
    -p 8888:8888 \
    -v /data/ODC/data/jupyterhub-home:/home/datacube/code \
    -v /data/ODC/data:/datacube \
    -e "DB_DATABASE=opendatacube" \
    -e "DB_HOSTNAME=teste-odc-pg" \
    -e "DB_USERNAME=opendatacube" \
    -e "DB_PASSWORD=senha" \
    -e "DB_PORT=5432" \
    vconrado/odc-jupyter:2018-10-21 \
    jupyter notebook --ip="0.0.0.0" --NotebookApp.token='senha'
```
[Jupyter](http://localhost:8888)


## 1.4 WMS
```
docker run -it -d \
   --name teste-odc-wms-01 \
   --hostname teste-odc-wms-01 \
   --network teste-odc-net \
   -v /data/ODC/data:/datacube \
   -e DB_DATABASE=opendatacube \
   -e DB_HOSTNAME=teste-odc-pg \
   -e DB_USERNAME=opendatacube \
   -e DB_PASSWORD=senha \
   -e DB_PORT=5432 \
   -p 8080:8080 \
   vconrado/odc-wms:2018-10-21   
```
```
docker exec -it teste-odc-wms-01 bash
python3 /home/datacube/Devel/datacube-wms/update_ranges.py
cd /home/datacube/Devel/datacube-wms/datacube_wms
gunicorn3 -b '0.0.0.0:8080' -w 5 --timeout 300 wsgi
```

[GetCapabilities](http://localhost:8080/?request=GetCapabilities&service=WMS)

[GetFeatureInfo*](http://localhost:8080/?request=GetFeatureInfo&&version=1.3.0&service=WMS&layers=ls8_level1_epsg31983&crs=EPSG%3A4326)
# Remover tudo
```
docker stop teste-odc-wms-01
docker rm -v teste-odc-wms-01
```

```
docker stop teste-odc-jupyter-01
docker rm -v teste-odc-jupyter-01
```

```
docker stop teste-odc-core-01
docker rm -v teste-odc-core-01
```

```
docker stop teste-odc-pg
docker rm -v teste-odc-pg
```

```
docker network rm teste-odc-net
```

```
sudo rm -rf /data/ODC/pgdata
mkdir /data/ODC/pgdata
```


```
rm -rf /data/ODC/data/USGS/Landsat/L8_ingested/ls8_level1_epsg31983/data/
mkdir -p /data/ODC/data/USGS/Landsat/L8_ingested/ls8_level1_epsg31983/data/
```


```
rm -rf LC08_L1TP_221067_20170606_20170616_01_T1 LC08_L1TP_221067_20170622_20170630_01_T1  LC08_L1TP_221067_20180711_20180717_01_T1
```

# Extra

```
psql -U opendatacube -h localhost -p 5433
```


```sql
SELECT id, name FROM agdc.dataset_type;
-- id = 3

DELETE FROM agdc.dataset_location WHERE dataset_ref IN 
    (SELECT dataset.id FROM agdc.dataset WHERE dataset_type_ref = 3);

DELETE FROM agdc.dataset_source WHERE dataset_ref IN 
    (SELECT dataset.id FROM agdc.dataset WHERE dataset_type_ref = 3);

DELETE FROM agdc.dataset WHERE dataset_type_ref = 3;

DELETE FROM agdc.dataset_type WHERE id = 3;
```
