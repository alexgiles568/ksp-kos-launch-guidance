// ======================================================
// SV-5.9 MISSION CONFIG
// 0.625 m TWO-STAGE LIQUID LAUNCHER
//
// CONFIGURABLE:
//   - Circular orbit altitude
//   - Orbital inclination
//   - Ascending / descending launch-plane branch
//
// Derived from successful SV-4.0.1 / SV-3.3 guidance.
//
// SV-5.9:
// - Keeps the SV-5.8 1365 m/s launch calibration; that
//   produced 29.988 deg at booster burnout.
// - Replaces the orbital-normal effectiveness/window trim
//   with a low-gain CROSS-TRACK PD controller.
// - The controller directly damps signed distance from the
//   target inertial plane and cross-plane velocity.
// - This fixes the late-burn behavior where the old node
//   trim reduced total plane angle while moving inclination
//   away from 30 deg.
// - Cross-track correction is continuous and smooth rather
//   than threshold-switched, with explicit velocity damping,
//   command filtering, and a 2-deg yaw cap.
// - The correction remains tied to the existing upper-stage
//   / terminal insertion burn; it cannot become a separate
//   plane-change burn.
// - SV-3.3 radial/tangential insertion remains unchanged.
//
// ======================================================

CLEARSCREEN.
CLEARGUIS().

SET orbitTarget TO 80000.
SET targetInclination TO 0.
SET planeBranch TO "ASCENDING".

// ======================================================
// MISSION CONFIG GUI
// ======================================================

SET configGui TO GUI(360).

SET configGui:X TO 50.
SET configGui:Y TO 80.
SET configGui:DRAGGABLE TO TRUE.

SET titleLabel TO configGui:ADDLABEL("SV-5.9 LAUNCH GUIDANCE").
SET titleLabel:STYLE:ALIGN TO "CENTER".
SET titleLabel:STYLE:HSTRETCH TO TRUE.

configGui:ADDSPACING(6).

SET subtitleLabel TO configGui:ADDLABEL("Mission Configuration").
SET subtitleLabel:STYLE:ALIGN TO "CENTER".
SET subtitleLabel:STYLE:HSTRETCH TO TRUE.

configGui:ADDSPACING(8).

SET altitudeRow TO configGui:ADDHLAYOUT().
SET altitudeLabel TO altitudeRow:ADDLABEL("Orbit altitude (km):").
SET altitudeLabel:STYLE:WIDTH TO 190.
SET altitudeField TO altitudeRow:ADDTEXTFIELD("80").
SET altitudeField:STYLE:WIDTH TO 120.

SET inclinationRow TO configGui:ADDHLAYOUT().
SET inclinationLabel TO inclinationRow:ADDLABEL("Inclination (deg):").
SET inclinationLabel:STYLE:WIDTH TO 190.
SET inclinationField TO inclinationRow:ADDTEXTFIELD("0").
SET inclinationField:STYLE:WIDTH TO 120.

SET branchRow TO configGui:ADDHLAYOUT().
SET branchLabel TO branchRow:ADDLABEL("Plane branch:").
SET branchLabel:STYLE:WIDTH TO 190.

SET branchMenu TO branchRow:ADDPOPUPMENU().
SET branchMenu:OPTIONS TO LIST("ASCENDING","DESCENDING").
SET branchMenu:INDEX TO 0.
SET branchMenu:STYLE:WIDTH TO 120.

configGui:ADDSPACING(8).

SET statusLabel TO configGui:ADDLABEL("Enter mission parameters.").
SET statusLabel:STYLE:ALIGN TO "CENTER".
SET statusLabel:STYLE:HSTRETCH TO TRUE.

configGui:ADDSPACING(6).

SET launchButton TO configGui:ADDBUTTON("ARM MISSION").
SET launchButton:STYLE:HSTRETCH TO TRUE.

configGui:SHOW().

// ======================================================
// WAIT FOR VALID CONFIGURATION
// ======================================================

SET configAccepted TO FALSE.

UNTIL configAccepted {

    IF launchButton:TAKEPRESS {

        SET altitudeKm TO altitudeField:TEXT:TONUMBER(-999999).
        SET inclinationInput TO inclinationField:TEXT:TONUMBER(-999999).

        SET branchInput TO "ASCENDING".

        IF branchMenu:INDEX = 1 {
            SET branchInput TO "DESCENDING".
        }.

        IF altitudeKm = -999999 {

            SET statusLabel:TEXT TO "Altitude must be a number.".

        } ELSE IF altitudeKm < 71 {

            SET statusLabel:TEXT TO "Altitude must be >= 71 km.".

        } ELSE IF altitudeKm > 5000 {

            SET statusLabel:TEXT TO "Altitude limit: 5000 km.".

        } ELSE IF inclinationInput = -999999 {

            SET statusLabel:TEXT TO "Inclination must be a number.".

        } ELSE IF inclinationInput < 0
               OR inclinationInput > 180 {

            SET statusLabel:TEXT TO "Inclination must be 0..180 deg.".

        } ELSE {

            SET orbitTarget TO altitudeKm * 1000.
            SET targetInclination TO inclinationInput.
            SET planeBranch TO branchInput.
            SET configAccepted TO TRUE.
            SET statusLabel:TEXT TO "MISSION ACCEPTED".
        }.
    }.

    WAIT 0.1.
}.

WAIT 0.4.

configGui:HIDE().
configGui:DISPOSE().

// ======================================================
// GUIDANCE CONSTANTS
// ======================================================

SET etaTarget TO 50.

SET sepMinAlt TO 33000.
SET sepMaxQ TO 0.025.

SET fairingMinAlt TO 60000.
SET fairingMaxQ TO 0.0005.

SET coarseTangentialGain TO 0.35.
SET fineTangentialGain TO 0.12.
SET fineLatchTanError TO 5.

SET fineRadialTimeConstant TO 25.
SET fineRadialVelGain TO 0.16.
SET radialVelMax TO 90.

SET radialTgoFloor TO 4.
SET radialAccelLimit TO 6.

// ------------------------------------------------------
// LAUNCH / PLANE TRIM
// ------------------------------------------------------
//
// Empirical launch-plane reference speed.
// Previous tests bracketed the correct 30-deg solution:
// full circular-speed compensation undershot inclination,
// while low/current-speed compensation overcorrected.
// Flight calibration:
//   SV-5.5: 1800 m/s -> 28.9995 deg booster burnout
//   SV-5.6: 1500 m/s -> 29.6077 deg booster burnout
//   SV-5.7: 1300 m/s -> 30.1904 deg booster burnout
// Linear interpolation puts the 30-deg reference near
// 1365 m/s.  Upper-stage yaw trim removes the residual.

SET launchPlaneReferenceSpeed TO 1365.

// Small yaw correction during the already-required
// second-stage burn.  It is never allowed to become a
// dedicated plane-change maneuver.

// Cross-track path controller.
//
// position error:
//   signed perpendicular distance from the vehicle's
//   current radius vector to the fixed target plane.
//
// velocity error:
//   signed inertial velocity perpendicular to that plane.
//
// The long position time constant keeps this a gentle yaw
// trim rather than a dogleg.  Velocity feedback supplies
// the damping that the earlier branches were missing.

SET crossTrackPositionTime TO 120.
SET crossTrackVelocityTime TO 12.
SET crossTrackVelocityLimit TO 20.
SET crossTrackFilterGain TO 0.12.

SET upperCrossTrackMaxQ TO 0.015.
SET upperCrossTrackMaxSteerError TO 6.
SET upperCrossTrackMaxYaw TO 2.

SET terminalCrossTrackMaxYaw TO 2.

SET planeResidualReportTolerance TO 0.05.
SET terminalIgnitionSteerError TO 8.

SET constraintAllocationFraction TO 0.98.
SET startLeadBias TO 0.8.

SET accelStopThreshold TO 0.0008.
SET accelStartThreshold TO 0.0010.

SET apsisTolerance TO 10.
SET inclinationTolerance TO 0.001.
SET planeCaptureTolerance TO 0.001.
SET captureHoldTime TO 0.75.

SET finePitchTS TO 4.
SET fineYawTS TO 6.

SET originalPitchTS TO STEERINGMANAGER:PITCHTS.
SET originalYawTS TO STEERINGMANAGER:YAWTS.
SET steeringFineTuned TO FALSE.

SET terminalMaxTime TO 360.
SET engineFailureHoldTime TO 2.

// ======================================================
// STATE FLAGS
// ======================================================

SET boosterBurnout TO FALSE.
SET boosterDropped TO FALSE.
SET fairingDeployed TO FALSE.
SET ascentDone TO FALSE.

SET terminalComplete TO FALSE.
SET terminalFailed TO FALSE.

SET fineLatched TO FALSE.

SET captureActive TO FALSE.
SET captureStartMET TO 0.

SET upperCrossAccelFiltered TO 0.
SET terminalCrossAccelFiltered TO 0.

SET lowDvStart TO -1.

SET throttleCmd TO 0.
SET pitchCmd TO 90.

SET thrustActive TO TRUE.

// ======================================================
// LOG FILES
// ======================================================

SET flightLog TO "0:/sv59flight.csv".
SET guidanceLog TO "0:/sv59guidance.csv".
SET ascentLog TO "0:/sv59ascent.csv".

IF EXISTS(flightLog) {
    DELETEPATH(flightLog).
}.

IF EXISTS(guidanceLog) {
    DELETEPATH(guidanceLog).
}.

IF EXISTS(ascentLog) {
    DELETEPATH(ascentLog).
}.

LOG
"MET,event,alt_m,lat_deg,inc_deg,surfspd_mps,orbspd_mps,vertspeed_mps,ap_m,pe_m,eta_ap_s,mass_t,throttle,dv_mps,q_atm"
TO flightLog.

