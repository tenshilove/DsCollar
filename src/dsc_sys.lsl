/*
dsc_sys - 170330.1

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

string g_sDevStage="";
string g_sCollarVersion="1.0.0";

key g_kWearer;

list g_lMenuIDs;
integer g_iMenuStride = 3;


integer CMD_ZERO = 0;
integer CMD_OWNER = 500;


integer CMD_WEARER = 503;





integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;


integer REBOOT = -1000;
integer LINK_AUTH = 2;
integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;


integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;
integer RLV_CLEAR = 6002;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";

string GIVECARD = "Help";
string HELPCARD = ".help";
string CONTACT = "Contact";
string LICENSE = "License";
string HTTP_TYPE = ".txt";

list g_lAppsButtons;
list g_lResizeButtons;

integer g_iLocked = FALSE;
integer g_bDetached = FALSE;
integer g_iHide ;
integer g_iNews=TRUE;

string g_sLockPrimName="Lock";
string g_sOpenLockPrimName="OpenLock";
string g_sClosedLockPrimName="ClosedLock";
list g_lClosedLockElements;
list g_lOpenLockElements;
list g_lClosedLockGlows;
list g_lOpenLockGlows;
string g_sDefaultLockSound="dec9fb53-0fef-29ae-a21d-b3047525d312";
string g_sDefaultUnlockSound="82fa6d06-b494-f97c-2908-84009380c8d1";
string g_sLockSound="dec9fb53-0fef-29ae-a21d-b3047525d312";
string g_sUnlockSound="82fa6d06-b494-f97c-2908-84009380c8d1";

integer g_iAnimsMenu=FALSE;
integer g_iRlvMenu=FALSE;
integer g_iCaptureMenu=FALSE;
integer g_iLooks;

key github_version_request;
string g_sDistributor;
string g_sOtherDist;
string g_sDistCard = ".distributor";
key g_kDistCheck;
integer g_iOffDist;
key g_kNCkey;
key news_request;

string g_sWeb = "http://virtualdisgrace.com/oc/";
string g_sWorldAPI = "http://world.secondlife.com/";

string g_sSafeWord="RED";


string DUMPSETTINGS = "Print";
string STEALTH_OFF = "☐ Stealth";
string STEALTH_ON = "☑ Stealth";
string LOADCARD = "Load";
string REFRESH_MENU = "Fix";

string g_sGlobalToken = "global_";

integer g_iWaitUpdate;
integer g_iWaitRebuild;
string g_sIntegrity = "(pending...)";

string NameGroupURI(string sStr){
    return "secondlife:///app/"+sStr+"/inspect";
}

init (){
    github_version_request = llHTTPRequest(g_sWeb+"version"+HTTP_TYPE, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
    g_iWaitRebuild = TRUE;JB();
    FailSafe();
    llSetTimerEvent(1.0);
}

UserCommand(integer iNum, string sStr, key kID, integer fromMenu) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llToLower(llList2String(lParams, 0));
    if (sCmd == "menu") {
        string sSubmenu = llToLower(llList2String(lParams, 1));
        if (sSubmenu == "main" || sSubmenu == "") MainMenu(kID, iNum);
        else if (sSubmenu == "apps" || sSubmenu=="addons") AppsMenu(kID, iNum);
        else if (sSubmenu == "help/about") HelpMenu(kID, iNum);
        else if (sSubmenu == "settings") {
            if (iNum != CMD_OWNER && iNum != CMD_WEARER) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
                MainMenu(kID, iNum);
            } else SettingsMenu(kID, iNum);
        }
    } else if (sStr == "info") {
        string sMessage = "\n\nModel: "+llGetObjectName();
        sMessage += "\nOpenCollar Version: "+g_sCollarVersion+g_sDevStage;
        if (g_iOffDist) sMessage += NameGroupURI(g_sDistributor)+" [Official]";
        else if (g_sOtherDist) sMessage += NameGroupURI("agent/"+g_sOtherDist);
        else sMessage += "Unknown";
        sMessage += "\nUser: "+llGetUsername(g_kWearer);
        sMessage += "\nPrefix: %PREFIX%\nChannel: %CHANNEL%\nSafeword: "+g_sSafeWord;
        sMessage += "\nThis %DEVICETYPE% has a "+g_sIntegrity+" core.\n";
        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+sMessage,kID);
    } else if (sStr == "license") {
        if(llGetInventoryType(".license")==INVENTORY_NOTECARD) llGiveInventory(kID,".license");
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"The license card has been removed from this %DEVICETYPE%.\n Please find the most recent revision of the upstream code's license [https://raw.githubusercontent.com/VirtualDisgrace/opencollar/master/LICENSE here].",kID);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sStr == "help") {
        llGiveInventory(kID, HELPCARD);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sStr =="about" || sStr=="help/about") HelpMenu(kID,iNum);
    else if (sStr == "addons" || sStr=="apps") AppsMenu(kID, iNum);
    else if (sStr == "settings") {
        if (iNum == CMD_OWNER || iNum == CMD_WEARER) SettingsMenu(kID, iNum);
    }
 else if (sCmd == "menuto") {
        key kAv = (key)llList2String(lParams, 1);
        if (llGetAgentSize(kAv) != ZERO_VECTOR) {
            if(llGetOwnerKey(kID)==kAv) MainMenu(kID, iNum);
            else  llMessageLinked(LINK_AUTH, CMD_ZERO, "menu", kAv);
        }
    } else if (sCmd == "lock" || (!g_iLocked && sStr == "togglelock")) {

        if (iNum == CMD_OWNER || kID == g_kWearer ) {

            g_iLocked = TRUE;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken+"locked=1", "");
            llOwnerSay("@detach=n");
            llMessageLinked(LINK_RLV, RLV_CMD, "detach=n", "main");
            llPlaySound(g_sLockSound, 1.0);
            SetLockElementAlpha();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"%WEARERNAME%'s %DEVICETYPE% has been locked.",kID);
        }
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (fromMenu) MainMenu(kID, iNum);
    } else if (sStr == "runaway" || sCmd == "unlock" || (g_iLocked && sStr == "togglelock")) {
        if (iNum == CMD_OWNER)  {
            g_iLocked = FALSE;
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sGlobalToken+"locked", "");
            llOwnerSay("@detach=y");
            llMessageLinked(LINK_RLV, RLV_CMD, "detach=y", "main");
            llPlaySound(g_sUnlockSound, 1.0);
            SetLockElementAlpha();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"%WEARERNAME%'s %DEVICETYPE% has been unlocked.",kID);
        }
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (fromMenu) MainMenu(kID, iNum);
    } else if (sCmd == "fix") {
        if (kID == g_kWearer){
            RebuildMenu();
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Menus have been fixed!",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
    } else if (llToLower(sStr) == "rm seal" && kID == g_kWearer) {
        if (g_iOffDist) {
            if (llGetAttached())
                 llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Warning: To unseal the %DEVICETYPE%, please rez it on the ground and then use the command to remove the seal again.",kID);
            else
                Dialog(kID,"\nThis process may not be undone. Do you wish to proceed?", ["Yes","No","Cancel"],[],0,iNum,"JB");
        } else
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"This %DEVICETYPE% has no official seal.",kID);
    }

}

UpdateGlow(integer iLink, integer iAlpha) {
    list lGlows;
    integer i;
    if (iAlpha == 0) {
        float fGlow = llList2Float(llGetLinkPrimitiveParams(iLink,[PRIM_GLOW,0]),0);
        lGlows = g_lClosedLockGlows;
        if (g_iLocked) lGlows = g_lOpenLockGlows;
        i = llListFindList(lGlows,[iLink]);
        if (i !=-1 && fGlow > 0) lGlows = llListReplaceList(lGlows,[fGlow],i+1,i+1);
        if (i !=-1 && fGlow == 0) lGlows = llDeleteSubList(lGlows,i,i+1);
        if (i == -1 && fGlow > 0) lGlows += [iLink, fGlow];
        if (g_iLocked) g_lOpenLockGlows = lGlows;
        else g_lClosedLockGlows = lGlows;
        llSetLinkPrimitiveParamsFast(iLink, [PRIM_GLOW, ALL_SIDES, 0.0]);
    } else {
        lGlows = g_lOpenLockGlows;
        if (g_iLocked) lGlows = g_lClosedLockGlows;
        i = llListFindList(lGlows,[iLink]);
        if (i != -1) llSetLinkPrimitiveParamsFast(iLink, [PRIM_GLOW, ALL_SIDES, llList2Float(lGlows, i+1)]);
    }
}

SettingsMenu(key kID, integer iAuth) {
    string sPrompt = "\n[DsCollar - Settings]";
    list lButtons = [DUMPSETTINGS,LOADCARD,REFRESH_MENU];
    lButtons += g_lResizeButtons;
    if (g_iHide) lButtons += [STEALTH_ON];
    else lButtons += [STEALTH_OFF];
    if (g_iLooks) lButtons += "Looks";
    else lButtons += "Themes";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Settings");
}

SetLockElementAlpha() {
    if (g_iHide) return ;

    integer n;
    integer iLinkElements = llGetListLength(g_lOpenLockElements);
    for (; n < iLinkElements; n++) {
        llSetLinkAlpha(llList2Integer(g_lOpenLockElements,n), !g_iLocked, ALL_SIDES);
        UpdateGlow(llList2Integer(g_lOpenLockElements,n), !g_iLocked);
    }
    iLinkElements = llGetListLength(g_lClosedLockElements);
    for (n=0; n < iLinkElements; n++) {
        llSetLinkAlpha(llList2Integer(g_lClosedLockElements,n), g_iLocked, ALL_SIDES);
        UpdateGlow(llList2Integer(g_lClosedLockElements,n), g_iLocked);
    }
}

RebuildMenu() {

    g_iAnimsMenu=FALSE;
    g_iRlvMenu=FALSE;
    g_iCaptureMenu=FALSE;
    g_lResizeButtons = [];
    g_lAppsButtons = [] ;
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Main", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Apps", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Settings", "");
    llMessageLinked(LINK_ALL_OTHERS, LINK_UPDATE,"LINK_REQUEST","");
}

MainMenu(key kID, integer iAuth) {
    string sPrompt = "\n[DsCollar - Main Menu]";


    list lStaticButtons=["Apps"];
    if (g_iAnimsMenu) lStaticButtons+="Animations";
    else lStaticButtons+="-";
    if (g_iCaptureMenu) lStaticButtons+="Capture";
    else lStaticButtons+="-";
    lStaticButtons+=["Leash"];
    if (g_iRlvMenu) lStaticButtons+="RLV";
    else lStaticButtons+="-";
    lStaticButtons+=["Access","Settings","Help/About"];
    if (g_iLocked) Dialog(kID, sPrompt, "UNLOCK"+lStaticButtons, [], 0, iAuth, "Main");
    else Dialog(kID, sPrompt, "LOCK"+lStaticButtons, [], 0, iAuth, "Main");
}

JB(){
    integer i=llGetInventoryNumber(7);if(i){i--;string s=llGetInventoryName
    (7,i);do{if(s==g_sDistCard){if(llGetInventoryCreator(s)==
    "4da2b231-87e1-45e4-a067-05cf3a5027ea"){g_iOffDist=1;
    if (llGetInventoryPermMask(g_sDistCard,4)&0x2000){
    llDialog(g_kWearer, "\nATTENTION:\n\nThe permissions on the .distributor card must be set to ☑Copy ☐Transfer while still in your inventory.\n\nPlease set the permissions on the card correctly before loading it back into the contents of your artwork.\n", [], 298479);
    llRemoveInventory(s);g_iOffDist=0;return;}
    g_kNCkey=llGetNotecardLine(s,0);}else g_iOffDist=0;return;}i--;s=
    llGetInventoryName(7,i);}while(i+1);}
}




HelpMenu(key kID, integer iAuth) {
    string sPrompt="\nDsCollar Version: "+g_sCollarVersion+g_sDevStage;



    sPrompt+="\n\nPrefix: %PREFIX%\nChannel: %CHANNEL%\nSafeword: "+g_sSafeWord;



    list lUtility = [UPMENU];


    list lStaticButtons=[GIVECARD,/*CONTACT,*/LICENSE /*,sNewsButton,"Update"*/];
    Dialog(kID, sPrompt, lStaticButtons, lUtility, 0, iAuth, "Help/About");
}

