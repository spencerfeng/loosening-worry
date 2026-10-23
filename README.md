# Loosening Worry

An iOS app for noticing worry loops and loosening them with short guided tools. Domain language lives in
`CONTEXT.md`; design decisions in `docs/adr/`.

## Requirements

- Xcode 27 with the iOS 27 SDK
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), SwiftFormat and SwiftLint:

```bash
brew install xcodegen swiftformat swiftlint
```

## Getting started

The Xcode project is generated from `project.yml` and is not committed, apart from the Swift package
lockfile (`Package.resolved`) inside it. After cloning, and after any pull that changes `project.yml`:

```bash
xcodegen generate
open LooseningWorry.xcodeproj
```

Then install the git hook once per clone:

```bash
./Scripts/install-git-hooks.sh
```

## Running tests

```bash
xcodebuild test -project LooseningWorry.xcodeproj -scheme LooseningWorry \
  -destination 'platform=iOS Simulator,name=iPhone Duo' -collect-test-diagnostics never
```

Keep `-collect-test-diagnostics never`. Without it, a failing run makes `xcodebuild` collect simulator
diagnostics, which with Xcode 27.1 often stalls for up to ten minutes before the result appears.

## Code style

SwiftFormat and SwiftLint are configured by `.swiftformat` and `.swiftlint.yml` at the repo root, and
cover `LooseningWorry/` and `LooseningWorryTests/`. Format, then lint:

```bash
swiftformat LooseningWorry LooseningWorryTests
swiftlint
```

- Check formatting without writing: `swiftformat LooseningWorry LooseningWorryTests --lint` (the `--lint`
  flag must follow the paths)
- Apply SwiftLint's safe auto-fixes: `swiftlint --fix`
- SwiftLint runs in strict mode, so warnings fail too

## Git pre-commit hook

The pre-commit hook formats and lints **staged `.swift` files** under `LooseningWorry/` and
`LooseningWorryTests/`, and normalizes the string catalog when it is staged. Commits that touch neither
are not affected. `./Scripts/install-git-hooks.sh` installs it by pointing `core.hooksPath` at
`Scripts/git-hooks`, so later changes to the hook apply without reinstalling.

On each commit the hook will:

1. Reorder `Localizable.xcstrings` into Xcode's collation, if it is staged, and re-stage it
2. Run SwiftFormat on staged Swift files
3. Re-stage the formatted files
4. Run SwiftLint in strict mode
5. Block the commit if lint fails

Step 1 exists because Xcode and `xcstringstool` sort the catalog's keys differently, so the file would
otherwise flip between two orderings and show a whole-file diff for a one-key change. The normalizer
(`Scripts/normalize-string-catalog.swift`) moves entries as raw text and refuses to write if the
reorder would alter the catalog's contents. See *String catalog* in `Agents.md`.

Steps 1 and 3 re-stage whole files. If you staged only some hunks of a file, its unstaged hunks are
committed too, so stage whole Swift files and the whole catalog.

If a tool the commit needs is missing, the hook stops and prints an install hint. Commits with no staged
Swift files don't need SwiftFormat or SwiftLint.
