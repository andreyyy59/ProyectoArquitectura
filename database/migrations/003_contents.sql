-- ============================================================
-- MS-03: Content Management — Tablas de contenidos educativos
-- Database per Service: educonnect_content
-- ============================================================

CREATE TABLE IF NOT EXISTS content_categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NULL,
    parent_id BIGINT UNSIGNED NULL,
    sort_order INT DEFAULT 0,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_cat_parent (parent_id),
    FOREIGN KEY (parent_id) REFERENCES content_categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    title VARCHAR(500) NOT NULL,
    description TEXT NULL,
    content_type ENUM('VIDEO', 'PDF', 'EXERCISE', 'QUIZ', 'INTERACTIVE', 'AUDIO', 'DOCUMENT') NOT NULL,
    category_id BIGINT UNSIGNED NULL,
    difficulty_level ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED') DEFAULT 'BEGINNER',
    estimated_duration_minutes INT DEFAULT 0,
    file_url VARCHAR(1000) NULL,
    file_size_bytes BIGINT DEFAULT 0,
    file_hash VARCHAR(64) NULL COMMENT 'SHA-256 del archivo para verificación',
    storage_path VARCHAR(500) NULL COMMENT 'Ruta en MinIO / disco local',
    thumbnail_url VARCHAR(500) NULL,
    version INT DEFAULT 1 COMMENT 'Versión del contenido para delta sync',
    is_offline_available TINYINT(1) DEFAULT 0 COMMENT 'Disponible sin conexión',
    is_published TINYINT(1) DEFAULT 0,
    metadata JSON NULL COMMENT 'Metadatos extendidos (xAPI, LOM, etc.)',
    published_at TIMESTAMP NULL,
    created_by BIGINT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_content_type (content_type),
    INDEX idx_content_category (category_id),
    INDEX idx_content_difficulty (difficulty_level),
    INDEX idx_content_offline (is_offline_available),
    INDEX idx_content_version (version),
    FULLTEXT idx_content_search (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS content_dependencies (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    content_id BIGINT UNSIGNED NOT NULL,
    depends_on_content_id BIGINT UNSIGNED NOT NULL,
    dependency_type ENUM('PREREQUISITE', 'RECOMMENDED', 'SEQUEL') DEFAULT 'PREREQUISITE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_dependency (content_id, depends_on_content_id),
    INDEX idx_dep_content (content_id),
    FOREIGN KEY (content_id) REFERENCES contents(id) ON DELETE CASCADE,
    FOREIGN KEY (depends_on_content_id) REFERENCES contents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS content_distributions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    content_id BIGINT UNSIGNED NOT NULL,
    edge_node_id BIGINT UNSIGNED NOT NULL,
    distribution_status ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED') DEFAULT 'PENDING',
    version_at_distribution INT DEFAULT 1,
    downloaded_at TIMESTAMP NULL,
    bytes_transferred BIGINT DEFAULT 0,
    error_message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_distribution (content_id, edge_node_id),
    INDEX idx_dist_node (edge_node_id, distribution_status),
    FOREIGN KEY (content_id) REFERENCES contents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
