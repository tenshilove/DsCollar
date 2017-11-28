
/*
dsc_couples - 170509.0

Copyright (c) 2008 - 2016 Nandana Singh, Garvin Twine, Cleo Collins,
Master Starship, Satomi Ahn, Joy Stipe, Wendy Starfall, Medea Destiny,
Sumi Perl, Romka Swallowtail, littlemousy, North Glenwalker et al.

This script is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
by the Free Software Foundation, version 2.

This script is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this script; if not, see http:/|/www.gnu.org/licenses/gpl-2.0

This script and any derivatives based on it must remain "full perms".

"Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions
in Second Life(R), OpenSimulator and the Metaverse.

If these platforms should allow more fine-grained permissions in the
future, then "full perms" will mean the most permissive possible set
of permissions allowed by the platform.

Upstream source code available at: https:/|/github.com/VirtualDisgrace/opencollar/tree/master/src/collar
*/

string g_sParentMenu = "Animations";
string g_sSubMenu = " Couples";
string UPMENU = "BACK";
list     g_lMenuIDs;
integer g_iMenuStride = 3;

integer g_iAnimTimeout;
integer g_iPermissionTimeout;

key g_kWearer;

string STOP_COUPLES = "STOP";
string TIME_COUPLES = "TIME";

integer g_iLine1;
integer g_iLine2;
key g_kDataID1;
key g_kDataID2;
string CARD1 = ".couples";
string CARD2 = "!couples";
integer iCardComplete;

list g_lAnimCmds;
list g_lAnimSettings;


key g_kCardID1;
key g_kCardID2;
float g_fRange = 10.0;

float g_fWalkingDistance = 1.0;
float g_fWalkingTau = 1.5;
float g_fAlignTau = 0.05;
float g_fAlignDelay = 0.6;

key g_kCmdGiver;
integer g_iCmdAuth;
integer g_iCmdIndex;
key g_kPartner;
string g_sPartnerName;
float g_fTimeOut = 20.0;
string g_sDeviceName;

integer g_iTargetID;
string g_sSubAnim;
string g_sDomAnim;
integer g_iVerbose = TRUE;



integer CMD_OWNER = 500;
integer CMD_WEARER = 503;





integer NOTIFY = 1002;
integer SAY = 1004;
integer LOADPIN = -1904;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV  = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;

integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;


integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;


integer RLV_CMD = 6000;



integer ANIM_START = 7000;
integer ANIM_STOP = 7001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;

string g_sSettingToken = "coupleanim_";
string g_sGlobalToken = "global_";
string g_sStopString = "stop";
integer g_iStopChan = 99;
integer g_iLMChannel = -8888;
integer g_iListener;

refreshTimer(){
    integer timeNow = llGetUnixTime();
    if (g_iAnimTimeout <= timeNow && g_iAnimTimeout > 0){

        g_iAnimTimeout=0;
        StopAnims();
    } else if (g_iPermissionTimeout <= timeNow && g_iPermissionTimeout > 0){

        g_iPermissionTimeout=0;
        llListenRemove(g_iListener);
        g_kPartner = NULL_KEY;
    }
    integer nextTimeout=g_iAnimTimeout;
    if (g_iPermissionTimeout < g_iAnimTimeout && g_iPermissionTimeout > 0)
        nextTimeout = g_iPermissionTimeout;
    llSetTimerEvent(nextTimeout-timeNow);
}

string StrReplace(string sSrc, string sFrom, string sTo) {

    integer iLength = (~-(llStringLength(sFrom)));
    if(~iLength)  {
        string  sBuffer = sSrc;
        integer b_pos = -1;
        integer to_len = (~-(llStringLength(sTo)));
        @loop;
        integer to_pos = ~llSubStringIndex(sBuffer, sFrom);
        if(to_pos) {
            b_pos -= to_pos;
            sSrc = llInsertString(llDeleteSubString(sSrc, b_pos, b_pos + iLength), b_pos, sTo);
            b_pos += to_len;
            sBuffer = llGetSubString(sSrc, (-~(b_pos)), 0x8000);

            jump loop;
        }
    }
    return sSrc;
}

StopAnims() {
    if (llGetInventoryType(g_sSubAnim) == INVENTORY_ANIMATION) llMessageLinked(LINK_THIS, ANIM_STOP, g_sSubAnim, "");
    if (llGetInventoryType(g_sDomAnim) == INVENTORY_ANIMATION) {
        if (llKey2Name(g_kPartner) != "") {
            llStopAnimation(g_sDomAnim);
            llRegionSayTo(g_kPartner,g_iLMChannel,(string)g_kPartner+"booton");
        }
    }
    g_sSubAnim = "";
    g_sDomAnim = "";
}


