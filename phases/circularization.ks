PRINT "=== CIRCULARIZATION PHASE ===".

// Set phase in display system
setPhase("CIRCULARIZATION").

// Initialize PID controller for vertical velocity control
SET verticalVelPID TO PIDLOOP(0.5, 0.1, 0.1, -45, 45).
SET verticalVelPID:SETPOINT TO 0.

// Wait until out of atmosphere if not already
IF ALTITUDE < 70000 {
    addMissionData("Status", "Exiting atmosphere", "", 0).
    WAIT UNTIL ALTITUDE > 70000.
}

// Calculate time to wait before apoapsis
LOCAL burnTime TO 0.
LOCAL shipAccel TO SHIP:MAXTHRUST / SHIP:MASS.
IF shipAccel > 0 {
    SET burnTime TO MIN(60, MAX(15, 500 / shipAccel)).
    addMissionData("Burn Time", burnTime, "s", 0).
} ELSE {
    SET burnTime TO 30. // Default
    addMissionData("Burn Time", burnTime, "s (default)", 0).
}

// Time warp to approach apoapsis
addMissionData("Status", "Warping to apoapsis", "", 0).
SET WARPMODE TO "RAILS".
WARPTO(TIME:SECONDS + ETA:APOAPSIS - burnTime/2).

// Wait until close to apoapsis
WAIT UNTIL ETA:APOAPSIS < burnTime/2.

// Point prograde for optimal burn
addMissionData("Status", "Aligning for burn", "", 0).
LOCK STEERING TO PROGRADE.
WAIT 5. // Give time to align with prograde

// Begin circularization
addMissionData("Status", "Executing burn", "", 0).
SET initialApo TO SHIP:ORBIT:APOAPSIS.
LOCK THROTTLE TO 0.5. // Start at half throttle

// Add initial telemetry data to display
addMissionData("Target Ratio", 0.05, "", 2).
addMissionData("Initial Apo", initialApo/1000, "km", 1).
addMissionData("Vertical Vel", 0, "m/s", 2).
addMissionData("Pitch Adjust", 0, "°", 1).

UNTIL ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) < 0.05 OR 
      SHIP:ORBIT:PERIAPSIS > initialApo * 1.05 OR 
      SHIP:ORBIT:APOAPSIS > initialApo * 1.05 {
    
    // Calculate vertical velocity component
    LOCAL verticalVel IS VDOT(SHIP:VELOCITY:ORBIT, SHIP:UP:VECTOR).
    
    // Use PID to calculate pitch adjustment needed to maintain 0 vertical velocity
    LOCAL pitchAdjustment IS verticalVelPID:UPDATE(TIME:SECONDS, verticalVel).
    
    // Calculate steering vector
    LOCAL hVel IS VXCL(SHIP:UP:VECTOR, SHIP:VELOCITY:ORBIT).
    IF hVel:MAG > 0.1 {
        LOCAL hDir IS hVel:NORMALIZED.
        LOCAL targetDir IS hDir * COS(pitchAdjustment) + SHIP:UP:VECTOR * SIN(pitchAdjustment).
        LOCK STEERING TO LOOKDIRUP(targetDir, SHIP:UP:VECTOR).
    } ELSE {
        // Fallback if horizontal velocity is too small
        LOCK STEERING TO HEADING(90, 90 + pitchAdjustment).
    }
    
    // Dynamic throttle control - reduce throttle as orbit becomes circular
    LOCAL orbitRatio IS ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS) / SHIP:ORBIT:APOAPSIS.
    LOCAL throttleSetting IS MIN(1.0, MAX(0.1, orbitRatio * 2)).
    LOCK THROTTLE TO throttleSetting.
    
    // Update telemetry in universal display
    addMissionData("Vertical Vel", verticalVel, "m/s", 2).
    addMissionData("Pitch Adjust", pitchAdjustment, "°", 1).
    addMissionData("Throttle", throttleSetting*100, "%", 0).
    addMissionData("Eccentricity", SHIP:ORBIT:ECCENTRICITY, "", 3).
    addMissionData("Orbit diff", ABS(SHIP:ORBIT:APOAPSIS - SHIP:ORBIT:PERIAPSIS)/1000, "km", 1).
    
    WAIT 0.1.
}.

// Shutdown
LOCK THROTTLE TO 0.
UNLOCK STEERING.

// Update final status
addMissionData("Status", "Circularization complete", "", 0).
addMissionData("Final Orbit", ROUND(SHIP:ORBIT:APOAPSIS/1000,1) + " × " + ROUND(SHIP:ORBIT:PERIAPSIS/1000,1), "km", 0).

PRINT "Orbit circularized at " + ROUND(SHIP:ORBIT:APOAPSIS/1000,1) + " × " + 
      ROUND(SHIP:ORBIT:PERIAPSIS/1000,1) + " km".

// End of circularization phase