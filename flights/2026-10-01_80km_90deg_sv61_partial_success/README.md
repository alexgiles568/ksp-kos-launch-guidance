# SV-6.1 flight test — 80 km / 90° ascending

**Result: ORBIT PASS / INCLINATION MISS**

- Final Ap: 80.00011 km
- Final Pe: 79.99033 km
- Final inclination: 88.587195°
- Final inclination error: +1.412805°
- Remaining dV: 1292.7 m/s

## What the flight showed

- The 90° case still carried substantial unwanted east/west inertial horizontal velocity.
- The local inclination-course heading by itself was not enough to force the actual horizontal velocity vector onto the requested polar course.
- The upper-stage / terminal inclination trim recovered some error, but it ran out of powered-burn authority before reaching 90°.
- Radial/tangential insertion remained excellent.

## Development response

SV-6.2 introduced speed-matched Kerbin-rotation compensation and upper-stage pre-pointing. SV-6.3 goes one step further: it closes the loop directly on the **actual horizontal inertial velocity vector**.

SV-6.3 measures the horizontal velocity component perpendicular to the local inclination course and damps that component toward zero during booster, upper-stage, and terminal powered flight. This directly cancels the unwanted eastward inertial velocity that matters most for a polar launch.

The raw ascent, flight, and guidance CSVs in this directory are the uploaded test logs.