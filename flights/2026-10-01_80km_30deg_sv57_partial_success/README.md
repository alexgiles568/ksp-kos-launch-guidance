# SV-5.7 flight test — 80 km / 30° ascending

**Result: ORBIT PASS / PLANE MISS / CONTROL ISSUES IDENTIFIED**

- Final Ap: 80.00049 km
- Final Pe: 79.99025 km
- Final inclination: 29.77422°
- Final plane error: 0.57546°
- Remaining dV: 1247.9 m/s
- Orbit capture succeeded.

## Upper-stage control loss

- Booster burnout inclination: 30.19043° — the 1300 m/s launch reference slightly overshot the 30° target.
- Booster separated at MET 80.76 s, altitude 28.34 km, q = 0.0575 atm.
- Upper engine became ready at MET 82.62 s, altitude 29.59 km, q = 0.0443 atm.
- Immediately after ignition, steering error grew from about 7.5° to more than 150° while plane trim itself was capped at 3°.
- This points to upper-stage attitude/aerodynamic instability at excessive dynamic pressure, not simply excessive plane-trim gain.

## Terminal yaw oscillation

- The plane-effectiveness gate in SV-5.7 used a hard 0.05 threshold.
- Between roughly MET 215.6 and 234.0, the plane-trim command switched on/off about 19 times as effectiveness crossed that threshold.
- The commanded yaw therefore repeatedly jumped between 0° and the 5° cap.
- This was a threshold-driven limit cycle rather than a classic underdamped steering PID.

## SV-5.8 response

- Delay booster separation until altitude >= 33 km and q <= 0.025 atm.
- Retain the post-separation coast before upper-engine ignition, so ignition occurs at substantially lower q.
- Recalibrate launch reference to 1365 m/s from the SV-5.6 / SV-5.7 booster-burnout interpolation.
- Upper-stage plane trim is inhibited above q = 0.015 atm and while steering error exceeds 5°.
- Plane trim uses hysteresis: enable at effectiveness >= 0.18, disable at <= 0.10.
- Once a correction window closes, it does not chatter back on during the same burn.
- Near-vacuum / terminal yaw authority is reduced back to 3°.
- Fine-mode yaw time constant increased from 4 to 6 for additional damping.

The raw ascent, flight, and guidance CSVs in this directory are the uploaded test logs.