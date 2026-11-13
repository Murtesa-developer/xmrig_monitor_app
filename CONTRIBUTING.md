# Contributing

Thanks for helping! This project is maintained by Murtesa Developer.

## Setup

```bash
git clone <your-fork-url> && cd xmrig-monitor
python3 tool/setup.py     # generates android/ ios/ web/ windows/ macos/ linux/ and applies permission patches
flutter pub get
flutter run -d <device>
```

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable).

## Before you open a pull request

```bash
flutter analyze
flutter test
```

- Keep changes focused; one topic per PR.
- Follow the existing structure: `core/` (design system), `data/` (models, services), `state/`
  (controller), `features/` (screens). See `README.md`.
- UI: use the shared widgets and `AppPalette` colours instead of hard-coded colours.
- If you change the Terms or Privacy text in `lib/features/about/legal_pages.dart`, run
  `python3 tool/export_legal.py` to refresh `TERMS.md` and `PRIVACY.md`.
- Add or update tests for parsing and config-building logic.
- **Never commit** wallet addresses, pool passwords, access tokens, keystores or `.env` files, and don't
  paste them into issues.

## Security issues

Do not file them publicly. See `SECURITY.md`.

## License of contributions

By submitting a contribution you agree it is licensed under the project's MIT License.
