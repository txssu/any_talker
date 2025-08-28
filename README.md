# AnyTalker

A Telegram bot initially developed for a specific chat. It can emulate characters using AI models (OpenAI) and includes basic anti-spam protection. While originally chat-specific, it can now be used in multiple chats — access control is managed solely by the owner. The bot runs at [@AnyTalkerBot](https://t.me/AnyTalkerBot).

## Envs

| Environment | Variable                | Required | Description                                         |
|-------------|-------------------------|----------|-----------------------------------------------------|
| DEV         | `OPENAI_URL`            | No       | URL for OpenAI API                                  |
| DEV         | `OPENAI_KEY`            | Yes      | API key for OpenAI                                  |
| DEV         | `OPENAI_PROXY_URL`      | No       | Used proxy for OpenAI client                        |
| DEV         | `TELEGRAM_BOT_OWNER_ID` | No       | Telegram Bot Owner ID                               |
| DEV         | `TELEGRAM_BOT_TOKEN`    | Yes      | Token for Telegram Bot                              |
| PROD        | `DATABASE_URL`          | Yes      | Production Database URL                             |
| PROD        | `SECRET_KEY_BASE`       | Yes      | You can generate one by calling: mix phx.gen.secret |
| PROD        | `PHX_HOST`              | Yes      | Domain for webapp                                   |
| PROD        | `METRICS_AUTH_TOKEN`    | No       | Random string                                       |

**Note**: In the development environment, both DEV and PROD variables are accessible.
