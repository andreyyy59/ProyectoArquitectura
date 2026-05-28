-- Seed para educonnect_content
-- Ejecutar: docker exec -i educonnect-mysql-content mysql -uroot -prootsecret educonnect_content < database/seeds/seed_content.sql

USE educonnect_content;

-- ============================================================
-- CATEGORÍAS
-- ============================================================
INSERT INTO content_categories (id, name, slug, description, parent_id, sort_order, is_active) VALUES
(1, 'Matemáticas', 'matematicas', 'Contenidos de matemáticas básica y avanzada', NULL, 1, 1),
(2, 'Aritmética', 'aritmetica', 'Operaciones básicas: suma, resta, multiplicación, división', 1, 1, 1),
(3, 'Geometría', 'geometria', 'Figuras, áreas, perímetros y volúmenes', 1, 2, 1),
(4, 'Álgebra', 'algebra', 'Ecuaciones y expresiones algebraicas', 1, 3, 1),
(5, 'Lenguaje', 'lenguaje', 'Contenidos de lengua y literatura', NULL, 2, 1),
(6, 'Comprensión Lectora', 'comprension-lectora', 'Lectura crítica y análisis de textos', 5, 1, 1),
(7, 'Producción Textual', 'produccion-textual', 'Redacción y escritura creativa', 5, 2, 1),
(8, 'Ciencias', 'ciencias', 'Contenidos de ciencias naturales', NULL, 3, 1);

