-- =============================================================
-- SigaEdu - Sistema de Gestao Academica
-- Script Completo: DDL, DCL, DML e Consultas
-- SGBD: PostgreSQL
-- =============================================================

-- =============================================================
-- 1. CRIACAO DOS ESQUEMAS (Namespaces)
-- =============================================================

CREATE SCHEMA IF NOT EXISTS academico;
CREATE SCHEMA IF NOT EXISTS seguranca;

-- =============================================================
-- 2. DDL - CRIACAO DAS TABELAS
-- =============================================================

-- Tabela de Alunos
CREATE TABLE academico.alunos (
    id_matricula    INTEGER         PRIMARY KEY,
    nome            VARCHAR(100)    NOT NULL,
    email           VARCHAR(100)    UNIQUE NOT NULL,
    endereco        VARCHAR(150),
    ativo           BOOLEAN         DEFAULT TRUE
);

-- Tabela de Docentes
CREATE TABLE academico.docentes (
    id_docente      SERIAL          PRIMARY KEY,
    nome            VARCHAR(100)    NOT NULL,
    ativo           BOOLEAN         DEFAULT TRUE
);

-- Tabela de Disciplinas
CREATE TABLE academico.disciplinas (
    cod_disciplina  VARCHAR(10)     PRIMARY KEY,
    nome            VARCHAR(100)    NOT NULL,
    carga_horaria   INTEGER         NOT NULL,
    id_docente      INTEGER,
    ativo           BOOLEAN         DEFAULT TRUE,

    CONSTRAINT fk_docente_disciplina
        FOREIGN KEY (id_docente)
        REFERENCES academico.docentes(id_docente)
);

-- Tabela de Ciclos Academicos
CREATE TABLE academico.ciclos (
    id_ciclo    SERIAL          PRIMARY KEY,
    descricao   VARCHAR(10)     UNIQUE NOT NULL,
    ativo       BOOLEAN         DEFAULT TRUE
);

-- Tabela de Matriculas (tabela associativa central)
CREATE TABLE academico.matriculas (
    id_matricula_reg    SERIAL          PRIMARY KEY,
    id_aluno            INTEGER         NOT NULL,
    cod_disciplina      VARCHAR(10)     NOT NULL,
    id_ciclo            INTEGER         NOT NULL,
    data_ingresso       DATE            NOT NULL,
    nota_final          DECIMAL(4,2),
    ativo               BOOLEAN         DEFAULT TRUE,

    CONSTRAINT fk_aluno
        FOREIGN KEY (id_aluno)
        REFERENCES academico.alunos(id_matricula),

    CONSTRAINT fk_disciplina
        FOREIGN KEY (cod_disciplina)
        REFERENCES academico.disciplinas(cod_disciplina),

    CONSTRAINT fk_ciclo
        FOREIGN KEY (id_ciclo)
        REFERENCES academico.ciclos(id_ciclo),

    CONSTRAINT uq_aluno_disciplina_ciclo
        UNIQUE (id_aluno, cod_disciplina, id_ciclo)
);

-- =============================================================
-- 3. DCL - SEGURANCA (Roles e Permissoes)
-- =============================================================

-- Criar os perfis (roles)
CREATE ROLE professor_role;
CREATE ROLE coordenador_role;

-- COORDENADOR: acesso total aos esquemas academico e seguranca
GRANT USAGE ON SCHEMA academico TO coordenador_role;
GRANT USAGE ON SCHEMA seguranca TO coordenador_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA academico TO coordenador_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA seguranca TO coordenador_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA academico TO coordenador_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA seguranca TO coordenador_role;

-- PROFESSOR: permissao de UPDATE apenas na coluna nota_final da tabela matriculas
GRANT USAGE ON SCHEMA academico TO professor_role;

-- Professor pode consultar as tabelas necessarias para seu trabalho
GRANT SELECT ON academico.disciplinas TO professor_role;
GRANT SELECT ON academico.docentes TO professor_role;
GRANT SELECT ON academico.ciclos TO professor_role;
GRANT SELECT ON academico.matriculas TO professor_role;

-- Professor pode atualizar APENAS a coluna nota_final na tabela matriculas
GRANT UPDATE (nota_final) ON academico.matriculas TO professor_role;

