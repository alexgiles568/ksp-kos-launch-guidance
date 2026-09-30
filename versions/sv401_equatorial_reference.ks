// ======================================================
// 0.625 m TWO-STAGE LIQUID LAUNCHER
// SV-4.0.1: EQUATORIAL 3D STATE VECTOR GUIDANCE
//
// Targets:
//   Apoapsis:    80,000 m
//   Periapsis:   80,000 m
//   Inclination: 0.000 deg
//
// Hotfix from SV-4.0:
// - Added missing fineTangentialGain definition.
//
// FAIRING MUST BE ON ACTION GROUP 1
//
// Logs:
//   0:/sv401flight.csv
//   0:/sv401guidance.csv
// ======================================================

CLEARSCREEN.

SET orbitTarget TO 80000.
SET targetInclination TO 0.
SET targetLatitude TO 0.
SET inclinationTolerance TO 0.001.
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

SET fineNorthTimeConstant TO 20.
SET fineNorthVelGain TO 0.18.
SET northVelMax TO 90.

SET radialTgoFloor TO 4.
SET radialAccelLimit TO 6.
SET northAccelLimit TO 10.
SET radialAllocationFraction TO 0.98.
SET startLeadBias TO 0.8.

SET accelStopThreshold TO 0.0017.
SET accelStartThreshold TO 0.0023.

SET apsisTolerance TO 10.
SET captureHoldTime TO 0.75.

SET finePitchTS TO 4.
SET fineYawTS TO 4.

SET originalPitchTS TO STEERINGMANAGER:PITCHTS.
SET originalYawTS TO STEERINGMANAGER:YAWTS.
SET steeringFineTuned TO FALSE.

SET terminalMaxTime TO 240.
SET engineFailureHoldTime TO 2.

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
SET pitchCmd TO 90.
SET throttleCmd TO 0.
SET thrustActive TO TRUE.

SET flightLog TO "0:/sv401flight.csv".
SET guidanceLog TO "0:/sv401guidance.csv".

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
"MET,mode,actuator,alt_m,lat_deg,inc_deg,alt_error_m,north_error_m,radial_vel_mps,north_vel_mps,east_vel_mps,circular_vel_mps,east_error_mps,tgo_s,natural_radial_accel,natural_north_accel,radial_req_accel,north_req_accel,east_req_accel,radial_alloc_accel,north_alloc_accel,east_alloc_accel,max_accel,command_accel,throttle,ap_m,pe_m,ap_error_m,pe_error_m,fine_latched,capture,steer_angle_err_deg"
TO guidanceLog.

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

FUNCTION checkFairing {
    IF NOT fairingDeployed
       AND SHIP:ALTITUDE >= fairingMinAlt
       AND SHIP:Q <= fairingMaxQ {

        TOGGLE AG1.
        SET fairingDeployed TO TRUE.
        logState("FAIRING_JETTISON").
        PRINT "FAIRING JETTISON" AT(0,9).
    }.
}.

SET throttleCmd TO 1.
SET pitchCmd TO 90.

LOCK THROTTLE TO throttleCmd.
LOCK STEERING TO HEADING(90,90).

PRINT "0.625m LAUNCH VEHICLE".
PRINT "SV-4.0.1 EQUATORIAL GUIDANCE".
PRINT "TARGET: 80 x 80 KM".
PRINT "INCLINATION: 0 DEG".
PRINT "".
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

