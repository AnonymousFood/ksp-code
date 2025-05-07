SET my_gui TO GUI(200).
LOCAL label IS my_gui:ADDLABEL("Hello world!").
LOCAL apo_text_field IS my_gui:ADDTEXTFIELD(ORBITAL_CFG:targetApo:TOSTRING).
SET apo_text_field:ONCONFIRM TO {
    parameter newVal. 
    SET ORBITAL_CFG:targetApo to newVal:TOSCALAR.
    print("NEW Apoapsis: " + ORBITAL_CFG:targetApo).
}.

LOCAL inc_text_field IS my_gui:ADDTEXTFIELD(ORBITAL_CFG:targetInc:TOSTRING).
SET inc_text_field:ONCONFIRM TO {
    parameter newVal. 
    SET ORBITAL_CFG:targetInc to newVal:TOSCALAR.
    print("NEW Inclination: " + ORBITAL_CFG:targetInc).
}.


SET button TO my_gui:ADDBUTTON("OK").
my_gui:SHOW().
UNTIL button:TAKEPRESS WAIT(0.1).
my_gui:HIDE().