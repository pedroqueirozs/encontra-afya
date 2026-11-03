# EncontraAFYA: Sistema Universitário de Achados e Perdidos

**Disciplina:** Banco de Dados
**Curso:** Engenharia da Computação, AFYA Centro Universitário
**Semestre:** 2º semestre de 2026

**Integrantes:**

- Luis Felipe Romão De Oliveira
- Pedro Douglas Gonçalves Queiroz
- Ciça Lima

## 1. Domínio do projeto

Em um campus universitário, alunos, professores e funcionários circulam diariamente por salas, laboratórios, biblioteca, cantina e estacionamento. Nesse movimento, objetos são perdidos e encontrados com frequência. Sem um registro organizado, quem perdeu não sabe se o objeto foi achado, e quem achou não sabe a quem devolvê-lo.

O EncontraAFYA é um banco de dados relacional, implementado em MySQL, que organiza esse processo do início ao fim. Ele registra os objetos perdidos e encontrados, compara os registros entre si, acompanha as tentativas de localizar o dono e documenta a devolução.

O tema foi aprovado pelo professor da disciplina. O projeto usa apenas SQL e não inclui interface gráfica nem aplicação.

## 2. Funcionamento do processo

1. Uma pessoa cadastrada informa que perdeu ou encontrou um objeto. Isso gera uma **ocorrência** do tipo PERDIDO ou ENCONTRADO, com status inicial ABERTO.
2. Um funcionário responsável analisa a ocorrência, que passa a EM_ANALISE. Cada mudança de status fica guardada no histórico.
3. O funcionário compara ocorrências de ENCONTRADO com ocorrências de PERDIDO. Cada comparação é uma **correspondência**, com situação PENDENTE, CONFIRMADA ou DESCARTADA.
4. Quando necessário, são feitas **tentativas de identificação**: contatos com quem alega ser dono do objeto ou com quem pode ser o dono.
5. Confirmado o dono, o funcionário registra a **devolução**. A ocorrência de ENCONTRADO passa a DEVOLVIDO e a ocorrência de PERDIDO ligada a ela passa a ENCERRADO.

## 3. Entidades

| Tabela | O que representa |
|---|---|
| `pessoa` | Alunos, professores e funcionários que usam o sistema |
| `funcionario_responsavel` | Dados específicos das pessoas autorizadas a conduzir o processo |
| `categoria` | Classificação dos objetos, como eletrônicos ou documentos |
| `local` | Lugares do campus onde objetos são perdidos ou encontrados |
| `objeto` | Características do item: nome, descrição, cor, marca e categoria |
| `ocorrencia` | Registro de que um objeto foi perdido ou encontrado |
| `tentativa_identificacao` | Contatos feitos com pessoas para identificar o dono |
| `correspondencia` | Comparação entre uma ocorrência de ENCONTRADO e uma de PERDIDO |
| `devolucao` | Entrega do objeto a quem o recebeu |
| `historico_status` | Trilha das mudanças de status de cada ocorrência |

## 4. Relacionamentos

| Tipo | Relacionamento | Implementação |
|---|---|---|
| 1:1 | `pessoa` e `funcionario_responsavel` | `id_pessoa` UNIQUE em `funcionario_responsavel` |
| 1:1 | `ocorrencia` e `devolucao` | `id_ocorrencia` UNIQUE em `devolucao` |
| 1:N | `categoria` → `objeto` | `objeto.id_categoria` |
| 1:N | `objeto` → `ocorrencia` | `ocorrencia.id_objeto` |
| 1:N | `pessoa` → `ocorrencia` | `ocorrencia.id_pessoa` |
| 1:N | `local` → `ocorrencia` | `ocorrencia.id_local` |
| 1:N | `funcionario_responsavel` → `devolucao` | `devolucao.id_funcionario` |
| 1:N | `pessoa` → `devolucao` | `devolucao.id_pessoa_recebedor` |
| N:N | `ocorrencia` e `pessoa` | Tabela associativa `tentativa_identificacao` |
| N:N | `ocorrencia` e `ocorrencia` | Tabela associativa `correspondencia` |
| N:N | `ocorrencia` e `funcionario_responsavel` | Tabela associativa `historico_status` |

## 5. Regras de negócio

A última coluna indica como cada regra é garantida. Parte delas é imposta pelo próprio banco. As demais dependem da forma como os dados são registrados e são respeitadas no povoamento.

