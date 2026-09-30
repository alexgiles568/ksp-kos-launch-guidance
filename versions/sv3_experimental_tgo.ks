// ======================================================
// 0.625 m TWO-STAGE LIQUID LAUNCHER
// SV-3: TIME-TO-GO STATE VECTOR GUIDANCE
//
// Target: 80 x 80 km Kerbin orbit
//
// Experimental branch:
// - Mass-sensitive burn-start timing.
// - Time-to-go radial terminal law.
// - Fine SV-2.1 guidance near the final orbit.
// - No control allocation under thrust saturation yet.
//
// FAIRING MUST BE ON ACTION GROUP 1
// ======================================================

CLEARSCREEN.

SET orbitTarget TO 80000.
SET etaTarget TO 50.

SET sepMinAlt TO 27000.
SET sepMaxQ TO 0.06.

SET fairingMinAlt TO 60000.
SET fairingMaxQ TO 0.0005.

SET coarseTangentialGain TO 0.35.

SET fineBand TO 1000.
SET fineRadialTimeConstant TO 25.
SET fineRadialVelGain TO 0.16.
SET fineTangentialGain TO 0.12.

SET radialVelMax TO 90.
SET radialTgoFloor TO 4.
SET radialAccelLimit TO 6.
SET startLeadBias TO 0.8.

SET accelDeadband TO 0.002.
SET apsisTolerance TO 25.
SET captureHoldTime TO 0.5.

SET terminalMaxTime TO 180.
SET engineFailureHoldTime TO 2.

SET boosterBurnout TO FALSE.
SET boosterDropped TO FALSE.
SET fairingDeployed TO FALSE.
SET ascentDone TO FALSE.
SET terminalComplete TO FALSE.
SET terminalFailed TO FALSE.
SET fineMode TO FALSE.
SET captureActive TO FALSE.
SET captureStartMET TO 0.
SET lowDvStart TO -1.
SET pitchCmd TO 90.
SET throttleCmd TO 0.

SET flightLog TO "0:/sv3flight.csv".
SET guidanceLog TO "0:/sv3guidance.csv".

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
"MET,mode,alt_m,alt_error_m,radial_vel_mps,tangential_vel_mps,circular_vel_mps,tangential_error_mps,tgo_s,natural_radial_accel,desired_radial_accel,radial_thrust_accel,tangential_thrust_accel,max_accel,command_accel,throttle,ap_m,pe_m,ap_error_m,pe_error_m,capture"
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
        ROUND(throttleCmd,6) + "," +
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
PRINT "SV-3 TIME-TO-GO GUIDANCE".
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

SET throttleCmd TO 0.
LOCK THROTTLE TO throttleCmd.
LOCK STEERING TO SRFPROGRADE.
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

    IF MISSIONTIME - lastLog >= 0.25 {
        logState("UPPER_ASCENT").
        SET lastLog TO MISSIONTIME.
    }.

    WAIT 0.02.
}.

SET throttleCmd TO 0.
LOCK THROTTLE TO throttleCmd.
LOCK STEERING TO PROGRADE.

UNTIL SHIP:ALTITUDE >= 60000
      AND SHIP:Q <= 0.0005 {

    checkFairing().

    IF MISSIONTIME - lastLog >= 0.5 {
        logState("ATMOSPHERIC_COAST").
        SET lastLog TO MISSIONTIME.
    }.

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

        SET totalMassFlow TO totalMassFlow + oneMassFlow.
    }.
}.

IF totalMassFlow > 0 {

    SET effectiveISP TO
        SHIP:AVAILABLETHRUST /
        (totalMassFlow * CONSTANT:g0).
}.

SET exhaustVelocity TO effectiveISP * CONSTANT:g0.

