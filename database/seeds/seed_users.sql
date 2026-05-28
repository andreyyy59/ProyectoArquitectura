-- Seed para educonnect_users
-- Password de todos los usuarios: "password" (bcrypt hash)
-- Ejecutar: docker exec -i educonnect-mysql-user mysql -uroot -prootsecret educonnect_users < database/seeds/seed_users.sql

USE educonnect_users;

-- ============================================================
-- USUARIOS
-- ============================================================
INSERT INTO users (uuid, full_name, email, password, role_id, document_id, phone, locale, is_active, last_login_at, last_sync_at, created_at, updated_at) VALUES
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'María García López',  'maria@educonnect.edu',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1, 'CC-1001', '3101112233', 'es', 1, NOW(), NOW(), NOW(), NOW()),
('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Carlos Pérez Martínez', 'carlos@educonnect.edu', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1, 'CC-1002', '3112223344', 'es', 1, NOW(), NOW(), NOW(), NOW()),
('c3d4e5f6-a7b8-9012-cdef-123456789012', 'Ana Martínez Ruiz',    'ana@educonnect.edu',    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2, 'CC-2001', '3123334455', 'es', 1, NOW(), NOW(), NOW(), NOW()),
('d4e5f6a7-b8c9-0123-defa-234567890123', 'Admin Sistema',        'admin@educonnect.edu',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 3, 'CC-3001', '3134445566', 'es', 1, NOW(), NOW(), NOW(), NOW()),
('e5f6a7b8-c9d0-1234-efab-345678901234', 'Pedro Sánchez Rojas',  'pedro@educonnect.edu',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1, 'CC-1003', '3145556677', 'es', 1, NOW(), NOW(), NOW(), NOW());

-- ============================================================
-- PERFILES DE USUARIO
-- ============================================================
INSERT INTO user_profiles (user_id, birth_date, gender, municipality, department, institution, grade_level, connectivity_type, device_type)
VALUES
(1, '2008-03-15', 'F', 'Timbiquí', 'Cauca', 'IE Timbiquí', '9°', '2G', 'TABLET'),
(2, '2009-07-22', 'M', 'Guapi', 'Cauca', 'IE Guapi Rural', '8°', '3G', 'PHONE'),
(3, '1985-11-10', 'F', 'Buenaventura', 'Valle del Cauca', 'IE Timbiquí', NULL, '4G', 'DESKTOP'),
(4, '1990-05-30', 'M', 'Popayán', 'Cauca', 'Secretaría Educación', NULL, 'FIBER', 'DESKTOP'),
(5, '2007-12-05', 'M', 'Barbacoas', 'Nariño', 'IE Barbacoas', '10°', '2G', 'TABLET');

-- ============================================================
-- EDGE NODES
-- ============================================================
INSERT INTO edge_nodes (uuid, name, location_lat, location_lng, municipality, department, node_type, ip_address, storage_capacity_mb, storage_used_mb, cpu_cores, ram_mb, status, config_json, is_active, created_at, updated_at)
VALUES
('f6a7b8c9-d0e1-2345-fabc-456789012345', 'Nodo Regional Cauca', 2.5700, -77.0000, 'Popayán', 'Cauca', 'REGIONAL', '10.0.1.10', 1024000, 256000, 8, 16384, 'ONLINE', '{"sync_interval":30,"max_concurrent_syncs":5}', 1, NOW(), NOW()),
('a7b8c9d0-e1f2-3456-abcd-567890123456', 'Nodo Local Timbiquí', 2.7736, -77.6650, 'Timbiquí', 'Cauca', 'LOCAL', '10.0.2.10', 512000, 128000, 4, 8192, 'ONLINE', '{"sync_interval":60,"max_concurrent_syncs":2}', 1, NOW(), NOW()),
('b8c9d0e1-f2a3-4567-bcde-678901234567', 'Nodo Escolar IE Timbiquí', 2.7710, -77.6680, 'Timbiquí', 'Cauca', 'SCHOOL', '10.0.3.10', 256000, 96000, 2, 4096, 'ONLINE', '{"sync_interval":120,"max_concurrent_syncs":1}', 1, NOW(), NOW());

