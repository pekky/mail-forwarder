# Pub/Sub Pull + History Handling

## Core Loop

- Pull messages from the subscription (short interval, small batch).
- Decode the Pub/Sub payload to read `historyId` and `emailAddress`.
- Call `users.history.list` with `startHistoryId` = last stored history id.
- For each history record, fetch messages via `users.messages.get`.
- Apply rule matching and deliver or cache.
- Ack Pub/Sub messages only after successful processing.

## History Expiration

If Gmail returns a 404 with "HistoryId too old":

1. Re-sync by listing recent messages (e.g., `users.messages.list` for `INBOX`).
2. Set `last_history_id` to the newest message's history id.
3. Continue normal pull loop.

## Idempotency

- Keep a local table of recent message ids to avoid duplicates.
- Only advance `last_history_id` after processing is complete.
