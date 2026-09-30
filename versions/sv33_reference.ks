// ======================================================
// 0.625 m TWO-STAGE LIQUID LAUNCHER
// SV-3.3: PRECISION GUIDANCE - LOCKED BASELINE
//
// Target: 80 x 80 km Kerbin orbit
//
// SV-3.3 changes:
//
// - Orbital guidance UNCHANGED from SV-3.2.
//
// - Adds actuator deadband hysteresis:
//
//      engine ON -> turn OFF below 0.0017 m/s^2
//      engine OFF -> remain OFF until above 0.0023 m/s^2
//
// - During fine-guidance coast periods, attitude holds
//   the LAST useful thrust direction.
//
// - Capture mode still points tangentially.
//
// FAIRING MUST BE ON ACTION GROUP 1
//
// Logs:
//   0:/sv33flight.csv
//   0:/sv33guidance.csv
// ======================================================

CLEARSCREEN.

SET orbitTarget TO 80000.
SET etaTarget TO 50.

SET sepMinAlt TO 27000.
SET sepMaxQ TO 0.06.

SET fairingMinAlt TO 60000.
SET fairingMaxQ TO 0.0005.

SET coarseTangentialGain TO 0.35.
SET fineLatchTanError TO 5.

SET fineRadialTimeConstant TO 25.
SET fineRadialVelGain TO 0.16.
SET fineTangentialGain TO 0.12.
SET radialVelMax TO 90.

SET radialTgoFloor TO 4.
SET radialAccelLimit TO 6.
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

SET terminalMaxTime TO 220.
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

SET flightLog TO "0:/sv33flight.csv".
SET guidanceLog TO "0:/sv33guidance.csv".

IF EXISTS(flightLog) {
    DELETEPATH(flightLog).
}.

IF EXISTS(guidanceLog) {
    DELETEPATH(guidanceLog).
}.

LOG
"MET,event,alt_m,surfspd_mps,orbspd_mps,vertspeed_mps,ap_m,pe_m,eta_ap_s,mass_t,throttle,dv_mps,q_atm"
TO flightLog.

LOG
"MET,mode,actuator,alt_m,alt_error_m,radial_vel_mps,tangential_vel_mps,circular_vel_mps,tangential_error_mps,tgo_s,natural_radial_accel,desired_radial_accel,radial_req_engine_accel,radial_alloc_accel,tan_req_engine_accel,tan_alloc_accel,max_accel,command_accel,throttle,ap_m,pe_m,ap_error_m,pe_error_m,fine_latched,capture,steer_angle_err_deg,steer_pitch_err_deg,steer_yaw_err_deg,pitch_ts,yaw_ts"
TO guidanceLog.

FUNCTION logState {
    PARAMETER eventName.

    LOG
        ROUND(MISSIONTIME,3) + "," +
        eventName + "," +
        ROUND(SHIP:ALTITUDE,3) + "," +
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
PRINT "SV-3.3 PRECISION GUIDANCE".
PRINT "TARGET: 80 x 80 KM".
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
    PRINT "VEL: " + ROUND(surfSpd,0) + " m/s     " AT(0,12).
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
    PRINT "VEL: " + ROUND(surfSpd,0) + " m/s     " AT(0,11).
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
PRINT "COASTING TO TERMINAL GUIDANCE".

SET lastLog TO MISSIONTIME.

UNTIL SHIP:ALTITUDE >= 60000
      AND SHIP:Q <= 0.0005 {

    checkFairing().

    IF MISSIONTIME - lastLog >= 0.5 {
        logState("ATMOSPHERIC_COAST").
        SET lastLog TO MISSIONTIME.
    }.

    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,2) + " km      " AT(0,8).
    PRINT "AP: " + ROUND(SHIP:OBT:APOAPSIS/1000,3) + " km     " AT(0,9).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,1) + " s      " AT(0,10).

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
PRINT "===== SV-3.3 ACQUISITION =====".

SET terminalStart TO FALSE.
SET lastLog TO MISSIONTIME.

