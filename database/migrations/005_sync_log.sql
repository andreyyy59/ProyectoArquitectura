-- ============================================================
-- MS-04: Offline Sync Engine — Tablas de sincronización
-- Database per Service: educonnect_sync
-- ============================================================

CREATE TABLE IF NOT EXISTS sync_batches (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    uuid CHAR(36) NOT NULL UNIQUE,
    edge_node_id BIGINT UNSIGNED NULL,
    user_id BIGINT UNSIGNED NULL,
    batch_type ENUM('FULL', 'DELTA', 'HEARTBEAT', 'CONFLICT_RESOLUTION') NOT NULL DEFAULT 'DELTA',
    status ENUM('INITIATED', 'HANDSHAKE', 'DOWNLOADING', 'UPLOADING', 'RESOLVING', 'COMPLETED', 'FAILED') DEFAULT 'INITIATED',
    phase ENUM('DETECTION', 'HANDSHAKE', 'DELTA_DOWNLOAD', 'DELTA_UPLOAD', 'CONFLICT_RESOLUTION') DEFAULT 'DETECTION',
    items_total INT DEFAULT 0,
    items_processed INT DEFAULT 0,
    bytes_transferred BIGINT DEFAULT 0,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    error_message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sync_batch_id BIGINT UNSIGNED NOT NULL,
    entity_type VARCHAR(100) NOT NULL COMMENT 'Tipo de entidad (user_progress, content, etc.)',
    entity_id VARCHAR(100) NOT NULL COMMENT 'ID de la entidad',
    operation ENUM('CREATE', 'UPDATE', 'DELETE') NOT NULL,
    payload JSON NOT NULL COMMENT 'Payload completo del cambio',
    payload_hash VARCHAR(64) NOT NULL COMMENT 'SHA-256 del payload',
    client_timestamp TIMESTAMP NOT NULL COMMENT 'Timestamp del cliente',
    server_timestamp TIMESTAMP NULL,
    conflict_resolution ENUM('CLIENT_WINS', 'SERVER_WINS', 'MERGED', 'PENDING') DEFAULT 'PENDING',
    is_synced TINYINT(1) DEFAULT 0,
    synced_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sync_batch (sync_batch_id),
    INDEX idx_sync_entity (entity_type, entity_id),
    INDEX idx_sync_synced (is_synced),
    INDEX idx_sync_conflict (conflict_resolution),
    FOREIGN KEY (sync_batch_id) REFERENCES sync_batches(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_conflicts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sync_event_id BIGINT UNSIGNED NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    client_payload JSON NOT NULL,
    server_payload JSON NOT NULL,
    resolution_strategy ENUM('LAST_WRITE_WINS', 'MERGE', 'MANUAL') DEFAULT 'LAST_WRITE_WINS',
    resolution_result JSON NULL,
    resolved_by ENUM('AUTOMATIC', 'MANUAL') DEFAULT 'AUTOMATIC',
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sync_event_id) REFERENCES sync_events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_checkpoints (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    edge_node_id BIGINT UNSIGNED NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    last_synced_id BIGINT UNSIGNED DEFAULT 0,
    last_synced_at TIMESTAMP NULL,
    checkpoint_data JSON NULL COMMENT 'Estado del checkpoint para reanudar sincronización',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_checkpoint (edge_node_id, entity_type),
    FOREIGN KEY (edge_node_id) REFERENCES edge_nodes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
