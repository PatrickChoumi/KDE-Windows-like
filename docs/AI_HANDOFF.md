# AI handoff and change journal

This is the living continuity record for humans and future assistants. Update
it with every implementation batch and once more at the end of a work session.

## Project contract

- Target: Windows 11 visual parity on KDE Plasma 6.6.6 / Ubuntu 26.04.
- Definition of pixel-perfect: comparison against approved Windows references
  at 1920×1080, 100% scale, single display, with documented dynamic-region
  handling. It is not a claim of identical rendering on every monitor.
- Safety: one component at a time; no `install.sh all` and no layout reset
  during iterative visual work; capture and verify before advancing.

## 2026-11-10 — visual-regression foundation

**Baseline reviewed:** `main` at `9c6148d81d3efb81756210ecc831e29f04cbb6d2`.

### Added

| Path | Why it exists | Verification |
|---|---|---|
| `docs/VISUAL_REGRESSION.md` | Defines the reproducible display contract, required scenario set and comparison method. | Read with this journal; follow before visual changes. |
| `scripts/visual-regression.sh` | Produces a diff image and fails when normalized RMSE exceeds a specified threshold. | `scripts/test-visual-regression.sh` tests identical and changed images. |
| `scripts/test-visual-regression.sh` | Keeps the comparison tool deterministic and CI-testable without a GUI. | Run locally or in GitHub Actions. |
| `.github/workflows/quality.yml` | Runs the visual-tool contract tests and ShellCheck on pushes and pull requests. | GitHub Actions workflow **Quality**. |

### Deliberate constraints

- CI cannot prove Plasma pixel parity: it lacks the target Wayland/KWin session.
  It only proves that the comparison machinery remains sound.
- Windows reference captures are not committed unless their licence permits it.
- The next implementation task is **Icon Tasks validation on real Plasma**;
  do not restyle more components before it has passed journal and screenshot
  checks.

### Next operator checklist

1. Create approved dark/light Windows 11 reference captures at the display
   contract above.
2. Capture matching Plasma states using `scripts/capture-screenshots.sh`.
3. Run `scripts/visual-regression.sh` per scenario and record the scores.
4. Validate Icon Tasks alone; then update this file with screenshots, logs,
   score and rollback command.
