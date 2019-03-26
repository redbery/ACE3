#include "script_component.hpp"
/*
 * Author: Glowbal, mharis001
 * Handles opening the Medical Menu. Called from onLoad event.
 *
 * Arguments:
 * 0: Medical Menu display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [DISPLAY] call ace_medical_gui_fnc_onMenuOpen
 *
 * Public: No
 */

params ["_display"];

// Create background effects based on interact menu setting
if (EGVAR(interact_menu,menuBackground) == 1) then {[QGVAR(id), true] call EFUNC(common,blurScreen)};
if (EGVAR(interact_menu,menuBackground) == 2) then {0 cutRsc [QEGVAR(interact_menu,menuBackground), "PLAIN", 1, false]};

// Fix mouse moving randomly
[{
    [{setMousePosition _this}, _this] call CBA_fnc_execNextFrame;
}, getMousePosition] call CBA_fnc_execNextFrame;

// Set target name as title
private _ctrlTitle = _display displayCtrl IDC_TITLE;
_ctrlTitle ctrlSetText ([GVAR(target)] call EFUNC(common,getName));

// Initially hide the triage select buttons
[_display] call FUNC(toggleTriageSelect);

// Store display and add PFH to update it
uiNamespace setVariable [QGVAR(menuDisplay), _display];
["ace_medicalMenuOpened", [ACE_player, GVAR(target), _display]] call CBA_fnc_localEvent;

if (GVAR(menuPFH) != -1) exitWith {
    TRACE_1("Menu PFH already running",GVAR(menuPFH));
};

GVAR(menuPFH) = [FUNC(menuPFH), 0, []] call CBA_fnc_addPerFrameHandler;