LOG
"MET,mode,actuator,alt_m,inc_deg,plane_angle_err_deg,cross_pos_m,cross_vel_mps,cross_target_vel_mps,cross_accel_cmd_mps2,cross_trim_yaw_deg,radial_vel_mps,tangential_vel_mps,circular_vel_mps,tangential_error_mps,tgo_s,natural_radial_accel,radial_req_accel,tangential_req_accel,radial_alloc_accel,tangential_alloc_accel,max_accel,base_command_accel,total_command_accel,throttle,ap_m,pe_m,ap_error_m,pe_error_m,fine_latched,capture,steer_angle_err_deg"
TO guidanceLog.

LOG
"MET,alt_m,inc_deg,plane_angle_err_deg,cross_pos_m,cross_vel_mps,cross_target_vel_mps,cross_accel_cmd_mps2,cross_trim_yaw_deg,pitch_cmd_deg,throttle,q_atm,ap_m,eta_ap_s,surfspd_mps,radial_vel_mps,tangential_vel_mps,steer_angle_err_deg"
TO ascentLog.

// ======================================================
// LOGGER
// ======================================================

FUNCTION logState {

    PARAMETER eventName.

    LOG
        ROUND(MISSIONTIME,3) + "," +
        eventName + "," +
        ROUND(SHIP:ALTITUDE,3) + "," +
        ROUND(SHIP:LATITUDE,7) + "," +
        ROUND(SHIP:OBT:INCLINATION,7) + "," +
        ROUND(SHIP:VELOCITY:SURFACE:MAG,3) + "," +
        ROUND(SHIP:VELOCITY:ORBIT:MAG,3) + "," +
        ROUND(SHIP:VERTICALSPEED,3) + "," +
        ROUND(SHIP:OBT:APOAPSIS,3) + "," +
        ROUND(SHIP:OBT:PERIAPSIS,3) + "," +
        ROUND(ETA:APOAPSIS,3) + "," +
        ROUND(SHIP:MASS,5) + "," +
        ROUND(throttleCmd,7) + "," +
        ROUND(SHIP:DELTAV:CURRENT,3) + "," +
        ROUND(SHIP:Q,7)
        TO flightLog.
}.

// ======================================================
// FAIRING
// ======================================================

FUNCTION checkFairing {

    IF NOT fairingDeployed
       AND SHIP:ALTITUDE >= fairingMinAlt
       AND SHIP:Q <= fairingMaxQ {

        TOGGLE AG1.
        SET fairingDeployed TO TRUE.
        logState("FAIRING_JETTISON").
    }.
}.

// ======================================================
// BUILD TARGET ORBITAL PLANE
// ======================================================

SET launchLat TO SHIP:LATITUDE.
SET launchUp TO SHIP:UP:VECTOR.
SET launchNorth TO SHIP:NORTH:VECTOR.
SET launchEast TO HEADING(90,0):VECTOR.

SET poleHat TO
    (launchUp * SIN(launchLat))
    +
    (launchNorth * COS(launchLat)).

SET poleHat TO poleHat:NORMALIZED.

SET eqRadVec TO
    launchUp -
    (poleHat * VDOT(launchUp,poleHat)).

SET eqRadHat TO eqRadVec:NORMALIZED.
SET eqEastHat TO launchEast:NORMALIZED.

SET planeInclination TO targetInclination.
SET desiredEastSign TO 1.

IF targetInclination > 90 {

    SET planeInclination TO
        180 -
        targetInclination.

    SET desiredEastSign TO -1.
}.

SET sinPlaneI TO SIN(planeInclination).
SET cosPlaneI TO COS(planeInclination).

IF ABS(sinPlaneI) < 0.000001 {

    SET targetPlaneNormal TO poleHat.

    SET rawAlong TO
        VCRS(
            targetPlaneNormal,
            launchUp
        ).

    SET alongCrossSign TO 1.

    IF rawAlong:MAG > 0.000001 {

        SET rawAlong TO rawAlong:NORMALIZED.

        IF VDOT(rawAlong,launchEast) *
           desiredEastSign < 0 {

            SET alongCrossSign TO -1.
        }.
    }.

} ELSE {

    SET qDot TO
        -(cosPlaneI * SIN(launchLat))
        /
        (sinPlaneI * COS(launchLat)).

    IF qDot > 1 {
        SET qDot TO 1.
    }.

    IF qDot < -1 {
        SET qDot TO -1.
    }.

    SET qPerpSquared TO
        1 -
        qDot^2.

    IF qPerpSquared < 0 {
        SET qPerpSquared TO 0.
    }.

    SET qPerp TO SQRT(qPerpSquared).

    SET q1 TO
        (eqRadHat * qDot)
        +
        (eqEastHat * qPerp).

    SET h1 TO
        (poleHat * cosPlaneI)
        +
        (q1 * sinPlaneI).

    SET h1 TO h1:NORMALIZED.

    SET q2 TO
        (eqRadHat * qDot)
        -
        (eqEastHat * qPerp).

    SET h2 TO
        (poleHat * cosPlaneI)
        +
        (q2 * sinPlaneI).

    SET h2 TO h2:NORMALIZED.

    SET rawAlong1 TO
        VCRS(
            h1,
            launchUp
        ).

    SET rawAlong2 TO
        VCRS(
            h2,
            launchUp
        ).

    SET sign1 TO 1.
    SET sign2 TO 1.

    IF rawAlong1:MAG > 0.000001 {

        SET rawAlong1 TO rawAlong1:NORMALIZED.

        IF VDOT(rawAlong1,launchEast) *
           desiredEastSign < 0 {

            SET sign1 TO -1.
            SET rawAlong1 TO -rawAlong1.
        }.
    }.

    IF rawAlong2:MAG > 0.000001 {

        SET rawAlong2 TO rawAlong2:NORMALIZED.

        IF VDOT(rawAlong2,launchEast) *
           desiredEastSign < 0 {

            SET sign2 TO -1.
            SET rawAlong2 TO -rawAlong2.
        }.
    }.

    SET north1 TO VDOT(rawAlong1,launchNorth).
    SET north2 TO VDOT(rawAlong2,launchNorth).

    IF planeBranch = "ASCENDING" {

        IF north1 >= north2 {

            SET targetPlaneNormal TO h1.
            SET alongCrossSign TO sign1.

        } ELSE {

            SET targetPlaneNormal TO h2.
            SET alongCrossSign TO sign2.
        }.

    } ELSE {

        IF north1 <= north2 {

            SET targetPlaneNormal TO h1.
            SET alongCrossSign TO sign1.

        } ELSE {

            SET targetPlaneNormal TO h2.
            SET alongCrossSign TO sign2.
        }.
    }.
}.

// ======================================================
// FREEZE TARGET PLANE IN AN INERTIAL BASIS
//
// Raw vectors cannot safely be stored as celestial
// directions because SHIP-RAW changes.  Store the target
// normal as three scalar coefficients relative to:
//
//   1) body rotation pole
//   2) Solar Prime projected into the equatorial plane
//   3) the orthogonal equatorial side axis
//
// SOLARPRIMEVECTOR is fixed to the firmament and
// BODY:ANGULARVEL supplies the body's inertial pole.
// Rebuilding from these each tick keeps the plane fixed
// in inertial space while Kerbin rotates underneath it.
// ======================================================

SET initialTargetPlaneNormal TO
    targetPlaneNormal:NORMALIZED.

SET inertialPole0 TO
    SHIP:BODY:ANGULARVEL.

IF inertialPole0:MAG < 0.0000001 {
    SET inertialPole0 TO poleHat.
} ELSE {
    SET inertialPole0 TO inertialPole0:NORMALIZED.
}.

SET inertialPrimeRaw0 TO
    SOLARPRIMEVECTOR -
    (
        inertialPole0 *
        VDOT(
            SOLARPRIMEVECTOR,
            inertialPole0
        )
    ).

IF inertialPrimeRaw0:MAG < 0.000001 {

    SET inertialPrimeRaw0 TO
        launchEast -
        (
            inertialPole0 *
            VDOT(
                launchEast,
                inertialPole0
            )
        ).
}.

SET inertialPrime0 TO
    inertialPrimeRaw0:NORMALIZED.

SET inertialSide0 TO
    VCRS(
        inertialPole0,
        inertialPrime0
    ):NORMALIZED.

SET targetPrimeCoeff TO
    VDOT(
        initialTargetPlaneNormal,
        inertialPrime0
    ).

SET targetSideCoeff TO
    VDOT(
        initialTargetPlaneNormal,
        inertialSide0
    ).

SET targetPoleCoeff TO
    VDOT(
        initialTargetPlaneNormal,
        inertialPole0
    ).

FUNCTION targetPlaneNow {

    LOCAL p IS
        SHIP:BODY:ANGULARVEL.

    IF p:MAG < 0.0000001 {
        SET p TO inertialPole0.
    } ELSE {
        SET p TO p:NORMALIZED.
    }.

    LOCAL primeRaw IS
        SOLARPRIMEVECTOR -
        (
            p *
            VDOT(
                SOLARPRIMEVECTOR,
                p
            )
        ).

    IF primeRaw:MAG < 0.000001 {
        SET primeRaw TO inertialPrime0.
    }.

    LOCAL primeAxis IS
        primeRaw:NORMALIZED.

    LOCAL sideAxis IS
        VCRS(
            p,
            primeAxis
        ):NORMALIZED.

    LOCAL resultVec IS
        (
            primeAxis *
            targetPrimeCoeff
        )
        +
        (
            sideAxis *
            targetSideCoeff
        )
        +
        (
            p *
            targetPoleCoeff
        ).

    RETURN resultVec:NORMALIZED.
}.

SET targetPlaneNormal TO
    targetPlaneNow().

// ======================================================
// INITIAL DESIRED ALONG-TRACK DIRECTION
// ======================================================

