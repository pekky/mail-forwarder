# Gmail OAuth and Watch Setup

1. Create a Google Cloud project and enable the Gmail API.
2. Configure OAuth consent screen (External or Internal).
3. Create OAuth client credentials (Desktop app recommended for Pi setup).
4. Download `credentials.json` to the Pi and store securely.
5. Run a one-time auth flow to generate `token.json`.
   - Scopes: `https://www.googleapis.com/auth/gmail.readonly`
   - If marking as read or labeling: use `https://www.googleapis.com/auth/gmail.modify`
6. Create a Pub/Sub topic and subscription in the same project.
7. Grant publish permission to Gmail push service account:
   - `gmail-api-push@system.gserviceaccount.com`
   - Role: `Pub/Sub Publisher` on the topic
8. Call `users.watch` with:
   - `topicName` set to the Pub/Sub topic
   - `labelIds` set to watched labels (e.g., `INBOX`)
9. Persist the returned `historyId` for later polling.
