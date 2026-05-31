# AGENTS

## Project Positioning

- This repository is a Flutter QA app used to test Easemob/Huanxin IM capabilities end to end.
- It is not a generic business app and should not be optimized as if the main goal were polish, growth, or product storytelling.
- Primary value is test coverage, operability, observability, and fast verification of SDK behavior across flows.
- When in doubt, prefer preserving test reachability, debug visibility, and explicit controls over simplifying the UI.

## What This App Covers

- Single chat feature testing
- Group feature testing
- Chatroom feature testing
- Conversation and contact related testing
- User info / device / push / connection state related testing
- SDK log viewing, in-app debug surfaces, and QA-oriented diagnostics
- Multi-environment server configuration and version check flows
- Mobile and Pad layouts for the same QA scenarios

## Key Entry Points

- App bootstrap: `lib/main.dart`
- Global settings and persisted runtime state: `lib/theme/app_settings.dart`
- App theme colors: `lib/theme/app_colors.dart`
- App version/runtime config: `lib/config/app_config.dart`
- Home shell and SDK event binding: `lib/pages/home_page.dart`
- Mobile QA entry shell: `lib/mobile/page_mobile.dart`
- Pad QA entry shell: `lib/pad/page_pad.dart`
- Server/environment configuration: `lib/common/server_config_page.dart`

## Directory Guide

- `lib/pages/single`
  - Single-chat and contact-related QA pages
- `lib/pages/group`
  - Group capability QA pages
- `lib/pages/chatroom`
  - Chatroom capability QA pages
- `lib/pages/conversation`
  - Conversation list and related verification pages
- `lib/mobile`
  - Mobile-specific shells and secondary pages
- `lib/pad`
  - Pad/tablet-specific shells and layouts
- `lib/common/widgets`
  - Shared QA widgets, dialogs, layouts, log panels, overlays
- `lib/common/utils`
  - Controllers, route observers, log helpers, version manager, counters
- `lib/common/mixins`
  - Shared page logic patterns, including login/SDK init helpers
- `test`
  - Widget tests and focused unit tests; prefer adding targeted tests here

## Architecture Notes For Agents

- `AppSettings` is a singleton `ChangeNotifier` and is the main persisted settings object.
- `VersionManager`, `LogService`, `OfflineMessageCounter`, `ConnectionStatusOverlayController`, and `OtherLoggedInDevicesController` are shared app-level state objects injected near `main.dart`.
- Many pages intentionally expose raw or semi-raw QA controls rather than hiding complexity behind productized UX.
- A number of mobile pages use callback injection for testability. Prefer extending that pattern instead of hard-wiring SDK calls into widget tests.
- Transparent `Scaffold` + shared background is an intentional pattern in this app shell.
- Chatroom message modification is a QA action on message log entries and the menu title is `修改` to match single chat. Text and custom messages use the fixed English body marker `Chatroom edited message`; text, custom, and ext-only editable messages write `qa_chatroom_edit=chatroom_edit_ext_updated`; command messages must not expose the modify action.

## Working Rules For LLM Agents

- Treat this as a QA tool first, UI app second.
- Do not remove logs, debug entry points, explicit action buttons, or environment controls unless explicitly requested.
- Do not collapse multiple testing flows into a single simplified flow just to make the UI cleaner.
- Do not over-abstract QA pages if that makes individual test actions harder to find or harder to verify.
- Keep behavior explicit. QA pages should make actions, state, and failure cases easy to observe.
- Preserve both mobile and Pad behavior when touching shared functionality.
- Follow existing callback-injection patterns when adding SDK-backed features so tests remain easy to write.
- Favor small, local changes over broad refactors.
- If a feature is implemented in both mobile and Pad variants, check whether both sides need updating.
- Do not add client-side fallback data, simulated success records, mock return values, locally fabricated QA results, or synthetic UI replacements in any QA scenario. QA pages should reflect real user input, real SDK callbacks, local SDK message objects, and service-returned data only. If a callback does not arrive, a message is not present locally, a query returns empty, or an operation fails, expose/log that real missing, empty, or failed state instead of inventing replacement UI data.

## Documentation Alignment

