# Visual regression protocol

This project aims for a Windows 11 match at a **defined** display contract:

- Ubuntu 26.04, Plasma 6.6.6, Wayland
- 1920×1080 display, 100% scale, single display
- Inter font, current Windows Modern icon theme
- dark and light variants tested separately

Pixel-perfect is assessed per scenario, not across arbitrary monitors,
hardware, font renderers, or application versions.

## Reference set

Store approved source captures outside the public repository when they are
licensed Windows screenshots. The public repository stores only the capture
manifest, measured specification, and derived diff images where appropriate.

Required scenarios:

1. clean desktop and taskbar;
2. Start menu: pinned, all apps, search;
3. system tray and quick settings;
4. calendar flyout;
5. active and inactive decorated windows;
6. context menu and representative Qt dialog;
7. lock screen and login screen.

Capture the Plasma side with `scripts/capture-screenshots.sh` after manually
normalising time, battery, network, wallpaper, open applications and scale.

## Comparison command

```bash
scripts/visual-regression.sh \
  --reference references/win11-dark-taskbar.png \
  --actual captures/plasma-dark-taskbar.png \
  --output artifacts/taskbar-diff.png \
  --crop 1920x96+0+984 \
  --threshold 0.015
```

The normalized RMSE is 0 for an identical image and 1 for maximal difference.
Use a threshold agreed per scenario, and record it with the comparison result.
Mask or crop dynamic regions instead of raising a threshold to hide regressions.

## CI boundary

GitHub Actions validates the comparison tool itself and its shell quality. It
does not claim to render a real Plasma/Wayland session: final screenshot
comparisons must run in the controlled desktop contract above.
