# SV-6.0 flight test — 80 km / 90° ascending

**Result: ORBIT PASS / INCLINATION MISS**

- Target: 80 km circular, 90° inclination
- Final Ap: 80.00021 km
- Final Pe: 79.99048 km
- Final inclination: 88.523229°
- Final inclination error: +1.476771°
- Final plane-geometry error: 1.908894°
- Remaining dV: 1292.7 m/s

## What the logs showed

- Booster burnout inclination was about 88.8093°.
- Upper-stage ascent then moved farther away from the requested polar inclination, reaching about 87.6882° at ascent cutoff.
- Terminal inclination-only trim behaved in the correct direction and recovered inclination steadily to about 88.52°, but the remaining insertion burn was not long enough to erase the full error.
- The radial/tangential insertion remained excellent, preserving the meter-class 80 × 80 km result.

## Root cause

SV-6.0 controlled inclination directly in the trim loop, but its **nominal booster and upper-stage course still followed a frozen full target plane**. That implicitly constrained LAN / RAAN. The effect was small at 30° and 45° but became obvious for a polar mission, where the desired local inertial course should remain north/south as Kerbin rotates beneath the vehicle.

## SV-6.1 response

- Nominal ascent steering now comes directly from the requested inclination at the vehicle's current latitude.
- Local east component is `cos(inclination) / cos(latitude)`.
- The north/south component is selected by the ASCENDING / DESCENDING mission branch.
- The resulting course specifies inclination without fixing LAN / RAAN.
- The existing direct inclination trim remains active during upper-stage and terminal powered flight.
- The frozen plane is retained only for legacy diagnostics.

The raw ascent, flight, and guidance CSVs in this directory are the uploaded test logs.