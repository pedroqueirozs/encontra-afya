-- EncontraAFYA: consultas
-- Executar depois de sql/encontraafya.sql.

USE encontraafya;

-- =====================================================================
-- Consultas simples
-- =====================================================================

-- Q1. Objetos encontrados aguardando atendimento
-- Pergunta: quais objetos encontrados ainda estão sob a guarda da instituição?
-- ABERTO e EM_ANALISE são os status de quem ainda não teve um desfecho.
SELECT id_ocorrencia, data_ocorrencia, status, descricao
FROM ocorrencia
WHERE tipo = 'ENCONTRADO'
  AND status IN ('ABERTO', 'EM_ANALISE')
ORDER BY data_ocorrencia;

-- Q2. Objetos com identificação do dono
-- Pergunta: quais objetos têm nome ou iniciais gravados, o que facilita achar o dono?
-- O % do LIKE aceita qualquer texto antes e depois da palavra.
SELECT id_objeto, nome, descricao
FROM objeto
WHERE descricao LIKE '%nome%'
   OR descricao LIKE '%iniciais%'
ORDER BY nome;

-- Q3. Ocorrências da primeira quinzena de outubro
-- Pergunta: o que foi perdido ou encontrado entre 1º e 15 de outubro de 2026?
-- BETWEEN inclui as duas datas dos extremos.
SELECT id_ocorrencia, data_ocorrencia, tipo, descricao
FROM ocorrencia
WHERE data_ocorrencia BETWEEN '2026-10-01' AND '2026-10-15'
ORDER BY data_ocorrencia;

-- Q4. Objetos de maior valor
-- Pergunta: quais objetos são eletrônicos (categoria 1) ou documentos (categoria 2)?
SELECT id_objeto, nome, marca, id_categoria
FROM objeto
WHERE id_categoria IN (1, 2)
ORDER BY id_categoria, nome;

-- Q5. Setores com funcionários responsáveis
-- Pergunta: quais setores do campus participam do atendimento?
-- Há 15 funcionários, mas vários são do mesmo setor; DISTINCT remove as repetições.
SELECT DISTINCT setor
FROM funcionario_responsavel
ORDER BY setor;

-- Q6. Últimos registros
-- Pergunta: quais foram as cinco ocorrências registradas mais recentemente?
SELECT id_ocorrencia, data_registro, tipo, descricao
FROM ocorrencia
ORDER BY data_registro DESC
LIMIT 5;

-- =====================================================================
-- Consultas com JOIN
-- =====================================================================

-- Q7. Eletrônicos encontrados: onde e quando (4 tabelas)
-- Pergunta: quais eletrônicos foram encontrados, em que local e qual a situação deles?
SELECT oc.id_ocorrencia, ob.nome AS objeto, l.nome AS local,
       oc.data_ocorrencia, oc.status
FROM ocorrencia oc
INNER JOIN objeto ob    ON ob.id_objeto = oc.id_objeto
INNER JOIN categoria c  ON c.id_categoria = ob.id_categoria
INNER JOIN local l      ON l.id_local = oc.id_local
WHERE c.nome = 'Eletrônicos'
  AND oc.tipo = 'ENCONTRADO'
ORDER BY oc.data_ocorrencia;

-- Q8. Locais com mais ocorrências (2 tabelas)
-- Pergunta: em quais locais acontecem mais perdas e achados?
-- SUM(CASE ...) soma 1 para cada linha do tipo indicado e 0 para as demais,
-- separando perdidos e encontrados no mesmo agrupamento.
-- HAVING filtra depois do agrupamento, o que o WHERE não consegue fazer.
SELECT l.nome AS local,
       COUNT(*) AS total,
       SUM(CASE WHEN oc.tipo = 'PERDIDO' THEN 1 ELSE 0 END) AS perdidos,
       SUM(CASE WHEN oc.tipo = 'ENCONTRADO' THEN 1 ELSE 0 END) AS encontrados
FROM ocorrencia oc
INNER JOIN local l ON l.id_local = oc.id_local
GROUP BY l.id_local, l.nome
HAVING COUNT(*) >= 4
ORDER BY total DESC, local;

-- Q9. Pessoas que mais registraram ocorrências (2 tabelas)
-- Pergunta: quem registrou duas ou mais ocorrências, e quando foi a última?
SELECT p.nome, p.tipo_pessoa,
       COUNT(*) AS ocorrencias,
       MAX(oc.data_registro) AS ultimo_registro
FROM pessoa p
INNER JOIN ocorrencia oc ON oc.id_pessoa = p.id_pessoa
GROUP BY p.id_pessoa, p.nome, p.tipo_pessoa
HAVING COUNT(*) >= 2
ORDER BY ocorrencias DESC, p.nome;

-- Q10. Tentativas de reclamar objetos de outra pessoa (4 tabelas)
-- Pergunta: quem procurou o atendimento por um objeto que não era seu?
SELECT DATE(t.data_tentativa) AS data, p.nome AS pessoa,
       ob.nome AS objeto, t.observacao
FROM tentativa_identificacao t
INNER JOIN pessoa p      ON p.id_pessoa = t.id_pessoa
INNER JOIN ocorrencia oc ON oc.id_ocorrencia = t.id_ocorrencia
INNER JOIN objeto ob     ON ob.id_objeto = oc.id_objeto
WHERE t.resultado = 'NAO_CONFIRMADO'
ORDER BY t.data_tentativa;

-- Q11. Devoluções por setor (3 tabelas)
-- Pergunta: quantas devoluções cada setor fez, em que período e em quantos dias, em média?
-- DATEDIFF calcula os dias entre a data em que o objeto foi encontrado e a devolução.
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

-- =====================================================================
-- Consultas bônus
-- =====================================================================

-- Q12. Objetos encontrados que não foram devolvidos (LEFT JOIN)
-- Pergunta: quais objetos encontrados ainda não tiveram devolução?
-- O LEFT JOIN mantém todas as ocorrências, mesmo sem devolução. Nesses casos,
-- as colunas de devolucao vêm NULL, e é isso que o WHERE filtra.
SELECT oc.id_ocorrencia, ob.nome AS objeto, oc.data_ocorrencia, oc.status
FROM ocorrencia oc
INNER JOIN objeto ob    ON ob.id_objeto = oc.id_objeto
LEFT JOIN devolucao d   ON d.id_ocorrencia = oc.id_ocorrencia
WHERE oc.tipo = 'ENCONTRADO'
  AND d.id_devolucao IS NULL
ORDER BY oc.data_ocorrencia;

-- Q13. Categorias acima da média (subconsulta)
-- Pergunta: quais categorias têm mais objetos que a média por categoria?
-- A subconsulta calcula a média (total de objetos dividido pelo total de
-- categorias) e o HAVING compara cada categoria com ela.
SELECT c.nome AS categoria, COUNT(*) AS objetos
FROM categoria c
INNER JOIN objeto ob ON ob.id_categoria = c.id_categoria
GROUP BY c.id_categoria, c.nome
HAVING COUNT(*) > (SELECT COUNT(*) FROM objeto) / (SELECT COUNT(*) FROM categoria)
ORDER BY objetos DESC, categoria;
