# SV-5.2 flight test — 80 km / 30° ascending

**Result: GUIDANCE FAILURE**

- Target: 80 km circular, 30° inclination
- Final Ap: 80.02178 km
- Final Pe: 79.99377 km
- Final inclination: 29.38339°
- Final plane error: 0.67023°
- Remaining dV: 1074.1 m/s

## Key findings

- Powered ascent still ended near 29.315° instead of 30°.
- Terminal guidance began at about 29.282° with ~0.891° orbital-plane error.
- The first node was usable: plane-effectiveness ratio started near 0.59 and the residual plane change was only about 32 m/s.
- SV-5.2 spread that correction across the whole circularization TGO, so the node passed before the plane change was complete.
- Fine radial/tangential mode was incorrectly gated on plane convergence. Because the plane error remained large, the coarse radial controller stayed active after circularization and eventually commanded near-radial / reverse steering with very large steering errors.

## SV-5.3 changes motivated by this flight

- Closed-loop ascent plane tracking using signed target-plane position error and cross-plane velocity.
- Rotation compensation now uses current horizontal inertial speed instead of final circular speed during the gravity turn.
- Radial/tangential fine mode is independent of plane state.
- Residual inclination correction is performed aggressively while near a useful plane-change node and suppressed away from the node.
- Terminal timeout is long enough to coast to the next node if the first correction opportunity is missed.

The raw flight and guidance CSVs in this directory are the uploaded test logs.
