//First, we'll clear the terminal screen to make it look nice
CLEARSCREEN.

SET turnStartAltitude TO 500.
SET turnEndAltitude TO 70000.
SET orbitHeight TO 22000000.
SET marginOfError TO 0.01.
SET compass to 0. // degrees from north going clockwise

LOCK THROTTLE TO 1.0.  // 1.0 is the max, 0.0 is idle.

SET V0 TO GETVOICE(0). // Gets a reference to the zero-th voice in the chip.

PRINT "Counting down:".
FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1.
    V0:PLAY( NOTE(130, 0.2)).  // Starts a note at 400 Hz for 2.5 seconds.
}

STAGE.
print "Liftoff!".

SET oldMaxThrust TO MAXTHRUST.
WHEN MAXTHRUST < oldMaxThrust / 3 or MAXTHRUST = 0 THEN {
    PRINT "Staging".
    PRINT "MAXTHRUST: " + MAXTHRUST + "oldMaxThrust: " + oldMaxThrust AT (0,23).
    STAGE.
    SET oldMaxThrust TO MAXTHRUST.
    PRESERVE.
}.

// --------
//  ASCENT
// --------
LOCK STEERING TO HEADING(compass, 90).
UNTIL SHIP:APOAPSIS >= orbitHeight {
    IF ALTITUDE < turnStartAltitude { // No turn yet
        LOCK STEERING TO HEADING(compass, 90).
    } ELSE IF ALTITUDE > turnStartAltitude and ALTITUDE < turnEndAltitude { // Gravity turn
        SET pitch TO 90 * (1 - ((ALTITUDE - turnStartAltitude) / (turnEndAltitude - turnStartAltitude))^0.7).
        LOCK STEERING TO HEADING(compass, MAX(pitch, 0)).
    }

    IF SHIP:APOAPSIS >= orbitHeight * 0.9 { // Slow down for more precise burn
        LOCK THROTTLE TO 0.1 + (1 - (SHIP:APOAPSIS/orbitHeight) * 0.9).
    }

    WAIT 0.1.
}.

PRINT "Apoapsis " + APOAPSIS + " reached target of " + orbitHeight + ".".
LOCK THROTTLE TO 0.

WAIT 3.
PRINT "Warping to apoapsis in " + ROUND(ETA:APOAPSIS - 60) + "s.".
SET WARPMODE TO "PHYSICS".  // Start with physics warp
SET WARPTIME TO TIME:SECONDS + ETA:APOAPSIS - 60.
SET WARP TO 4.
WARPTO(WARPTIME).

WAIT UNTIL ALTITUDE >= 70000.

PRINT "Deploying Solar Panels...".
PANELS ON.
WAIT 3.

PRINT "Warping to apoapsis in " + ROUND(ETA:APOAPSIS - 60) + "s.".
SET WARPMODE TO "RAILS".
SET WARPTIME TO TIME:SECONDS + ETA:APOAPSIS - 60.
WARPTO(WARPTIME).

// ----------------------
//  Circularization Burn
// ----------------------
LOCK STEERING TO PROGRADE.
UNTIL SHIP:ORBIT:PERIAPSIS >= orbitHeight {
    IF 1 - (SHIP:ORBIT:PERIAPSIS/orbitHeight) <= marginOfError { BREAK. } // Exits loop when close enough
    IF ETA:APOAPSIS <= 30 {
        LOCK THROTTLE TO 0.1 + (1 - (SHIP:ORBIT:PERIAPSIS/orbitHeight) * 0.9).
        PRINT "Periapsis: " + ROUND(SHIP:ORBIT:PERIAPSIS, 0) + "m        " AT (0, 20).
        PRINT "Apoapsis: "  + ROUND(SHIP:ORBIT:APOAPSIS, 0)  + "m        " AT (0, 21).
    } ELSE {
        PRINT "Beginning Circularization Burn in " + ROUND(ETA:APOAPSIS - 30) + "s." AT (0, 22).
    }
    WAIT 0.1.
}

//At this point, our apoapsis is above 100km and our main loop has ended. Next
//we'll make sure our throttle is zero and that we're pointed prograde
LOCK THROTTLE TO 0.

//This sets the user's throttle setting to zero to prevent the throttle
//from returning to the position it was at before the script was run.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

// Shuts off all engines in case of electrical failure
LIST ENGINES IN engList.
FOR eng IN engList {
    print "Shutting off engine: " + eng:NAME + "...".
    eng:SHUTDOWN().
}.

WAIT 1.
PRINT "Mission complete!".