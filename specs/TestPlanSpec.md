# Test Plan Spec

## Targets

| Target | Runs on | Contents |
|--------|---------|----------|
| `MixStackTests` | Every PR / push | Unit + accessibility contract + contrast |

Future: split UI schemes (`MixStackUISmoke`, `MixStackUIAccessibility`) on nightly matrix.

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

## UI test launch args (planned)

```
-ui_test_reset
-disable_analytics
-enable_full_product_surface
```

## Coverage

- Local: Xcode scheme `gatherCoverageData: true`
- CI: informational artifact via `Scripts/ci/coverage-summary.sh` (no threshold gate)

## Verification

Last verified: 2026-06-16
