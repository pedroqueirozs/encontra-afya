USE encontraafya;

-- Q1: Lista os objetos encontrados que ainda aguardam o dono (status ABERTO ou EM_ANALISE).
SELECT id_ocorrencia, data_ocorrencia, status, descricao
FROM ocorrencia
WHERE tipo = 'ENCONTRADO'
  AND status IN ('ABERTO', 'EM_ANALISE')
ORDER BY data_ocorrencia;

-- Q2: Busca os objetos que têm nome ou iniciais do dono na descrição, o que facilita a identificação.
SELECT id_objeto, nome, descricao
FROM objeto
WHERE descricao LIKE '%nome%'
   OR descricao LIKE '%iniciais%'
ORDER BY nome;

-- Q3: Lista as ocorrências que aconteceram entre 1º e 15 de outubro de 2026.
SELECT id_ocorrencia, data_ocorrencia, tipo, descricao
FROM ocorrencia
WHERE data_ocorrencia BETWEEN '2026-10-01' AND '2026-10-15'
ORDER BY data_ocorrencia;

-- Q4: Lista os objetos das categorias Eletrônicos (1) e Documentos (2).
SELECT id_objeto, nome, marca, id_categoria
FROM objeto
WHERE id_categoria IN (1, 2)
ORDER BY id_categoria, nome;

-- Q5: Mostra, sem repetição, os setores que têm funcionários responsáveis pelo atendimento.
SELECT DISTINCT setor
FROM funcionario_responsavel
ORDER BY setor;

-- Q6: Mostra as cinco ocorrências registradas mais recentemente.
SELECT id_ocorrencia, data_registro, tipo, descricao
FROM ocorrencia
ORDER BY data_registro DESC
LIMIT 5;

-- Q7: Mostra os eletrônicos encontrados, com o local onde foram achados e a situação atual.
SELECT oc.id_ocorrencia, ob.nome AS objeto, l.nome AS local,
       oc.data_ocorrencia, oc.status
FROM ocorrencia oc
INNER JOIN objeto ob    ON ob.id_objeto = oc.id_objeto
INNER JOIN categoria c  ON c.id_categoria = ob.id_categoria
INNER JOIN local l      ON l.id_local = oc.id_local
WHERE c.nome = 'Eletrônicos'
  AND oc.tipo = 'ENCONTRADO'
ORDER BY oc.data_ocorrencia;

-- Q8: Conta as ocorrências por local, separando perdidos e encontrados, só dos locais com 4 ou mais.
SELECT l.nome AS local,
       COUNT(*) AS total,
       SUM(CASE WHEN oc.tipo = 'PERDIDO' THEN 1 ELSE 0 END) AS perdidos,
       SUM(CASE WHEN oc.tipo = 'ENCONTRADO' THEN 1 ELSE 0 END) AS encontrados
FROM ocorrencia oc
INNER JOIN local l ON l.id_local = oc.id_local
GROUP BY l.id_local, l.nome
HAVING COUNT(*) >= 4
ORDER BY total DESC, local;

-- Q9: Mostra as pessoas que registraram duas ou mais ocorrências e a data do último registro.
SELECT p.nome, p.tipo_pessoa,
       COUNT(*) AS ocorrencias,
       MAX(oc.data_registro) AS ultimo_registro
FROM pessoa p
INNER JOIN ocorrencia oc ON oc.id_pessoa = p.id_pessoa
GROUP BY p.id_pessoa, p.nome, p.tipo_pessoa
HAVING COUNT(*) >= 2
ORDER BY ocorrencias DESC, p.nome;

-- Q10: Lista quem procurou o atendimento por um objeto que não era seu (tentativa NAO_CONFIRMADO).
SELECT DATE(t.data_tentativa) AS data, p.nome AS pessoa,
       ob.nome AS objeto, t.observacao
FROM tentativa_identificacao t
INNER JOIN pessoa p      ON p.id_pessoa = t.id_pessoa
INNER JOIN ocorrencia oc ON oc.id_ocorrencia = t.id_ocorrencia
INNER JOIN objeto ob     ON ob.id_objeto = oc.id_objeto
WHERE t.resultado = 'NAO_CONFIRMADO'
ORDER BY t.data_tentativa;

-- Q11: Mostra, por setor, quantas devoluções foram feitas, a primeira, a última e a média de dias até devolver.
SELECT f.setor,
       COUNT(*) AS devolucoes,
       MIN(d.data_devolucao) AS primeira,
       MAX(d.data_devolucao) AS ultima,
       ROUND(AVG(DATEDIFF(d.data_devolucao, oc.data_ocorrencia)), 1) AS media_dias
FROM devolucao d
INNER JOIN ocorrencia oc              ON oc.id_ocorrencia = d.id_ocorrencia
INNER JOIN funcionario_responsavel f  ON f.id_funcionario = d.id_funcionario
GROUP BY f.setor
ORDER BY devolucoes DESC, f.setor;

-- Q12: Lista os objetos encontrados que não têm devolução registrada (LEFT JOIN com IS NULL).
SELECT oc.id_ocorrencia, ob.nome AS objeto, oc.data_ocorrencia, oc.status
FROM ocorrencia oc
INNER JOIN objeto ob    ON ob.id_objeto = oc.id_objeto
LEFT JOIN devolucao d   ON d.id_ocorrencia = oc.id_ocorrencia
WHERE oc.tipo = 'ENCONTRADO'
  AND d.id_devolucao IS NULL
ORDER BY oc.data_ocorrencia;

-- Q13: Mostra as categorias com mais objetos que a média por categoria (calculada por subconsulta).
SELECT c.nome AS categoria, COUNT(*) AS objetos
FROM categoria c
INNER JOIN objeto ob ON ob.id_categoria = c.id_categoria
GROUP BY c.id_categoria, c.nome
HAVING COUNT(*) > (SELECT COUNT(*) FROM objeto) / (SELECT COUNT(*) FROM categoria)
ORDER BY objetos DESC, categoria;
