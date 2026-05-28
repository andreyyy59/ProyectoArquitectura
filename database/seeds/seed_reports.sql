-- Seed para educonnect_reports
-- Ejecutar: docker exec -i educonnect-mysql-reports mysql -uroot -prootsecret educonnect_reports < database/seeds/seed_reports.sql

USE educonnect_reports;

-- ============================================================
-- TABLAS DE REPORTES
-- ============================================================
CREATE TABLE IF NOT EXISTS regional_stats (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department VARCHAR(100) NOT NULL,
    municipality VARCHAR(100) NOT NULL,
    total_students INT DEFAULT 0,
    total_teachers INT DEFAULT 0,
    active_nodes INT DEFAULT 0,
    learning_paths_created INT DEFAULT 0,
    contents_delivered INT DEFAULT 0,
    avg_completion_rate DECIMAL(5,2) DEFAULT 0,
    connectivity_type VARCHAR(50) DEFAULT 'NONE',
    report_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_region (department, municipality, report_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS student_performance (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    subject_area VARCHAR(100),
    avg_score DECIMAL(5,2) DEFAULT 0,
    activities_completed INT DEFAULT 0,
    total_time_minutes INT DEFAULT 0,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_subject (subject_area)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- DATOS REGIONALES
-- ============================================================
INSERT INTO regional_stats (department, municipality, total_students, total_teachers, active_nodes, learning_paths_created, contents_delivered, avg_completion_rate, connectivity_type, report_date)
VALUES
('Cauca', 'Timbiquí', 45, 3, 2, 28, 15, 62.50, '2G', CURDATE()),
('Cauca', 'Guapi', 38, 2, 1, 22, 12, 55.00, '3G', CURDATE()),
('Cauca', 'Popayán', 120, 8, 3, 85, 45, 78.30, 'FIBER', CURDATE()),
('Valle del Cauca', 'Buenaventura', 95, 6, 2, 60, 30, 70.10, '4G', CURDATE()),
('Nariño', 'Barbacoas', 32, 2, 1, 18, 10, 48.00, '2G', CURDATE()),
('Cauca', 'Timbiquí', 42, 3, 2, 25, 12, 60.00, '2G', DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
('Cauca', 'Guapi', 35, 2, 1, 20, 10, 52.00, '3G', DATE_SUB(CURDATE(), INTERVAL 1 MONTH));

-- ============================================================
-- RENDIMIENTO DE ESTUDIANTES
-- ============================================================
INSERT INTO student_performance (user_id, subject_area, avg_score, activities_completed, total_time_minutes, period_start, period_end)
VALUES
(1, 'Matemáticas', 78.50, 2, 55, DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE()),
(1, 'Lenguaje', 90.00, 1, 20, DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE()),
(5, 'Matemáticas', 88.25, 4, 112, DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE()),
(2, 'Matemáticas', 0, 0, 0, DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE()),
(1, 'Matemáticas', 75.00, 1, 30, DATE_SUB(CURDATE(), INTERVAL 60 DAY), DATE_SUB(CURDATE(), INTERVAL 31 DAY)),
(5, 'Matemáticas', 85.00, 2, 50, DATE_SUB(CURDATE(), INTERVAL 60 DAY), DATE_SUB(CURDATE(), INTERVAL 31 DAY));
