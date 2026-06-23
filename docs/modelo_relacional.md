# Modelo Relacional — Fundos de Investimento (CVM)

Esquema relacional resultante do mapeamento ER → Relacional (Etapa 2),
já refletindo as correções identificadas durante a carga de dados real (Etapa 3).

Notação: `TABELA(pk sublinhada, atributos, fk → tabela_referenciada)`

---

## FUNDO

```
FUNDO(
    ID_Registro_Fundo,      -- PK
    CNPJ_Fundo,
    Denominacao_Social,
    Tipo_Fundo,
    Situacao,
    Data_Registro,
    Data_Constituicao,
    CNPJ_Administrador,     -- FK → ADMINISTRADOR
    CPF_CNPJ_Gestor         -- FK → GESTOR
)
```

> `CNPJ_Fundo` **não** é único — re-registros históricos na CVM (ex.: adaptações
> sucessivas à RCVM175) podem gerar múltiplos `ID_Registro_Fundo` para o mesmo CNPJ.

## CLASSE

```
CLASSE(
    ID_Registro_Classe,     -- PK
    ID_Registro_Fundo,      -- FK → FUNDO
    CNPJ_Classe,            -- UNIQUE
    Denominacao_Social,
    Tipo_Classe,
    Situacao,
    Classificacao,
    Classificacao_Anbima,
    Publico_Alvo,
    Patrimonio_Liquido
)
```

## ADMINISTRADOR

```
ADMINISTRADOR(
    CNPJ_Administrador,     -- PK
    Nome
)
```

## GESTOR

```
GESTOR(
    CPF_CNPJ_Gestor,        -- PK
    Nome,
    Tipo_Pessoa             -- CHECK IN ('PF', 'PJ')
)
```

## PRESTADOR_SERVICO

```
PRESTADOR_SERVICO(
    CNPJ,                   -- PK
    Nome
)
```

> Unifica Auditor, Custodiante e Controlador — estrutura idêntica entre os três.
> `Tipo` não está aqui: foi movido para `CLASSE_PRESTADOR` (ver nota abaixo).

## CLASSE_PRESTADOR (tabela associativa)

```
CLASSE_PRESTADOR(
    CNPJ_Classe,            -- PK (parte 1) + FK → CLASSE
    CNPJ_Prestador,         -- PK (parte 2) + FK → PRESTADOR_SERVICO
    Tipo                    -- PK (parte 3) — CHECK IN ('AUDITOR','CUSTODIANTE','CONTROLADOR')
)
```

> `Tipo` está aqui, e não em `PRESTADOR_SERVICO`, porque a mesma instituição
> pode atuar com papéis diferentes em classes diferentes (ex.: Auditor de uma
> classe e Custodiante de outra). É uma propriedade do relacionamento, não da
> entidade prestadora.

## INFORME_DIARIO

```
INFORME_DIARIO(
    CNPJ_Classe,            -- PK (parte 1) + FK → CLASSE
    ID_Subclasse,           -- PK (parte 2) — '' quando não aplicável
    DT_COMPTC,              -- PK (parte 3)
    VL_TOTAL,
    VL_QUOTA,
    VL_PATRIM_LIQ,
    CAPTC_DIA,              -- CHECK >= 0
    RESG_DIA,                -- CHECK >= 0
    NR_COTST                -- CHECK >= 0
)
```

> `ID_Subclasse` entra na chave porque ~1,2% dos informes são reportados no
> nível de subclasse — múltiplas subclasses podem compartilhar o mesmo
> `CNPJ_Classe` e mesma data.
>
> `VL_QUOTA` e `VL_PATRIM_LIQ` não têm restrição de sinal — valores negativos
> são possíveis quando as obrigações do fundo superam seus ativos (observado
> nos dados reais).

---

## Resumo de cardinalidades (origem ER)

| Relacionamento | Entidades | Cardinalidade | Participação |
|---|---|---|---|
| administra | Administrador — Fundo | 1:N | Parcial em Fundo |
| gere | Gestor — Fundo | 1:N | Parcial em ambos |
| possui | Fundo — Classe | 1:N | Total em Classe |
| contrata | Classe — Prestador_Servico | N:M | Parcial em ambos |
| gera | Classe — Informe_Diario | 1:N | Total em Informe |

Esquema completo, normalizado até 3FN. Detalhes da análise de dependências
funcionais e verificação de formas normais estão no relatório técnico,
Etapa 2.