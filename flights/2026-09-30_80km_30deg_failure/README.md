# SV-5.0.2 flight test — 80 km / 30° ascending

**Result: GUIDANCE FAILURE**

- Target: 80 km circular, 30° inclination
- Final Ap: 87.224299 km
- Final Pe: 80.000079 km
- Final inclination: 29.6216308°
- Remaining dV: 788.884 m/s
- Final MET: 504.24 s

## Failure sequence

The launch azimuth selection was directionally correct, but the coast orbit entered terminal guidance at only 27.141° inclination. At terminal-guidance entry (MET 203.96 s), plane error was -4374.015 m, cross-plane velocity was -65.713 m/s, and the along-track burn time estimate was only 25.552 s.

SV-5.0.2 used that along-track time-to-go as the deadline for radial and plane correction. The cross-plane controller therefore saturated near its 10 m/s² limit and drove cross velocity to roughly -385 m/s. Fine mode then latched when along-track error fell below 5 m/s even though the plane state was still badly unsettled. At the first fine-mode sample, inclination was only 21.554°, plane error was -584.56 m, and cross-plane velocity was -364.26 m/s. Apoapsis subsequently climbed as high as about 157.316 km while the stage unwound the cross-plane error.

## Changes motivated by this test

SV-5.1 adds:

- rotation-compensated surface launch azimuth derived from the target inertial plane;
- dynamic target-plane-following azimuth during ascent;
- plane-error-aware terminal acquisition timing;
- an independent plane feasibility horizon based on displacement and cross velocity;
- a shared multi-axis guidance horizon; and
- a fine-mode interlock requiring the plane state to be controlled before fine mode can latch.

The raw flight and guidance CSVs in this directory are the uploaded test logs.
