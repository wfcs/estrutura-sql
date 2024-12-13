--fOrdemdeCompras

WITH ConsultasMescladas AS (
    SELECT
        oc.DATACRIACAO,
        oc.CENTROCUSTO,
        oc.NUMEROORDEMCOMPRA,
        oc.NOMEFORNECEDORORDEM,
        oc.NOMEREQUISITANTE,
        oc.STATUSORDEMCOMPRA,
        it.CodigoMaterial,
        it.NomeMaterial,
        it.ValorTotal,
        it.CodigoRequisicaoCompras,
        it.TextoContabilizacao,
        it.STATUSLINHA,
        it.ContaDespesa,
        it.QUANTIDADE
    FROM DWFLEET_ORDEMCOMPRAS oc
    LEFT JOIN DWFLEET_ITENSORDEMCOMPRAS it
        ON oc.NumeroOrdemCompra = it.NumeroOrdemCompra
        AND oc.CentroCusto = it.CentroCusto
    WHERE oc.DATACRIACAO >= '2024-01-01' 
        AND it.DataCriacao >= '2024-01-01' 
)
/*
-- Coluna de Condicional Responsabilidade
ColunaCondicionalResponsabilidade AS (
    SELECT *,
          CASE 
              WHEN [Numero NF] IS NULL OR [Numero NF] = '' THEN 'Fornecedor'
              ELSE 'Financeiro'
          END AS CondicionalResponsabilidade
    FROM ConsultasMescladas
),
-- Calcular a diferença de dias entre DataCriacao e a data atual
SubtracaoDatas AS (
    SELECT *,
          DATEDIFF(DAY, DataCriacao, GETDATE()) AS Subtracao
    FROM ColunaCondicionalResponsabilidade
),
-- Criar a faixa de dias baseada na diferença calculada
FaixaDeDias AS (
    SELECT *,
          CASE 
              WHEN Subtracao <= 15 THEN 'A. Até 15 Dias'
              WHEN Subtracao <= 30 THEN 'B. 16 a 30 Dias'
              WHEN Subtracao <= 40 THEN 'C. 31 a 40 Dias'
              WHEN Subtracao <= 50 THEN 'D. 41 a 50 Dias'
              WHEN Subtracao <= 60 THEN 'E. 51 a 60 Dias'
              ELSE 'F. Acima de 60 Dias'
          END AS FaixaDeDias
    FROM SubtracaoDatas
) */


--fRazaoComtabil

  SELECT 
    a.CONTACONTABILID, 
    a.HISTORICOLANCAMENTO, 
    a.DATACRIACAO, 
    a.DATALANCAMENTO, 
    a.CONTACONTABIL, 
    a.CENTROCUSTO, 
    SUM(a.VALORMOVIMENTO) AS VALORMOVIMENTO,
    b.RazaoSocialFornecedor
FROM 
    AX_RAZAOCONTABIL a
/* INNER JOIN 
    DWFLEET_NOTASFISCAISFORNECEDOR b
    ON a.VOUCHER = b.NumeroComprovante */-- Ajuste aqui para a chave de relacionamento correta
WHERE 
    a.CONTACONTABIL IN ('410206000002', '410301000002', '410304000002', '410601000018',
                        '410301000001', '410304000001', '410401000001', '410302000001', 
                        '410302000002') 
    AND 
        a.DATACRIACAO >= '2024-01-01'
GROUP BY 
    a.CONTACONTABILID, 
    a.HISTORICOLANCAMENTO, 
    a.DATACRIACAO, 
    a.DATALANCAMENTO, 
    a.CONTACONTABIL, 
    a.CENTROCUSTO,
    b.RazaoSocialFornecedor
ORDER BY 
    a.DATACRIACAO DESC;

---Ordem de Serviço

-- Defina as variáveis de intervalo (RangeStart e RangeEnd)
DECLARE @DataAtual DATE = GETDATE(); -- Substitua pela data inicial desejada
DECLARE @DataHoraAtual DATETIME = DATEADD(HOUR, -3, DATE) ;
-- Consulta principal
WITH Fonte AS (
    SELECT 
        DataHoraCriacao,
        OrdemServico,
        Equipamento,
        DataConclusao,
        DescricaoEquipamento,
        Departamento,
        StatusDescricao,
        TipoOs,
        DataInicioProgramada,
        DataHoraUltimaAlteracao
    FROM HxGN_ordem_servico
),
IntervaloDias AS (
    SELECT *,
           DATEDIFF(DAY, DataInicioProgramada, @DataHoraAtual) AS DeltaProgramado
    FROM Fonte
),
 Tipodata AS (  --Tipodata = IF(HxGN_ordem_servico[DIFPROGRAMACAO]>0,"Atrasada","No Prazo") 
    SELECT *,
           CASE 
               WHEN DeltaProgramado > 0 THEN 'Atrasada'
               ELSE 'No prazo'
           END AS TipoDataNovo
    FROM IntervaloDias
),
StatusOS AS (
    SELECT *,
           CASE 
               WHEN DeltaProgramado > 0 THEN 'Atrasada'
               WHEN DeltaProgramado IS NULL THEN 'Sem data de inicio programda'
               ELSE 'No prazo'
           END AS StatusOSAtual
    FROM Tipodata
)
SELECT 
    DataHoraCriacao,
    OrdemServico,
    Equipamento,
    DataConclusao,
    DescricaoEquipamento,
    Departamento,
    StatusDescricao,
    CASE 
        WHEN TipoOs = 'BRKD' THEN 'MCE'
        ELSE TipoOs
    END AS TipoOs,
    CAST(DataInicioProgramada AS DATE) AS DataInicioProgramada,
    StatusOSAtual,
    TipoDataNovo
FROM StatusOS;

