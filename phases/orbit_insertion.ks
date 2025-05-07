WAIT UNTIL SHIP:UNPACKED.
CORE:DOEVENT("Open Terminal").
CLEARSCREEN.

PRINT "=== ORBIT INSERTION PHASE ===".

// Set target orbit parameters
SET targetApo TO 200000. // Target apoapsis in meters
SET targetPeri TO 200000. // Target periapsis in meters

// Calculate the required delta-v for insertion
LOCAL currentApo IS SHIP:ORBIT:APOAPSIS.
LOCAL currentPeri IS SHIP:ORBIT:PERIAPSIS.
LOCAL deltaV IS 0.

// Check if we need to perform a burn for insertion
IF currentApo < targetApo OR currentPeri < targetPeri {
    // Calculate the required delta-v for the burn
    deltaV IS SQRT(SHIP:ORBIT:GRAVITY * (2 / currentPeri - 1 / targetApo) * (1 + (targetApo / currentPeri))) - SHIP:VELOCITY:ORBIT:MAG.
    
    PRINT "Required Delta-V for insertion: " + ROUND(deltaV, 2) + " m/s".

    // Execute the burn
    LOCK THROTTLE TO 1.
    WAIT UNTIL ABS(SHIP:VELOCITY:ORBIT:MAG - (SHIP:ORBIT:GRAVITY * SQRT(2 / currentPeri))) < 1.0.
    LOCK THROTTLE TO 0.
    
    PRINT "Orbit insertion burn complete.".
} ELSE {
    PRINT "No insertion burn required.".
}

// Final adjustments
WAIT UNTIL SHIP:ORBIT:APOAPSIS >= targetApo AND SHIP:ORBIT:PERIAPSIS >= targetPeri.
PRINT "Target orbit achieved: Apoapsis = " + ROUND(SHIP:ORBIT:APOAPSIS) + "m, Periapsis = " + ROUND(SHIP:ORBIT:PERIAPSIS) + "m".