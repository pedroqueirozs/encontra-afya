# Dicionário de Dados: EncontraAFYA

Este documento descreve as tabelas e colunas do banco de dados. As regras de negócio citadas (RN) estão em [proposta.md](proposta.md).

**Convenções**

- Todas as tabelas usam `ENGINE=InnoDB` e `DEFAULT CHARSET=utf8mb4`.
- Toda chave primária é `INT AUTO_INCREMENT`.
- As restrições têm nome próprio, com os prefixos `fk_` (chave estrangeira), `ck_` (CHECK) e `uq_` (UNIQUE).
- Colunas com um conjunto fechado de valores usam `VARCHAR(20)` com CHECK.

## 1. `pessoa`

Alunos, professores e funcionários que usam o sistema.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_pessoa` | INT | PK, AUTO_INCREMENT | Identificador da pessoa |
| `nome` | VARCHAR(120) | NOT NULL | Nome completo |
| `email` | VARCHAR(120) | NOT NULL, UNIQUE (`uq_pessoa_email`) | E-mail de contato |
| `matricula` | VARCHAR(15) | NOT NULL, UNIQUE (`uq_pessoa_matricula`) | Matrícula na instituição |
| `telefone` | VARCHAR(20) | NULL | Telefone de contato, de preenchimento opcional |
| `tipo_pessoa` | VARCHAR(20) | NOT NULL, CHECK (`ck_pessoa_tipo_pessoa`) | Vínculo com a instituição |
| `status` | CHAR(1) | NOT NULL, DEFAULT 'A', CHECK (`ck_pessoa_status`) | Situação do cadastro |
| `data_cadastro` | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Momento do cadastro |

**Valores permitidos**

- `tipo_pessoa`: `ALUNO`, `PROFESSOR`, `FUNCIONARIO`.
- `status`: `A` (ativa), `I` (inativa).

## 2. `funcionario_responsavel`

Dados específicos das pessoas autorizadas a conduzir o processo. Relação 1:1 com `pessoa`.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_funcionario` | INT | PK, AUTO_INCREMENT | Identificador do funcionário responsável |
| `id_pessoa` | INT | NOT NULL, UNIQUE (`uq_funcionario_responsavel_id_pessoa`), FK | Pessoa correspondente |
| `setor` | VARCHAR(60) | NOT NULL | Setor em que trabalha |
| `cargo` | VARCHAR(60) | NOT NULL | Cargo exercido |
| `data_inicio` | DATE | NOT NULL | Data em que passou a atuar como responsável |

## 3. `categoria`

Classificação dos objetos.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_categoria` | INT | PK, AUTO_INCREMENT | Identificador da categoria |
| `nome` | VARCHAR(60) | NOT NULL, UNIQUE (`uq_categoria_nome`) | Nome da categoria |
| `descricao` | VARCHAR(255) | NULL | Detalhes sobre o que a categoria abrange |

## 4. `local`

Lugares do campus onde objetos são perdidos ou encontrados.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_local` | INT | PK, AUTO_INCREMENT | Identificador do local |
| `nome` | VARCHAR(80) | NOT NULL | Nome do local |
| `bloco` | VARCHAR(20) | NULL | Bloco do campus; vazio em áreas fora dos blocos, como o estacionamento |
| `andar` | VARCHAR(20) | NULL | Andar; vazio em áreas sem andares |
| `descricao` | VARCHAR(255) | NULL | Referências para localizar o lugar |

## 5. `objeto`

Características do item perdido ou encontrado.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_objeto` | INT | PK, AUTO_INCREMENT | Identificador do objeto |
| `nome` | VARCHAR(80) | NOT NULL | Nome do objeto |
| `descricao` | VARCHAR(255) | NOT NULL | Características que ajudam a identificá-lo |
| `cor` | VARCHAR(30) | NULL | Cor predominante; vazia quando não se aplica |
| `marca` | VARCHAR(60) | NULL | Marca; vazia quando não há marca identificável |
| `id_categoria` | INT | NOT NULL, FK | Categoria do objeto |

## 6. `ocorrencia`

Registro de que um objeto foi perdido ou encontrado.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_ocorrencia` | INT | PK, AUTO_INCREMENT | Identificador da ocorrência |
| `tipo` | VARCHAR(20) | NOT NULL, CHECK (`ck_ocorrencia_tipo`) | Natureza da ocorrência |
| `data_ocorrencia` | DATE | NOT NULL | Data em que o objeto foi perdido ou encontrado |
| `descricao` | VARCHAR(255) | NOT NULL | Relato do que aconteceu |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'ABERTO', CHECK (`ck_ocorrencia_status`) | Situação atual da ocorrência |
| `id_objeto` | INT | NOT NULL, FK | Objeto envolvido |
| `id_pessoa` | INT | NOT NULL, FK | Pessoa que registrou a ocorrência |
| `id_local` | INT | NOT NULL, FK | Local do fato |
| `data_registro` | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Momento em que a ocorrência foi registrada |