SET launchAlongVec TO
    VCRS(
        targetPlaneNormal,
        launchUp
    )
    *
    alongCrossSign.

IF launchAlongVec:MAG < 0.000001 {
    SET launchAlongVec TO launchEast.
}.

SET launchAlongHat TO launchAlongVec:NORMALIZED.

// ======================================================
// ROTATION-COMPENSATED LAUNCH AZIMUTH
//
// launchAlongHat is the desired INERTIAL orbit direction.
// HEADING() is surface-relative, so subtract the local
// rotational frame velocity before deriving the heading.
// ======================================================

SET launchRotationVel TO
    SHIP:VELOCITY:ORBIT -
    SHIP:VELOCITY:SURFACE.

SET desiredLaunchInertialVel TO
    launchAlongHat *
    launchPlaneReferenceSpeed.

SET desiredLaunchSurfaceVel TO
    desiredLaunchInertialVel -
    launchRotationVel.

SET desiredLaunchSurfaceVel TO
    desiredLaunchSurfaceVel -
    (
        launchUp *
        VDOT(
            desiredLaunchSurfaceVel,
            launchUp
        )
    ).

IF desiredLaunchSurfaceVel:MAG <
   0.000001 {

    SET desiredLaunchSurfaceVel TO
        launchAlongHat.
}.

SET launchSurfaceHat TO
    desiredLaunchSurfaceVel:NORMALIZED.

SET launchNorthComponent TO
    VDOT(
        launchSurfaceHat,
        launchNorth
    ).

SET launchEastComponent TO
    VDOT(
        launchSurfaceHat,
        launchEast
    ).

SET launchAzimuth TO
    ARCTAN2(
        launchEastComponent,
        launchNorthComponent
    ).

IF launchAzimuth < 0 {
    SET launchAzimuth TO launchAzimuth + 360.
}.

SET guidanceAzimuth TO
    launchAzimuth.

// ======================================================
// MISSION SUMMARY
// ======================================================

CLEARSCREEN.

PRINT "===== SV-5.9 MISSION =====".
PRINT "".
PRINT "TARGET ALT: " + ROUND(orbitTarget / 1000,2) + " km".
PRINT "TARGET INC: " + ROUND(targetInclination,3) + " deg".
PRINT "PLANE BRANCH: " + planeBranch.
PRINT "LAUNCH AZ: " + ROUND(launchAzimuth,3) + " deg".
PRINT "".
PRINT "LAUNCHING IN 5 SECONDS".

WAIT 2.

// ======================================================
// PRELAUNCH
// ======================================================

SET throttleCmd TO 1.

LOCK THROTTLE TO throttleCmd.
LOCK STEERING TO HEADING(launchAzimuth,90).

PRINT "T-3".
WAIT 1.
PRINT "T-2".
WAIT 1.
PRINT "T-1".
WAIT 1.

logState("PRELAUNCH").

PRINT "IGNITION".

STAGE.

WAIT 0.2.

logState("LIFTOFF").

SET lastLog TO MISSIONTIME.

// ======================================================
// BOOSTER ASCENT
// ======================================================

UNTIL boosterBurnout {

    SET surfSpd TO SHIP:VELOCITY:SURFACE:MAG.

    // Recompute the surface-relative heading that follows
    // the fixed target inertial plane at the current position.

    SET targetPlaneNormal TO
        targetPlaneNow().

    SET planeUp TO SHIP:UP:VECTOR.
    SET planeNorth TO SHIP:NORTH:VECTOR.
    SET planeEast TO HEADING(90,0):VECTOR.

    SET planeAlongVec TO
        VCRS(
            targetPlaneNormal,
            planeUp
        )
        *
        alongCrossSign.

    IF planeAlongVec:MAG < 0.000001 {
        SET planeAlongVec TO launchAlongHat.
    }.

    SET planeAlongHat TO
        planeAlongVec:NORMALIZED.

    // --------------------------------------------------
    // NOMINAL TARGET-PLANE TANGENT
    // --------------------------------------------------
    //
    // Diagnostics still measure geometric plane position
    // and cross-plane velocity, but they do NOT command a
    // dogleg.  Residual error is trimmed gently during the
    // powered upper-stage / terminal burn.

    SET planeOrbitVel TO
        SHIP:VELOCITY:ORBIT.

    SET planeRadialVel TO
        VDOT(
            planeOrbitVel,
            planeUp
        ).

    SET planeHorizontalVel TO
        planeOrbitVel -
        (
            planeUp *
            planeRadialVel
        ).

    SET planeHorizontalSpeed TO
        planeHorizontalVel:MAG.

    SET planePositionDot TO
        VDOT(
            planeUp,
            targetPlaneNormal
        ).

    IF planePositionDot > 1 {
        SET planePositionDot TO 1.
    }.

    IF planePositionDot < -1 {
        SET planePositionDot TO -1.
    }.

    SET ascentPlaneAngle TO
        ARCSIN(
            planePositionDot
        ).

    SET ascentPlaneErrorM TO
        (
            SHIP:BODY:RADIUS +
            SHIP:ALTITUDE
        )
        *
        ascentPlaneAngle
        *
        CONSTANT:DEGTORAD.

    SET ascentCrossAxis TO
        targetPlaneNormal -
        (
            planeUp *
            planePositionDot
        ).

    IF ascentCrossAxis:MAG <
       0.000001 {

        SET ascentCrossAxis TO
            targetPlaneNormal.
    }.

    SET ascentCrossAxis TO
        ascentCrossAxis:NORMALIZED.

    SET ascentCrossVel TO
        VDOT(
            planeOrbitVel,
            ascentCrossAxis
        ).

    SET desiredPlaneInertialVel TO
        planeAlongHat *
        launchPlaneReferenceSpeed.

    SET planeRotationVel TO
        SHIP:VELOCITY:ORBIT -
        SHIP:VELOCITY:SURFACE.

    SET desiredPlaneSurfaceVel TO
        desiredPlaneInertialVel -
        planeRotationVel.

    SET desiredPlaneSurfaceVel TO
        desiredPlaneSurfaceVel -
        (
            planeUp *
            VDOT(
                desiredPlaneSurfaceVel,
                planeUp
            )
        ).

    IF desiredPlaneSurfaceVel:MAG >
       0.000001 {

        SET desiredPlaneSurfaceHat TO
            desiredPlaneSurfaceVel:NORMALIZED.

        SET planeNorthComponent TO
            VDOT(
                desiredPlaneSurfaceHat,
                planeNorth
            ).

        SET planeEastComponent TO
            VDOT(
                desiredPlaneSurfaceHat,
                planeEast
            ).

        SET guidanceAzimuth TO
            ARCTAN2(
                planeEastComponent,
                planeNorthComponent
            ).

        IF guidanceAzimuth < 0 {

            SET guidanceAzimuth TO
                guidanceAzimuth +
                360.
        }.
    }.

    IF surfSpd < 40 {

        SET pitchCmd TO 90.

    } ELSE IF surfSpd < 100 {

        SET pitchCmd TO
            90 -
            ((surfSpd - 40) / 60) * 8.

    } ELSE IF surfSpd < 220 {

        SET pitchCmd TO
            82 -
            ((surfSpd - 100) / 120) * 17.

    } ELSE IF surfSpd < 400 {

        SET pitchCmd TO
            65 -
            ((surfSpd - 220) / 180) * 18.

    } ELSE IF surfSpd < 650 {

        SET pitchCmd TO
            47 -
            ((surfSpd - 400) / 250) * 12.

    } ELSE {

        // Above 650 m/s retain the closed-loop plane
        // azimuth and let pitch relax with flight path.

        SET fpaBoost TO 0.

        IF surfSpd > 1 {

            SET fpaBoostRatio TO
                SHIP:VERTICALSPEED /
                surfSpd.

            IF fpaBoostRatio > 1 {
                SET fpaBoostRatio TO 1.
            }.

            IF fpaBoostRatio < -1 {
                SET fpaBoostRatio TO -1.
            }.

            SET fpaBoost TO
                ARCSIN(
                    fpaBoostRatio
                ).
        }.

        SET pitchCmd TO
            fpaBoost.
    }.

    LOCK STEERING TO
        HEADING(
            guidanceAzimuth,
            pitchCmd
        ).

    SET throttleCmd TO 1.

    IF SHIP:Q > 0.35 {
        SET throttleCmd TO 0.85.
    }.

    IF SHIP:Q > 0.45 {
        SET throttleCmd TO 0.65.
    }.

    LOCK THROTTLE TO throttleCmd.

    PRINT "BOOSTER ASCENT        " AT(0,7).
    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km      " AT(0,10).
    PRINT "AZ: " + ROUND(guidanceAzimuth,2) + " deg      " AT(0,11).
    PRINT "PLN: " + ROUND(ascentPlaneErrorM,1) + " m       " AT(0,12).
    PRINT "XVEL: " + ROUND(ascentCrossVel,1) + " m/s      " AT(0,13).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,2) + " km      " AT(0,14).
    PRINT "Q: " + ROUND(SHIP:Q,3) + " atm      " AT(0,15).

    IF MISSIONTIME - lastLog >= 0.5 {

        logState("BOOSTER_ASCENT").
        SET lastLog TO MISSIONTIME.
    }.

    IF SHIP:AVAILABLETHRUST < 0.1
       AND MISSIONTIME > 5 {

        SET boosterBurnout TO TRUE.
        SET throttleCmd TO 0.
        LOCK THROTTLE TO throttleCmd.
        LOCK STEERING TO SRFPROGRADE.
        logState("BOOSTER_BURNOUT").
    }.

    WAIT 0.02.
}.

// ======================================================
// BOOSTER COAST / SEPARATION
// ======================================================

CLEARSCREEN.

PRINT "===== BOOSTER BURNOUT =====".
PRINT "".
PRINT "COASTING TO SAFE SEPARATION".

