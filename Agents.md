# Project: Loosening Worry

## Quick Reference
- **Platform**: iOS 27+
- **Language**: Swift 6.4
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with @Observable
- **Minimum Deployment**: iOS 27.0
- **Package Manager**: Swift Package Manager

## Project Generation (XcodeGen)
This project uses XcodeGen. `project.yml` is the source of truth for the Xcode project, Info keys, entitlements, and the shared scheme. Generated files are gitignored — never edit them.

XcodeGen writes `project.pbxproj`, `LooseningWorry/Info.plist`, `LooseningWorry/LooseningWorry.entitlements`, the shared scheme, and the inner workspace stub. The Swift package lockfile under `LooseningWorry.xcodeproj/` stays committed.

- **Add a new file**: place the `.swift` file in the correct directory under `LooseningWorry/` or `LooseningWorryTests/`, then run `xcodegen generate`
- **Regenerate after pulling**: run `xcodegen generate` if the project fails to open or build after a pull that changed `project.yml`
- **Info keys**: put nested or custom keys in `info.properties` (App Transport Security, `RevenueCatAPIKey`, fonts, background modes). Put keys Xcode actually merges from build settings in `INFOPLIST_KEY_*`. Do not put `MARKETING_VERSION` or bundle version in `project.yml` — CI writes `MARKETING_VERSION` into `Configuration/Base.xcconfig`.

## String catalog (`LooseningWorry/Resources/Localizable.xcstrings`)

The app target sets `SWIFT_EMIT_LOC_STRINGS: YES` in `project.yml`. **Do not remove it.** Xcode's
app template sets it; XcodeGen does not. Without it the Swift compiler emits no `.stringsdata`, so
Xcode's catalog sync sees an empty extracted set: it marks every translated key `stale` and adds
no new ones. Stale keys are excluded from *Export Localizations*, so the strings silently never
reach a translator. This is what #278 fixed — 38 live keys flagged stale and 65 more never
recorded at all.

The catalog is stored **as Xcode writes it** — Xcode's own key order, and **no trailing newline**.

Xcode and `xcstringstool` disagree about collation. The tool sorts keys by byte value, which puts
the uppercase `Text` literals in one block ahead of the dotted keys; Xcode sorts case-insensitively
with punctuation-only keys first, interleaving the two groups. Neither form survives the other
writer, so whichever ran last leaves the file dirty against the other. We store Xcode's form because IDE builds happen all day and the hand-sync is rare.

So: **a reorder-only diff on this file is expected, not a bug.** Review it by key set and values,
never by line order. On top of reordering, an IDE build also prunes empty entries whose literal is
no longer in source, and drops `extractionState` from entries whose stored value it cannot match
against the extracted one — which includes every hand-authored plural (see below). Neither is a
regression; `LocalizationCatalogTests` is the thing that decides.

Plural entries are written by hand. The source declares one `String(localized:key, defaultValue:)`
carrying a `%lld`, and the catalog entry holds `variations.plural` with `one` and `other`;
`String.localizedStringWithFormat` resolves the category at runtime.

The pre-commit hook keeps the stored form honest: when the catalog is staged it runs
`Scripts/normalize-string-catalog.swift`, which reorders entries into Xcode's collation and
re-stages the file. The script moves entries as raw text rather than re-serialising them, so
everything inside an entry survives byte for byte, and it refuses to write if the reorder would
change the parsed contents. Either writer can therefore touch the catalog and the commit still
shows only what actually changed. Install the hook once per clone with
`./Scripts/install-git-hooks.sh` — without it, a `xcstringstool sync` lands as a whole-file reorder.

Xcode rewrites the catalog on IDE builds only; `xcodebuild` from the CLI never does — which is why
a CLI-only session can add keys and leave the file in whatever form it was already in. To refresh
it by hand after adding or removing localized strings (this writes the tool's collation; the hook
puts it back on commit):

