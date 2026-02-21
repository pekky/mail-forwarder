# Architecture Conventions

## Boundaries
- Separate configuration, core logic, and adapters (I/O).
- Keep integration code thin; business logic should be testable without I/O.

## Interfaces
- Use stable, explicit interfaces between modules.
- Document assumptions and invariants at module boundaries.

## Configuration
- Store project config in dedicated files; never in source code.
- Keep secrets out of Git; use local env or secret stores.

## Dependencies
- Prefer minimal dependencies; avoid heavy frameworks unless necessary.
- Pin versions for reproducibility.