SET lastLog TO MISSIONTIME.

UNTIL boosterDropped {

    SET throttleCmd TO 0.

    LOCK THROTTLE TO throttleCmd.
    LOCK STEERING TO SRFPROGRADE.

    IF MISSIONTIME - lastLog >= 0.25 {

        logState("BOOSTER_COAST").
        SET lastLog TO MISSIONTIME.
    }.

    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km       " AT(0,8).
    PRINT "Q: " + ROUND(SHIP:Q,4) + " atm      " AT(0,9).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,2) + " km       " AT(0,10).

    IF SHIP:ALTITUDE >= sepMinAlt
       AND SHIP:Q <= sepMaxQ {

        logState("PRE_SEPARATION").
        STAGE.
        SET boosterDropped TO TRUE.
        WAIT 0.2.
        logState("BOOSTER_SEPARATED").
    }.

    WAIT 0.02.
}.

// ======================================================
// BOOSTER CLEARANCE
// ======================================================

SET throttleCmd TO 0.

LOCK THROTTLE TO throttleCmd.
LOCK STEERING TO SRFPROGRADE.

WAIT 1.8.

IF SHIP:AVAILABLETHRUST < 0.1 {

    STAGE.
    WAIT 0.25.
}.

logState("UPPER_ENGINE_READY").

// ======================================================
// UPPER-STAGE ASCENT
//
// Inertial target-plane pitch guidance + small normal trim.
// The trim is a yaw bias on an existing powered burn,
// never an independent plane-change command.
// ======================================================

CLEARSCREEN.

SET lastLog TO MISSIONTIME.
SET lastAscentLog TO MISSIONTIME.

UNTIL ascentDone {

    SET surfSpd TO
        SHIP:VELOCITY:SURFACE:MAG.

    SET fpa TO 0.

    SET targetPlaneNormal TO
        targetPlaneNow().

    SET planeUp TO
        SHIP:UP:VECTOR.

    SET planeAlongVec TO
        VCRS(
            targetPlaneNormal,
            planeUp
        )
        *
        alongCrossSign.

    IF planeAlongVec:MAG <
       0.000001 {

        SET planeAlongVec TO
            launchAlongHat.
    }.

    SET planeAlongHat TO
        planeAlongVec:NORMALIZED.

    SET orbitVelVec TO
        SHIP:VELOCITY:ORBIT.

    SET radialVel TO
        VDOT(
            orbitVelVec,
            planeUp
        ).

    SET tangentialVelVec TO
        orbitVelVec -
        (
            planeUp *
            radialVel
        ).

    SET tangentialVel TO
        tangentialVelVec:MAG.

    // --------------------------------------------------
    // CURRENT ORBITAL-PLANE ERROR
    // --------------------------------------------------

    SET currentNormalVec TO
        VCRS(
            orbitVelVec,
            planeUp
        ).

    IF currentNormalVec:MAG >
       0.000001 {

        SET currentOrbitNormal TO
            currentNormalVec:NORMALIZED.

    } ELSE {

        SET currentOrbitNormal TO
            targetPlaneNormal.
    }.

    IF VDOT(
        currentOrbitNormal,
        targetPlaneNormal
       ) < 0 {

        SET currentOrbitNormal TO
            -currentOrbitNormal.
    }.

    SET planeAngleError TO
        VANG(
            currentOrbitNormal,
            targetPlaneNormal
        ).

    SET planeDvEstimate TO
        2 *
        tangentialVel *
        SIN(
            planeAngleError /
            2
        ).

    // Probe +/- current orbit normal to select the yaw
    // direction that locally reduces target-plane error.

    SET plusProbeVel TO
        orbitVelVec +
        (
            currentOrbitNormal *
            planeProbeDv
        ).

    SET plusProbeNormal TO
        VCRS(
            plusProbeVel,
            planeUp
        ).

    IF plusProbeNormal:MAG >
       0.000001 {

        SET plusProbeNormal TO
            plusProbeNormal:NORMALIZED.

    } ELSE {

        SET plusProbeNormal TO
            currentOrbitNormal.
    }.

    IF VDOT(
        plusProbeNormal,
        targetPlaneNormal
       ) < 0 {

        SET plusProbeNormal TO
            -plusProbeNormal.
    }.

    SET plusProbeAngle TO
        VANG(
            plusProbeNormal,
            targetPlaneNormal
        ).

    SET minusProbeVel TO
        orbitVelVec -
        (
            currentOrbitNormal *
            planeProbeDv
        ).

    SET minusProbeNormal TO
        VCRS(
            minusProbeVel,
            planeUp
        ).

    IF minusProbeNormal:MAG >
       0.000001 {

        SET minusProbeNormal TO
            minusProbeNormal:NORMALIZED.

    } ELSE {

        SET minusProbeNormal TO
            currentOrbitNormal.
    }.

    IF VDOT(
        minusProbeNormal,
        targetPlaneNormal
       ) < 0 {

        SET minusProbeNormal TO
            -minusProbeNormal.
    }.

    SET minusProbeAngle TO
        VANG(
            minusProbeNormal,
            targetPlaneNormal
        ).

    SET planeCorrectionUnit TO
        currentOrbitNormal.

    SET bestProbeAngle TO
        plusProbeAngle.

    IF minusProbeAngle <
       plusProbeAngle {

        SET planeCorrectionUnit TO
            -currentOrbitNormal.

        SET bestProbeAngle TO
            minusProbeAngle.
    }.

    SET planeImprovementPerDv TO
        (
            planeAngleError -
            bestProbeAngle
        )
        /
        planeProbeDv.

    IF planeImprovementPerDv < 0 {
        SET planeImprovementPerDv TO 0.
    }.

    SET idealPlaneEffectiveness TO 0.

    IF tangentialVel > 1 {

        SET idealPlaneEffectiveness TO
            57.2957795 /
            tangentialVel.
    }.

    SET planeEffectivenessRatio TO 0.

    IF idealPlaneEffectiveness >
       0.0000001 {

        SET planeEffectivenessRatio TO
            planeImprovementPerDv /
            idealPlaneEffectiveness.
    }.

    IF planeEffectivenessRatio > 1 {
        SET planeEffectivenessRatio TO 1.
    }.

    IF planeEffectivenessRatio < 0 {
        SET planeEffectivenessRatio TO 0.
    }.

    // Local dV required at the current geometry.
    // This is the key SV-5.9 gain fix.  SV-5.5 multiplied
    // ideal plane dV by effectiveness, which REDUCED the
    // command exactly when geometry made each m/s less
    // effective.  The numerical derivative already tells
    // us how much orbital-normal angle each m/s buys here.

    SET localPlaneDvEstimate TO
        planeDvEstimate.

    IF planeImprovementPerDv >
       0.0000001 {

        SET localPlaneDvEstimate TO
            planeAngleError /
            planeImprovementPerDv.
    }.

    // --------------------------------------------------
    // PITCH / APOAPSIS GUIDANCE
    // --------------------------------------------------

    IF surfSpd > 1 {

        SET fpaRatio TO
            SHIP:VERTICALSPEED /
            surfSpd.

        IF fpaRatio > 1 {
            SET fpaRatio TO 1.
        }.

        IF fpaRatio < -1 {
            SET fpaRatio TO -1.
        }.

        SET fpa TO
            ARCSIN(
                fpaRatio
            ).
    }.

    IF SHIP:Q > 0.015 {

        SET pitchCmd TO fpa.

    } ELSE {

        SET etaError TO
            etaTarget -
            ETA:APOAPSIS.

        SET pitchOffset TO
            etaError *
            0.20.

        IF pitchOffset < -10 {
            SET pitchOffset TO -10.
        }.

        IF pitchOffset > 10 {
            SET pitchOffset TO 10.
        }.

        SET pitchCmd TO
            fpa +
            pitchOffset.

        IF pitchCmd < 0 {
            SET pitchCmd TO 0.
        }.

        IF pitchCmd > 45 {
            SET pitchCmd TO 45.
        }.

        IF SHIP:OBT:APOAPSIS <
           60000
           AND
           pitchCmd < 12 {

            SET pitchCmd TO 12.
        }.

        IF SHIP:OBT:APOAPSIS >=
           60000
           AND
           SHIP:OBT:APOAPSIS <
           70000
           AND
           pitchCmd < 6 {

            SET pitchCmd TO 6.
        }.
    }.

    // --------------------------------------------------
    // THROTTLE / APOAPSIS CUTOFF
    // --------------------------------------------------

    SET throttleCmd TO 1.

    IF SHIP:Q > 0.05 {

        SET throttleCmd TO 0.35.

    } ELSE IF SHIP:Q > 0.03 {

        SET throttleCmd TO 0.50.

    } ELSE IF SHIP:Q > 0.015 {

        SET throttleCmd TO 0.70.
    }.

    SET apReserve TO
        SHIP:Q *
        20000.

    IF apReserve > 750 {
        SET apReserve TO 750.
    }.

    IF apReserve < 0 {
        SET apReserve TO 0.
    }.

    SET cutoffApTarget TO
        orbitTarget +
        apReserve.

    SET apError TO
        cutoffApTarget -
        SHIP:OBT:APOAPSIS.

    IF apError < 3000
       AND
       throttleCmd > 0.55 {

        SET throttleCmd TO 0.55.
    }.

    IF apError < 1200
       AND
       throttleCmd > 0.30 {

        SET throttleCmd TO 0.30.
    }.

    IF apError < 400
       AND
       throttleCmd > 0.15 {

        SET throttleCmd TO 0.15.
    }.

    // --------------------------------------------------
    // INERTIAL IN-PLANE STEERING + LIMITED YAW TRIM
    // --------------------------------------------------

    SET baseDir TO
        (
            planeAlongHat *
            COS(
                pitchCmd
            )
        )
        +
        (
            planeUp *
            SIN(
                pitchCmd
            )
        ).

    SET baseDir TO
        baseDir:NORMALIZED.

    SET maxAccel TO
        SHIP:AVAILABLETHRUST /
        SHIP:MASS.

    SET poweredAccel TO
        maxAccel *
        throttleCmd.

    // --------------------------------------------------
    // DAMPED CROSS-TRACK PD TRIM
    // --------------------------------------------------

    SET planePositionDot TO
        VDOT(
            planeUp,
            targetPlaneNormal
        ).

    IF planePositionDot > 1 {
        SET planePositionDot TO 1.
    }.

    IF planePositionDot < -1 {
        SET planePositionDot TO -1.
    }.

    SET crossPositionAngle TO
        ARCSIN(
            planePositionDot
        ).

    SET crossPositionM TO
        (
            SHIP:BODY:RADIUS +
            SHIP:ALTITUDE
        )
        *
        crossPositionAngle
        *
        CONSTANT:DEGTORAD.

    SET crossTrackAxis TO
        targetPlaneNormal -
        (
            planeUp *
            planePositionDot
        ).

    IF crossTrackAxis:MAG <
       0.000001 {

        SET crossTrackAxis TO
            targetPlaneNormal.
    }.

    SET crossTrackAxis TO
        crossTrackAxis:NORMALIZED.

    SET crossVelocity TO
        VDOT(
            orbitVelVec,
            crossTrackAxis
        ).

    SET crossTargetVelocity TO
        -
        crossPositionM /
        crossTrackPositionTime.

    IF crossTargetVelocity >
       crossTrackVelocityLimit {

        SET crossTargetVelocity TO
            crossTrackVelocityLimit.
    }.

    IF crossTargetVelocity <
       -crossTrackVelocityLimit {

        SET crossTargetVelocity TO
            -crossTrackVelocityLimit.
    }.

    SET crossAccelRaw TO
        (
            crossTargetVelocity -
            crossVelocity
        )
        /
        crossTrackVelocityTime.

    SET crossAccelAllowed TO TRUE.

    IF SHIP:Q >
       upperCrossTrackMaxQ {

        SET crossAccelAllowed TO FALSE.
    }.

    IF ABS(
        STEERINGMANAGER:ANGLEERROR
       ) >
       upperCrossTrackMaxSteerError {

        SET crossAccelAllowed TO FALSE.
    }.

    IF NOT crossAccelAllowed {

        SET crossAccelRaw TO 0.
    }.

    SET upperCrossAccelFiltered TO
        upperCrossAccelFiltered
        +
        crossTrackFilterGain
        *
        (
            crossAccelRaw -
            upperCrossAccelFiltered
        ).

    SET maxCrossAccelByYaw TO
        poweredAccel *
        TAN(
            upperCrossTrackMaxYaw
        ).

    SET crossAccelCmd TO
        upperCrossAccelFiltered.

    IF crossAccelCmd >
       maxCrossAccelByYaw {

        SET crossAccelCmd TO
            maxCrossAccelByYaw.
    }.

    IF crossAccelCmd <
       -maxCrossAccelByYaw {

        SET crossAccelCmd TO
            -maxCrossAccelByYaw.
    }.

    SET desiredSteeringVec TO
        (
            baseDir *
            poweredAccel
        )
        +
        (
            crossTrackAxis *
            crossAccelCmd
        ).

    IF desiredSteeringVec:MAG >
       0.000001 {

        LOCK STEERING TO
            desiredSteeringVec.

    } ELSE {

        LOCK STEERING TO
            baseDir.
    }.

    LOCK THROTTLE TO
        throttleCmd.

    checkFairing().

    IF SHIP:OBT:APOAPSIS >=
       cutoffApTarget {

        SET ascentDone TO TRUE.

        SET throttleCmd TO 0.

        LOCK THROTTLE TO
            throttleCmd.

        logState(
            "ASCENT_CUTOFF"
        ).
    }.

    SET actualTrimYaw TO 0.

    IF poweredAccel > 0 {

        SET actualTrimYaw TO
            ARCTAN2(
                crossAccelCmd,
                poweredAccel
            ).
    }.

    IF MISSIONTIME -
       lastAscentLog >= 0.1 {

        LOG
            ROUND(MISSIONTIME,3) + "," +
            ROUND(SHIP:ALTITUDE,3) + "," +
            ROUND(SHIP:OBT:INCLINATION,7) + "," +
            ROUND(planeAngleError,7) + "," +
            ROUND(crossPositionM,3) + "," +
            ROUND(crossVelocity,5) + "," +
            ROUND(crossTargetVelocity,5) + "," +
            ROUND(crossAccelCmd,6) + "," +
            ROUND(actualTrimYaw,5) + "," +
            ROUND(pitchCmd,5) + "," +
            ROUND(throttleCmd,7) + "," +
            ROUND(SHIP:Q,7) + "," +
            ROUND(SHIP:OBT:APOAPSIS,3) + "," +
            ROUND(ETA:APOAPSIS,3) + "," +
            ROUND(surfSpd,3) + "," +
            ROUND(radialVel,5) + "," +
            ROUND(tangentialVel,5) + "," +
            ROUND(STEERINGMANAGER:ANGLEERROR,5)
            TO ascentLog.

        SET lastAscentLog TO
            MISSIONTIME.
    }.

    PRINT
        "UPPER-STAGE ASCENT     "
        AT(0,6).

    PRINT
        "ALT: " +
        ROUND(
            SHIP:ALTITUDE/1000,
            2
        ) +
        " km       "
        AT(0,9).

    PRINT
        "AP: " +
        ROUND(
            SHIP:OBT:APOAPSIS/1000,
            2
        ) +
        " km       "
        AT(0,10).

    PRINT
        "INC: " +
        ROUND(
            SHIP:OBT:INCLINATION,
            4
        ) +
        " deg      "
        AT(0,11).

    PRINT
        "PLANE: " +
        ROUND(
            planeAngleError,
            4
        ) +
        " deg      "
        AT(0,12).

    PRINT
        "YAW TRIM: " +
        ROUND(
            actualTrimYaw,
            3
        ) +
        " deg      "
        AT(0,13).

    PRINT
        "XPOS: " +
        ROUND(
            crossPositionM,
            1
        ) +
        " m        "
        AT(0,14).

    PRINT
        "XVEL: " +
        ROUND(
            crossVelocity,
            2
        ) +
        " m/s      "
        AT(0,15).

    PRINT
        "ETA AP: " +
        ROUND(
            ETA:APOAPSIS,
            1
        ) +
        " s        "
        AT(0,16).

    PRINT
        "THR: " +
        ROUND(
            throttleCmd,
            3
        ) +
        "          "
        AT(0,17).

    IF MISSIONTIME -
       lastLog >= 0.25 {

        logState(
            "UPPER_ASCENT"
        ).

        SET lastLog TO
            MISSIONTIME.
    }.

    WAIT 0.02.
}.

