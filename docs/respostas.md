# SigaEdu - Respostas Teóricas e Modelo Lógico

---

## Item 1 - Modelagem e Arquitetura

### 1.1 Justificativa para SGBD Relacional (PostgreSQL)

A escolha de um SGBD Relacional como o PostgreSQL é a mais adequada para um sistema de gestão acadêmica pelos seguintes motivos:

- **Propriedades ACID**: Um sistema acadêmico lida com dados críticos como notas, matrículas e históricos. As propriedades ACID (Atomicidade, Consistência, Isolamento, Durabilidade) garantem que operações como o lançamento de notas ou a efetivação de uma matrícula ocorram de forma completa ou sejam totalmente revertidas em caso de falha, evitando estados intermediários e inconsistentes.

- **Integridade Referencial**: Os dados acadêmicos possuem relações bem definidas entre si (um aluno se matricula em uma disciplina, que é ministrada por um docente, dentro de um ciclo). As chaves estrangeiras (FK) do modelo relacional impõem essas regras diretamente no banco, impedindo, por exemplo, que uma matrícula seja criada para um aluno ou disciplina inexistente. Em um banco NoSQL, essa validação ficaria inteiramente na aplicação, aumentando o risco de inconsistências.

- **Consultas Complexas com SQL**: O modelo relacional permite consultas sofisticadas com JOINs, agregações (GROUP BY, HAVING), subconsultas e filtros, essenciais para gerar relatórios acadêmicos como boletins, médias por disciplina e alocação de docentes.

- **Esquema Fixo e Previsível**: Os dados acadêmicos possuem estrutura bem definida e estável. O schema rígido do modelo relacional garante que todos os registros sigam o mesmo formato, facilitando a manutenção e a auditoria.

Um banco NoSQL (como MongoDB) seria mais indicado para cenários com dados semi-estruturados, alta variabilidade de esquema ou necessidade de escala horizontal massiva, o que não se aplica a um sistema acadêmico universitário.

### 1.2 Justificativa para o uso de Esquemas (Schemas)

Em ambientes profissionais de Engenharia de Dados, o uso de esquemas (namespaces lógicos dentro do banco) em vez de concentrar tudo no esquema `public` é recomendado pelos seguintes motivos:

- **Organização e Separação de Domínios**: Esquemas permitem agrupar tabelas por domínio funcional. No SigaEdu, o esquema `academico` contém tabelas de negócio (alunos, disciplinas, matrículas), enquanto o esquema `seguranca` pode abrigar objetos relacionados a controle de acesso. Isso torna o banco autodocumentado e mais fácil de navegar.

- **Governança e Controle de Acesso (DCL)**: Com esquemas, é possível aplicar permissões GRANT/REVOKE por namespace inteiro. Por exemplo, um `professor_role` pode ter acesso restrito apenas a certas tabelas do esquema `academico`, sem precisar gerenciar permissões tabela por tabela.

- **Prevenção de Conflitos de Nomes**: Em projetos grandes com múltiplas equipes, esquemas evitam colisões de nomes de tabelas, views ou funções, pois cada domínio opera em seu próprio namespace.

- **Escalabilidade e Manutenibilidade**: À medida que o sistema cresce, a separação em esquemas facilita migrações, backups seletivos e a evolução independente de módulos.

---

## Item 2 - Modelo Lógico (Normalização em 3FN)

### Análise da Planilha Legada

A planilha original concentra todos os dados em uma única tabela desnormalizada, com repetição de dados de alunos, disciplinas e docentes em cada linha. A normalização foi aplicada seguindo as três formas normais:

**1FN (Primeira Forma Normal):** A planilha já atende à 1FN, pois cada célula contém um valor atômico e não há grupos repetitivos dentro de uma mesma coluna.

**2FN (Segunda Forma Normal):** Na tabela original, atributos como `Nome_Usuario`, `Email_Usuario` e `Endereco_Usuario` dependem apenas de `ID_Matricula` (o aluno), não da chave composta completa. Da mesma forma, `Nome_Disciplina` e `Carga_H` dependem somente de `Cod_Servico_Academico`. Para atender à 2FN, esses atributos foram extraídos em tabelas próprias, eliminando dependências parciais.

**3FN (Terceira Forma Normal):** O atributo `Nome_Docente` depende transitivamente de `Matricula_Operador_Pedagogico`, e não da chave primária da matrícula. Para atender à 3FN, os docentes foram extraídos para sua própria tabela, eliminando dependências transitivas.

### Esquema do Modelo Lógico Resultante

