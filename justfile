set shell := ["sh", "-eu", "-o", "pipefail", "-c"]

server:
    iex -S mix phx.server

tunnel:
    tuna http 4000 --domain=$PHX_HOST

setup:
    docker compose up -d database
    mix setup
