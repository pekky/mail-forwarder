# Claude Code Project Instructions

## Read First
- @README.md

## Purpose
This project contains the OpenClawd skill and helper scripts for forwarding Gmail messages to Telegram on Raspberry Pi.

## Key Paths
- Skill source: `gmail-telegram-forwarder/`
- Skill instructions: `gmail-telegram-forwarder/SKILL.md`
- Scripts: `gmail-telegram-forwarder/scripts/`
- References: `gmail-telegram-forwarder/references/`

## Conventions
- Important directories should have a `README.md`; other directories are optional.
- Project-specific memory lives in `README.md` under **Project Memory**.
- Do not store secrets in this repo.

## Runtime Defaults
- venv: `~/.openclawd/venv`
- data: `~/.openclawd/gmail_to_tg/`
- secrets: `~/.openclawd/secrets/`
- logs: `~/.openclawd/logs/`

## Notes
- Prefer MarkdownV2 for Telegram messages.
- Quiet hours and filtering rules are configurable.
