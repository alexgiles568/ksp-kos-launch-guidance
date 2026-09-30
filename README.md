# KSP kOS Launch Guidance

Autonomous launch-guidance development for a 0.625 m two-stage liquid-fueled Kerbal Space Program launcher using kOS.

## Proven reference builds

- **SV-3.3** — locked 80 km circular-orbit baseline. Flight result: **80.00010 × 79.99057 km**.
- **SV-4.0.1** — locked 80 km / 0° inclination 3-D baseline. Flight result: **80.00026 × 79.99081 km at 0.0001303° inclination**.
- **SV-5.0.2** — mission-config GUI passed the 80 km / 0° regression test but failed the 80 km / 30° test.
- **SV-5.1** — failed the 80 km / 30° re-test because the target plane was still represented in a rotating/raw-vector frame.
- **SV-5.2** — current development branch: inertially frozen target plane plus orbit-normal terminal guidance.

## Development path

1. Initial two-stage 0.625 m liquid launcher and diagnostic branches
2. Maneuver-node circularization experiment
3. SV-1 / SV-2 direct state-vector guidance
4. SV-2.1 capture/failure-handling refinement
5. SV-3 time-to-go experiment
6. SV-3.1 radial-priority control allocation
7. SV-3.2 ±10 m capture and steering damping
8. SV-3.3 actuator hysteresis; frozen 2-D reference
9. SV-4.0 / SV-4.0.1 3-D equatorial-plane guidance; frozen 3-D reference
10. SV-5.0.x configurable mission GUI / arbitrary target-plane branch
11. SV-5.1 rotation-compensated, multi-axis plane-guidance branch

See `HISTORY.md` for flight-test notes and status.

## Vehicle assumptions

- Two-stage 0.625 m liquid launcher
- Fairing jettison on action group 1
- Booster separation delayed for safe altitude / dynamic pressure
- Upper-stage ignition delayed for booster clearance

## Repository policy

`sv33_reference.ks` and `sv401_equatorial_reference.ks` are frozen regression references. New work should branch from them rather than changing the reference files in place.
