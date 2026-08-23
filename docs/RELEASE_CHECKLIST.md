# CashTrack release checklist

## Security and privacy

- [ ] Rotate all provider keys; verify no secret is present in the Git diff or app binary.
- [ ] Deploy Functions, Firestore, and Storage rules.
- [ ] Confirm Firebase App Check enforcement and metrics for Android, iOS, web, Functions, Firestore, and Storage.
- [ ] Verify data deletion, account deletion, and backup/restore on a test account.
- [ ] Review Play Data safety and App Store privacy disclosures against `DATA_SAFETY.md`.

## Quality gates

- [ ] `dart format --output=none lib test`
- [ ] `flutter analyze --no-fatal-warnings --no-fatal-infos`
- [ ] `flutter test`
- [ ] `cd functions; npm run lint; npm run audit`
- [ ] Build and install signed Android app bundle on a physical device.
- [ ] Test first-run, upgrade migration, offline edit, conflict resolution, deletion propagation, export, and permission denial.

## Accessibility and localization

- [ ] Test TalkBack and VoiceOver: navigation, dashboard totals, charts, forms, dialogs, and destructive actions.
- [ ] Test 200% text scaling and minimum 320dp width.
- [ ] Test Bengali and English with dates, currency, truncation, and screen-reader labels.
- [ ] Verify color contrast and that color is never the only status indicator.
