# Cubo de Dados

## 1. Preparando as imagens dos containers

Baixe o repositório e compile as imagens:

```bash
git clone https://github.com/vconrado/odc-deploy.git
cd odc-deploy/docker
./build.sh
```
Com este script serão compiladas as imagens odc, odc-jupyter e odc-wms.

### 1.1 Volumes

Este ambiente considera que os dados serão armazenados em volumes compartilhados entre o host e os containers. Para isso, a seguinte estrutura de pastas foi criada:

- **data/**
    - **pgdata/**: dados do banco de dados
    - **data/**: dados brutos e processados do ODC
        - **jupyterhub-home/**: pasta com notebooks
        - **USGS/**:
            - **Landsat/**: dados Landsat
                - **L8/**: dados brutos Landsat 8
                    - *ls8_level1_usgs.yaml*: arquivo com a descrição do produto L8
                    - **PATH/**: 
                        - **ROW/**: dados Landsat 8
                - **L8_ingested/**: dados Landsat 8 reorganizados
                    - **nome_do_produto/**: pasta com o nome do novo produto
                        - *nome_do_produto.yaml*: arquivo com a descrição do novo produto (*ingest*) produzido
                        - **data/**: pasta com os dados do novo produto (formato NetCDF)
        

### 1.2 Rede

Crie uma rede para ser utilizada entre os containers. Digite: 
```bash
docker network create test-odc-net
```
    
### 1.3 Banco de Dados
Para instanciar o container do banco de dados, execute:
```bash
docker run -it -d \
    --net=test-odc-net \
    --name=test-odc-pg \
    -e POSTGRES_USER=odc \
    -e POSTGRES_PASSWORD=odc \
    -e POSTGRES_DB=datacube \
    -p 5433:5432 \
    -d postgres:10
```

### 1.4 ODC (opendatacube-core)
Para rodar o odc, execute:
```bash
docker run -it -d \
    --net=test-odc-net \
    --name test-odc-1 \
    -e DB_HOSTNAME=test-odc-pg \
    -e DB_DATABASE=datacube \
    -e DB_USERNAME=odc \
    -e DB_PASSWORD=odc \
    -v $HOME:/home/datacube/my_home \
    odc:1.7 /bin/bash
```

No primeiro containter que executar o ODC, é necessário executar os comandos abaixo para iniciar as tabelas do banco de dados.

Inicialmente, acesse o container odc-core-01:
```bash
docker exec -it odc-core-01 bash
```
Inicialize o ODC:
```bash
datacube -v system init
```

## 1.5 Jupyter

Para executar um container com o jupyter com suporte ao ODC, execute:
```bash
docker run -it -d \
    --name odc-jupyter-01 \
    --hostname odc-jupyter-01 \
    --network odc-net \
    --restart unless-stopped \
    -p 8888:8888 \
    -v /data/ODC/data/jupyterhub-home:/home/datacube/code \
    -v /data/ODC/data:/datacube \
    -e "DB_DATABASE=opendatacube" \
    -e "DB_HOSTNAME=odc-pg" \
    -e "DB_USERNAME=opendatacube" \
    -e "DB_PASSWORD=troque@senha" \
    -e "DB_PORT=5432" \
    odc-jupyter:2018-10-21 \
    jupyter notebook --ip="*" --NotebookApp.token='troque@token'
```

O Jupyter Notebook pode ser acesso através do IP do host na porta 8888.


## 1.5 WMS (datacube-wms)
Para executar um container com o serviço WMS integrado ao ODC, execute:
```bash
docker run -it -d\
   --name odc-wms-01 \
   --hostname odc-wms-01 \
   -v /data/ODC/data:/datacube \
   --network odc-net \
   -e DB_DATABASE=opendatacube \
   -e DB_HOSTNAME=odc-pg \
   -e DB_USERNAME=opendatacube \
   -e DB_PASSWORD=troque@senha \
   -e DB_PORT=5433 \
   -p 8080:8080 \
   odc-wms:2018-10-21
```

Entre no docker e atualize a lista de camadas
```
docker exec -it odc-wms-01
python3 /home/datacube/Devel/datacube-wms/update_ranges.py
```

Rode o serviço:
```
cd /home/datacube/Devel/datacube-wms/datacube_wms
gunicorn3 -b '0.0.0.0:8080' -w 5 --timeout 300 wsgi
```

O serviço será executado vinculado à porta 8080 do servidor. Para acessário, abra o link [IP_HOST:8080/?request=GetCapabilities&service=WMS](IP_HOST:8080/?request=GetCapabilities&service=WMS). 
## 2 Subindo Dados

Subir dados no ODC consiste em 3 etapas:
- 1. Cadastrar um Produto;
- 2. Incluir *Datasets* ao Produto; e 
- 3. Criar novos produtos a partir do produto previamente cadastrado.

### 2.1 Cadastrando o produto *ls8_level1_usgs.yaml*

O arquivo *ls8_level1_usgs.yaml* possui os metadados suficientes para cadastrar o produto com os dados brutos do L8.
Para inserir o novo produto, digite:
```bash
datacube product add /datacube/USGS/Landsat/L8/ls8_level1_usgs.yaml
```

### 2.2 Incluir os datasets

Para subir os datasets (cenas) do L8 no produto  *ls8_level1_usgs.yaml* recém cadastrado, utilize o script localizado no repositório:
```bash
odc-deploy/scripts/prepare_add.sh /datacube/USGS/Landsat/L8 ls8_level1_usgs
```

O primeiro argumento indica a pasta onde os dados serão buscados e o segundo o nome do produto. 
Esse script buscará todos arquivos **.tar.gz** a partir do caminho passado (incluido subpastas). Para cada arquivo encontrado, será:
- descompactado o tar.gz para pasta com mesmo nome do arquivo (sem extensão);
- produzido arquivo com metadados (yaml) dentro da pasta criada;
- adicionados os arquivos como um dataset do produto informado.


### 2.3 Produzindo novos produtos a partir de outros (**Ingest**)

O ODC permite a criação de novos produtos a partir de outros já registrados. Nesse processo, é possível reprojetar, re-amostrar, selecionar atributos e quebrar os dados em blocos menores (chunks). Na pasta *templates/ingest* desse repositório, existem alguns modelos. Para alterar o sistema de referência de ls8_level1_usgs e gerar um novo produto (por exemplo, ls8_level1_epsg31983), basta executar:
<!--
```bash
datacube ingest -c /datacube/USGS/Landsat/L8_ingested/ls8_level1_epsg31983/ls8_level1_epsg31983.yaml --executor multiproc 20
```
-->
```bash
odc-deploy/scripts/ingest.sh /datacube/USGS/Landsat/L8_ingested/ls8_level1_epsg31983/ls8_level1_epsg31983.yaml 20
```
O primeiro parâmetro é o caminho do arquivo yaml e o segundo, o qual é opcional, define o número de processadores que deverão ser utilizados para criar o novo produto. Altere esse número para um valor mais adequado ao seu servidor. 

## 3. Ambiente Interativo

Para acessar o ambiente interativo Jupyter Notebook executado anteriormente, basta abrir o link [IP_HOST:8888](IP_HOST:8888). Abaixo segue um exemplo de código que utiliza a API do ODC. 
```python
import datacube

dc = datacube.Datacube()
prod_df = dc.list_products()
print(prod_df)


ds_df = dc.find_datasets(product=product.name)
product_bbox = datacube.api.core.get_bounds(ds_df, product.grid_spec.crs)
print(product_bbox)
```

## 4. Referências

[1] [Open Data Cube Manual](https://datacube-core.readthedocs.io/en/latest/index.html)   
[2] [Repositório AGDC-v2](https://github.com/ceos-seo/agdc-v2)   
[3] [Repositório datacube-core](https://github.com/opendatacube/datacube-core)   
[4] [Repositório datacube-wms](https://github.com/opendatacube/datacube-wms)







