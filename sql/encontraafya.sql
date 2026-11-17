CREATE DATABASE encontraafya
  CHARACTER SET utf8mb4;

USE encontraafya;

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

-- ON UPDATE RESTRICT: o MySQL não aceita CASCADE em colunas usadas em CHECK (erro 3823).
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

-- Povoamento

INSERT INTO pessoa (id_pessoa, nome, email, matricula, telefone, tipo_pessoa, status, data_cadastro) VALUES
  (1,  'Ana Beatriz Souza',          'ana.souza@aluno.afya.edu.br',          '202410157', '(31) 98741-2201', 'ALUNO',       'A', '2026-02-03 09:12:00'),
  (2,  'Bruno Henrique Lima',        'bruno.lima@aluno.afya.edu.br',         '202310482', '(31) 99652-1187', 'ALUNO',       'A', '2026-02-03 09:40:00'),
  (3,  'Camila Ferreira Rocha',      'camila.rocha@aluno.afya.edu.br',       '202510233', NULL,              'ALUNO',       'A', '2026-02-03 10:05:00'),
  (4,  'Daniel Alves Pereira',       'daniel.pereira@aluno.afya.edu.br',     '202410398', '(31) 98815-3340', 'ALUNO',       'A', '2026-02-03 10:31:00'),
  (5,  'Eduarda Martins Costa',      'eduarda.costa@aluno.afya.edu.br',      '202310076', '(31) 99123-4578', 'ALUNO',       'A', '2026-02-04 08:20:00'),
  (6,  'Felipe Augusto Ribeiro',     'felipe.ribeiro@aluno.afya.edu.br',     '202410511', '(31) 98476-9902', 'ALUNO',       'A', '2026-02-04 08:55:00'),
  (7,  'Gabriela Nunes Carvalho',    'gabriela.carvalho@aluno.afya.edu.br',  '202510064', '(31) 99734-2615', 'ALUNO',       'A', '2026-02-04 11:17:00'),
  (8,  'Gustavo Oliveira Santos',    'gustavo.santos@aluno.afya.edu.br',     '202210349', '(31) 98290-7731', 'ALUNO',       'A', '2026-02-05 14:02:00'),
  (9,  'Helena Cristina Barros',     'helena.barros@aluno.afya.edu.br',      '202410622', NULL,              'ALUNO',       'A', '2026-02-05 15:48:00'),
  (10, 'Igor Matheus Teixeira',      'igor.teixeira@aluno.afya.edu.br',      '202310215', '(31) 99408-1153', 'ALUNO',       'A', '2026-02-06 09:30:00'),
  (11, 'Isabela Moreira Dias',       'isabela.dias@aluno.afya.edu.br',       '202510187', '(31) 98563-0048', 'ALUNO',       'A', '2026-02-06 10:12:00'),
  (12, 'João Pedro Cardoso',         'joao.cardoso@aluno.afya.edu.br',       '202410704', '(31) 99871-6620', 'ALUNO',       'A', '2026-02-09 08:45:00'),
  (13, 'Juliana Mendes Araújo',      'juliana.araujo@aluno.afya.edu.br',     '202310433', '(31) 98102-5597', 'ALUNO',       'A', '2026-02-09 13:20:00'),
  (14, 'Kaique Ramos Silva',         'kaique.silva@aluno.afya.edu.br',       '202510356', '(31) 99285-3014', 'ALUNO',       'A', '2026-02-09 16:05:00'),
  (15, 'Larissa Gomes Freitas',      'larissa.freitas@aluno.afya.edu.br',    '202410819', NULL,              'ALUNO',       'A', '2026-02-10 09:00:00'),
  (16, 'Lucas Gabriel Monteiro',     'lucas.monteiro@aluno.afya.edu.br',     '202210588', '(31) 98937-4482', 'ALUNO',       'A', '2026-02-10 10:40:00'),
  (17, 'Mariana Lopes Batista',      'mariana.batista@aluno.afya.edu.br',    '202310690', '(31) 99546-7203', 'ALUNO',       'A', '2026-02-10 14:25:00'),
  (18, 'Mateus Vieira Campos',       'mateus.campos@aluno.afya.edu.br',      '202510421', '(31) 98674-1139', 'ALUNO',       'A', '2026-02-11 08:10:00'),
  (19, 'Natália Pires Correia',      'natalia.correia@aluno.afya.edu.br',    '202410947', '(31) 99013-8856', 'ALUNO',       'A', '2026-02-11 11:33:00'),
  (20, 'Otávio Cunha Moura',         'otavio.moura@aluno.afya.edu.br',       '202310758', '(31) 98351-2790', 'ALUNO',       'A', '2026-02-12 09:05:00'),
  (21, 'Paula Regina Farias',        'paula.farias@aluno.afya.edu.br',       '202510498', '(31) 99467-3321', 'ALUNO',       'A', '2026-02-12 15:50:00'),
  (22, 'Pedro Henrique Duarte',      'pedro.duarte@aluno.afya.edu.br',       '202411036', '(31) 98218-6604', 'ALUNO',       'A', '2026-02-13 10:15:00'),
  (23, 'Rafaela Castro Pinto',       'rafaela.pinto@aluno.afya.edu.br',      '202210812', NULL,              'ALUNO',       'A', '2026-02-13 13:42:00'),
  (24, 'Renan Sousa Tavares',        'renan.tavares@aluno.afya.edu.br',      '202310871', '(31) 99752-0917', 'ALUNO',       'A', '2026-02-16 08:30:00'),
  (25, 'Sabrina Melo Andrade',       'sabrina.andrade@aluno.afya.edu.br',    '202510533', '(31) 98429-5578', 'ALUNO',       'A', '2026-02-16 09:55:00'),
  (26, 'Samuel Rezende Lacerda',     'samuel.lacerda@aluno.afya.edu.br',     '202411102', '(31) 99186-2245', 'ALUNO',       'A', '2026-02-17 14:10:00'),
  (27, 'Thaís Fonseca Brito',        'thais.brito@aluno.afya.edu.br',        '202310925', '(31) 98845-7031', 'ALUNO',       'A', '2026-02-18 11:20:00'),
  (28, 'Thiago Barbosa Neves',       'thiago.neves@aluno.afya.edu.br',       '202510612', '(31) 99631-4486', 'ALUNO',       'A', '2026-02-19 16:45:00'),
  (29, 'Valentina Rocha Leal',       'valentina.leal@aluno.afya.edu.br',     '202411187', NULL,              'ALUNO',       'A', '2026-02-20 10:00:00'),
  (30, 'Vinícius Azevedo Prado',     'vinicius.prado@aluno.afya.edu.br',     '202211063', '(31) 98572-9914', 'ALUNO',       'A', '2026-02-23 08:35:00'),
  (31, 'Yasmin Coelho Machado',      'yasmin.machado@aluno.afya.edu.br',     '202510705', '(31) 99308-6152', 'ALUNO',       'A', '2026-03-02 09:25:00'),
  (32, 'Arthur Miranda Sales',       'arthur.sales@aluno.afya.edu.br',       '202411240', '(31) 98163-0375', 'ALUNO',       'A', '2026-03-02 13:05:00'),
  (33, 'Letícia Guimarães Paiva',    'leticia.paiva@aluno.afya.edu.br',      '202311004', '(31) 99894-2768', 'ALUNO',       'A', '2026-03-03 10:50:00'),
  (34, 'Caio Rodrigues Viana',       'caio.viana@aluno.afya.edu.br',         '202210977', '(31) 98036-5541', 'ALUNO',       'I', '2026-02-05 09:15:00'),
  (35, 'Beatriz Antunes Siqueira',   'beatriz.siqueira@aluno.afya.edu.br',   '202310512', NULL,              'ALUNO',       'I', '2026-02-06 14:30:00'),
  (36, 'Rodrigo Peixoto Marques',    'rodrigo.marques@aluno.afya.edu.br',    '202411315', '(31) 99215-8873', 'ALUNO',       'I', '2026-02-12 11:45:00'),
  (37, 'Marcos Antônio Bezerra',     'marcos.bezerra@afya.edu.br',           'PROF1023',  '(31) 99702-3318', 'PROFESSOR',   'A', '2026-02-02 08:00:00'),
  (38, 'Patrícia Helena Cavalcanti', 'patricia.cavalcanti@afya.edu.br',      'PROF1047',  '(31) 98614-2059', 'PROFESSOR',   'A', '2026-02-02 08:05:00'),
  (39, 'Ricardo Luiz Fontes',        'ricardo.fontes@afya.edu.br',           'PROF1088',  '(31) 99527-6630', 'PROFESSOR',   'A', '2026-02-02 08:10:00'),
  (40, 'Simone Aparecida Torres',    'simone.torres@afya.edu.br',            'PROF1102',  '(31) 98390-1447', 'PROFESSOR',   'A', '2026-02-02 08:15:00'),
  (41, 'André Luís Medeiros',        'andre.medeiros@afya.edu.br',           'PROF1135',  '(31) 99158-7724', 'PROFESSOR',   'A', '2026-02-02 08:20:00'),
  (42, 'Cláudia Regina Pacheco',     'claudia.pacheco@afya.edu.br',          'PROF1169',  '(31) 98827-4096', 'PROFESSOR',   'A', '2026-02-02 08:25:00'),
  (43, 'Fernando José Albuquerque',  'fernando.albuquerque@afya.edu.br',     'PROF1191',  '(31) 99436-5182', 'PROFESSOR',   'A', '2026-02-02 08:30:00'),
  (44, 'Luciana Maria Sampaio',      'luciana.sampaio@afya.edu.br',          'PROF1224',  '(31) 98705-3361', 'PROFESSOR',   'A', '2026-02-02 08:35:00'),
  (45, 'Roberto Fábio Dantas',       'roberto.dantas@afya.edu.br',           'PROF1258',  NULL,              'PROFESSOR',   'A', '2026-02-02 08:40:00'),
  (46, 'Adriana Souza Lemos',        'adriana.lemos@afya.edu.br',            'FUNC2011',  '(31) 99620-1835', 'FUNCIONARIO', 'A', '2026-02-02 07:30:00'),
  (47, 'Carlos Eduardo Brandão',     'carlos.brandao@afya.edu.br',           'FUNC2024',  '(31) 98741-6092', 'FUNCIONARIO', 'A', '2026-02-02 07:32:00'),
  (48, 'Denise Ferraz Quintela',     'denise.quintela@afya.edu.br',          'FUNC2038',  '(31) 99385-2207', 'FUNCIONARIO', 'A', '2026-02-02 07:34:00'),
  (49, 'Edson Pereira Lobo',         'edson.lobo@afya.edu.br',               'FUNC2045',  '(31) 98512-7740', 'FUNCIONARIO', 'A', '2026-02-02 07:36:00'),
  (50, 'Fátima Cristina Rangel',     'fatima.rangel@afya.edu.br',            'FUNC2059',  '(31) 99247-3318', 'FUNCIONARIO', 'A', '2026-02-02 07:38:00'),
  (51, 'Geraldo Magno Bastos',       'geraldo.bastos@afya.edu.br',           'FUNC2063',  '(31) 98906-1452', 'FUNCIONARIO', 'A', '2026-02-02 07:40:00'),
  (52, 'Jéssica Aline Furtado',      'jessica.furtado@afya.edu.br',          'FUNC2077',  '(31) 99158-6623', 'FUNCIONARIO', 'A', '2026-02-02 07:42:00'),
  (53, 'Márcio Roberto Gusmão',      'marcio.gusmao@afya.edu.br',            'FUNC2082',  '(31) 98363-0971', 'FUNCIONARIO', 'A', '2026-02-02 07:44:00'),
  (54, 'Neide Aparecida Couto',      'neide.couto@afya.edu.br',              'FUNC2096',  '(31) 99714-5586', 'FUNCIONARIO', 'A', '2026-02-02 07:46:00'),
  (55, 'Osvaldo Lins Barreto',       'osvaldo.barreto@afya.edu.br',          'FUNC2101',  '(31) 98025-9134', 'FUNCIONARIO', 'A', '2026-02-02 07:48:00'),
  (56, 'Priscila Damasceno Reis',    'priscila.reis@afya.edu.br',            'FUNC2115',  '(31) 99463-2078', 'FUNCIONARIO', 'A', '2026-02-02 07:50:00'),
  (57, 'Raimundo Nonato Freire',     'raimundo.freire@afya.edu.br',          'FUNC2120',  '(31) 98819-4405', 'FUNCIONARIO', 'A', '2026-02-02 07:52:00'),
  (58, 'Sandra Lúcia Bittencourt',   'sandra.bittencourt@afya.edu.br',       'FUNC2134',  '(31) 99572-8361', 'FUNCIONARIO', 'A', '2026-02-02 07:54:00'),
  (59, 'Valter Henrique Moraes',     'valter.moraes@afya.edu.br',            'FUNC2148',  '(31) 98234-6619', 'FUNCIONARIO', 'A', '2026-02-02 07:56:00'),
  (60, 'Wellington Sá Cordeiro',     'wellington.cordeiro@afya.edu.br',      'FUNC2153',  '(31) 99681-0247', 'FUNCIONARIO', 'A', '2026-02-02 07:58:00');

