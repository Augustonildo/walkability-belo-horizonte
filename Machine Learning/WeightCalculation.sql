-- O objetivo dos passos a seguir é preparar os dados obtidos durante o projeto
-- para realizar um balanceamento dos pesos.

-- Para esse processo, vamos utilizar algoritmos de aprendizado supervisionado de máquina.
-- Algoritmos como esses necessitam que ao menos uma parte do dataset esteja tabelada com "labels".
-- No nosso caso, utilizaremos uma label binária: 1 ou 0, para um lugar bom ou ruim de se caminhar, respectivamente.

-- Comecemos criando uma coluna na tabela walkable_grid para armazenar essas labels.
ALTER TABLE walkable_grid
ADD COLUMN label_caminhabilidade INTEGER;

-- Em seguida, precisamos assinalar a algumas das células os valores para sua label.
-- NÃO atribuiremos label para todas as células. 
-- Como o motivo para o rebalanceamento do peso é a desconfiança na exatidão do algoritmo,
-- tabelaremos somente as células com razoavelmente maior certeza no resultado encontrado.

-- A primeira atribuição será de label para células "ruins". 
-- Empiricamente, percebemos que as células com caminhabilidade inferior ou igual a 0.4 notavelmente não eram ideias.
-- Portanto, vamos atribuir 0 para label_caminhabilidade destas células
UPDATE walkable_grid w
	SET label_caminhabilidade = 0
	WHERE w.regiao_estudo_id is not null
		AND w.caminhabilidade <= 0.4

-- De um total de 54762 células do estudo,
-- já atribuimos a 4090 células uma label.

-- Também empiricamente, usaremos as células com caminhabilidade >= 0.88 como controle positivo.
-- Gostaria que esse controle fosse ainda superior, porém existe uma pequeníssima quantidade de células acima desse índice.
UPDATE walkable_grid w
	SET label_caminhabilidade = 1
	WHERE w.regiao_estudo_id is not null
		AND w.caminhabilidade >= 0.88

-- Outra adição de dados de controle positivo que será não só empirica como também arbitrária é a adição da região da praça da liberdade.
-- Essa foi uma das divergências mais gritantes entre o algoritmo e a expectativa.
-- Abaixo, atualizaremos todas as células que tocam especificamente a praça da liberdade.
UPDATE walkable_grid w
	SET label_caminhabilidade = 1
	WHERE w.regiao_estudo_id is not null
		AND EXISTS(SELECT 1
				FROM praca p
				WHERE ST_Intersects(w.geom, p.geom)
				AND p.id_prc = 996);

-- Ao fim, temos as seguintes quantidades de dados de teste para o algoritmo:
	-- Positivo: 3002
	-- Negativo: 4090
	-- Sem label: 47.670

-- FIM: Consulta utilizada para gerar o arquivo csv
SELECT w.id,
		w.regiao_estudo_id as regiao,
		w.media_declividade, 
		w.praca_ou_parque, 
		COALESCE(w.unidades_iluminacao, 0) as unidades_iluminacao,
		COALESCE(w.atividades_economicas, 0) as atividades_economicas,
		w.meio_fio,
		w.pavimentacao, 
		w.label_caminhabilidade as caminhavel
	FROM walkable_grid w
	WHERE regiao_estudo_id IS NOT NULL