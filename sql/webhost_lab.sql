-- WebHost Lab - criação do banco, tabela e registros de teste
-- Execução: mysql -u root -p < webhost_lab.sql

CREATE DATABASE IF NOT EXISTS webhost_lab
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE webhost_lab;

CREATE TABLE IF NOT EXISTS servidores (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(50)  NOT NULL,
  funcao        VARCHAR(100) NOT NULL,
  ip            VARCHAR(15)  NOT NULL,
  sistema       VARCHAR(50)  NOT NULL,
  criado_em     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO servidores (nome, funcao, ip, sistema) VALUES
  ('WEB-SRV01', 'Servidor web (IIS)',       '192.168.100.10', 'Windows Server 2022'),
  ('WEB-SRV01', 'Banco de dados (MySQL)',   '192.168.100.10', 'Windows Server 2022'),
  ('HOST-LAB',  'Hospedeiro Hyper-V',       '192.168.100.1',  'Windows 11');

-- Consulta de validação
SELECT id, nome, funcao, ip, sistema, criado_em FROM servidores;
SELECT COUNT(*) AS total_registros FROM servidores;
