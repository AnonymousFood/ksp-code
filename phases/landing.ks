WAIT UNTIL SHIP:UNPACKED.
CORE:DOEVENT("Open Terminal").
CLEARSCREEN.

PRINT "=== LANDING PHASE ===".

// Initialize landing parameters
SET landingAltitude TO 5000. // Target altitude for landing
SET descentRatePID TO PIDLOOP(0.1, 0.01, 0.5, -10, 10). // PID for controlling descent rate
SET targetDescentRate TO -5. // Target descent rate in m/s

// Main landing loop
UNTIL ALTITUDE <= landingAltitude {
    LOCAL verticalVel IS VDOT(SHIP:VELOCITY:ORBIT, SHIP:UP:VECTOR).
    
    // Use PID to adjust throttle for controlled descent
    LOCAL throttleAdjustment IS descentRatePID:UPDATE(TIME:SECONDS, verticalVel - targetDescentRate).
    LOCK THROTTLE TO MAX(0, MIN(1, 1 + throttleAdjustment)).
    
    PRINT "Altitude: " + ROUND(ALTITUDE) + "m    " AT (0,4).
    PRINT "Vertical Velocity: " + ROUND(verticalVel, 2) + " m/s    " AT (0,5).
    PRINT "Throttle: " + ROUND(THROTTLE * 100, 1) + "%    " AT (0,6).
    
    WAIT 0.1.
}

// Final landing sequence
LOCK THROTTLE TO 0.
PRINT "Touchdown!" AT (0,8).
WAIT 2.
CLEARSCREEN.
PRINT "Landing complete. Mission accomplished!".