-- PRIVACIDADE: professor NAO tem acesso a coluna email dos alunos
-- Conceder SELECT apenas nas colunas permitidas (excluindo email)
GRANT SELECT (id_matricula, nome, endereco, ativo) ON academico.alunos TO professor_role;

-- =============================================================
-- 4. DML - POPULACAO DE DADOS (Inserts)
-- =============================================================

-- Inserir Docentes
INSERT INTO academico.docentes (nome) VALUES
('Prof. Carlos Mendes'),       -- id_docente = 1
('Profa. Juliana Castro'),     -- id_docente = 2
('Prof. Renato Alves'),        -- id_docente = 3
('Profa. Marina Lopes'),       -- id_docente = 4
('Prof. Eduardo Pires'),       -- id_docente = 5
('Prof. Ricardo Faria'),       -- id_docente = 6
('Prof. Marcos Silva');        -- id_docente = 7 (sem turma - para LEFT JOIN)

-- Inserir Disciplinas (cada disciplina com seu docente responsavel)
INSERT INTO academico.disciplinas (cod_disciplina, nome, carga_horaria, id_docente) VALUES
('ADS101', 'Banco de Dados',           80, 1),   -- Prof. Carlos Mendes
('ADS102', 'Engenharia de Software',   80, 2),   -- Profa. Juliana Castro
('ADS103', 'Algoritmos',               60, 3),   -- Prof. Renato Alves
('ADS104', 'Redes de Computadores',    60, 4),   -- Profa. Marina Lopes
('ADS105', 'Sistemas Operacionais',    60, 5),   -- Prof. Eduardo Pires
('ADS106', 'Estruturas de Dados',      80, 6);   -- Prof. Ricardo Faria

-- Inserir Alunos (dados unicos extraidos da planilha)
INSERT INTO academico.alunos (id_matricula, nome, email, endereco) VALUES
(2026001, 'Ana Beatriz Lima',      'ana.lima@aluno.edu.br',        'Braganca Paulista/SP'),
(2026002, 'Bruno Henrique Souza',  'bruno.souza@aluno.edu.br',     'Atibaia/SP'),
(2026003, 'Camila Ferreira',       'camila.ferreira@aluno.edu.br', 'Jundiai/SP'),
(2026004, 'Diego Martins',         'diego.martins@aluno.edu.br',   'Campinas/SP'),
(2026005, 'Eduarda Nunes',         'eduarda.nunes@aluno.edu.br',   'Itatiba/SP'),
(2026006, 'Felipe Araujo',         'felipe.araujo@aluno.edu.br',   'Louveira/SP'),
(2025010, 'Gabriela Torres',       'gabriela.torres@aluno.edu.br', 'Nazare Paulista/SP'),
(2025011, 'Helena Rocha',          'helena.rocha@aluno.edu.br',    'Piracaia/SP'),
(2025012, 'Igor Santana',          'igor.santana@aluno.edu.br',    'Jarinu/SP');

-- Inserir Ciclos Academicos
INSERT INTO academico.ciclos (descricao) VALUES
('2026/1'),   -- id_ciclo = 1
('2025/2');   -- id_ciclo = 2

-- Inserir Matriculas (registros da planilha legada)
-- Ciclo 2026/1 (id_ciclo = 1)
INSERT INTO academico.matriculas (id_aluno, cod_disciplina, id_ciclo, data_ingresso, nota_final) VALUES
-- Ana Beatriz Lima
(2026001, 'ADS101', 1, '2026-01-20', 9.1),
(2026001, 'ADS102', 1, '2026-01-20', 8.4),
(2026001, 'ADS105', 1, '2026-01-20', 8.9),
-- Bruno Henrique Souza
(2026002, 'ADS101', 1, '2026-01-21', 7.3),
(2026002, 'ADS103', 1, '2026-01-21', 6.8),
(2026002, 'ADS104', 1, '2026-01-21', 7.0),
-- Camila Ferreira
(2026003, 'ADS101', 1, '2026-01-22', 5.9),
(2026003, 'ADS102', 1, '2026-01-22', 7.5),
(2026003, 'ADS106', 1, '2026-01-22', 6.1),
-- Diego Martins
(2026004, 'ADS103', 1, '2026-01-23', 4.7),
(2026004, 'ADS104', 1, '2026-01-23', 6.2),
(2026004, 'ADS105', 1, '2026-01-23', 5.8),
-- Eduarda Nunes
(2026005, 'ADS102', 1, '2026-01-24', 9.5),
(2026005, 'ADS104', 1, '2026-01-24', 8.1),
(2026005, 'ADS106', 1, '2026-01-24', 8.7),
-- Felipe Araujo
(2026006, 'ADS101', 1, '2026-01-25', 6.4),
(2026006, 'ADS103', 1, '2026-01-25', 5.6),
(2026006, 'ADS105', 1, '2026-01-25', 6.9);

