WAIT UNTIL SHIP:UNPACKED.
CORE:DOEVENT("Open Terminal").
CLEARSCREEN.

PRINT "=== MISSION INITIALIZATION ===".

IF ALTITUDE > 1000 {
    PRINT "ERROR: Flight".
    SHUTDOWN.
}

// Copy files
PRINT "Copying files to local disk...".

FOR f IN list("boot/mission_boot.ks", "/gui", "/configs", "/lib", "/phases") {
    PRINT "  Loading: " + f.
    COPYPATH("0:/" + f, "1:/").
}
SWITCH TO 1.

// Load configs ONCE
PRINT "Loading configurations...".
for f in OPEN("configs/") {
    PRINT "  Loading: " + f.
    RUNONCEPATH("configs/" + f).
}

PRINT "Running orbit setup...".
RUNONCEPATH("gui/launch_gui.ks").

// Load and initialize display system
PRINT "Initializing telemetry display...".
RUNONCEPATH("lib/display.ks").
startDisplay().
setPhase("INITIALIZATION").
addMissionData("Status", "Loading mission", "", 0).

// Define phases and their config dependencies for cleaner code
LOCAL phases IS LIST(
    LEXICON("name", "ascent", "required", TRUE),
    LEXICON("name", "circularization", "required", TRUE),
    LEXICON("name", "orbit_insertion", "required", MISSION_CFG:PERFORM_ORBIT_INSERTION),
    LEXICON("name", "plane_change", "required", MISSION_CFG:PERFORM_PLANE_CHANGE),
    LEXICON("name", "hohmann_transfer", "required", MISSION_CFG:PERFORM_TRANSFER),
    LEXICON("name", "landing", "required", MISSION_CFG:PERFORM_LANDING)
).

// Track completed phases for this mission run to clean up files
GLOBAL COMPLETED_PHASES IS LIST().

// Execute phases
FOR phase IN phases {
    IF phase:required {
        LOCAL phaseName IS phase:name.
        LOCAL phasePath IS "phases/" + phaseName + ".ks".
        
        // Update display with current phase
        IF DEFINED startDisplay {
            setPhase("LOADING " + phaseName:TOUPPER()).
            addMissionData("Status", "Starting phase...", "", 0).
        }
        
        IF NOT EXISTS(phasePath) {
            PRINT "ERROR: Phase script not found: " + phasePath.
            IF DEFINED startDisplay {
                addMissionData("Error", "Missing " + phaseName + " script", "", 0).
            }
            PRINT 1/0.
        }
        
        // Execute the phase
        RUNPATH(phasePath).
        WAIT 1.
        
        // Add cleanup to free space after phase completion
        COMPLETED_PHASES:ADD(phaseName).
        IF EXISTS(phasePath) { 
            DELETEPATH(phasePath). 
        }
    }
}

// Final mission status
IF DEFINED startDisplay {
    setPhase("COMPLETE").
    addMissionData("Status", "Mission completed", "", 0).
    WAIT 5.
    stopDisplay().
}

PRINT "Mission sequence completed successfully.".