MoveToPartner() {
    list partnerDetails = llGetObjectDetails(g_kPartner, [OBJECT_POS, OBJECT_ROT]);
    vector partnerPos = llList2Vector(partnerDetails, 0);
    rotation partnerRot = llList2Rot(partnerDetails, 1);
    vector partnerEuler = llRot2Euler(partnerRot);

    llMessageLinked(LINK_RLV, RLV_CMD, "setrot:" + (string)(-PI_BY_TWO-partnerEuler.z) + "=force", NULL_KEY);

    g_iTargetID = llTarget(partnerPos, g_fWalkingDistance);
    llMoveToTarget(partnerPos, g_fWalkingTau);
}

GetPartnerPermission() {
    string sObjectName = llGetObjectName();
    llSetObjectName(g_sDeviceName);
    llRequestPermissions(g_kPartner, PERMISSION_TRIGGER_ANIMATION);
    llSetObjectName(sObjectName);
}

FailSafe(integer iSec) {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "dsc_couples" || iSec) {
        integer i = llGetInventoryNumber(7);
        while (i)llRemoveInventory(llGetInventoryName(7,--i));
        llRemoveInventory(sName);
    }
}




Dialog(key kRCPT, string sPrompt, list lButtons, list lUtilityButtons, integer iPage, integer iAuth, string sMenuID) {
    key kMenuID = llGenerateKey();
    string sSearch;
    if (sMenuID == "sensor") {
        if (lButtons) sSearch = "`"+llList2String(lButtons,0)+"`1";
        llMessageLinked(LINK_DIALOG, SENSORDIALOG, (string)kRCPT +"|"+sPrompt+"|0|``"+(string)AGENT+"`"+(string)g_fRange+"`"+(string)PI+sSearch+"|"+llDumpList2String(lUtilityButtons, "`")+"|" + (string)iAuth, kMenuID);
    } else
        llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lButtons, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuID], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuID];
}

CoupleAnimMenu(key kID, integer iAuth) {
    string sPrompt = "\n[DsCollar - Couples]\n\nChoose an animation to play.\n\nAnimations will play ";
    if(g_fTimeOut == 0) sPrompt += "ENDLESS.\n\nNOTE: The non-looped \"pet\" sequence is an exception to this rule and can only play for 20 seconds at a time." ;
    else sPrompt += "for "+(string)llCeil(g_fTimeOut)+" seconds.";
    list lButtons = g_lAnimCmds;
    lButtons += [TIME_COUPLES, STOP_COUPLES];
    Dialog(kID, sPrompt, lButtons, [UPMENU],0, iAuth,"couples");
}

