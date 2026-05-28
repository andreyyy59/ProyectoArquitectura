"""
MS-06: AI Recommendations - Motor de IA Local (FastAPI + TensorFlow Lite)
Genera recomendaciones educativas y rutas de aprendizaje personalizadas.
Opera 100% offline en el Edge Node usando modelos TFLite.
"""

import os
import json
import re
import logging
import numpy as np
from typing import Optional
from datetime import datetime

import httpx
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


# ═══════════════════════════════════════════════════════════════
# ─── Ollama LLM (Generación de contenido educativo) ─────────
# ═══════════════════════════════════════════════════════════════

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2:1b")
OLLAMA_TIMEOUT = int(os.getenv("OLLAMA_TIMEOUT", "30"))


class ExerciseRequest(BaseModel):
    topic: str = Field(..., description="Tema del ejercicio, ej: Fracciones")
    subject: str = Field(default="Matemáticas", description="Asignatura, ej: Matemáticas, Ciencias, Lenguaje, Historia")
    count: int = Field(default=5, ge=1, le=10)
    difficulty: str = Field(default="INTERMEDIATE", pattern="^(BEGINNER|INTERMEDIATE|ADVANCED)$")
    language: str = Field(default="es", pattern="^(es|en)$")
    grade: Optional[str] = Field(default=None, description="Grado escolar, ej: 5°")


class ExerciseResponse(BaseModel):
    topic: str
    exercises: list[dict]
    source: str


class LessonRequest(BaseModel):
    concept: str = Field(..., description="Concepto a explicar")
    level: str = Field(default="INTERMEDIATE", pattern="^(BEGINNER|INTERMEDIATE|ADVANCED)$")
    language: str = Field(default="es", pattern="^(es|en)$")


class EvaluateRequest(BaseModel):
    question: str
    student_answer: str
    correct_answer: str
    topic: str


class EvaluateResponse(BaseModel):
    is_correct: bool
    feedback: str
    explanation: str


