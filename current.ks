// ======================================================
// SV-5.1 MISSION CONFIG
// 0.625 m TWO-STAGE LIQUID LAUNCHER
//
// CONFIGURABLE:
//   - Circular orbit altitude
//   - Orbital inclination
//   - Ascending / descending launch-plane branch
//
// Derived from successful SV-4.0.1 / SV-3.3 guidance.
//
// SV-5.1:
// - Keeps both SV-5.0.2 GUI fixes.
// - Rotation-compensated, target-plane-following ascent azimuth.
// - Plane-error-aware terminal acquisition.
// - Multi-axis guidance horizon.
// - Fine mode cannot latch until cross-plane state is controlled.
//
// FAIRING MUST BE ON ACTION GROUP 1
//
// Logs:
//   0:/sv51flight.csv
//   0:/sv51guidance.csv
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

SET titleLabel TO configGui:ADDLABEL("SV-5.1 LAUNCH GUIDANCE").
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

SET sepMinAlt TO 27000.
SET sepMaxQ TO 0.06.

SET fairingMinAlt TO 60000.
SET fairingMaxQ TO 0.0005.

SET coarseTangentialGain TO 0.35.
SET fineTangentialGain TO 0.12.
SET fineLatchTanError TO 5.

SET fineRadialTimeConstant TO 25.
SET fineRadialVelGain TO 0.16.
SET radialVelMax TO 90.

SET finePlaneTimeConstant TO 20.
SET finePlaneVelGain TO 0.18.
SET planeVelMax TO 90.

SET radialTgoFloor TO 4.
SET radialAccelLimit TO 6.
SET planeAccelLimit TO 10.

// Plane feasibility timing.
// A rest-to-rest translation over distance d under
// acceleration a needs about 2*sqrt(d/a).  Cross velocity
// also gets a conservative 2*v/a stopping horizon.

SET planeTimePositionFactor TO 2.
SET planeTimeVelocityFactor TO 2.
SET planeLeadMargin TO 2.

// Fine mode is not allowed to latch solely because
// along-track speed is nearly correct.

SET planeFineLatchPosition TO 250.
SET planeFineLatchVelocity TO 10.

SET constraintAllocationFraction TO 0.98.
SET startLeadBias TO 0.8.

SET accelStopThreshold TO 0.0017.
SET accelStartThreshold TO 0.0023.

SET apsisTolerance TO 10.
SET inclinationTolerance TO 0.001.
SET planePositionTolerance TO 15.
SET planeVelocityTolerance TO 0.05.
SET captureHoldTime TO 0.75.

SET finePitchTS TO 4.
SET fineYawTS TO 4.

SET originalPitchTS TO STEERINGMANAGER:PITCHTS.
SET originalYawTS TO STEERINGMANAGER:YAWTS.
SET steeringFineTuned TO FALSE.

SET terminalMaxTime TO 300.
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

SET lowDvStart TO -1.

SET throttleCmd TO 0.
SET pitchCmd TO 90.

SET thrustActive TO TRUE.

// ======================================================
// LOG FILES
// ======================================================

SET flightLog TO "0:/sv51flight.csv".
SET guidanceLog TO "0:/sv51guidance.csv".

IF EXISTS(flightLog) {
    DELETEPATH(flightLog).
}.

IF EXISTS(guidanceLog) {
    DELETEPATH(guidanceLog).
}.

LOG
"MET,event,alt_m,lat_deg,inc_deg,surfspd_mps,orbspd_mps,vertspeed_mps,ap_m,pe_m,eta_ap_s,mass_t,throttle,dv_mps,q_atm"
TO flightLog.

LOG
"MET,mode,actuator,alt_m,inc_deg,plane_angle_deg,plane_error_m,radial_vel_mps,cross_vel_mps,along_vel_mps,circular_vel_mps,along_error_mps,along_tgo_s,plane_tgo_req_s,guidance_time_s,plane_ready_fine,natural_radial_accel,natural_cross_accel,radial_req_accel,cross_req_accel,along_req_accel,radial_alloc_accel,cross_alloc_accel,along_alloc_accel,max_accel,command_accel,throttle,ap_m,pe_m,ap_error_m,pe_error_m,fine_latched,capture,steer_angle_err_deg"
TO guidanceLog.

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

