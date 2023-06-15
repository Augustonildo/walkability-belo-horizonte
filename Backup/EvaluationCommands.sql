-- Aqui serão adicionados os comandos utilizados para calcular os parâmetros relevantes para cada variável de interesse entre as célculas da região de estudo

-- A coluna caminhabilidade é a principal coluna para a avaliação, armazenando uma nota de 0 a 1 para a caminhabilidade
-- Essa nota será calculada por um serviço externo com base nas informações das outras colunas.
ALTER TABLE walkable_grid
ADD COLUMN caminhabilidade DECIMAL(10, 2);

-- Declividade do trecho:
-- Consideraremos a declividade média do trecho do logradouro, sendo este trecho uma secção da rua, avenida, etc.
UPDATE walkable_grid w
	SET media_declividade = subquery.media_declividade
	FROM (
		SELECT w.id, COALESCE(AVG(d.declivida0), 0) AS media_declividade
		FROM walkable_grid w
		LEFT JOIN declividade_trecho_lograd d ON ST_Intersects(w.geom, d.geom)
		WHERE w.regiao_estudo_id IS NOT NULL
		GROUP BY w.id
	) AS subquery
	WHERE w.id = subquery.id;
	
-- Praça ou parque:
-- Identifica se a célula toca em uma praça ou um parque (1) ou se não toca em nenhum (0).
UPDATE walkable_grid w
	SET praca_ou_parque = 1
	WHERE w.regiao_estudo_id is not null
		AND EXISTS(
			SELECT 1
				FROM praca p, parques_municipais pm
				WHERE ST_Intersects(w.geom, p.geom) OR ST_Intersects(w.geom, pm.geom)
		);

UPDATE walkable_grid w
	SET praca_ou_parque = 0
	WHERE w.regiao_estudo_id is not null
	AND w.praca_ou_parque is null
	
-- Postes de luz:
-- Identifica quantos postes existem num raio de 25 metros da célula
-- Por que 25 metros? Pois, como o raio de iluminação de um poste pode variar de 15 a 30 metros, 
-- um poste a 25 metros distante certamente ilumina a maior parte da célula.