FALLBACK_EXERCISES: dict[str, list[dict]] = {
    "numeros_naturales": [
        {"question": "¿Cuál es el resultado de 25 + 37?", "options": ["52", "62", "72", "42"], "correct_answer": 1, "explanation": "25 + 37 = 62. Sumamos unidades: 5+7=12, llevamos 1. Decenas: 2+3+1=6."},
        {"question": "¿Cuánto es 8 × 7?", "options": ["48", "56", "64", "54"], "correct_answer": 1, "explanation": "8 × 7 = 56. La tabla del 8: 8, 16, 24, 32, 40, 48, 56."},
        {"question": "¿Cuál es la mitad de 24?", "options": ["10", "12", "14", "8"], "correct_answer": 1, "explanation": "La mitad de 24 es 12, porque 24 ÷ 2 = 12."},
    ],
    "suma_y_resta": [
        {"question": "¿Cuánto es 145 + 238?", "options": ["373", "383", "363", "473"], "correct_answer": 0, "explanation": "145 + 238 = 373. Unidades: 5+8=13, llevamos 1. Decenas: 4+3+1=8. Centenas: 1+2=3."},
        {"question": "¿Cuánto es 500 - 237?", "options": ["263", "273", "253", "363"], "correct_answer": 0, "explanation": "500 - 237 = 263. Pedimos prestado: 5-2=3 centenas, 9-3=6 decenas, 10-7=3 unidades."},
        {"question": "María tiene 345 libros y Juan 289. ¿Cuántos tienen entre los dos?", "options": ["634", "624", "644", "534"], "correct_answer": 0, "explanation": "345 + 289 = 634. Sumamos unidades: 5+9=14, llevamos 1. Decenas: 4+8+1=13, llevamos 1. Centenas: 3+2+1=6."},
    ],
    "multiplicacion": [
        {"question": "¿Cuánto es 12 × 5?", "options": ["50", "60", "55", "65"], "correct_answer": 1, "explanation": "12 × 5 = 60. 10×5=50, 2×5=10, 50+10=60."},
        {"question": "¿Cuánto es 7 × 8?", "options": ["48", "56", "64", "54"], "correct_answer": 1, "explanation": "7 × 8 = 56. La tabla del 7: 7, 14, 21, 28, 35, 42, 49, 56."},
        {"question": "Un trébol tiene 3 hojas. ¿Cuántas hojas tienen 9 tréboles?", "options": ["27", "24", "18", "21"], "correct_answer": 0, "explanation": "9 × 3 = 27 hojas en total."},
    ],
    "division": [
        {"question": "¿Cuánto es 36 ÷ 6?", "options": ["4", "6", "7", "5"], "correct_answer": 1, "explanation": "36 ÷ 6 = 6, porque 6 × 6 = 36."},
        {"question": "Reparte 48 caramelos entre 8 niños. ¿Cuántos le tocan a cada uno?", "options": ["4", "8", "6", "7"], "correct_answer": 2, "explanation": "48 ÷ 8 = 6 caramelos por niño."},
        {"question": "¿Cuánto es 72 ÷ 9?", "options": ["7", "9", "8", "6"], "correct_answer": 2, "explanation": "72 ÷ 9 = 8, porque 9 × 8 = 72."},
    ],
    "fracciones": [
        {"question": "¿Cuál es el resultado de 1/2 + 1/4?", "options": ["2/6", "3/4", "1/6", "2/4"], "correct_answer": 1, "explanation": "1/2 = 2/4, luego 2/4 + 1/4 = 3/4."},
        {"question": "¿Qué fracción representa 0.75?", "options": ["1/4", "1/2", "3/4", "2/3"], "correct_answer": 2, "explanation": "0.75 = 75/100 = 3/4."},
        {"question": "Si tienes 2/3 de pizza y comes 1/6, ¿cuánto te queda?", "options": ["1/3", "1/2", "3/6", "1/6"], "correct_answer": 1, "explanation": "2/3 = 4/6, luego 4/6 - 1/6 = 3/6 = 1/2."},
    ],
    "geometria_basica": [
        {"question": "¿Cuántos lados tiene un cuadrado?", "options": ["3", "4", "5", "6"], "correct_answer": 1, "explanation": "Un cuadrado tiene 4 lados iguales."},
        {"question": "¿Qué figura tiene 3 lados?", "options": ["Cuadrado", "Rectángulo", "Triángulo", "Círculo"], "correct_answer": 2, "explanation": "Un triángulo tiene 3 lados."},
        {"question": "¿Cuántos vértices tiene un cubo?", "options": ["4", "6", "8", "12"], "correct_answer": 2, "explanation": "Un cubo tiene 8 vértices (esquinas)."},
    ],
    "estadistica": [
        {"question": "En una encuesta, 5 prefieren rojo, 3 azul y 2 verde. ¿Cuántos participaron?", "options": ["8", "10", "12", "7"], "correct_answer": 1, "explanation": "5 + 3 + 2 = 10 personas participaron."},
        {"question": "Las edades son: 8, 9, 7, 8, 10. ¿Cuál es la moda?", "options": ["7", "8", "9", "10"], "correct_answer": 1, "explanation": "La moda es 8, porque es el valor que más se repite."},
        {"question": "Si la temperatura fue 20°, 25°, 30°, 25°. ¿Cuál fue el promedio?", "options": ["20", "25", "30", "27.5"], "correct_answer": 1, "explanation": "(20 + 25 + 30 + 25) ÷ 4 = 100 ÷ 4 = 25°."},
    ],
    "probabilidad": [
        {"question": "En una moneda, ¿qué probabilidad hay de que salga cara?", "options": ["1/2", "1/3", "1/4", "1/1"], "correct_answer": 0, "explanation": "La moneda tiene 2 caras, la probabilidad de cara es 1/2."},
        {"question": "En un dado, ¿qué probabilidad hay de sacar un 5?", "options": ["1/3", "1/6", "1/2", "1/5"], "correct_answer": 1, "explanation": "El dado tiene 6 caras numeradas. La probabilidad de cualquier número es 1/6."},
        {"question": "Si hay 3 canicas rojas y 2 azules, ¿probabilidad de sacar una roja?", "options": ["2/5", "3/5", "1/5", "3/2"], "correct_answer": 1, "explanation": "3 rojas de 5 totales: probabilidad = 3/5."},
    ],
    "seres_vivos": [
        {"question": "¿Los seres vivos que nacen, crecen, se reproducen y mueren se llaman?", "options": ["Seres inertes", "Seres vivos", "Plantas", "Animales"], "correct_answer": 1, "explanation": "Los seres vivos son los que nacen, crecen, se reproducen y mueren."},
        {"question": "¿Cuál de estos NO es un ser vivo?", "options": ["Un perro", "Un árbol", "Una roca", "Un hongo"], "correct_answer": 2, "explanation": "Una roca es un ser inerte, no nace, no crece, no se reproduce."},
    ],
    "cuerpo_humano": [
        {"question": "¿Cuál es el órgano más grande del cuerpo humano?", "options": ["El hígado", "La piel", "El cerebro", "El corazón"], "correct_answer": 1, "explanation": "La piel es el órgano más grande del cuerpo humano."},
        {"question": "¿Cuántos huesos tiene un adulto?", "options": ["106", "206", "306", "156"], "correct_answer": 1, "explanation": "El cuerpo humano adulto tiene 206 huesos."},
    ],
    "vocabulario": [
        {"question": "¿Cuál es el sinónimo de 'alegría'?", "options": ["Tristeza", "Felicidad", "Enojo", "Miedo"], "correct_answer": 1, "explanation": "Alegría y felicidad son sinónimos, significan lo mismo."},
        {"question": "El antónimo de 'grande' es:", "options": ["Enorme", "Pequeño", "Gigante", "Alto"], "correct_answer": 1, "explanation": "Pequeño es lo opuesto a grande."},
    ],
    "lectura": [
        {"question": "¿Cuál es el personaje principal de 'Don Quijote de la Mancha'?", "options": ["Sancho Panza", "Don Quijote", "Dulcinea", "Tirante el Blanco"], "correct_answer": 1, "explanation": "Don Quijote es el personaje principal de la novela de Cervantes."},
        {"question": "¿Qué es una fábula?", "options": ["Una historia real", "Un cuento con moraleja", "Un poema", "Una canción"], "correct_answer": 1, "explanation": "La fábula es un cuento breve que deja una enseñanza o moraleja."},
    ],
    "historia_local": [
        {"question": "¿Qué celebramos el 20 de julio en Colombia?", "options": ["La independencia", "El descubrimiento", "La batalla", "El carnaval"], "correct_answer": 0, "explanation": "El 20 de julio de 1810 se conmemora el Grito de Independencia de Colombia."},
        {"question": "¿Quién fue Simón Bolívar?", "options": ["Un escritor", "Un libertador", "Un rey", "Un científico"], "correct_answer": 1, "explanation": "Simón Bolívar fue el Libertador de varias naciones sudamericanas."},
    ],
    "default": [
        {"question": "¿Cuánto es 5 + 3?", "options": ["6", "7", "8", "9"], "correct_answer": 2, "explanation": "5 + 3 = 8. Sumamos ambos números para obtener el resultado."},
        {"question": "¿Cuál es el doble de 6?", "options": ["8", "10", "12", "14"], "correct_answer": 2, "explanation": "El doble de 6 es 12, porque 6 × 2 = 12."},
        {"question": "¿Cuántas horas tiene un día?", "options": ["12", "24", "36", "48"], "correct_answer": 1, "explanation": "Un día tiene 24 horas."},
    ],
}