-- ============================================================
-- HEARTBEATS
-- ============================================================
INSERT INTO node_heartbeats (edge_node_id, status, latency_ms, cpu_usage_percent, ram_usage_percent, storage_usage_percent, active_users_count, bandwidth_kbps, checked_at)
VALUES
(1, 'ONLINE', 45, 32, 55, 25, 12, 1024, NOW()),
(1, 'ONLINE', 48, 38, 58, 25, 14, 980, DATE_SUB(NOW(), INTERVAL 5 MINUTE)),
(1, 'ONLINE', 42, 30, 52, 25, 10, 1100, DATE_SUB(NOW(), INTERVAL 10 MINUTE)),
(2, 'ONLINE', 120, 45, 62, 25, 5, 256, NOW()),
(2, 'ONLINE', 130, 48, 65, 25, 6, 220, DATE_SUB(NOW(), INTERVAL 5 MINUTE)),
(3, 'DEGRADED', 450, 72, 85, 37, 3, 64, NOW());

-- ============================================================
-- VENTANAS DE SINCRONIZACIÓN
-- ============================================================
INSERT INTO node_sync_windows (edge_node_id, window_start, window_end, day_of_week, priority, is_active)
VALUES
(1, '00:00', '06:00', 7, 'HIGH', 1),
(1, '02:00', '05:00', 1, 'MEDIUM', 1),
(2, '01:00', '04:00', 7, 'HIGH', 1),
(2, '23:00', '05:00', 0, 'MEDIUM', 1),
(3, '22:00', '06:00', 0, 'CRITICAL', 1),
(3, '22:00', '06:00', 1, 'CRITICAL', 1),
(3, '22:00', '06:00', 2, 'CRITICAL', 1),
(3, '22:00', '06:00', 3, 'CRITICAL', 1),
(3, '22:00', '06:00', 4, 'CRITICAL', 1),
(3, '22:00', '06:00', 5, 'CRITICAL', 1),
(3, '22:00', '06:00', 6, 'CRITICAL', 1);

-- ============================================================
-- RUTAS DE APRENDIZAJE
-- ============================================================
INSERT INTO learning_paths (uuid, user_id, subject_area, status, progress_percent, metadata, started_at, last_activity_at, created_at, updated_at)
VALUES
('c9d0e1f2-a3b4-5678-cdef-789012345678', 1, 'Matemáticas', 'ACTIVE', 35.00, '{"grade":"9°","generated_by":"ai","recommended":true}', DATE_SUB(NOW(), INTERVAL 14 DAY), NOW(), NOW(), NOW()),
('d0e1f2a3-b4c5-6789-defa-890123456789', 1, 'Lenguaje', 'ACTIVE', 12.50, '{"grade":"9°","generated_by":"ai","recommended":true}', DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), NOW(), NOW()),
('e1f2a3b4-c5d6-7890-efab-901234567890', 5, 'Matemáticas', 'ACTIVE', 68.00, '{"grade":"10°","generated_by":"teacher","recommended":false}', DATE_SUB(NOW(), INTERVAL 30 DAY), NOW(), NOW(), NOW());

