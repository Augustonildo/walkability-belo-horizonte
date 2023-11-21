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

-- Estas colunas foram criadas especificamente para facilitar o cálculo de custo e custo_reverso
-- Para economizar espaços, elas podem ser removidas após o UPDATE associado.
ALTER TABLE walkable_grid_edges
ADD COLUMN IF NOT EXISTS caminhabilidade_source numeric,
ADD COLUMN IF NOT EXISTS caminhabilidade_target numeric;

UPDATE walkable_grid_edges
SET
    caminhabilidade_source = a.caminhabilidade,
    caminhabilidade_target = b.caminhabilidade
FROM walkable_grid_vertices a,
	walkable_grid_vertices b
WHERE a.id = source
	AND b.id = target

-- TODO: tornar esse cálculo ainda mais rápido, está tomando mais de uma hora.
UPDATE walkable_grid_edges
SET
    cost = ST_Length(geom) * (1 - (caminhabilidade_target)),
    reverse_cost = ST_Length(geom) * (1 - (caminhabilidade_source));

-- TODO:
SELECT pgr_createTopology('walkable_grid_edges', 0.00001, 'geom', 'source', 'target');

-- TODO:
SELECT pgr_analyzegraph('walkable_grid_edges', 0.00001, 'geom', 'id', 'source', 'target');

-- TODO:
-- * dijkstra *