UNTIL boosterBurnout {

    SET surfSpd TO SHIP:VELOCITY:SURFACE:MAG.

    IF surfSpd < 40 {
        SET pitchCmd TO 90.
    } ELSE IF surfSpd < 100 {
        SET pitchCmd TO 90 - ((surfSpd - 40) / 60) * 8.
    } ELSE IF surfSpd < 220 {
        SET pitchCmd TO 82 - ((surfSpd - 100) / 120) * 17.
    } ELSE IF surfSpd < 400 {
        SET pitchCmd TO 65 - ((surfSpd - 220) / 180) * 18.
    } ELSE IF surfSpd < 650 {
        SET pitchCmd TO 47 - ((surfSpd - 400) / 250) * 12.
    } ELSE {
        LOCK STEERING TO SRFPROGRADE.
    }.

    IF surfSpd < 650 {
        LOCK STEERING TO HEADING(90,pitchCmd).
    }.

    SET throttleCmd TO 1.

    IF SHIP:Q > 0.35 {
        SET throttleCmd TO 0.85.
    }.

    IF SHIP:Q > 0.45 {
        SET throttleCmd TO 0.65.
    }.

    LOCK THROTTLE TO throttleCmd.

    PRINT "BOOSTER ASCENT          " AT(0,7).
    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km      " AT(0,11).
    PRINT "LAT: " + ROUND(SHIP:LATITUDE,4) + " deg     " AT(0,12).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,2) + " km      " AT(0,13).
    PRINT "Q: " + ROUND(SHIP:Q,3) + " atm     " AT(0,14).

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

CLEARSCREEN.
PRINT "===== BOOSTER BURNOUT =====".
PRINT "".
PRINT "COASTING TO SAFE SEPARATION".

SET lastLog TO MISSIONTIME.

UNTIL boosterDropped {

    SET throttleCmd TO 0.
    LOCK THROTTLE TO throttleCmd.
    LOCK STEERING TO SRFPROGRADE.

    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km      " AT(0,8).
    PRINT "Q: " + ROUND(SHIP:Q,4) + " atm     " AT(0,9).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,2) + " km      " AT(0,10).

    IF MISSIONTIME - lastLog >= 0.25 {
        logState("BOOSTER_COAST").
        SET lastLog TO MISSIONTIME.
    }.

    IF SHIP:ALTITUDE >= sepMinAlt
       AND SHIP:Q <= sepMaxQ {

        logState("PRE_SEPARATION").
        PRINT "SEPARATING" AT(0,12).
        STAGE.
        SET boosterDropped TO TRUE.
        WAIT 0.2.
        logState("BOOSTER_SEPARATED").
    }.

    WAIT 0.02.
}.

SET throttleCmd TO 0.
LOCK THROTTLE TO throttleCmd.
LOCK STEERING TO SRFPROGRADE.
PRINT "BOOSTER CLEARANCE..." AT(0,14).
WAIT 1.8.

IF SHIP:AVAILABLETHRUST < 0.1 {
    STAGE.
    WAIT 0.25.
}.

logState("UPPER_ENGINE_READY").

CLEARSCREEN.
SET lastLog TO MISSIONTIME.

UNTIL ascentDone {

    SET surfSpd TO SHIP:VELOCITY:SURFACE:MAG.
    SET fpa TO 0.

    IF surfSpd > 1 {
        SET fpaRatio TO SHIP:VERTICALSPEED / surfSpd.

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

        LOCK STEERING TO HEADING(90,pitchCmd).
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

    PRINT "UPPER-STAGE ASCENT      " AT(0,6).
    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km      " AT(0,10).
    PRINT "LAT: " + ROUND(SHIP:LATITUDE,5) + " deg     " AT(0,11).
    PRINT "FPA: " + ROUND(fpa,1) + " deg     " AT(0,12).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,2) + " km      " AT(0,13).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,1) + " s       " AT(0,14).
    PRINT "THR: " + ROUND(throttleCmd,2) + "         " AT(0,15).

    IF MISSIONTIME - lastLog >= 0.25 {
        logState("UPPER_ASCENT").
        SET lastLog TO MISSIONTIME.
    }.

    WAIT 0.02.
}.

SET throttleCmd TO 0.
LOCK THROTTLE TO throttleCmd.
LOCK STEERING TO PROGRADE.

CLEARSCREEN.
PRINT "===== ASCENT COMPLETE =====".
PRINT "".
PRINT "COASTING TO 3D TERMINAL GUIDANCE".

SET lastLog TO MISSIONTIME.

