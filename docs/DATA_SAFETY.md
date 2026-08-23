# Data safety inventory

This is an engineering inventory, not legal advice. Product/legal review must
confirm it before every store submission.

| Data | Purpose | Storage / sharing | User control |
| --- | --- | --- | --- |
| Financial records, categories, accounts | Tracking, reports, sync | Encrypted local storage; private Firebase documents when cloud sync is used | Edit, delete, export, restore |
| Receipt images | Optional transaction attachment | Private Firebase Storage path when upload is enabled | Delete attachment / transaction |
| Authentication identifier and email | Account login and ownership | Firebase Authentication | Sign out; account-deletion flow required before launch |
| Financial notification text | Optional automatic transaction detection | Processed locally; do not send notification text to telemetry | Disable notification listener at any time |
| AI question plus selected financial summary | Optional AI assistant response | Sent to Groq only after user invokes AI | Do not use AI; delete local data |
| Crash diagnostics | Reliability | Redacted operational error category in Crashlytics | Covered by privacy policy |

Never include raw transaction notes, amounts, receipt content, account numbers,
notification text, API keys, or provider responses in analytics, logs, or crash reports.
