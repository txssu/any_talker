set shell := ["sh", "-eu", "-o", "pipefail", "-c"]

server:
    #!/usr/bin/env sh
    just tuna-loop &
    TUNA_PID=$!
    cleanup() {
      echo "Shutting down tuna ($$TUNA_PID)..."
      kill "$$TUNA_PID" 2>/dev/null || true
      wait "$$TUNA_PID" 2>/dev/null || true
    }
    trap cleanup EXIT INT TERM
    # основной процесс — когда он завершится, сработает trap
    iex -S mix phx.server

setup:
    docker compose up -d database
    mix setup

tuna-loop:
    #!/usr/bin/env sh
    while true; do
        tuna http 4000 --no-colors --domain=$PHX_HOST > tmp/tuna.log 2>&1
        echo "tuna crashed, restarting..."
        sleep 2
    done
