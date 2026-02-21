<!-- File: README.md | Project memory and conventions -->
# Mail Frowarder Project

This repository contains the OpenClawd skill and helper scripts that forward Gmail messages to Telegram on Raspberry Pi.

## What This Project Does
- Provide a Codex/OpenClawd skill for Gmail -> Telegram forwarding
- Include deployment, OAuth setup, and systemd guidance
- Offer helper scripts for dependency checks and environment verification

## Directory Layout
- `gmail-telegram-forwarder/` Skill source and resources
- `mail-frowarder.code-workspace` VSCode workspace configuration
- `pi_env_check.sh` Local environment check helper

## Runtime Conventions
- Use venv at `~/.openclawd/venv`
- Store runtime data at `~/.openclawd/gmail_to_tg/`
- Store secrets at `~/.openclawd/secrets/`
- Store logs at `~/.openclawd/logs/`

## Project Memory
- Preferred language: Chinese
- Default timezone: Asia/Shanghai
- Default environment: Raspberry Pi OS on Raspberry Pi 5
- Skill root (source): /Users/laibinqiang/Documents/mail-frowarder/gmail-telegram-forwarder
- Skill symlink: /Users/laibinqiang/.codex/skills/gmail-telegram-forwarder
- Telegram format: MarkdownV2
- Quiet hours caching: configurable, default realtime 08:00-24:00, catchup 07:59
- Filtering rules: sender/subject keywords/labels/unread

- Runtime data at `~/.openclawd/gmail_to_tg/`
- Secrets at `~/.openclawd/secrets/`
- Logs at `~/.openclawd/logs/`
- Use Markdown for Telegram messages (MarkdownV2)
## Agent Onboarding
- Read `AGENTS.md`
- Then read `engineering-playbook/conventions/` for team-wide standards

## Team Conventions (Summary)
- Clarity over cleverness; small functions; validate inputs
- Separate config/core/I-O boundaries
- Requirements in user language; small increments; explicit done criteria
- Important directories have README.md; files have header descriptions

## Notes
- Do not store secrets in this repository.