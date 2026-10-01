# Version Archive

## Complete source archived from the development chat

- `sv21.ks` — SV-2.1 sustained propulsion-failure detection.
- `sv3_experimental_tgo.ks` — SV-3 time-to-go experiment; unsuccessful flight.
- `sv31.ks` — SV-3.1 radial-priority control allocation.
- `sv32.ks` — SV-3.2 ±10 m precision lock and steering damping.
- `sv33_reference.ks` — SV-3.3 frozen 2-D reference.
- `sv40_broken_missing_fine_gain.ks` — SV-4.0 failed build, retained intentionally with the missing `fineTangentialGain` definition.
- `sv401_equatorial_reference.ks` — SV-4.0.1 frozen equatorial 3-D reference.
- `sv50_gui_original_broken.ks` — original SV-5.0 GUI build, retaining both discovered GUI bugs.
- `sv501_gui_clear_fix_broken_popup.ks` — SV-5.0.1 with `CLEARGUIS()` fixed but popup string assignment still broken.
- `sv502_mission_config.ks` — SV-5.0.2 branch with both known GUI issues fixed.
- `sv51_plane_guidance.ks` — current SV-5.1 rotation-compensated, feasibility-aware plane-guidance branch.

## Reconstructed source

Earlier builds for which the exact assistant message was not fully recoverable in the active transcript are kept under `../reconstructed/` rather than presented as byte-for-byte originals.

See the repository-level `HISTORY.md` for tested results and development rationale.

- `sv52_inertial_orbit_normal_guidance.ks` — current SV-5.2 branch: inertially fixed target plane and orbit-normal terminal controller.

- `sv53_closed_loop_plane_node_guidance.ks` — current SV-5.3 branch: closed-loop ascent plane tracking plus node-window residual plane correction.

- `sv54_phased_insertion_plane_cleanup.ks` — current SV-5.4 branch: circular insertion, aligned node plane burn, then orbit cleanup.

- `sv55_direct_plane_launch_yaw_trim.ks` — current SV-5.5 branch: calibrated direct-plane launch with limited upper-stage/terminal yaw trim.

- `sv56_calibrated_launch_effectiveness_gain_fix.ks` — current SV-5.6 branch: 1500 m/s launch-plane calibration with corrected local-dV yaw-trim gain.

- `sv59_damped_cross_track_pd.ks` — current SV-5.9 branch: damped cross-track position/velocity plane guidance with 2° yaw cap.

- `sv60_inclination_only_trim.ks` — current SV-6.0 branch: inclination-only numerical normal-trim controller.

- `sv61_local_inclination_course.ks` — current SV-6.1 branch: local inclination-derived ascent course with direct inclination trim.

- `sv62_speed_matched_rotation_prepoint.ks` — SV-6.2 intermediate branch with speed-matched booster rotation compensation and upper-stage pre-pointing.
- `sv63_horizontal_velocity_servo.ks` — current SV-6.3 branch: horizontal inertial velocity-vector course servo.
