# SV-5.5 flight test — 80 km / 30° ascending

**Result: ORBIT PASS / PLANE MISS**

- Final Ap: 80.00021 km
- Final Pe: 79.99068 km
- Final inclination: 29.713286°
- Final plane error: 0.705064°
- Remaining dV: 1484.9 m/s
- 80 × 80 km orbit capture succeeded.

## What worked

- The radial/tangential SV-3.3 architecture remained excellent: final apsis errors were about -0.21 m and +9.32 m.
- The 1800 m/s launch reference was much closer than the previous low-speed compensation: booster burnout inclination was 28.9995°.
- The limited yaw-trim architecture was stable and did not produce the large doglegs or dedicated plane burns seen in earlier branches.

## What was wrong

SV-5.5's plane-trim gain had the effectiveness term backwards. It computed an ideal plane-change dV and then multiplied the requested acceleration by local effectiveness. When geometry made a normal burn less effective, that reduced the command further. The numerical probe already measures angle improvement per m/s, so the correct local dV is `planeAngleError / planeImprovementPerDv`.

At terminal-guidance entry, plane error was about 0.889° and effectiveness about 0.618. The controller initially used only ~0.76° of yaw trim and the plane error fell to ~0.705° before the useful geometry passed. The available 3° yaw cap was never reached during the main powered portion of the burn.

## SV-5.6 changes

- Launch reference speed reduced from 1800 to 1500 m/s to move the booster modestly closer to the target 30° plane.
- Plane-trim command now uses the numerically estimated **local dV required** instead of multiplying ideal dV by effectiveness.
- Upper-stage trim time constant reduced from 20 s to 12 s.
- Terminal trim time floor reduced from 8 s to 6 s.
- Existing yaw caps remain: 1.5° at higher dynamic pressure and 3° in near-vacuum/terminal flight.

The raw CSVs in this directory are the uploaded flight and guidance logs.