UNTIL terminalStart {

    SET upVec TO SHIP:UP:VECTOR.
    SET orbitVelVec TO SHIP:VELOCITY:ORBIT.

    SET radialVel TO VDOT(orbitVelVec,upVec).

    SET tangentialVelVec TO
        orbitVelVec -
        (upVec * radialVel).

    SET tangentialVel TO tangentialVelVec:MAG.

    SET radiusNow TO
        SHIP:BODY:RADIUS +
        SHIP:ALTITUDE.

    SET circularVelNow TO
        SQRT(SHIP:BODY:MU / radiusNow).

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

    SET startLead TO
        halfDvLead +
        startLeadBias.

    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,3) + " km      " AT(0,6).
    PRINT "RAD VEL: " + ROUND(radialVel,2) + " m/s     " AT(0,7).
    PRINT "TAN ERR: " + ROUND(tangentialError,1) + " m/s     " AT(0,8).
    PRINT "FULL BURN: " + ROUND(burnEstimate,2) + " s       " AT(0,10).
    PRINT "DV MIDPOINT: " + ROUND(halfDvLead,2) + " s       " AT(0,11).
    PRINT "START LEAD: " + ROUND(startLead,2) + " s       " AT(0,12).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,2) + " s       " AT(0,13).

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
PRINT "===== SV-3.3 TERMINAL =====".

SET terminalStartMET TO MISSIONTIME.
SET guidanceVec TO SHIP:PROGRADE:VECTOR.
SET steeringTargetVec TO guidanceVec.
SET throttleCmd TO 0.

LOCK STEERING TO steeringTargetVec.
LOCK THROTTLE TO throttleCmd.

SET lastFlightLog TO MISSIONTIME.
SET lastGuidanceLog TO MISSIONTIME.

