# AnyTalker Agent Principles

## General Principles

- Prioritize the **simplest solution**. If code feels complex, step back. Ask: “Is this the simplest, clearest way?” Repeat until simplicity is achieved.
- For design decisions, follow principles used by companies like **Apple, Linear, Vercel**. Prioritize clean, intuitive UX.
- Default to **Phoenix/LiveView solutions**. Only use JavaScript when unavoidable, and implement it via `phx-hook`.
- Replace `@impl true` with **`@impl ModuleName`**.
- Use the **new HEEX syntax** `{@variable}` instead of `<%= @variable %>`.
- Prefer `:if` inside elements instead of wrapping them with conditional divs.
- Use **Verified Routes** (`~p"/path"`) instead of `Routes.page_path/2`.
- Before suggesting code, aggressively simplify it using pattern matching, guards, and helper functions.
- Make functions short and avoid nested blocks. If a function is long, break it into smaller functions.
- Always write tests for any added or changed functionality.
- Use **pipe-based query syntax** for clarity and composability.
- Use **Elixir’s set-theoretic types** through structs. You don't need to add `@spec`.
- Name unused variables (e.g., `_error`), don’t leave as `_`.
- Favor **pattern matching** over `case` or `cond`.

## File and Code Structure

### Configuration

- Store global configs in `lib/any_talker/config/`.
- Prefix modules with `AnyTalker.Config.*` (e.g., `AnyTalker.Config.LanguageConfig`).

### Schemas

- Use context-prefixed names (e.g., `AnyTalker.Accounts.User`).
- Add a `@moduledoc` with a **field table** for schemas: Field Name | Type | Description.
- Use `List` instead of `Array` for types.
- Always include `timestamps(type: :utc_datetime_usec)`.
- Default `array` fields to `[]`.
- Generate migrations alongside schema changes using `mix ecto.gen.migration`.

### Controllers

- Located in `lib/any_talker_web/controllers/`.
- Use `use AnyTalkerWeb, :controller`.
- Add `@moduledoc` for the controller and `@doc` for each action.
- File and module names should match.

### LiveView Pages

- Located in `lib/any_talker_web/live/`.
- Use `@moduledoc false`.
- Place `render` callback **at the top** of the module.
- Use `use AnyTalkerWeb, :live_view`.

### Components

- Shared components: `lib/any_talker_web/components/`.
- Import them via `html_helpers` in `any_talker_web.ex`.
- Use `Phoenix.Component.attr/3` for attributes.
- Write `@moduledoc` and `@doc` with usage examples.
- Add previews in `lib/any_talker_dev/ui_preview/` and register routes for them.
- Use `<.text>` for any textual content, never raw tags.
- Render slots with `{render_slot(@inner_block)}` only.
- When styling, pass classes to the component (`<.card_content class="...">`), not through extra divs.

### CSS

- Use **Tailwind CSS v4**.
- Never use default Tailwind colors. Use tokens like `bg-zk-surface`.
- Create reusable utilities in `app.css` with `zk-` prefix.
- Use `size-` for equal width/height (`size-4` instead of `w-4 h-4`).

### Icons

- Use **Tabler icons** via `<.icon name="tabler-icon-name" />`.

### API

- Use `AnyTalkerWeb.API.ErrorResponse` for error formatting.
- Add missing error formats if needed.

## Documentation Standards

- Clear, concise, objective.
- Avoid vague terms (“secure,” “best practice”); describe exact behavior.
- Use `@moduledoc` for module overviews and `@doc` for functions.
- Always include usage examples in `@doc`.
- Don’t prefix examples with `elixir`.
- Group multiple `on_mount` docs into a **single `@doc` block**.

## Testing

- Mirror controller/module names with `_test` suffix.
- Use `AnyTalkerWeb.ConnCase` for web, `AnyTalker.DataCase` for data.
- Create fixtures in `test/support/fixtures/`.
- Avoid setup blocks for fixtures; call them explicitly.
- Use the **PhoenixTest** library for testing.
- Use `Phoenix.Flash.get/2` instead of deprecated `get_flash/2`.
- Never expose private functions for testing.
- Always run `mix test` and `mix ci` before stop.

<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below. 
Before attempting to use any of these packages or to discover if you should use them, review their 
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- claude-start -->
## claude usage
_Batteries-included Claude Code integration for Elixir projects_

[claude usage rules](deps/claude/usage-rules.md)
<!-- claude-end -->
<!-- claude:subagents-start -->
## claude:subagents usage
[claude:subagents usage rules](deps/claude/usage-rules/subagents.md)
<!-- claude:subagents-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

[usage_rules usage rules](deps/usage_rules/usage-rules.md)
<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
[usage_rules:elixir usage rules](deps/usage_rules/usage-rules/elixir.md)
<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
[usage_rules:otp usage rules](deps/usage_rules/usage-rules/otp.md)
<!-- usage_rules:otp-end -->
<!-- usage-rules-end -->
