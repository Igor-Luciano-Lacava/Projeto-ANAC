--ALÉM DA BASE DA NOSSA BASE DE DADOS E INSTRUÇÕES. ESTAMOS DANDO PERGUNTAS E QUERYS PRA BALIZAR ELE E DAR MAIS CONTEXTO. QUANTO MAIS CONTEXTO, MELHOR. BOM TER DIFERENTES FONTES PRA TER UM CONTEXTO MAIS ASSERTIVO, POR ISSO ESSE TANTO DE MÉTODOS DISTINTOS. ESSAS SÃO AS PERGUNTAS QUE CONSTRUÍMOS TODA ESSA ENGENHARIA DE DADOS PARA RESPONDÊ-LAS

"Como o atraso de partida evolui ao longo do dia?"
--qtd de voos atrasados / qtd de voos avaliaveis * 100
-- 
SELECT
    hora_partida_prevista                                                      AS hora,
    COUNT(*)                                                                   AS voos,
    ROUND(AVG(atraso_partida_min), 2)                                          AS atraso_medio_min,
    ROUND(
        100.0 * try_divide(
            SUM(CASE WHEN partida_pontual = false THEN 1 ELSE 0 END),
            SUM(CASE WHEN partida_pontual IS NOT NULL THEN 1 ELSE 0 END)
            ),
             2
    ) AS pct_atrasados
FROM voebem.gold.obt_voos
WHERE hora_partida_prevista IS NOT NULL
GROUP BY hora_partida_prevista
ORDER BY hora_partida_prevista;



"Qual companhia entrega a melhor pontualidade e a menor taxa de cancelamento?"
SELECT
    nome_companhia,
    COUNT(*)                                                                   AS voos,
    ROUND(100.0 * SUM(CASE WHEN voo_cancelado THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_cancelados,
    ROUND(100.0 * try_divide(SUM(CASE WHEN partida_pontual = true THEN 1 ELSE 0 END),
                             SUM(CASE WHEN partida_pontual IS NOT NULL THEN 1 ELSE 0 END)), 2) AS pct_pontuais,
    ROUND(AVG(atraso_partida_min), 2)                                          AS atraso_medio_min
FROM voebem.gold.obt_voos
GROUP BY 1
HAVING COUNT(*) >= 10000 -- PRECISA TER NO MINIMO 10000 VOOS
ORDER BY pct_pontuais DESC;



 "Quais aeroportos do Brasil concentram os maiores atrasos de partida?"
  SELECT
    nome_aeroporto_origem,
    municipio_origem,
    uf_origem,
    COUNT(*)                                                                   AS voos,
    ROUND(AVG(atraso_partida_min), 2)                                          AS atraso_medio_min,
    ROUND(100.0 * try_divide(SUM(CASE WHEN partida_pontual = false THEN 1 ELSE 0 END),
                             SUM(CASE WHEN partida_pontual IS NOT NULL THEN 1 ELSE 0 END)), 2) AS pct_atrasados
FROM voebem.gold.obt_voos
WHERE pais_origem = 'Brasil'
GROUP BY 1, 2, 3
HAVING COUNT(*) >= 5000
ORDER BY pct_atrasados DESC
LIMIT 10;



"Quais rotas domesticas tem o maior atraso medio de partida?"
SELECT
    rota_municipios,
    rota_icao,
    COUNT(*)                                                                   AS voos,
    ROUND(AVG(atraso_partida_min), 2)                                          AS atraso_medio_min,
    ROUND(100.0 * try_divide(SUM(CASE WHEN partida_pontual = false THEN 1 ELSE 0 END),
                             SUM(CASE WHEN partida_pontual IS NOT NULL THEN 1 ELSE 0 END)), 2) AS pct_atrasados
FROM voebem.gold.obt_voos
WHERE escopo_voo = 'Domestico'
GROUP BY 1, 2
HAVING COUNT(*) >= 2000
ORDER BY atraso_medio_min DESC
LIMIT 10;



"Voos internacionais atrasam mais que domesticos? Quanto?"
 SELECT
    escopo_voo,
    COUNT(*)                                                                   AS voos,
    ROUND(AVG(atraso_partida_min), 2)                                          AS atraso_medio_min,
    ROUND(100.0 * try_divide(SUM(CASE WHEN partida_pontual = false THEN 1 ELSE 0 END),
                             SUM(CASE WHEN partida_pontual IS NOT NULL THEN 1 ELSE 0 END)), 2) AS pct_atrasados
FROM voebem.gold.obt_voos
GROUP BY 1
ORDER BY voos DESC



"Em quais aeroportos brasileiros a diferenca de atraso entre internacional e domestico e maior?"
SELECT
    nome_aeroporto_origem,
    municipio_origem,
    SUM(CASE WHEN escopo_voo = 'Domestico'     THEN 1 ELSE 0 END)              AS voos_domesticos,
    SUM(CASE WHEN escopo_voo = 'Internacional' THEN 1 ELSE 0 END)              AS voos_internacionais,
    ROUND(AVG(CASE WHEN escopo_voo = 'Domestico'     THEN atraso_partida_min END), 2) AS atraso_domestico,
    ROUND(AVG(CASE WHEN escopo_voo = 'Internacional' THEN atraso_partida_min END), 2) AS atraso_internacional,
    ROUND(AVG(CASE WHEN escopo_voo = 'Internacional' THEN atraso_partida_min END)
        - AVG(CASE WHEN escopo_voo = 'Domestico'     THEN atraso_partida_min END), 2) AS diferenca_min
FROM voebem.gold.obt_voos
WHERE pais_origem = 'Brasil'
GROUP BY 1, 2
HAVING SUM(CASE WHEN escopo_voo = 'Internacional' THEN 1 ELSE 0 END) >= 2000
    AND SUM(CASE WHEN escopo_voo = 'Domestico'     THEN 1 ELSE 0 END) >= 2000
ORDER BY diferenca_min DESC
LIMIT 10



"Quanto atraso as companhias recuperam em voo?"
SELECT
    nome_companhia,
    COUNT(*)                                                                   AS voos,
    ROUND(AVG(atraso_partida_min), 2)                                          AS atraso_saida_min,
    ROUND(AVG(atraso_chegada_min), 2)                                          AS atraso_chegada_min,
    ROUND(AVG(minutos_recuperados), 2)                                         AS recuperados_medio_min
FROM voebem.gold.obt_voos
WHERE minutos_recuperados IS NOT NULL
GROUP BY 1
HAVING COUNT(*) >= 10000
ORDER BY recuperados_medio_min DESC



"Em quais rotas a recuperacao em voo nao acontece?"
SELECT
    rota_municipios,
    rota_icao,
    COUNT(*)                                                                   AS voos,
    ROUND(AVG(atraso_partida_min), 2)                                          AS atraso_saida_min,
    ROUND(AVG(atraso_chegada_min), 2)                                          AS atraso_chegada_min,
    ROUND(AVG(minutos_recuperados), 2)                                         AS recuperados_medio_min
FROM voebem.gold.obt_voos
WHERE minutos_recuperados IS NOT NULL
GROUP BY 1, 2
HAVING COUNT(*) >= 2000
ORDER BY recuperados_medio_min ASC
LIMIT 10


--AGORA, SÓ TESTAR PERGUNTANDO PRO GENIE!
