server:
    tuna http 4000 --no-colors --domain=$PHX_HOST > tmp/tuna.log 2>&1 &
    iex -S mix phx.server

setup:
    docker compose up -d database
    mix setup
