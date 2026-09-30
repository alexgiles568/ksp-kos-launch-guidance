# SV-5.4 flight test — 80 km / 30° ascending

**Result: WRONG DEVELOPMENT DIRECTION / GUIDANCE FAILURE**

- Target: 80 km circular, 30° inclination
- Booster burnout inclination: 32.884171°
- Ascent cutoff inclination: 32.933197°
- Terminal entry inclination: about 32.9°
- Late orbit: about 80.00084 × 79.98867 km
- Plane error remained about 3.19°
- Remaining dV late in the run: about 1472.9 m/s

## Main conclusion

The sequential insertion -> coast -> dedicated plane burn -> cleanup architecture is unnecessary for this launcher and did not address the real source of the error. The vehicle should launch almost directly into the requested plane, and any small residual should be removed by a modest yaw bias during the upper-stage burn that is already required for orbital insertion.

## What the flight showed

- Using current/low-speed rotation compensation drove the ascent too far north: the booster was already at 32.88° instead of 30°.
- The circular-orbit controller still produced an excellent near-80 × 80 km orbit.
- Because the plane error was large, the phased controller never provided the practical one-burn ascent/insertion behavior desired for this vehicle.

## SV-5.5 response

- Replace current-speed launch compensation with a tunable fixed reference speed, initially 1800 m/s.
- Keep the booster on the target-plane great-circle tangent.
- Upper stage uses an inertial in-plane pitch vector.
- Compute actual orbital-normal error continuously.
- Add only a small normal component as yaw trim during the powered second-stage burn.
- Cap the correction by yaw angle: 1.5° in higher dynamic pressure and 3° in near-vacuum/terminal flight.
- Restore SV-3.3 radial/tangential terminal guidance and never allow plane correction to become a standalone burn.

The raw flight and guidance CSVs in this directory are the uploaded test logs.