- `README.md` is the human-facing project summary.
- `AGENTS.md` is the agent-facing execution guide.
- `case_list.md` is the QA capability and case coverage checklist mapped to the official Easemob/Huanxin IM docs.
- If project positioning, scope, or workflow changes, keep both files aligned instead of updating only one.
- Whenever adding, removing, or completing a QA capability or test case, update `case_list.md` in the same change so its implemented / partially implemented / not implemented status stays aligned with the code.

## Common Code Patterns

- For SDK initialization, check existing helpers in `lib/common/mixins/login_logic_mixin.dart` before adding new init logic.
- For route-level background and overlay behavior, check `lib/main.dart` and `lib/common/widgets/layout/mobile_log_overlay.dart`.
- For log-related UI or file access, reuse existing helpers under `lib/common/utils` and `lib/common/widgets/log_*`.
- For user/device/profile-style pages, prefer injectable callbacks for fetch/save/kick actions to keep widget tests deterministic.
- For connection/device/offline counters, inspect existing controllers before introducing new state holders.

## Testing Expectations

- For behavior changes, prefer adding or updating focused tests under `test/`.
- When changing a specific page, first run the most relevant targeted test file rather than defaulting to the whole suite.
- Recommended verification flow for most changes:
  - `flutter test <relevant test file>`
  - `flutter analyze <changed files>`
- If the change affects shared shells or routing, also run the nearest related widget tests.

## Toolchain Notes

- Project Dart SDK requirement is declared in `pubspec.yaml`.
- If the globally available Flutter or Dart version does not satisfy the project's SDK requirement, use the local project-managed `fvm`/Flutter toolchain for verification and release commands instead of the incompatible global installation.
- Android APK version is sourced from `pubspec.yaml` `version:`. The part before `+` becomes `versionName`, and the part after `+` becomes `versionCode`.
- `fvm flutter build apk --release` uses the `pubspec.yaml` version automatically. Temporary overrides with `--build-name` and `--build-number` are allowed, but release builds should keep `pubspec.yaml`, `changelog.md`, and the Git tag aligned.

## High-Value Safety Notes

- Be careful with persistent settings in `AppSettings`; changes can affect login flow, environment selection, and QA state restoration.
- Be careful with user/device/profile pages that call live SDK APIs; test injection hooks are preferred for coverage.
- Be careful with release/version logic; this repository has explicit release-card parsing requirements.
- Do not silently change release-note section headings or their markdown bullet structure.

## Release Rule

- If a version tag has already been created and pushed, any later code changes must bump the app version before creating a new release tag.
- Release flow for follow-up changes is: update `pubspec.yaml` version, update `changelog.md`, commit, create the matching `v<version>` tag, then push both commit and tag.
- Every release entry in `changelog.md` must use this exact section header format: `## [<version>] - YYYY-MM-DD`. The `<version>` must exactly match `pubspec.yaml` version and the Git tag without the leading `v`, so tag `v1.77.9+217` must match changelog header `## [1.77.9+217] - 2026-04-16`.
- The release date in the changelog header must be the actual release date used when creating that version entry. Do not leave an old date in place when bumping a new release.
- The Android release workflow parses `changelog.md` by matching the current version section and then extracting only `### Feature`, `### UI/UX`, and `### Bug Fix` subsections. These subsection titles are case-sensitive and must be written exactly as shown.
- For release card generation:
  - `### Feature` and `### UI/UX` are merged into the WeCom card's “新增” content.
  - `### Bug Fix` is used for the WeCom card's “修复” content.
- Under `### Feature`, `### UI/UX`, and `### Bug Fix`, every item that should appear in the release card must be written as a first-level Markdown bullet starting with `- `. Do not use plain paragraphs, numbered lists, or only nested bullets for card content.
- If a change should appear in the WeCom release card, place it directly under one of these three subsections. Content under other headings such as `### CI/CD`, `### Refactor`, `### Doc`, or `### Behavior` will not be included in the card summary by the current parser.
- Each release should include at least one of these parsed subsections when applicable, so the release card does not end up showing both “新增: 无” and “修复: 无” by accident.
- If the globally available Flutter or Dart version does not satisfy the project's SDK requirement, use the local project-managed `fvm`/Flutter toolchain for verification and release commands instead of the incompatible global installation.
