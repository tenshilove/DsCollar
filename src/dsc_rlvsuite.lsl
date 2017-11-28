/*
dsc_rlvsuite - 170509.0

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

string  RESTRICTION_BUTTON          = "Restrictions";
string  RESTRICTIONS_CHAT_COMMAND   = "restrictions";
string  TERMINAL_BUTTON             = "Terminal";
string  TERMINAL_CHAT_COMMAND       = "terminal";
string  OUTFITS_BUTTON              = "Outfits";
string  COLLAR_PARENT_MENU          = "RLV";
string  UPMENU                      = "BACK";
string  BACKMENU                    = "⏎";

integer g_iMenuCommand;
key     g_kMenuClicker;

list    g_lMenuIDs;
integer g_iMenuStride = 3;





integer g_iSendRestricted;
integer g_iReadRestricted;
integer g_iHearRestricted;
integer g_iTalkRestricted;
integer g_iTouchRestricted;
integer g_iStrayRestricted;
integer g_iRummageRestricted;
integer g_iStandRestricted;
integer g_iDressRestricted;
integer g_iBlurredRestricted;
integer g_iDazedRestricted;

integer g_iSitting;


integer g_iListener;
integer g_iFolderRLV = 98745923;
integer g_iFolderRLVSearch = 98745925;
integer g_iTimeOut = 30;
integer g_iRlvOn = FALSE;
integer g_iRlvaOn = FALSE;
string g_sCurrentPath;
string g_sPathPrefix = ".outfits";


key     g_kWearer;


integer CMD_OWNER                   = 500;
integer CMD_TRUSTED = 501;

integer CMD_WEARER                  = 503;
integer CMD_EVERYONE = 504;

integer CMD_SAFEWORD                = 510;
integer CMD_RELAY_SAFEWORD          = 511;


integer NOTIFY                     = 1002;

integer REBOOT                     = -1000;
integer LINK_DIALOG                = 3;
integer LINK_RLV                   = 4;
integer LINK_SAVE                  = 5;
integer LINK_UPDATE                = -10;
integer LM_SETTING_SAVE            = 2000;

integer LM_SETTING_RESPONSE        = 2002;
integer LM_SETTING_DELETE          = 2003;
integer LM_SETTING_EMPTY           = 2004;



integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;



integer RLV_CMD                    = 6000;
integer RLV_CLEAR                  = 6002;
integer RLV_OFF                    = 6100;
integer RLV_ON                     = 6101;
integer RLVA_VERSION               = 6004;

integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer DIALOG_TIMEOUT             = -9002;
integer SENSORDIALOG               = -9003;
integer g_iAuth;

key g_kLastForcedSeat;
string g_sLastForcedSeat;
string g_sTerminalText = "\n[DsCollar - RLV Command Terminal]\n\nType one command per line without \"@\" sign.";

SitMenu(key kID, integer iAuth) {
    integer iSitting=llGetAgentInfo(g_kWearer)&AGENT_SITTING;
    string sButton;
    string sitPrompt = "\nAbility to Stand up is ";
    if (g_iStandRestricted) sitPrompt += "restricted by ";
    else sitPrompt += "un-restricted.\n";
    if (g_iStandRestricted == 500) sitPrompt += "Owner.\n";
    else if (g_iStandRestricted == 501) sitPrompt += "Trusted.\n";
    else if (g_iStandRestricted == 502) sitPrompt += "Group.\n";

    if (g_iStandRestricted) sButton = "☑ strict`";
    else sButton = "☐ strict`";
    if (iSitting) sButton+="[Get up]`BACK";
    else {
        if (CheckLastSit(g_kLastForcedSeat)==TRUE) {
            sButton+="[Sit back]`BACK";
            sitPrompt="\nLast forced to sit on "+g_sLastForcedSeat+"\n";
        } else sButton+="BACK";
    }
    Dialog(kID, sitPrompt+"\nChoose a seat:\n", [sButton], [], 0, iAuth, "sensor");
}


RestrictionsMenu(key keyID, integer iAuth) {
    string sPrompt = "\n[Restrictions]";
    list lMyButtons;

    if (g_iSendRestricted) lMyButtons += "☐ Send IMs";
    else lMyButtons += "☑ Send IMs";
    if (g_iReadRestricted) lMyButtons += "☐ Read IMs";
    else lMyButtons += "☑ Read IMs";
    if (g_iHearRestricted) lMyButtons += "☐ Hear";
    else lMyButtons += "☑ Hear";
    if (g_iTalkRestricted) lMyButtons += "☐ Talk";
    else lMyButtons += "☑ Talk";
    if (g_iTouchRestricted) lMyButtons += "☐ Touch";
    else lMyButtons += "☑ Touch";
    if (g_iStrayRestricted) lMyButtons += "☐ Stray";
    else lMyButtons += "☑ Stray";
    if (g_iRummageRestricted) lMyButtons += "☐ Rummage";
    else lMyButtons += "☑ Rummage";
    if (g_iDressRestricted) lMyButtons += "☐ Dress";
    else lMyButtons += "☑ Dress";
    lMyButtons += "RESET";
    if (g_iBlurredRestricted) lMyButtons += "Un-Dazzle";
    else lMyButtons += "Dazzle";
    if (g_iDazedRestricted) lMyButtons += "Un-Daze";
    else lMyButtons += "Daze";

    Dialog(keyID, sPrompt, lMyButtons, ["BACK"], 0, iAuth, "restrictions");
}

OutfitsMenu(key kID, integer iAuth) {
    g_kMenuClicker = kID;
    g_iAuth = iAuth;
    g_sCurrentPath = g_sPathPrefix + "/";
    llSetTimerEvent(g_iTimeOut);
    g_iListener = llListen(g_iFolderRLV, "", g_kWearer, "");
    llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
}

releaseRestrictions() {
    g_iSendRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_send","");
    g_iReadRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_read","");
    g_iHearRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_hear","");
    g_iTalkRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_talk","");
    g_iStrayRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_touch","");
    g_iTouchRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_stray","");
    g_iRummageRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_stand","");
    g_iStandRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_rummage","");
    g_iDressRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_dress","");
    g_iBlurredRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_blurred","");
    g_iDazedRestricted=FALSE;
    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_dazed","");

    doRestrictions();
}

doRestrictions(){
    if (g_iSendRestricted)     llMessageLinked(LINK_RLV,RLV_CMD,"sendim=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"sendim=y","vdRestrict");

    if (g_iReadRestricted)     llMessageLinked(LINK_RLV,RLV_CMD,"recvim=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"recvim=y","vdRestrict");

    if (g_iHearRestricted)     llMessageLinked(LINK_RLV,RLV_CMD,"recvchat=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"recvchat=y","vdRestrict");

    if (g_iTalkRestricted)     llMessageLinked(LINK_RLV,RLV_CMD,"sendchat=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"sendchat=y","vdRestrict");

    if (g_iTouchRestricted)    llMessageLinked(LINK_RLV,RLV_CMD,"touchall=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"touchall=y","vdRestrict");

    if (g_iStrayRestricted)    llMessageLinked(LINK_RLV,RLV_CMD,"tplm=n,tploc=n,tplure=n,sittp=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"tplm=y,tploc=y,tplure=y,sittp=y","vdRestrict");

    if (g_iStandRestricted) {
        if (llGetAgentInfo(g_kWearer)&AGENT_SITTING) llMessageLinked(LINK_RLV,RLV_CMD,"unsit=n","vdRestrict");
    } else llMessageLinked(LINK_RLV,RLV_CMD,"unsit=y","vdRestrict");

    if (g_iRummageRestricted)  llMessageLinked(LINK_RLV,RLV_CMD,"showinv=n,viewscript=n,viewtexture=n,edit=n,rez=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"showinv=y,viewscript=y,viewtexture=y,edit=y,rez=y","vdRestrict");

    if (g_iDressRestricted)    llMessageLinked(LINK_RLV,RLV_CMD,"addattach=n,remattach=n,defaultwear=n,addoutfit=n,remoutfit=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"addattach=y,remattach=y,defaultwear=y,addoutfit=y,remoutfit=y","vdRestrict");

    if (g_iBlurredRestricted)  llMessageLinked(LINK_RLV,RLV_CMD,"setdebug_renderresolutiondivisor:16=force","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"setdebug_renderresolutiondivisor:1=force","vdRestrict");

    if (g_iDazedRestricted)    llMessageLinked(LINK_RLV,RLV_CMD,"shownames=n,showhovertextworld=n,showloc=n,showworldmap=n,showminimap=n","vdRestrict");
    else llMessageLinked(LINK_RLV,RLV_CMD,"shownames=y,showhovertextworld=y,showloc=y,showworldmap=y,showminimap=y","vdRestrict");
}

WearFolder (string sStr) {
    string sAttach ="@attachallover:"+sStr+"=force,attachallover:"+g_sPathPrefix+"/.core/=force";
    string sPrePath;
    list lTempSplit = llParseString2List(sStr,["/"],[]);
    lTempSplit = llList2List(lTempSplit,0,llGetListLength(lTempSplit) -2);
    sPrePath = llDumpList2String(lTempSplit,"/");
    if (g_sPathPrefix + "/" != sPrePath)
        sAttach += ",attachallover:"+sPrePath+"/.core/=force";

    llOwnerSay("@remoutfit=force,detach=force");
    llSleep(1.5);
    llOwnerSay(sAttach);
}

UserCommand(integer iNum, string sStr, key kID, integer bFromMenu) {
    string sLowerStr=llToLower(sStr);


    if (sLowerStr == "outfits" || sLowerStr == "menu outfits") {
        if (g_iRlvaOn) OutfitsMenu(kID, iNum);
        else {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nWarning: This feature can not work with the original RLV specification.\nTo use it, a RLVa-enabled vieweris required. The regular \"# Folders\" feature is a good alternative to this.\n" ,kID);
            llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
        }
        return;
    } else if (llSubStringIndex(sStr,"wear ") == 0) {
        if (!g_iRlvaOn) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nWarning: This feature can not work with the original RLV specification.\nTo use it, a RLVa-enabled vieweris required. The regular \"# Folders\" feature is a good alternative to this.\n" ,kID);
            if (bFromMenu) llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
            return;
        } else if (g_iDressRestricted)
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Warning: You can not wear Outfits while the ability to dress is restricted.",kID);
        else {
            sLowerStr = llDeleteSubString(sStr,0,llStringLength("wear ")-1);
            if (sLowerStr) {
                llSetTimerEvent(g_iTimeOut);
                g_iListener = llListen(g_iFolderRLVSearch, "", g_kWearer, "");
                g_kMenuClicker = kID;
                if (g_iRlvaOn) {
                    llOwnerSay("@findfolders:"+sLowerStr+"="+(string)g_iFolderRLVSearch);
                }
                else {
                    llOwnerSay("@findfolder:"+sLowerStr+"="+(string)g_iFolderRLVSearch);
                }
            }
        }
        if (bFromMenu) OutfitsMenu(kID, iNum);
        return;
    }

    if (iNum==CMD_WEARER) {
        if (sStr == RESTRICTIONS_CHAT_COMMAND || sLowerStr == "sit" || sLowerStr == TERMINAL_CHAT_COMMAND) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%NOACCESS%",kID);
        } else if (sLowerStr == "menu force sit" || sStr == "menu " + RESTRICTION_BUTTON || sStr == "menu " + TERMINAL_BUTTON){
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%NOACCESS%",kID);
            llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
        }
        return;
    } else if (sStr == RESTRICTIONS_CHAT_COMMAND || sStr == "menu " + RESTRICTION_BUTTON) {
        RestrictionsMenu(kID, iNum);
        return;
    } else if (sStr == TERMINAL_CHAT_COMMAND || sStr == "menu " + TERMINAL_BUTTON) {
        if (sStr == TERMINAL_CHAT_COMMAND) g_iMenuCommand = FALSE;
        else g_iMenuCommand = TRUE;
        Dialog(kID, g_sTerminalText, [], [], 0, iNum, "terminal");
        return;
    } else if (sLowerStr == "restrictions back") {
        llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
        return;
    } else if (sLowerStr == "restrictions reset" || sLowerStr == "allow all"){
        if (iNum == CMD_OWNER) releaseRestrictions();
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☐ send ims" || sLowerStr == "allow sendim"){
        if (iNum <= g_iSendRestricted || !g_iSendRestricted) {
            g_iSendRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_send","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% may send IMs again.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ send ims" || sLowerStr == "forbid sendim"){
        if (iNum <= g_iSendRestricted || !g_iSendRestricted) {
            g_iSendRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_send="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% may not send IMs.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☐ read ims" || sLowerStr == "allow readim"){
        if (iNum <= g_iReadRestricted || !g_iReadRestricted) {
            g_iReadRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_read","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% may read IMs again.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ read ims" || sLowerStr == "forbid readim"){
        if (iNum <= g_iReadRestricted || !g_iReadRestricted) {
            g_iReadRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_read="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% may not read IMs.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☐ hear" || sLowerStr == "allow hear"){
        if (iNum <= g_iHearRestricted || !g_iHearRestricted) {
            g_iHearRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_hear","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME%'s ears have been unplugged.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ hear" || sLowerStr == "forbid hear"){
        if (iNum <= g_iHearRestricted || !g_iHearRestricted) {
            g_iHearRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_hear="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME%'s ears have been plugged.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☐ touch" || sLowerStr == "allow touch"){
        if (iNum <= g_iTouchRestricted || !g_iTouchRestricted) {
            g_iTouchRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_touch","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% may touch again.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ touch" || sLowerStr == "forbid touch"){
        if (iNum <= g_iTouchRestricted || !g_iTouchRestricted) {
            g_iTouchRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_touch="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% has been forbidden to touch.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☐ stray" || sLowerStr == "allow stray"){
        if (iNum <= g_iStrayRestricted || !g_iStrayRestricted) {
            g_iStrayRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_stray","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% is allowed to travel again.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ stray" || sLowerStr == "forbid stray"){
        if (iNum <= g_iStrayRestricted || !g_iStrayRestricted) {
            g_iStrayRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_stray="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% has been grounded.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);

    } else if (sLowerStr == "restrictions ☐ stand" || sLowerStr == "allow stand"){
        if (iNum <= g_iStandRestricted || !g_iStandRestricted) {
            g_iStandRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_stand","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% is free to stand up again.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ stand" || sLowerStr == "forbid stand"){
        if (iNum <= g_iStandRestricted || !g_iStandRestricted) {
            g_iStandRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_stand="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% may not stand up.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☐ talk" || sLowerStr == "allow talk"){
        if (iNum <= g_iTalkRestricted || !g_iTalkRestricted) {
            g_iTalkRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_talk","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAE% may speak freely again.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ talk" || sLowerStr == "forbid talk"){
        if (iNum <= g_iTalkRestricted || !g_iTalkRestricted) {
            g_iTalkRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_talk="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% has been forbidden to speak.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☐ rummage" || sLowerStr == "allow rummage"){
        if (iNum <= g_iRummageRestricted || !g_iRummageRestricted) {
            g_iRummageRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_rummage","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME%'s closed has been opened.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ rummage" || sLowerStr == "forbid rummage"){
        if (iNum <= g_iRummageRestricted || !g_iRummageRestricted) {
            g_iRummageRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_rummage="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME%'s closet has been closed.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☐ dress" || sLowerStr == "allow dress"){
        if (iNum <= g_iDressRestricted || !g_iDressRestricted) {
            g_iDressRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_dress","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% is allowed to dress again.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions ☑ dress" || sLowerStr == "forbid dress"){
        if (iNum <= g_iDressRestricted || !g_iDressRestricted) {
            g_iDressRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_dress="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% has been forbidden from dressing.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions un-dazzle" || sLowerStr == "undazzle"){
        if (iNum <= g_iBlurredRestricted || !g_iBlurredRestricted) {
            g_iBlurredRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_blurred","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% may see clearly again.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions dazzle" || sLowerStr == "dazzle"){
        if (iNum <= g_iBlurredRestricted || !g_iBlurredRestricted) {
            g_iBlurredRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_blurred="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME%'s vision has been blurred.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions un-daze" || sLowerStr == "undaze"){
        if (iNum <= g_iDazedRestricted || !g_iDazedRestricted) {
            g_iDazedRestricted=FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,"restrictions_dazed","");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% is no longer dazed.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "restrictions daze" || sLowerStr == "daze"){
        if (iNum <= g_iDazedRestricted || !g_iDazedRestricted) {
            g_iDazedRestricted=iNum;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,"restrictions_dazed="+(string)iNum,"");
            doRestrictions();
            llMessageLinked(LINK_DIALOG,NOTIFY,"1%WEARERNAME% is dazed.",kID);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
    } else if (sLowerStr == "stand" || sLowerStr == "standnow"){
        if (iNum <= g_iStandRestricted || !g_iStandRestricted) {
            llMessageLinked(LINK_RLV,RLV_CMD,"unsit=y,unsit=force","vdRestrict");
            g_iSitting = FALSE;


            llSleep(0.5);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
        if (bFromMenu) SitMenu(kID, iNum);
        return;
    } else if (sLowerStr == "menu force sit" || sLowerStr == "sit" || sLowerStr == "sitnow"){
        SitMenu(kID, iNum);


        return;
    } else if (sLowerStr == "sit back") {
        if (iNum <= g_iStandRestricted || !g_iStandRestricted) {
            if (CheckLastSit(g_kLastForcedSeat)==FALSE) return;
            llMessageLinked(LINK_RLV,RLV_CMD,"unsit=y,unsit=force","vdRestrict");
            llSleep(0.5);
            llMessageLinked(LINK_RLV,RLV_CMD,"sit:"+(string)g_kLastForcedSeat+"=force","vdRestrict");
            if (g_iStandRestricted) llMessageLinked(LINK_RLV,RLV_CMD,"unsit=n","vdRestrict");
            g_iSitting = TRUE;
            llSleep(0.5);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
        if (bFromMenu) SitMenu(kID, iNum);
        return;
    } else if (llSubStringIndex(sLowerStr,"sit ") == 0) {
        if (iNum <= g_iStandRestricted || !g_iStandRestricted) {
            sLowerStr = llDeleteSubString(sStr,0,llStringLength("sit ")-1);
            if ((key)sLowerStr) {
                llMessageLinked(LINK_RLV,RLV_CMD,"unsit=y,unsit=force","vdRestrict");
                llSleep(0.5);
                g_kLastForcedSeat=(key)sLowerStr;
                g_sLastForcedSeat=llKey2Name(g_kLastForcedSeat);
                llMessageLinked(LINK_RLV,RLV_CMD,"sit:"+sLowerStr+"=force","vdRestrict");
                if (g_iStandRestricted) llMessageLinked(LINK_RLV,RLV_CMD,"unsit=n","vdRestrict");
                g_iSitting = TRUE;
                llSleep(0.5);
            } else {
                Dialog(kID, "", [""], [sLowerStr,"1"], 0, iNum, "find");
                return;
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0%NOACCESS%",kID);
        if (bFromMenu) SitMenu(kID, iNum);
        return;
    } else if (sLowerStr == "clear") {
        releaseRestrictions();
        return;
    } else if (!llSubStringIndex(sLowerStr, "hudtpto:") && (iNum == CMD_OWNER || iNum == CMD_TRUSTED)) {
        if (g_iRlvOn) llMessageLinked(LINK_RLV,RLV_CMD,llGetSubString(sLowerStr,3,-1),"");
    }
    if (bFromMenu) RestrictionsMenu(kID,iNum);
}

FolderMenu(key keyID, integer iAuth,string sFolders) {
    string sPrompt = "\n[Outfits]";
    sPrompt += "\n\nCurrent Path = "+g_sCurrentPath;
    list lMyButtons = llParseString2List(sFolders,[","],[""]);
    lMyButtons = llListSort(lMyButtons, 1, TRUE);

    list lStaticButtons;
    if (g_sCurrentPath == g_sPathPrefix+"/")
        lStaticButtons = [UPMENU];
    else {
        if (sFolders == "") lStaticButtons = ["WEAR",UPMENU,BACKMENU];
        else lStaticButtons = [UPMENU,BACKMENU];
    }
    Dialog(keyID, sPrompt, lMyButtons, lStaticButtons, 0, iAuth, "folder");
}

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "dsc_rlvsuite")
        llRemoveInventory(sName);
}

DoTerminalCommand(string sMessage, key kID) {
    string sCRLF= llUnescapeURL("%0A");
    list lCommands = llParseString2List(sMessage, [sCRLF], []);
    sMessage = llDumpList2String(lCommands, ",");
    llMessageLinked(LINK_RLV,RLV_CMD,sMessage,"vdTerminal");
    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Your command(s) were sent to %WEARERNAME%'s RL-Viewer:\n" + sMessage, kID);
    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"secondlife:///app/agent/"+(string)kID+"/about" + " has changed your rlv restrictions.", g_kWearer);
}




Dialog(key kRCPT, string sPrompt, list lButtons, list lUtilityButtons, integer iPage, integer iAuth, string sMenuID) {
    key kMenuID = llGenerateKey();
    if (sMenuID == "sensor" || sMenuID == "find")
        llMessageLinked(LINK_DIALOG, SENSORDIALOG, (string)kRCPT +"|"+sPrompt+"|0|``"+(string)(SCRIPTED|PASSIVE)+"`20`"+(string)PI+"`"+llDumpList2String(lUtilityButtons,"`")+"|"+llDumpList2String(lButtons,"`")+"|" + (string)iAuth, kMenuID);
    else
        llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lButtons, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuID], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuID];
}

integer CheckLastSit(key kSit) {
    vector avPos=llGetPos();
    list lastSeatInfo=llGetObjectDetails(kSit, [OBJECT_POS]);
    vector lastSeatPos=(vector)llList2String(lastSeatInfo,0);
    if (llVecDist(avPos,lastSeatPos)<20) return TRUE;
    else return FALSE;
}

default {

    state_entry() {
        g_kWearer = llGetOwner();
        FailSafe();

    }

    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer) llResetScript();
        g_iRlvOn = FALSE;
        g_iRlvaOn = FALSE;
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + RESTRICTION_BUTTON, "");
            llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|Force Sit", "");
            llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + TERMINAL_BUTTON, "");
            llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + OUTFITS_BUTTON, "");
        } else if (iNum == LM_SETTING_EMPTY) {
            if (sStr=="restrictions_send")         g_iSendRestricted=FALSE;
            else if (sStr=="restrictions_read")    g_iReadRestricted=FALSE;
            else if (sStr=="restrictions_hear")    g_iHearRestricted=FALSE;
            else if (sStr=="restrictions_talk")    g_iTalkRestricted=FALSE;
            else if (sStr=="restrictions_touch")   g_iTouchRestricted=FALSE;
            else if (sStr=="restrictions_stray")   g_iStrayRestricted=FALSE;
            else if (sStr=="restrictions_stand")   g_iStandRestricted=FALSE;
            else if (sStr=="restrictions_rummage") g_iRummageRestricted=FALSE;
            else if (sStr=="restrictions_blurred") g_iBlurredRestricted=FALSE;
            else if (sStr=="restrictions_dazed")   g_iDazedRestricted=FALSE;
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (~llSubStringIndex(sToken,"restrictions_")){
                if (sToken=="restrictions_send")          g_iSendRestricted=(integer)sValue;
                else if (sToken=="restrictions_read")     g_iReadRestricted=(integer)sValue;
                else if (sToken=="restrictions_hear")     g_iHearRestricted=(integer)sValue;
                else if (sToken=="restrictions_talk")     g_iTalkRestricted=(integer)sValue;
                else if (sToken=="restrictions_touch")    g_iTouchRestricted=(integer)sValue;
                else if (sToken=="restrictions_stray")    g_iStrayRestricted=(integer)sValue;
                else if (sToken=="restrictions_stand")    g_iStandRestricted=(integer)sValue;
                else if (sToken=="restrictions_rummage")  g_iRummageRestricted=(integer)sValue;
                else if (sToken=="restrictions_blurred")  g_iBlurredRestricted=(integer)sValue;
                else if (sToken=="restrictions_dazed")    g_iDazedRestricted=(integer)sValue;
            }
        }
        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID,FALSE);
        else if (iNum == RLV_ON) {
            g_iRlvOn = TRUE;
            doRestrictions();
            if (g_iSitting && g_iStandRestricted) {
                if (CheckLastSit(g_kLastForcedSeat)==TRUE) {
                    llMessageLinked(LINK_RLV,RLV_CMD,"sit:"+(string)g_kLastForcedSeat+"=force","vdRestrict");
                    if (g_iStandRestricted) llMessageLinked(LINK_RLV,RLV_CMD,"unsit=n","vdRestrict");
                } else llMessageLinked(LINK_RLV,RLV_CMD,"unsit=y","vdRestrict");
            }
        } else if (iNum == RLV_OFF) {
            g_iRlvOn = FALSE;
            releaseRestrictions();
        } else if (iNum == RLV_CLEAR) releaseRestrictions();
        else if (iNum == RLVA_VERSION) g_iRlvaOn = TRUE;
        else if (iNum == CMD_SAFEWORD || iNum == CMD_RELAY_SAFEWORD) releaseRestrictions();
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenu == "restrictions") UserCommand(iAuth, "restrictions "+sMessage,kAv,TRUE);
                else if (sMenu == "sensor") {
                    if (sMessage=="BACK") {
                        llMessageLinked(LINK_RLV, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
                        return;
                    }
                    else if (sMessage == "[Sit back]") UserCommand(iAuth, "sit back", kAv, FALSE);
                    else if (sMessage == "[Get up]") UserCommand(iAuth, "stand", kAv, FALSE);
                    else if (sMessage == "☑ strict") UserCommand(iAuth, "allow stand",kAv, FALSE);
                    else if (sMessage == "☐ strict") UserCommand(iAuth, "forbid stand",kAv, FALSE);
                    else UserCommand(iAuth, "sit "+sMessage, kAv, FALSE);
                    UserCommand(iAuth, "menu force sit", kAv, TRUE);
                } else if (sMenu == "find") UserCommand(iAuth, "sit "+sMessage, kAv, FALSE);
                else if (sMenu == "terminal") {
                    if (llStringLength(sMessage) > 4) DoTerminalCommand(sMessage, kAv);
                    if (g_iMenuCommand) llMessageLinked(LINK_RLV, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
                } else if (sMenu == "folder" || sMenu == "multimatch") {
                    g_kMenuClicker = kAv;
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_RLV, iAuth, "menu "+COLLAR_PARENT_MENU, kAv);
                    else if (sMessage == BACKMENU) {
                        list lTempSplit = llParseString2List(g_sCurrentPath,["/"],[]);
                        lTempSplit = llList2List(lTempSplit,0,llGetListLength(lTempSplit) -2);
                        g_sCurrentPath = llDumpList2String(lTempSplit,"/") + "/";
                        llSetTimerEvent(g_iTimeOut);
                        g_iAuth = iAuth;
                        g_iListener = llListen(g_iFolderRLV, "", g_kWearer, "");
                        llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
                    } else if (sMessage == "WEAR") WearFolder(g_sCurrentPath);
                    else if (sMessage != "") {
                        g_sCurrentPath += sMessage + "/";
                        if (sMenu == "multimatch") g_sCurrentPath = sMessage + "/";
                        llSetTimerEvent(g_iTimeOut);
                        g_iAuth = iAuth;
                        g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
                        llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    listen(integer iChan, string sName, key kID, string sMsg) {

        llSetTimerEvent(0.0);

        if (iChan == g_iFolderRLV) {
            FolderMenu(g_kMenuClicker,g_iAuth,sMsg);
            g_iAuth = CMD_EVERYONE;
        }
        else if (iChan == g_iFolderRLVSearch) {
            if (sMsg == "") {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"That outfit couldn't be found in #RLV/"+g_sPathPrefix,kID);
            } else {
                if (llSubStringIndex(sMsg,",") < 0) {
                    g_sCurrentPath = sMsg;
                    WearFolder(g_sCurrentPath);

                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Loading outfit #RLV/"+sMsg,kID);
                } else {
                    string sPrompt = "\nPick one!";
                    list lFolderMatches = llParseString2List(sMsg,[","],[]);
                    Dialog(g_kMenuClicker, sPrompt, lFolderMatches, [UPMENU], 0, g_iAuth, "multimatch");
                    g_iAuth = CMD_EVERYONE;
                }
            }
        }
    }

    timer() {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) FailSafe();
    }


}