```bash
xcodebuild -project LooseningWorry.xcodeproj -scheme LooseningWorry \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath /tmp/dd build

args=()
while IFS= read -r f; do args+=(--stringsdata "$f"); done \
  < <(find /tmp/dd/Build/Intermediates.noindex/LooseningWorry.build -name '*.stringsdata')
xcstringstool sync LooseningWorry/Resources/Localizable.xcstrings "${args[@]}"
```

The file you pass to `sync` must be *named* `Localizable.xcstrings` — the tool matches stringsdata
tables by filename and silently syncs nothing against a differently-named copy.

`LocalizationCatalogTests` fails if a key referenced in source is marked stale, if a key referenced in
source is missing from the catalog, or if the trailing newline comes back. "Referenced in source" means
every key the compiler extracted into the `Localizable` table — `Text("…")`, `String(localized:)` and the
rest — read from the app target's `.stringsdata`. The test scheme passes their location in
`LOCALIZATION_STRINGSDATA_DIR` (set in `project.yml`); files whose source has since been deleted are
skipped. If the build extracted no `Localizable` keys the two key checks fail rather than pass on an empty
set. A separate test fails if `project.yml` stops setting `SWIFT_EMIT_LOC_STRINGS: YES`, which an
incremental build would otherwise hide behind the previous build's `.stringsdata`.

## XcodeBuildMCP Integration
**IMPORTANT**: This project uses XcodeBuildMCP for all Xcode operations.
- Build: `mcp__xcodebuildmcp__build_sim_name_proj`
- Test: `mcp__xcodebuildmcp__test_sim_name_proj`
- Clean: `mcp__xcodebuildmcp__clean`

**Always pass `-collect-test-diagnostics never` when running tests** — as an extra argument to the
XcodeBuildMCP test tool, or directly on `xcodebuild test`. By default `xcodebuild` collects simulator
diagnostics (`simctl diagnose`) whenever a test fails, and with Xcode 27.1 that step intermittently stalls
until its 600-second timeout, so a failing run takes ten minutes to report. Passing runs are unaffected.

## Project Structure

```
MyApp/
├── App/                    # App entry point, App delegate
├── Features/               # Feature modules
│   ├── [FeatureName]/
│   │   ├── Views/          # SwiftUI views
│   │   ├── ViewModels/     # @Observable classes
│   │   └── Models/         # Data models
├── Core/                   # Shared utilities
│   ├── Extensions/
│   ├── Services/
│   └── Networking/
├── Resources/              # Assets, Localizations
└── Tests/
```

## Testing Requirements
- Compprehensive unit tests for all ViewModels
- Use Swift Testing framework (`@Test`, `#expect`)
- No UI tests, and none are to be added — there is no UI test target and `NoUITestsTests` fails if one appears
- Minimum 90% code coverage for business logic
- Prevent SourceKit from misresolving the SwiftData Job model as a Swift Concurrency Job

## Code Style (SwiftFormat + SwiftLint)

Install via Homebrew: `brew install swiftformat swiftlint`

Config: `.swiftformat` and `.swiftlint.yml` at the repo root. Applies to `LooseningWorry/` and `LooseningWorryTests/`.

**Before committing Swift changes**, format then lint:

```bash
swiftformat LooseningWorry LooseningWorryTests
swiftlint
```

Useful variants:

- Check formatting without writing: `swiftformat LooseningWorry LooseningWorryTests --lint` (the `--lint` flag must follow the paths)
- SwiftLint auto-fix (safe fixes only): `swiftlint --fix`
- Fail on warnings: `swiftlint --strict` (also enabled in `.swiftlint.yml`)

**Git pre-commit hook** (normalizes the string catalog when it is staged; formats and lints staged `.swift`
files under `LooseningWorry/` and `LooseningWorryTests/`, skipping those steps when none are staged):

```bash
./Scripts/install-git-hooks.sh   # once per clone
```

See `README.md` for full usage details.

## Git Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) for **all** git commits in this repo.

Format:

```
type(optional-scope): short imperative summary
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore`.

Examples:

```
feat(onboarding): add language selection screen
fix(audio): resume playback after interruption
chore: update SwiftLint configuration
```

## Agent skills

### Issue tracker

Issues live in GitHub Issues for this repo (use the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Domain docs

Single-context layout: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
