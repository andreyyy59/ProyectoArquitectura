-- ============================================================
-- MS-02: Edge Node Manager — Tablas de topología y nodos
-- Database: educonnect_users (comparte DB con MS-01)
-- ============================================================

CREATE TABLE IF NOT EXISTS edge_nodes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL COMMENT 'Nombre del nodo (ej: Nodo-Cauca-01)',
    location_lat DECIMAL(10, 7) NULL,
    location_lng DECIMAL(10, 7) NULL,
    municipality VARCHAR(255) NULL,
    department VARCHAR(255) NULL,
    node_type ENUM('REGIONAL', 'LOCAL', 'SCHOOL') DEFAULT 'LOCAL',
    ip_address VARCHAR(45) NULL,
    mac_address VARCHAR(17) NULL,
    storage_capacity_mb BIGINT DEFAULT 0,
    storage_used_mb BIGINT DEFAULT 0,
    cpu_cores INT DEFAULT 0,
    ram_mb INT DEFAULT 0,
    status ENUM('ONLINE', 'OFFLINE', 'DEGRADED', 'MAINTENANCE') DEFAULT 'OFFLINE',
    last_heartbeat_at TIMESTAMP NULL,
    last_sync_at TIMESTAMP NULL,
    parent_node_id BIGINT UNSIGNED NULL COMMENT 'Nodo padre en la topología',
    config_json JSON NULL COMMENT 'Configuración específica del nodo',
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_nodes_status (status),
    INDEX idx_nodes_region (municipality, department),
    INDEX idx_nodes_parent (parent_node_id),
    FOREIGN KEY (parent_node_id) REFERENCES edge_nodes(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS node_heartbeats (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    edge_node_id BIGINT UNSIGNED NOT NULL,
    status ENUM('ONLINE', 'OFFLINE', 'DEGRADED') NOT NULL DEFAULT 'ONLINE',
    latency_ms INT NOT NULL DEFAULT 0 COMMENT 'Latencia medida en ms',
    cpu_usage_percent DECIMAL(5, 2) DEFAULT 0,
    ram_usage_percent DECIMAL(5, 2) DEFAULT 0,
    storage_usage_percent DECIMAL(5, 2) DEFAULT 0,
    active_users_count INT DEFAULT 0,
    bandwidth_kbps INT DEFAULT 0,
    checked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_heartbeat_node (edge_node_id),
    INDEX idx_heartbeat_time (checked_at DESC),
    FOREIGN KEY (edge_node_id) REFERENCES edge_nodes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS node_sync_windows (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    edge_node_id BIGINT UNSIGNED NOT NULL,
    window_start TIME NOT NULL COMMENT 'Inicio de ventana de conectividad',
    window_end TIME NOT NULL COMMENT 'Fin de ventana de conectividad',
    day_of_week TINYINT NOT NULL COMMENT '1=Lun ... 7=Dom',
    priority ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') DEFAULT 'MEDIUM',
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sync_window_node (edge_node_id, is_active),
    FOREIGN KEY (edge_node_id) REFERENCES edge_nodes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
