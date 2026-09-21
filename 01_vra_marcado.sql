--ANOTAÇÕES GERAIS:

--aqui ele utiliza o conceito de DAG tb, que é execução não sincrona, ou seja, não entra em loop infinito

--pipeline é um bom caminho para aplicarmos qualidade. Usamos spark declarativo de pipelines, pq ele traz facilidade na avaliação da qualidade que queremos fazer. Temos as Constraints no databricks, que trazem validações em sql e executam no pipeline


--pipeline é limitada no free edition aqui do databricks, pq tem uma qtd de clusters serverless que podemos ter em execução aqui. Free edition não podemos ter mais que um. Ao criar um pipeline, você atribui um cluster serverless para ele, e no databricks, ele pode interpretar isso como você estar usando dois clusters separados se tiver duas pipelines em execução, então não dá certo

--vamos construir aqui na parte de qualidade pq queremos aplicar a constraint nessa fase, e ela só funciona em pipeline

--vamos realizar a orquestração dessa pipeline, ou seja, colocar a sequência de ações e tasks que ela vai executar sequencialmente 

--no spark declarative, colocar 01, 02 e 03 no nomes dos scripts inferem a ele a ordem de execução

--spark declarativo de pipelines funciona inclusive na versao open source do spark
--queremos colocar regras de qualidade e que essas regras, nesse momento, nao removerão essas linhas, vão apenas dizer que temos problemas, isso dentro da nossa tabela de vra.

--vra_marcado --> script que faz a marcação
--vra_auditado --> processo de verificação e auditoria
--vra_quarentena --> quais linhas tem problema   
--pipeline pode ter agendamento ou trigger pra fazer execução automática, ali na aba schedule

--Tipos de tasks:
--View --> script sql que toda vez que consulto aquele objeto, ele executa o script sql e me traz a saída
--Materialized View --> mesma coisa que o View, a diferença é que ela faz com que o dado persista, isso é, carregada fisicamente. Enquanto eu nao dar um refresh e atualizar essa view materializada ela vai continuar com o mesmo dado travado desde o momento em que a view foi atualizado pela ultima vez. é quase que uma job. 
--View pode dar tipo de visualizações diferentes para usuários de contextos diferentes

-- ---------------------------------------------------------------------------
-- Passo 1 — marcar cada voo com o resultado dos testes de integridade.
--
-- Expectation (spark declarativo de pipelines também, não sei se é a mesma coisa que expectation) NAO aceita subquery. E integridade referencial e, por definicao,
-- "existe na outra tabela?" — ou seja, uma subquery. A saida e resolver o join
-- AQUI, com LEFT JOIN + flag booleana, e deixar a expectation olhando so a flag.
--
-- Temporary view: e logica intermediaria do pipeline, nao dado publicado.
--
-- Repare no que NAO tem aqui: nenhuma classificacao. A versao anterior deste
-- arquivo criava escopo_origem/escopo_destino ('nacional'/'estrangeiro') pelo
-- prefixo ICAO. Isso e classificacao de negocio e o lugar dela e a gold.
-- Aqui so existe fato verificavel: o codigo esta ou nao esta no cadastro.

--Como não pode subquery, trabalhamos com uma view temporária e CTE
-- ---------------------------------------------------------------------------
CREATE TEMPORARY VIEW vra_marcado AS
WITH aerodromo AS (
  SELECT DISTINCT icao FROM voebem.silver.aerodromos --SÓ ICAOS (SIGLA DO AEROPORTO) UNICOS
  WHERE icao IS NOT NULL AND icao <> '' --ONDE NAO ESTIVER NULOS OU VAZIOS
),
empresa AS (
  SELECT DISTINCT icao FROM voebem.silver.empresas
  WHERE icao IS NOT NULL AND icao <> ''
)
--AGORA, MARCAÇÃO
SELECT
  v.*,
  (ao.icao IS NOT NULL) AS origem_no_cadastro,
  (ad.icao IS NOT NULL) AS destino_no_cadastro,
  (em.icao IS NOT NULL) AS empresa_no_cadastro
FROM voebem.silver.vra v
LEFT JOIN aerodromo ao ON v.icao_origem  = ao.icao
LEFT JOIN aerodromo ad ON v.icao_destino = ad.icao
LEFT JOIN empresa   em ON v.icao_empresa = em.icao;