INSERT INTO funcionario_responsavel (id_funcionario, id_pessoa, setor, cargo, data_inicio) VALUES
  (1,  46, 'Achados e Perdidos',    'Coordenadora de Achados e Perdidos', '2021-03-01'),
  (2,  47, 'Portaria',              'Porteiro',                           '2019-05-13'),
  (3,  48, 'Biblioteca',            'Bibliotecária',                      '2018-08-06'),
  (4,  49, 'Segurança Patrimonial', 'Vigilante',                          '2020-01-20'),
  (5,  50, 'Secretaria Acadêmica',  'Assistente Administrativa',          '2022-02-14'),
  (6,  51, 'Segurança Patrimonial', 'Supervisor de Segurança',            '2017-09-04'),
  (7,  52, 'Achados e Perdidos',    'Assistente de Atendimento',          '2024-07-01'),
  (8,  53, 'Laboratórios',          'Técnico de Laboratório',             '2021-08-02'),
  (9,  54, 'Serviços Gerais',       'Auxiliar de Limpeza',                '2016-03-07'),
  (10, 55, 'Portaria',              'Porteiro',                           '2023-01-09'),
  (11, 56, 'Biblioteca',            'Auxiliar de Biblioteca',             '2025-02-03'),
  (12, 57, 'Serviços Gerais',       'Encarregado de Limpeza',             '2015-06-15'),
  (13, 58, 'Coordenação de Curso',  'Secretária de Coordenação',          '2020-10-05'),
  (14, 59, 'Laboratórios',          'Técnico de Informática',             '2022-07-18'),
  (15, 60, 'Segurança Patrimonial', 'Vigilante',                          '2026-02-02');

