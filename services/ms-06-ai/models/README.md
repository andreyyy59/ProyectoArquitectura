# Modelos TFLite para EduConnect AI

Coloca aquí tus modelos TensorFlow Lite (.tflite) para el motor de recomendaciones.

## Formato esperado

- `model.tflite` — Modelo principal de recomendación de contenidos
- Input: `[avg_score, completion_rate, engagement_level, difficulty_preference]`
- Output: `[score_1, score_2, ..., score_n]`

Los modelos serán cargados automáticamente por `main.py` en el directorio `/models`.