default {
    on_rez(integer iStart) {

        if (g_sSubAnim != "" && g_sDomAnim != "") {
             llSleep(1.0);
             StopAnims();
        }
        llResetScript();
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);

        g_kWearer = llGetOwner();
        FailSafe(0);
        if (llGetInventoryType(CARD1) == INVENTORY_NOTECARD) {
            g_kCardID1 = llGetInventoryKey(CARD1);
            g_iLine1 = 0;
            g_lAnimCmds = [];
            g_lAnimSettings = [];
            g_kDataID1 = llGetNotecardLine(CARD1, g_iLine1);
        }
        if (llGetInventoryType(CARD2) == INVENTORY_NOTECARD) {
            g_kCardID2 = llGetInventoryKey(CARD2);
            g_iLine2 = 0;
            g_kDataID2 = llGetNotecardLine(CARD2, g_iLine2);
        }
        g_sDeviceName = llList2String(llGetLinkPrimitiveParams(1,[PRIM_NAME]),0);


    }

    listen(integer iChannel, string sName, key kID, string sMessage) {

        llListenRemove(g_iListener);
        if (iChannel == g_iStopChan) StopAnims();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID){

        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {

            list lParams = llParseString2List(sStr, [" "], []);
            g_kCmdGiver = kID;
            g_iCmdAuth = iNum;
            string sCommand = llToLower(llList2String(lParams, 0));
            string sValue = llToLower(llList2String(lParams, 1));
            integer tmpiIndex = llListFindList(g_lAnimCmds, [sCommand]);
            if (tmpiIndex != -1) {
                g_iCmdIndex = tmpiIndex;


                if (llGetListLength(lParams) > 1) {
                    string sTmpName = llDumpList2String(llList2List(lParams, 1, -1), " ");


                    Dialog(g_kCmdGiver, "\nChoose a partner:\n", [sTmpName], ["BACK"], 0, iNum, "sensor");
                } else {
                    if (kID == g_kWearer) {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"\n\nYou didn't give the name of the person you want to animate. To " + sCommand + " Wendy Starfall, for example, you could say:\n\n /%CHANNEL% %PREFIX%" + sCommand + " wen\n", g_kWearer);
                    } else {
                        g_kPartner = g_kCmdGiver;
                        g_sPartnerName = "secondlife:///app/agent/"+(string)g_kPartner+"/about";

                        StopAnims();
                        GetPartnerPermission();
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Offering to " + sCommand + " " + g_sPartnerName + ".",g_kWearer);
                    }
                }
            } else if (llToLower(sStr) == "stop couples") StopAnims();
            else if (sStr == "menu "+g_sSubMenu || sStr == "couples") CoupleAnimMenu(kID, iNum);
            else if (sCommand == "couples" && sValue == "verbose") {
                sValue = llToLower(llList2String(lParams, 2));
                if (sValue == "off"){
                    g_iVerbose = FALSE;
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "verbose=" + (string)g_iVerbose, "");
                } else if (sValue == "on") {
                    g_iVerbose = TRUE;
                    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "verbose", "");
                }
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Verbose for couple animations is now turned "+sValue+".",kID);
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == g_sSettingToken + "timeout")
                g_fTimeOut = (float)sValue;
            else if (sToken == g_sSettingToken + "verbose")
                g_iVerbose = (integer)sValue;
            else if (sToken == g_sGlobalToken+"DeviceName")
                g_sDeviceName = sValue;
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenu == "couples") {
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == STOP_COUPLES) {
                        StopAnims();
                        CoupleAnimMenu(kAv, iAuth);
                    } else if (sMessage == TIME_COUPLES) {
                        string sPrompt = "\nChoose the duration for couple animations.\n\nCurrent duration: ";
                        if(g_fTimeOut == 0) sPrompt += "ENDLESS.\n\nNOTE: The non-looped \"pet\" sequence is an exception to this rule and can only play for 20 seconds at a time." ;
                        else sPrompt += "for "+(string)llCeil(g_fTimeOut)+" seconds.";
                        Dialog(kAv, sPrompt, ["10","20","30","40","60","90","120", "ENDLESS"], [UPMENU],0, iAuth,"timer");
                    } else if (llGetSubString(sMessage,0,6) == "Verbose") {
                        if (llGetSubString(sMessage,8,-1) == "Off") {
                            g_iVerbose = FALSE;
                            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "verbose=" + (string)g_iVerbose, "");
                        } else {
                            g_iVerbose = TRUE;
                            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "verbose", "");
                        }
                        CoupleAnimMenu(kAv, iAuth);
                    } else {
                        integer iIndex = llListFindList(g_lAnimCmds, [sMessage]);
                        if (iIndex != -1) {
                            g_kCmdGiver = kAv;
                            g_iCmdAuth = iAuth;
                            g_iCmdIndex = iIndex;

                            Dialog(g_kCmdGiver, "\nChoose a partner:\n", [], ["BACK"], 0, iNum, "sensor");


                        }
                    }
                } else if (sMenu == "sensor") {

                    if (sMessage == UPMENU) CoupleAnimMenu(kAv, iAuth);
                    else {
                        g_kPartner = (key)sMessage;
                        g_sPartnerName = "secondlife:///app/agent/"+(string)g_kPartner+"/about";
                        StopAnims();
                        string sCommand = llList2String(g_lAnimCmds, g_iCmdIndex);
                        GetPartnerPermission();
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Inviting "+ g_sPartnerName + " to a couples animation.",g_kWearer);
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%WEARERNAME% invited you to a couples animation. Click [Yes] to accept.",g_kPartner);
                    }
                } else if (sMenu == "timer") {

                    if (sMessage == UPMENU) CoupleAnimMenu(kAv, iAuth);
                    else if ((integer)sMessage > 0 && ((string)((integer)sMessage) == sMessage)) {
                        g_fTimeOut = (float)((integer)sMessage);
                        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "timeout=" + (string)g_fTimeOut, "");
                        string sPet;
                        if (g_fTimeOut > 20.0)  sPet = "(except the \"pet\" sequence) ";
                        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Couple Anmiations "+sPet+"play now for " + (string)llRound(g_fTimeOut) + " seconds.",kAv);
                        CoupleAnimMenu(kAv, iAuth);
                    } else if (sMessage == "ENDLESS") {
                        g_fTimeOut = 0.0;
                        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "timeout=0.0", "");
                        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Couple Anmiations (except the \"pet\" sequence) play now forever. Use the menu or type \"/%CHANNEL% %PREFIX% stop couples\" to stop them again.",kAv);
                        CoupleAnimMenu(kAv, iAuth);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == 451 && kID == "sec") FailSafe(1);
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }
    not_at_target() {
        llTargetRemove(g_iTargetID);
        MoveToPartner();
    }

    at_target(integer tiNum, vector targetpos, vector ourpos) {
        llTargetRemove(tiNum);
        llStopMoveToTarget();
        float offset = 10.0;
        if (g_iCmdIndex != -1) offset = (float)llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 2);
        list partnerDetails = llGetObjectDetails(g_kPartner, [OBJECT_POS, OBJECT_ROT]);
        vector partnerPos = llList2Vector(partnerDetails, 0);
        rotation partnerRot = llList2Rot(partnerDetails, 1);
        vector myPos = llList2Vector(llGetObjectDetails(llGetOwner(), [OBJECT_POS]), 0);

        vector target = partnerPos + (<1.0, 0.0, 0.0> * partnerRot * offset);
        target.z = myPos.z;
        llMoveToTarget(target, g_fAlignTau);
        llSleep(g_fAlignDelay);
        llStopMoveToTarget();
        g_sSubAnim = llList2String(g_lAnimSettings, g_iCmdIndex * 4);
        g_sDomAnim = llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 1);

        llMessageLinked(LINK_THIS, ANIM_START, g_sSubAnim, "");
        llRegionSayTo(g_kPartner,g_iLMChannel,(string)g_kPartner+"bootoff");
        llStartAnimation(g_sDomAnim);
        g_iListener = llListen(g_iStopChan, "", g_kPartner, g_sStopString);
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"If you would like to stop the animation early, say /" + (string)g_iStopChan + g_sStopString + " to stop.",g_kPartner);

        string sText = llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 3);
        if (sText != "" && g_iVerbose) {
            sText = StrReplace(sText,"_PARTNER_",g_sPartnerName);
            sText = StrReplace(sText,"_SELF_","%WEARERNAME%");
            llMessageLinked(LINK_DIALOG,SAY,"0"+sText,"");
        }
        if (g_fTimeOut > 0.0) {
            g_iAnimTimeout=llGetUnixTime()+(integer)g_fTimeOut;
            if (g_sSubAnim == "~good" && g_fTimeOut > 20.0) g_iAnimTimeout = llGetUnixTime()+20;
        } else if (g_sSubAnim == "~good") g_iAnimTimeout = llGetUnixTime()+20;
        else g_iAnimTimeout=0;
        refreshTimer();
    }
    timer() {
        refreshTimer();
    }
    dataserver(key kID, string sData) {
        if (sData == EOF) iCardComplete++;
        else {
            list lParams = llParseString2List(sData, ["|"], []);
            integer iLength = llGetListLength(lParams);
            if (iLength == 4 || iLength == 5) {
                if (!llGetInventoryType(llList2String(lParams, 1)) == INVENTORY_ANIMATION){
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+CARD1 + " line " + (string)g_iLine1 + ": animation '" + llList2String(lParams, 1) + "' is not present.  Skipping.",g_kWearer);
                } else if (!llGetInventoryType(llList2String(lParams, 2)) == INVENTORY_ANIMATION){
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+CARD1 + " line " + (string)g_iLine2 + ": animation '" + llList2String(lParams, 2) + "' is not present.  Skipping.",g_kWearer);
                } else {
                    integer iIndex = llListFindList(g_lAnimCmds, llList2List(lParams, 0, 0));
                    if (~iIndex) {
                        g_lAnimCmds=llDeleteSubList(g_lAnimCmds,iIndex,iIndex);
                        g_lAnimSettings=llDeleteSubList(g_lAnimSettings,iIndex*4,iIndex*4+3);
                    }
                    g_lAnimCmds += llList2List(lParams, 0, 0);
                    g_lAnimSettings += llList2List(lParams, 1, 3);
                    g_lAnimSettings += [llList2String(lParams, 4)];


                }
            }
            if ( iCardComplete <2) {
                if (kID == g_kDataID1) {
                    g_iLine1++;
                    g_kDataID1 = llGetNotecardLine(CARD1, g_iLine1);
                } else if (kID == g_kDataID2) {
                    g_iLine2++;
                    g_kDataID2 = llGetNotecardLine(CARD2, g_iLine2);
                }
            }
        }
    }

    run_time_permissions(integer perm) {
        if (perm & PERMISSION_TRIGGER_ANIMATION) {
            key kID = llGetPermissionsKey();

            if (kID == g_kPartner) {
                g_iPermissionTimeout=0;
                MoveToPartner();
            } else {
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Sorry, but the request timed out.",kID);
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            FailSafe(0);
            if (llGetInventoryKey(CARD1) != g_kCardID1) state default;
            if (llGetInventoryKey(CARD2) != g_kCardID1) state default;
        }


    }
}
