-- Seed para educonnect_sync
-- Ejecutar: docker exec -i educonnect-mysql-sync mysql -uroot -prootsecret educonnect_sync < database/seeds/seed_sync.sql

USE educonnect_sync;

-- ============================================================
-- BATCHES DE SINCRONIZACIÓN
-- ============================================================
INSERT INTO sync_batches (uuid, edge_node_id, user_id, batch_type, status, phase, items_total, items_processed, bytes_transferred, error_message, started_at, completed_at, created_at)
VALUES
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 2, 1, 'DELTA', 'COMPLETED', 'CONFLICT_RESOLUTION', 5, 5, 204800, NULL, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
('b2c3d4e5-f6a7-8901-bcde-f12345678901', 3, 5, 'HEARTBEAT', 'COMPLETED', 'CONFLICT_RESOLUTION', 0, 0, 1024, NULL, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),
('c3d4e5f6-a7b8-9012-cdef-123456789012', 2, 1, 'DELTA', 'UPLOADING', 'DELTA_UPLOAD', 3, 1, 51200, NULL, NOW(), NULL, NOW());

-- ============================================================
-- EVENTOS DE SINCRONIZACIÓN
-- ============================================================
INSERT INTO sync_events (sync_batch_id, entity_type, entity_id, operation, payload, payload_hash, client_timestamp, server_timestamp, conflict_resolution, is_synced, synced_at, created_at)
VALUES
(1, 'student_progress', '1:3', 'UPDATE', '{"progress_percent":45,"status":"IN_PROGRESS","is_offline":true}', 'sha256-dummy-hash-001', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 'CLIENT_WINS', 1, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(1, 'student_progress', '1:7', 'UPDATE', '{"progress_percent":30,"status":"IN_PROGRESS","is_offline":true}', 'sha256-dummy-hash-002', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 'CLIENT_WINS', 1, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(1, 'learning_path_item', '1:3', 'UPDATE', '{"status":"IN_PROGRESS","time_spent_seconds":900}', 'sha256-dummy-hash-003', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 'SERVER_WINS', 1, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(1, 'learning_path', '1', 'UPDATE', '{"progress_percent":35,"last_activity_at":"2026-05-23T10:30:00Z"}', 'sha256-dummy-hash-004', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 'MERGED', 1, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(1, 'xapi_statement', 'xapi-001', 'CREATE', '{"actor":{"mbox":"mailto:maria@educonnect.edu"},"verb":{"id":"http://adlnet.gov/expapi/verbs/completed"},"object":{"id":"http://educonnect/content/3"}}', 'sha256-dummy-hash-005', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 'CLIENT_WINS', 1, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(3, 'student_progress', '1:3', 'UPDATE', '{"progress_percent":55,"status":"IN_PROGRESS","is_offline":false}', 'sha256-dummy-hash-006', NOW(), NULL, 'PENDING', 0, NULL, NOW()),
(3, 'xapi_statement', 'xapi-002', 'CREATE', '{"actor":{"mbox":"mailto:maria@educonnect.edu"},"verb":{"id":"http://adlnet.gov/expapi/verbs/interacted"},"object":{"id":"http://educonnect/content/3"}}', 'sha256-dummy-hash-007', NOW(), NULL, 'PENDING', 0, NULL, NOW());

-- ============================================================
-- CONFLICTOS DE SINCRONIZACIÓN
-- ============================================================
INSERT INTO sync_conflicts (sync_event_id, entity_type, entity_id, client_payload, server_payload, resolution_strategy, resolution_result, resolved_by, resolved_at, created_at)
VALUES
(4, 'learning_path', '1', '{"progress_percent":35,"last_activity_at":"2026-05-23T10:30:00Z"}', '{"progress_percent":30,"last_activity_at":"2026-05-23T09:15:00Z"}', 'LAST_WRITE_WINS', '{"applied":"client","reason":"client_timestamp newer"}', 'AUTOMATIC', DATE_SUB(NOW(), INTERVAL 2 DAY), NOW());

-- CHECKPOINTS omitidos porque sync_checkpoints requiere FK a edge_nodes(id)
-- que está en educonnect_users (base de datos distinta, no soportado por FK)