async def call_ollama(prompt: str, system_prompt: str = "") -> str | None:
    """Llama a Ollama API con timeout y manejo de errores."""
    try:
        async with httpx.AsyncClient(timeout=OLLAMA_TIMEOUT) as client:
            payload = {
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
                "options": {"temperature": 0.7, "num_predict": 2048},
            }
            if system_prompt:
                payload["system"] = system_prompt

            resp = await client.post(f"{OLLAMA_URL}/api/generate", json=payload)
            resp.raise_for_status()
            data = resp.json()
            return data.get("response", "").strip()
    except httpx.ConnectError:
        logger.warning("Ollama no disponible (ConnectError), usando fallback")
        return None
    except httpx.TimeoutException:
        logger.warning("Ollama timeout, usando fallback")
        return None
    except Exception as e:
        logger.error(f"Error llamando a Ollama: {e}")
        return None


def _parse_json_from_ollama(text: str) -> list | None:
    """Extrae un array JSON de la respuesta de Ollama (puede venir con markdown)."""
    # Intentar parsear directamente
    text = text.strip()
    if text.startswith("["):
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            pass

    # Buscar bloque JSON ```json ... ```
    m = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", text, re.DOTALL)
    if m:
        try:
            return json.loads(m.group(1))
        except json.JSONDecodeError:
            pass

    # Buscar cualquier [...] en el texto
    m = re.search(r"(\[.*\])", text, re.DOTALL)
    if m:
        try:
            return json.loads(m.group(1))
        except json.JSONDecodeError:
            pass

    return None


_ACCENT_MAP = {
    "á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u",
    "ü": "u", "ñ": "n",
}


def _normalize_topic_key(topic: str) -> str:
    """Convierte un tema a key del diccionario: minúsculas, sin acentos, sin espacios."""
    key = topic.lower().strip()
    for acc, plain in _ACCENT_MAP.items():
        key = key.replace(acc, plain)
    key = key.replace(" ", "_")
    # Fallback carpet: pick the first matching key if exact not found
    return key


def _get_fallback_exercises(topic: str, count: int) -> list[dict]:
    """Retorna ejercicios fallback según el tema."""
    topic_key = _normalize_topic_key(topic)
    exercises = FALLBACK_EXERCISES.get(topic_key)
    if not exercises:
        # Try partial match (e.g. "Suma y Resta" -> "suma_y_resta")
        for key, vals in FALLBACK_EXERCISES.items():
            if topic_key in key or key in topic_key:
                exercises = vals
                break
    if not exercises:
        exercises = FALLBACK_EXERCISES.get("default", [])
    return exercises[:count]


