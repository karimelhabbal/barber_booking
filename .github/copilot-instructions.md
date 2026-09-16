# barber_booking Project Rules

## Architecture
- Preserve the existing architecture.
- Do not introduce a new architecture.
- Do not migrate between Bloc and Cubit patterns unless explicitly requested.
- Do not refactor unrelated features.

## Flutter
- Preserve existing Flutter and Dart conventions.
- Do not add packages unless explicitly requested.
- Preserve existing routes and navigation behavior unless explicitly requested.

## Firebase
- Preserve the existing FirebaseService initialization flow.
- Do not change Firebase configuration unless explicitly requested.
- Do not modify Firebase rules or configuration as part of unrelated tasks.

## Existing Code
- Treat existing behavior as intentional unless the task explicitly identifies it as a bug.
- Do not remove legacy code merely because it appears unused.
- Do not change localization content unless explicitly requested.

## Feature Work
- Work only within the requested feature and files.
- Preserve public APIs and existing behavior unless the task explicitly requires a change.
- Prefer minimal changes over broad refactoring.

## Project-Specific Rule
- The existing project structure is the baseline.
- Do not move directories or reorganize the project unless explicitly requested.
- Do not rename existing files or classes unless explicitly requested.