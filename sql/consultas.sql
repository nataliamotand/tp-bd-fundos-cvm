-- Consultas base 


--  1. SELECT + WHERE 
-- Classes Multimercados Livre ativas com patrimônio acima de R$ 500 milhões

SELECT
    cnpj_classe,
    denominacao_social,
    classificacao_anbima,
    patrimonio_liquido
FROM classe
WHERE classificacao_anbima = 'Multimercados Livre'
  AND situacao = 'Em Funcionamento Normal'
  AND patrimonio_liquido > 500000000
ORDER BY patrimonio_liquido DESC;


--  2. Agregações (COUNT, SUM, AVG, MIN, MAX) 
-- Estatísticas de patrimônio por classificação ANBIMA, restrito a
-- fundos do tipo FIF (que possuem classificação ANBIMA consistente)

SELECT
    classificacao_anbima,
    COUNT(*)                     AS qtd_classes,
    SUM(patrimonio_liquido)      AS patrimonio_total,
    AVG(patrimonio_liquido)      AS patrimonio_medio,
    MIN(patrimonio_liquido)      AS patrimonio_min,
    MAX(patrimonio_liquido)      AS patrimonio_max
FROM classe
WHERE situacao = 'Em Funcionamento Normal'
  AND tipo_classe = 'Classes de Cotas de Fundos FIF'
  AND classificacao_anbima IS NOT NULL
GROUP BY classificacao_anbima
ORDER BY patrimonio_total DESC;


--  3. GROUP BY + HAVING 
-- Classificações ANBIMA com pelo menos 100 classes ativas (FIF)

SELECT
    classificacao_anbima,
    COUNT(*) AS qtd_classes,
    SUM(patrimonio_liquido) AS patrimonio_total
FROM classe
WHERE situacao = 'Em Funcionamento Normal'
  AND tipo_classe = 'Classes de Cotas de Fundos FIF'
  AND classificacao_anbima IS NOT NULL
GROUP BY classificacao_anbima
HAVING COUNT(*) >= 100
ORDER BY patrimonio_total DESC;


--  4. JOIN entre tabelas 
-- Administradores com maior número de classes ativas (classe → fundo → administrador)

SELECT
    a.nome AS administrador,
    COUNT(DISTINCT c.id_registro_classe) AS qtd_classes
FROM classe c
JOIN fundo f
    ON c.id_registro_fundo = f.id_registro_fundo
JOIN administrador a
    ON f.cnpj_administrador = a.cnpj_administrador
WHERE c.situacao = 'Em Funcionamento Normal'
GROUP BY a.nome
ORDER BY qtd_classes DESC
LIMIT 15;


-- Perguntas investigativas (EDA)

--  Pergunta 1 
-- Como evoluiu o valor da cota por classificação ANBIMA ao longo de 2025?

