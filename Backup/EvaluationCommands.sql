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
-- Identifica quantos postes existem num raio de 15 metros da célula
-- Por que 15 metros? Pois, como o raio de iluminação de um poste pode variar de 15 a 30 metros, 
-- um poste em um raio de 15 metros da célula garantidamente ilumina ao menos uma parte dela.
UPDATE walkable_grid wg
	SET unidades_iluminacao = subquery.unidades_iluminacao
	FROM (
		SELECT w.id, COUNT(*) AS unidades_iluminacao
		FROM walkable_grid w, unidade_iluminacao_publica u
		WHERE w.regiao_estudo_id IS NOT NULL
		AND ST_Intersects(w.geom, ST_Buffer(u.geom, 15))
		GROUP BY w.id
	) AS subquery
	WHERE wg.id = subquery.id;

-- #TODO: rodar novamente, possivelmente em parcelas menores
-- Foi necessário interromper a execução após 5h38m e a query ainda não estava completa.

-- Estabelecimentos econômicos:
-- Identifica quantos pontos de atividade econômica existem num raio de 25 metros da célula. Essa distância foi definida arbitrariamente.
-- O objetivo é destacar os ambientes de maior circulação de pessoas devido à atividade econômica no local.
UPDATE walkable_grid wg
SET atividades_economicas = subquery.atividades_economicas
FROM (
    SELECT w.id, COUNT(*) AS atividades_economicas
    FROM walkable_grid w, atividade_economica a
    WHERE w.regiao_estudo_id IS NOT NULL
    AND ST_Intersects(w.geom, ST_Buffer(a.geom, 25))
    GROUP BY w.id
) AS subquery
WHERE wg.id = subquery.id;



-- FIM: Verificar os resultados calculados para cada célula
SELECT w.id,
		w.valid,
		w.regiao_estudo_id, 
		w.media_declividade, 
		w.praca_ou_parque, 
		w.unidades_iluminacao, 
		w.atividades_economicas, 
		w.caminhabilidade, 
		w.geom
	FROM walkable_grid
	WHERE regiao_estudo_is IS NOT NULL