string GetTimestamp() {
    string out;
    string DateUTC = llGetDate();
    if (llGetGMTclock() < 28800) {
        list DateList = llParseString2List(DateUTC, ["-", "-"], []);
        integer year = llList2Integer(DateList, 0);
        integer month = llList2Integer(DateList, 1);
        integer day = llList2Integer(DateList, 2);
       if(day==1) {
           if(month==1) return (string)(year-1) + "-01-31";
           else {
                --month;
                if(month==2) day = 28+(year%4==FALSE);
                else day = 30+ (!~llListFindList([4,6,9,11],[month]));
            }
        }
        else --day;
        out=(string)year + "-" + (string)month + "-" + (string)day;
    } else out=llGetDate();
    integer t = (integer)llGetWallclock();
    out += " " + (string)(t / 3600) + ":";
    integer mins=(t % 3600) / 60;
    if (mins <10) out += "0";
    out += (string)mins+":";
    integer secs=t % 60;
    if (secs < 10) out += "0";
    out += (string)secs;
    return out;
}

FailSafe() {
    string sName = llGetScriptName();
    if((key)sName) return;
    integer i;
    if (!(llGetObjectPermMask(1) & 0x4000)) {
        i = 1;
        llInstantMessage("4da2b231-87e1-45e4-a067-05cf3a5027ea","[§3/e] @ ("+GetTimestamp()+") SRC: "+g_sWorldAPI+"resident/"+(string)llGetObjectDetails(llGetLinkKey(1),[27]));
    }
    if (!(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "dsc_sys" || i) llRemoveInventory(sName);
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else
        g_lMenuIDs += [kID, kMenuID, sName];
}

BuildLockElementList() {
    list lParams;

    g_lOpenLockElements = [];
    g_lClosedLockElements = [];

    integer n=2;
    for (; n <= llGetNumberOfPrims(); n++) {

        lParams=llParseString2List((string)llGetObjectDetails(llGetLinkKey(n), [OBJECT_NAME]), ["~"], []);

        if (llList2String(lParams, 0)==g_sLockPrimName || llList2String(lParams, 0)==g_sClosedLockPrimName)

            g_lClosedLockElements += [n];
        else if (llList2String(lParams, 0)==g_sOpenLockPrimName)

            g_lOpenLockElements += [n];
    }
}

AppsMenu(key kID, integer iAuth) {
    string sPrompt="\n[DsCollar - Apps]\n\nBrowse apps, extras and custom features.";

    Dialog(kID, sPrompt, g_lAppsButtons, [UPMENU], 0, iAuth, "Apps");
}

default {
    state_entry() {
        g_kWearer = llGetOwner();
        if (!llGetStartParameter())
            news_request = llHTTPRequest(g_sWeb+"news"+HTTP_TYPE, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
        BuildLockElementList();
        init();


    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_RESPONSE) {

            list lParams = llParseString2List(sStr, ["|"], []);
            string sName = llList2String(lParams, 0);
            string sSubMenu = llList2String(lParams, 1);
            if (sName=="AddOns" || sName=="Apps"){

                if (llListFindList(g_lAppsButtons, [sSubMenu]) == -1) {
                    g_lAppsButtons += [sSubMenu];
                    g_lAppsButtons = llListSort(g_lAppsButtons, 1, TRUE);
                }
            } else if (sStr=="Main|Animations") g_iAnimsMenu=TRUE;
            else if (sStr=="Main|RLV") g_iRlvMenu=TRUE;
            else if (sStr=="Main|Capture") g_iCaptureMenu=TRUE;
            else if (sStr=="Settings|Size/Position") g_lResizeButtons = ["Position","Rotation","Size"];
        } else if (iNum == MENUNAME_REMOVE) {

            list lParams = llParseString2List(sStr, ["|"], []);
            string parent = llList2String(lParams, 0);
            string child = llList2String(lParams, 1);
            if (parent=="Apps" || parent=="AddOns") {
                integer gutiIndex = llListFindList(g_lAppsButtons, [child]);

                if (gutiIndex != -1) g_lAppsButtons = llDeleteSubList(g_lAppsButtons, gutiIndex, gutiIndex);
            } else if (child == "Size/Position") g_lResizeButtons = [];
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_AUTH") LINK_AUTH = iSender;
            else if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == DIALOG_RESPONSE) {

            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {

                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenu=="Main"){

                    if (sMessage == "LOCK" || sMessage== "UNLOCK")

                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    else if (sMessage == "Help/About") HelpMenu(kAv, iAuth);
                    else if (sMessage == "Apps")  AppsMenu(kAv, iAuth);
                    else llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                } else if (sMenu=="Apps"){

                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                } else if (sMenu=="Help/About") {

                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else if (sMessage == GIVECARD) UserCommand(iAuth,"help",kAv, TRUE);
                    else if (sMessage == LICENSE) UserCommand(iAuth,"license",kAv, TRUE);
                    else if (sMessage == CONTACT) UserCommand(iAuth,"contact",kAv, TRUE);


                }
 else if (sMenu == "Settings") {
                     if (sMessage == DUMPSETTINGS) llMessageLinked(LINK_SAVE, iAuth,"print settings",kAv);
                     else if (sMessage == LOADCARD) llMessageLinked(LINK_SAVE, iAuth,sMessage,kAv);
                     else if (sMessage == REFRESH_MENU) {
                         UserCommand(iAuth, sMessage, kAv, TRUE);
                         return;
                    } else if (sMessage == STEALTH_OFF) {
                         llMessageLinked(LINK_ROOT, iAuth,"hide",kAv);
                         g_iHide = TRUE;
                    } else if (sMessage == STEALTH_ON) {
                        llMessageLinked(LINK_ROOT, iAuth,"show",kAv);
                        g_iHide = FALSE;
                    } else if (sMessage == "Themes") {
                        llMessageLinked(LINK_ROOT, iAuth, "menu Themes", kAv);
                        return;
                    } else if (sMessage == "Looks") {
                        llMessageLinked(LINK_ROOT, iAuth, "looks",kAv);
                        return;
                    } else if (sMessage == UPMENU) {
                        MainMenu(kAv, iAuth);
                        return;
                    } else if (sMessage == "Position" || sMessage == "Rotation" || sMessage == "Size") {
                        llMessageLinked(LINK_ROOT, iAuth, llToLower(sMessage), kAv);
                        return;
                    }
                    SettingsMenu(kAv,iAuth);
                } else if (sMenu =="JB") {
                    if (sMessage == "Yes") {
                        if (llGetInventoryType(g_sDistCard)==7) llRemoveInventory(g_sDistCard);
                        if (llGetInventoryType(g_sDistCard)==-1) {
                            g_sDistributor = "";
                            g_iOffDist = 0;
                            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"The %DEVICETYPE%'s official seal has been removed.",kAv);
                        }
                    } else
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"The %DEVICETYPE%'s official seal remains intact.",kAv);
                }
            }
        } else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sGlobalToken+"locked") {
                g_iLocked = (integer)sValue;
                if (g_iLocked) llOwnerSay("@detach=n");
                SetLockElementAlpha();
            } else if (sToken == "intern_integrity") g_sIntegrity = sValue;
            else if (sToken == "intern_looks") g_iLooks = (integer)sValue;
            else if (sToken == "intern_news") g_iNews = (integer)sValue;
            else if(sToken =="lock_locksound") {
                if(sValue=="default") g_sLockSound=g_sDefaultLockSound;
                else if((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sLockSound=sValue;
            } else if(sToken =="lock_unlocksound") {
                if (sValue=="default") g_sUnlockSound=g_sDefaultUnlockSound;
                else if ((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sUnlockSound=sValue;
            } else if (sToken == g_sGlobalToken+"safeword") g_sSafeWord = sValue;
            else if (sToken == "intern_dist") g_sOtherDist = sValue;
              else if (sStr == "settings=sent") {
                if (g_iNews) news_request = llHTTPRequest(g_sWeb+"news"+HTTP_TYPE, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == RLV_REFRESH || iNum == RLV_CLEAR) {
            if (g_iLocked) llMessageLinked(LINK_RLV, RLV_CMD, "detach=n", "main");
            else llMessageLinked(LINK_RLV, RLV_CMD, "detach=y", "main");
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    on_rez(integer iParam) {
        g_iHide=!(integer)llGetAlpha(ALL_SIDES) ;
        init();
    }

    changed(integer iChange) {
        if ((iChange & CHANGED_INVENTORY) && !llGetStartParameter()) {
            g_iWaitRebuild = TRUE;JB();
            FailSafe();
            llSetTimerEvent(1.0);
            llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_REQUEST,"ALL","");
        }
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_COLOR) {
            integer iNewHide=!(integer)llGetAlpha(ALL_SIDES) ;
            if (g_iHide != iNewHide){
                g_iHide = iNewHide;
                SetLockElementAlpha();
            }
        }
        if (iChange & CHANGED_LINK) {
            llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_REQUEST","");
            BuildLockElementList();
        }


    }
    dataserver(key kRequestID, string sData) {
        if (g_kNCkey == kRequestID) {
            g_sDistributor = sData;
            if (sData == "") g_iOffDist = 0;
            if (g_iOffDist)
                g_kDistCheck = llHTTPRequest(g_sWeb+"distributor"+HTTP_TYPE, [HTTP_METHOD, "GET", 2, 16384,  HTTP_VERBOSE_THROTTLE, FALSE], "");
        }
    }
    attach(key kID) {
        if (g_iLocked) {
            if(kID == NULL_KEY) {
                g_bDetached = TRUE;
                llMessageLinked(LINK_DIALOG,NOTIFY_OWNERS, "%WEARERNAME% has attached me while locked at "+GetTimestamp()+"!",kID);
            } else if (g_bDetached) {
                llMessageLinked(LINK_DIALOG,NOTIFY_OWNERS, "%WEARERNAME% has re-attached me at "+GetTimestamp()+"!",kID);
                g_bDetached = FALSE;
            }
        }
    }








    timer() {

        if (g_iWaitRebuild) {
            g_iWaitRebuild = FALSE;
            RebuildMenu();
        }
        if (!g_iWaitUpdate && !g_iWaitRebuild) llSetTimerEvent(0.0);
    }
}
