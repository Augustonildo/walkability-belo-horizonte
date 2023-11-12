-- Aqui serão adicionados os comandos utilizados para calcular os parâmetros relevantes para cada variável de interesse entre as célculas da região de estudo

-- Para reproduzir os próximos passos, é essencial a criação de spatial indexes para as células geométricas
-- Sem estes, as operações abaixo podem levar várias horas.

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
		LEFT JOIN declividade_trecho_lograd d ON ST_Intersects(ST_Buffer(w.geom, 30), d.geom)
		GROUP BY w.id
	) AS subquery
	WHERE w.id = subquery.id;

-- *EDIT:* declividade por curva de nível
	-- Após análise de todo o mapa, a ausência de informações de declividade relacionadas a células que não fazem
	-- parte de logradouros, como praças, parques e outros, foi sentida. Portanto, foi realizada uma adaptação para calcular
	-- a declividade com base nas informações de curva de nível.
	-- Após criar uma interpolação, calcular a declividade na interpolação e transformar isso para células, temos uma declividade
	-- que não só cobre os espaços descartados previamente como também melhor identifica as diferenças de declividade dentro de um mesmo segmento.

	UPDATE walkable_grid as w
		SET declividade = dc.valor_declividade
		FROM declividade_celulas as dc 
		WHERE ST_Contains(dc.geom, ST_Centroid(w.geom))

	-- Devido aos limites da abrangência dos dados de curva de nível, algumas células caminháveis não possuem um valor de declividade atrelado
	-- Para estas, portanto, prevalesce os valores já obtidos de declividade do logradouro, que foram utilizadas anteriormente.
	UPDATE walkable_grid as w
		SET declividade = media_declividade
		WHERE declividade is null
	
	
-- Praça ou parque:
-- Identifica se a célula toca em uma praça ou um parque (1) ou se não toca em nenhum (0).
UPDATE walkable_grid w
	SET praca_ou_parque = 1
		WHERE EXISTS(
			SELECT 1
				FROM parques_municipais pm
				WHERE ST_Intersects(w.geom, pm.geom)
		);

UPDATE walkable_grid w
	SET praca_ou_parque = 1
		WHERE EXISTS(
			SELECT 1
				FROM praca p
				WHERE ST_Intersects(w.geom, p.geom)
		);

UPDATE walkable_grid w
	SET praca_ou_parque = 0
	WHERE w.praca_ou_parque is null

-- Postes de luz:
-- Identifica quantos postes existem num raio de 15 metros da célula
-- Por que 15 metros? Pois, como o raio de iluminação de um poste pode variar de 15 a 30 metros, 
-- um poste em um raio de 15 metros da célula garantidamente ilumina ao menos uma parte dela.
UPDATE walkable_grid wg
	SET unidades_iluminacao = subquery.unidades_iluminacao
	FROM (
		SELECT w.id, COUNT(*) AS unidades_iluminacao
		FROM walkable_grid w, unidade_iluminacao_publica u
		WHERE ST_Intersects(w.geom, ST_Buffer(u.geom, 15))
		GROUP BY w.id
	) AS subquery
	WHERE wg.id = subquery.id;

-- Estabelecimentos econômicos:
-- Identifica quantos pontos de atividade econômica existem num raio de 25 metros da célula. Essa distância foi definida arbitrariamente.
-- O objetivo é destacar os ambientes de maior circulação de pessoas devido à atividade econômica no local.
UPDATE walkable_grid wg
SET atividades_economicas = subquery.atividades_economicas
FROM (
    SELECT w.id, COUNT(*) AS atividades_economicas
    FROM walkable_grid w, atividade_economica a
    WHERE ST_Intersects(w.geom, ST_Buffer(a.geom, 25))
    GROUP BY w.id
) AS subquery
WHERE wg.id = subquery.id;


-- Meio-fio:
-- Identifica se a célula está em uma rua que possa meio-fio válido.
UPDATE walkable_grid w
	SET meio_fio = 1
	WHERE EXISTS(
			SELECT 1
				FROM meio_fio m
				WHERE ST_Intersects(ST_Buffer(w.geom, 30), m.geom)
				AND m.ind_mf = 'S'
		);

UPDATE walkable_grid w
	SET meio_fio = 0
	WHERE w.meio_fio is null

-- Pavimento:
-- Query muito similar à do meio-fio, porém verificando o pavimento.
UPDATE walkable_grid w
	SET pavimentacao = 1
	WHERE EXISTS(
			SELECT 1
				FROM pavimentacao p
				WHERE ST_Intersects(ST_Buffer(w.geom, 30), p.geom)
				AND p.ind_pav = 'Sim'
		);

UPDATE walkable_grid w
	SET pavimentacao = 0
	WHERE w.pavimentacao is null


-- Classificação viária:
-- Limpando os dados de largura da via
ALTER TABLE classificacao_viaria
ADD COLUMN largura DECIMAL(10, 2);

UPDATE classificacao_viaria
SET largura = 
  CASE			-- As definições a seguir são arbitrárias e certamente não correspondem 100% com a realidade
    WHEN tipo_largu = 'A' THEN 7.5	-- "LARGURA DA VIA < 10 m"
    WHEN tipo_largu = 'B' THEN 12.5	-- "10m <= LARGURA DA VIA < 15m"
    WHEN tipo_largu = 'C' THEN 17.5	-- "LARGURA DA VIA >= 15m"
  END;	

-- Assinalando a classificação viária para cada célula baseando-se na largura de cada via
-- Caso uma célula se encontre em mais de uma via, será escolhida a circulação mais "intensa"
-- Caso uma célula não se conecte com nenhuma classificação viária, terá valor nulo
WITH max_classifica AS (
	SELECT wg.id, MAX(
					CASE
						WHEN classifica = 'LIGACAO REGIONAL' THEN 6
						WHEN classifica = 'ARTERIAL' THEN 5
						WHEN classifica = 'COLETORA' THEN 4
						WHEN classifica = 'LOCAL' THEN 3
						WHEN classifica = 'MISTA' THEN 2
						WHEN classifica = 'VIA DE PEDESTRES' THEN 1
						ELSE 0
					END) classi
	FROM classificacao_viaria c
	JOIN walkable_grid wg
		ON ST_Intersects(ST_Buffer(c.geom, c.largura), wg.geom)
	GROUP BY wg.id
)
UPDATE walkable_grid w
SET class_viaria = (CASE
        WHEN classi = 6 THEN 'LIGACAO REGIONAL'
        WHEN classi = 5 THEN 'ARTERIAL'
        WHEN classi = 4 THEN 'COLETORA'
        WHEN classi = 3 THEN 'LOCAL'
        WHEN classi = 2 THEN 'MISTA'
        WHEN classi = 1 THEN 'VIA DE PEDESTRES'
        ELSE NULL
    END)
FROM max_classifica mc
WHERE w.id = mc.id


-- FIM: Verificar os resultados calculados para cada célula
SELECT w.id,
		w.valid,
		w.media_declividade, 
		w.praca_ou_parque, 
		w.unidades_iluminacao, 
		w.atividades_economicas,
		w.meio_fio,
		w.pavimentacao, 
		w.class_viaria, 
		w.caminhabilidade,
		w.geom
	FROM walkable_grid w