| Código | Regra | Como é garantida |
|---|---|---|
| RN01 | Toda pessoa tem nome, e-mail e matrícula, sendo e-mail e matrícula únicos. O tipo é ALUNO, PROFESSOR ou FUNCIONARIO. | NOT NULL, UNIQUE e CHECK |
| RN02 | Uma pessoa pode estar ativa (A) ou inativa (I). Quem se desliga da instituição é inativado, e seus registros são mantidos. | CHECK e DEFAULT |
| RN03 | Um funcionário responsável corresponde a uma única pessoa, do tipo FUNCIONARIO. | UNIQUE para a unicidade; povoamento para o tipo |
| RN04 | Todo objeto pertence a exatamente uma categoria. | FK e NOT NULL |
| RN05 | Toda ocorrência é do tipo PERDIDO ou ENCONTRADO e informa o objeto, a pessoa que registrou e o local. | CHECK, FK e NOT NULL |
| RN06 | Toda ocorrência começa como ABERTO e pode passar por EM_ANALISE, DEVOLVIDO e ENCERRADO. | CHECK e DEFAULT |
| RN07 | Uma ocorrência pode ter várias tentativas de identificação. Cada tentativa registra a pessoa, a data, o meio de contato e o resultado. | Tabela associativa e CHECK |
| RN08 | Somente um funcionário responsável pode registrar uma devolução, alterar o status de uma ocorrência ou analisar uma correspondência. | Estrutura: as FKs apontam para `funcionario_responsavel` |
| RN09 | Uma correspondência liga sempre uma ocorrência de ENCONTRADO a uma de PERDIDO, e o mesmo par não se repete. Quando confirmada, a ocorrência de PERDIDO passa a referenciar o mesmo objeto da ocorrência de ENCONTRADO. | UNIQUE e CHECK para o par; trigger para os tipos; povoamento para o objeto |
| RN10 | A devolução é registrada apenas na ocorrência de ENCONTRADO, no máximo uma vez, com o funcionário e a pessoa que recebeu o objeto. A ocorrência de ENCONTRADO passa a DEVOLVIDO e a de PERDIDO passa a ENCERRADO. | UNIQUE e FK para a devolução; povoamento para os status |
| RN11 | Registros com dependências não podem ser excluídos. | FK com ON DELETE RESTRICT |
| RN12 | Toda mudança de status gera um registro no histórico, e o status novo é sempre diferente do anterior. | CHECK para os valores; povoamento para o registro |
| RN13 | As datas seguem a ordem do processo: a ocorrência vem antes das tentativas e correspondências, e estas vêm antes da devolução. | Povoamento |

## 6. Decisões de modelagem

**Separação entre `pessoa` e `funcionario_responsavel`.** Os dados gerais ficam em `pessoa`, e a outra tabela guarda apenas setor, cargo e data de início. Assim, os dados de um funcionário não são repetidos e os demais usuários não ficam com colunas vazias.

**RN08 garantida pela estrutura.** Devolução, histórico e análise de correspondência apontam para `funcionario_responsavel`, e não para `pessoa`. Dessa forma, quem não está cadastrado como responsável não pode ser informado nessas tabelas.

**Separação entre `objeto` e `ocorrencia`.** O objeto descreve o item e a ocorrência descreve o fato. Como um mesmo objeto pode aparecer em mais de uma ocorrência, a relação é 1:N. Quando uma correspondência é confirmada, as duas ocorrências passam a apontar para o mesmo objeto.

**Um único registro por devolução.** Uma devolução confirmada envolve duas ocorrências. Ela é registrada só na ocorrência de ENCONTRADO, porque é ela que representa o objeto sob a guarda da instituição. A ocorrência de PERDIDO é encerrada, sem registro próprio. Assim, uma entrega física nunca aparece duas vezes.

**Status atual e histórico.** O status atual fica em `ocorrencia`, e as mudanças ficam em `historico_status`. Essa redundância é intencional: consultar o status atual é uma operação frequente e não deveria exigir a busca do último registro do histórico. Em contrapartida, os dois precisam ser mantidos coerentes. A decisão será detalhada na justificativa de normalização do relatório técnico.

**Ações referenciais.** O padrão é `ON DELETE RESTRICT ON UPDATE CASCADE`, conforme a RN11. As exceções são:

- `tentativa_identificacao.id_ocorrencia` usa `ON DELETE CASCADE`, porque uma tentativa não existe sem a ocorrência.
- `correspondencia.id_funcionario` usa `ON DELETE SET NULL`, porque a correspondência continua válida sem o analista.
- As duas FKs de ocorrência em `correspondencia` usam `ON DELETE RESTRICT ON UPDATE RESTRICT`. Essas colunas fazem parte do `CHECK (id_ocorrencia_encontrada <> id_ocorrencia_perdida)`, e o MySQL não aceita `ON UPDATE CASCADE` em colunas usadas em CHECK (erro 3823).

**Limites do CHECK no MySQL.** O CHECK não consulta outras tabelas nem aceita funções não determinísticas, como `NOW()`. Por isso, ele não consegue verificar se uma correspondência liga mesmo um ENCONTRADO a um PERDIDO, já que o tipo está na tabela `ocorrencia`. Essa verificação será feita por um trigger em `sql/auxiliares.sql`. Pelo mesmo motivo, a ordem das datas é respeitada no povoamento.

**Versão do MySQL.** O projeto exige MySQL 8.0.16 ou superior, pois as versões anteriores não aplicam as restrições CHECK.