// ======================================================
// COAST TO NEAR VACUUM
// ======================================================

SET throttleCmd TO 0.

LOCK THROTTLE TO throttleCmd.
LOCK STEERING TO PROGRADE.

CLEARSCREEN.

PRINT "===== ASCENT COMPLETE =====".
PRINT "".
PRINT "COASTING TO TERMINAL GUIDANCE".

SET lastLog TO MISSIONTIME.

UNTIL SHIP:ALTITUDE >= 60000
      AND SHIP:Q <= 0.0005 {

    checkFairing().

    IF MISSIONTIME - lastLog >= 0.5 {

        logState("ATMOSPHERIC_COAST").
        SET lastLog TO MISSIONTIME.
    }.

    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km       " AT(0,8).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,3) + " km       " AT(0,9).
    PRINT "INC: " + ROUND(SHIP:OBT:INCLINATION,4) + " deg      " AT(0,10).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,1) + " s        " AT(0,11).

    WAIT 0.05.
}.

checkFairing().
logState("NEAR_VACUUM").

// ======================================================
// ENGINE PERFORMANCE
// ======================================================

LIST ENGINES IN engineList.

SET totalMassFlow TO 0.
SET effectiveISP TO 0.

FOR eng IN engineList {

    IF eng:IGNITION
       AND NOT eng:FLAMEOUT {

        SET oneMassFlow TO
            eng:AVAILABLETHRUST /
            (eng:ISP * CONSTANT:g0).

        SET totalMassFlow TO
            totalMassFlow +
            oneMassFlow.
    }.
}.

IF totalMassFlow > 0 {

    SET effectiveISP TO
        SHIP:AVAILABLETHRUST /
        (totalMassFlow * CONSTANT:g0).
}.

SET exhaustVelocity TO
    effectiveISP *
    CONSTANT:g0.

// ======================================================
// TERMINAL ACQUISITION
//
// Same timing architecture as the successful SV-3.3
// branch.  Plane error does not alter burn timing.
// ======================================================

CLEARSCREEN.

PRINT "===== SV-5.9 ACQUISITION =====".

SET terminalStart TO FALSE.
SET lastLog TO MISSIONTIME.

