# Contributing

Thanks for helping improve kalc.

## Setup

1. Install the project Ruby with `mise install`.
2. Install dependencies with `bin/setup`.
3. Run the test suite with `bundle exec rake spec`.
4. Run the linter with `bundle exec rubocop`.

## Workflow

1. Create a branch for your change.
2. Add or update tests alongside code changes.
3. Keep pull requests focused and explain any user-visible behavior changes.
4. Update the changelog when the change should be called out in a release.

## Development Notes

- `bin/console` starts an IRB session with `Kalc` loaded and a `runner` object ready to use.
- `bin/ikalc` starts the interactive REPL.
- Built-in functions live under `lib/kalc/builtins`.
