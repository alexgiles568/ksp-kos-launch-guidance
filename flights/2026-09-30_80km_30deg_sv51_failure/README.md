# SV-5.1 flight test — 80 km / 30° ascending

**Result: GUIDANCE FAILURE**

- Target: 80 km circular, 30° inclination
- Final Ap: 80.664605 km
- Final Pe: 79.999997 km
- Final inclination: 29.451662°
- Final inclination error: +0.548338°
- Remaining dV: 1138.519 m/s
- Guidance timed out at MET 459.94 s

## What the log showed

Terminal guidance started at MET 160.10 s with:

- inclination: 29.315343°
- reported plane angle: 0.691714°
- reported geometric plane offset: -8096.766 m
- radial velocity: +319.836 m/s
- cross-plane velocity: -18.075 m/s
- tangential error: +1045.698 m/s

The old SV-5.1 controller treated instantaneous distance from its stored plane as a translational state. It then drove cross-plane velocity as far as roughly -191 m/s and pushed apoapsis to roughly 126.9 km before spending the rest of the flight unwinding the error.

## Root cause

The target plane had originally been stored as a raw vector built from surface-referenced axes. That is not a safe way to represent a fixed celestial plane while Kerbin rotates and SHIP-RAW changes. The 0° case hid the distinction because surface north/south, equatorial plane error, latitude error, and inclination error nearly coincide there.

SV-5.2 replaces this architecture:

- the target plane is frozen as scalar coefficients in an inertial basis defined by `SOLARPRIMEVECTOR` and `BODY:ANGULARVEL`;
- the target normal is reconstructed every physics tick in current SHIP-RAW coordinates;
- terminal plane control uses the angle between current and target **orbital normals**, not geometric distance from the plane;
- a small hypothetical normal-dV probe determines which burn direction actually reduces orbital-plane error at the current orbital position.

The raw flight and guidance CSVs in this directory are the uploaded test logs.
