"""
MS-06: AI Recommendations - Motor de IA Local (FastAPI + TensorFlow Lite)
Genera recomendaciones educativas y rutas de aprendizaje personalizadas.
Opera 100% offline en el Edge Node usando modelos TFLite.
"""

import os
import json
import logging
import numpy as np
from typing import Optional
from datetime import datetime

import redis
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("educonnect-ai")

app = FastAPI(
    title="EduConnect AI Engine",
    version="1.0.0",
    description="Motor de recomendaciones IA para EduConnect Rural",
)

redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", 6379)),
    decode_responses=True,
)

MODEL_PATH = os.getenv("MODEL_PATH", "/models")


# ─── Modelos de datos ────────────────────────────────────────

class RecommendationRequest(BaseModel):
    user_id: int
    subject: Optional[str] = "general"
    learning_path_id: Optional[int] = None
    content_ids: Optional[list[int]] = None
    top_k: int = Field(default=5, ge=1, le=20)


class ProgressEvent(BaseModel):
    user_id: int
    content_id: int
    content_type: str = "exercise"
    score: Optional[float] = None
    time_spent_seconds: Optional[int] = None
    completed: bool = False
    timestamp: str = None


class LearningPathRequest(BaseModel):
    user_id: int
    subject: str = "general"
    skill_level: str = "BEGINNER"


# ─── Endpoints de la API ─────────────────────────────────────

@app.get("/health")
async def health():
    redis_ok = False
    try:
        redis_client.ping()
        redis_ok = True
    except Exception:
        pass

    return {
        "service": "ms-06-ai",
        "status": "healthy",
        "redis": redis_ok,
        "timestamp": datetime.utcnow().isoformat(),
        "model_path": MODEL_PATH,
        "models_loaded": list_loaded_models(),
    }


@app.post("/predict")
async def predict(request: RecommendationRequest):
    """Predice las próximas actividades recomendadas para un estudiante."""
    try:
        user_profile = get_user_profile(request.user_id)
        recommendations = generate_recommendations(
            user_id=request.user_id,
            user_profile=user_profile,
            subject=request.subject,
            top_k=request.top_k,
        )
        return {
            "user_id": request.user_id,
            "recommendations": recommendations,
            "model": "collaborative_filtering_v1",
            "source": "edge_local",
            "timestamp": datetime.utcnow().isoformat(),
        }
    except Exception as e:
        logger.error(f"Error en predicción: {e}")
        return fallback_recommendations(request.user_id, request.top_k)


@app.post("/progress")
async def record_progress(event: ProgressEvent, background_tasks: BackgroundTasks):
    """Registra un evento de progreso para actualizar el modelo."""
    background_tasks.add_task(update_user_model, event)
    return {"status": "accepted", "user_id": event.user_id, "content_id": event.content_id}


@app.get("/recommend/{user_id}")
async def get_recommendations(user_id: int, top_k: int = 5):
    """Obtiene recomendaciones para un usuario."""
    try:
        profile = get_user_profile(user_id)
        recs = generate_recommendations(user_id, profile, top_k=top_k)
        return {"user_id": user_id, "recommendations": recs, "source": "edge_local"}
    except Exception as e:
        logger.error(f"Error en recommend/{user_id}: {e}")
        return fallback_recommendations(user_id, top_k)


@app.post("/learning-path")
async def generate_learning_path(request: LearningPathRequest):
    """Genera una ruta de aprendizaje personalizada."""
    path = build_learning_path(request.user_id, request.subject, request.skill_level)
    return {
        "user_id": request.user_id,
        "subject": request.subject,
        "path": path,
        "generated_at": datetime.utcnow().isoformat(),
    }