**Valores permitidos**

- `tipo`: `PERDIDO`, `ENCONTRADO`.
- `status`:
  - `ABERTO`: registrada e ainda não analisada.
  - `EM_ANALISE`: em análise por um funcionário responsável.
  - `DEVOLVIDO`: objeto entregue; usado apenas em ocorrências de ENCONTRADO.
  - `ENCERRADO`: processo finalizado sem registro próprio de devolução, como a ocorrência de PERDIDO cujo objeto foi devolvido.

## 7. `tentativa_identificacao`

Contatos feitos para identificar o dono de um objeto. Tabela associativa da relação N:N entre `ocorrencia` e `pessoa`.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_tentativa` | INT | PK, AUTO_INCREMENT | Identificador da tentativa |
| `id_ocorrencia` | INT | NOT NULL, FK | Ocorrência relacionada |
| `id_pessoa` | INT | NOT NULL, FK | Pessoa que alegou ser dona ou foi contatada |
| `data_tentativa` | DATETIME | NOT NULL | Momento do contato |
| `meio_contato` | VARCHAR(20) | NOT NULL, CHECK (`ck_tentativa_identificacao_meio_contato`) | Meio utilizado |
| `resultado` | VARCHAR(20) | NOT NULL, CHECK (`ck_tentativa_identificacao_resultado`) | Resultado do contato |
| `observacao` | VARCHAR(255) | NULL | Informações adicionais |

**Valores permitidos**

- `meio_contato`: `EMAIL`, `TELEFONE`, `PRESENCIAL`, `WHATSAPP`.
- `resultado`: `CONFIRMADO`, `NAO_CONFIRMADO`, `SEM_RESPOSTA`.

## 8. `correspondencia`

Comparação entre uma ocorrência de ENCONTRADO e uma de PERDIDO. Tabela associativa da relação N:N de `ocorrencia` com ela mesma.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_correspondencia` | INT | PK, AUTO_INCREMENT | Identificador da correspondência |
| `id_ocorrencia_encontrada` | INT | NOT NULL, FK | Ocorrência do tipo ENCONTRADO |
| `id_ocorrencia_perdida` | INT | NOT NULL, FK | Ocorrência do tipo PERDIDO |
| `data_analise` | DATE | NULL | Data da análise; vazia enquanto a correspondência não foi analisada |
| `situacao` | VARCHAR(20) | NOT NULL, DEFAULT 'PENDENTE', CHECK (`ck_correspondencia_situacao`) | Resultado da comparação |
| `id_funcionario` | INT | NULL, FK | Funcionário que analisou; vazio enquanto não houver análise |

**Restrições da tabela**

- `uq_correspondencia_par`: UNIQUE composto em (`id_ocorrencia_encontrada`, `id_ocorrencia_perdida`). O mesmo par não se repete, mas cada ocorrência pode aparecer em vários pares.
- `ck_correspondencia_ocorrencias`: CHECK (`id_ocorrencia_encontrada` <> `id_ocorrencia_perdida`). Uma ocorrência não pode ser comparada com ela mesma.

**Valores permitidos**

- `situacao`: `PENDENTE`, `CONFIRMADA`, `DESCARTADA`.

## 9. `devolucao`

