set shell := ["sh", "-eu", "-o", "pipefail", "-c"]

server:
    iex -S mix phx.server

branch name:
    git checkout main
    git pull
    git checkout -b {{name}}

setup:
    docker compose up -d database
    mix setup
