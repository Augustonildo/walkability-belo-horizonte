-- O objetivo dos passos a seguir é preparar os dados obtidos durante o projeto
-- para realizar um balanceamento dos pesos.

-- Para esse processo, vamos utilizar algoritmos de aprendizado supervisionado de máquina.
-- Algoritmos como esses necessitam que ao menos uma parte do dataset esteja tabelada com "labels".
-- No nosso caso, utilizaremos uma label binária: 1 ou 0, para um lugar bom ou ruim de se caminhar, respectivamente.

-- Comecemos criando uma coluna na tabela walkable_grid para armazenar essas labels.
ALTER TABLE walkable_grid
ADD COLUMN label_caminhabilidade INTEGER;

CREATE INDEX walkable_grid_label_caminhabilidade 
	ON geodata.walkable_grid USING btree(label_caminhabilidade)

-- Em seguida, precisamos assinalar a algumas das células os valores para sua label.
-- NÃO atribuiremos label para todas as células. 
-- Como o motivo para o rebalanceamento do peso é a desconfiança na exatidão do algoritmo,
-- tabelaremos somente as células com razoavelmente maior certeza no resultado encontrado.

-- A primeira atribuição será de label para células "ruins". 
-- Percebemos analisando o mapa que as células com caminhabilidade inferior a 0.4 notavelmente não eram ideais.
-- Portanto, vamos atribuir 0 para label_caminhabilidade destas células
UPDATE walkable_grid w
	SET label_caminhabilidade = 0
	WHERE w.caminhabilidade < 0.4

-- De um total de 4.068.581 células do estudo,
-- já atribuimos a 79.721 células uma label.

-- Também empiricamente, usaremos as células com caminhabilidade >= 0.88 como controle positivo.
UPDATE walkable_grid w
	SET label_caminhabilidade = 1
	WHERE w.caminhabilidade >= 0.88

-- Outra adição de dados de controle positivo que será não só empirica como também arbitrária é a adição da região da praça da liberdade.
-- Essa foi uma das divergências mais gritantes entre o algoritmo e a expectativa.
-- Abaixo, atualizaremos todas as células próximas à praça da liberdade.
UPDATE walkable_grid w
	SET label_caminhabilidade = 1
	WHERE EXISTS(SELECT 1
				FROM praca p
				WHERE ST_Intersects(w.geom, ST_Buffer(p.geom, 10))
				AND p.id_prc = 996);

-- Em contra partida, a região do parque municipal José Maria Alkimim, ao lado do shopping Ponteio, 
-- não parece ter estrutura ideal para trânsito de pessoas, embora existam algumas trilhas desenhadas pela circulação de transeuntes.
-- Pela falta de infraestrutura, atualizaremos abaixo suas células como não ideais.
UPDATE walkable_grid w
	SET label_caminhabilidade = 0
	WHERE EXISTS(SELECT 1
				FROM parques_municipais pm
				WHERE ST_Intersects(w.geom, ST_Buffer(pm.geom, 10))
				AND pm.id_unidade_fpmzb = 345);

-- Outra região obviamente não ideal para caminhada é um espaço com alta circulação de veículos de carga pesada e em alta velocidade
-- A caminhada no espaço dos veículos no Anel Rodoviária é completamente desaconselhada.
-- todo: [optimize or remove]
UPDATE walkable_grid w
	SET label_caminhabilidade = 0
	WHERE EXISTS(SELECT 1
				FROM classificacao_viaria cv
				WHERE ST_Intersects(w.geom, ST_Buffer(cv.geom, cv.largura))
				AND cv.no_log = 'ANEL RODOVIARIO CELSO MELLO AZEVEDO');


-- Adicionando um controle positivo, temos a pista de cooper da rua José de Patrocínio Pontes, próxima ao Parque das Mangabeiras. 
-- É considerada em diversas fontes como um dos melhores locais para se caminhar em belo horizonte
-- Abaixo será selecionado somente o trecho que possui a pista de cooper.
UPDATE walkable_grid w
	SET label_caminhabilidade = 1
	WHERE EXISTS(SELECT 1
				FROM classificacao_viaria cv
				WHERE ST_Intersects(w.geom, ST_Buffer(cv.geom, 5))
				AND cv.id IN (36638, 46988));

-- Ao fim, temos as seguintes quantidades de dados de teste para o algoritmo:
	-- Positivo: 18295
	-- Negativo: 85152
	-- Sem label: 3.965.134

-- FIM: Consulta utilizada para gerar o arquivo csv
SELECT w.id,
		w.media_declividade, 
		w.praca_ou_parque, 
		COALESCE(w.unidades_iluminacao, 0) as unidades_iluminacao,
		COALESCE(w.atividades_economicas, 0) as atividades_economicas,
		w.meio_fio,
		w.pavimentacao, 
		w.class_viaria, 
		w.label_caminhabilidade as caminhavel
	FROM walkable_grid w

--
--
-- Armazenando os resultados!
--
--

-- -- Após realizar as predições utilizando os algoritmos de aprendizado de máquina
-- -- o resultado obtido será um arquivo .csv com as predições de caminhabilidade para cada célula
-- -- para esse caso, criaremos uma tabela com as previsões e armazenaremos nela os valores encontrados.

-- Criação da tabela
CREATE TABLE geodata.prediction_walkability (
    id serial PRIMARY KEY,
    previsao integer
);

-- *realizar a importação para a tabela nova através do SGBD preferido* --

UPDATE walkable_grid
	SET predicao = pw.previsao
	FROM prediction_walkability pw
	WHERE walkable_grid.id = pw.id;

-- Agora é só abrir esta tabela no QGIS e visualizar os dados obtidos!
-- A tabela prediction_walkability já pode ser limpa.