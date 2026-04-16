# AGENTS

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