INSERT INTO categoria (id_categoria, nome, descricao) VALUES
  (1,  'Eletrônicos',          'Celulares, fones, notebooks, carregadores e acessórios'),
  (2,  'Documentos',           'RG, CNH, carteirinha estudantil e outros documentos'),
  (3,  'Chaves',               'Chaves de casa, de carro e de armários'),
  (4,  'Garrafas e copos',     'Garrafas, copos térmicos e canecas'),
  (5,  'Vestuário',            'Casacos, bonés, cachecóis e outras peças de roupa'),
  (6,  'Material escolar',     'Cadernos, estojos, calculadoras e similares'),
  (7,  'Livros',               'Livros didáticos, apostilas e atlas'),
  (8,  'Acessórios',           'Relógios, cintos e outros acessórios pessoais'),
  (9,  'Bolsas e mochilas',    'Mochilas, bolsas e pastas'),
  (10, 'Óculos',               'Óculos de grau e de sol'),
  (11, 'Carteiras',            'Carteiras e porta-cartões'),
  (12, 'Guarda-chuvas',        NULL),
  (13, 'Artigos esportivos',   'Bolas, raquetes e equipamentos de treino'),
  (14, 'Joias e bijuterias',   'Anéis, pulseiras, colares e brincos'),
  (15, 'Itens de laboratório', 'Jalecos, óculos de proteção e materiais de aula prática');

INSERT INTO local (id_local, nome, bloco, andar, descricao) VALUES
  (1,  'Biblioteca Central',           'A',  'Térreo',   'Balcão de empréstimos e área de estudo'),
  (2,  'Sala de Estudos em Grupo',     'A',  '1º andar', 'Salas reserváveis da biblioteca'),
  (3,  'Cantina',                      NULL, NULL,       'Prédio de convivência ao lado do pátio'),
  (4,  'Pátio Central',                NULL, NULL,       'Área aberta com bancos entre os blocos'),
  (5,  'Estacionamento Principal',     NULL, NULL,       'Acesso pela portaria principal'),
  (6,  'Estacionamento de Motos',      NULL, NULL,       'Ao lado do ginásio'),
  (7,  'Portaria Principal',           NULL, NULL,       'Controle de acesso de pedestres'),
  (8,  'Ginásio Poliesportivo',        NULL, NULL,       'Quadra, arquibancada e vestiários'),
  (9,  'Auditório',                    'A',  'Térreo',   'Capacidade para 300 pessoas'),
  (10, 'Secretaria Acadêmica',         'A',  'Térreo',   'Atendimento ao aluno'),
  (11, 'Sala 101',                     'A',  '1º andar', 'Sala de aula teórica'),
  (12, 'Sala 204',                     'B',  '2º andar', 'Sala de aula teórica'),
  (13, 'Sala 305',                     'B',  '3º andar', NULL),
  (14, 'Laboratório de Informática 1', 'B',  'Térreo',   'Quarenta computadores'),
  (15, 'Laboratório de Informática 2', 'B',  '1º andar', 'Usado também para provas online'),
  (16, 'Laboratório de Química',       'C',  'Térreo',   'Exige jaleco e óculos de proteção'),
  (17, 'Laboratório de Anatomia',      'C',  '1º andar', 'Bancadas e peças anatômicas'),
  (18, 'Copiadora',                    'A',  'Térreo',   'Impressões e cópias');