SET targetCircularSpeedRef TO
    SQRT(
        SHIP:BODY:MU /
        (
            SHIP:BODY:RADIUS +
            orbitTarget
        )
    ).

SET launchRotationVel TO
    SHIP:VELOCITY:ORBIT -
    SHIP:VELOCITY:SURFACE.

SET desiredLaunchInertialVel TO
    launchAlongHat *
    targetCircularSpeedRef.

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

PRINT "===== SV-5.1 MISSION =====".
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

    SET planeRotationVel TO
        SHIP:VELOCITY:ORBIT -
        SHIP:VELOCITY:SURFACE.

    SET desiredPlaneSurfaceVel TO
        (
            planeAlongHat *
            targetCircularSpeedRef
        )
        -
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

    IF desiredPlaneSurfaceVel:MAG > 0.000001 {

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
            SET guidanceAzimuth TO guidanceAzimuth + 360.
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

        LOCK STEERING TO SRFPROGRADE.
    }.

    IF surfSpd < 650 {

        LOCK STEERING TO
            HEADING(
                guidanceAzimuth,
                pitchCmd
            ).
    }.

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
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,2) + " km      " AT(0,12).
    PRINT "Q: " + ROUND(SHIP:Q,3) + " atm      " AT(0,13).

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
// ======================================================

CLEARSCREEN.

SET lastLog TO MISSIONTIME.

