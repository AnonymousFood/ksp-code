WAIT UNTIL SHIP:UNPACKED.
CORE:DOEVENT("Open Terminal").
CLEARSCREEN.

PRINT "=== HOHMANN TRANSFER PHASE ===".

// Define parameters for the Hohmann transfer
SET initialOrbitApo TO SHIP:ORBIT:APOAPSIS.
SET initialOrbitPeri TO SHIP:ORBIT:PERIAPSIS.
SET targetOrbitApo TO 2000000. // Example target apoapsis in meters
SET targetOrbitPeri TO 1000000. // Example target periapsis in meters

// Calculate the delta-v required for the transfer
SET deltaV1 TO SQRT(SHIP:GRAVITY:MU / initialOrbitPeri) * (SQRT(2 * targetOrbitApo / (initialOrbitPeri + targetOrbitApo)) - 1).
SET deltaV2 TO SQRT(SHIP:GRAVITY:MU / targetOrbitPeri) * (1 - SQRT(2 * initialOrbitApo / (initialOrbitApo + targetOrbitPeri))).

PRINT "Delta-V for transfer burn 1: " + ROUND(deltaV1, 2) + " m/s".
PRINT "Delta-V for transfer burn 2: " + ROUND(deltaV2, 2) + " m/s".

// Execute the first burn
LOCK THROTTLE TO 1.
LOCK STEERING TO HEADING(90, 0). // Adjust heading as necessary
WAIT UNTIL SHIP:APOAPSIS >= initialOrbitApo + 1000. // Wait until reaching the desired apoapsis

PRINT "Executing first burn...".
WAIT 5. // Duration of the burn
LOCK THROTTLE TO 0.

WAIT UNTIL SHIP:APOAPSIS >= targetOrbitApo - 1000. // Wait until reaching the target apoapsis

// Execute the second burn
LOCK THROTTLE TO 1.
LOCK STEERING TO HEADING(90, 0). // Adjust heading as necessary
WAIT UNTIL SHIP:PERIAPSIS <= targetOrbitPeri + 1000. // Wait until reaching the desired periapsis

PRINT "Executing second burn...".
WAIT 5. // Duration of the burn
LOCK THROTTLE TO 0.

PRINT "Hohmann transfer complete. Current Apoapsis: " + ROUND(SHIP:ORBIT:APOAPSIS) + "m, Current Periapsis: " + ROUND(SHIP:ORBIT:PERIAPSIS) + "m".