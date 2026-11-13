# EncontraAFYA

**Sistema Universitário de Achados e Perdidos**

Projeto final da disciplina de Banco de Dados, modelado e implementado em MySQL 8.0.

| | |
|---|---|
| **Instituição** | AFYA Centro Universitário |
| **Curso** | Engenharia da Computação |
| **Disciplina** | Banco de Dados |
| **Semestre** | 2º semestre de 2026 |
| **Integrantes** | Ciça Lima, Pedro Douglas e Luis Felipe Romão |

## O projeto em números

| Item | Quantidade |
|---|---|
| Tabelas | 10, em Terceira Forma Normal |
| Relacionamentos | 2 do tipo 1:1, 6 do tipo 1:N e 3 do tipo N:N |
| Restrições | 15 FKs, 11 CHECK, 6 UNIQUE e 6 DEFAULT |
| Registros | 334, com pelo menos 15 por tabela |
| Consultas | 13: 6 simples, 5 com JOIN, 1 com LEFT JOIN e 1 com subconsulta |
| Trigger | 1, para uma regra que o CHECK não consegue verificar |

## Documentação

1. [Domínio e regras de negócio](docs/proposta.md)
2. [Diagrama entidade-relacionamento](docs/der.png)
3. [Dicionário de dados](docs/dicionario_dados.md)
4. [Normalização](docs/relatorio.md#5-justificativa-da-normalização)
5. [Criação do banco e povoamento](sql/encontraafya.sql)
6. [Trigger](sql/auxiliares.sql)
7. [Consultas](sql/consultas.sql)

O [relatório técnico completo](docs/relatorio.md) reúne todo o conteúdo, com a saída de cada consulta.

## Estrutura do repositório

```text
encontra-afya/
├── README.md
├── Projeto_Final_Banco_de_Dados(3).docx   enunciado do projeto
├── docs/
│   ├── relatorio.md                       relatório técnico completo
│   ├── proposta.md                        domínio, regras de negócio e decisões
│   ├── dicionario_dados.md                tabelas, colunas, tipos e restrições
│   ├── der.png                            diagrama entidade-relacionamento
│   └── der.mmd                            código-fonte do diagrama (Mermaid)
└── sql/
    ├── encontraafya.sql                   criação do banco, das tabelas e dos dados
    ├── auxiliares.sql                     trigger e conferência da carga
    └── consultas.sql                      as 13 consultas comentadas
```

## Como executar

O banco roda em um contêiner Docker com a imagem oficial do MySQL. Execute os comandos na pasta do projeto.

```bash
# 1. Baixar a imagem e subir o MySQL
docker pull mysql:8.0
docker run -d --name encontraafya-mysql -e MYSQL_ROOT_PASSWORD=afya2026 mysql:8.0

# 2. Aguardar até a resposta "mysqld is alive"
docker exec encontraafya-mysql mysqladmin ping -h127.0.0.1 -uroot -pafya2026

# 3. Criar o banco, inserir os dados e criar o trigger
docker exec -i encontraafya-mysql mysql -uroot -pafya2026 --default-character-set=utf8mb4 < sql/encontraafya.sql
docker exec -i encontraafya-mysql mysql -uroot -pafya2026 --default-character-set=utf8mb4 -t < sql/auxiliares.sql

# 4. Abrir o MySQL e executar as consultas de sql/consultas.sql
docker exec -it encontraafya-mysql mysql -uroot -pafya2026 --default-character-set=utf8mb4 encontraafya
```

Para recomeçar do zero, use `docker rm -f encontraafya-mysql` e repita os passos. O passo a passo detalhado está na [seção 7 do relatório](docs/relatorio.md#7-instruções-de-execução).
