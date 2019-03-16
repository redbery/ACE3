#include "script_component.hpp"
/*
 * Author: Glowbal
 * Displays the patient information for given unit.
 *
 * Arguments:
 * 0: The Unit <OBJECT>
 * 1: Show <NUMBER> (default: 0)
 * 2: Selection <NUMBER> (default: 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [bob, true, 2] call ACE_medical_fnc_displayPatientInformation
 *
 * Public: No
 */
#define MAX_DISTANCE 10

params ["_target", ["_show", 0], ["_selectionN", 0]];

GVAR(currentSelectedSelectionN) = [0, _selectionN] select (IS_SCALAR(_selectionN));
GVAR(displayPatientInformationTarget) = [ObjNull, _target] select _show;

if (_show == 1) then {
    ("ACE_MedicalRscDisplayInformation" call BIS_fnc_rscLayer) cutRsc [QGVAR(DisplayInformation),"PLAIN"];

    [{
        params ["_args", "_idPFH"];
        _args params ["_target", "_selectionN"];

        if (GVAR(displayPatientInformationTarget) != _target || GVAR(currentSelectedSelectionN) != _selectionN) exitwith {
            [_idPFH] call CBA_fnc_removePerFrameHandler;
        };
        if (ACE_player distance _target > MAX_DISTANCE) exitwith {
            ("ACE_MedicalRscDisplayInformation" call BIS_fnc_rscLayer) cutText ["","PLAIN"];
            [_idPFH] call CBA_fnc_removePerFrameHandler;
            [QEGVAR(common,displayTextStructured), [[ELSTRING(medical,DistanceToFar), [_target] call EFUNC(common,getName)], 1.75, ACE_player], [ACE_player]] call CBA_fnc_targetEvent;
        };

        disableSerialization;
        private _display = uiNamespace getVariable QGVAR(DisplayInformation);
        if (isnil "_display") exitwith {
            [_idPFH] call CBA_fnc_removePerFrameHandler;
        };

        private _allInjuryTexts = [];
        private _genericMessages = [];

        private _partText = [ELSTRING(medical_gui,Head), ELSTRING(medical_gui,Torso), ELSTRING(medical_gui,Arm_L), ELSTRING(medical_gui,Arm_R), ELSTRING(medical_gui,Leg_L), ELSTRING(medical_gui,Leg_R)] select _selectionN;
        _genericMessages pushback [localize _partText, [1, 1, 1, 1]];

        if IS_BLEEDING(_target) then {
            _genericMessages pushback [LLSTRING(Status_Bleeding), [1, 0.1, 0.1, 1]];
        };

        // Give a qualitative description of the blood volume lost
        switch (GET_HEMORRHAGE(_target)) do {
            case 1: {
                _genericMessages pushBack [LLSTRING(Lost_Blood1), [1, 0.1, 0.1, 1]];
            };
            case 2: {
                _genericMessages pushBack [LLSTRING(Lost_Blood2), [1, 0.1, 0.1, 1]];
            };
            case 3: {
                _genericMessages pushBack [LLSTRING(Lost_Blood3), [1, 0.1, 0.1, 1]];
            };
            case 4: {
                _genericMessages pushBack [LLSTRING(Lost_Blood4), [1, 0.1, 0.1, 1]];
            };
        };

        if (HAS_TOURNIQUET_APPLIED_ON(_target,_selectionN)) then {
            _genericMessages pushback [localize ELSTRING(medical_treatment,Status_Tourniquet_Applied), [0.77, 0.51, 0.08, 1]];
        };
        if (GVAR(showPainInMenu) && {[ACE_player, GVAR(painVisualization)] call EFUNC(medical_treatment,isMedic)}) then {
            private _painLevel = GET_PAIN_PERCEIVED(_target);
            if (_painLevel > 0) then {
                private _painText = localize ELSTRING(medical_treatment,Status_Pain);
                if (_painLevel < 0.1) then {
                    _painText = localize ELSTRING(medical_treatment,Status_MildPain);
                } else {
                    if (_painLevel > 0.5) then {
                        _painText = localize ELSTRING(medical_treatment,Status_SeverePain);
                    };
                };
                _genericMessages pushback [_painText, [1, 1, 1, 1]];
            };
        };

        private _totalIvVolume = 0;
        {
            _x params ["_xVolumeAdded"];
            _totalIvVolume = _totalIvVolume + _xVolumeAdded;
        } foreach (_target getVariable [QEGVAR(medical,ivBags), []]);

        if (_totalIvVolume >= 1) then {
            _genericMessages pushback [format[localize ELSTRING(medical_treatment,receivingIvVolume), floor _totalIvVolume], [1, 1, 1, 1]];
        };

        private _selectionTourniquet = GET_TOURNIQUETS(_target);
        private _selectionBloodLoss = [0, 0, 0, 0, 0, 0];
        private _selectionDamage = _target getVariable [QEGVAR(medical,bodyPartDamage), [0,0,0,0,0,0]];
        private _allInjuryTexts = [];

        {
            _x params ["", "_woundClassID", "_bodyPartN", "_amountOf", "_bleeding", "_damage", "_category"];
            _selectionBloodLoss set [_bodyPartN, (_selectionBloodLoss select _bodyPartN) + (20 * (_bleeding * _amountOf))];
            if (_selectionN == _bodyPartN) then {
                // Collect the text to be displayed for this injury [ Select injury class type definition - select the classname DisplayName (6th), amount of injuries for this]
                if (_amountOf > 0) then {
                    private _className = (EGVAR(medical_damage,woundsData) select _woundClassID) select 6;
                    private _postfix = ["Minor", "Medium", "Large"] select _category;
                    private _woundDescription = localize format [ELSTRING(medical_damage,%1_%2), _className, _postfix];
                    if (_amountOf >= 1) then {
                        _allInjuryTexts pushBack [format["%2x %1", _woundDescription, ceil _amountOf], [1,1,1,1]];
                    } else {
                        _allInjuryTexts pushBack [format["Partial %1", _woundDescription], [1,1,1,1]];
                    };
                } else {
                    if (!EGVAR(medical_treatment,advancedBandages) || {!EGVAR(medical_treatment,woundReopening)}) then {
                        private _className = (EGVAR(medical_damage,woundsData) select _woundClassID) select 6;
                        private _postfix = ["Minor", "Medium", "Large"] select _category;
                        private _woundDescription = localize format [ELSTRING(medical_damage,%1_%2), _className, _postfix];
                        if (_amountOf >= 1) then {
                            _allInjuryTexts pushBack [format ["[B] %2x %1", _woundDescription, ceil _amountOf], [0.7,0.7,0.7,1]];
                        } else {
                            _allInjuryTexts pushBack [format ["[B] Partial %1", _woundDescription], [0.7,0.7,0.7,1]];
                        };
                    };
                };
            };
        } forEach (_target getVariable [QEGVAR(medical,openWounds), []]);

        {
            _x params ["", "_woundClassID", "_bodyPartN", "_amountOf", "_bleeding", "_damage", "_category"];
            if (_selectionN == _bodyPartN) then {
                // Collect the text to be displayed for this injury [ Select injury class type definition - select the classname DisplayName (6th), amount of injuries for this]
                if (_amountOf > 0) then {
                    private _className = (EGVAR(medical_damage,woundsData) select _woundClassID) select 6;
                    private _postfix = ["Minor", "Medium", "Large"] select _category;
                    private _woundDescription = localize format [ELSTRING(medical_damage,%1_%2), _className, _postfix];
                    if (_amountOf >= 1) then {
                        _allInjuryTexts pushBack [format ["[B] %2x %1", _woundDescription, ceil _amountOf], [0.88,0.7,0.65,1]];
                    } else {
                        _allInjuryTexts pushBack [format ["[B] Partial %1", _woundDescription], [0.88,0.7,0.65,1]];
                    };
                };
            };
        } forEach (_target getVariable [QEGVAR(medical,bandagedWounds), []]);

        {
            _x params ["", "_woundClassID", "_bodyPartN", "_amountOf", "_bleeding", "_damage", "_category"];
            if (_selectionN == _bodyPartN) then {
                // Collect the text to be displayed for this injury [ Select injury class type definition - select the classname DisplayName (6th), amount of injuries for this]
                if (_amountOf > 0) then {
                    private _className = (EGVAR(medical_damage,woundsData) select _woundClassID) select 6;
                    private _postfix = ["Minor", "Medium", "Large"] select _category;
                    private _woundDescription = localize format [ELSTRING(medical_damage,%1_%2), _className, _postfix];
                    if (_amountOf >= 1) then {
                        _allInjuryTexts pushBack [format ["[S] %2x %1", _woundDescription, ceil _amountOf], [0.7,0.7,0.7,1]];
                    } else {
                        _allInjuryTexts pushBack [format ["[S] Partial %1", _woundDescription], [0.7,0.7,0.7,1]];
                    };
                };
            };
        } forEach (_target getVariable [QEGVAR(medical,stitchedWounds), []]);

        // Handle the body image coloring
        private _availableSelections = [50, 51, 52, 53, 54, 55];
        {
            private _red = 1;
            private _green = 1;
            private _blue = 1;

            private _torniquet = _selectionTourniquet select _forEachIndex;
            if (_torniquet > 0) then {
                _red = 0;
                _green = 0;
                _blue = 0.8;
            } else {
                private _bloodLoss = _selectionBloodLoss select _forEachIndex;
                if (_bloodLoss > 0) then {
                    _green = 0 max (0.8 - _bloodLoss);
                    _blue = _green;
                } else {
                    private _damage = _selectionDamage select _forEachIndex;
                    if (_damage > 0.1) then {
                        _blue = 0 max (1 - _damage);
                        _green = 0.5 max (1 - _damage / 2);
                    };
                };
            };

            (_display displayCtrl _x) ctrlSetTextColor [_red, _green, _blue, 1.0];
        } forEach _availableSelections;

        // update tourniquet information
        [_display, _target getVariable [QGVAR(tourniquets), [0,0,0,0,0,0]]] call FUNC(updateTourniquets);

        private _lbCtrl = (_display displayCtrl 200);
        lbClear _lbCtrl;
        {
            _x params ["_add", "_color"];
            _lbCtrl lbAdd _add;
            _lbCtrl lbSetColor [_foreachIndex, _color];
        } foreach _genericMessages;

        private _amountOfGeneric = count _genericMessages;
        {
            _x params ["_add", "_color"];
            _lbCtrl lbAdd _add;
            _lbCtrl lbSetColor [_foreachIndex + _amountOfGeneric, _color];
        } foreach _allInjuryTexts;
        if (count _allInjuryTexts == 0) then {
            _lbCtrl lbAdd (localize ELSTRING(medical_treatment,NoInjuriesBodypart));
        };

        private _logCtrl = (_display displayCtrl 302);
        lbClear _logCtrl;

        private _logs = _target getVariable [QGVAR(logFile_Activity), []];
        {
            _x params ["_message", "_moment", "_type", "_arguments"];
            if (isLocalized _message) then {
                _message = localize _message;
            };

            {
                if (_x isEqualType "" && {isLocalized _x}) then {
                    _arguments set [_foreachIndex, localize _x];
                };
            } foreach _arguments;
            _message = format([_message] + _arguments);
            _logCtrl lbAdd format["%1 %2", _moment, _message];
        } foreach _logs;

        private _triageStatus = [_target] call EFUNC(medical_treatment,getTriageStatus);
        (_display displayCtrl 303) ctrlSetText (_triageStatus select 0);
        (_display displayCtrl 303) ctrlSetBackgroundColor (_triageStatus select 2);

    }, 0, [_target, GVAR(currentSelectedSelectionN)]] call CBA_fnc_addPerFrameHandler;

} else {
    ("ACE_MedicalRscDisplayInformation" call BIS_fnc_rscLayer) cutText ["","PLAIN"];
};
