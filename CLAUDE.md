# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Database**
- `mix ecto.gen.migration <name>` - Generate new migration

**Code Quality**
- `mix ci` - Run full CI pipeline (compile, format check, credo, sobelow, deps audit)

## Architecture Overview

**Core Application Structure**
- **AnyTalker** - Main application context containing business logic
- **AnyTalkerBot** - Telegram bot implementation using ExGram
- **AnyTalkerWeb** - Phoenix web interface with LiveView

**Key Components**

**Telegram Bot (`lib/any_talker_bot/`)**
- `Dispatcher` - Main bot message handler with middleware pipeline
- `AskCommand` - AI chat functionality with rate limiting and validation
- Middleware: antispam, data loading, telemetry, and message processing
- Commands: `/ask` (AI chat), `/privacy` (privacy policy)

**AI Integration (`lib/any_talker/ai/`)**
- `OpenAIClient` - Custom OpenAI API client with proxy support
- `Message` - Message structure for AI conversations
- `Response` - AI response handling and parsing

**Web Interface (`lib/any_talker_web/`)**
- LiveView pages: chat interface, user profiles, admin panel
- Authentication system with Telegram WebApp integration
- Admin functionality for user and global configuration management

**Database Contexts (`lib/any_talker/`)**
- `Accounts` - User management and authentication
- `Settings` - Chat and global configuration
- `Events` - Message and update tracking
- `Antispam` - Captcha and rate limiting

**Key Features**
- Telegram bot with AI chat functionality
- Web dashboard with user profiles and admin panel
- Rate limiting and antispam protection
- Multi-language support with Gettext
- Monitoring with PromEx and telemetry
- Background job processing with Oban

**Important Notes**
- This is an Elixir/Phoenix application, not Node.js
- Uses PostgreSQL database with Ecto ORM
- Telegram bot runs via polling, not webhooks
- AI responses support both text and images
- Web interface uses Telegram WebApp authentication
