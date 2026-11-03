-- EncontraAFYA: Sistema Universitário de Achados e Perdidos
-- Requer MySQL 8.0.16 ou superior, pois versões anteriores não aplicam CHECK.

CREATE DATABASE encontraafya
  CHARACTER SET utf8mb4;

USE encontraafya;

-- As tabelas seguem a ordem das dependências: uma tabela só pode ter FK
-- para outra que já exista.

CREATE TABLE pessoa (
  id_pessoa     INT          AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(120) NOT NULL,
  email         VARCHAR(120) NOT NULL,
  matricula     VARCHAR(15)  NOT NULL,
  telefone      VARCHAR(20)  NULL,
  tipo_pessoa   VARCHAR(20)  NOT NULL,
  status        CHAR(1)      NOT NULL DEFAULT 'A',
  data_cadastro DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_pessoa_email UNIQUE (email),
  CONSTRAINT uq_pessoa_matricula UNIQUE (matricula),
  CONSTRAINT ck_pessoa_tipo_pessoa
    CHECK (tipo_pessoa IN ('ALUNO', 'PROFESSOR', 'FUNCIONARIO')),
  CONSTRAINT ck_pessoa_status
    CHECK (status IN ('A', 'I'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- O UNIQUE em id_pessoa transforma a relação em 1:1: uma pessoa só pode ter
-- um cadastro de funcionário responsável.
CREATE TABLE funcionario_responsavel (
  id_funcionario INT         AUTO_INCREMENT PRIMARY KEY,
  id_pessoa      INT         NOT NULL,
  setor          VARCHAR(60) NOT NULL,
  cargo          VARCHAR(60) NOT NULL,
  data_inicio    DATE        NOT NULL,
  CONSTRAINT uq_funcionario_responsavel_id_pessoa UNIQUE (id_pessoa),
  CONSTRAINT fk_funcionario_responsavel_pessoa
    FOREIGN KEY (id_pessoa) REFERENCES pessoa (id_pessoa)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE categoria (
  id_categoria INT          AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(60)  NOT NULL,
  descricao    VARCHAR(255) NULL,
  CONSTRAINT uq_categoria_nome UNIQUE (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- bloco e andar aceitam NULL porque há locais fora dos blocos, como o estacionamento.
CREATE TABLE local (
  id_local  INT          AUTO_INCREMENT PRIMARY KEY,
  nome      VARCHAR(80)  NOT NULL,
  bloco     VARCHAR(20)  NULL,
  andar     VARCHAR(20)  NULL,
  descricao VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE objeto (
  id_objeto    INT          AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(80)  NOT NULL,
  descricao    VARCHAR(255) NOT NULL,
  cor          VARCHAR(30)  NULL,
  marca        VARCHAR(60)  NULL,
  id_categoria INT          NOT NULL,
  CONSTRAINT fk_objeto_categoria
    FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- status guarda a situação atual para consulta rápida; historico_status guarda
-- a trilha das mudanças.
CREATE TABLE ocorrencia (
  id_ocorrencia   INT          AUTO_INCREMENT PRIMARY KEY,
  tipo            VARCHAR(20)  NOT NULL,
  data_ocorrencia DATE         NOT NULL,
  descricao       VARCHAR(255) NOT NULL,
  status          VARCHAR(20)  NOT NULL DEFAULT 'ABERTO',
  id_objeto       INT          NOT NULL,
  id_pessoa       INT          NOT NULL,
  id_local        INT          NOT NULL,
  data_registro   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_ocorrencia_tipo
    CHECK (tipo IN ('PERDIDO', 'ENCONTRADO')),
  CONSTRAINT ck_ocorrencia_status
    CHECK (status IN ('ABERTO', 'EM_ANALISE', 'DEVOLVIDO', 'ENCERRADO')),
  CONSTRAINT fk_ocorrencia_objeto
    FOREIGN KEY (id_objeto) REFERENCES objeto (id_objeto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ocorrencia_pessoa
    FOREIGN KEY (id_pessoa) REFERENCES pessoa (id_pessoa)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ocorrencia_local
    FOREIGN KEY (id_local) REFERENCES local (id_local)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Relação N:N entre ocorrencia e pessoa.
-- ON DELETE CASCADE: uma tentativa não existe sem a ocorrência.
CREATE TABLE tentativa_identificacao (
  id_tentativa   INT          AUTO_INCREMENT PRIMARY KEY,
  id_ocorrencia  INT          NOT NULL,
  id_pessoa      INT          NOT NULL,
  data_tentativa DATETIME     NOT NULL,
  meio_contato   VARCHAR(20)  NOT NULL,
  resultado      VARCHAR(20)  NOT NULL,
  observacao     VARCHAR(255) NULL,
  CONSTRAINT ck_tentativa_identificacao_meio_contato
    CHECK (meio_contato IN ('EMAIL', 'TELEFONE', 'PRESENCIAL', 'WHATSAPP')),
  CONSTRAINT ck_tentativa_identificacao_resultado
    CHECK (resultado IN ('CONFIRMADO', 'NAO_CONFIRMADO', 'SEM_RESPOSTA')),
  CONSTRAINT fk_tentativa_identificacao_ocorrencia
    FOREIGN KEY (id_ocorrencia) REFERENCES ocorrencia (id_ocorrencia)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_tentativa_identificacao_pessoa
    FOREIGN KEY (id_pessoa) REFERENCES pessoa (id_pessoa)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Relação N:N de ocorrencia com ela mesma.
-- O UNIQUE é composto: o par não se repete, mas cada ocorrência pode aparecer
-- em vários pares.
-- As duas FKs de ocorrência usam ON UPDATE RESTRICT porque as colunas fazem
-- parte de um CHECK, e o MySQL não aceita ON UPDATE CASCADE nesse caso (erro 3823).
-- O CHECK não consulta outras tabelas, então não verifica o tipo das ocorrências.
CREATE TABLE correspondencia (
  id_correspondencia       INT         AUTO_INCREMENT PRIMARY KEY,
  id_ocorrencia_encontrada INT         NOT NULL,
  id_ocorrencia_perdida    INT         NOT NULL,
  data_analise             DATE        NULL,
  situacao                 VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
  id_funcionario           INT         NULL,
  CONSTRAINT uq_correspondencia_par
    UNIQUE (id_ocorrencia_encontrada, id_ocorrencia_perdida),
  CONSTRAINT ck_correspondencia_ocorrencias
    CHECK (id_ocorrencia_encontrada <> id_ocorrencia_perdida),
  CONSTRAINT ck_correspondencia_situacao
    CHECK (situacao IN ('PENDENTE', 'CONFIRMADA', 'DESCARTADA')),
  CONSTRAINT fk_correspondencia_encontrada
    FOREIGN KEY (id_ocorrencia_encontrada) REFERENCES ocorrencia (id_ocorrencia)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_correspondencia_perdida
    FOREIGN KEY (id_ocorrencia_perdida) REFERENCES ocorrencia (id_ocorrencia)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT fk_correspondencia_funcionario
    FOREIGN KEY (id_funcionario) REFERENCES funcionario_responsavel (id_funcionario)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- O UNIQUE em id_ocorrencia transforma a relação em 1:1: uma ocorrência tem no
-- máximo uma devolução.
-- id_funcionario aponta para funcionario_responsavel para garantir a RN08.
CREATE TABLE devolucao (
  id_devolucao        INT          AUTO_INCREMENT PRIMARY KEY,
  id_ocorrencia       INT          NOT NULL,
  id_funcionario      INT          NOT NULL,
  id_pessoa_recebedor INT          NOT NULL,
  data_devolucao      DATE         NOT NULL,
  observacao          VARCHAR(255) NULL,
  CONSTRAINT uq_devolucao_id_ocorrencia UNIQUE (id_ocorrencia),
  CONSTRAINT fk_devolucao_ocorrencia
    FOREIGN KEY (id_ocorrencia) REFERENCES ocorrencia (id_ocorrencia)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_devolucao_funcionario
    FOREIGN KEY (id_funcionario) REFERENCES funcionario_responsavel (id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_devolucao_recebedor
    FOREIGN KEY (id_pessoa_recebedor) REFERENCES pessoa (id_pessoa)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Relação N:N entre ocorrencia e funcionario_responsavel.
CREATE TABLE historico_status (
  id_historico    INT         AUTO_INCREMENT PRIMARY KEY,
  id_ocorrencia   INT         NOT NULL,
  id_funcionario  INT         NOT NULL,
  status_anterior VARCHAR(20) NOT NULL,
  status_novo     VARCHAR(20) NOT NULL,
  data_alteracao  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_historico_status_anterior
    CHECK (status_anterior IN ('ABERTO', 'EM_ANALISE', 'DEVOLVIDO', 'ENCERRADO')),
  CONSTRAINT ck_historico_status_novo
    CHECK (status_novo IN ('ABERTO', 'EM_ANALISE', 'DEVOLVIDO', 'ENCERRADO')),
  CONSTRAINT ck_historico_status_diferente
    CHECK (status_anterior <> status_novo),
  CONSTRAINT fk_historico_status_ocorrencia
    FOREIGN KEY (id_ocorrencia) REFERENCES ocorrencia (id_ocorrencia)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_historico_status_funcionario
    FOREIGN KEY (id_funcionario) REFERENCES funcionario_responsavel (id_funcionario)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
