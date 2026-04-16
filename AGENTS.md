# AGENTS

## Release Rule

- If a version tag has already been created and pushed, any later code changes must bump the app version before creating a new release tag.
- Release flow for follow-up changes is: update `pubspec.yaml` version, update `changelog.md`, commit, create the matching `v<version>` tag, then push both commit and tag.