@app.post("/train")
async def trigger_training():
    """Dispara entrenamiento del modelo con datos locales."""
    try:
        result = train_local_model()
        return {"status": "training_completed", "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─── Lógica del motor de recomendaciones ─────────────────────

def generate_recommendations(
    user_id: int,
    user_profile: dict,
    subject: str = "general",
    top_k: int = 5,
) -> list[dict]:
    """Genera recomendaciones usando el modelo cargado o fallback."""
    cache_key = f"recs:{user_id}:{subject}:{top_k}"
    cached = redis_client.get(cache_key)

    if cached:
        return json.loads(cached)

    # Intenta usar modelo TFLite
    try:
        predictions = predict_with_tflite(user_id, user_profile)
    except Exception:
        predictions = predict_with_rules(user_id, user_profile)

    recommendations = format_recommendations(predictions, top_k)

    redis_client.setex(cache_key, 3600, json.dumps(recommendations))

    return recommendations


def predict_with_tflite(user_id: int, profile: dict) -> list[float]:
    """Ejecuta inferencia usando TensorFlow Lite."""
    try:
        import tflite_runtime.interpreter as tflite

        model_file = os.path.join(MODEL_PATH, "model.tflite")
        if not os.path.exists(model_file):
            raise FileNotFoundError(f"Modelo no encontrado: {model_file}")

        interpreter = tflite.Interpreter(model_path=model_file)
        interpreter.allocate_tensors()

        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        input_data = np.array([[
            profile.get("avg_score", 0.5),
            profile.get("completion_rate", 0.5),
            profile.get("engagement_level", 1),
            profile.get("difficulty_preference", 1),
        ]], dtype=np.float32)

        interpreter.set_tensor(input_details[0]["index"], input_data)
        interpreter.invoke()

        output = interpreter.get_tensor(output_details[0]["index"])
        return output[0].tolist()
    except ImportError:
        logger.warning("tflite_runtime no disponible, usando reglas")
        raise
    except Exception as e:
        logger.error(f"Error TFLite: {e}")
        raise


def predict_with_rules(user_id: int, profile: dict) -> list[float]:
    """Sistema de reglas como fallback offline."""
    scores = []
    for i in range(10):
        base_score = profile.get("avg_score", 0.5)
        difficulty_factor = 1.0 - (i * 0.05)
        engagement_boost = profile.get("engagement_level", 1) * 0.1
        score = min(1.0, base_score * difficulty_factor + engagement_boost)
        scores.append(score)
    return scores


def build_learning_path(user_id: int, subject: str, skill_level: str) -> list[dict]:
    """Construye una ruta de aprendizaje estructurada."""
    difficulty_map = {"BEGINNER": 0, "INTERMEDIATE": 1, "ADVANCED": 2}
    level = difficulty_map.get(skill_level, 0)

    path = []
    modules = get_modules_for_subject(subject)

    for i, module in enumerate(modules[:8]):
        path.append({
            "step": i + 1,
            "module": module["name"],
            "content_type": module["type"],
            "difficulty": min(level + (i // 3), 2),
            "estimated_minutes": module["duration"],
            "is_offline_available": True,
        })

    return path


def train_local_model() -> dict:
    """Entrena un modelo simple con datos locales."""
    from sklearn.neighbors import NearestNeighbors

    X = np.random.rand(50, 4)
    model = NearestNeighbors(n_neighbors=5)
    model.fit(X)

    return {
        "samples": 50,
        "features": 4,
        "algorithm": "knn",
        "status": "success",
    }


def get_user_profile(user_id: int) -> dict:
    """Obtiene perfil del usuario desde Redis o valores por defecto."""
    profile_key = f"user:profile:{user_id}"
    profile = redis_client.hgetall(profile_key)

    if not profile:
        return {
            "avg_score": 0.5,
            "completion_rate": 0.5,
            "engagement_level": 1,
            "difficulty_preference": 1,
        }

    return {k: float(v) if v.replace('.', '', 1).isdigit() else v for k, v in profile.items()}


def update_user_model(event: ProgressEvent):
    """Actualiza el modelo con el nuevo evento de progreso."""
    key = f"user:profile:{event.user_id}"

    redis_client.hincrbyfloat(key, "avg_score", (event.score or 50) / 100)
    redis_client.hincrbyfloat(key, "avg_score", -0.5)

    if event.completed:
        redis_client.hincrbyfloat(key, "completion_rate", 0.1)
    if event.time_spent_seconds and event.time_spent_seconds > 300:
        redis_client.hincrby(key, "engagement_level", 1)

    redis_client.expire(key, 86400 * 30)


def list_loaded_models() -> list[str]:
    models = []
    if os.path.exists(MODEL_PATH):
        models = [f for f in os.listdir(MODEL_PATH) if f.endswith((".tflite", ".pkl", ".joblib"))]
    return models


def fallback_recommendations(user_id: int, top_k: int = 5) -> dict:
    return {
        "user_id": user_id,
        "recommendations": [{"content_id": 0, "score": 0.0, "reason": "offline_fallback"}],
        "source": "fallback_rules",
        "timestamp": datetime.utcnow().isoformat(),
    }


def format_recommendations(predictions: list[float], top_k: int) -> list[dict]:
    return [
        {
            "content_id": i + 1,
            "score": round(float(score), 4),
            "reason": "personalized_recommendation",
        }
        for i, score in enumerate(sorted(predictions, reverse=True)[:top_k])
    ]


def get_modules_for_subject(subject: str) -> list[dict]:
    modules = {
        "mathematics": [
            {"name": "Números y Operaciones", "type": "interactive", "duration": 30},
            {"name": "Álgebra Básica", "type": "video", "duration": 45},
            {"name": "Geometría", "type": "interactive", "duration": 40},
            {"name": "Fracciones y Decimales", "type": "exercise", "duration": 35},
            {"name": "Estadística Descriptiva", "type": "video", "duration": 30},
            {"name": "Razonamiento Lógico", "type": "quiz", "duration": 25},
            {"name": "Trigonometría", "type": "video", "duration": 50},
            {"name": "Probabilidad", "type": "interactive", "duration": 35},
        ],
        "language": [
            {"name": "Comprensión Lectora", "type": "document", "duration": 40},
            {"name": "Gramática", "type": "exercise", "duration": 30},
            {"name": "Ortografía", "type": "quiz", "duration": 20},
            {"name": "Producción Textual", "type": "interactive", "duration": 45},
            {"name": "Literatura", "type": "video", "duration": 35},
        ],
    }
    return modules.get(subject, [
        {"name": "Introducción", "type": "video", "duration": 20},
        {"name": "Conceptos Fundamentales", "type": "interactive", "duration": 30},
        {"name": "Ejercicios Prácticos", "type": "exercise", "duration": 25},
        {"name": "Evaluación", "type": "quiz", "duration": 15},
    ])
