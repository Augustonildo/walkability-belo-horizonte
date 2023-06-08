# walkability-belo-horizonte
Repositório auxiliar para Monografia em Sistemas de Informação na UFMG

A base de dados utilizada foi disponibilizada pela prefeitura de BH.  O site [BHMAP](http://bhmap.pbh.gov.br/v2/mapa) oferece uma ferramenta de mapa interativo onde é possível visualizar um mapa da cidade com diversos recursos e funcionalidades.

### Ferramentas relevantes para estudo e compreensão

[QGIS](https://qgis.org/pt_BR/site/)<br>
[BHMAP](http://bhmap.pbh.gov.br/v2/mapa)<br>
[GeoSQL](http://aqui.io/geosql/) - Plataforma do DCC para aprender na prática comandos PostGIS.

# Manipulando os dados SQL
## Configurando o Banco de Dados

Para instalar o backup dos dados na sua base de dados Postgres, certifique-se de ter as extensões necessárias instaladas. Abra sua ferramenta SQL (e.g. pgAdmin) e execute os seguintes comandos:

```sql
-- Esse comando instala a extensão PostGIS, essencial para lidar com os dados geográficos.
create extension postgis;

-- Criamos um novo schema para separar a estrutura necessária para o funcionamento do PostGIS e os dados em questão. 
create schema geodata;
set search_path = geodata, public;

-- Extensão ao PostGIS para funcionalidades extras
create extension pgrouting;
```

## Verificando as Versões
Para garantir que as extensões necessárias estejam corretamente instaladas, execute as seguintes consultas SQL para verificar as versões:

```sql
select version(); -- Versão do servidor PostgreSQL
select postgis_version();
select pgr_version();
````