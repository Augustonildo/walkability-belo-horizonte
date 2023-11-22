-- Criando tabela para os vértices
-- Cada vértice será uma das célula caminháveis da tesselação
CREATE TABLE walkable_grid_vertices AS
SELECT id,
    ST_Centroid(geom) AS geom,
    caminhabilidade
FROM walkable_grid;

CREATE UNIQUE INDEX walkable_grid_vertices_pkey ON geodata.walkable_grid_vertices USING btree (id)

CREATE INDEX sidx_walkable_grid_vertices_geom ON geodata.walkable_grid_vertices USING gist (geom)

-- Criando a tabela de arestas
-- Uma aresta liga células adjacentes
CREATE TABLE walkable_grid_edges AS
SELECT a.id AS source,
    b.id AS target,
    ST_MakeLine(a_vertice.geom, b_vertice.geom) AS geom
FROM walkable_grid a
JOIN walkable_grid b
ON ST_Touches(a.geom, b.geom) 
    AND a.id < b.id
JOIN walkable_grid_vertices a_vertice
	on a_vertice.id = a.id
JOIN walkable_grid_vertices b_vertice
	on b_vertice.id = b.id

ALTER TABLE walkable_grid_edges
ADD COLUMN id serial;

CREATE UNIQUE INDEX walkable_grid_edges_pkey ON geodata.walkable_grid_edges USING btree (id)

CREATE INDEX sidx_walkable_grid_edges_geom ON geodata.walkable_grid_edges USING gist (geom)

CREATE INDEX walkable_grid_edges_source ON geodata.walkable_grid_edges USING btree (source)
CREATE INDEX walkable_grid_edges_target ON geodata.walkable_grid_edges USING btree (target)


-- Será adicionado neste momento o custo atrelado a cada aresta para o cálculo do roteamento
-- Neste cenário, o custo é definido não só pelo tamanho do trajeto mas também pela caminhabilidade
-- das células atravessadas. 
-- 
-- Células com boa caminhabilidade são incentivadas pelo algoritmo.
ALTER TABLE walkable_grid_edges
ADD COLUMN IF NOT EXISTS cost double precision,
ADD COLUMN IF NOT EXISTS reverse_cost double precision;


UPDATE walkable_grid_edges
SET
    caminhabilidade_source = a.caminhabilidade,
    caminhabilidade_target = b.caminhabilidade
FROM walkable_grid_vertices a,
	walkable_grid_vertices b
WHERE a.id = source
	AND b.id = target

UPDATE walkable_grid_edges
SET
    cost = ST_Length(geom) * (1 - (
        SELECT caminhabilidade
        FROM walkable_grid_vertices
        WHERE walkable_grid_vertices.id = walkable_grid_edges.target
    )),
    reverse_cost = ST_Length(geom) * (1 - (
        SELECT caminhabilidade
        FROM walkable_grid_vertices
        WHERE walkable_grid_vertices.id = walkable_grid_edges.source
    ));


-- Exemplos de criação de rota


-- Rota que liga a estação UFMG do MOVE e a orla da Pampulha,
-- especificamente Chopp da Fábrica
create table path_estacao_orla_edges as (
	select id, geom from walkable_grid_edges where id in (
		select edge from pgr_bddijkstra('select id, source, target, cost, reverse_cost from walkable_grid_edges',
										13866633, -- ID da célula de início
										11478735) -- ID da célula de chegada
	)
)


-- Rota que leva da praça Milton Campos, encontro entre Afonso Pena e Contorno,
-- para a portaria do parque das Mangabeiras.ß
create table path_milton_mangabeiras_edges as (
	select id, geom from walkable_grid_edges where id in (
		select edge from pgr_bddijkstra('select id, source, target, cost, reverse_cost from walkable_grid_edges',
										17968972, -- ID da célula de início
										20725961) -- ID da célula de chegada
	)
)

-- Sugestões:
-- Ao exibir a rota no QGIS, aumentar a grossura da linha do trajeto e selecionar uma cor contrastante (azul).