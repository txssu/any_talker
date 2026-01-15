set shell := ["sh", "-eu", "-o", "pipefail", "-c"]

[parallel]
server-tunnel: tunnel server

tunnel:
    tuna tunnel clear
    tuna http 4000 --no-colors --domain=$PHX_HOST > tmp/tuna.log 2>&1

server:
    iex -S mix phx.server

setup:
    docker compose up -d database
    mix setup
