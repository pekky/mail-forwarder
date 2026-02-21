# Coding Conventions

## Principles
- Prefer clarity over cleverness; optimize for readability.
- Keep functions small and single-purpose.
- Validate inputs at boundaries; fail fast with clear errors.
- Keep side effects at the edges (I/O, network, filesystem).

## Error Handling
- Return actionable error messages with context.
- Avoid swallowing exceptions; log and rethrow when appropriate.

## Testing
- Write tests for core logic and known regressions.
- Add smoke tests for critical workflows.

## Observability
- Log key milestones with structured fields where possible.
- Avoid logging secrets or personal data.