INSERT INTO objeto (id_objeto, nome, descricao, cor, marca, id_categoria) VALUES
  (1,  'Celular',                'Capinha transparente com adesivo de planeta',  'Preto',        'Samsung',       1),
  (2,  'Carteira de couro',      'Contém cartões e carteirinha estudantil',      'Marrom',       NULL,            11),
  (3,  'Molho de chaves',        'Três chaves e chaveiro de time de futebol',    'Prateado',     NULL,            3),
  (4,  'Garrafa térmica',        'Garrafa de 500 ml com nome gravado na tampa',  'Azul',         'Stanley',       4),
  (5,  'Mochila',                'Mochila com notebook e caderno de anatomia',   'Preta',        'Nike',          9),
  (6,  'Óculos de grau',         'Armação redonda em estojo vermelho',           'Marrom',       'Ray-Ban',       10),
  (7,  'Fone de ouvido sem fio', 'Estojo de carregamento com arranhões',         'Branco',       'JBL',           1),
  (8,  'Moletom',                'Moletom com capuz e logo de Engenharia',       'Azul-marinho', NULL,            5),
  (9,  'Calculadora científica', 'Etiqueta com iniciais na parte de trás',       'Preta',        'Casio',         6),
  (10, 'RG',                     'Carteira de identidade em capa plástica',      NULL,           NULL,            2),
  (11, 'Notebook',               'Notebook em capa de neoprene',                 'Cinza',        'Lenovo',        1),
  (12, 'Guarda-chuva',           'Guarda-chuva retrátil com cabo de madeira',    'Verde',        NULL,            12),
  (13, 'Livro de Cálculo',       'Volume 1 com anotações a lápis',               NULL,           NULL,            7),
  (14, 'Jaleco',                 'Jaleco com nome bordado no bolso',             'Branco',       NULL,            15),
  (15, 'Relógio',                'Relógio digital com pulseira de silicone',     'Preto',        'Casio',         8),
  (16, 'CNH',                    'Habilitação dentro de porta-documentos',       NULL,           NULL,            2),
  (17, 'Carteirinha estudantil', 'Carteirinha com foto e matrícula',             NULL,           NULL,            2),
  (18, 'Carregador de celular',  'Carregador USB-C com cabo de 1 metro',         'Branco',       'Motorola',      1),
  (19, 'Pen drive',              'Pen drive de 32 GB preso a um chaveiro',       'Vermelho',     'SanDisk',       1),
  (20, 'Chave de carro',         'Chave com controle de alarme',                 'Preta',        'Volkswagen',    3),
  (21, 'Copo térmico',           'Copo com tampa e canudo',                      'Rosa',         NULL,            4),
  (22, 'Caderno',                'Caderno de 10 matérias com capa de paisagem',  'Verde',        'Tilibra',       6),
  (23, 'Estojo',                 'Estojo com canetas coloridas e marca-texto',   'Roxo',         'Faber-Castell', 6),
  (24, 'Atlas de anatomia',      'Atlas de anatomia humana',                     NULL,           NULL,            7),
  (25, 'Bolsa transversal',      'Bolsa pequena com zíper quebrado',             'Bege',         NULL,            9),
  (26, 'Óculos de sol',          'Lentes espelhadas, sem estojo',                'Preto',        'Chilli Beans',  10),
  (27, 'Bolsa transversal',      'Bolsa pequena de couro sintético',             'Caramelo',     NULL,            9),
  (28, 'Boné',                   'Boné de aba reta',                             'Preto',        'Adidas',        5),
  (29, 'Bola de futsal',         'Bola com assinaturas do time',                 'Branca',       'Penalty',       13),
  (30, 'Pulseira',               'Pulseira de prata com pingente de coração',    'Prateada',     NULL,            14),
  (31, 'Óculos de sol',          'Lentes escuras e haste dourada',               'Preto',        'Ray-Ban',       10),
  (32, 'Fone de ouvido com fio', 'Fone intra-auricular enrolado',                'Preto',        'Samsung',       1),
  (33, 'Chave de carro',         'Chave com controle e chaveiro de borracha',    'Preta',        'Fiat',          3),
  (34, 'Cachecol',               'Cachecol de lã listrado',                      'Vermelho',     NULL,            5),
  (35, 'Óculos de proteção',     'Óculos de segurança para laboratório',         'Incolor',      '3M',            15);