Entrega do objeto a quem o recebeu. Relação 1:1 com `ocorrencia`.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_devolucao` | INT | PK, AUTO_INCREMENT | Identificador da devolução |
| `id_ocorrencia` | INT | NOT NULL, UNIQUE (`uq_devolucao_id_ocorrencia`), FK | Ocorrência de ENCONTRADO devolvida |
| `id_funcionario` | INT | NOT NULL, FK | Funcionário que registrou a devolução |
| `id_pessoa_recebedor` | INT | NOT NULL, FK | Pessoa que recebeu o objeto |
| `data_devolucao` | DATE | NOT NULL | Data da entrega |
| `observacao` | VARCHAR(255) | NULL | Informações adicionais |

## 10. `historico_status`

Trilha das mudanças de status. Tabela associativa da relação N:N entre `ocorrencia` e `funcionario_responsavel`.

| Coluna | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_historico` | INT | PK, AUTO_INCREMENT | Identificador do registro |
| `id_ocorrencia` | INT | NOT NULL, FK | Ocorrência alterada |
| `id_funcionario` | INT | NOT NULL, FK | Funcionário que fez a alteração |
| `status_anterior` | VARCHAR(20) | NOT NULL, CHECK (`ck_historico_status_anterior`) | Status antes da mudança |
| `status_novo` | VARCHAR(20) | NOT NULL, CHECK (`ck_historico_status_novo`) | Status depois da mudança |
| `data_alteracao` | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Momento da mudança |

**Restrições da tabela**

- `ck_historico_status_diferente`: CHECK (`status_anterior` <> `status_novo`). Uma mudança precisa alterar o status.

**Valores permitidos**

- `status_anterior` e `status_novo`: `ABERTO`, `EM_ANALISE`, `DEVOLVIDO`, `ENCERRADO`.

## 11. Chaves estrangeiras

| Restrição | Coluna | Referencia | ON DELETE | ON UPDATE |
|---|---|---|---|---|
| `fk_funcionario_responsavel_pessoa` | `funcionario_responsavel.id_pessoa` | `pessoa` | RESTRICT | CASCADE |
| `fk_objeto_categoria` | `objeto.id_categoria` | `categoria` | RESTRICT | CASCADE |
| `fk_ocorrencia_objeto` | `ocorrencia.id_objeto` | `objeto` | RESTRICT | CASCADE |
| `fk_ocorrencia_pessoa` | `ocorrencia.id_pessoa` | `pessoa` | RESTRICT | CASCADE |
| `fk_ocorrencia_local` | `ocorrencia.id_local` | `local` | RESTRICT | CASCADE |
| `fk_tentativa_identificacao_ocorrencia` | `tentativa_identificacao.id_ocorrencia` | `ocorrencia` | CASCADE | CASCADE |
| `fk_tentativa_identificacao_pessoa` | `tentativa_identificacao.id_pessoa` | `pessoa` | RESTRICT | CASCADE |
| `fk_correspondencia_encontrada` | `correspondencia.id_ocorrencia_encontrada` | `ocorrencia` | RESTRICT | RESTRICT |
| `fk_correspondencia_perdida` | `correspondencia.id_ocorrencia_perdida` | `ocorrencia` | RESTRICT | RESTRICT |
| `fk_correspondencia_funcionario` | `correspondencia.id_funcionario` | `funcionario_responsavel` | SET NULL | CASCADE |
| `fk_devolucao_ocorrencia` | `devolucao.id_ocorrencia` | `ocorrencia` | RESTRICT | CASCADE |
| `fk_devolucao_funcionario` | `devolucao.id_funcionario` | `funcionario_responsavel` | RESTRICT | CASCADE |
| `fk_devolucao_recebedor` | `devolucao.id_pessoa_recebedor` | `pessoa` | RESTRICT | CASCADE |
| `fk_historico_status_ocorrencia` | `historico_status.id_ocorrencia` | `ocorrencia` | RESTRICT | CASCADE |
| `fk_historico_status_funcionario` | `historico_status.id_funcionario` | `funcionario_responsavel` | RESTRICT | CASCADE |

O padrão `ON DELETE RESTRICT ON UPDATE CASCADE` impede a exclusão de registros com dependências (RN11) e mantém as referências corretas se um identificador mudar. As exceções são:

- **`fk_tentativa_identificacao_ocorrencia`:** usa `ON DELETE CASCADE` porque uma tentativa não existe sem a ocorrência.
- **`fk_correspondencia_funcionario`:** usa `ON DELETE SET NULL` porque a correspondência continua válida sem o analista.
- **`fk_correspondencia_encontrada` e `fk_correspondencia_perdida`:** usam `RESTRICT` nas duas ações porque as colunas fazem parte de um CHECK, e o MySQL não aceita `ON UPDATE CASCADE` nesse caso (erro 3823).
