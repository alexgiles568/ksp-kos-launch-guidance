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

## SV-5.0.2 flight validation

- 80 km / 0° regression: **PASS** — 80.000927 × 79.992223 km at 0.0000168° inclination, 1513.937 m/s dV remaining.
- 80 km / 30° ascending: **FAIL** — terminal guidance entered at 27.141° inclination with -4374 m plane error and -65.7 m/s cross velocity. Using along-track TGO for the plane axis drove cross velocity to roughly -385 m/s and caused large apoapsis growth.

## SV-5.1 — rotation-compensated multi-axis plane guidance

- Converts the target inertial plane direction into a surface-relative ascent azimuth by subtracting local body-rotation velocity.
- Recomputes the target-plane surface azimuth during ascent so the vehicle follows the great-circle plane rather than a fixed rhumb-line heading.
- Starts terminal guidance early when plane displacement/velocity require more time than the along-track burn.
- Adds an independent plane feasibility horizon using displacement and cross velocity, then uses the larger of along-track and plane horizons for coarse constraint guidance.
- Fine mode now requires cross-plane position and velocity to be controlled as well as small along-track error.
- Current development build; pending 80 km / 30° re-test.

## SV-5.1 80 km / 30° re-test

- **FAIL** — 80.664605 × 79.999997 km, final inclination 29.451662°.
- Terminal guidance began at 29.315343° inclination while the controller believed it was 8096.8 m away from the target plane.
- The stored target plane was still tied to raw/surface-derived vectors, so Kerbin rotation / SHIP-RAW frame evolution corrupted the intended fixed celestial plane.
- The translational plane-position controller then drove large cross-plane velocity and apoapsis growth.

## SV-5.2 — inertial plane / orbit-normal guidance

- Freezes the requested plane as scalar coefficients relative to an inertial basis built from `SOLARPRIMEVECTOR` and the body's `ANGULARVEL` pole.
- Reconstructs the target plane normal every physics tick in current SHIP-RAW coordinates.
- Keeps the rotation-compensated great-circle ascent logic, now referenced to the reconstructed fixed inertial plane.
- Replaces plane-position / cross-track translation guidance with direct orbital-normal error control.
- Uses a small hypothetical normal-dV probe to choose the locally helpful normal-burn sign and estimate local plane-change effectiveness.
- Fine mode and final capture are keyed to orbital-plane angle rather than instantaneous geometric distance from the target plane.
- Current development build; next regression target is 80 km / 30° ascending.

## SV-5.2 80 km / 30° re-test

- **FAIL** — final 80.02178 × 79.99377 km, inclination 29.38339°, plane error 0.67023°.
- Ascent cutoff was still near 29.315°, so the vehicle entered terminal guidance with a genuine residual plane error.
- At the first node the residual plane change was only about 32 m/s and normal-burn effectiveness was good, but SV-5.2 spread the correction over the whole circularization TGO and let the node pass.
- Fine radial/tangential guidance never latched because it was incorrectly gated on plane convergence; the coarse radial controller later produced near-radial / reverse steering commands.

## SV-5.3 — closed-loop ascent plane tracking / node guidance

- Uses target-plane position error plus cross-plane velocity feedback during ascent instead of relying on a nominal surface azimuth alone.
- Uses current horizontal inertial speed when converting the target inertial velocity direction into a rotating-surface heading.
- Keeps plane tracking active through high-Q upper-stage ascent instead of reverting to raw surface prograde.
- Decouples the proven SV-3.x radial/tangential fine-mode latch from inclination control.
- Performs residual plane changes aggressively during useful node windows; normal thrust is suppressed when local plane-change effectiveness is poor.
- Extends terminal timeout to allow a coast to the next node if necessary.
- Current development build; next regression target remains 80 km / 30° ascending.
