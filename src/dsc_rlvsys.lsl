/*
dsc_rlvsys - 170509.0

Based on OpenCollar 6.5.0
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

integer g_iRLVOn = TRUE;
integer g_iRLVOff = FALSE;
integer g_iViewerCheck = FALSE;
integer g_iRlvActive = FALSE;
integer g_iWaitRelay;

integer g_iListener;
float g_fVersionTimeOut = 30.0;
integer g_iRlvVersion;
integer g_iRlvaVersion;
integer g_iCheckCount;
integer g_iMaxViewerChecks = 3;
integer g_iCollarLocked = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "RLV";
list g_lMenu;

list    g_lMenuIDs;
integer g_iMenuStride = 3;
integer RELAY_CHANNEL = -1812221819;



integer CMD_OWNER = 500;
integer CMD_WEARER = 503;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;



integer NOTIFY = 1002;
integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer REBOOT = -1000;
integer LOADPIN = -1904;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;


integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;
integer RLV_CLEAR = 6002;
integer RLV_VERSION = 6003;
integer RLVA_VERSION = 6004;

integer RLV_OFF = 6100;
integer RLV_ON = 6101;
integer RLV_QUERY = 6102;
integer RLV_RESPONSE = 6103;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string TURNON = "  ON";
string TURNOFF = " OFF";
string CLEAR = "CLEAR ALL";

key g_kWearer;

string g_sSettingToken = "rlvsys_";
string g_sGlobalToken = "global_";
string g_sRlvVersionString="(unknown)";
string g_sRlvaVersionString="(unknown)";

list g_lOwners;
list g_lRestrictions;

list g_lBaked=[];
key g_kSitter=NULL_KEY;
key g_kSitTarget=NULL_KEY;

integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;

ApplyRem(string sBehav) {

    integer iRestr=llListFindList(g_lBaked, [sBehav]);
    if (~iRestr) {
        integer i;
        for (i=0;i<=llGetListLength(g_lRestrictions);i++) {
            list lSrcRestr=llParseString2List(llList2String(g_lRestrictions,i),["§"],[]);
            if (llListFindList(lSrcRestr, [sBehav])!=-1) return;
        }

        list lParts=llParseString2List(sBehav,[":"],[]);
        g_lBaked=llDeleteSubList(g_lBaked,iRestr,iRestr);
        llOwnerSay("@"+sBehav+"=y");


    }

}

setRlvState(){
    if (g_iRLVOn && g_iViewerCheck){
        if (!g_iRlvActive) {


            g_iRlvActive=TRUE;

            g_lMenu = [] ;
            llMessageLinked(LINK_ALL_OTHERS, MENUNAME_REQUEST, g_sSubMenu, "");

            llMessageLinked(LINK_ALL_OTHERS, RLV_REFRESH, "", NULL_KEY);
            g_iWaitRelay = 1;
            llSetTimerEvent(1.5);
        }
    } else if (g_iRlvActive) {

        g_iRlvActive=FALSE;
        while (llGetListLength(g_lBaked)){
            llOwnerSay("@"+llList2String(g_lBaked,-1)+"=y");
            g_lBaked=llDeleteSubList(g_lBaked,-1,-1);
        }
        llMessageLinked(LINK_ALL_OTHERS, RLV_OFF, "", NULL_KEY);
    } else if (g_iRLVOn){
        if (g_iListener) llListenRemove(g_iListener);
        g_iListener = llListen(293847, "", g_kWearer, "");
        llSetTimerEvent(g_fVersionTimeOut);
        g_iCheckCount=0;
        llOwnerSay("@versionnew=293847");
    } else
        llSetTimerEvent(0.0);
}

rebakeSourceRestrictions(key kSource){

    integer iSourceIndex=llListFindList(g_lRestrictions,[kSource]);
    if (~iSourceIndex) {
        list lRestr=llParseString2List(llList2String(g_lRestrictions,iSourceIndex+1),["§"],[]);
        while(llGetListLength(lRestr)){
            ApplyAdd(llList2String(lRestr,-1));
            lRestr=llDeleteSubList(lRestr,-1,-1);
        }
    }
}

UserCommand(integer iNum, string sStr, key kID) {
    sStr = llToLower(sStr);
    if (sStr=="runaway" && kID==g_kWearer) {
        llSleep(2);
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on="+(string)g_iRLVOn, "");
    } else if (sStr == "rlv" || sStr == "menu rlv" ){

        DoMenu(kID, iNum);
    } else if (sStr == "rlv on") {
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Starting RLV...",g_kWearer);
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=1", "");
        g_iRLVOn = TRUE;
        g_iRLVOff = FALSE;
        setRlvState();
    } else if (sStr == "rlv off") {
        if (iNum == CMD_OWNER) {
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=0", "");
            llSetTimerEvent(0.0);
            g_iRLVOn = FALSE;
            g_iRLVOff = TRUE;
            setRlvState();
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"RLV disabled.",g_kWearer);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
    } else if (sStr == "clear") {
        if (iNum == CMD_OWNER) SafeWord(kID);
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",g_kWearer);
    } else if (llGetSubString(sStr,0,13) == "rlv handshakes") {
        if (iNum != CMD_WEARER && iNum != CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",g_kWearer);
        else {
            if ((integer)llGetSubString(sStr,-2,-1)) {
                g_iMaxViewerChecks = (integer)llGetSubString(sStr,-2,-1);
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Next time RLV is turned on or if the %DEVICETYPE% is attached with RLV turned on, there will be "+(string)g_iMaxViewerChecks+" extra handshake attempts before disabling RLV.", kID);
                llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken + "handshakes="+(string)g_iMaxViewerChecks, "");
            } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nRLV handshakes means the set number of attempts to check for active RLV support in the viewer. Being on slow connections and/or having an unusually large inventory might mean having to check more often than the default of 3 times.\n\nCommand syntax: %PREFIX% rlv handshakes [number]\n", kID);
        }
    }  else if (sStr=="show restrictions") {
        string sOut="\n\n%WEARERNAME% is restricted by the following sources:\n";
        integer numRestrictions=llGetListLength(g_lRestrictions);
        if (!numRestrictions) sOut="There are no restrictions right now.";
        while (numRestrictions){
            key kSource=(key)llList2String(g_lRestrictions,numRestrictions-2);
            if ((key)kSource)
                sOut+="\n"+llKey2Name((key)kSource)+" ("+(string)kSource+"): "+llList2String(g_lRestrictions,numRestrictions-1)+"\n";
            else
                sOut+="\nThis %DEVICETYPE% ("+(string)kSource+"): "+llList2String(g_lRestrictions,numRestrictions-1)+"\n";
            numRestrictions -= 2;
        }
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sOut,kID);
    }
}

SafeWord(key kID) {

    integer numRestrictions=llGetListLength(g_lRestrictions);
    while (numRestrictions){
        numRestrictions -= 2;
        string kSource=llList2String(g_lRestrictions,numRestrictions);
        if (kSource != "main" && kSource != "rlvex" && llSubStringIndex(kSource,"utility_") != 0)
            llMessageLinked(LINK_THIS,RLV_CMD,"clear",kSource);
    }
    llMessageLinked(LINK_THIS,RLV_CMD,"unsit=force","");
    llMessageLinked(LINK_ALL_OTHERS,RLV_CLEAR,"","");
    if (kID) llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"RLV restrictions cleared.",kID);
}

RemRestriction(key kID, string sBehav) {

    integer iSource=llListFindList(g_lRestrictions,[kID]);
    if (~iSource) {
        list lSrcRestr = llParseString2List(llList2String(g_lRestrictions,iSource+1),["§"],[]);
        integer iRestr=llListFindList(lSrcRestr,[sBehav]);
        if (~iRestr || sBehav=="ALL") {
            if (llGetListLength(lSrcRestr)==1) {
                g_lRestrictions=llDeleteSubList(g_lRestrictions,iSource, iSource+1);
                if ((key)kID) llMessageLinked(LINK_ALL_OTHERS, CMD_REMSRC,"",kID);
            } else {
                lSrcRestr=llDeleteSubList(lSrcRestr,iRestr,iRestr);
                g_lRestrictions=llListReplaceList(g_lRestrictions,[llDumpList2String(lSrcRestr,"§")] ,iSource+1,iSource+1);
            }
            if (sBehav=="unsit"&&g_kSitter==kID) {
                g_kSitter=NULL_KEY;
                g_kSitTarget=NULL_KEY;
            }
            lSrcRestr=[];
            ApplyRem(sBehav);
        }
    }
    DoLock();
}

FailSafe(integer iSec) {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "dsc_rlvsys" || iSec)
        llRemoveInventory(sName);
}




DoMenu(key kID, integer iAuth){
    key kMenuID = llGenerateKey();
    string sPrompt = "\n[DsCollar - RLV Controls]\n\n";
    if (g_iRlvActive) {
        if (g_iRlvVersion) sPrompt += "\nRestrainedLove API: RLV v"+g_sRlvVersionString;
        if (g_iRlvaVersion) sPrompt += " / RLVa v"+g_sRlvaVersionString;
    } else if (g_iRLVOff) sPrompt += "\nRLV is turned off.";
    else {
        if (g_iRLVOn) sPrompt += "\nThe RLV script is still trying to handshake with the viewer. Just wait another minute and try again.\n\n[ON] restarts the RLV handshake cycle.";
        else sPrompt += "\nRLV appears to be disabled in the viewer's preferences.\n\n[ON] attempts another RLV handshake with the viewer.";
        sPrompt += "\n\n[OFF] will prevent the %DEVICETYPE% from attempting another \"@versionnew=293847\" handshake at the next login.\n\nNOTE: Turning RLV off here means that it has to be manually turned on once activated in the viewer.";
    }
    list lButtons;
    if (g_iRlvActive) {
        lButtons = llListSort(g_lMenu, 1, TRUE);
        integer iRelay = llListFindList(lButtons,["Relay"]);
        integer iTerminal = llListFindList(lButtons,["Terminal"]);
        if (~iRelay && ~iTerminal) {
            lButtons = llListReplaceList(lButtons,["Relay"],iTerminal,iTerminal);
            lButtons = llDeleteSubList(lButtons,iRelay,iRelay);
        }
        lButtons = [TURNOFF, CLEAR] + lButtons;
    } else if (g_iRLVOff) lButtons = [TURNON];
    else lButtons = [TURNON, TURNOFF];
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|0|" + llDumpList2String(lButtons, "`") + "|" + UPMENU + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, g_sSubMenu], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, g_sSubMenu];

}

DoLock(){
    integer numSources=llGetListLength(llList2ListStrided(g_lRestrictions,0,-2,2));
    while (numSources--){
        if ((key)llList2Key(llList2ListStrided(g_lRestrictions,0,-2,2),numSources)){
            ApplyAdd("detach");
            return;
        }
    }
    ApplyRem("detach");
}

ApplyAdd (string sBehav) {
    if (! ~llListFindList(g_lBaked, [sBehav])) {
        g_lBaked+=[sBehav];
        llOwnerSay("@"+sBehav+"=n");



    }
}

AddRestriction(key kID, string sBehav) {

    integer iSource=llListFindList(g_lRestrictions,[kID]);
    if (! ~iSource ) {
        g_lRestrictions += [kID,""];
        iSource=-2;
        if ((key)kID) llMessageLinked(LINK_ALL_OTHERS, CMD_ADDSRC,"",kID);
    }
    string sSrcRestr = llList2String(g_lRestrictions,iSource+1);


    if (!~llSubStringIndex("§"+sSrcRestr+"§","§"+sBehav+"§")) {

        sSrcRestr+="§"+sBehav;
        if (llSubStringIndex(sSrcRestr,"§")==0) sSrcRestr=llGetSubString(sSrcRestr,1,-1);

        g_lRestrictions=llListReplaceList(g_lRestrictions,[sSrcRestr],iSource+1, iSource+1);

        ApplyAdd(sBehav);
        if (sBehav=="unsit") {
            g_kSitTarget = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
            g_kSitter=kID;
        }
    }
    DoLock();
}

default {
    on_rez(integer param) {


        g_iRlvActive=FALSE;
        g_iViewerCheck=FALSE;
        g_iRLVOn=FALSE;
        g_lBaked=[];
        llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_RLV","");
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);

        FailSafe(0);
        setRlvState();


        llOwnerSay("@clear");
        g_kWearer = llGetOwner();

    }

    listen(integer iChan, string sName, key kID, string sMsg) {


        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        g_iCheckCount = 0;
        g_iViewerCheck = TRUE;


        list lParam = llParseString2List(sMsg,[" "],[""]);

        list lVersionSplit = llParseString2List(llGetSubString(llList2String(lParam,2), 1, -1),["."],[]);
        g_iRlvVersion = llList2Integer(lVersionSplit,0) * 100 + llList2Integer(lVersionSplit,1);
        string sRlvResponseString = llList2String(lParam,2);
        g_sRlvVersionString = llGetSubString(sRlvResponseString,llSubStringIndex(sRlvResponseString,"v")+1,llSubStringIndex(sRlvResponseString,")") );
        string sRlvaResponseString = llList2String(lParam,4);
        g_sRlvaVersionString = llGetSubString(sRlvaResponseString,0,llSubStringIndex(sRlvaResponseString,")") -1);

        lVersionSplit = llParseString2List(g_sRlvaVersionString,["."],[]);
        g_iRlvaVersion = llList2Integer(lVersionSplit,0) * 100 + llList2Integer(lVersionSplit,1);




        setRlvState();

    }





    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lMenu = [] ;
            llMessageLinked(LINK_ALL_OTHERS, MENUNAME_REQUEST, g_sSubMenu, "");
        }
        else if (iNum <= CMD_WEARER && iNum >= CMD_OWNER) UserCommand(iNum, sStr, kID);
        else if (iNum == DIALOG_RESPONSE) {

            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
                llSensorRepeat("N0thin9","abc",ACTIVE,0.1,0.1,0.22);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                lMenuParams=[];
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenu == g_sSubMenu) {
                    if (sMsg == TURNON) {
                        UserCommand(iAuth, "rlv on", kAv);
                    } else if (sMsg == TURNOFF) {
                        UserCommand(iAuth, "rlv off", kAv);
                        DoMenu(kAv, iAuth);
                    } else if (sMsg == CLEAR) {
                        UserCommand(iAuth, "clear", kAv);
                        DoMenu(kAv, iAuth);
                    } else if (sMsg == UPMENU) {
                        llMessageLinked(LINK_ALL_OTHERS, iAuth, "menu "+g_sParentMenu, kAv);
                    } else if (~llListFindList(g_lMenu, [sMsg])) {
                        llMessageLinked(LINK_ALL_OTHERS, iAuth, "menu " + sMsg, kAv);
                    }
                }
            }
        }  else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LM_SETTING_REQUEST && sStr == "ALL") {
            if (g_iRlvActive == TRUE) {
                llSleep(2);
                llMessageLinked(LINK_ALL_OTHERS, RLV_ON, "", NULL_KEY);
                if (g_iRlvaVersion) llMessageLinked(LINK_ALL_OTHERS, RLVA_VERSION, (string) g_iRlvaVersion, NULL_KEY);
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            lParams=[];
            if (sToken == "auth_owner") g_lOwners = llParseString2List(sValue, [","], []);
            else if (sToken==g_sGlobalToken+"lock") g_iCollarLocked=(integer)sValue;
            else if (sToken==g_sSettingToken+"handshakes") g_iMaxViewerChecks=(integer)sValue;
            else if (sToken==g_sSettingToken+"on") {
                g_iRLVOn=(integer)sValue;
                g_iRLVOff = !g_iRLVOn;
                setRlvState();
            }
        } else if (iNum == CMD_SAFEWORD || iNum == CMD_RELAY_SAFEWORD) SafeWord("");
        else if (iNum==RLV_QUERY) {
            if (g_iRlvActive) llMessageLinked(LINK_ALL_OTHERS, RLV_RESPONSE, "ON", "");
            else llMessageLinked(LINK_ALL_OTHERS, RLV_RESPONSE, "OFF", "");
        } else if (iNum == MENUNAME_RESPONSE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            string sThisParent = llList2String(lParams, 0);
            string sChild = llList2String(lParams, 1);
            lParams=[];
            if (sThisParent == g_sSubMenu) {
                if (! ~llListFindList(g_lMenu, [sChild])) {
                    g_lMenu += [sChild];
                }
            }
        } else if (iNum == MENUNAME_REMOVE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            string sThisParent = llList2String(lParams, 0);
            string sChild = llList2String(lParams, 1);
            lParams=[];
            if (sThisParent == g_sSubMenu) {
                integer iIndex = llListFindList(g_lMenu, [sChild]);
                if (iIndex != -1) {
                    g_lMenu = llDeleteSubList(g_lMenu, iIndex, iIndex);
                }
            }
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if (iNum == 451 && kID == "sec") FailSafe(1);
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") {
                LINK_SAVE = iSender;
                if (g_iRLVOn) llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on="+(string)g_iRLVOn, "");
            } else if (sStr == "LINK_REQUEST") llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_RLV","");
        } else if (g_iRlvActive) {
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
            llSensorRepeat("N0thin9","abc",ACTIVE,0.1,0.1,0.22);
            if (iNum == RLV_CMD) {

                list lCommands=llParseString2List(llToLower(sStr),[","],[]);
                while (llGetListLength(lCommands)) {
                    string sCommand=llToLower(llList2String(lCommands,0));
                    list lArgs = llParseString2List(sCommand,["="],[]);
                    string sCom = llList2String(lArgs,0);
                    if (llGetSubString(sCom,-1,-1)==":") sCom=llGetSubString(sCom,0,-2);
                    string sVal = llList2String(lArgs,1);
                    lArgs=[];
                    if (sVal=="n"||sVal=="add") AddRestriction(kID,sCom);
                    else if (sVal=="y"||sVal=="rem") RemRestriction(kID,sCom);
                    else if (sCom=="clear") {

                        integer iSource=llListFindList(g_lRestrictions,[kID]);
                        if (kID=="rlvex"){
                            RemRestriction(kID,sVal);
                        } else if (~iSource) {

                            list lSrcRestr=llParseString2List(llList2String(g_lRestrictions,iSource+1),["§"],[]);
                            integer numRestrictions=llGetListLength(lSrcRestr);
                            list lRestrictionsToRemove;

                            while (llGetListLength(lSrcRestr)) {
                                string  sBehav=llList2String(lSrcRestr,-1);
                                if (sVal=="" || llSubStringIndex(sBehav,sVal)!=-1) {

                                    lRestrictionsToRemove+=sBehav;

                                }
                                lSrcRestr=llDeleteSubList(lSrcRestr,-1,-1);
                            }
                            lSrcRestr=[];

                            while(llGetListLength(lRestrictionsToRemove)){
                                RemRestriction(kID,llList2String(lRestrictionsToRemove,-1));
                                lRestrictionsToRemove=llDeleteSubList(lRestrictionsToRemove,-1,-1);
                            }
                        }
                    } else {

                        if (llSubStringIndex(sCom,"tpto")==0) {
                            if ( ~llListFindList(g_lBaked,["tploc"])  || ~llListFindList(g_lBaked,["unsit"]) ) {
                                if ((key)kID) llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Can't teleport due to RLV restrictions",kID);
                                return;
                            }
                        } else if (sStr=="unsit=force") {
                            if (~llListFindList(g_lBaked,["unsit"]) ) {
                                if ((key)kID) llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Can't force stand due to RLV restrictions",kID);
                                return;
                            }
                        }
                        llOwnerSay("@"+sCommand);
                        if (g_kSitter==NULL_KEY&&llGetSubString(sCommand,0,3)=="sit:") {
                            g_kSitter=kID;

                            g_kSitTarget=(key)llGetSubString(sCom,4,-1);

                        }
                    }

                    lCommands=llDeleteSubList(lCommands,0,0);

                }
            } else if (iNum == CMD_RLV_RELAY) {
                if (llGetSubString(sStr,-43,-1)== ","+(string)g_kWearer+",!pong") {

                    if (kID==g_kSitter) llOwnerSay("@"+"sit:"+(string)g_kSitTarget+"=force");
                    rebakeSourceRestrictions(kID);
                }
            }
        }
    }

    no_sensor() {
        llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_HIGH,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.0]);
        llSensorRemove();
    }

    timer() {
        if (g_iWaitRelay) {
            if (g_iWaitRelay < 2) {
                g_iWaitRelay = 2;
                llMessageLinked(LINK_ALL_OTHERS, RLV_ON, "", NULL_KEY);
                llMessageLinked(LINK_ALL_OTHERS, RLV_VERSION, (string)g_iRlvVersion, "");
                if (g_iRlvaVersion)
                    llMessageLinked(LINK_ALL_OTHERS, RLVA_VERSION, (string)g_iRlvaVersion, "");
                DoLock();
                llSetTimerEvent(3.0);
            } else {
                llSetTimerEvent(0.0);
                g_iWaitRelay = FALSE;
                integer i;
                for (i=0;i<llGetListLength(g_lRestrictions)/2;i++) {
                    key kSource=(key)llList2String(llList2ListStrided(g_lRestrictions,0,-1,2),i);
                    if ((key)kSource) llShout(RELAY_CHANNEL,"ping,"+(string)kSource+",ping,ping");
                    else rebakeSourceRestrictions(kSource);
                }
                if (!llGetStartParameter()) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"RLV ready!",g_kWearer);
            }
        } else {
            if (g_iCheckCount++ < g_iMaxViewerChecks) {
                llOwnerSay("@versionnew=293847");

            } else {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"\n\nRLV appears to be disabled in your viewer. There will be no further attempted handshakes \"@versionnew=293847\" until the next time you log in. To permanently turn RLV off, type \"/%CHANNEL% %PREFIX% rlv off\" but keep in mind that you will have to manually enable it if you wish to use it in the future.", g_kWearer);
                llSetTimerEvent(0.0);
                llListenRemove(g_iListener);
                g_iCheckCount=0;
                g_iViewerCheck = FALSE;
                g_iRlvVersion = FALSE;
                g_iRlvaVersion = FALSE;

                g_iRLVOn = FALSE;

            }
        }
    }
    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange * CHANGED_INVENTORY) FailSafe(0);

        if (iChange & CHANGED_TELEPORT || iChange & CHANGED_REGION) {

            integer numBaked=llGetListLength(g_lBaked);
            while (numBaked--){
                llOwnerSay("@"+llList2String(g_lBaked,numBaked)+"=n");

            }

        }
    }


}
