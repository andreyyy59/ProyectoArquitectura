<?php

namespace EduConnect\Contracts;

/**
 * Contrato del motor adaptativo (MS-05) para generar
 * rutas de aprendizaje personalizadas basadas en xAPI.
 */
interface AdaptiveEngineContract
{
    /**
     * Genera una ruta de aprendizaje personalizada para un estudiante.
     */
    public function generateLearningPath(int $userId, ?string $subjectArea): array;

    /**
     * Evalúa el progreso del estudiante y ajusta la ruta.
     */
    public function evaluateProgress(int $userId, int $learningPathId): array;

    /**
     * Predice la próxima actividad óptima usando IA local (MS-06).
     */
    public function predictNextActivity(int $userId, int $learningPathId): array;

    /**
     * Procesa eventos xAPI y actualiza el modelo de competencias.
     */
    public function processXapiEvent(array $statement): void;
}
