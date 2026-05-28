-- Seed para educonnect_analytics
-- Ejecutar: docker exec -i educonnect-mysql-analytics mysql -uroot -prootsecret educonnect_analytics < database/seeds/seed_analytics.sql

USE educonnect_analytics;

-- ============================================================
-- TABLAS ANALÍTICAS (creadas por migración)
-- ============================================================

-- Las tablas de analytics son creadas por la migración pero no tengo acceso al DDL exacto.
-- Asumiendo tablas genéricas para almacenar eventos xAPI y métricas.

CREATE TABLE IF NOT EXISTS xapi_statements (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    statement_id VARCHAR(255) UNIQUE NOT NULL,
    user_id BIGINT UNSIGNED,
    verb VARCHAR(100) NOT NULL,
    object_id VARCHAR(255) NOT NULL,
    object_type VARCHAR(100),
    result_score DECIMAL(5,2),
    result_completion BOOLEAN,
    result_duration_seconds INT,
    context_activities JSON,
    raw_statement JSON NOT NULL,
    stored_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_verb (verb),
    INDEX idx_stored (stored_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS daily_metrics (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    metric_date DATE NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(12,2) NOT NULL,
    dimensions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_metric (metric_date, metric_name),
    INDEX idx_date (metric_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- STATEMENTS xAPI
-- ============================================================
INSERT INTO xapi_statements (statement_id, user_id, verb, object_id, object_type, result_score, result_completion, result_duration_seconds, context_activities, raw_statement, stored_at)
VALUES
('xapi-001-0001', 1, 'completed', 'http://educonnect/content/1', 'VIDEO', 85.00, TRUE, 1800, '{"parent":"http://educonnect/path/1","grouping":"http://educonnect/course/1"}', '{"actor":{"mbox":"mailto:maria@educonnect.edu","name":"María García"},"verb":{"id":"http://adlnet.gov/expapi/verbs/completed","display":{"es":"Completó"}},"object":{"id":"http://educonnect/content/1","definition":{"name":{"es":"Números Naturales"},"type":"http://adlnet.gov/expapi/activities/video"}},"result":{"score":{"raw":85,"min":0,"max":100},"completion":true,"duration":"PT30M"}}', DATE_SUB(NOW(), INTERVAL 12 DAY)),
('xapi-001-0002', 1, 'completed', 'http://educonnect/content/2', 'INTERACTIVE', 72.00, TRUE, 1500, '{"parent":"http://educonnect/path/1","grouping":"http://educonnect/course/1"}', '{"actor":{"mbox":"mailto:maria@educonnect.edu"},"verb":{"id":"http://adlnet.gov/expapi/verbs/completed"},"object":{"id":"http://educonnect/content/2"},"result":{"score":{"raw":72},"completion":true,"duration":"PT25M"}}', DATE_SUB(NOW(), INTERVAL 10 DAY)),
('xapi-001-0003', 1, 'progressed', 'http://educonnect/content/3', 'EXERCISE', NULL, FALSE, 900, '{"parent":"http://educonnect/path/1"}', '{"actor":{"mbox":"mailto:maria@educonnect.edu"},"verb":{"id":"http://adlnet.gov/expapi/verbs/progressed"},"object":{"id":"http://educonnect/content/3"},"result":{"extensions":{"http://educonnect/extensions/progress":45}}}', DATE_SUB(NOW(), INTERVAL 1 DAY)),
('xapi-001-0004', 5, 'completed', 'http://educonnect/content/1', 'VIDEO', 95.00, TRUE, 1500, '{"parent":"http://educonnect/path/3","grouping":"http://educonnect/course/1"}', '{"actor":{"mbox":"mailto:pedro@educonnect.edu"},"verb":{"id":"http://adlnet.gov/expapi/verbs/completed"},"object":{"id":"http://educonnect/content/1"},"result":{"score":{"raw":95},"completion":true,"duration":"PT25M"}}', DATE_SUB(NOW(), INTERVAL 25 DAY)),
('xapi-001-0005', 5, 'completed', 'http://educonnect/content/4', 'VIDEO', 92.00, TRUE, 1600, '{"parent":"http://educonnect/path/3"}', '{"actor":{"mbox":"mailto:pedro@educonnect.edu"},"verb":{"id":"http://adlnet.gov/expapi/verbs/completed"},"object":{"id":"http://educonnect/content/4"},"result":{"score":{"raw":92},"completion":true,"duration":"PT27M"}}', DATE_SUB(NOW(), INTERVAL 10 DAY)),
('xapi-001-0006', 1, 'completed', 'http://educonnect/content/6', 'VIDEO', 90.00, TRUE, 1200, '{"parent":"http://educonnect/path/2"}', '{"actor":{"mbox":"mailto:maria@educonnect.edu"},"verb":{"id":"http://adlnet.gov/expapi/verbs/completed"},"object":{"id":"http://educonnect/content/6"},"result":{"score":{"raw":90},"completion":true,"duration":"PT20M"}}', DATE_SUB(NOW(), INTERVAL 5 DAY));

-- ============================================================
-- MÉTRICAS DIARIAS
-- ============================================================
INSERT INTO daily_metrics (metric_date, metric_name, metric_value, dimensions)
VALUES
(CURDATE(), 'active_users', 4, '{"total":4,"students":3,"teachers":1}'),
(CURDATE(), 'content_views', 15, '{"video":5,"interactive":3,"document":2,"exercise":3,"quiz":2}'),
(CURDATE(), 'sync_operations', 7, '{"completed":5,"pending":2,"conflicts":1}'),
(CURDATE(), 'offline_usage_pct', 23.5, '{"online":76.5,"offline":23.5}'),
(DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'active_users', 3, '{"total":3,"students":2,"teachers":1}'),
(DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'content_views', 10, '{"video":4,"interactive":2,"document":1,"exercise":2,"quiz":1}'),
(DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'sync_operations', 4, '{"completed":4,"pending":0}'),
(DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'active_users', 5, '{"total":5,"students":3,"teachers":2}'),
(DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'content_views', 20, '{"video":8,"interactive":4,"document":3,"exercise":3,"quiz":2}');