-- Ciclo 2025/2 (id_ciclo = 2)
INSERT INTO academico.matriculas (id_aluno, cod_disciplina, id_ciclo, data_ingresso, nota_final) VALUES
-- Gabriela Torres
(2025010, 'ADS101', 2, '2025-08-05', 6.4),
(2025010, 'ADS102', 2, '2025-08-05', 7.1),
-- Helena Rocha
(2025011, 'ADS103', 2, '2025-08-06', 8.8),
(2025011, 'ADS104', 2, '2025-08-06', 7.9),
-- Igor Santana
(2025012, 'ADS105', 2, '2025-08-07', 5.5),
(2025012, 'ADS106', 2, '2025-08-07', 6.3);

-- =============================================================
-- 5. CONSULTAS E RELATORIOS (Item 4)
-- =============================================================

-- ---------------------------------------------------------------
-- 5.1 Listagem de Matriculados (Ciclo 2026/1)
-- Nome dos alunos, nomes das disciplinas e ciclo
-- ---------------------------------------------------------------
SELECT
    a.nome          AS nome_aluno,
    d.nome          AS nome_disciplina,
    c.descricao     AS ciclo
FROM academico.matriculas m
INNER JOIN academico.alunos a       ON m.id_aluno = a.id_matricula
INNER JOIN academico.disciplinas d  ON m.cod_disciplina = d.cod_disciplina
INNER JOIN academico.ciclos c       ON m.id_ciclo = c.id_ciclo
WHERE c.descricao = '2026/1'
ORDER BY a.nome, d.nome;

-- ---------------------------------------------------------------
-- 5.2 Baixo Desempenho
-- Media de notas por disciplina com media inferior a 6.0
-- ---------------------------------------------------------------
SELECT
    d.nome                          AS nome_disciplina,
    ROUND(AVG(m.nota_final), 2)     AS media_notas
FROM academico.matriculas m
INNER JOIN academico.disciplinas d ON m.cod_disciplina = d.cod_disciplina
GROUP BY d.nome
HAVING AVG(m.nota_final) < 6.0
ORDER BY media_notas;

-- ---------------------------------------------------------------
-- 5.3 Alocacao de Docentes (LEFT JOIN)
-- Lista todos os docentes e suas respectivas disciplinas,
-- incluindo docentes sem turmas vinculadas
-- ---------------------------------------------------------------
SELECT
    doc.nome        AS nome_docente,
    d.nome          AS nome_disciplina
FROM academico.docentes doc
LEFT JOIN academico.disciplinas d ON doc.id_docente = d.id_docente
ORDER BY doc.nome, d.nome;

-- ---------------------------------------------------------------
-- 5.4 Destaque Academico (Subconsulta)
-- Aluno com a maior nota na disciplina "Banco de Dados"
-- ---------------------------------------------------------------
SELECT
    a.nome          AS nome_aluno,
    m.nota_final    AS nota
FROM academico.matriculas m
INNER JOIN academico.alunos a       ON m.id_aluno = a.id_matricula
INNER JOIN academico.disciplinas d  ON m.cod_disciplina = d.cod_disciplina
WHERE d.nome = 'Banco de Dados'
  AND m.nota_final = (
      SELECT MAX(m2.nota_final)
      FROM academico.matriculas m2
      INNER JOIN academico.disciplinas d2 ON m2.cod_disciplina = d2.cod_disciplina
      WHERE d2.nome = 'Banco de Dados'
  );
