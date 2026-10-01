# SV-5.8 flight test — 80 km / 30° ascending

**Result: ORBIT PASS / PLANE STILL OFF**

- Final Ap: 80.00009 km
- Final Pe: 79.99010 km
- Final inclination: 29.81998°
- Final plane error: 0.47953°
- Remaining dV: 1477.3 m/s
- Orbit capture succeeded.

## What improved

- Booster burnout inclination was 29.98792°, essentially on the 30° target.
- Delayed separation/ignition fixed the upper-stage loss-of-control problem from SV-5.7.
- The 80 × 80 km insertion remained meter-class.

## What the logs showed

- Upper-stage cutoff inclination was 29.91880° with plane error about 0.486°.
- Terminal guidance started near 29.901° inclination / 0.487° plane error.
- The old orbital-normal plane trim activated briefly around MET 229.7–231.5 s. It reduced total orbital-normal angle only slightly, but drove inclination down from roughly 29.92° to about 29.82°.
- This is why the flight looked very close and then opened an inclination error late in the burn.
- The root problem is that minimizing total orbital-normal angle during a short node window can trade inclination error against LAN/plane-node error.

## SV-5.9 response

- Keep the successful 1365 m/s direct-launch calibration.
- Remove effectiveness-threshold / node-window plane trim from the powered guidance law.
- Replace it with a low-gain cross-track PD controller that directly damps signed distance from the fixed target plane and cross-plane velocity.
- Position time constant: 120 s.
- Velocity time constant: 12 s.
- Cross-track target velocity limited to ±20 m/s.
- Cross-track acceleration filtered each cycle and capped to 2° yaw.
- The same controller continues through terminal insertion, with its authority shrinking automatically as the main radial/tangential burn dies away.

The raw ascent, flight, and guidance CSVs in this directory are the uploaded test logs.