UNTIL ascentDone {

    SET surfSpd TO SHIP:VELOCITY:SURFACE:MAG.
    SET fpa TO 0.

    // Continue following the target inertial plane as the
    // great-circle course changes with position.

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

    SET planeRotationVel TO
        SHIP:VELOCITY:ORBIT -
        SHIP:VELOCITY:SURFACE.

    SET desiredPlaneSurfaceVel TO
        (
            planeAlongHat *
            targetCircularSpeedRef
        )
        -
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

    IF desiredPlaneSurfaceVel:MAG > 0.000001 {

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
            SET guidanceAzimuth TO guidanceAzimuth + 360.
        }.
    }.

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

        SET fpa TO ARCSIN(fpaRatio).
    }.

    IF SHIP:Q > 0.015 {

        SET pitchCmd TO fpa.
        LOCK STEERING TO SRFPROGRADE.

    } ELSE {

        SET etaError TO etaTarget - ETA:APOAPSIS.
        SET pitchOffset TO etaError * 0.20.

        IF pitchOffset < -10 {
            SET pitchOffset TO -10.
        }.

        IF pitchOffset > 10 {
            SET pitchOffset TO 10.
        }.

        SET pitchCmd TO fpa + pitchOffset.

        IF pitchCmd < 0 {
            SET pitchCmd TO 0.
        }.

        IF pitchCmd > 45 {
            SET pitchCmd TO 45.
        }.

        IF SHIP:OBT:APOAPSIS < 60000
           AND pitchCmd < 12 {

            SET pitchCmd TO 12.
        }.

        IF SHIP:OBT:APOAPSIS >= 60000
           AND SHIP:OBT:APOAPSIS < 70000
           AND pitchCmd < 6 {

            SET pitchCmd TO 6.
        }.

        LOCK STEERING TO
            HEADING(
                guidanceAzimuth,
                pitchCmd
            ).
    }.

    SET throttleCmd TO 1.

    IF SHIP:Q > 0.05 {

        SET throttleCmd TO 0.35.

    } ELSE IF SHIP:Q > 0.03 {

        SET throttleCmd TO 0.50.

    } ELSE IF SHIP:Q > 0.015 {

        SET throttleCmd TO 0.70.
    }.

    SET apReserve TO SHIP:Q * 20000.

    IF apReserve > 750 {
        SET apReserve TO 750.
    }.

    IF apReserve < 0 {
        SET apReserve TO 0.
    }.

    SET cutoffApTarget TO orbitTarget + apReserve.
    SET apError TO cutoffApTarget - SHIP:OBT:APOAPSIS.

    IF apError < 3000
       AND throttleCmd > 0.55 {

        SET throttleCmd TO 0.55.
    }.

    IF apError < 1200
       AND throttleCmd > 0.30 {

        SET throttleCmd TO 0.30.
    }.

    IF apError < 400
       AND throttleCmd > 0.15 {

        SET throttleCmd TO 0.15.
    }.

    LOCK THROTTLE TO throttleCmd.
    checkFairing().

    IF SHIP:OBT:APOAPSIS >= cutoffApTarget {

        SET ascentDone TO TRUE.
        SET throttleCmd TO 0.
        LOCK THROTTLE TO throttleCmd.
        logState("ASCENT_CUTOFF").
    }.

    PRINT "UPPER-STAGE ASCENT     " AT(0,6).
    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km       " AT(0,9).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,2) + " km       " AT(0,10).
    PRINT "TARGET: " + ROUND(orbitTarget/1000,2) + " km       " AT(0,11).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,1) + " s        " AT(0,12).
    PRINT "INC: " + ROUND(SHIP:OBT:INCLINATION,3) + " deg      " AT(0,13).
    PRINT "THR: " + ROUND(throttleCmd,3) + "          " AT(0,14).

    IF MISSIONTIME - lastLog >= 0.25 {

        logState("UPPER_ASCENT").
        SET lastLog TO MISSIONTIME.
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
// ======================================================

CLEARSCREEN.

PRINT "===== SV-5.1 ACQUISITION =====".

SET terminalStart TO FALSE.
SET lastLog TO MISSIONTIME.

UNTIL terminalStart {

    SET rHat TO SHIP:UP:VECTOR.

    SET planeDot TO
        VDOT(
            rHat,
            targetPlaneNormal
        ).

    IF planeDot > 1 {
        SET planeDot TO 1.
    }.

    IF planeDot < -1 {
        SET planeDot TO -1.
    }.

    SET planeAngle TO
        ARCSIN(planeDot).

    SET crossAxisVec TO
        targetPlaneNormal -
        (rHat * planeDot).

    IF crossAxisVec:MAG < 0.000001 {
        SET crossAxisVec TO launchNorth.
    }.

    SET crossHat TO crossAxisVec:NORMALIZED.

    SET alongVec TO
        VCRS(
            targetPlaneNormal,
            rHat
        )
        *
        alongCrossSign.

    IF alongVec:MAG < 0.000001 {
        SET alongVec TO launchAlongHat.
    }.

    SET alongHat TO alongVec:NORMALIZED.

    SET orbitVelVec TO SHIP:VELOCITY:ORBIT.

    SET radialVel TO VDOT(orbitVelVec,rHat).
    SET crossVel TO VDOT(orbitVelVec,crossHat).
    SET alongVel TO VDOT(orbitVelVec,alongHat).

    SET radiusNow TO
        SHIP:BODY:RADIUS +
        SHIP:ALTITUDE.

    SET circularVelNow TO
        SQRT(
            SHIP:BODY:MU /
            radiusNow
        ).

    SET alongError TO
        circularVelNow -
        alongVel.

    SET planeError TO
        -radiusNow *
        planeAngle *
        CONSTANT:DEGTORAD.

    SET dvEstimate TO
        SQRT(
            alongError^2 +
            radialVel^2 +
            crossVel^2
        ).

    SET burnEstimate TO 0.
    SET halfDvLead TO 0.

    IF dvEstimate > 0
       AND totalMassFlow > 0 {

        SET finalMassEstimate TO
            SHIP:MASS /
            (CONSTANT:e ^ (dvEstimate / exhaustVelocity)).

        SET burnEstimate TO
            (SHIP:MASS - finalMassEstimate)
            / totalMassFlow.

        SET halfDvMass TO
            SHIP:MASS /
            (CONSTANT:e ^ (0.5 * dvEstimate / exhaustVelocity)).

        SET halfDvLead TO
            (SHIP:MASS - halfDvMass)
            / totalMassFlow.
    }.

    SET planePositionTime TO 0.
    SET planeVelocityTime TO 0.

    IF planeAccelLimit > 0 {

        SET planePositionTime TO
            planeTimePositionFactor *
            SQRT(
                ABS(planeError) /
                planeAccelLimit
            ).

        SET planeVelocityTime TO
            planeTimeVelocityFactor *
            ABS(crossVel) /
            planeAccelLimit.
    }.

    SET planeRequiredTime TO
        planePositionTime.

    IF planeVelocityTime >
       planeRequiredTime {

        SET planeRequiredTime TO
            planeVelocityTime.
    }.

    IF planeRequiredTime <
       radialTgoFloor {

        SET planeRequiredTime TO
            radialTgoFloor.
    }.

    SET startLead TO
        halfDvLead +
        startLeadBias.

    SET planeStartLead TO
        planeRequiredTime +
        planeLeadMargin.

    IF planeStartLead >
       startLead {

        SET startLead TO
            planeStartLead.
    }.

    PRINT "PLANE ERR: " + ROUND(planeError,1) + " m       " AT(0,7).
    PRINT "CROSS VEL: " + ROUND(crossVel,2) + " m/s     " AT(0,8).
    PRINT "ALONG ERR: " + ROUND(alongError,1) + " m/s     " AT(0,9).
    PRINT "INC: " + ROUND(SHIP:OBT:INCLINATION,4) + " deg      " AT(0,10).
    PRINT "FULL BURN: " + ROUND(burnEstimate,2) + " s        " AT(0,12).
    PRINT "PLANE TGO: " + ROUND(planeRequiredTime,2) + " s        " AT(0,13).
    PRINT "START LEAD: " + ROUND(startLead,2) + " s        " AT(0,14).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,2) + " s        " AT(0,15).

    IF ETA:APOAPSIS <= startLead {
        SET terminalStart TO TRUE.
    }.

    IF MISSIONTIME - lastLog >= 0.5 {

        logState("TERMINAL_COAST").
        SET lastLog TO MISSIONTIME.
    }.

    WAIT 0.02.
}.

