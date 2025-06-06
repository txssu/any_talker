# AnyTalker

## Envs

| Environment | Variable                | Required | Description                                         |
|-------------|-------------------------|----------|-----------------------------------------------------|
| DEV         | `OPENAI_URL`            | No       | URL for OpenAI API                                  |
| DEV         | `OPENAI_KEY`            | Yes      | API key for OpenAI                                  |
| DEV         | `OPENAI_PROXY_URL`      | No       | Used proxy for OpenAI requests                      |
| DEV         | `TELEGRAM_BOT_OWNER_ID` | No       | Telegram Bot Owner ID                               |
| DEV         | `TELEGRAM_BOT_TOKEN`    | Yes      | Token for Telegram Bot                              |
| PROD        | `DATABASE_URL`          | Yes      | Production Database URL                             |
| PROD        | `SECRET_KEY_BASE`       | Yes      | You can generate one by calling: mix phx.gen.secret |
| PROD        | `PHX_HOST`              | Yes      | Domain for webapp                                   |
| PROD        | `METRICS_AUTH_TOKEN`    | No       | Random string                                       |

**Note**: In the development environment, both DEV and PROD variables are accessible.
