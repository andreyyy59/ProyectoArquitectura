-- ============================================================
-- MS-05: Adaptive Engine — Rutas de aprendizaje personalizadas
-- Database: educonnect_users
-- ============================================================

CREATE TABLE IF NOT EXISTS learning_paths (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(255) NULL,
    subject_area VARCHAR(255) NULL COMMENT 'Área de conocimiento',
    status ENUM('ACTIVE', 'COMPLETED', 'PAUSED', 'ABANDONED') DEFAULT 'ACTIVE',
    progress_percent DECIMAL(5, 2) DEFAULT 0.00,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    last_activity_at TIMESTAMP NULL,
    metadata JSON NULL COMMENT 'Datos de la ruta generada por el motor adaptativo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_lp_user (user_id),
    INDEX idx_lp_status (status),
    INDEX idx_lp_progress (progress_percent),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS learning_path_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    learning_path_id BIGINT UNSIGNED NOT NULL,
    content_id BIGINT UNSIGNED NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    status ENUM('PENDING', 'AVAILABLE', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'SKIPPED') DEFAULT 'PENDING',
    score DECIMAL(5, 2) NULL,
    time_spent_seconds INT DEFAULT 0,
    attempts_count INT DEFAULT 0,
    max_attempts INT DEFAULT 3,
    is_mandatory TINYINT(1) DEFAULT 1,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_lpi_path (learning_path_id),
    INDEX idx_lpi_content (content_id),
    INDEX idx_lpi_status (status),
    FOREIGN KEY (learning_path_id) REFERENCES learning_paths(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_progress (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    content_id BIGINT UNSIGNED NOT NULL,
    progress_percent DECIMAL(5, 2) DEFAULT 0.00,
    score DECIMAL(5, 2) NULL,
    time_spent_seconds INT DEFAULT 0,
    interaction_count INT DEFAULT 0,
    last_position VARCHAR(50) NULL COMMENT 'Última posición en video/lectura',
    status ENUM('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED', 'FAILED') DEFAULT 'NOT_STARTED',
    is_offline TINYINT(1) DEFAULT 0 COMMENT 'Registrado offline',
    client_timestamp TIMESTAMP NULL COMMENT 'Timestamp del cliente para resolución offline',
    synced_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_progress (user_id, content_id),
    INDEX idx_progress_user (user_id),
    INDEX idx_progress_content (content_id),
    INDEX idx_progress_sync (synced_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS competencies (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT NULL,
    subject_area VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_competencies (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    competency_id BIGINT UNSIGNED NOT NULL,
    proficiency_level DECIMAL(5, 2) DEFAULT 0.00 COMMENT '0.00 - 100.00',
    last_assessed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_comp (user_id, competency_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (competency_id) REFERENCES competencies(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
