WAIT UNTIL SHIP:UNPACKED.
CORE:DOEVENT("Open Terminal").
CLEARSCREEN.

PRINT "=== PLANE CHANGE PHASE ===".

// Define the target inclination and current inclination
SET targetInclination TO 45.0. // Example target inclination in degrees
SET currentInclination TO SHIP:ORBIT:INCLINATION.

// Calculate the required delta-v for the plane change
LOCAL deltaV IS 0.
IF ABS(currentInclination - targetInclination) > 0.1 {
    // Calculate the delta-v needed for the plane change
    LOCAL inclinationDifference IS ABS(currentInclination - targetInclination).
    LOCAL velocityAtApoapsis IS SQRT(SHIP:ORBIT:GRAVITY * (SHIP:ORBIT:APOAPSIS + SHIP:ORBIT:PERIAPSIS) / 2).
    deltaV IS 2 * velocityAtApoapsis * SIN(inclinationDifference / 2).
}

// Execute the burn for the plane change
IF deltaV > 0 {
    PRINT "Executing plane change burn: " + ROUND(deltaV, 2) + " m/s.".
    LOCK THROTTLE TO 1.
    WAIT 1. // Wait for 1 second before starting the burn
    LOCK THROTTLE TO MAX(deltaV / SHIP:MAXTHRUST, 0.1). // Adjust throttle based on delta-v
    WAIT 5. // Duration of the burn, adjust as necessary
    LOCK THROTTLE TO 0.
    PRINT "Plane change burn complete.".
} ELSE {
    PRINT "No plane change required.".
}

// Final adjustments and cleanup
CLEARSCREEN.
PRINT "Plane change phase completed. Current Inclination: " + ROUND(SHIP:ORBIT:INCLINATION, 2) + "°".

setPhase("PLANE CHANGE").
addMissionData("Target Inc", targetInclination, "°", 1).
addMissionData("Current Inc", SHIP:ORBIT:INCLINATION, "°", 1).