UNTIL SHIP:ALTITUDE >= 60000
      AND SHIP:Q <= 0.0005 {

    checkFairing().

    IF MISSIONTIME - lastLog >= 0.5 {
        logState("ATMOSPHERIC_COAST").
        SET lastLog TO MISSIONTIME.
    }.

    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km      " AT(0,8).
    PRINT "LAT: " + ROUND(SHIP:LATITUDE,5) + " deg     " AT(0,9).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,3) + " km     " AT(0,10).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,1) + " s      " AT(0,11).

    WAIT 0.05.
}.

checkFairing().
logState("NEAR_VACUUM").

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

SET exhaustVelocity TO effectiveISP * CONSTANT:g0.

CLEARSCREEN.
PRINT "===== SV-4.0.1 ACQUISITION =====".

SET terminalStart TO FALSE.
SET lastLog TO MISSIONTIME.

UNTIL terminalStart {

    SET upVec TO SHIP:UP:VECTOR.
    SET northVec TO SHIP:NORTH:VECTOR.
    SET eastVec TO HEADING(90,0):VECTOR.
    SET orbitVelVec TO SHIP:VELOCITY:ORBIT.

    SET radialVel TO VDOT(orbitVelVec,upVec).
    SET northVel TO VDOT(orbitVelVec,northVec).
    SET eastVel TO VDOT(orbitVelVec,eastVec).

    SET radiusNow TO SHIP:BODY:RADIUS + SHIP:ALTITUDE.
    SET circularVelNow TO SQRT(SHIP:BODY:MU / radiusNow).
    SET eastError TO circularVelNow - eastVel.

    SET northError TO
        (targetLatitude - SHIP:LATITUDE)
        * CONSTANT:DEGTORAD
        * radiusNow.

    SET northEquivalentError TO northVel.

    SET dvEstimate TO
        SQRT(
            eastError^2 +
            radialVel^2 +
            northEquivalentError^2
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

    SET startLead TO halfDvLead + startLeadBias.

    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,3) + " km      " AT(0,6).
    PRINT "LAT: " + ROUND(SHIP:LATITUDE,5) + " deg     " AT(0,7).
    PRINT "N ERR: " + ROUND(northError,1) + " m       " AT(0,8).
    PRINT "N VEL: " + ROUND(northVel,2) + " m/s     " AT(0,9).
    PRINT "EAST ERR: " + ROUND(eastError,1) + " m/s     " AT(0,10).
    PRINT "FULL BURN: " + ROUND(burnEstimate,2) + " s       " AT(0,12).
    PRINT "START LEAD: " + ROUND(startLead,2) + " s       " AT(0,13).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,2) + " s       " AT(0,14).

    IF ETA:APOAPSIS <= startLead {
        SET terminalStart TO TRUE.
    }.

    IF MISSIONTIME - lastLog >= 0.5 {
        logState("TERMINAL_COAST").
        SET lastLog TO MISSIONTIME.
    }.

    WAIT 0.02.
}.