UNTIL terminalComplete
      OR terminalFailed {

    SET upVec TO SHIP:UP:VECTOR.
    SET orbitVelVec TO SHIP:VELOCITY:ORBIT.

    SET radialVel TO VDOT(orbitVelVec,upVec).

    SET tangentialVelVec TO
        orbitVelVec -
        (upVec * radialVel).

    SET tangentialVel TO tangentialVelVec:MAG.

    IF tangentialVel > 1 {
        SET tangentialUnit TO tangentialVelVec:NORMALIZED.
    } ELSE {
        SET tangentialUnit TO SHIP:PROGRADE:VECTOR.
    }.

    SET currentAp TO SHIP:OBT:APOAPSIS.
    SET currentPe TO SHIP:OBT:PERIAPSIS.

    SET apOrbitError TO orbitTarget - currentAp.
    SET peOrbitError TO orbitTarget - currentPe.

    SET radiusNow TO
        SHIP:BODY:RADIUS +
        SHIP:ALTITUDE.

    SET altitudeError TO
        orbitTarget -
        SHIP:ALTITUDE.

    SET circularVelNow TO
        SQRT(SHIP:BODY:MU / radiusNow).

    SET tangentialError TO
        circularVelNow -
        tangentialVel.

    IF NOT fineLatched
       AND ABS(tangentialError) <= fineLatchTanError {

        SET fineLatched TO TRUE.

        SET STEERINGMANAGER:PITCHTS TO finePitchTS.
        SET STEERINGMANAGER:YAWTS TO fineYawTS.
        STEERINGMANAGER:RESETPIDS().

        SET steeringFineTuned TO TRUE.
        logState("FINE_MODE_LATCH").
    }.

    SET positiveTanError TO tangentialError.

    IF positiveTanError < 0 {
        SET positiveTanError TO 0.
    }.

    SET tGo TO 0.

    IF positiveTanError > 0
       AND totalMassFlow > 0 {

        SET tgoFinalMass TO
            SHIP:MASS /
            (CONSTANT:e ^ (positiveTanError / exhaustVelocity)).

        SET tGo TO
            (SHIP:MASS - tgoFinalMass)
            / totalMassFlow.
    }.

    SET gravityAccel TO
        SHIP:BODY:MU /
        (radiusNow^2).

    SET centrifugalAccel TO
        (tangentialVel^2) /
        radiusNow.

    SET naturalRadialAccel TO
        centrifugalAccel -
        gravityAccel.

    IF NOT fineLatched {

        SET radialGuidanceTime TO tGo.

        IF radialGuidanceTime < radialTgoFloor {
            SET radialGuidanceTime TO radialTgoFloor.
        }.

        SET desiredRadialAccel TO
            (6 * altitudeError / (radialGuidanceTime^2))
            -
            (4 * radialVel / radialGuidanceTime).

        IF desiredRadialAccel > radialAccelLimit {
            SET desiredRadialAccel TO radialAccelLimit.
        }.

        IF desiredRadialAccel < -radialAccelLimit {
            SET desiredRadialAccel TO -radialAccelLimit.
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
    }.

    SET radialReqAccel TO
        desiredRadialAccel -
        naturalRadialAccel.

    IF fineLatched {
        SET tangentialGain TO fineTangentialGain.
    } ELSE {
        SET tangentialGain TO coarseTangentialGain.
    }.

    SET desiredTangentialAccel TO
        tangentialGain *
        tangentialError.

    SET tangentialCoupling TO
        (radialVel * tangentialVel) /
        radiusNow.

    SET tanReqAccel TO
        desiredTangentialAccel +
        tangentialCoupling.

    IF fineLatched
       AND tanReqAccel < 0 {
        SET tanReqAccel TO 0.
    }.

    IF NOT fineLatched
       AND tanReqAccel < -2 {
        SET tanReqAccel TO -2.
    }.

    SET maxAccel TO
        SHIP:AVAILABLETHRUST /
        SHIP:MASS.

    SET radialAllocLimit TO
        maxAccel *
        radialAllocationFraction.

    SET radialAllocAccel TO
        radialReqAccel.

    IF radialAllocAccel > radialAllocLimit {
        SET radialAllocAccel TO radialAllocLimit.
    }.

    IF radialAllocAccel < -radialAllocLimit {
        SET radialAllocAccel TO -radialAllocLimit.
    }.

    SET tanCapacitySquared TO
        maxAccel^2 -
        radialAllocAccel^2.

    IF tanCapacitySquared < 0 {
        SET tanCapacitySquared TO 0.
    }.

    SET tanCapacity TO SQRT(tanCapacitySquared).
    SET tanAllocAccel TO tanReqAccel.

    IF tanAllocAccel > tanCapacity {
        SET tanAllocAccel TO tanCapacity.
    }.

    IF tanAllocAccel < -tanCapacity {
        SET tanAllocAccel TO -tanCapacity.
    }.

    SET guidanceVec TO
        (tangentialUnit * tanAllocAccel)
        +
        (upVec * radialAllocAccel).

    SET commandAccel TO guidanceVec:MAG.

    SET insideCapture TO FALSE.

    IF ABS(apOrbitError) <= apsisTolerance
       AND ABS(peOrbitError) <= apsisTolerance {

        SET insideCapture TO TRUE.
    }.

    IF insideCapture
       AND NOT captureActive {

        SET captureActive TO TRUE.
        SET captureStartMET TO MISSIONTIME.
        SET thrustActive TO FALSE.
        SET throttleCmd TO 0.
        SET steeringTargetVec TO tangentialUnit.
        LOCK THROTTLE TO throttleCmd.
        logState("CAPTURE_ENTER").
    }.

    IF captureActive {

        SET throttleCmd TO 0.
        SET steeringTargetVec TO tangentialUnit.
        LOCK THROTTLE TO throttleCmd.

        IF NOT insideCapture {

            SET captureActive TO FALSE.
            SET thrustActive TO FALSE.
            logState("CAPTURE_LOST").

        } ELSE IF
            MISSIONTIME -
            captureStartMET >= captureHoldTime {

            SET terminalComplete TO TRUE.
            logState("CAPTURE_CONFIRMED").
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
            logState("LOW_PROPULSION_DETECTED").
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

    PRINT "===== SV-3.3 TERMINAL =====" AT(0,2).

    IF captureActive {
        PRINT "MODE: CAPTURE VERIFY     " AT(0,3).
    } ELSE IF fineLatched {
        IF thrustActive {
            PRINT "MODE: FINE THRUST        " AT(0,3).
        } ELSE {
            PRINT "MODE: FINE COAST         " AT(0,3).
        }.
    } ELSE {
        PRINT "MODE: TGO + RAD PRIORITY " AT(0,3).
    }.

    PRINT "AP: " + ROUND(currentAp/1000,5) + " km      " AT(0,5).
    PRINT "PE: " + ROUND(currentPe/1000,5) + " km      " AT(0,6).
    PRINT "AP ERR: " + ROUND(apOrbitError,2) + " m       " AT(0,7).
    PRINT "PE ERR: " + ROUND(peOrbitError,2) + " m       " AT(0,8).
    PRINT "RAD VEL: " + ROUND(radialVel,4) + " m/s     " AT(0,10).
    PRINT "TAN ERR: " + ROUND(tangentialError,4) + " m/s     " AT(0,11).
    PRINT "CMD ACC: " + ROUND(commandAccel,6) + " m/s2    " AT(0,13).
    PRINT "THR OFF < " + ROUND(accelStopThreshold,4) + "        " AT(0,14).
    PRINT "THR ON  > " + ROUND(accelStartThreshold,4) + "        " AT(0,15).
    PRINT "THROTTLE: " + ROUND(throttleCmd,7) + "         " AT(0,17).
    PRINT "STEER ERR: " + ROUND(STEERINGMANAGER:ANGLEERROR,3) + " deg     " AT(0,19).
    PRINT "PITCH ERR: " + ROUND(STEERINGMANAGER:PITCHERROR,3) + " deg     " AT(0,20).
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
            ROUND(altitudeError,3) + "," +
            ROUND(radialVel,5) + "," +
            ROUND(tangentialVel,5) + "," +
            ROUND(circularVelNow,5) + "," +
            ROUND(tangentialError,5) + "," +
            ROUND(tGo,5) + "," +
            ROUND(naturalRadialAccel,5) + "," +
            ROUND(desiredRadialAccel,5) + "," +
            ROUND(radialReqAccel,5) + "," +
            ROUND(radialAllocAccel,5) + "," +
            ROUND(tanReqAccel,5) + "," +
            ROUND(tanAllocAccel,5) + "," +
            ROUND(maxAccel,5) + "," +
            ROUND(commandAccel,7) + "," +
            ROUND(throttleCmd,8) + "," +
            ROUND(currentAp,3) + "," +
            ROUND(currentPe,3) + "," +
            ROUND(apOrbitError,3) + "," +
            ROUND(peOrbitError,3) + "," +
            fineLatched + "," +
            captureActive + "," +
            ROUND(STEERINGMANAGER:ANGLEERROR,5) + "," +
            ROUND(STEERINGMANAGER:PITCHERROR,5) + "," +
            ROUND(STEERINGMANAGER:YAWERROR,5) + "," +
            ROUND(STEERINGMANAGER:PITCHTS,3) + "," +
            ROUND(STEERINGMANAGER:YAWTS,3)
        TO guidanceLog.

        SET lastGuidanceLog TO MISSIONTIME.
    }.

    IF MISSIONTIME - lastFlightLog >= 0.5 {
        logState("SV33_GUIDANCE").
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

SET upVec TO SHIP:UP:VECTOR.
SET orbitVelVec TO SHIP:VELOCITY:ORBIT.
SET finalRadialVel TO VDOT(orbitVelVec,upVec).

SET finalTangentialVec TO
    orbitVelVec -
    (upVec * finalRadialVel).

IF finalTangentialVec:MAG > 1 {
    LOCK STEERING TO finalTangentialVec:NORMALIZED.
}.

WAIT 0.25.
logState("SV33_CUTOFF").
UNLOCK STEERING.

SET finalAp TO SHIP:OBT:APOAPSIS.
SET finalPe TO SHIP:OBT:PERIAPSIS.
SET finalApError TO orbitTarget - finalAp.
SET finalPeError TO orbitTarget - finalPe.

SET upVec TO SHIP:UP:VECTOR.
SET orbitVelVec TO SHIP:VELOCITY:ORBIT.

SET finalRadialVel TO VDOT(orbitVelVec,upVec).

SET finalTangentialVec TO
    orbitVelVec -
    (upVec * finalRadialVel).

SET finalTangentialVel TO finalTangentialVec:MAG.
SET finalRadius TO SHIP:BODY:RADIUS + SHIP:ALTITUDE.
SET finalCircularVel TO SQRT(SHIP:BODY:MU / finalRadius).
SET finalTanError TO finalCircularVel - finalTangentialVel.

CLEARSCREEN.

PRINT "===== SV-3.3 GUIDANCE COMPLETE =====".
PRINT "".
PRINT "Final Ap:       " + ROUND(finalAp/1000,5) + " km".
PRINT "Final Pe:       " + ROUND(finalPe/1000,5) + " km".
PRINT "".
PRINT "Ap error:       " + ROUND(finalApError,2) + " m".
PRINT "Pe error:       " + ROUND(finalPeError,2) + " m".
PRINT "".
PRINT "Altitude:       " + ROUND(SHIP:ALTITUDE,2) + " m".
PRINT "Radial vel:     " + ROUND(finalRadialVel,5) + " m/s".
PRINT "Tan vel error:  " + ROUND(finalTanError,5) + " m/s".
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
PRINT "0:/sv33flight.csv".
PRINT "".
PRINT "GUIDANCE LOG:".
PRINT "0:/sv33guidance.csv".

logState("FINAL").