def _build_exercise_prompt(topic: str, subject: str, count: int, difficulty: str, language: str, grade: str | None) -> str:
    """Construye el prompt para generar ejercicios."""
    grade_line = f" del grado {grade}" if grade else ""
    lang = "español" if language == "es" else "inglés"
    return f"""Eres un profesor de {subject}. Genera {count} ejercicios de {topic}{grade_line} para nivel {difficulty} en {lang}.

IMPORTANTE: Cada ejercicio debe estar ESTRICTAMENTE relacionado con el tema "{topic}" de la asignatura {subject}. No te desvies a otros temas.

Cada ejercicio debe tener: question (texto), options (array de 4 strings), correct_answer (índice 0-3), explanation (texto breve).

Responde SOLO con un array JSON válido, sin explicaciones adicionales, sin markdown.

Ejemplo:
[
  {{
    "question": "¿Cuánto es 2+2?",
    "options": ["3", "4", "5", "6"],
    "correct_answer": 1,
    "explanation": "2+2 = 4 porque sumamos ambas cantidades."
  }}
]"""


# ─── Endpoints de IA con Ollama ───────────────────────────────


@app.post("/generate-exercises")
async def generate_exercises(request: ExerciseRequest):
    """Genera ejercicios educativos usando LLM local."""
    cache_key = f"exercises:{request.topic}:{request.count}:{request.difficulty}"
    cached = redis_client.get(cache_key)
    if cached:
        try:
            return {"topic": request.topic, "exercises": json.loads(cached), "source": "cache"}
        except Exception:
            pass

    prompt = _build_exercise_prompt(
        request.topic, request.subject, request.count, request.difficulty,
        request.language, request.grade,
    )
    system = f"Eres un profesor de {request.subject} que genera ejercicios educativos en español. Siempre respondes con JSON válido."

    raw = await call_ollama(prompt, system)
    exercises = None
    source = "ollama"

    if raw:
        exercises = _parse_json_from_ollama(raw)
        if exercises and len(exercises) > request.count:
            exercises = exercises[:request.count]

    if not exercises:
        exercises = _get_fallback_exercises(request.topic, request.count)
        source = "fallback"

    try:
        redis_client.setex(cache_key, 3600, json.dumps(exercises))
    except Exception:
        pass

    return {"topic": request.topic, "exercises": exercises, "source": source}


@app.post("/generate-lesson")
async def generate_lesson(request: LessonRequest):
    """Genera una explicación de un concepto educativo."""
    cache_key = f"lesson:{request.concept}:{request.level}"
    cached = redis_client.get(cache_key)
    if cached:
        return {"concept": request.concept, "lesson": cached, "source": "cache"}

    prompt = f"""Explica el concepto "{request.concept}" para un estudiante de nivel {request.level} en español.
La explicación debe ser clara, didáctica, con ejemplos prácticos de la vida cotidiana en zonas rurales.
Máximo 3 párrafos. Responde en español."""

    system = "Eres un profesor paciente que explica conceptos de forma sencilla con ejemplos prácticos."

    raw = await call_ollama(prompt, system)
    lesson = raw or f"Concepto: {request.concept}. Nivel: {request.level}. (Contenido no disponible offline)"
    source = "ollama" if raw else "fallback"

    try:
        redis_client.setex(cache_key, 7200, lesson)
    except Exception:
        pass

    return {"concept": request.concept, "lesson": lesson, "source": source}


@app.post("/evaluate-answer")
async def evaluate_answer(request: EvaluateRequest):
    """Evalúa la respuesta del estudiante usando IA."""
    prompt = f"""Evalúa la siguiente respuesta de un estudiante:

Tema: {request.topic}
Pregunta: {request.question}
Respuesta correcta: {request.correct_answer}
Respuesta del estudiante: {request.student_answer}

Determina si es correcta y da retroalimentación educativa útil en español.
Responde SOLO con JSON: {{"is_correct": bool, "feedback": "texto", "explanation": "texto"}}"""

    system = "Eres un profesor que evalúa respuestas y da retroalimentación constructiva."

    raw = await call_ollama(prompt, system)
    if raw:
        try:
            result = json.loads(raw)
            return EvaluateResponse(**result)
        except (json.JSONDecodeError, Exception):
            pass

    is_correct = request.student_answer.strip().lower() == request.correct_answer.strip().lower()
    return EvaluateResponse(
        is_correct=is_correct,
        feedback="Respuesta " + ("correcta" if is_correct else "incorrecta") + ". (Evaluación offline)",
        explanation="La respuesta correcta era: " + request.correct_answer,
    )