CLEARSCREEN.
PRINT "===== SV-3 GUIDANCE ACQUISITION =====".

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

    SET radiusNow TO SHIP:BODY:RADIUS + SHIP:ALTITUDE.
    SET circularVelNow TO SQRT(SHIP:BODY:MU / radiusNow).
    SET altitudeError TO orbitTarget - SHIP:ALTITUDE.
    SET tangentialError TO circularVelNow - tangentialVel.

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

    SET startLead TO halfDvLead + startLeadBias.

    PRINT "ALT: " + ROUND(SHIP:ALTITUDE/1000,3) + " km      " AT(0,6).
    PRINT "RAD VEL: " + ROUND(radialVel,2) + " m/s     " AT(0,7).
    PRINT "TAN VEL: " + ROUND(tangentialVel,2) + " m/s     " AT(0,8).
    PRINT "CIRC VEL: " + ROUND(circularVelNow,2) + " m/s     " AT(0,9).
    PRINT "DV EST: " + ROUND(dvEstimate,1) + " m/s     " AT(0,11).
    PRINT "FULL BURN: " + ROUND(burnEstimate,2) + " s       " AT(0,12).
    PRINT "DV MIDPOINT: " + ROUND(halfDvLead,2) + " s       " AT(0,13).
    PRINT "START LEAD: " + ROUND(startLead,2) + " s       " AT(0,14).
    PRINT "ETA AP: " + ROUND(ETA:APOAPSIS,2) + " s       " AT(0,15).

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
PRINT "===== SV-3 TERMINAL GUIDANCE =====".

SET terminalStartMET TO MISSIONTIME.
SET guidanceVec TO SHIP:PROGRADE:VECTOR.
SET throttleCmd TO 0.

