server:
    just tuna-loop &
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