UNTIL terminalStart {

    SET upVec TO
        SHIP:UP:VECTOR.

    SET orbitVelVec TO
        SHIP:VELOCITY:ORBIT.

    SET radialVel TO
        VDOT(
            orbitVelVec,
            upVec
        ).

    SET tangentialVelVec TO
        orbitVelVec -
        (
            upVec *
            radialVel
        ).

    SET tangentialVel TO
        tangentialVelVec:MAG.

    SET radiusNow TO
        SHIP:BODY:RADIUS +
        SHIP:ALTITUDE.

    SET circularVelNow TO
        SQRT(
            SHIP:BODY:MU /
            radiusNow
        ).

    SET tangentialError TO
        circularVelNow -
        tangentialVel.

    SET dvEstimate TO
        SQRT(
            tangentialError^2 +
            radialVel^2
        ).

    SET burnEstimate TO 0.
    SET halfDvLead TO 0.

    IF dvEstimate > 0
       AND totalMassFlow > 0 {

        SET finalMassEstimate TO
            SHIP:MASS /
            (
                CONSTANT:e ^
                (
                    dvEstimate /
                    exhaustVelocity
                )
            ).

        SET burnEstimate TO
            (
                SHIP:MASS -
                finalMassEstimate
            )
            /
            totalMassFlow.

        SET halfDvMass TO
            SHIP:MASS /
            (
                CONSTANT:e ^
                (
                    0.5 *
                    dvEstimate /
                    exhaustVelocity
                )
            ).

        SET halfDvLead TO
            (
                SHIP:MASS -
                halfDvMass
            )
            /
            totalMassFlow.
    }.

    SET startLead TO
        halfDvLead +
        startLeadBias.

    PRINT
        "ALT: " +
        ROUND(
            SHIP:ALTITUDE/1000,
            3
        ) +
        " km      "
        AT(0,6).

    PRINT
        "INC: " +
        ROUND(
            SHIP:OBT:INCLINATION,
            5
        ) +
        " deg      "
        AT(0,7).

    PRINT
        "RAD VEL: " +
        ROUND(
            radialVel,
            2
        ) +
        " m/s     "
        AT(0,8).

    PRINT
        "TAN ERR: " +
        ROUND(
            tangentialError,
            1
        ) +
        " m/s     "
        AT(0,9).

    PRINT
        "FULL BURN: " +
        ROUND(
            burnEstimate,
            2
        ) +
        " s       "
        AT(0,11).

    PRINT
        "START LEAD: " +
        ROUND(
            startLead,
            2
        ) +
        " s       "
        AT(0,12).

    PRINT
        "ETA AP: " +
        ROUND(
            ETA:APOAPSIS,
            2
        ) +
        " s       "
        AT(0,13).

    IF ETA:APOAPSIS <=
       startLead {

        SET terminalStart TO TRUE.
    }.

    IF MISSIONTIME -
       lastLog >= 0.5 {

        logState(
            "TERMINAL_COAST"
        ).

        SET lastLog TO
            MISSIONTIME.
    }.

    WAIT 0.02.
}.

// ======================================================
// SV-5.9 TERMINAL
//
// Proven radial/tangential SV-3.3 controller with a small
// normal component layered on as a yaw bias.  The normal
// component is capped as a fraction of the burn the orbit
// controller already wants.  When the orbit burn stops,
// plane correction stops too.
// ======================================================

CLEARSCREEN.

PRINT "===== SV-5.9 TERMINAL =====".

SET terminalStartMET TO
    MISSIONTIME.

SET terminalCrossAccelFiltered TO 0.

SET guidanceVec TO
    SHIP:PROGRADE:VECTOR.

SET steeringTargetVec TO
    guidanceVec.

SET throttleCmd TO 0.

LOCK STEERING TO
    steeringTargetVec.

LOCK THROTTLE TO
    throttleCmd.

SET lastFlightLog TO
    MISSIONTIME.

SET lastGuidanceLog TO
    MISSIONTIME.

