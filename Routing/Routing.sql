-- Criando tabela para os vértices
-- Cada vértice será uma das célula caminháveis da tesselação
CREATE TABLE walkable_grid_vertices AS
SELECT id,
    ST_Centroid(geom) AS geom
FROM walkable_grid;

-- Criando a tabela de arestas
-- Uma aresta liga células adjacentes
CREATE TABLE walkable_grid_edges AS
SELECT a.id AS source,
    b.id AS target,
    ST_MakeLine(a.geom, b.geom) AS geom
FROM walkable_grid_vertices a
JOIN walkable_grid_vertices b
ON ST_Intersects(a.geom, b.geom) 
    AND a.id < b.id;

--
-- TODO:
--
--

-- 1) Adicionar cost e reverse_cost, utilizando como peso: length * (1 - caminhabilidade)

-- 2)
SELECT pgr_createTopology('walkable_grid_edges', 0.00001, 'geom', 'source', 'target');

-- 3)
SELECT pgr_analyzegraph('walkable_grid_edges', 0.00001, 'geom', 'id', 'source', 'target');