INSERT INTO ocorrencia (id_ocorrencia, tipo, data_ocorrencia, descricao, status, id_objeto, id_pessoa, id_local, data_registro) VALUES
  (1,  'PERDIDO',    '2026-08-05', 'Celular esquecido na mesa durante o almoço',       'ENCERRADO',  1,  1,  3,  '2026-08-05 14:20:00'),
  (2,  'ENCONTRADO', '2026-08-05', 'Celular encontrado na mesa próxima ao caixa',      'DEVOLVIDO',  1,  54, 3,  '2026-08-05 15:05:00'),
  (3,  'PERDIDO',    '2026-08-07', 'Carteira perdida na área de estudo',               'ENCERRADO',  2,  8,  1,  '2026-08-07 10:40:00'),
  (4,  'ENCONTRADO', '2026-08-07', 'Carteira encontrada embaixo de uma mesa',          'DEVOLVIDO',  2,  3,  1,  '2026-08-07 11:15:00'),
  (5,  'ENCONTRADO', '2026-08-12', 'Molho de chaves encontrado no chão',               'DEVOLVIDO',  3,  49, 5,  '2026-08-12 07:50:00'),
  (6,  'PERDIDO',    '2026-08-12', 'Chaves perdidas entre o carro e o bloco A',        'ENCERRADO',  3,  37, 5,  '2026-08-12 12:30:00'),
  (7,  'ENCONTRADO', '2026-08-14', 'CNH encontrada perto da cancela',                  'DEVOLVIDO',  16, 47, 5,  '2026-08-14 08:10:00'),
  (8,  'PERDIDO',    '2026-08-18', 'Garrafa térmica esquecida após a aula',            'ENCERRADO',  4,  13, 12, '2026-08-18 21:15:00'),
  (9,  'ENCONTRADO', '2026-08-18', 'Garrafa térmica encontrada na última fileira',     'DEVOLVIDO',  4,  12, 12, '2026-08-18 21:40:00'),
  (10, 'ENCONTRADO', '2026-08-21', 'Mochila encontrada em uma bancada',                'DEVOLVIDO',  5,  53, 17, '2026-08-21 16:30:00'),
  (11, 'PERDIDO',    '2026-08-21', 'Mochila esquecida após a aula prática',            'ENCERRADO',  5,  19, 17, '2026-08-21 18:05:00'),
  (12, 'ENCONTRADO', '2026-08-25', 'Óculos de proteção deixados na bancada',           'ENCERRADO',  35, 53, 16, '2026-08-25 17:20:00'),
  (13, 'PERDIDO',    '2026-08-26', 'Óculos de grau perdidos durante palestra',         'ENCERRADO',  6,  40, 9,  '2026-08-26 20:30:00'),
  (14, 'ENCONTRADO', '2026-08-27', 'Estojo de óculos encontrado sob uma poltrona',     'DEVOLVIDO',  6,  22, 9,  '2026-08-27 08:45:00'),
  (15, 'ENCONTRADO', '2026-09-02', 'Fone sem fio encontrado na arquibancada',          'DEVOLVIDO',  7,  28, 8,  '2026-09-02 19:10:00'),
  (16, 'PERDIDO',    '2026-09-02', 'Fone de ouvido perdido durante o treino',          'ENCERRADO',  7,  16, 8,  '2026-09-02 21:00:00'),
  (17, 'PERDIDO',    '2026-09-08', 'Moletom esquecido no encosto da cadeira',          'ENCERRADO',  8,  6,  11, '2026-09-08 22:10:00'),
  (18, 'ENCONTRADO', '2026-09-09', 'Moletom encontrado durante a limpeza',             'DEVOLVIDO',  8,  54, 11, '2026-09-09 07:30:00'),
  (19, 'PERDIDO',    '2026-09-10', 'Estojo perdido após a prova de Cálculo',           'ENCERRADO',  23, 2,  13, '2026-09-10 19:45:00'),
  (20, 'PERDIDO',    '2026-09-14', 'Calculadora esquecida após a prova',               'ENCERRADO',  9,  24, 13, '2026-09-14 10:20:00'),
  (21, 'ENCONTRADO', '2026-09-14', 'Calculadora encontrada na mesa do professor',      'DEVOLVIDO',  9,  41, 13, '2026-09-14 10:55:00'),
  (22, 'PERDIDO',    '2026-09-17', 'RG perdido na fila de atendimento',                'ENCERRADO',  10, 27, 10, '2026-09-17 15:40:00'),
  (23, 'ENCONTRADO', '2026-09-17', 'RG encontrado no balcão de atendimento',           'DEVOLVIDO',  10, 50, 10, '2026-09-17 16:10:00'),
  (24, 'ENCONTRADO', '2026-09-23', 'Notebook deixado em uma das bancadas',             'DEVOLVIDO',  11, 59, 14, '2026-09-23 12:15:00'),
  (25, 'PERDIDO',    '2026-09-23', 'Notebook esquecido após a aula de programação',    'ENCERRADO',  11, 30, 14, '2026-09-23 13:00:00'),
  (26, 'ENCONTRADO', '2026-09-29', 'Carteirinha esquecida na copiadora',               'DEVOLVIDO',  17, 17, 18, '2026-09-29 11:25:00'),
  (27, 'PERDIDO',    '2026-10-01', 'Guarda-chuva esquecido em dia de chuva',           'ENCERRADO',  12, 42, 7,  '2026-10-01 18:50:00'),
  (28, 'ENCONTRADO', '2026-10-02', 'Guarda-chuva encontrado no suporte da portaria',   'DEVOLVIDO',  12, 55, 7,  '2026-10-02 07:15:00'),
  (29, 'PERDIDO',    '2026-10-08', 'Livro de Cálculo esquecido na sala de estudos',    'ENCERRADO',  13, 10, 2,  '2026-10-08 17:30:00'),
  (30, 'ENCONTRADO', '2026-10-09', 'Livro encontrado na sala de estudos 3',            'DEVOLVIDO',  13, 56, 2,  '2026-10-09 09:00:00'),
  (31, 'ENCONTRADO', '2026-10-15', 'Chave de carro encontrada ao lado de uma vaga',    'EM_ANALISE', 20, 49, 5,  '2026-10-15 22:30:00'),
  (32, 'PERDIDO',    '2026-10-14', 'Chave de carro perdida, talvez na sala de aula',   'EM_ANALISE', 33, 9,  11, '2026-10-16 08:30:00'),
  (33, 'PERDIDO',    '2026-10-16', 'Bolsa perdida no horário do almoço',               'EM_ANALISE', 27, 21, 3,  '2026-10-16 13:40:00'),
  (34, 'ENCONTRADO', '2026-10-20', 'Jaleco deixado no armário do laboratório',         'DEVOLVIDO',  14, 33, 16, '2026-10-20 11:50:00'),
  (35, 'PERDIDO',    '2026-10-20', 'Jaleco com nome bordado esquecido após a aula',    'ENCERRADO',  14, 5,  16, '2026-10-20 14:25:00'),
  (36, 'PERDIDO',    '2026-10-22', 'Óculos de sol perdidos entre o laboratório e o pátio', 'EM_ANALISE', 31, 7, 15, '2026-10-22 18:00:00'),
  (37, 'ENCONTRADO', '2026-10-23', 'Bolsa encontrada em um dos sofás',                 'EM_ANALISE', 25, 11, 1,  '2026-10-23 15:20:00'),
  (38, 'PERDIDO',    '2026-10-27', 'Relógio perdido durante o jogo',                   'ENCERRADO',  15, 20, 8,  '2026-10-27 21:30:00'),
  (39, 'ENCONTRADO', '2026-10-28', 'Relógio encontrado no vestiário durante a ronda',  'DEVOLVIDO',  15, 60, 8,  '2026-10-28 06:50:00'),
  (40, 'ENCONTRADO', '2026-10-30', 'Óculos de sol encontrados em um banco',            'EM_ANALISE', 26, 38, 4,  '2026-10-30 12:40:00'),
  (41, 'PERDIDO',    '2026-11-02', 'Caderno esquecido na sala',                        'ABERTO',     22, 15, 12, '2026-11-02 20:15:00'),
  (42, 'ENCONTRADO', '2026-11-03', 'Carregador esquecido na tomada',                   'ABERTO',     18, 4,  15, '2026-11-03 16:45:00'),
  (43, 'PERDIDO',    '2026-11-04', 'Atlas de anatomia esquecido na bancada',           'ABERTO',     24, 23, 17, '2026-11-04 10:30:00'),
  (44, 'ENCONTRADO', '2026-11-05', 'Pen drive conectado em um computador',             'ABERTO',     19, 14, 14, '2026-11-05 09:20:00'),
  (45, 'ENCONTRADO', '2026-11-06', 'Copo térmico deixado em uma mesa',                 'ABERTO',     21, 54, 3,  '2026-11-06 14:00:00'),
  (46, 'PERDIDO',    '2026-11-06', 'Pulseira perdida durante evento no auditório',     'ABERTO',     30, 25, 9,  '2026-11-06 22:00:00'),
  (47, 'PERDIDO',    '2026-11-08', 'Fone de ouvido perdido na cantina',                'ABERTO',     32, 18, 3,  '2026-11-08 12:50:00'),
  (48, 'ENCONTRADO', '2026-11-09', 'Boné encontrado em um banco do pátio',             'ABERTO',     28, 26, 4,  '2026-11-09 17:35:00'),
  (49, 'ENCONTRADO', '2026-11-10', 'Bola de futsal encontrada na quadra',              'ABERTO',     29, 49, 8,  '2026-11-10 08:05:00'),
  (50, 'PERDIDO',    '2026-11-10', 'Cachecol esquecido no balcão',                     'ABERTO',     34, 44, 1,  '2026-11-10 16:20:00');