UNTIL terminalComplete
      OR terminalFailed {

    SET targetPlaneNormal TO
        targetPlaneNow().

    SET upVec TO
        SHIP:UP:VECTOR.

    SET orbitVelVec TO
        SHIP:VELOCITY:ORBIT.

    SET radialVel TO
        VDOT(
            orbitVelVec,
            upVec
        ).

    SET tangentialVelVec TO
        orbitVelVec -
        (
            upVec *
            radialVel
        ).

    SET tangentialVel TO
        tangentialVelVec:MAG.

    IF tangentialVel > 1 {

        SET tangentialUnit TO
            tangentialVelVec:NORMALIZED.

    } ELSE {

        SET tangentialUnit TO
            SHIP:PROGRADE:VECTOR.
    }.

    SET currentAp TO
        SHIP:OBT:APOAPSIS.

    SET currentPe TO
        SHIP:OBT:PERIAPSIS.

    SET currentInclination TO
        SHIP:OBT:INCLINATION.

    SET apOrbitError TO
        orbitTarget -
        currentAp.

    SET peOrbitError TO
        orbitTarget -
        currentPe.

    SET radiusNow TO
        SHIP:BODY:RADIUS +
        SHIP:ALTITUDE.

    SET altitudeError TO
        orbitTarget -
        SHIP:ALTITUDE.

    SET circularVelNow TO
        SQRT(
            SHIP:BODY:MU /
            radiusNow
        ).

    SET tangentialError TO
        circularVelNow -
        tangentialVel.

    // --------------------------------------------------
    // ORBITAL-PLANE ERROR / TRIM DIRECTION
    // --------------------------------------------------

    SET currentNormalVec TO
        VCRS(
            orbitVelVec,
            upVec
        ).

    IF currentNormalVec:MAG >
       0.000001 {

        SET currentOrbitNormal TO
            currentNormalVec:NORMALIZED.

    } ELSE {

        SET currentOrbitNormal TO
            targetPlaneNormal.
    }.

    IF VDOT(
        currentOrbitNormal,
        targetPlaneNormal
       ) < 0 {

        SET currentOrbitNormal TO
            -currentOrbitNormal.
    }.

    SET planeAngleError TO
        VANG(
            currentOrbitNormal,
            targetPlaneNormal
        ).

    SET planeDvEstimate TO
        2 *
        tangentialVel *
        SIN(
            planeAngleError /
            2
        ).

    SET plusProbeVel TO
        orbitVelVec +
        (
            currentOrbitNormal *
            planeProbeDv
        ).

    SET plusProbeNormal TO
        VCRS(
            plusProbeVel,
            upVec
        ).

    IF plusProbeNormal:MAG >
       0.000001 {

        SET plusProbeNormal TO
            plusProbeNormal:NORMALIZED.

    } ELSE {

        SET plusProbeNormal TO
            currentOrbitNormal.
    }.

    IF VDOT(
        plusProbeNormal,
        targetPlaneNormal
       ) < 0 {

        SET plusProbeNormal TO
            -plusProbeNormal.
    }.

    SET plusProbeAngle TO
        VANG(
            plusProbeNormal,
            targetPlaneNormal
        ).

    SET minusProbeVel TO
        orbitVelVec -
        (
            currentOrbitNormal *
            planeProbeDv
        ).

    SET minusProbeNormal TO
        VCRS(
            minusProbeVel,
            upVec
        ).

    IF minusProbeNormal:MAG >
       0.000001 {

        SET minusProbeNormal TO
            minusProbeNormal:NORMALIZED.

    } ELSE {

        SET minusProbeNormal TO
            currentOrbitNormal.
    }.

    IF VDOT(
        minusProbeNormal,
        targetPlaneNormal
       ) < 0 {

        SET minusProbeNormal TO
            -minusProbeNormal.
    }.

    SET minusProbeAngle TO
        VANG(
            minusProbeNormal,
            targetPlaneNormal
        ).

    SET planeCorrectionUnit TO
        currentOrbitNormal.

    SET bestProbeAngle TO
        plusProbeAngle.

    IF minusProbeAngle <
       plusProbeAngle {

        SET planeCorrectionUnit TO
            -currentOrbitNormal.

        SET bestProbeAngle TO
            minusProbeAngle.
    }.

    SET planeImprovementPerDv TO
        (
            planeAngleError -
            bestProbeAngle
        )
        /
        planeProbeDv.

    IF planeImprovementPerDv < 0 {
        SET planeImprovementPerDv TO 0.
    }.

    SET idealPlaneEffectiveness TO 0.

    IF tangentialVel > 1 {

        SET idealPlaneEffectiveness TO
            57.2957795 /
            tangentialVel.
    }.

    SET planeEffectivenessRatio TO 0.

    IF idealPlaneEffectiveness >
       0.0000001 {

        SET planeEffectivenessRatio TO
            planeImprovementPerDv /
            idealPlaneEffectiveness.
    }.

    IF planeEffectivenessRatio > 1 {
        SET planeEffectivenessRatio TO 1.
    }.

    IF planeEffectivenessRatio < 0 {
        SET planeEffectivenessRatio TO 0.
    }.

    SET localPlaneDvEstimate TO
        planeDvEstimate.

    IF planeImprovementPerDv >
       0.0000001 {

        SET localPlaneDvEstimate TO
            planeAngleError /
            planeImprovementPerDv.
    }.

    // --------------------------------------------------
    // PROVEN SV-3.3 RADIAL / TANGENTIAL CONTROLLER
    // --------------------------------------------------

    IF NOT fineLatched
       AND
       ABS(
           tangentialError
       ) <=
       fineLatchTanError {

        SET fineLatched TO TRUE.

        SET STEERINGMANAGER:PITCHTS TO
            finePitchTS.

        SET STEERINGMANAGER:YAWTS TO
            fineYawTS.

        STEERINGMANAGER:RESETPIDS().

        SET steeringFineTuned TO TRUE.

        logState(
            "FINE_MODE_LATCH"
        ).
    }.

    SET positiveTanError TO
        tangentialError.

    IF positiveTanError < 0 {
        SET positiveTanError TO 0.
    }.

    SET tGo TO 0.

    IF positiveTanError > 0
       AND totalMassFlow > 0 {

        SET tgoFinalMass TO
            SHIP:MASS /
            (
                CONSTANT:e ^
                (
                    positiveTanError /
                    exhaustVelocity
                )
            ).

        SET tGo TO
            (
                SHIP:MASS -
                tgoFinalMass
            )
            /
            totalMassFlow.
    }.

    SET gravityAccel TO
        SHIP:BODY:MU /
        (
            radiusNow^2
        ).

    SET centrifugalAccel TO
        (
            tangentialVel^2
        )
        /
        radiusNow.

    SET naturalRadialAccel TO
        centrifugalAccel -
        gravityAccel.

    IF NOT fineLatched {

        SET radialGuidanceTime TO
            tGo.

        IF radialGuidanceTime <
           radialTgoFloor {

            SET radialGuidanceTime TO
                radialTgoFloor.
        }.

        SET desiredRadialAccel TO
            (
                6 *
                altitudeError /
                (
                    radialGuidanceTime^2
                )
            )
            -
            (
                4 *
                radialVel /
                radialGuidanceTime
            ).

        IF desiredRadialAccel >
           radialAccelLimit {

            SET desiredRadialAccel TO
                radialAccelLimit.
        }.

        IF desiredRadialAccel <
           -radialAccelLimit {

            SET desiredRadialAccel TO
                -radialAccelLimit.
        }.

    } ELSE {

        SET radialTarget TO
            altitudeError /
            fineRadialTimeConstant.

        IF radialTarget >
           radialVelMax {

            SET radialTarget TO
                radialVelMax.
        }.

        IF radialTarget <
           -radialVelMax {

            SET radialTarget TO
                -radialVelMax.
        }.

        SET desiredRadialAccel TO
            fineRadialVelGain *
            (
                radialTarget -
                radialVel
            ).
    }.

    SET radialReqAccel TO
        desiredRadialAccel -
        naturalRadialAccel.

    IF fineLatched {

        SET tangentialGain TO
            fineTangentialGain.

    } ELSE {

        SET tangentialGain TO
            coarseTangentialGain.
    }.

    SET desiredTangentialAccel TO
        tangentialGain *
        tangentialError.

    SET tangentialCoupling TO
        (
            radialVel *
            tangentialVel
        )
        /
        radiusNow.

    SET tanReqAccel TO
        desiredTangentialAccel +
        tangentialCoupling.

    IF fineLatched
       AND
       tanReqAccel < 0 {

        SET tanReqAccel TO 0.
    }.

    IF NOT fineLatched
       AND
       tanReqAccel < -2 {

        SET tanReqAccel TO -2.
    }.

    SET maxAccel TO
        SHIP:AVAILABLETHRUST /
        SHIP:MASS.

    SET radialAllocLimit TO
        maxAccel *
        constraintAllocationFraction.

    SET radialAllocAccel TO
        radialReqAccel.

    IF radialAllocAccel >
       radialAllocLimit {

        SET radialAllocAccel TO
            radialAllocLimit.
    }.

    IF radialAllocAccel <
       -radialAllocLimit {

        SET radialAllocAccel TO
            -radialAllocLimit.
    }.

    SET tanCapacitySquared TO
        maxAccel^2 -
        radialAllocAccel^2.

    IF tanCapacitySquared < 0 {
        SET tanCapacitySquared TO 0.
    }.

    SET tanCapacity TO
        SQRT(
            tanCapacitySquared
        ).

    SET tanAllocAccel TO
        tanReqAccel.

    IF tanAllocAccel >
       tanCapacity {

        SET tanAllocAccel TO
            tanCapacity.
    }.

    IF tanAllocAccel <
       -tanCapacity {

        SET tanAllocAccel TO
            -tanCapacity.
    }.

    SET orbitGuidanceVec TO
        (
            tangentialUnit *
            tanAllocAccel
        )
        +
        (
            upVec *
            radialAllocAccel
        ).

    SET baseCommandAccel TO
        orbitGuidanceVec:MAG.

    // --------------------------------------------------
    // DAMPED CROSS-TRACK PD TRIM
    //
    // Same path-state controller as upper-stage ascent,
    // but its authority is tied to the radial/tangential
    // command already being flown.  As insertion thrust
    // decays, cross-track authority decays with it.
    // --------------------------------------------------

    SET planePositionDot TO
        VDOT(
            upVec,
            targetPlaneNormal
        ).

    IF planePositionDot > 1 {
        SET planePositionDot TO 1.
    }.

    IF planePositionDot < -1 {
        SET planePositionDot TO -1.
    }.

    SET crossPositionAngle TO
        ARCSIN(
            planePositionDot
        ).

    SET crossPositionM TO
        radiusNow
        *
        crossPositionAngle
        *
        CONSTANT:DEGTORAD.

    SET crossTrackAxis TO
        targetPlaneNormal -
        (
            upVec *
            planePositionDot
        ).

    IF crossTrackAxis:MAG <
       0.000001 {

        SET crossTrackAxis TO
            targetPlaneNormal.
    }.

    SET crossTrackAxis TO
        crossTrackAxis:NORMALIZED.

    SET crossVelocity TO
        VDOT(
            orbitVelVec,
            crossTrackAxis
        ).

    SET crossTargetVelocity TO
        -
        crossPositionM /
        crossTrackPositionTime.

    IF crossTargetVelocity >
       crossTrackVelocityLimit {

        SET crossTargetVelocity TO
            crossTrackVelocityLimit.
    }.

    IF crossTargetVelocity <
       -crossTrackVelocityLimit {

        SET crossTargetVelocity TO
            -crossTrackVelocityLimit.
    }.

    SET crossAccelRaw TO
        (
            crossTargetVelocity -
            crossVelocity
        )
        /
        crossTrackVelocityTime.

    SET terminalCrossAccelFiltered TO
        terminalCrossAccelFiltered
        +
        crossTrackFilterGain
        *
        (
            crossAccelRaw -
            terminalCrossAccelFiltered
        ).

    SET maxCrossAccelByYaw TO
        baseCommandAccel *
        TAN(
            terminalCrossTrackMaxYaw
        ).

    SET crossAccelCmd TO
        terminalCrossAccelFiltered.

    IF crossAccelCmd >
       maxCrossAccelByYaw {

        SET crossAccelCmd TO
            maxCrossAccelByYaw.
    }.

    IF crossAccelCmd <
       -maxCrossAccelByYaw {

        SET crossAccelCmd TO
            -maxCrossAccelByYaw.
    }.

    SET guidanceVec TO
        orbitGuidanceVec +
        (
            crossTrackAxis *
            crossAccelCmd
        ).

    SET commandAccel TO
        guidanceVec:MAG.

    SET actualTrimYaw TO 0.

    IF baseCommandAccel >
       0.000001 {

        SET actualTrimYaw TO
            ARCTAN2(
                crossAccelCmd,
                baseCommandAccel
            ).
    }.

    // --------------------------------------------------
    // ORBIT CAPTURE
    // --------------------------------------------------

    SET insideCapture TO FALSE.

    IF ABS(apOrbitError) <=
          apsisTolerance
       AND
       ABS(peOrbitError) <=
          apsisTolerance {

        SET insideCapture TO TRUE.
    }.

    IF insideCapture
       AND NOT captureActive {

        SET captureActive TO TRUE.

        SET captureStartMET TO
            MISSIONTIME.

        SET thrustActive TO FALSE.

        SET throttleCmd TO 0.

        SET steeringTargetVec TO
            tangentialUnit.

        LOCK THROTTLE TO
            throttleCmd.

        logState(
            "CAPTURE_ENTER"
        ).
    }.

    IF captureActive {

        SET throttleCmd TO 0.

        SET steeringTargetVec TO
            tangentialUnit.

        LOCK THROTTLE TO
            throttleCmd.

        IF NOT insideCapture {

            SET captureActive TO FALSE.

            SET thrustActive TO FALSE.

            logState(
                "CAPTURE_LOST"
            ).

        } ELSE IF
          MISSIONTIME -
          captureStartMET >=
          captureHoldTime {

            SET terminalComplete TO TRUE.

            logState(
                "CAPTURE_CONFIRMED"
            ).
        }.

    } ELSE {

        IF thrustActive {

            IF commandAccel <=
               accelStopThreshold {

                SET thrustActive TO FALSE.

                SET throttleCmd TO 0.

                LOCK THROTTLE TO
                    throttleCmd.

                logState(
                    "FINE_COAST_ENTER"
                ).

            } ELSE {

                SET steeringTargetVec TO
                    guidanceVec.

                IF maxAccel > 0 {

                    SET throttleCmd TO
                        commandAccel /
                        maxAccel.

                } ELSE {

                    SET throttleCmd TO 0.
                }.

                // Do not light a tiny precision burn while
                // the vehicle is still slewing to the new
                // guidance vector.

                IF STEERINGMANAGER:ANGLEERROR >
                   terminalIgnitionSteerError {

                    SET throttleCmd TO 0.
                }.

                IF throttleCmd > 1 {
                    SET throttleCmd TO 1.
                }.

                IF throttleCmd < 0 {
                    SET throttleCmd TO 0.
                }.

                LOCK THROTTLE TO
                    throttleCmd.
            }.

        } ELSE {

            SET throttleCmd TO 0.

            LOCK THROTTLE TO
                throttleCmd.

            IF commandAccel >=
               accelStartThreshold {

                SET thrustActive TO TRUE.

                SET steeringTargetVec TO
                    guidanceVec.

                IF maxAccel > 0 {

                    SET throttleCmd TO
                        commandAccel /
                        maxAccel.

                } ELSE {

                    SET throttleCmd TO 0.
                }.

                // Do not light a tiny precision burn while
                // the vehicle is still slewing to the new
                // guidance vector.

                IF STEERINGMANAGER:ANGLEERROR >
                   terminalIgnitionSteerError {

                    SET throttleCmd TO 0.
                }.

                IF throttleCmd > 1 {
                    SET throttleCmd TO 1.
                }.

                IF throttleCmd < 0 {
                    SET throttleCmd TO 0.
                }.

                LOCK THROTTLE TO
                    throttleCmd.

                logState(
                    "FINE_COAST_EXIT"
                ).
            }.
        }.
    }.

    // --------------------------------------------------
    // FAILURE / TIMEOUT
    // --------------------------------------------------

    IF SHIP:DELTAV:CURRENT <
       0.5
       AND
       SHIP:AVAILABLETHRUST <
       0.1 {

        IF lowDvStart < 0 {

            SET lowDvStart TO
                MISSIONTIME.
        }.

        IF MISSIONTIME -
           lowDvStart >=
           engineFailureHoldTime {

            SET terminalFailed TO TRUE.

            SET throttleCmd TO 0.

            LOCK THROTTLE TO
                throttleCmd.

            logState(
                "PROPULSION_FAILURE"
            ).
        }.

    } ELSE {

        SET lowDvStart TO -1.
    }.

    IF MISSIONTIME -
       terminalStartMET >
       terminalMaxTime {

        SET terminalFailed TO TRUE.

        SET throttleCmd TO 0.

        LOCK THROTTLE TO
            throttleCmd.

        logState(
            "GUIDANCE_TIMEOUT"
        ).
    }.

    // --------------------------------------------------
    // DISPLAY
    // --------------------------------------------------

    PRINT
        "===== SV-5.9 TERMINAL ====="
        AT(0,2).

    IF captureActive {

        PRINT
            "MODE: CAPTURE VERIFY     "
            AT(0,3).

    } ELSE IF fineLatched {

        IF thrustActive {

            PRINT
                "MODE: FINE + YAW TRIM  "
                AT(0,3).

        } ELSE {

            PRINT
                "MODE: FINE COAST       "
                AT(0,3).
        }.

    } ELSE {

        PRINT
            "MODE: TGO + YAW TRIM     "
            AT(0,3).
    }.

    PRINT
        "AP: " +
        ROUND(
            currentAp/1000,
            5
        ) +
        " km      "
        AT(0,5).

    PRINT
        "PE: " +
        ROUND(
            currentPe/1000,
            5
        ) +
        " km      "
        AT(0,6).

    PRINT
        "INC: " +
        ROUND(
            currentInclination,
            6
        ) +
        " deg      "
        AT(0,7).

    PRINT
        "PLANE: " +
        ROUND(
            planeAngleError,
            6
        ) +
        " deg      "
        AT(0,8).

    PRINT
        "AP ERR: " +
        ROUND(
            apOrbitError,
            2
        ) +
        " m       "
        AT(0,9).

    PRINT
        "PE ERR: " +
        ROUND(
            peOrbitError,
            2
        ) +
        " m       "
        AT(0,10).

    PRINT
        "RAD VEL: " +
        ROUND(
            radialVel,
            4
        ) +
        " m/s     "
        AT(0,12).

    PRINT
        "TAN ERR: " +
        ROUND(
            tangentialError,
            4
        ) +
        " m/s     "
        AT(0,13).

    PRINT
        "YAW TRIM: " +
        ROUND(
            actualTrimYaw,
            3
        ) +
        " deg      "
        AT(0,15).

    PRINT
        "XPOS: " +
        ROUND(
            crossPositionM,
            1
        ) +
        " m        "
        AT(0,16).

    PRINT
        "XVEL: " +
        ROUND(
            crossVelocity,
            2
        ) +
        " m/s      "
        AT(0,17).

    PRINT
        "THROTTLE: " +
        ROUND(
            throttleCmd,
            7
        ) +
        "         "
        AT(0,18).

    PRINT
        "STEER ERR: " +
        ROUND(
            STEERINGMANAGER:ANGLEERROR,
            3
        ) +
        " deg     "
        AT(0,19).

    PRINT
        "DV LEFT: " +
        ROUND(
            SHIP:DELTAV:CURRENT,
            1
        ) +
        " m/s     "
        AT(0,21).

    // --------------------------------------------------
    // GUIDANCE LOG
    // --------------------------------------------------

    IF MISSIONTIME -
       lastGuidanceLog >= 0.1 {

        SET modeText TO "TGO".
        SET actuatorText TO "THRUST".

        IF fineLatched {
            SET modeText TO "FINE".
        }.

        IF captureActive {
            SET modeText TO "CAPTURE".
        }.

        IF NOT thrustActive {
            SET actuatorText TO "COAST".
        }.

        LOG
            ROUND(MISSIONTIME,3) + "," +
            modeText + "," +
            actuatorText + "," +
            ROUND(SHIP:ALTITUDE,3) + "," +
            ROUND(currentInclination,7) + "," +
            ROUND(planeAngleError,7) + "," +
            ROUND(crossPositionM,3) + "," +
            ROUND(crossVelocity,5) + "," +
            ROUND(crossTargetVelocity,5) + "," +
            ROUND(crossAccelCmd,6) + "," +
            ROUND(actualTrimYaw,5) + "," +
            ROUND(radialVel,5) + "," +
            ROUND(tangentialVel,5) + "," +
            ROUND(circularVelNow,5) + "," +
            ROUND(tangentialError,5) + "," +
            ROUND(tGo,5) + "," +
            ROUND(naturalRadialAccel,5) + "," +
            ROUND(radialReqAccel,5) + "," +
            ROUND(tanReqAccel,5) + "," +
            ROUND(radialAllocAccel,5) + "," +
            ROUND(tanAllocAccel,5) + "," +
            ROUND(maxAccel,5) + "," +
            ROUND(baseCommandAccel,7) + "," +
            ROUND(commandAccel,7) + "," +
            ROUND(throttleCmd,8) + "," +
            ROUND(currentAp,3) + "," +
            ROUND(currentPe,3) + "," +
            ROUND(apOrbitError,3) + "," +
            ROUND(peOrbitError,3) + "," +
            fineLatched + "," +
            captureActive + "," +
            ROUND(
                STEERINGMANAGER:ANGLEERROR,
                5
            )
            TO guidanceLog.

        SET lastGuidanceLog TO
            MISSIONTIME.
    }.

    IF MISSIONTIME -
       lastFlightLog >= 0.5 {

        logState(
            "SV59_GUIDANCE"
        ).

        SET lastFlightLog TO
            MISSIONTIME.
    }.

    WAIT 0.02.
}.

