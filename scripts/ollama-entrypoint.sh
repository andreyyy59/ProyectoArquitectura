#!/bin/sh
# Ollama entrypoint: starts the server, pulls the model, keeps running

# Start Ollama server in background
ollama serve &

# Wait for server to be ready
echo "Waiting for Ollama server..."
until ollama list >/dev/null 2>&1; do
  sleep 2
done
echo "Ollama server is ready."

# Pull the default model if not already present
MODEL="${OLLAMA_MODEL:-llama3.2:1b}"
if ! ollama list 2>/dev/null | grep -q "$MODEL"; then
  echo "Pulling model: $MODEL..."
  ollama pull "$MODEL"
  echo "Model $MODEL pulled successfully."
else
  echo "Model $MODEL already present."
fi

# Keep container running
wait
