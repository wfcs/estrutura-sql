WITH FornecedorExtraction AS (
    SELECT 
        CONTACONTABILID,
        HISTORICOLANCAMENTO,
        VOUCHER,
        DATACRIACAO,
        DATALANCAMENTO,
        CONTACONTABIL,
        CENTROCUSTO,
        VALORMOVIMENTO,
        TRIM(SUBSTRING(
            HISTORICOLANCAMENTO, 
            CHARINDEX('Fornecedor', HISTORICOLANCAMENTO) + 11,
            CHARINDEX(' ', HISTORICOLANCAMENTO + ' ', CHARINDEX('Fornecedor', HISTORICOLANCAMENTO) + 11) 
            - CHARINDEX('Fornecedor', HISTORICOLANCAMENTO) - 11
        )) AS ID_FORNECEDOR
    FROM AX_RAZAOCONTABIL
    WHERE 
        DATACRIACAO >= '2024-01-01'
        AND CONTACONTABIL IN (
            '410206000002', '410301000002', '410304000002',
            '410601000018', '410301000001', '410304000001',
            '410401000001', '410302000001', '410302000002'
        )
        AND CENTROCUSTO IN ("& CentroCustos &")
        AND CHARINDEX('Fornecedor', HISTORICOLANCAMENTO) > 0
)

SELECT 
    fe.CONTACONTABILID,
    fe.HISTORICOLANCAMENTO,
    fe.VOUCHER,
    fe.DATACRIACAO,
    fe.DATALANCAMENTO,
    fe.CONTACONTABIL,
    fe.CENTROCUSTO,
    SUM(fe.VALORMOVIMENTO) AS VALORMOVIMENTO,
    fe.ID_FORNECEDOR,
    f.NomeFornecedor
FROM FornecedorExtraction fe
INNER JOIN DWFLEET_FORNECEDORES f ON f.Codigo = fe.ID_FORNECEDOR
GROUP BY 
    fe.CONTACONTABILID,
    fe.HISTORICOLANCAMENTO,
    fe.VOUCHER,
    fe.DATACRIACAO,
    fe.DATALANCAMENTO,
    fe.CONTACONTABIL,
    fe.CENTROCUSTO,
    fe.ID_FORNECEDOR,
    f.NomeFornecedor;


-- Gemini


WITH ExtractedFornecedor AS (
    SELECT
        a.*,
        SUBSTRING(
            a.HISTORICOLANCAMENTO,
            CHARINDEX('Fornecedor', a.HISTORICOLANCAMENTO) + 11,
            CHARINDEX(' ', a.HISTORICOLANCAMENTO + '-', CHARINDEX('Fornecedor', a.HISTORICOLANCAMENTO) + 11)
            - CHARINDEX('Fornecedor', a.HISTORICOLANCAMENTO) - 11
        ) AS ExtractedIDFornecedor
    FROM AX_RAZAOCONTABIL a
    WHERE a.datacriacao >= '2024-01-01'
        AND a.contacontabil IN (
            '410206000002', '410301000002', '410304000002',
            '410601000018', '410301000001', '410304000001',
            '410401000001', '410303000001', '410302000002'
        )
        AND a.centrocusto IN ("& CentroCustos &")
)
SELECT
    ef.CONTACONTABILID,
    ef.HISTORICOLANCAMENTO,
    ef.VOUCHER,
    ef.DATACRIACAO,
    ef.DATALANCAMENTO,
    ef.CONTACONTABIL,
    ef.CENTROCUSTO,
    SUM(ef.valormovimento) AS VALORMOVIMENTO,
    ef.ExtractedIDFornecedor,
    f.NomeFornecedor
FROM ExtractedFornecedor ef
INNER JOIN DWFLEET_FORNECEDORES f ON f.Codigo = ef.ExtractedIDFornecedor
GROUP BY
    ef.centrocusto,
    ef.datacriacao,
    ef.contacontabil,
    ef.historicolancamento,
    ef.voucher,
    ef.datalancamento,
    ef.contacontabilid,
    f.NomeFornecedor;



-- AX Financeiro

WITH ExtrairCodigoFornecedor AS (
    SELECT
        CONTACONTABILID,
        HISTORICOLANCAMENTO,
        VOUCHER,
        DATACRIACAO,
        DATALANCAMENTO,
        CONTACONTABIL,
        CENTROCUSTO,
        SUM(valormovimento) AS VALORMOVIMENTO,
        CASE 
            WHEN CHARINDEX('Fornecedor ', HISTORICOLANCAMENTO) > 0 
                AND CHARINDEX(' -', HISTORICOLANCAMENTO) > CHARINDEX('Fornecedor ', HISTORICOLANCAMENTO)
            THEN SUBSTRING(
                HISTORICOLANCAMENTO, 
                CHARINDEX('Fornecedor ', HISTORICOLANCAMENTO) + 11, 
                CHARINDEX(' -', HISTORICOLANCAMENTO) - (CHARINDEX('Fornecedor ', HISTORICOLANCAMENTO) + 11)
            )
            ELSE NULL -- Retorna NULL se os critérios não forem atendidos
        END AS CODIGOFORNECEDOR
    FROM AX_RAZAOCONTABIL
    WHERE datacriacao >= '2024-01-01'
    AND contacontabil IN ('410206000002', '410301000002', '410304000002',
                          '410601000018', '410301000001', '410304000001',
                          '410401000001', '410302000001', '410302000002')
    GROUP BY centrocusto,
             datacriacao,
             contacontabil,
             historicolancamento,
             voucher,
             datalancamento,
             contacontabilid
)
SELECT
    ecf.CONTACONTABILID,
    ecf.HISTORICOLANCAMENTO,
    ecf.VOUCHER,
    ecf.DATACRIACAO,
    ecf.DATALANCAMENTO,
    ecf.CONTACONTABIL,
    ecf.CENTROCUSTO,
    ecf.VALORMOVIMENTO,
    ecf.CODIGOFORNECEDOR,
    f.RAZAOSOCIAL
FROM ExtrairCodigoFornecedor ecf
INNER JOIN DWFLEET_FORNECEDORES f ON ecf.CODIGOFORNECEDOR = f.CODIGO
ORDER BY ecf.DATACRIACAO DESC;