CLEARSCREEN.
PRINT "===== SV-4.0.1 EQUATORIAL =====".

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

    SET upVec TO SHIP:UP:VECTOR.
    SET northVec TO SHIP:NORTH:VECTOR.
    SET eastVec TO HEADING(90,0):VECTOR.
    SET orbitVelVec TO SHIP:VELOCITY:ORBIT.

    SET radialVel TO VDOT(orbitVelVec,upVec).
    SET northVel TO VDOT(orbitVelVec,northVec).
    SET eastVel TO VDOT(orbitVelVec,eastVec).

    SET currentAp TO SHIP:OBT:APOAPSIS.
    SET currentPe TO SHIP:OBT:PERIAPSIS.
    SET currentInclination TO SHIP:OBT:INCLINATION.

    SET apOrbitError TO orbitTarget - currentAp.
    SET peOrbitError TO orbitTarget - currentPe.

    SET radiusNow TO SHIP:BODY:RADIUS + SHIP:ALTITUDE.
    SET altitudeError TO orbitTarget - SHIP:ALTITUDE.

    SET northError TO
        (targetLatitude - SHIP:LATITUDE)
        * CONSTANT:DEGTORAD
        * radiusNow.

    SET circularVelNow TO SQRT(SHIP:BODY:MU / radiusNow).
    SET eastError TO circularVelNow - eastVel.

    IF NOT fineLatched
       AND ABS(eastError) <= fineLatchTanError {

        SET fineLatched TO TRUE.
        SET STEERINGMANAGER:PITCHTS TO finePitchTS.
        SET STEERINGMANAGER:YAWTS TO fineYawTS.
        STEERINGMANAGER:RESETPIDS().
        SET steeringFineTuned TO TRUE.
        logState("FINE_MODE_LATCH").
    }.

    SET positiveEastError TO eastError.

    IF positiveEastError < 0 {
        SET positiveEastError TO 0.
    }.

    SET tGo TO 0.

    IF positiveEastError > 0
       AND totalMassFlow > 0 {

        SET tgoFinalMass TO
            SHIP:MASS /
            (CONSTANT:e ^ (positiveEastError / exhaustVelocity)).

        SET tGo TO
            (SHIP:MASS - tgoFinalMass)
            / totalMassFlow.
    }.

    SET gravityAccel TO SHIP:BODY:MU / (radiusNow^2).

    SET naturalRadialAccel TO
        ((eastVel^2 + northVel^2) / radiusNow)
        - gravityAccel.

    SET naturalNorthAccel TO
        -(radialVel * northVel / radiusNow)
        -(eastVel^2 * TAN(SHIP:LATITUDE) / radiusNow).

    IF NOT fineLatched {

        SET guidanceTime TO tGo.

        IF guidanceTime < radialTgoFloor {
            SET guidanceTime TO radialTgoFloor.
        }.

        SET desiredRadialAccel TO
            (6 * altitudeError / (guidanceTime^2))
            - (4 * radialVel / guidanceTime).

        IF desiredRadialAccel > radialAccelLimit {
            SET desiredRadialAccel TO radialAccelLimit.
        }.

        IF desiredRadialAccel < -radialAccelLimit {
            SET desiredRadialAccel TO -radialAccelLimit.
        }.

        SET desiredNorthAccel TO
            (6 * northError / (guidanceTime^2))
            - (4 * northVel / guidanceTime).

        IF desiredNorthAccel > northAccelLimit {
            SET desiredNorthAccel TO northAccelLimit.
        }.

        IF desiredNorthAccel < -northAccelLimit {
            SET desiredNorthAccel TO -northAccelLimit.
        }.

    } ELSE {

        SET radialTarget TO altitudeError / fineRadialTimeConstant.

        IF radialTarget > radialVelMax {
            SET radialTarget TO radialVelMax.
        }.

        IF radialTarget < -radialVelMax {
            SET radialTarget TO -radialVelMax.
        }.

        SET desiredRadialAccel TO
            fineRadialVelGain *
            (radialTarget - radialVel).

        SET northTargetVel TO
            northError /
            fineNorthTimeConstant.

        IF northTargetVel > northVelMax {
            SET northTargetVel TO northVelMax.
        }.

        IF northTargetVel < -northVelMax {
            SET northTargetVel TO -northVelMax.
        }.

        SET desiredNorthAccel TO
            fineNorthVelGain *
            (northTargetVel - northVel).
    }.

    SET radialReqAccel TO
        desiredRadialAccel -
        naturalRadialAccel.

    SET northReqAccel TO
        desiredNorthAccel -
        naturalNorthAccel.

    IF fineLatched {
        SET eastGain TO fineTangentialGain.
    } ELSE {
        SET eastGain TO coarseTangentialGain.
    }.

    SET desiredEastAccel TO
        eastGain *
        eastError.

    SET eastCoupling TO
        (radialVel * eastVel / radiusNow)
        -
        (northVel * eastVel * TAN(SHIP:LATITUDE) / radiusNow).

    SET eastReqAccel TO
        desiredEastAccel +
        eastCoupling.

    IF fineLatched
       AND eastReqAccel < 0 {
        SET eastReqAccel TO 0.
    }.

    IF NOT fineLatched
       AND eastReqAccel < -2 {
        SET eastReqAccel TO -2.
    }.

    SET maxAccel TO
        SHIP:AVAILABLETHRUST /
        SHIP:MASS.

    SET constraintReqVec TO
        (upVec * radialReqAccel)
        +
        (northVec * northReqAccel).

    SET constraintReqMag TO
        constraintReqVec:MAG.

    SET constraintLimit TO
        maxAccel *
        radialAllocationFraction.

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

    SET northAllocAccel TO
        northReqAccel *
        constraintScale.

    SET eastCapacitySquared TO
        maxAccel^2
        -
        radialAllocAccel^2
        -
        northAllocAccel^2.

    IF eastCapacitySquared < 0 {
        SET eastCapacitySquared TO 0.
    }.

    SET eastCapacity TO
        SQRT(eastCapacitySquared).

    SET eastAllocAccel TO eastReqAccel.

    IF eastAllocAccel > eastCapacity {
        SET eastAllocAccel TO eastCapacity.
    }.

    IF eastAllocAccel < -eastCapacity {
        SET eastAllocAccel TO -eastCapacity.
    }.

    SET guidanceVec TO
        (eastVec * eastAllocAccel)
        +
        (upVec * radialAllocAccel)
        +
        (northVec * northAllocAccel).

    SET commandAccel TO
        guidanceVec:MAG.

    SET insideCapture TO FALSE.

    IF ABS(apOrbitError) <= apsisTolerance
       AND ABS(peOrbitError) <= apsisTolerance
       AND ABS(currentInclination - targetInclination) <= inclinationTolerance {

        SET insideCapture TO TRUE.
    }.

    IF insideCapture
       AND NOT captureActive {

        SET captureActive TO TRUE.
        SET captureStartMET TO MISSIONTIME.
        SET thrustActive TO FALSE.
        SET throttleCmd TO 0.
        SET steeringTargetVec TO eastVec.
        LOCK THROTTLE TO throttleCmd.
        logState("EQUATORIAL_CAPTURE_ENTER").
    }.

    IF captureActive {

        SET throttleCmd TO 0.
        SET steeringTargetVec TO eastVec.
        LOCK THROTTLE TO throttleCmd.

        IF NOT insideCapture {

            SET captureActive TO FALSE.
            SET thrustActive TO FALSE.
            logState("EQUATORIAL_CAPTURE_LOST").

        } ELSE IF
            MISSIONTIME -
            captureStartMET >= captureHoldTime {

            SET terminalComplete TO TRUE.
            logState("EQUATORIAL_CAPTURE_CONFIRMED").
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

    PRINT "===== SV-4.0.1 EQUATORIAL =====" AT(0,2).

    IF captureActive {
        PRINT "MODE: EQUATOR CAPTURE    " AT(0,3).
    } ELSE IF fineLatched {
        IF thrustActive {
            PRINT "MODE: 3D FINE THRUST     " AT(0,3).
        } ELSE {
            PRINT "MODE: 3D FINE COAST      " AT(0,3).
        }.
    } ELSE {
        PRINT "MODE: 3D TGO             " AT(0,3).
    }.

    PRINT "AP: " + ROUND(currentAp/1000,5) + " km      " AT(0,5).
    PRINT "PE: " + ROUND(currentPe/1000,5) + " km      " AT(0,6).
    PRINT "INC: " + ROUND(currentInclination,6) + " deg     " AT(0,7).
    PRINT "LAT: " + ROUND(SHIP:LATITUDE,6) + " deg     " AT(0,8).
    PRINT "N ERR: " + ROUND(northError,2) + " m       " AT(0,10).
    PRINT "N VEL: " + ROUND(northVel,4) + " m/s     " AT(0,11).
    PRINT "RAD VEL: " + ROUND(radialVel,4) + " m/s     " AT(0,12).
    PRINT "EAST ERR: " + ROUND(eastError,4) + " m/s     " AT(0,13).
    PRINT "R ALLOC: " + ROUND(radialAllocAccel,4) + " m/s2    " AT(0,15).
    PRINT "N ALLOC: " + ROUND(northAllocAccel,4) + " m/s2    " AT(0,16).
    PRINT "E ALLOC: " + ROUND(eastAllocAccel,4) + " m/s2    " AT(0,17).
    PRINT "THROTTLE: " + ROUND(throttleCmd,7) + "         " AT(0,19).
    PRINT "STEER ERR: " + ROUND(STEERINGMANAGER:ANGLEERROR,3) + " deg     " AT(0,20).
    PRINT "DV LEFT: " + ROUND(SHIP:DELTAV:CURRENT,1) + " m/s     " AT(0,22).

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
            ROUND(SHIP:LATITUDE,7) + "," +
            ROUND(currentInclination,7) + "," +
            ROUND(altitudeError,3) + "," +
            ROUND(northError,3) + "," +
            ROUND(radialVel,5) + "," +
            ROUND(northVel,5) + "," +
            ROUND(eastVel,5) + "," +
            ROUND(circularVelNow,5) + "," +
            ROUND(eastError,5) + "," +
            ROUND(tGo,5) + "," +
            ROUND(naturalRadialAccel,5) + "," +
            ROUND(naturalNorthAccel,5) + "," +
            ROUND(radialReqAccel,5) + "," +
            ROUND(northReqAccel,5) + "," +
            ROUND(eastReqAccel,5) + "," +
            ROUND(radialAllocAccel,5) + "," +
            ROUND(northAllocAccel,5) + "," +
            ROUND(eastAllocAccel,5) + "," +
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
        logState("SV401_GUIDANCE").
        SET lastFlightLog TO MISSIONTIME.
    }.

    WAIT 0.02.
}.