INSERT INTO tentativa_identificacao (id_tentativa, id_ocorrencia, id_pessoa, data_tentativa, meio_contato, resultado, observacao) VALUES
  (1,  2,  14, '2026-08-06 09:30:00', 'PRESENCIAL', 'NAO_CONFIRMADO', 'Procurava um celular de outro modelo'),
  (2,  2,  1,  '2026-08-06 10:00:00', 'WHATSAPP',   'CONFIRMADO',     'Descreveu a capinha e o adesivo'),
  (3,  4,  8,  '2026-08-08 09:00:00', 'EMAIL',      'CONFIRMADO',     'Informou os cartões da carteira'),
  (4,  5,  37, '2026-08-12 14:30:00', 'TELEFONE',   'SEM_RESPOSTA',   NULL),
  (5,  5,  37, '2026-08-12 16:00:00', 'EMAIL',      'CONFIRMADO',     'Descreveu o chaveiro'),
  (6,  7,  39, '2026-08-14 09:30:00', 'EMAIL',      'SEM_RESPOSTA',   'Contato localizado pelo nome na CNH'),
  (7,  7,  39, '2026-08-17 10:00:00', 'TELEFONE',   'CONFIRMADO',     NULL),
  (8,  9,  13, '2026-08-19 09:00:00', 'WHATSAPP',   'CONFIRMADO',     'Nome gravado na tampa conferido'),
  (9,  10, 19, '2026-08-21 19:00:00', 'TELEFONE',   'CONFIRMADO',     NULL),
  (10, 12, 40, '2026-08-27 10:30:00', 'PRESENCIAL', 'NAO_CONFIRMADO', 'Procurava óculos de grau'),
  (11, 14, 40, '2026-08-27 11:00:00', 'PRESENCIAL', 'CONFIRMADO',     'Reconheceu o estojo vermelho'),
  (12, 15, 16, '2026-09-03 09:30:00', 'EMAIL',      'SEM_RESPOSTA',   NULL),
  (13, 15, 16, '2026-09-03 18:00:00', 'WHATSAPP',   'CONFIRMADO',     NULL),
  (14, 18, 6,  '2026-09-10 09:00:00', 'WHATSAPP',   'CONFIRMADO',     'Logo do curso conferido'),
  (15, 21, 2,  '2026-09-15 09:15:00', 'TELEFONE',   'NAO_CONFIRMADO', 'Procurava um estojo'),
  (16, 21, 24, '2026-09-15 10:00:00', 'EMAIL',      'CONFIRMADO',     NULL),
  (17, 23, 27, '2026-09-18 08:30:00', 'TELEFONE',   'CONFIRMADO',     NULL),
  (18, 24, 32, '2026-09-23 14:20:00', 'PRESENCIAL', 'NAO_CONFIRMADO', 'Notebook de outra marca'),
  (19, 24, 30, '2026-09-23 15:00:00', 'EMAIL',      'CONFIRMADO',     NULL),
  (20, 26, 31, '2026-09-29 14:30:00', 'WHATSAPP',   'SEM_RESPOSTA',   NULL),
  (21, 26, 31, '2026-09-30 08:30:00', 'EMAIL',      'CONFIRMADO',     'Matrícula conferida'),
  (22, 28, 42, '2026-10-05 09:00:00', 'EMAIL',      'CONFIRMADO',     NULL),
  (23, 30, 10, '2026-10-13 09:45:00', 'EMAIL',      'SEM_RESPOSTA',   NULL),
  (24, 30, 10, '2026-10-13 10:00:00', 'WHATSAPP',   'CONFIRMADO',     NULL),
  (25, 31, 43, '2026-10-16 10:00:00', 'TELEFONE',   'NAO_CONFIRMADO', 'Chave de outro modelo de carro'),
  (26, 34, 5,  '2026-10-21 09:30:00', 'EMAIL',      'CONFIRMADO',     NULL),
  (27, 37, 21, '2026-10-24 10:00:00', 'WHATSAPP',   'SEM_RESPOSTA',   NULL),
  (28, 39, 18, '2026-10-29 08:00:00', 'PRESENCIAL', 'NAO_CONFIRMADO', 'Relógio de outra marca'),
  (29, 39, 20, '2026-10-29 09:00:00', 'WHATSAPP',   'CONFIRMADO',     NULL),
  (30, 40, 7,  '2026-10-31 11:00:00', 'EMAIL',      'SEM_RESPOSTA',   NULL);