WITH classes_invalidas AS (
    SELECT DISTINCT cnpj_classe
    FROM informe_diario
    WHERE vl_quota <= 0.01
),
cota_extremos AS (
    SELECT DISTINCT
        i.cnpj_classe,
        i.id_subclasse,
        c.classificacao_anbima,
        FIRST_VALUE(i.vl_quota) OVER (
            PARTITION BY i.cnpj_classe, i.id_subclasse
            ORDER BY i.dt_comptc
        ) AS quota_inicial,
        LAST_VALUE(i.vl_quota) OVER (
            PARTITION BY i.cnpj_classe, i.id_subclasse
            ORDER BY i.dt_comptc
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS quota_final
    FROM informe_diario i
    JOIN classe c ON i.cnpj_classe = c.cnpj_classe
    WHERE c.tipo_classe = 'Classes de Cotas de Fundos FIF'
      AND c.classificacao_anbima IS NOT NULL
      AND i.cnpj_classe NOT IN (SELECT cnpj_classe FROM classes_invalidas)
)
SELECT
    classificacao_anbima,
    COUNT(*) AS qtd_classes,
    ROUND(MEDIAN((quota_final / quota_inicial - 1) * 100), 2) AS retorno_mediano_pct,
    ROUND(AVG((quota_final / quota_inicial - 1) * 100), 2)    AS retorno_medio_pct
FROM cota_extremos
WHERE quota_inicial > 0
GROUP BY classificacao_anbima
HAVING COUNT(*) >= 100
ORDER BY retorno_mediano_pct DESC;


-- Pergunta 2a
-- Quais classes tiveram maior captação líquida (captação - resgate) em 2025?

SELECT
    i.cnpj_classe,
    c.denominacao_social,
    c.classificacao_anbima,
    SUM(i.captc_dia)              AS captacao_total,
    SUM(i.resg_dia)               AS resgate_total,
    SUM(i.captc_dia - i.resg_dia) AS captacao_liquida
FROM informe_diario i
JOIN classe c ON i.cnpj_classe = c.cnpj_classe
WHERE c.tipo_classe = 'Classes de Cotas de Fundos FIF'
GROUP BY i.cnpj_classe, c.denominacao_social, c.classificacao_anbima
ORDER BY captacao_liquida DESC
LIMIT 15;


-- Pergunta 2b 
-- Há sazonalidade no fluxo de captação/resgate ao longo do ano?

SELECT
    EXTRACT(MONTH FROM i.dt_comptc) AS mes,
    SUM(i.captc_dia)              AS captacao_total,
    SUM(i.resg_dia)               AS resgate_total,
    SUM(i.captc_dia - i.resg_dia) AS captacao_liquida
FROM informe_diario i
JOIN classe c ON i.cnpj_classe = c.cnpj_classe
WHERE c.tipo_classe = 'Classes de Cotas de Fundos FIF'
GROUP BY mes
ORDER BY mes;


-- Pergunta 3 
-- Quais administradores concentram maior patrimônio entre os fundos
-- FIF ativos em 2025?

WITH pl_admin AS (
    SELECT
        a.nome AS administrador,
        SUM(c.patrimonio_liquido) AS patrimonio_total
    FROM classe c
    JOIN fundo f ON c.id_registro_fundo = f.id_registro_fundo
    JOIN administrador a ON f.cnpj_administrador = a.cnpj_administrador
    WHERE c.situacao = 'Em Funcionamento Normal'
      AND c.tipo_classe = 'Classes de Cotas de Fundos FIF'
    GROUP BY a.nome
)
SELECT
    administrador,
    patrimonio_total,
    ROUND(100.0 * patrimonio_total / SUM(patrimonio_total) OVER (), 2) AS pct_mercado,
    ROUND(100.0 * SUM(patrimonio_total) OVER (
        ORDER BY patrimonio_total DESC
    ) / SUM(patrimonio_total) OVER (), 2) AS pct_acumulado
FROM pl_admin
ORDER BY patrimonio_total DESC
LIMIT 15;


-- Pergunta 4
-- Qual classificação ANBIMA apresenta maior volatilidade no valor da cota?


WITH classes_invalidas AS (
    SELECT DISTINCT cnpj_classe
    FROM informe_diario
    WHERE vl_quota <= 0.01
),
retornos AS (
    SELECT
        i.cnpj_classe,
        i.id_subclasse,
        c.classificacao_anbima,
        i.vl_quota / LAG(i.vl_quota) OVER (
            PARTITION BY i.cnpj_classe, i.id_subclasse
            ORDER BY i.dt_comptc
        ) - 1 AS retorno_diario
    FROM informe_diario i
    JOIN classe c ON i.cnpj_classe = c.cnpj_classe
    WHERE c.tipo_classe = 'Classes de Cotas de Fundos FIF'
      AND c.classificacao_anbima IS NOT NULL
      AND i.cnpj_classe NOT IN (SELECT cnpj_classe FROM classes_invalidas)
)
SELECT
    classificacao_anbima,
    COUNT(DISTINCT cnpj_classe)              AS qtd_classes,
    ROUND(STDDEV(retorno_diario) * 100, 4)   AS volatilidade_pct
FROM retornos
WHERE retorno_diario IS NOT NULL
  AND ABS(retorno_diario) <= 10
GROUP BY classificacao_anbima
HAVING COUNT(DISTINCT cnpj_classe) >= 100
ORDER BY volatilidade_pct DESC;