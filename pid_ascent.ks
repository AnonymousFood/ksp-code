WAIT UNTIL SHIP:UNPACKED.
CORE:DOEVENT("Open Terminal").
CLEARSCREEN.

IF ALTITUDE > 100 {
    PRINT "ERROR: Ship already in flight (Alt: " + ROUND(ALTITUDE,0) + "m)".
    PRINT "Launch script must start on the ground.".
    PRINT 1/0.
}

SET LAUNCH_CFG TO LEXICON(
    "turnStartAlt", 500,
    "turnEndAlt", 70000,
    "targetApo", 200000,
    "margin", 0.01,
    "compass", 90
).

SET pitchPID TO PIDLOOP(0.05, 0.01, 0.3, 0, 90).

CLEARSCREEN.
SET currentPitch TO 90.
LOCK STEERING TO HEADING(LAUNCH_CFG:compass, currentPitch).
LOCK THROTTLE TO 1.
STAGE.

SET oldThrust TO MAXTHRUST.
FUNCTION doStage {
    // Store current control states
    LOCAL oldThrottle IS THROTTLE.
    LOCAL oldPitch IS currentPitch.
    
    // Pause controls
    LOCK THROTTLE TO 0.
    PRINT "Staging..." AT (0,8).
    
    // Execute staging
    WAIT 1.
    STAGE.
    SET oldThrust TO MAXTHRUST.
    
    // Resume controls
    WAIT 2.
    LOCK THROTTLE TO oldThrottle.
    SET currentPitch TO oldPitch.
    PRINT "Stage Complete" AT (0,8).
    PRINT "            " AT (0,8).  // Clear message
}.

FUNCTION updateTelemetry {
    CLEARSCREEN.
    PRINT "=== ASCENT TELEMETRY ===".
    PRINT "Altitude: " + ROUND(ALTITUDE) + "m".
    PRINT "Apoapsis: " + ROUND(SHIP:APOAPSIS/1000,1) + " km".
    PRINT "Periapsis: " + ROUND(SHIP:ORBIT:PERIAPSIS/1000,1) + " km".
    PRINT "Current Pitch: " + ROUND(currentPitch,1) + "°".
    PRINT "Stage: " + STAGE:NUMBER.
    PRINT "Vertical Vel: " + ROUND(VDOT(SHIP:VELOCITY:ORBIT, SHIP:UP:VECTOR),1) + " m/s".
    PRINT "Delta-V Remaining: " + ROUND(SHIP:DELTAV:CURRENT,1) + " m/s".
}

// Staging trigger
WHEN MAXTHRUST < oldThrust * 0.8 OR MAXTHRUST = 0 THEN {
    IF STAGE:NUMBER > 0 {
        doStage().
        PRESERVE.
    }
}.

WHEN ALTITUDE > 70000 THEN {
    AG10 ON.
    WAIT 2.
    PANELS ON.
}.

SET verticalVelPID TO PIDLOOP(0.5, 0.1, 0.1, -45, 45).
SET verticalVelPID:SETPOINT TO 0.

// Main ascent loop
UNTIL SHIP:APOAPSIS >= LAUNCH_CFG:targetApo {
    IF ALTITUDE > LAUNCH_CFG:turnStartAlt AND ALTITUDE < LAUNCH_CFG:turnEndAlt {
        IF SHIP:VELOCITY:SURFACE:MAG > 100 {
            LOCAL targetPitch IS 90 * (1 - ((ALTITUDE - LAUNCH_CFG:turnStartAlt) / 
                                          (LAUNCH_CFG:turnEndAlt - LAUNCH_CFG:turnStartAlt))^0.7).
            LOCAL prog IS SHIP:VELOCITY:ORBIT:NORMALIZED.
            LOCAL face IS SHIP:FACING:VECTOR.
            LOCAL offset IS VANG(face, prog).
            IF VDOT(VCRS(face, prog), SHIP:UP:VECTOR) < 0 { SET offset TO -offset. }
            
            LOCAL adj IS pitchPID:UPDATE(TIME:SECONDS, offset).
            SET currentPitch TO targetPitch - adj.
            SET currentPitch TO MIN(90, MAX(0, currentPitch)).
        }

        IF ALTITUDE > 70000 {
            LOCAL verticalVel IS VDOT(SHIP:VELOCITY:ORBIT, SHIP:UP:VECTOR).
            
            IF verticalVel < 2 {
                LOCAL velAdjustment IS verticalVelPID:UPDATE(TIME:SECONDS, MAX(0, verticalVel)).

                SET currentPitch TO MAX(0, MIN(90, currentPitch - velAdjustment)).
            }
        }
    }
    
    IF SHIP:APOAPSIS >= LAUNCH_CFG:targetApo * 0.9 {
        LOCK THROTTLE TO MAX((LAUNCH_CFG:targetApo - SHIP:APOAPSIS) / LAUNCH_CFG:targetApo, 0.1).
    }
    
    updateTelemetry().
    WAIT 0.1.
}.

LOCK THROTTLE TO 0.

WAIT UNTIL ALTITUDE > 70000.

WAIT 5.

PRINT "Warping to apoapsis - " + ROUND(ETA:APOAPSIS - 60) + "s remaining".
SET WARPMODE TO "RAILS".
SET WARPTIME TO TIME:SECONDS + ETA:APOAPSIS - 60.
WARPTO(WARPTIME).

WAIT UNTIL ETA:APOAPSIS < 10.

SET initialApo TO SHIP:ORBIT:APOAPSIS.
LOCK THROTTLE TO 1.
UNTIL ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) < 1000 OR 
      SHIP:ORBIT:PERIAPSIS > initialApo * 1.05 OR 
      SHIP:ORBIT:APOAPSIS > initialApo * 1.05 {
    
    LOCAL verticalVel IS VDOT(SHIP:VELOCITY:ORBIT, SHIP:UP:VECTOR).
    
    // Use PID to calculate pitch adjustment needed to maintain 0 vertical velocity
    LOCAL pitchAdjustment IS verticalVelPID:UPDATE(TIME:SECONDS, verticalVel).
    
    LOCAL hVel IS VXCL(SHIP:UP:VECTOR, SHIP:VELOCITY:ORBIT).
    IF hVel:MAG > 0.1 {
        LOCAL hDir IS hVel:NORMALIZED.
        LOCAL targetDir IS hDir * COS(pitchAdjustment) + SHIP:UP:VECTOR * SIN(pitchAdjustment).
        LOCK STEERING TO LOOKDIRUP(targetDir, SHIP:UP:VECTOR).
    } ELSE {
        // Fallback if horizontal velocity is too small
        LOCK STEERING TO HEADING(90, 90 + pitchAdjustment).
    }
    
    // reduce throttle
    LOCAL orbitRatio IS ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) / SHIP:ORBIT:APOAPSIS.
    LOCAL throttleSetting IS MIN(0.8, MAX(0.05, orbitRatio * 2)).
    LOCK THROTTLE TO throttleSetting.
    
    updateTelemetry().
    WAIT 0.1.
}.

// Shutdown
LOCK THROTTLE TO 0.
CLEARSCREEN.
PRINT "Orbit achieved: " + ROUND(SHIP:ORBIT:APOAPSIS) + "m x " + ROUND(SHIP:ORBIT:PERIAPSIS) + "m".