SET throttleCmd TO 0.
LOCK THROTTLE TO throttleCmd.

IF steeringFineTuned {
    SET STEERINGMANAGER:PITCHTS TO originalPitchTS.
    SET STEERINGMANAGER:YAWTS TO originalYawTS.
    STEERINGMANAGER:RESETPIDS().
}.

LOCK STEERING TO HEADING(90,0).
WAIT 0.25.
logState("SV401_CUTOFF").
UNLOCK STEERING.

SET finalAp TO SHIP:OBT:APOAPSIS.
SET finalPe TO SHIP:OBT:PERIAPSIS.
SET finalInc TO SHIP:OBT:INCLINATION.
SET finalApError TO orbitTarget - finalAp.
SET finalPeError TO orbitTarget - finalPe.

CLEARSCREEN.

PRINT "===== SV-4.0.1 GUIDANCE COMPLETE =====".
PRINT "".
PRINT "Final Ap:       " + ROUND(finalAp/1000,5) + " km".
PRINT "Final Pe:       " + ROUND(finalPe/1000,5) + " km".
PRINT "Inclination:    " + ROUND(finalInc,7) + " deg".
PRINT "".
PRINT "Ap error:       " + ROUND(finalApError,2) + " m".
PRINT "Pe error:       " + ROUND(finalPeError,2) + " m".
PRINT "Latitude:       " + ROUND(SHIP:LATITUDE,7) + " deg".
PRINT "".
PRINT "Remaining dV:   " + ROUND(SHIP:DELTAV:CURRENT,1) + " m/s".
PRINT "".

IF terminalComplete {
    PRINT "EQUATORIAL ORBIT CAPTURED".
} ELSE {
    PRINT "GUIDANCE TERMINATED BEFORE CAPTURE".
}.

PRINT "".
PRINT "FLIGHT LOG:".
PRINT "0:/sv401flight.csv".
PRINT "".
PRINT "GUIDANCE LOG:".
PRINT "0:/sv401guidance.csv".

logState("FINAL").
