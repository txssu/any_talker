# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Project Setup**
- `mix setup` - Complete setup: install deps, setup database, build assets
- `mix deps.get` - Install dependencies
- `mix ecto.setup` - Create and migrate database, run seeds
- `mix ecto.reset` - Drop, create, and migrate database

**Development Server**
- `mix phx.server` - Start Phoenix server
- `iex -S mix phx.server` - Start server with interactive Elixir shell

**Database**
- `mix ecto.create` - Create database
- `mix ecto.migrate` - Run migrations
- `mix ecto.gen.migration <name>` - Generate new migration

**Testing**
- `mix test` - Run all tests
- `mix test test/path/to/specific_test.exs` - Run specific test file
- `mix test --cover` - Run tests with coverage

**Code Quality**
- `mix ci` - Run full CI pipeline (compile, format check, credo, sobelow, deps audit)
- `mix format` - Format code
- `mix credo` - Static code analysis
- `mix sobelow` - Security analysis

**Assets**
- `mix assets.build` - Build assets (Tailwind + esbuild)
- `mix assets.deploy` - Build and minify assets for production

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
