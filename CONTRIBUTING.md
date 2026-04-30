# Contributing to CashTrack

Thank you for your interest in contributing to CashTrack! 🎉

## How to Contribute

### Reporting Bugs

- Use the [GitHub Issues](https://github.com/ug2102070-blip/CashTrack/issues) page
- Include steps to reproduce the bug
- Include screenshots if applicable
- Specify your device and Flutter version

### Suggesting Features

- Open a [Feature Request](https://github.com/ug2102070-blip/CashTrack/issues/new) issue
- Describe the feature and its use case
- Explain why it would benefit users

### Pull Requests

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a feature branch: `git checkout -b feature/my-feature`
4. **Make** your changes following our code style
5. **Test** your changes: `flutter test`
6. **Commit** with clear messages: `git commit -m "feat: add new feature"`
7. **Push** to your fork: `git push origin feature/my-feature`
8. **Open** a Pull Request against `main`

## Code Style

- Follow the [Dart Style Guide](https://dart.dev/effective-dart/style)
- Use `flutter analyze` to check for issues
- Keep files focused and under 500 lines when possible
- Write meaningful variable and function names
- Add comments for complex logic

## Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Description |
|--------|-------------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation |
| `style:` | Code style (formatting, etc.) |
| `refactor:` | Code refactoring |
| `test:` | Adding tests |
| `chore:` | Maintenance tasks |

## Development Setup

```bash
# Clone the repository
git clone https://github.com/ug2102070-blip/CashTrack.git
cd CashTrack

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Run the app
flutter run
```

## Questions?

Feel free to open an issue or reach out at support@cashtrack.app.

---

Thank you for helping make CashTrack better! 🚀
