// Universal telemetry display system

// Initialize display variables
GLOBAL DISPLAY_ROW IS 15.      // Starting row for dynamic display
GLOBAL DISPLAY_VALUES IS LEXICON(). // Store all display values
GLOBAL DISPLAY_ACTIVE IS TRUE.  // Control flag

// Create basic structure
FUNCTION initDisplay {
    CLEARSCREEN.
    PRINT "=== MISSION TELEMETRY ===".
    PRINT "-------------------------------".
}

// Update a specific telemetry value with formatting
FUNCTION updateValue {
    PARAMETER name, value, units, precision IS 1, row IS -1.
    
    LOCAL displayText IS name + ": " + ROUND(value, precision) + " " + units + "      ".
    
    // Store in the global dictionary
    SET DISPLAY_VALUES[name] TO displayText.
    
    // If row specified, print directly there
    IF row >= 0 {
        PRINT displayText AT (0, row).
    }
}

// Render all values in the dictionary
FUNCTION renderDisplay {
    LOCAL currentRow IS DISPLAY_ROW.
    
    PRINT "-------------------------------" AT (0, currentRow-1).
    
    FOR val IN DISPLAY_VALUES:VALUES {
        PRINT val AT (0, currentRow).
        SET currentRow TO currentRow + 1.
    }
    
    // Include mission time
    PRINT "Mission Time: " + TIME:CLOCK AT (0, 3).
    
    // Include mission phase if available
    IF DEFINED MISSION_PHASE {
        PRINT "Phase: " + MISSION_PHASE AT (0, 4).
    }
}

// Start the display update loop
FUNCTION startDisplay {
    // Basic telemetry that's always useful
    updateValue("Altitude", ALTITUDE, "m", 0).
    updateValue("Velocity", SHIP:VELOCITY:SURFACE:MAG, "m/s", 1).
    updateValue("Apoapsis", SHIP:APOAPSIS/1000, "km", 1).
    updateValue("Periapsis", SHIP:ORBIT:PERIAPSIS/1000, "km", 1).
    updateValue("Throttle", THROTTLE * 100, "%", 0).
    updateValue("Pitch", 90 - VANG(SHIP:UP:VECTOR, SHIP:FACING:VECTOR), "°", 1).
    updateValue("Stage", STAGE:NUMBER, "").
    
    // Start update loop
    WHEN DISPLAY_ACTIVE THEN {
        renderDisplay().
        PRESERVE.
        RETURN 0.5. // Update every 0.5 seconds
    }
}

// Stop the display updates
FUNCTION stopDisplay {
    SET DISPLAY_ACTIVE TO FALSE.
}

// Add mission-specific data to the display
FUNCTION addMissionData {
    PARAMETER name, value, units, precision IS 1.
    updateValue(name, value, units, precision).
}

// Set current mission phase
FUNCTION setPhase {
    PARAMETER phase.
    GLOBAL MISSION_PHASE IS phase.
}

// Initialize display on load
initDisplay().