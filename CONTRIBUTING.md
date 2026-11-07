# Contributing to StockBar

Thanks for taking the time to contribute. StockBar is a small, deliberately minimal macOS menu-bar app: one number in the menu bar, a lightweight panel, no Dock icon, no accounts, no tracking. Contributions that keep it that way are very welcome.

## Requirements

- macOS 13 or newer (the app targets macOS 26 SDK when built on a recent toolchain)
- Swift 6.3 toolchain — either full Xcode or the Command Line Tools
- No third-party dependencies: the package uses only Foundation, SwiftUI and AppKit

## Build and run

```bash
git clone https://github.com/huandc/StockBar.git
cd StockBar
swift build
./.build/debug/StockBar
```

For a release build: `swift build -c release`.

## Tests

```bash
./scripts/test.sh
```

**Do not call `swift test` directly if you only have the Command Line Tools.** The test target uses [swift-testing](https://github.com/swiftlang/swift-testing), and the CLT installation does not put `Testing.framework` and the `TestingMacros` plugin on the default search paths, so a plain `swift test` fails with:

```
error: no such module 'Testing'
```

`scripts/test.sh` detects that layout and adds the framework search path, the macro plugin library and the runtime `rpath` that `lib_TestingInterop.dylib` needs. On a machine with full Xcode (and on CI) the script simply runs `swift test`, because the native paths already work.

Tests must not touch the network. HTTP-dependent code takes an injectable `HTTPTransporting`, and the test suite ships `ScriptedTransport` for that purpose.

## Documentation images

`docs/images/*.png` are rendered offscreen from the app's own SwiftUI views by `DocSnapshots`
(`StockBar --render-docs-images <dir>`), which `./scripts/screenshots.sh` wraps. Re-run it after
changing the panel or menu bar layout, and commit the regenerated PNGs. Rendering is deterministic:
if the images change without a UI change, the sample data or a time field is not frozen.

## Project layout

| File | Responsibility |
| --- | --- |
| `StockBarApp.swift` | `@main` entry, `MenuBarExtra`, menu-bar label and status icon |
| `QuoteModel.swift` | Observable state: refresh loop, watchlist rotation, persistence |
| `ContentView.swift` | Panel and settings UI |
| `QuoteProvider.swift` | Provider protocol, `FetchError`, display helpers |
| `YahooProvider.swift`, `EastMoneyProvider.swift` | Concrete data sources and response parsing |
| `QuoteHTTP.swift` | Transport abstraction, timeouts, retry policy, logging |
| `SourceStatus.swift` | Which source is active, why/when it switched |
| `RefreshStatus.swift` | Menu-bar status icon and refresh/retry wording |
| `MenuBarLayout.swift` | Width-aware truncation of the menu-bar text |
| `WatchlistRotation.swift` | Parsing and index math for the rotating watchlist |
| `MarketSession.swift`, `SymbolMapper.swift`, `DisplayFormat.swift`, `QuoteColors.swift` | Pure helpers: sessions, symbol normalisation, formatting, colours |

Rule of thumb: **keep the logic that can break out of the views**. Anything with branching (formatting, session maths, truncation, index rotation, error wording) should be a pure function or value type that a unit test can drive without launching the app.

## Branches and pull requests

`main` is protected:

- pull requests only — direct pushes are rejected
- required status check: `check` (the `PR Check` workflow: `swift build`, the unit tests, and the PR title check)
- squash merges only, no force pushes, admins are not exempt

So a change looks like this:

```bash
git checkout main && git pull
git checkout -b fix/timeout-on-sleep
# ... edit, build, test ...
git commit -m "fix: 休眠唤醒后首次刷新必定超时"
git push -u origin HEAD
gh pr create --base main --fill
```

Keep the PR focused on one thing. If a change touches the UI, include a before/after screenshot of the menu bar or the panel.

### Commit and PR titles

Conventional Commits, enforced by CI on the PR title (the commit history is squashed, so the PR title becomes the commit on `main`):

```
^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(scope\))?!?: .+
```

| Type | Use for |
| --- | --- |
| `feat` | user-visible behaviour changes |
| `fix` | bug fixes |
| `docs` | README, CONTRIBUTING, comments in docs |
| `refactor` | same behaviour, better structure |
| `perf` | measurable speed or memory wins |
| `test` | tests only |
| `build`, `ci`, `chore` | tooling, workflows, dependencies |

The subject line may be English or Chinese; Chinese is fine and used throughout the existing history. The body should explain **why**, in a sentence or two, not restate the diff.

## Roadmap

`docs/ROADMAP.md` is the working queue, ordered by priority. Pick the first unchecked item, finish it in one PR, tick it, and add a line under 「已完成」 with the date and a one-sentence summary. If an item turns out to be too big for one sitting, split it and leave a note rather than leaving the checkbox half-done.

## Adding a data source

1. Add a case to `QuoteProvider` with a display name.
2. Implement `fetch(_:)` against the shared `QuoteHTTPClient` (do not create your own `URLSession`).
3. Use the existing `FetchError` cases so the retry policy and the user-facing reason strings keep working.
4. Parse into `Quote` — normalise the symbol through `SymbolMapper` first.
5. Add parser tests with recorded JSON. No live network calls in tests.
6. Mention the new source in the README settings table.

## Code style and environment gotchas

- Formatting is enforced by CI: run `./scripts/format.sh` before pushing (it rewrites `Sources/` and `Tests/` with the checked-in `.swift-format` config: 4-space indent, 120-column lines). `./scripts/format.sh --lint` is the check CI runs — do not reformat unrelated files in the same PR.
- 4-space indent, Chinese comments in the app code, English in tests and docs.
- `os.Logger` interpolations are autoclosures: referencing `self`-properties inside them fails with `reference to property 'x' in closure requires explicit use of 'self'`. Assign a local constant first.
- In `Package.swift`, `targets:` must precede `swiftLanguageModes:`, otherwise SwiftPM reports `argument 'targets' must precede argument 'swiftLanguageModes'`.
- `Package.swift` pins Swift language mode v5 on purpose while the toolchain is 6.x; do not flip it to v6 as part of an unrelated change.

## Releasing and the Homebrew cask

1. Branch from `main` as `release/vX.Y.Z` and push it — `.github/workflows/release.yml` builds the `.app`, ad-hoc signs it, zips it and attaches `StockBar-X.Y.Z-macOS.zip` to a GitHub release tagged `vX.Y.Z`.
2. Point the cask at the new build and commit the result:

```bash
./scripts/update-cask.sh X.Y.Z   # rewrites version + sha256, then self-checks
git add Casks/stockbar.rb && git commit -m "chore: 更新 Homebrew cask 到 X.Y.Z"
```

`scripts/check-cask.sh` downloads the release asset and refuses a cask whose `sha256` does not match, so a stale cask cannot be merged unnoticed — `cask-check` runs it automatically on any PR that touches `Casks/`.

The cask lives in this repository under `Casks/`, so users install it with `brew tap huandc/stockbar https://github.com/huandc/StockBar`, `brew trust --cask huandc/stockbar/stockbar` (Homebrew 7 refuses untrusted third-party taps) and then `brew install --cask stockbar`; there is no separate tap repository to keep in sync.

## Reporting bugs

Use the issue forms (`.github/ISSUE_TEMPLATE/`): the bug report asks for the macOS version, chip, data source and logs, which is usually everything needed to reproduce a menu-bar or refresh problem. For security reports, do not open a public issue — use the private channel linked from the issue chooser.
