-- ============================================================
-- MS-01: User Management — Tablas principales
-- Database per Service: educonnect_users
-- ============================================================

CREATE TABLE IF NOT EXISTS roles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE COMMENT 'student | teacher | admin | edge_admin',
    slug VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    document_id VARCHAR(50) NULL UNIQUE COMMENT 'Cédula / Identificación',
    phone VARCHAR(20) NULL,
    avatar_url VARCHAR(500) NULL,
    locale VARCHAR(10) DEFAULT 'es',
    is_active TINYINT(1) DEFAULT 1,
    last_login_at TIMESTAMP NULL,
    last_sync_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_users_role (role_id),
    INDEX idx_users_active (is_active),
    INDEX idx_users_sync (last_sync_at),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    birth_date DATE NULL,
    gender ENUM('M', 'F', 'OTHER', 'UNDISCLOSED') DEFAULT 'UNDISCLOSED',
    municipality VARCHAR(255) NULL COMMENT 'Municipio / Distrito',
    department VARCHAR(255) NULL COMMENT 'Departamento / Provincia',
    institution VARCHAR(255) NULL COMMENT 'Nombre de la escuela / colegio',
    grade_level VARCHAR(50) NULL COMMENT 'Grado / Año escolar',
    connectivity_type ENUM('2G', '3G', '4G', 'SATELLITE', 'FIBER', 'NONE') DEFAULT 'NONE',
    device_type ENUM('TABLET', 'PHONE', 'DESKTOP', 'SHARED') DEFAULT 'DESKTOP',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    token_jwt VARCHAR(500) NOT NULL,
    refresh_token VARCHAR(500) NULL,
    device_info JSON NULL,
    ip_address VARCHAR(45) NULL,
    is_valid TINYINT(1) DEFAULT 1,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sessions_user (user_id),
    INDEX idx_sessions_token (token_jwt(255)),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS offline_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE COMMENT 'Hash del token offline',
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    last_validated_at TIMESTAMP NULL,
    is_revoked TINYINT(1) DEFAULT 0,
    INDEX idx_offline_user (user_id),
    INDEX idx_offline_hash (token_hash),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed roles
INSERT INTO roles (name, slug, description) VALUES
    ('Estudiante', 'student', 'Estudiante que consume contenidos educativos'),
    ('Docente', 'teacher', 'Docente que gestiona grupos y contenidos'),
    ('Administrador', 'admin', 'Administrador global del sistema'),
    ('Admin de Nodo', 'edge_admin', 'Administrador de un nodo periférico')
ON DUPLICATE KEY UPDATE name = VALUES(name);
