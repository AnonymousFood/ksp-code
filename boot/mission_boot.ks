WAIT UNTIL SHIP:UNPACKED.
CORE:DOEVENT("Open Terminal").
CLEARSCREEN.

PRINT "=== MISSION INITIALIZATION ===".

// Check launch conditions
IF ALTITUDE > 100 {
    PRINT "ERROR: Ship already in flight (Alt: " + ROUND(ALTITUDE,0) + "m)".
    PRINT "Launch script must start on the ground.".
    PRINT 1/0.
}

// Copy configuration files
PRINT "Copying files to local disk...".
COPYPATH("0:/", "1:/").
SWITCH TO 1.
LIST FILES.

// Load configurations
PRINT "Loading configurations...".
RUN ONCE "configs/launch_config.ks".
RUN ONCE "configs/orbital_config.ks". 
RUN ONCE "configs/vessel_config.ks".
RUN ONCE "configs/mission_config.ks".

PRINT "Running orbit setup...".
RUN ONCE "gui/launch_gui.ks".

// Start the mission phases
PRINT "Starting ascent phase...".
IF NOT EXISTS("phases/ascent.ks") {
    PRINT "ERROR: Ascent phase script not found.".
    PRINT 1/0.
}
RUN "phases/ascent.ks".
PRINT "Ascent phase complete.".
WAIT 1.

PRINT "Starting circularization phase...".
RUN "phases/circularization.ks".
PRINT "Circularization phase complete.".

// Only run additional phases if configured
IF MISSION_CFG:PERFORM_ORBIT_INSERTION {
    PRINT "Starting orbit insertion phase...".
    RUN "phases/orbit_insertion.ks".
    PRINT "Orbit insertion phase complete.".
}

IF MISSION_CFG:PERFORM_PLANE_CHANGE {
    PRINT "Starting plane change phase...".
    RUN "phases/plane_change.ks".
    PRINT "Plane change phase complete.".
}

IF MISSION_CFG:PERFORM_TRANSFER {
    PRINT "Starting Hohmann transfer phase...".
    RUN "phases/hohmann_transfer.ks".
    PRINT "Hohmann transfer phase complete.".
}

IF MISSION_CFG:PERFORM_LANDING {
    PRINT "Starting landing phase...".
    RUN "phases/landing.ks".
    PRINT "Landing phase complete.".
}

PRINT "Mission sequence completed successfully.".