-- ============================================================
-- CONTENIDOS
-- ============================================================
INSERT INTO contents (id, uuid, title, description, content_type, category_id, difficulty_level, estimated_duration_minutes, file_url, file_size_bytes, file_hash, storage_path, version, is_offline_available, is_published, metadata, published_at, created_at, updated_at)
VALUES
(1, 'f1a2b3c4-d5e6-7890-abcd-ef1234567890', 'Números Naturales', 'Introducción a los números naturales, valor posicional y descomposición', 'VIDEO', 2, 'BEGINNER', 30, '/storage/content/videos/numeros-naturales.mp4', 157286400, 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0', 'content/videos/numeros-naturales.mp4', 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Identificar números naturales","Comprender valor posicional","Descomponer números"]}', NOW(), NOW(), NOW()),
(2, 'f2b3c4d5-e6f7-8901-bcde-f12345678901', 'Suma y Resta', 'Ejercicios interactivos de suma y resta con llevadas', 'INTERACTIVE', 2, 'BEGINNER', 25, '/storage/content/interactive/suma-resta.html', 5120000, 'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1', 'content/interactive/suma-resta.html', 2, 1, 1, '{"author":"Docente Ana","learning_objectives":["Sumar números de 4 cifras","Restar con llevadas","Verificar resultados"]}', NOW(), NOW(), NOW()),
(3, 'f3c4d5e6-f7a8-9012-cdef-123456789012', 'Multiplicación', 'Aprende las tablas de multiplicar y multiplicación por dos cifras', 'EXERCISE', 2, 'INTERMEDIATE', 35, '/storage/content/exercises/multiplicacion.pdf', 2048000, 'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2', 'content/exercises/multiplicacion.pdf', 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Memorizar tablas","Multiplicar por 2 cifras"]}', NOW(), NOW(), NOW()),
(4, 'f4d5e6f7-a8b9-0123-defa-234567890123', 'División', 'División exacta e inexacta, algoritmo de la división', 'VIDEO', 2, 'INTERMEDIATE', 30, '/storage/content/videos/division.mp4', 183500800, 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3', 'content/videos/division.mp4', 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Dividir por 1 cifra","Identificar cociente y residuo"]}', NOW(), NOW(), NOW()),
(5, 'f5e6f7a8-b9c0-1234-efab-345678901234', 'Fracciones', 'Concepto de fracción, fracciones equivalentes, suma de fracciones', 'INTERACTIVE', 2, 'ADVANCED', 40, '/storage/content/interactive/fracciones.html', 6144000, 'e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4', 'content/interactive/fracciones.html', 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Representar fracciones","Sumar fracciones homogéneas"]}', NOW(), NOW(), NOW()),
(6, 'f6a7b8c9-d0e1-2345-fabc-456789012345', 'Lectura Comprensiva', 'Estrategias de lectura: antes, durante y después del texto', 'VIDEO', 6, 'BEGINNER', 20, '/storage/content/videos/lectura-comprensiva.mp4', 104857600, 'f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5', 'content/videos/lectura-comprensiva.mp4', 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Aplicar estrategias pre-lectura","Identificar idea principal"]}', NOW(), NOW(), NOW()),
(7, 'f7a8b9c0-d1e2-3456-fbcd-567890123456', 'El Cuento y sus Partes', 'Estructura del cuento: inicio, nudo y desenlace', 'DOCUMENT', 6, 'BEGINNER', 15, '/storage/content/documents/el-cuento.pdf', 1024000, 'a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6', 'content/documents/el-cuento.pdf', 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Identificar partes del cuento","Crear cuentos cortos"]}', NOW(), NOW(), NOW()),
(8, 'f8a9b0c1-d2e3-4567-fcde-678901234567', 'Gramática Básica', 'Sustantivos, adjetivos, verbos y concordancia', 'QUIZ', 7, 'INTERMEDIATE', 25, NULL, NULL, NULL, NULL, 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Identificar categorías gramaticales","Aplicar concordancia"]}', NOW(), NOW(), NOW()),
(9, 'f9b0c1d2-e3f4-5678-fdef-789012345678', 'Ecosistemas Colombianos', 'Tipos de ecosistemas en Colombia: páramo, selva, manglar', 'VIDEO', 8, 'BEGINNER', 35, '/storage/content/videos/ecosistemas.mp4', 209715200, 'b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7', 'content/videos/ecosistemas.mp4', 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Identificar ecosistemas colombianos","Comprender biodiversidad"]}', NOW(), NOW(), NOW()),
(10, 'f0c1d2e3-f4a5-6789-efab-890123456789', 'El Ciclo del Agua', 'Evaporación, condensación, precipitación y recolección', 'INTERACTIVE', 8, 'BEGINNER', 20, '/storage/content/interactive/ciclo-agua.html', 4096000, 'c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8', 'content/interactive/ciclo-agua.html', 1, 1, 1, '{"author":"Docente Ana","learning_objectives":["Describir ciclo del agua","Identificar estados del agua"]}', NOW(), NOW(), NOW());

-- ============================================================
-- DEPENDENCIAS (prerrequisitos)
-- ============================================================
INSERT INTO content_dependencies (content_id, depends_on_content_id, dependency_type) VALUES
(3, 2, 'PREREQUISITE'),  -- Multiplicación necesita Suma y Resta
(4, 3, 'PREREQUISITE'),  -- División necesita Multiplicación
(5, 4, 'PREREQUISITE'),  -- Fracciones necesita División
(7, 6, 'RECOMMENDED'),   -- El Cuento recomienda Lectura Comprensiva
(8, 6, 'PREREQUISITE'),  -- Gramática necesita Lectura Comprensiva
(9, 10, 'SEQUEL'),       -- Ecosistemas es secuela del Ciclo del Agua
(10, 9, 'RECOMMENDED');  -- Ciclo del Agua recomienda Ecosistemas

-- ============================================================
-- DISTRIBUCIONES A NODOS
-- ============================================================
INSERT INTO content_distributions (content_id, edge_node_id, distribution_status, version_at_distribution, downloaded_at, bytes_transferred)
VALUES
(1, 2, 'COMPLETED', 1, NOW(), 157286400),
(1, 3, 'COMPLETED', 1, NOW(), 157286400),
(2, 2, 'COMPLETED', 2, NOW(), 5120000),
(2, 3, 'COMPLETED', 2, NOW(), 5120000),
(3, 2, 'COMPLETED', 1, NOW(), 2048000),
(3, 3, 'PENDING', 1, NULL, NULL),
(6, 2, 'COMPLETED', 1, NOW(), 104857600),
(6, 3, 'COMPLETED', 1, NOW(), 104857600),
(9, 2, 'IN_PROGRESS', 1, NULL, NULL);
