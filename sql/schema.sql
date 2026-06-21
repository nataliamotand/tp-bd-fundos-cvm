-- ── ADMINISTRADOR ────────────────────────────────────────────
CREATE TABLE administrador (
    cnpj_administrador  VARCHAR(18) PRIMARY KEY,
    nome                VARCHAR(200) NOT NULL
);

-- ── GESTOR ───────────────────────────────────────────────────
CREATE TABLE gestor (
    cpf_cnpj_gestor  VARCHAR(18) PRIMARY KEY,
    nome             VARCHAR(200) NOT NULL,
    tipo_pessoa      VARCHAR(2) CHECK (tipo_pessoa IN ('PF', 'PJ'))
);

-- ── PRESTADOR_SERVICO ────────────────────────────────────────
-- Unifica Auditor, Custodiante e Controlador
CREATE TABLE prestador_servico (
    cnpj   VARCHAR(18) PRIMARY KEY,
    nome   VARCHAR(200) NOT NULL
);

-- ── FUNDO ────────────────────────────────────────────────────
CREATE TABLE fundo (
    id_registro_fundo    INTEGER PRIMARY KEY,
    cnpj_fundo           VARCHAR(18) NOT NULL,
    denominacao_social   VARCHAR(300) NOT NULL,
    tipo_fundo           VARCHAR(100),
    situacao             VARCHAR(50) NOT NULL,
    data_registro        DATE,
    data_constituicao    DATE,
    cnpj_administrador   VARCHAR(18) REFERENCES administrador(cnpj_administrador),
    cpf_cnpj_gestor      VARCHAR(18) REFERENCES gestor(cpf_cnpj_gestor)
);

-- ── CLASSE ───────────────────────────────────────────────────
CREATE TABLE classe (
    id_registro_classe     INTEGER PRIMARY KEY,
    id_registro_fundo      INTEGER NOT NULL REFERENCES fundo(id_registro_fundo),
    cnpj_classe             VARCHAR(18) NOT NULL UNIQUE,
    denominacao_social      VARCHAR(300) NOT NULL,
    tipo_classe             VARCHAR(100),
    situacao                VARCHAR(50) NOT NULL,
    classificacao           VARCHAR(100),
    classificacao_anbima    VARCHAR(150),
    publico_alvo            VARCHAR(100),
    patrimonio_liquido      DECIMAL(18, 2)
);

-- ── CLASSE_PRESTADOR (tabela associativa) ───────────────────
CREATE TABLE classe_prestador (
    cnpj_classe      VARCHAR(18) NOT NULL REFERENCES classe(cnpj_classe),
    cnpj_prestador   VARCHAR(18) NOT NULL REFERENCES prestador_servico(cnpj),
    tipo             VARCHAR(20) CHECK (tipo IN ('AUDITOR', 'CUSTODIANTE', 'CONTROLADOR')),

    PRIMARY KEY (cnpj_classe, cnpj_prestador, tipo)
);

-- ── INFORME_DIARIO ───────────────────────────────────────────
CREATE TABLE informe_diario (
    cnpj_classe      VARCHAR(18) NOT NULL REFERENCES classe(cnpj_classe),
    id_subclasse     VARCHAR(20) NOT NULL DEFAULT '',
    dt_comptc        DATE NOT NULL,
    vl_total         DECIMAL(18, 2),
    vl_quota         DECIMAL(20, 8),
    vl_patrim_liq    DECIMAL(18, 2),
    captc_dia        DECIMAL(18, 2) CHECK (captc_dia >= 0),
    resg_dia         DECIMAL(18, 2) CHECK (resg_dia >= 0),
    nr_cotst         INTEGER CHECK (nr_cotst >= 0),

    PRIMARY KEY (cnpj_classe, id_subclasse, dt_comptc)
);

-- Nota: a restrição "dt_comptc não pode ser data futura" não foi
-- implementada como CHECK porque o DuckDB não aceita funções
-- tipo CURRENT_DATE em constraints de tabela.