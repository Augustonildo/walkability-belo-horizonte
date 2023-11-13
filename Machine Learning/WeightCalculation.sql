-- O objetivo dos passos a seguir é preparar os dados obtidos durante o projeto
-- para realizar um balanceamento dos pesos.

-- Para esse processo, vamos utilizar algoritmos de aprendizado supervisionado de máquina.
-- Algoritmos como esses necessitam que ao menos uma parte do dataset esteja tabelada com "labels".
-- Após a análise de resultados anteriores, utilizaremos as labels a seguir: 
-- 
-- 0: Muito ruim
-- 1: Ruim
-- 2: Médio
-- 3: Aceitável
-- 4: Muito bom
--
--

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
-- Percebemos analisando o mapa que as células com caminhabilidade inferior ou igual a 0.1 notavelmente não eram ideais.
-- Portanto, vamos atribuir 0 para label_caminhabilidade destas células
UPDATE walkable_grid w
	SET label_caminhabilidade = 0
	WHERE w.caminhabilidade <= 0.1

-- Estes são os valores que definem as classes intermediárias da pesquisa

UPDATE walkable_grid w
	SET label_caminhabilidade = 1
	where caminhabilidade >= 0.2 
	and caminhabilidade < 0.22		


UPDATE walkable_grid w
	SET label_caminhabilidade = 2
	where caminhabilidade >= 0.44 
	and caminhabilidade < 0.46


UPDATE walkable_grid w
	SET label_caminhabilidade = 3
	where caminhabilidade >= 0.79 
	and caminhabilidade < 0.81

-- Também considerando os valores encontrados, usaremos as células com caminhabilidade >= 0.87 como controle positivo de excelência.
UPDATE walkable_grid w
	SET label_caminhabilidade = 4
	WHERE w.caminhabilidade >= 0.87

-- Ao fim, temos as seguintes quantidades de dados de teste para o algoritmo:
	-- 0: Muito ruim	- 90.681
	-- 1: Ruim			- 36.949
	-- 2: Médio			- 42.536
	-- 3: Aceitável		- 42.414
	-- 4: Muito bom		- 13.922
	-- Sem label: 3.965.134

-- FIM: Consulta utilizada para gerar o arquivo csv
SELECT w.id,
		w.declividade, 
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