# Development History

## Early launcher / diagnostics

- Initial two-stage 0.625 m liquid launcher built after an all-solid 0.625 m challenge vehicle.
- Diagnostic scripts logged ascent, burn timing, and circularization performance.
- Early automated insertion produced a roughly 320 × 80 km orbit, exposing premature second-burn timing.
- Later diagnostic iterations introduced delayed upper-stage ignition, fairing deployment, lofted ascent, and safer stage separation.

## Maneuver-node branch

- A maneuver-node circularization branch was tested.
- Recorded result: approximately **80.907 × 79.069 km**.
- This was abandoned because direct human-style state feedback was more accurate than node execution.

## SV-1 / SV-2

- Guidance changed to direct control of horizontal/tangential and radial velocity.
- SV-2 added a capture region and stopped chasing tiny errors indefinitely.

## SV-2.1

- Preserved SV-2 guidance while fixing a false propellant-depletion abort caused by transient `DELTAV:CURRENT` readings.
- Failure detection required both near-zero reported dV and near-zero available thrust for a sustained interval.

## SV-3

- Added time-to-go radial guidance and mass-sensitive terminal-burn timing.
- Flight result was poor: roughly **81.939 × 76.892 km** after the controller became under-actuated during the main burn.
- Diagnosis: the requested radial component was being lost when the combined acceleration vector saturated available thrust.

## SV-3.1

- Introduced radial-priority control allocation.
- Added a permanent fine-mode latch once tangential error was small.
- Result: **80.00395 × 79.97526 km**.

## SV-3.2

- Tightened capture from ±25 m to ±10 m.
- Added fine steering damping and steering-error logging.
- Result: **80.00350 × 79.99013 km**.

## SV-3.3 — frozen 2-D reference

- Added actuator hysteresis and held the last useful thrust attitude while coasting.
- Result: **80.00010 × 79.99057 km**.
- This is the frozen 80 km circular-orbit regression baseline.

## SV-4.0

- Extended terminal guidance to three axes: radial, eastward, and north/south.
- Targeted 0° inclination and equatorial-plane convergence.
- First run reached essentially 0° inclination and an 80.000 km apoapsis before crashing at fine-mode entry because `fineTangentialGain` was undefined.

## SV-4.0.1 — frozen 3-D reference

- Hotfix: restored `SET fineTangentialGain TO 0.12.`
- Result: **80.00026 × 79.99081 km**, inclination **0.0001303°**.
- Equatorial-orbit capture confirmed.

## SV-5.0.x — mission configuration

- Began generalizing target altitude and inclination through a kOS GUI.
- GUI issue 1: `CLEARGUIS` needed to be called as `CLEARGUIS()`.
- GUI issue 2: popup strings could not be assigned directly through `PopupMenu:VALUE` on this kOS build; branch selection was changed to numeric `PopupMenu:INDEX`.
- Current branch: **SV-5.0.2**, awaiting regression flight.