INSERT INTO correspondencia (id_correspondencia, id_ocorrencia_encontrada, id_ocorrencia_perdida, data_analise, situacao, id_funcionario) VALUES
  (1,  2,  1,  '2026-08-06', 'CONFIRMADA', 1),
  (2,  4,  3,  '2026-08-08', 'CONFIRMADA', 3),
  (3,  5,  6,  '2026-08-12', 'CONFIRMADA', 4),
  (4,  9,  8,  '2026-08-19', 'CONFIRMADA', 1),
  (5,  10, 11, '2026-08-21', 'CONFIRMADA', 8),
  (6,  12, 13, '2026-08-27', 'DESCARTADA', 7),
  (7,  14, 13, '2026-08-27', 'CONFIRMADA', 7),
  (8,  15, 16, '2026-09-03', 'CONFIRMADA', 1),
  (9,  18, 17, '2026-09-10', 'CONFIRMADA', 7),
  (10, 21, 19, '2026-09-15', 'DESCARTADA', 13),
  (11, 21, 20, '2026-09-15', 'CONFIRMADA', 13),
  (12, 23, 22, '2026-09-18', 'CONFIRMADA', 5),
  (13, 24, 25, '2026-09-23', 'CONFIRMADA', 14),
  (14, 28, 27, '2026-10-05', 'CONFIRMADA', 10),
  (15, 30, 29, '2026-10-13', 'CONFIRMADA', 11),
  (16, 31, 32, '2026-10-17', 'DESCARTADA', 6),
  (17, 34, 35, '2026-10-21', 'CONFIRMADA', 8),
  (18, 39, 38, '2026-10-29', 'CONFIRMADA', 6),
  (19, 37, 33, NULL,         'PENDENTE',   NULL),
  (20, 40, 36, NULL,         'PENDENTE',   NULL);

INSERT INTO devolucao (id_devolucao, id_ocorrencia, id_funcionario, id_pessoa_recebedor, data_devolucao, observacao) VALUES
  (1,  2,  1,  1,  '2026-08-06', 'Dona desbloqueou a tela na frente do atendente'),
  (2,  4,  3,  8,  '2026-08-08', 'Documentos da carteira conferidos'),
  (3,  5,  4,  37, '2026-08-13', NULL),
  (4,  7,  2,  39, '2026-08-18', 'Foto do documento conferida'),
  (5,  9,  1,  13, '2026-08-20', NULL),
  (6,  10, 8,  19, '2026-08-22', 'Aluna descreveu o conteúdo da mochila'),
  (7,  14, 7,  40, '2026-08-28', NULL),
  (8,  15, 1,  16, '2026-09-04', 'Fone pareado com o celular do dono'),
  (9,  18, 7,  6,  '2026-09-10', NULL),
  (10, 21, 13, 24, '2026-09-16', 'Iniciais da etiqueta conferidas'),
  (11, 23, 5,  27, '2026-09-18', 'Foto do documento conferida'),
  (12, 24, 14, 30, '2026-09-24', 'Aluno fez login no notebook'),
  (13, 26, 1,  31, '2026-09-30', NULL),
  (14, 28, 10, 42, '2026-10-06', NULL),
  (15, 30, 11, 10, '2026-10-14', 'Anotações conferidas com o aluno'),
  (16, 34, 8,  5,  '2026-10-22', 'Nome bordado conferido'),
  (17, 39, 6,  20, '2026-10-30', NULL);

