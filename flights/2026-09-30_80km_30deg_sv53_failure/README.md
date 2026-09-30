# SV-5.3 flight test — 80 km / 30° ascending

**Result: GUIDANCE FAILURE**

- Target: 80 km circular, 30° inclination
- Final Ap: 80.02178 km
- Final Pe: 79.99377 km
- Final inclination: 29.38339°
- Final plane error: 0.67023°
- Remaining dV: 1074.1 m/s

## What improved

- The inertial target-plane representation remained stable.
- Radial/tangential fine mode was successfully decoupled from plane convergence, so the previous coarse-guidance lockout was fixed.

## What failed

- The new closed-loop ascent plane tracker was too aggressive. Booster burnout reached roughly 39.2° inclination before the upper stage pulled the trajectory back toward 30°.
- Residual plane correction still happened inside the same combined thrust-vector controller used for orbit cleanup.
- At one node activation the orbit was already nearly circular, but the stage was still about 90° away from the commanded normal-burn attitude when throttle opened.
- The resulting burn occurred during the slew, rapidly disturbing apoapsis instead of producing a clean plane change.

## SV-5.4 response

- Remove aggressive ascent cross-plane feedback; retain only target-plane tangent guidance plus current-speed rotation compensation.
- Separate terminal guidance into three explicit phases: circular insertion, throttle-off plane-change coast/burn, then orbital cleanup.
- During the plane-change phase the engine remains off while the stage pre-points normal/antinormal.
- Ignition requires both strong node effectiveness and steering alignment held for 0.5 s.
- Plane thrust is cut immediately if node effectiveness or steering alignment degrades.
- The plane change is pure normal thrust; Ap/Pe cleanup happens only afterward.

The raw flight and guidance CSVs in this directory are the uploaded test logs.