// ======================================================
// 3-AXIS TERMINAL GUIDANCE
// ======================================================

CLEARSCREEN.

PRINT "===== SV-5.1 TERMINAL =====".

SET terminalStartMET TO MISSIONTIME.
SET throttleCmd TO 0.
SET steeringTargetVec TO SHIP:PROGRADE:VECTOR.

LOCK STEERING TO steeringTargetVec.
LOCK THROTTLE TO throttleCmd.

SET thrustActive TO TRUE.

SET lastFlightLog TO MISSIONTIME.
SET lastGuidanceLog TO MISSIONTIME.

UNTIL terminalComplete
      OR terminalFailed {

    SET rHat TO SHIP:UP:VECTOR.

    SET planeDot TO
        VDOT(
            rHat,
            targetPlaneNormal
        ).

    IF planeDot > 1 {
        SET planeDot TO 1.
    }.

    IF planeDot < -1 {
        SET planeDot TO -1.
    }.

    SET planeAngle TO ARCSIN(planeDot).

    SET crossAxisVec TO
        targetPlaneNormal -
        (rHat * planeDot).

    IF crossAxisVec:MAG < 0.000001 {
        SET crossAxisVec TO launchNorth.
    }.

    SET crossHat TO crossAxisVec:NORMALIZED.

    SET alongVec TO
        VCRS(
            targetPlaneNormal,
            rHat
        )
        *
        alongCrossSign.

    IF alongVec:MAG < 0.000001 {
        SET alongVec TO launchAlongHat.
    }.

    SET alongHat TO alongVec:NORMALIZED.

    SET orbitVelVec TO SHIP:VELOCITY:ORBIT.

    SET radialVel TO VDOT(orbitVelVec,rHat).
    SET crossVel TO VDOT(orbitVelVec,crossHat).
    SET alongVel TO VDOT(orbitVelVec,alongHat).

    SET radiusNow TO
        SHIP:BODY:RADIUS +
        SHIP:ALTITUDE.

    SET altitudeError TO
        orbitTarget -
        SHIP:ALTITUDE.

    SET planeError TO
        -radiusNow *
        planeAngle *
        CONSTANT:DEGTORAD.

    SET circularVelNow TO
        SQRT(
            SHIP:BODY:MU /
            radiusNow
        ).

    SET alongError TO
        circularVelNow -
        alongVel.

    SET currentAp TO SHIP:OBT:APOAPSIS.
    SET currentPe TO SHIP:OBT:PERIAPSIS.
    SET currentInclination TO SHIP:OBT:INCLINATION.

    SET apOrbitError TO orbitTarget - currentAp.
    SET peOrbitError TO orbitTarget - currentPe.

    SET planeReadyForFine TO FALSE.

    IF ABS(planeError) <=
          planeFineLatchPosition
       AND
       ABS(crossVel) <=
          planeFineLatchVelocity {

        SET planeReadyForFine TO TRUE.
    }.

    IF NOT fineLatched
       AND ABS(alongError) <= fineLatchTanError
       AND planeReadyForFine {

        SET fineLatched TO TRUE.

        SET STEERINGMANAGER:PITCHTS TO finePitchTS.
        SET STEERINGMANAGER:YAWTS TO fineYawTS.

        STEERINGMANAGER:RESETPIDS().

        SET steeringFineTuned TO TRUE.

        logState("FINE_MODE_LATCH").
    }.

    SET positiveAlongError TO alongError.

    IF positiveAlongError < 0 {
        SET positiveAlongError TO 0.
    }.

    SET tGo TO 0.

    IF positiveAlongError > 0
       AND totalMassFlow > 0 {

        SET tgoFinalMass TO
            SHIP:MASS /
            (CONSTANT:e ^ (positiveAlongError / exhaustVelocity)).

        SET tGo TO
            (SHIP:MASS - tgoFinalMass)
            / totalMassFlow.
    }.

    // Independent plane feasibility horizon.

    SET planePositionTime TO 0.
    SET planeVelocityTime TO 0.

    IF planeAccelLimit > 0 {

        SET planePositionTime TO
            planeTimePositionFactor *
            SQRT(
                ABS(planeError) /
                planeAccelLimit
            ).

        SET planeVelocityTime TO
            planeTimeVelocityFactor *
            ABS(crossVel) /
            planeAccelLimit.
    }.

    SET planeRequiredTime TO
        planePositionTime.

    IF planeVelocityTime >
       planeRequiredTime {

        SET planeRequiredTime TO
            planeVelocityTime.
    }.

    IF planeRequiredTime <
       radialTgoFloor {

        SET planeRequiredTime TO
            radialTgoFloor.
    }.

    // Shared constraint horizon.  The radial/plane axes
    // are never forced to finish faster than the plane can
    // physically settle.

    SET guidanceTime TO
        tGo.

    IF planeRequiredTime >
       guidanceTime {

        SET guidanceTime TO
            planeRequiredTime.
    }.

    IF guidanceTime <
       radialTgoFloor {

        SET guidanceTime TO
            radialTgoFloor.
    }.

    SET gravityAccel TO
        SHIP:BODY:MU /
        (radiusNow^2).

    SET tangentialSpeedSquared TO
        alongVel^2 +
        crossVel^2.

    SET naturalRadialAccel TO
        (tangentialSpeedSquared / radiusNow)
        -
        gravityAccel.

    SET naturalCrossAccel TO
        -(radialVel * crossVel / radiusNow)
        -
        (alongVel^2 * TAN(planeAngle) / radiusNow).

    IF NOT fineLatched {

        SET desiredRadialAccel TO
            (6 * altitudeError / (guidanceTime^2))
            -
            (4 * radialVel / guidanceTime).

        IF desiredRadialAccel > radialAccelLimit {
            SET desiredRadialAccel TO radialAccelLimit.
        }.

        IF desiredRadialAccel < -radialAccelLimit {
            SET desiredRadialAccel TO -radialAccelLimit.
        }.

        SET desiredCrossAccel TO
            (6 * planeError / (guidanceTime^2))
            -
            (4 * crossVel / guidanceTime).

        IF desiredCrossAccel > planeAccelLimit {
            SET desiredCrossAccel TO planeAccelLimit.
        }.

        IF desiredCrossAccel < -planeAccelLimit {
            SET desiredCrossAccel TO -planeAccelLimit.
        }.

    } ELSE {

        SET radialTarget TO
            altitudeError /
            fineRadialTimeConstant.

        IF radialTarget > radialVelMax {
            SET radialTarget TO radialVelMax.
        }.

        IF radialTarget < -radialVelMax {
            SET radialTarget TO -radialVelMax.
        }.

        SET desiredRadialAccel TO
            fineRadialVelGain *
            (radialTarget - radialVel).

        SET planeTargetVel TO
            planeError /
            finePlaneTimeConstant.

        IF planeTargetVel > planeVelMax {
            SET planeTargetVel TO planeVelMax.
        }.

        IF planeTargetVel < -planeVelMax {
            SET planeTargetVel TO -planeVelMax.
        }.

        SET desiredCrossAccel TO
            finePlaneVelGain *
            (planeTargetVel - crossVel).
    }.

    SET radialReqAccel TO
        desiredRadialAccel -
        naturalRadialAccel.

    SET crossReqAccel TO
        desiredCrossAccel -
        naturalCrossAccel.

    IF fineLatched {
        SET alongGain TO fineTangentialGain.
    } ELSE {
        SET alongGain TO coarseTangentialGain.
    }.

    SET desiredAlongAccel TO
        alongGain *
        alongError.

    SET alongCoupling TO
        (radialVel * alongVel / radiusNow)
        -
        (crossVel * alongVel * TAN(planeAngle) / radiusNow).

    SET alongReqAccel TO
        desiredAlongAccel +
        alongCoupling.

    IF fineLatched
       AND alongReqAccel < 0 {

        SET alongReqAccel TO 0.
    }.

    IF NOT fineLatched
       AND alongReqAccel < -2 {

        SET alongReqAccel TO -2.
    }.

    SET maxAccel TO
        SHIP:AVAILABLETHRUST /
        SHIP:MASS.

    SET constraintReqVec TO
        (rHat * radialReqAccel)
        +
        (crossHat * crossReqAccel).

    SET constraintReqMag TO constraintReqVec:MAG.

    SET constraintLimit TO
        maxAccel *
        constraintAllocationFraction.

    SET constraintScale TO 1.

    IF constraintReqMag > constraintLimit
       AND constraintReqMag > 0 {

        SET constraintScale TO
            constraintLimit /
            constraintReqMag.
    }.

    SET radialAllocAccel TO
        radialReqAccel *
        constraintScale.

    SET crossAllocAccel TO
        crossReqAccel *
        constraintScale.

    SET alongCapacitySquared TO
        maxAccel^2
        -
        radialAllocAccel^2
        -
        crossAllocAccel^2.

    IF alongCapacitySquared < 0 {
        SET alongCapacitySquared TO 0.
    }.

    SET alongCapacity TO SQRT(alongCapacitySquared).
    SET alongAllocAccel TO alongReqAccel.

    IF alongAllocAccel > alongCapacity {
        SET alongAllocAccel TO alongCapacity.
    }.

    IF alongAllocAccel < -alongCapacity {
        SET alongAllocAccel TO -alongCapacity.
    }.

    SET guidanceVec TO
        (alongHat * alongAllocAccel)
        +
        (rHat * radialAllocAccel)
        +
        (crossHat * crossAllocAccel).

    SET commandAccel TO guidanceVec:MAG.

    SET insideCapture TO FALSE.

    IF ABS(apOrbitError) <= apsisTolerance
       AND ABS(peOrbitError) <= apsisTolerance
       AND ABS(currentInclination - targetInclination) <= inclinationTolerance
       AND ABS(planeError) <= planePositionTolerance
       AND ABS(crossVel) <= planeVelocityTolerance {

        SET insideCapture TO TRUE.
    }.

    IF insideCapture
       AND NOT captureActive {

        SET captureActive TO TRUE.
        SET captureStartMET TO MISSIONTIME.
        SET thrustActive TO FALSE.
        SET throttleCmd TO 0.
        SET steeringTargetVec TO alongHat.
        LOCK THROTTLE TO throttleCmd.
        logState("ORBIT_CAPTURE_ENTER").
    }.

    IF captureActive {

        SET throttleCmd TO 0.
        SET steeringTargetVec TO alongHat.
        LOCK THROTTLE TO throttleCmd.

        IF NOT insideCapture {

            SET captureActive TO FALSE.
            SET thrustActive TO FALSE.
            logState("ORBIT_CAPTURE_LOST").

        } ELSE IF
          MISSIONTIME -
          captureStartMET >= captureHoldTime {

            SET terminalComplete TO TRUE.
            logState("ORBIT_CAPTURE_CONFIRMED").
        }.

    } ELSE {

        IF thrustActive {

            IF commandAccel <= accelStopThreshold {

                SET thrustActive TO FALSE.
                SET throttleCmd TO 0.
                LOCK THROTTLE TO throttleCmd.
                logState("FINE_COAST_ENTER").

            } ELSE {

                SET steeringTargetVec TO guidanceVec.

                IF maxAccel > 0 {
                    SET throttleCmd TO commandAccel / maxAccel.
                } ELSE {
                    SET throttleCmd TO 0.
                }.

                IF throttleCmd > 1 {
                    SET throttleCmd TO 1.
                }.

                IF throttleCmd < 0 {
                    SET throttleCmd TO 0.
                }.

                LOCK THROTTLE TO throttleCmd.
            }.

        } ELSE {

            SET throttleCmd TO 0.
            LOCK THROTTLE TO throttleCmd.

            IF commandAccel >= accelStartThreshold {

                SET thrustActive TO TRUE.
                SET steeringTargetVec TO guidanceVec.

                IF maxAccel > 0 {
                    SET throttleCmd TO commandAccel / maxAccel.
                } ELSE {
                    SET throttleCmd TO 0.
                }.

                IF throttleCmd > 1 {
                    SET throttleCmd TO 1.
                }.

                IF throttleCmd < 0 {
                    SET throttleCmd TO 0.
                }.

                LOCK THROTTLE TO throttleCmd.
                logState("FINE_COAST_EXIT").
            }.
        }.
    }.

    IF SHIP:DELTAV:CURRENT < 0.5
       AND SHIP:AVAILABLETHRUST < 0.1 {

        IF lowDvStart < 0 {
            SET lowDvStart TO MISSIONTIME.
        }.

        IF MISSIONTIME - lowDvStart >= engineFailureHoldTime {

            SET terminalFailed TO TRUE.
            SET throttleCmd TO 0.
            LOCK THROTTLE TO throttleCmd.
            logState("PROPULSION_FAILURE").
        }.

    } ELSE {

        SET lowDvStart TO -1.
    }.

    IF MISSIONTIME - terminalStartMET > terminalMaxTime {

        SET terminalFailed TO TRUE.
        SET throttleCmd TO 0.
        LOCK THROTTLE TO throttleCmd.
        logState("GUIDANCE_TIMEOUT").
    }.

    PRINT "===== SV-5.1 TERMINAL =====" AT(0,2).

    IF captureActive {

        PRINT "MODE: CAPTURE VERIFY     " AT(0,3).

    } ELSE IF fineLatched {

        IF thrustActive {
            PRINT "MODE: 3D FINE THRUST    " AT(0,3).
        } ELSE {
            PRINT "MODE: 3D FINE COAST     " AT(0,3).
        }.

    } ELSE {

        PRINT "MODE: 3D TGO            " AT(0,3).
    }.

    PRINT "AP: " + ROUND(currentAp/1000,5) + " km       " AT(0,5).
    PRINT "PE: " + ROUND(currentPe/1000,5) + " km       " AT(0,6).
    PRINT "INC: " + ROUND(currentInclination,6) + " deg      " AT(0,7).
    PRINT "TARGET INC: " + ROUND(targetInclination,3) + " deg      " AT(0,8).
    PRINT "PLANE ERR: " + ROUND(planeError,2) + " m        " AT(0,10).
    PRINT "CROSS VEL: " + ROUND(crossVel,4) + " m/s      " AT(0,11).
    PRINT "RAD VEL: " + ROUND(radialVel,4) + " m/s      " AT(0,12).
    PRINT "ALONG ERR: " + ROUND(alongError,4) + " m/s      " AT(0,13).
    PRINT "PLANE TGO: " + ROUND(planeRequiredTime,2) + " s        " AT(0,14).
    PRINT "R ALLOC: " + ROUND(radialAllocAccel,4) + " m/s2     " AT(0,15).
    PRINT "X ALLOC: " + ROUND(crossAllocAccel,4) + " m/s2     " AT(0,16).
    PRINT "A ALLOC: " + ROUND(alongAllocAccel,4) + " m/s2     " AT(0,17).
    PRINT "THROTTLE: " + ROUND(throttleCmd,7) + "          " AT(0,19).
    PRINT "STEER ERR: " + ROUND(STEERINGMANAGER:ANGLEERROR,3) + " deg      " AT(0,20).
    PRINT "DV LEFT: " + ROUND(SHIP:DELTAV:CURRENT,1) + " m/s      " AT(0,22).

    IF MISSIONTIME - lastGuidanceLog >= 0.1 {

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
            ROUND(planeAngle,7) + "," +
            ROUND(planeError,3) + "," +
            ROUND(radialVel,5) + "," +
            ROUND(crossVel,5) + "," +
            ROUND(alongVel,5) + "," +
            ROUND(circularVelNow,5) + "," +
            ROUND(alongError,5) + "," +
            ROUND(tGo,5) + "," +
            ROUND(planeRequiredTime,5) + "," +
            ROUND(guidanceTime,5) + "," +
            planeReadyForFine + "," +
            ROUND(naturalRadialAccel,5) + "," +
            ROUND(naturalCrossAccel,5) + "," +
            ROUND(radialReqAccel,5) + "," +
            ROUND(crossReqAccel,5) + "," +
            ROUND(alongReqAccel,5) + "," +
            ROUND(radialAllocAccel,5) + "," +
            ROUND(crossAllocAccel,5) + "," +
            ROUND(alongAllocAccel,5) + "," +
            ROUND(maxAccel,5) + "," +
            ROUND(commandAccel,7) + "," +
            ROUND(throttleCmd,8) + "," +
            ROUND(currentAp,3) + "," +
            ROUND(currentPe,3) + "," +
            ROUND(apOrbitError,3) + "," +
            ROUND(peOrbitError,3) + "," +
            fineLatched + "," +
            captureActive + "," +
            ROUND(STEERINGMANAGER:ANGLEERROR,5)
            TO guidanceLog.

        SET lastGuidanceLog TO MISSIONTIME.
    }.

    IF MISSIONTIME - lastFlightLog >= 0.5 {

        logState("SV51_GUIDANCE").
        SET lastFlightLog TO MISSIONTIME.
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

SET finalAlongVec TO
    VCRS(
        targetPlaneNormal,
        finalRHat
    )
    *
    alongCrossSign.

IF finalAlongVec:MAG > 0.000001 {

    LOCK STEERING TO finalAlongVec:NORMALIZED.
}.

WAIT 0.25.

logState("SV51_CUTOFF").

UNLOCK STEERING.

// ======================================================
// FINAL REPORT
// ======================================================

SET finalAp TO SHIP:OBT:APOAPSIS.
SET finalPe TO SHIP:OBT:PERIAPSIS.
SET finalInc TO SHIP:OBT:INCLINATION.
SET finalApError TO orbitTarget - finalAp.
SET finalPeError TO orbitTarget - finalPe.

CLEARSCREEN.

PRINT "===== SV-5.1 GUIDANCE COMPLETE =====".
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
PRINT "0:/sv51flight.csv".
PRINT "".
PRINT "GUIDANCE LOG:".
PRINT "0:/sv51guidance.csv".

logState("FINAL").
