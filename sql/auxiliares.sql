USE encontraafya;

-- Impede correspondência que não ligue uma ocorrência ENCONTRADO a uma PERDIDO.
DELIMITER //

CREATE TRIGGER trg_correspondencia_tipos
BEFORE INSERT ON correspondencia
FOR EACH ROW
BEGIN
  DECLARE tipo_encontrada VARCHAR(20);
  DECLARE tipo_perdida VARCHAR(20);

  SELECT tipo INTO tipo_encontrada
  FROM ocorrencia
  WHERE id_ocorrencia = NEW.id_ocorrencia_encontrada;

  SELECT tipo INTO tipo_perdida
  FROM ocorrencia
  WHERE id_ocorrencia = NEW.id_ocorrencia_perdida;

  IF tipo_encontrada <> 'ENCONTRADO' OR tipo_perdida <> 'PERDIDO' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'A correspondência deve ligar uma ocorrência ENCONTRADO a uma PERDIDO';
  END IF;
END //

DELIMITER ;

-- Conferência: quantidade de registros por tabela.
SELECT 'pessoa' AS tabela, COUNT(*) AS registros FROM pessoa
UNION ALL SELECT 'funcionario_responsavel', COUNT(*) FROM funcionario_responsavel
UNION ALL SELECT 'categoria', COUNT(*) FROM categoria
UNION ALL SELECT 'local', COUNT(*) FROM local
UNION ALL SELECT 'objeto', COUNT(*) FROM objeto
UNION ALL SELECT 'ocorrencia', COUNT(*) FROM ocorrencia
UNION ALL SELECT 'tentativa_identificacao', COUNT(*) FROM tentativa_identificacao
UNION ALL SELECT 'correspondencia', COUNT(*) FROM correspondencia
UNION ALL SELECT 'devolucao', COUNT(*) FROM devolucao
UNION ALL SELECT 'historico_status', COUNT(*) FROM historico_status;