LOCK STEERING TO guidanceVec.
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

    SET radiusNow TO SHIP:BODY:RADIUS + SHIP:ALTITUDE.
    SET altitudeError TO orbitTarget - SHIP:ALTITUDE.
    SET circularVelNow TO SQRT(SHIP:BODY:MU / radiusNow).
    SET tangentialError TO circularVelNow - tangentialVel.

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

    IF ABS(apOrbitError) <= fineBand
       AND ABS(peOrbitError) <= fineBand {
        SET fineMode TO TRUE.
    } ELSE {
        SET fineMode TO FALSE.
    }.

    SET gravityAccel TO SHIP:BODY:MU / (radiusNow^2).
    SET centrifugalAccel TO (tangentialVel^2) / radiusNow.
    SET naturalRadialAccel TO centrifugalAccel - gravityAccel.

    IF NOT fineMode {

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

    SET radialThrustAccel TO
        desiredRadialAccel -
        naturalRadialAccel.

    IF fineMode {
        SET tangentialGain TO fineTangentialGain.
    } ELSE {
        SET tangentialGain TO coarseTangentialGain.
    }.

    SET desiredTangentialAccel TO tangentialGain * tangentialError.

    SET tangentialCoupling TO
        (radialVel * tangentialVel) /
        radiusNow.

    SET tangentialThrustAccel TO
        desiredTangentialAccel +
        tangentialCoupling.

    IF fineMode
       AND tangentialThrustAccel < 0 {
        SET tangentialThrustAccel TO 0.
    }.

    IF NOT fineMode
       AND tangentialThrustAccel < -2 {
        SET tangentialThrustAccel TO -2.
    }.

    SET guidanceVec TO
        (tangentialUnit * tangentialThrustAccel)
        +
        (upVec * radialThrustAccel).

    SET commandAccel TO guidanceVec:MAG.
    SET maxAccel TO SHIP:AVAILABLETHRUST / SHIP:MASS.

    SET insideCapture TO FALSE.

    IF ABS(apOrbitError) <= apsisTolerance
       AND ABS(peOrbitError) <= apsisTolerance {
        SET insideCapture TO TRUE.
    }.

    IF insideCapture
       AND NOT captureActive {

        SET captureActive TO TRUE.
        SET captureStartMET TO MISSIONTIME.
        SET throttleCmd TO 0.
        LOCK THROTTLE TO throttleCmd.
        LOCK STEERING TO tangentialUnit.
        logState("CAPTURE_ENTER").
    }.

    IF captureActive {

        SET throttleCmd TO 0.
        LOCK THROTTLE TO throttleCmd.
        LOCK STEERING TO tangentialUnit.

        IF NOT insideCapture {

            SET captureActive TO FALSE.
            logState("CAPTURE_LOST").

        } ELSE IF MISSIONTIME - captureStartMET >= captureHoldTime {

            SET terminalComplete TO TRUE.
            logState("CAPTURE_CONFIRMED").
        }.

    } ELSE {

        IF commandAccel < accelDeadband {

            SET throttleCmd TO 0.
            LOCK THROTTLE TO throttleCmd.
            LOCK STEERING TO tangentialUnit.

        } ELSE {

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

            IF guidanceVec:MAG > 0.0001 {
                LOCK STEERING TO guidanceVec.
            } ELSE {
                LOCK STEERING TO tangentialUnit.
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

    PRINT "===== SV-3 TERMINAL =====" AT(0,2).

    IF captureActive {
        PRINT "MODE: CAPTURE VERIFY    " AT(0,3).
    } ELSE IF fineMode {
        PRINT "MODE: FINE GUIDANCE     " AT(0,3).
    } ELSE {
        PRINT "MODE: TGO GUIDANCE      " AT(0,3).
    }.

    PRINT "AP: " + ROUND(currentAp/1000,4) + " km       " AT(0,5).
    PRINT "PE: " + ROUND(currentPe/1000,4) + " km       " AT(0,6).
    PRINT "AP ERR: " + ROUND(apOrbitError,2) + " m        " AT(0,7).
    PRINT "PE ERR: " + ROUND(peOrbitError,2) + " m        " AT(0,8).
    PRINT "ALT: " + ROUND(SHIP:ALTITUDE,2) + " m        " AT(0,10).
    PRINT "RAD VEL: " + ROUND(radialVel,3) + " m/s      " AT(0,11).
    PRINT "TAN ERR: " + ROUND(tangentialError,3) + " m/s      " AT(0,12).
    PRINT "TGO: " + ROUND(tGo,3) + " s        " AT(0,14).
    PRINT "RAD ACC DES: " + ROUND(desiredRadialAccel,3) + " m/s2     " AT(0,15).
    PRINT "RAD THR ACC: " + ROUND(radialThrustAccel,3) + " m/s2     " AT(0,16).
    PRINT "TAN THR ACC: " + ROUND(tangentialThrustAccel,3) + " m/s2     " AT(0,17).
    PRINT "THROTTLE: " + ROUND(throttleCmd,6) + "          " AT(0,19).
    PRINT "DV LEFT: " + ROUND(SHIP:DELTAV:CURRENT,1) + " m/s      " AT(0,22).

    IF MISSIONTIME - lastGuidanceLog >= 0.1 {

        SET modeText TO "TGO".

        IF fineMode {
            SET modeText TO "FINE".
        }.

        IF captureActive {
            SET modeText TO "CAPTURE".
        }.

        LOG
            ROUND(MISSIONTIME,3) + "," +
            modeText + "," +
            ROUND(SHIP:ALTITUDE,3) + "," +
            ROUND(altitudeError,3) + "," +
            ROUND(radialVel,5) + "," +
            ROUND(tangentialVel,5) + "," +
            ROUND(circularVelNow,5) + "," +
            ROUND(tangentialError,5) + "," +
            ROUND(tGo,5) + "," +
            ROUND(naturalRadialAccel,5) + "," +
            ROUND(desiredRadialAccel,5) + "," +
            ROUND(radialThrustAccel,5) + "," +
            ROUND(tangentialThrustAccel,5) + "," +
            ROUND(maxAccel,5) + "," +
            ROUND(commandAccel,6) + "," +
            ROUND(throttleCmd,7) + "," +
            ROUND(currentAp,3) + "," +
            ROUND(currentPe,3) + "," +
            ROUND(apOrbitError,3) + "," +
            ROUND(peOrbitError,3) + "," +
            captureActive
        TO guidanceLog.

        SET lastGuidanceLog TO MISSIONTIME.
    }.

    IF MISSIONTIME - lastFlightLog >= 0.5 {
        logState("SV3_GUIDANCE").
        SET lastFlightLog TO MISSIONTIME.
    }.

    WAIT 0.02.
}.

SET throttleCmd TO 0.
LOCK THROTTLE TO throttleCmd.

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
logState("SV3_CUTOFF").
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

PRINT "===== SV-3 GUIDANCE COMPLETE =====".
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
PRINT "0:/sv3flight.csv".
PRINT "".
PRINT "GUIDANCE LOG:".
PRINT "0:/sv3guidance.csv".

logState("FINAL").
