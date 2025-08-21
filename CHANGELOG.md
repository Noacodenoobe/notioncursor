# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- Add: Architecture file `ARCHITECTURE.md` with high-level design and policies.
- Add: Non-destructive change policy and documentation cadence.
- Add: AI Bridge service (FastAPI) scaffold with endpoints plan.
- Add: Docker Compose wrapper script `scripts/compose.sh`.
- Add: Git helper scripts `scripts/commit.sh`, `scripts/push.sh`.
- Change: Prepare version pinning via `.env` and `docker-compose.yml`.
- Change: Health and checks scripts to include AI Bridge.
- Fix: Prepare `pull_models.sh` to support embedding model and robust parsing.
