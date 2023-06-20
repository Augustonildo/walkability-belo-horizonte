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
```

# Visualizando os resultados no QGIS
Para visualizar no mapa as conclusões dos cálculos da métrica de caminhabilidade, é interessante adicionar um estilo de gradiente de cores para compreender quais são as melhores e piores áreas nesse quesito. <br>

Para fazer isso, siga os passos:
- Selecione a tabela 'walkable_grid' como um layer
- Filtre os resultados do layer para exibir somente as células em que "'regiao_estudo_id' IS NOT NULL"
- Vá em Estilos -> Editar símbolo -> Preenchimento Simples. Ao lado de 'Cor do Preenchimento', clique em Editar e preencha o código a seguir:
    - ```
        color_rgb(255 * (1 - "caminhabilidade"), 255 * "caminhabilidade", 0)
- Agora, as células com melhores índices de caminhabilidade devem estar mais verdes, enquanto as piores estão mais avermelhadas.
  
Outra sugestão relevante é remover os traços ao redor das células, para permitir a visualização dos dados mesmo com um "zoom-out" grande. Com a borda colorida das células, ao remover o zoom as células se tornam somente uma grande mancha preta.
