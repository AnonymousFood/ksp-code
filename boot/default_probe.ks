// Basic launch script for altitude 9000-13000m at 90-170m/s
CLEARSCREEN.
PRINT "Initializing launch sequence...".

// Set initial parameters
LOCK THROTTLE TO 1.
LOCK STEERING TO UP.

// Wait for engine startup
PRINT "Engine startup in 3...".
WAIT 3.

// Launch sequence
STAGE.
PRINT "Liftoff!".

UNTIL ALT:RADAR >= 9000 {
    // Check if current stage is out of fuel
    IF STAGE:RESOURCESLEX["LIQUIDFUEL"]:AMOUNT <= 0.1 {
        PRINT "Staging...".
        STAGE.
        WAIT 1.
    }
    
    // Throttle control based on speed
    IF SHIP:VELOCITY:SURFACE:MAG > 170 {
        LOCK THROTTLE TO 0.5.
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG < 90 {
        LOCK THROTTLE TO 1.
    }
    
    // Print telemetry
    PRINT "Altitude: " + ROUND(ALT:RADAR,0) + "m    " AT (0,10).
    PRINT "Speed: " + ROUND(SHIP:VELOCITY:SURFACE:MAG,1) + "m/s    " AT (0,11).
    
    WAIT 0.1.
}

// Cut throttle when target altitude reached
LOCK THROTTLE TO 0.
PRINT "Target altitude reached!".
PRINT "Final altitude: " + ROUND(ALT:RADAR,0) + "m".
PRINT "Final speed: " + ROUND(SHIP:VELOCITY:SURFACE:MAG,1) + "m/s".