```
academico.alunos (
    id_matricula    INTEGER       PRIMARY KEY,
    nome            VARCHAR(100)  NOT NULL,
    email           VARCHAR(100)  UNIQUE NOT NULL,
    endereco        VARCHAR(150),
    ativo           BOOLEAN       DEFAULT TRUE
)

academico.docentes (
    id_docente      SERIAL        PRIMARY KEY,
    nome            VARCHAR(100)  NOT NULL,
    ativo           BOOLEAN       DEFAULT TRUE
)

academico.disciplinas (
    cod_disciplina  VARCHAR(10)   PRIMARY KEY,
    nome            VARCHAR(100)  NOT NULL,
    carga_horaria   INTEGER       NOT NULL,
    id_docente      INTEGER       REFERENCES academico.docentes(id_docente),
    ativo           BOOLEAN       DEFAULT TRUE
)

academico.ciclos (
    id_ciclo    SERIAL        PRIMARY KEY,
    descricao   VARCHAR(10)   UNIQUE NOT NULL,
    ativo       BOOLEAN       DEFAULT TRUE
)

academico.matriculas (
    id_matricula_reg  SERIAL        PRIMARY KEY,
    id_aluno          INTEGER       NOT NULL  REFERENCES academico.alunos(id_matricula),
    cod_disciplina    VARCHAR(10)   NOT NULL  REFERENCES academico.disciplinas(cod_disciplina),
    id_ciclo          INTEGER       NOT NULL  REFERENCES academico.ciclos(id_ciclo),
    data_ingresso     DATE          NOT NULL,
    nota_final        DECIMAL(4,2),
    ativo             BOOLEAN       DEFAULT TRUE,
    UNIQUE(id_aluno, cod_disciplina, id_ciclo)
)
```

### Relacionamentos

- **alunos 1:N matriculas** - Um aluno pode ter várias matrículas em disciplinas.
- **disciplinas 1:N matriculas** - Uma disciplina pode ter vários alunos matriculados.
- **docentes 1:N disciplinas** - Um docente pode ser responsável por várias disciplinas.
- **ciclos 1:N matriculas** - Um ciclo acadêmico agrupa várias matrículas.

---

## Item 5 - Transações e Concorrência

### Cenário: Dois operadores alteram a nota do mesmo ID_Matricula simultaneamente

Quando dois operadores da secretaria tentam alterar a nota do mesmo registro de matrícula ao mesmo tempo, o SGBD relacional (PostgreSQL) utiliza os mecanismos de **Isolamento (propriedade ACID)** e **Locks (bloqueios)** para garantir a consistência dos dados:

#### Isolamento (ACID)

O Isolamento é a propriedade que garante que transações concorrentes não interfiram entre si. O PostgreSQL implementa o nível de isolamento padrão **Read Committed**, onde cada transação enxerga apenas dados que já foram commitados por outras transações. Isso significa que:

- A Transação A inicia e lê a nota atual do registro (ex: 7.0).
- A Transação B também inicia e lê a mesma nota (7.0).
- Quando A tenta atualizar para 8.5, o PostgreSQL adquire um **lock exclusivo** na linha.
- Se B tentar atualizar a mesma linha enquanto A ainda não fez COMMIT, B ficará **bloqueada (aguardando)** até que A finalize.

#### Locks (Bloqueios)

O PostgreSQL utiliza **bloqueios em nível de linha (row-level locks)**. Quando um `UPDATE` é executado:

1. O SGBD adquire um **lock exclusivo (FOR UPDATE)** na linha afetada.
2. Qualquer outra transação que tente modificar a mesma linha será suspensa até que o lock seja liberado (via COMMIT ou ROLLBACK).
3. Após A fazer COMMIT (nota = 8.5), o lock é liberado.
4. B então adquire o lock, **relê o valor atualizado** (8.5) e aplica sua alteração (ex: para 9.0).

#### Resultado

O dado final será **sempre consistente**: a última transação a fazer COMMIT prevalece, e nenhuma atualização é perdida silenciosamente. O mecanismo de locks serializa o acesso à linha, transformando duas operações simultâneas em operações sequenciais. Isso impede o problema conhecido como **Lost Update**, onde uma alteração sobrescreveria a outra sem sequer perceber.

Caso se deseje um controle ainda mais rigoroso, pode-se utilizar o nível de isolamento **SERIALIZABLE**, que faz com que a segunda transação falhe com um erro de serialização caso detecte um conflito, permitindo que a aplicação trate e repita a operação.
