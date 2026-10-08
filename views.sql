USE dashboard_tcc;

-- Cada linha de avistamento representa um avistamento.
-- A media usa todos os anos anteriores presentes na tabela, contando
-- como zero os meses sem registros nesses anos.
CREATE OR REPLACE SQL SECURITY INVOKER VIEW vw_avistamentos_mensal AS
WITH
meses AS (
    SELECT 1 AS numero, 'Janeiro' AS nome
    UNION ALL SELECT 2, 'Fevereiro'
    UNION ALL SELECT 3, 'Março'
    UNION ALL SELECT 4, 'Abril'
    UNION ALL SELECT 5, 'Maio'
    UNION ALL SELECT 6, 'Junho'
    UNION ALL SELECT 7, 'Julho'
    UNION ALL SELECT 8, 'Agosto'
    UNION ALL SELECT 9, 'Setembro'
    UNION ALL SELECT 10, 'Outubro'
    UNION ALL SELECT 11, 'Novembro'
    UNION ALL SELECT 12, 'Dezembro'
),
referencia AS (
    SELECT YEAR(CURDATE()) AS ano
),
dados AS (
    -- timestamp esta armazenado como texto no formato ISO 8601.
    SELECT
        CAST(LEFT(`timestamp`, 4) AS UNSIGNED) AS ano,
        CAST(SUBSTRING(`timestamp`, 6, 2) AS UNSIGNED) AS mes
    FROM avistamento
    WHERE `timestamp` REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])-'
),
historico AS (
    SELECT COUNT(DISTINCT d.ano) AS quantidade_anos
    FROM dados d
    CROSS JOIN referencia r
    WHERE d.ano < r.ano
)
SELECT
    m.nome AS mes,
    COALESCE(
        ROUND(COUNT(CASE WHEN d.ano < r.ano THEN 1 END)
            / NULLIF(h.quantidade_anos, 0), 2),
        0.00
    ) AS media,
    COUNT(CASE WHEN d.ano = r.ano - 1 THEN 1 END) AS ano_passado,
    COUNT(CASE WHEN d.ano = r.ano THEN 1 END) AS atual
FROM meses m
CROSS JOIN referencia r
CROSS JOIN historico h
LEFT JOIN dados d ON d.mes = m.numero
GROUP BY m.numero, m.nome, r.ano, h.quantidade_anos
ORDER BY m.numero;
