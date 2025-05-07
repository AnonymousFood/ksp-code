// At the beginning of the script
setPhase("ASCENT").

// Initialize PID controllers
SET pitchPid TO PIDLOOP(0.05, 0.01, 0.3, 0, 90).
SET verticalVelPid TO PIDLOOP(0.5, 0.1, 0.1, -45, 45).
SET verticalVelPid:SETPOINT TO 0.

PRINT("Running ascent phase...").

// Initialize flight control
SET currentPitch TO 90.
LOCK STEERING TO HEADING(ORBITAL_CFG:targetInc, currentPitch).
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
}

// Staging trigger
WHEN MAXTHRUST < oldThrust * 0.8 OR MAXTHRUST = 0 THEN {
    IF STAGE:NUMBER > 0 {
        doStage().
        PRESERVE.
    }
}

WHEN ALTITUDE > 70000 THEN {
    AG10 ON.
    WAIT 2.
    PANELS ON.
}

PRINT "Current altitude: " + ROUND(ALTITUDE) + "m".
PRINT "Current apoapsis: " + ROUND(SHIP:APOAPSIS) + "m".
PRINT "Target apoapsis: " + ORBITAL_CFG:targetApo + "m".

// PID controller for precise apoapsis control
SET apoPid TO PIDLOOP(0.4, 0.1, 0.2).
SET apoPid:SETPOINT TO 0.

// Variables for acceleration tracking
SET lastApo TO SHIP:APOAPSIS.
SET lastTime TO TIME:SECONDS.
SET apoRate TO 0. // Rate of apoapsis change (m/s)

// Main ascent loop
UNTIL SHIP:APOAPSIS >= ORBITAL_CFG:targetApo {
    // Calculate rate of apoapsis change (for prediction)
    IF TIME:SECONDS > lastTime + 0.5 {
        SET apoRate TO (SHIP:APOAPSIS - lastApo) / (TIME:SECONDS - lastTime).
        SET lastApo TO SHIP:APOAPSIS.
        SET lastTime TO TIME:SECONDS.
    }

    IF ALTITUDE > LAUNCH_CFG:turnStartAlt AND ALTITUDE < LAUNCH_CFG:turnEndAlt {
        IF SHIP:VELOCITY:SURFACE:MAG > 100 {
            LOCAL targetPitch IS 90 * (1 - ((ALTITUDE - LAUNCH_CFG:turnStartAlt) / 
                                          (LAUNCH_CFG:turnEndAlt - LAUNCH_CFG:turnStartAlt))^0.7).
            LOCAL progradeVector IS SHIP:VELOCITY:ORBIT:NORMALIZED.
            LOCAL facingVector IS SHIP:FACING:VECTOR.
            LOCAL angleOffset IS VANG(facingVector, progradeVector).
            IF VDOT(VCRS(facingVector, progradeVector), SHIP:UP:VECTOR) < 0 { 
                SET angleOffset TO -angleOffset. 
            }
            
            LOCAL pitchAdjustment IS pitchPid:UPDATE(TIME:SECONDS, angleOffset).
            SET currentPitch TO targetPitch - pitchAdjustment.
            SET currentPitch TO MIN(90, MAX(0, currentPitch)).
        }

        IF ALTITUDE > 70000 {
            LOCAL verticalVel IS VDOT(SHIP:VELOCITY:ORBIT, SHIP:UP:VECTOR).
            
            IF verticalVel < 2 {
                LOCAL velAdjustment IS verticalVelPid:UPDATE(TIME:SECONDS, MAX(0, verticalVel)).
                SET currentPitch TO MAX(0, MIN(90, currentPitch - velAdjustment)).
            }
        }
    }
    
    IF SHIP:APOAPSIS >= ORBITAL_CFG:targetApo * 0.90 {
        LOCK THROTTLE TO MAX((ORBITAL_CFG:targetApo - SHIP:APOAPSIS) / (ORBITAL_CFG:targetApo * 0.1), 0.1).
    }
    
    // Enhanced throttle control for final approach
    IF SHIP:APOAPSIS >= ORBITAL_CFG:targetApo * 0.85 {
        // Calculate predicted overshoot based on current acceleration
        LOCAL timeToKill TO 0.5. // Estimated engine shutdown delay (in seconds)
        LOCAL predictedApo TO SHIP:APOAPSIS + (apoRate * timeToKill).
        LOCAL apoDiff TO ORBITAL_CFG:targetApo - predictedApo.
        
        // Use PID controller for final adjustments
        LOCAL throttleCmd TO apoPid:UPDATE(TIME:SECONDS, apoDiff).
        
        // Multi-stage throttle scaling
        IF predictedApo >= ORBITAL_CFG:targetApo {
            // We're projected to overshoot, cut throttle immediately
            LOCK THROTTLE TO 0.
        } ELSE IF SHIP:APOAPSIS >= ORBITAL_CFG:targetApo * 0.98 {
            // Final approach - very precise control
            LOCK THROTTLE TO MAX(0.05, MIN(0.2, throttleCmd)).
        } ELSE IF SHIP:APOAPSIS >= ORBITAL_CFG:targetApo * 0.95 {
            // Getting close - moderate throttle
            LOCK THROTTLE TO MAX(0.1, MIN(0.4, throttleCmd)).
        } ELSE {
            // Initial approach - higher throttle
            LOCK THROTTLE TO MAX(0.2, MIN(0.8, (ORBITAL_CFG:targetApo - SHIP:APOAPSIS) / (ORBITAL_CFG:targetApo * 0.15))).
        }
        
        // Display detailed throttle info
        PRINT "Target Apo: " + ROUND(ORBITAL_CFG:targetApo/1000,1) + " km       " AT (0,10).
        PRINT "Current:    " + ROUND(SHIP:APOAPSIS/1000,1) + " km       " AT (0,11).
        PRINT "Predicted:  " + ROUND(predictedApo/1000,1) + " km       " AT (0,12).
        PRINT "Apo Rate:   " + ROUND(apoRate,1) + " m/s       " AT (0,13).
        PRINT "Throttle:   " + ROUND(THROTTLE*100,0) + "%       " AT (0,14).

        // During your main loops, add phase-specific information
        addMissionData("Target Apo", ORBITAL_CFG:targetApo/1000, "km", 1).
        addMissionData("Apo Rate", apoRate, "m/s", 1).
    }
    
    WAIT 0.1.
}

// Cut throttle and return control when target apoapsis reached
LOCK THROTTLE TO 0.
PRINT "Target apoapsis reached: " + ROUND(SHIP:APOAPSIS/1000,1) + " km".

// End of ascent phase - control returns to mission_boot.ks