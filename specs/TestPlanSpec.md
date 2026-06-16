# Test Plan Spec

## Targets

| Target / Scheme | Runs on | Contents |
|-----------------|---------|----------|
| `MixStackTests` via `MixStackCI` | Every PR / push | Unit + accessibility contract + contrast + persistence |
| `MixStackUISmoke` | Nightly + local | Tab navigation + seeded catalog |
| `MixStackUILandscape` | Nightly + local | Landscape orientation smoke |
| `MixStackUIAccessibility` | Nightly + local | WCAG `performAccessibilityAudit` on core screens |
| `MixStackUIPad` | Nightly + local | iPad split navigation |
| `MixStackUI` | Local dev | All UI targets (parallel) |
| `MixStack` | Local dev | Unit + all UI targets + coverage |

## Swift Testing tags

Defined in `Tests/TestTags.swift`:

- `.unit` — pure logic, models, services
- `.accessibility` — contrast, identifier contracts
- `.regression` — bugs that must not return
- `.releaseGate` — required before ship
- `.importFlow`, `.audio` — domain tags

## Accessibility tests

| File | Purpose |
|------|---------|
| `WCAGContrastTests.swift` | Brand token contrast ratios |
| `AccessibilityIdentifierContractTests.swift` | Stable `A11yID` strings |

## Persistence integration

| File | Purpose |
|------|---------|
| `PersistenceIntegrationTests.swift` | Disk store survives simulated relaunch |
| `PersistenceTestSupport.swift` | Temporary store helpers |

## UI test launch args

```
-ui_test_reset
-ui_test_skip_onboarding
-ui_test_seed_catalog
-disable_analytics
```

Implemented in `Sources/Support/UITestLaunch.swift` and `UITestDataSeeder.swift`.

## WCAG UI audits

| File | Screens |
|------|---------|
| `WCAGAccessibilityUITests.swift` | Library, song detail, projects, settings |
| `Support/WCAGAccessibilitySupport.swift` | `performAccessibilityAudit` helpers |

Nightly iPhone job runs these alongside tab + landscape smoke tests.
iPad-only split tests live in `IPadSplitUITests` (skipped on iPhone).

## Coverage

- Local: Xcode scheme `gatherCoverageData: true` on `MixStackCI`
- CI: informational artifact via `Scripts/ci/coverage-summary.sh` (no threshold gate)

## Verification

Last verified: 2026-06-16 — 98 unit tests + 10 UI tests across split schemes
