#include "script_component.hpp"
/*
 * Author: Glowbal
 * Action for checking the response status of the patient
 *
 * Arguments:
 * 0: The medic <OBJECT>
 * 1: The patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [bob, kevin] call ace_medical_treatment_fnc_actionCheckResponse
 *
 * Public: No
 */

params ["_caller", "_target"];

private _output = [ELSTRING(medical_treatment,Check_Response_Unresponsive), ELSTRING(medical_treatment,Check_Response_Responsive)] select (_target call EFUNC(common,isAwake));

[QEGVAR(common,displayTextStructured), [[_output, _target call EFUNC(common,getName)], 2, _caller], _caller] call CBA_fnc_targetEvent;

[_target ,"activity", _output, [[_target, false, true] call EFUNC(common,getName)]] call FUNC(addToLog);
[_target, "quick_view", _output, [[_target, false, true] call EFUNC(common,getName)]] call FUNC(addToLog);