// ======================================================
// FINAL CUTOFF
// ======================================================

SET throttleCmd TO 0.

LOCK THROTTLE TO throttleCmd.

IF steeringFineTuned {

    SET STEERINGMANAGER:PITCHTS TO originalPitchTS.
    SET STEERINGMANAGER:YAWTS TO originalYawTS.
    STEERINGMANAGER:RESETPIDS().
}.

SET finalRHat TO SHIP:UP:VECTOR.

SET finalOrbitVel TO
    SHIP:VELOCITY:ORBIT.

SET finalRadialVel TO
    VDOT(
        finalOrbitVel,
        finalRHat
    ).

SET finalTangentialVec TO
    finalOrbitVel -
    (
        finalRHat *
        finalRadialVel
    ).

IF finalTangentialVec:MAG > 1 {

    LOCK STEERING TO
        finalTangentialVec:NORMALIZED.
}.

WAIT 0.25.

logState("SV59_CUTOFF").

UNLOCK STEERING.

// ======================================================
// FINAL REPORT
// ======================================================

SET finalAp TO SHIP:OBT:APOAPSIS.
SET finalPe TO SHIP:OBT:PERIAPSIS.
SET finalInc TO SHIP:OBT:INCLINATION.
SET finalApError TO orbitTarget - finalAp.
SET finalPeError TO orbitTarget - finalPe.

SET targetPlaneNormal TO
    targetPlaneNow().

SET finalRHat TO
    SHIP:UP:VECTOR.

SET finalOrbitVel TO
    SHIP:VELOCITY:ORBIT.

SET finalNormalVec TO
    VCRS(
        finalOrbitVel,
        finalRHat
    ).

IF finalNormalVec:MAG > 0.000001 {

    SET finalOrbitNormal TO
        finalNormalVec:NORMALIZED.

} ELSE {

    SET finalOrbitNormal TO
        targetPlaneNormal.
}.

IF VDOT(
    finalOrbitNormal,
    targetPlaneNormal
   ) < 0 {

    SET finalOrbitNormal TO
        -finalOrbitNormal.
}.

SET finalPlaneAngle TO
    VANG(
        finalOrbitNormal,
        targetPlaneNormal
    ).

CLEARSCREEN.

PRINT "===== SV-5.9 GUIDANCE COMPLETE =====".
PRINT "".
PRINT "Target:         " + ROUND(orbitTarget/1000,2) + " km @ " + ROUND(targetInclination,3) + " deg".
PRINT "".
PRINT "Final Ap:       " + ROUND(finalAp/1000,5) + " km".
PRINT "Final Pe:       " + ROUND(finalPe/1000,5) + " km".
PRINT "Inclination:    " + ROUND(finalInc,7) + " deg".
PRINT "".
PRINT "Ap error:       " + ROUND(finalApError,2) + " m".
PRINT "Pe error:       " + ROUND(finalPeError,2) + " m".
PRINT "Inc error:      " + ROUND(targetInclination - finalInc,7) + " deg".
PRINT "Plane error:    " + ROUND(finalPlaneAngle,7) + " deg".

IF finalPlaneAngle <= planeResidualReportTolerance {
    PRINT "Plane status:   IN TOLERANCE".
} ELSE {
    PRINT "Plane status:   RESIDUAL - TUNE LAUNCH/TRIM".
}.

PRINT "".
PRINT "Remaining dV:   " + ROUND(SHIP:DELTAV:CURRENT,1) + " m/s".
PRINT "".

IF terminalComplete {
    PRINT "TARGET ORBIT CAPTURED".
} ELSE {
    PRINT "GUIDANCE TERMINATED BEFORE CAPTURE".
}.

PRINT "".
PRINT "FLIGHT LOG:".
PRINT "0:/sv59flight.csv".
PRINT "".
PRINT "GUIDANCE LOG:".
PRINT "0:/sv59guidance.csv".
PRINT "".
PRINT "ASCENT LOG:".
PRINT "0:/sv59ascent.csv".

logState("FINAL").