-- ============================================================
-- ITEMS DE RUTAS
-- ============================================================
INSERT INTO learning_path_items (learning_path_id, content_id, sort_order, status, score, time_spent_seconds, attempts_count, max_attempts, is_mandatory, completed_at)
VALUES
-- Ruta Matemáticas de María (path_id=1)
(1, 1, 1, 'COMPLETED', 85.00, 1800, 1, 3, 1, DATE_SUB(NOW(), INTERVAL 12 DAY)),
(1, 2, 2, 'COMPLETED', 72.00, 1500, 2, 3, 1, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(1, 3, 3, 'IN_PROGRESS', NULL, 900, 1, 3, 1, NULL),
(1, 4, 4, 'PENDING', NULL, 0, 0, 3, 1, NULL),
(1, 5, 5, 'PENDING', NULL, 0, 0, 3, 0, NULL),
-- Ruta Lenguaje de María (path_id=2)
(2, 6, 1, 'COMPLETED', 90.00, 1200, 1, 3, 1, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(2, 7, 2, 'IN_PROGRESS', NULL, 600, 1, 3, 1, NULL),
(2, 8, 3, 'PENDING', NULL, 0, 0, 3, 1, NULL),
-- Ruta Matemáticas de Pedro (path_id=3)
(3, 1, 1, 'COMPLETED', 95.00, 1500, 1, 3, 1, DATE_SUB(NOW(), INTERVAL 25 DAY)),
(3, 2, 2, 'COMPLETED', 88.00, 1400, 1, 3, 1, DATE_SUB(NOW(), INTERVAL 20 DAY)),
(3, 3, 3, 'COMPLETED', 78.00, 2200, 2, 3, 1, DATE_SUB(NOW(), INTERVAL 15 DAY)),
(3, 4, 4, 'COMPLETED', 92.00, 1600, 1, 3, 1, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(3, 5, 5, 'IN_PROGRESS', NULL, 800, 1, 3, 0, NULL);

-- ============================================================
-- PROGRESO DE ESTUDIANTES
-- ============================================================
INSERT INTO student_progress (user_id, content_id, progress_percent, score, time_spent_seconds, interaction_count, last_position, status, is_offline, client_timestamp, synced_at)
VALUES
(1, 1, 100.00, 85.00, 1800, 5, '100%', 'COMPLETED', 0, DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(1, 2, 100.00, 72.00, 1500, 4, '100%', 'COMPLETED', 0, DATE_SUB(NOW(), INTERVAL 10 DAY), NOW()),
(1, 3, 45.00, NULL, 900, 2, '45%', 'IN_PROGRESS', 1, NOW(), NULL),
(1, 6, 100.00, 90.00, 1200, 3, '100%', 'COMPLETED', 0, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
(1, 7, 30.00, NULL, 600, 1, '30%', 'IN_PROGRESS', 1, DATE_SUB(NOW(), INTERVAL 2 DAY), NULL),
(5, 1, 100.00, 95.00, 1500, 6, '100%', 'COMPLETED', 0, DATE_SUB(NOW(), INTERVAL 25 DAY), NOW()),
(5, 2, 100.00, 88.00, 1400, 4, '100%', 'COMPLETED', 0, DATE_SUB(NOW(), INTERVAL 20 DAY), NOW()),
(5, 3, 100.00, 78.00, 2200, 5, '100%', 'COMPLETED', 0, DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),
(5, 4, 100.00, 92.00, 1600, 4, '100%', 'COMPLETED', 0, DATE_SUB(NOW(), INTERVAL 10 DAY), NOW()),
(5, 5, 35.00, NULL, 800, 2, '35%', 'IN_PROGRESS', 0, NOW(), NOW());

-- ============================================================
-- COMPETENCIAS
-- ============================================================
INSERT INTO competencies (code, name, description, subject_area) VALUES
('MATH-NUM', 'Pensamiento Numérico', 'Operaciones básicas con números naturales y fracciones', 'Matemáticas'),
('MATH-GEO', 'Pensamiento Geométrico', 'Figuras geométricas, área y perímetro', 'Matemáticas'),
('MATH-ALG', 'Pensamiento Algebraico', 'Ecuaciones lineales y expresiones algebraicas', 'Matemáticas'),
('LANG-COM', 'Comprensión Lectora', 'Lectura crítica e inferencial de textos', 'Lenguaje'),
('LANG-WRI', 'Producción Escrita', 'Redacción de textos narrativos y argumentativos', 'Lenguaje'),
('LANG-ORA', 'Comunicación Oral', 'Expresión oral y escucha activa', 'Lenguaje'),
('SCI-BIO', 'Biología Básica', 'Ecosistemas, biodiversidad y cuerpo humano', 'Ciencias'),
('SCI-PHY', 'Física Introductoria', 'Movimiento, fuerzas y energía', 'Ciencias');

-- ============================================================
-- COMPETENCIAS DE USUARIO
-- ============================================================
INSERT INTO user_competencies (user_id, competency_id, proficiency_level, last_assessed_at) VALUES
(1, 1, 72.50, DATE_SUB(NOW(), INTERVAL 7 DAY)),
(1, 2, 65.00, DATE_SUB(NOW(), INTERVAL 7 DAY)),
(1, 3, 35.00, DATE_SUB(NOW(), INTERVAL 7 DAY)),
(1, 4, 85.00, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(5, 1, 90.00, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(5, 2, 82.00, DATE_SUB(NOW(), INTERVAL 10 DAY)),
(5, 3, 70.00, DATE_SUB(NOW(), INTERVAL 10 DAY));

-- ============================================================
-- TOKENS OFFLINE
-- ============================================================
INSERT INTO offline_tokens (user_id, token_hash, issued_at, expires_at, is_revoked)
VALUES
(1, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 0),
(5, '$2y$10$ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 0);