INSERT INTO historico_status (id_historico, id_ocorrencia, id_funcionario, status_anterior, status_novo, data_alteracao) VALUES
  (1,  2,  1,  'ABERTO',     'EM_ANALISE', '2026-08-06 09:00:00'),
  (2,  1,  1,  'ABERTO',     'EM_ANALISE', '2026-08-06 09:05:00'),
  (3,  2,  1,  'EM_ANALISE', 'DEVOLVIDO',  '2026-08-06 16:20:00'),
  (4,  1,  1,  'EM_ANALISE', 'ENCERRADO',  '2026-08-06 16:25:00'),
  (5,  4,  3,  'ABERTO',     'EM_ANALISE', '2026-08-08 08:30:00'),
  (6,  3,  3,  'ABERTO',     'EM_ANALISE', '2026-08-08 08:35:00'),
  (7,  4,  3,  'EM_ANALISE', 'DEVOLVIDO',  '2026-08-08 15:00:00'),
  (8,  3,  3,  'EM_ANALISE', 'ENCERRADO',  '2026-08-08 15:05:00'),
  (9,  5,  4,  'ABERTO',     'EM_ANALISE', '2026-08-12 14:00:00'),
  (10, 6,  4,  'ABERTO',     'EM_ANALISE', '2026-08-12 14:05:00'),
  (11, 5,  4,  'EM_ANALISE', 'DEVOLVIDO',  '2026-08-13 10:15:00'),
  (12, 6,  4,  'EM_ANALISE', 'ENCERRADO',  '2026-08-13 10:20:00'),
  (13, 7,  2,  'ABERTO',     'EM_ANALISE', '2026-08-14 09:00:00'),
  (14, 7,  2,  'EM_ANALISE', 'DEVOLVIDO',  '2026-08-18 11:00:00'),
  (15, 9,  1,  'ABERTO',     'EM_ANALISE', '2026-08-19 08:40:00'),
  (16, 8,  1,  'ABERTO',     'EM_ANALISE', '2026-08-19 08:45:00'),
  (17, 9,  1,  'EM_ANALISE', 'DEVOLVIDO',  '2026-08-20 19:30:00'),
  (18, 8,  1,  'EM_ANALISE', 'ENCERRADO',  '2026-08-20 19:35:00'),
  (19, 10, 8,  'ABERTO',     'EM_ANALISE', '2026-08-21 18:30:00'),
  (20, 11, 8,  'ABERTO',     'EM_ANALISE', '2026-08-21 18:35:00'),
  (21, 10, 8,  'EM_ANALISE', 'DEVOLVIDO',  '2026-08-22 17:10:00'),
  (22, 11, 8,  'EM_ANALISE', 'ENCERRADO',  '2026-08-22 17:15:00'),
  (23, 12, 8,  'ABERTO',     'EM_ANALISE', '2026-08-26 08:30:00'),
  (24, 14, 7,  'ABERTO',     'EM_ANALISE', '2026-08-27 10:00:00'),
  (25, 13, 7,  'ABERTO',     'EM_ANALISE', '2026-08-27 10:05:00'),
  (26, 14, 7,  'EM_ANALISE', 'DEVOLVIDO',  '2026-08-28 20:00:00'),
  (27, 13, 7,  'EM_ANALISE', 'ENCERRADO',  '2026-08-28 20:05:00'),
  (28, 15, 1,  'ABERTO',     'EM_ANALISE', '2026-09-03 09:15:00'),
  (29, 16, 1,  'ABERTO',     'EM_ANALISE', '2026-09-03 09:20:00'),
  (30, 15, 1,  'EM_ANALISE', 'DEVOLVIDO',  '2026-09-04 18:40:00'),
  (31, 16, 1,  'EM_ANALISE', 'ENCERRADO',  '2026-09-04 18:45:00'),
  (32, 18, 7,  'ABERTO',     'EM_ANALISE', '2026-09-10 08:30:00'),
  (33, 17, 7,  'ABERTO',     'EM_ANALISE', '2026-09-10 08:35:00'),
  (34, 18, 7,  'EM_ANALISE', 'DEVOLVIDO',  '2026-09-10 21:00:00'),
  (35, 17, 7,  'EM_ANALISE', 'ENCERRADO',  '2026-09-10 21:05:00'),
  (36, 19, 13, 'ABERTO',     'EM_ANALISE', '2026-09-11 08:45:00'),
  (37, 21, 13, 'ABERTO',     'EM_ANALISE', '2026-09-15 09:00:00'),
  (38, 20, 13, 'ABERTO',     'EM_ANALISE', '2026-09-15 09:05:00'),
  (39, 19, 13, 'EM_ANALISE', 'ENCERRADO',  '2026-09-15 11:00:00'),
  (40, 21, 13, 'EM_ANALISE', 'DEVOLVIDO',  '2026-09-16 10:30:00'),
  (41, 20, 13, 'EM_ANALISE', 'ENCERRADO',  '2026-09-16 10:35:00'),
  (42, 23, 5,  'ABERTO',     'EM_ANALISE', '2026-09-18 08:15:00'),
  (43, 22, 5,  'ABERTO',     'EM_ANALISE', '2026-09-18 08:20:00'),
  (44, 23, 5,  'EM_ANALISE', 'DEVOLVIDO',  '2026-09-18 16:45:00'),
  (45, 22, 5,  'EM_ANALISE', 'ENCERRADO',  '2026-09-18 16:50:00'),
  (46, 24, 14, 'ABERTO',     'EM_ANALISE', '2026-09-23 14:00:00'),
  (47, 25, 14, 'ABERTO',     'EM_ANALISE', '2026-09-23 14:05:00'),
  (48, 24, 14, 'EM_ANALISE', 'DEVOLVIDO',  '2026-09-24 11:20:00'),
  (49, 25, 14, 'EM_ANALISE', 'ENCERRADO',  '2026-09-24 11:25:00'),
  (50, 26, 1,  'ABERTO',     'EM_ANALISE', '2026-09-29 14:00:00'),
  (51, 26, 1,  'EM_ANALISE', 'DEVOLVIDO',  '2026-09-30 10:40:00'),
  (52, 28, 10, 'ABERTO',     'EM_ANALISE', '2026-10-05 08:50:00'),
  (53, 27, 10, 'ABERTO',     'EM_ANALISE', '2026-10-05 08:55:00'),
  (54, 28, 10, 'EM_ANALISE', 'DEVOLVIDO',  '2026-10-06 18:30:00'),
  (55, 27, 10, 'EM_ANALISE', 'ENCERRADO',  '2026-10-06 18:35:00'),
  (56, 30, 11, 'ABERTO',     'EM_ANALISE', '2026-10-13 09:30:00'),
  (57, 29, 11, 'ABERTO',     'EM_ANALISE', '2026-10-13 09:35:00'),
  (58, 30, 11, 'EM_ANALISE', 'DEVOLVIDO',  '2026-10-14 14:10:00'),
  (59, 29, 11, 'EM_ANALISE', 'ENCERRADO',  '2026-10-14 14:15:00'),
  (60, 31, 6,  'ABERTO',     'EM_ANALISE', '2026-10-16 08:00:00'),
  (61, 32, 6,  'ABERTO',     'EM_ANALISE', '2026-10-16 09:00:00'),
  (62, 33, 1,  'ABERTO',     'EM_ANALISE', '2026-10-17 10:00:00'),
  (63, 34, 8,  'ABERTO',     'EM_ANALISE', '2026-10-21 09:00:00'),
  (64, 35, 8,  'ABERTO',     'EM_ANALISE', '2026-10-21 09:05:00'),
  (65, 34, 8,  'EM_ANALISE', 'DEVOLVIDO',  '2026-10-22 15:30:00'),
  (66, 35, 8,  'EM_ANALISE', 'ENCERRADO',  '2026-10-22 15:35:00'),
  (67, 36, 7,  'ABERTO',     'EM_ANALISE', '2026-10-23 09:30:00'),
  (68, 37, 1,  'ABERTO',     'EM_ANALISE', '2026-10-24 09:00:00'),
  (69, 12, 8,  'EM_ANALISE', 'ENCERRADO',  '2026-10-26 17:00:00'),
  (70, 39, 6,  'ABERTO',     'EM_ANALISE', '2026-10-29 07:30:00'),
  (71, 38, 6,  'ABERTO',     'EM_ANALISE', '2026-10-29 07:35:00'),
  (72, 39, 6,  'EM_ANALISE', 'DEVOLVIDO',  '2026-10-30 19:50:00'),
  (73, 38, 6,  'EM_ANALISE', 'ENCERRADO',  '2026-10-30 19:55:00'),
  (74, 40, 7,  'ABERTO',     'EM_ANALISE', '2026-10-31 10:00:00');
