/*
dsc_dialog - 170509.0

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

This is an adaptation of Schmobag Hogfather's SchmoDialog script

*/

integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;






integer NOTIFY = 1002;
integer NOTIFY_OWNERS=1003;
integer SAY = 1004;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer REBOOT = -1000;
integer LOADPIN = -1904;
integer LM_SETTING_SAVE = 2000;

integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

















integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;


integer g_iPagesize = 12;
string MORE = "►";
string PREV = "◄";
string UPMENU = "BACK";


string BLANK = "-";
integer g_iTimeOut = 300;
integer g_iReapeat = 5;

list g_lMenus;




list g_lRemoteMenus;
integer g_iStrideLength = 12;


list MRSBUN = [];
string SPAMSWITCH = "verbose";

key g_kWearer;
string g_sSettingToken = "dialog_";
string g_sGlobalToken = "global_";
integer g_iListenChan=1;
string g_sPrefix;
string g_sDeviceType = "collar";
string g_sDeviceName;
string g_sWearerName;
list g_lOwners;

list g_lSensorDetails;
integer g_bSensorLock;
integer g_iSensorTimeout;
integer g_iSelectAviMenu;
integer g_iColorMenu;

list g_lColors = [
"Red",<1.00000, 0.00000, 0.00000>,
"Green",<0.00000, 1.00000, 0.00000>,
"Blue",<0.00000, 0.50196, 1.00000>,
"Yellow",<1.00000, 1.00000, 0.00000>,
"Pink",<1.00000, 0.50588, 0.62353>,
"Brown",<0.24314, 0.14902, 0.07059>,
"Purple",<0.62353, 0.29020, 0.71765>,
"Black",<0.00000, 0.00000, 0.00000>,
"White",<1.00000, 1.00000, 1.00000>,
"Barbie",<0.91373, 0.00000, 0.34510>,
"Orange",<0.96078, 0.60784, 0.00000>,
"Toad",<0.25098, 0.25098, 0.00000>,
"Khaki",<0.62745, 0.50196, 0.38824>,
"Pool",<0.14902, 0.88235, 0.94510>,
"Blood",<0.42353, 0.00000, 0.00000>,
"Gray",<0.70588, 0.70588, 0.70588>,
"Anthracite",<0.08627, 0.08627, 0.08627>,
"Midnight",<0.00000, 0.10588, 0.21176>
];

dequeueSensor() {


    list lParams = llParseStringKeepNulls(llList2String(g_lSensorDetails,2), ["|"], []);

    list lSensorInfo = llParseStringKeepNulls(llList2String(lParams, 3), ["`"], []);



    if (llList2Integer(lSensorInfo,2) == (integer)AGENT) g_iSelectAviMenu = TRUE;
    else g_iSelectAviMenu = FALSE;
    llSensor(llList2String(lSensorInfo,0),(key)llList2String(lSensorInfo,1),llList2Integer(lSensorInfo,2),llList2Float(lSensorInfo,3),llList2Float(lSensorInfo,4));
    g_iSensorTimeout=llGetUnixTime()+10;
    llSetTimerEvent(g_iReapeat);
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum == CMD_GROUP) return;
    list lParams = llParseString2List(llToLower(sStr), ["="], []);
    string sToken = llList2String(lParams, 0);
    string sValue = llList2String(lParams, 1);
    if (sToken == SPAMSWITCH) {
        integer i = llListFindList(MRSBUN, [kID]);
        if (sValue == "off") {
            if (~i) return;
            MRSBUN += [kID];
            Notify(kID,"Verbose Feature activated for you.",FALSE);
        } else if (~i) {
            MRSBUN = llDeleteSubList(MRSBUN, i, i);
            Notify(kID,"Verbose Feature de-activated for you.",FALSE);
        } else return;
        if (!llGetListLength(MRSBUN)) llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + SPAMSWITCH, "");
        else llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + SPAMSWITCH + "=" + llList2CSV(MRSBUN), "");
    }
}

string TruncateString(string sStr, integer iBytes) {
    sStr = llEscapeURL(sStr);
    integer j = 0;
    string sOut;
    integer l = llStringLength(sStr);
    for (; j < l; j++) {
        string c = llGetSubString(sStr, j, j);
        if (c == "%") {
            if (iBytes >= 2) {
                sOut += llGetSubString(sStr, j, j+2);
                j += 2;
                iBytes -= 2;
            }
        } else if (iBytes >= 1) {
            sOut += c;
            iBytes --;
        }
    }
    return llUnescapeURL(sOut);
}

string SubstitudeVars(string sMsg) {
        if (sMsg == "%NOACCESS%") return "Access denied.";
        if (~llSubStringIndex(sMsg, "%PREFIX%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, ["%PREFIX%"], []), g_sPrefix);
        if (~llSubStringIndex(sMsg, "%CHANNEL%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, ["%CHANNEL%"], []), (string)g_iListenChan);
        if (~llSubStringIndex(sMsg, "%DEVICETYPE%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, ["%DEVICETYPE%"], []), g_sDeviceType);
        if (~llSubStringIndex(sMsg, "%WEARERNAME%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, ["%WEARERNAME%"], []), g_sWearerName);
        return sMsg;
}

Say(string sMsg, integer iWhisper) {
    sMsg = SubstitudeVars(sMsg);
    string sObjectName = llGetObjectName();
    llSetObjectName("");
    if (iWhisper) llWhisper(0,"/me "+sMsg);
    else llSay(0, sMsg);
    llSetObjectName(sObjectName);
}

RemoveMenuStride(integer iIndex)  {



    integer iListener = llList2Integer(g_lMenus, iIndex + 2);
    llListenRemove(iListener);
    g_lMenus=llDeleteSubList(g_lMenus, iIndex, iIndex + g_iStrideLength - 1);
}

list PrettyButtons(list lOptions, list lUtilityButtons, list iPagebuttons) {
    list lSpacers;
    list lCombined = lOptions + lUtilityButtons + iPagebuttons;
    while (llGetListLength(lCombined) % 3 != 0 && llGetListLength(lCombined) < 12) {
        lSpacers += [BLANK];
        lCombined = lOptions + lSpacers + lUtilityButtons + iPagebuttons;
    }

    integer u = llListFindList(lCombined, [UPMENU]);
    if (u != -1) lCombined = llDeleteSubList(lCombined, u, u);

    list lOut = llList2List(lCombined, 9, 11);
    lOut += llList2List(lCombined, 6, 8);
    lOut += llList2List(lCombined, 3, 5);
    lOut += llList2List(lCombined, 0, 2);

    if (u != -1) lOut = llListInsertList(lOut, [UPMENU], 2);

    return lOut;
}

NotifyOwners(string sMsg, string comments) {
    integer n;
    integer iStop = llGetListLength(g_lOwners);
    for (; n < iStop; ++n) {
        key kAv = (key)llList2String(g_lOwners, n);
        if (comments=="ignoreNearby") {

            vector vOwnerPos = (vector)llList2String(llGetObjectDetails(kAv, [OBJECT_POS]), 0);
            if (vOwnerPos == ZERO_VECTOR || llVecDist(vOwnerPos, llGetPos()) > 20.0) {


                Notify(kAv, sMsg,FALSE);


            }
        } else {

            Notify(kAv, sMsg,FALSE);
        }
    }
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if ((key)kID){
        sMsg = SubstitudeVars(sMsg);
        string sObjectName = llGetObjectName();
        if (g_sDeviceName != sObjectName) llSetObjectName(g_sDeviceName);
        if (kID == g_kWearer) llOwnerSay(sMsg);
        else {
            if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
            else llInstantMessage(kID, sMsg);
            if (iAlsoNotifyWearer) llOwnerSay(sMsg);
        }
        llSetObjectName(sObjectName);
    }
}






string NameURI(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

integer GetStringBytes(string sStr) {
    sStr = llEscapeURL(sStr);
    integer l = llStringLength(sStr);
    list lAtoms = llParseStringKeepNulls(sStr, ["%"], []);
    return l - 2 * llGetListLength(lAtoms) + 2;
}

FailSafe(integer iSec) {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "dsc_dialog" || iSec)
        llRemoveInventory(sName);
}

Dialog(key kRecipient, string sPrompt, list lMenuItems, list lUtilityButtons, integer iPage, key kID, integer iWithNums, integer iAuth,string extraInfo)
{

    integer iNumitems = llGetListLength(lMenuItems);
    integer iStart = 0;
    integer iMyPageSize = g_iPagesize - llGetListLength(lUtilityButtons);
    if (g_iSelectAviMenu) {
        iMyPageSize = iMyPageSize-3;
        if (iNumitems == 8) iMyPageSize = iMyPageSize-1;

        else if (iNumitems == 7) iMyPageSize = iMyPageSize-2;
    }
    string sPagerPrompt;
    if (iNumitems > iMyPageSize) {
        iMyPageSize=iMyPageSize-2;

        integer numPages=(iNumitems-1)/iMyPageSize;
        if (iPage>numPages)iPage=0;
        else if (iPage<0) iPage=numPages;

        iStart = iPage * iMyPageSize;

        sPagerPrompt = sPagerPrompt + "\nPage "+(string)(iPage+1)+"/"+(string)(numPages+1);
    }
    integer iEnd = iStart + iMyPageSize - 1;
    if (iEnd >= iNumitems) iEnd = iNumitems - 1;
    integer iPagerPromptLen = GetStringBytes(sPagerPrompt);



    if (iWithNums == -1) {
        integer iNumButtons=llGetListLength(lMenuItems);
        iWithNums=llStringLength((string)iNumButtons);



        while (iNumButtons--) {
            if (GetStringBytes(llList2String(lMenuItems,iNumButtons))>18) {
                jump longButtonName;
            }
        }
        iWithNums=0;
        @longButtonName;
    }


    string sNumberedButtons;
    integer iNBPromptlen;
    list lButtons;
    if (iWithNums) {
        integer iCur;
        sNumberedButtons="\n";
        for (iCur = iStart; iCur <= iEnd; iCur++) {
            string sButton = llList2String(lMenuItems, iCur);
            if ((key)sButton) {

                if (g_iSelectAviMenu) sButton = NameURI((key)sButton);
                else if (llGetDisplayName((key)sButton)) sButton=llGetDisplayName((key)sButton);
                else sButton=llKey2Name((key)sButton);
            }

            string sButtonNumber = (string)iCur;

            while (llStringLength(sButtonNumber)<iWithNums)
               sButtonNumber = "0"+sButtonNumber;
            sButton=sButtonNumber + " " + sButton;


            sNumberedButtons+=sButton+"\n";
            sButton = TruncateString(sButton, 24);
            if(g_iSelectAviMenu) sButton = sButtonNumber;
            lButtons += [sButton];
        }
        iNBPromptlen=GetStringBytes(sNumberedButtons);
    } else if (iNumitems > iMyPageSize) lButtons = llList2List(lMenuItems, iStart, iEnd);
    else  lButtons = lMenuItems;

    sPrompt = SubstitudeVars(sPrompt);

    integer iPromptlen=GetStringBytes(sPrompt);
    string sThisPrompt;
    string sThisChat;
    if (iPromptlen + iNBPromptlen + iPagerPromptLen < 512)
        sThisPrompt = sPrompt + sNumberedButtons + sPagerPrompt ;
    else if (iPromptlen + iPagerPromptLen < 512) {
        if (iPromptlen + iPagerPromptLen < 459) {
            sThisPrompt = sPrompt + "\nPlease check nearby chat for button descriptions.\n" + sPagerPrompt;
        } else
            sThisPrompt = sPrompt + sPagerPrompt;
        sThisChat = sNumberedButtons;
    } else {
        sThisPrompt=TruncateString(sPrompt,510-iPagerPromptLen)+sPagerPrompt;
        sThisChat = sPrompt+sNumberedButtons;
    }


    if (! ~llListFindList(MRSBUN, [kRecipient])){
        integer iRemainingChatLen;
        while (iRemainingChatLen=llStringLength(sThisChat)){
            if(iRemainingChatLen<1015) {
                Notify(kRecipient,sThisChat,FALSE);
                sThisChat="";
            } else {
                string sMessageChunk=TruncateString(sPrompt,1015);
                Notify(kRecipient,sMessageChunk,FALSE);
                sThisChat=llGetSubString(sThisChat,llStringLength(sMessageChunk),-1);
            }
        }
    }

    integer iChan=llRound(llFrand(10000000)) + 100000;
    while (~llListFindList(g_lMenus, [iChan])) iChan=llRound(llFrand(10000000)) + 100000;
    integer iListener = llListen(iChan, "", kRecipient, "");

    llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);

    if (llGetListLength(lMenuItems+lUtilityButtons)){
        list lNavButtons;
        if (iNumitems > iMyPageSize) lNavButtons=[PREV,MORE];
        llDialog(kRecipient, sThisPrompt, PrettyButtons(lButtons, lUtilityButtons, lNavButtons), iChan);
    }
    else llTextBox(kRecipient, sThisPrompt, iChan);

    llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_HIGH,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.0]);

    llSetTimerEvent(g_iReapeat);
    integer ts = llGetUnixTime() + g_iTimeOut;


    g_lMenus += [iChan, kID, iListener, ts, kRecipient, sPrompt, llDumpList2String(lMenuItems, "|"), llDumpList2String(lUtilityButtons, "|"), iPage, iWithNums, iAuth,extraInfo];

}

ClearUser(key kRCPT) {

    integer iIndex = llListFindList(g_lMenus, [kRCPT]);
    while (~iIndex) {

        RemoveMenuStride(iIndex -4);

        iIndex = llListFindList(g_lMenus, [kRCPT]);
    }

}

CleanList() {



    integer iLength = llGetListLength(g_lMenus);
    integer n;
    integer iNow = llGetUnixTime();
    for (n = iLength - g_iStrideLength; n >= 0; n -= g_iStrideLength) {
        integer iDieTime = llList2Integer(g_lMenus, n + 3);

        if (iNow > iDieTime) {

            key kID = llList2Key(g_lMenus, n + 1);
            llMessageLinked(LINK_ALL_OTHERS, DIALOG_TIMEOUT, "", kID);
            RemoveMenuStride(n);
        }
    }
    if (g_iSensorTimeout>iNow){
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,3);
        if (llGetListLength(g_lSensorDetails)>0) dequeueSensor();
    }
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
        g_kWearer=llGetOwner();
        FailSafe(0);
        g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()), 0,1));
        g_sWearerName = NameURI(g_kWearer);
        g_sDeviceName = llList2String(llGetLinkPrimitiveParams(1,[PRIM_DESC]),0);
        if (g_sDeviceName == "" || g_sDeviceName =="(No Description)")
            g_sDeviceName = llList2String(llGetLinkPrimitiveParams(1,[PRIM_NAME]),0);
        llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_NAME,g_sDeviceName]);

    }

    sensor(integer num_detected){

        list lSensorInfo=llList2List(g_lSensorDetails,0,3);
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,3);

        list lParams=llParseStringKeepNulls(llList2String(lSensorInfo,2), ["|"], []);
        list lButtons = llParseStringKeepNulls(llList2String(lParams, 3), ["`"], []);



        string sFind=llList2String(lButtons,5);

        integer bReturnFirstMatch=llList2Integer(lButtons,6);
        lButtons=[];
        integer i;
        for (; i<num_detected;i++){
            lButtons += llDetectedKey(i);
            if (bReturnFirstMatch || (sFind != "")) {
                if (llSubStringIndex(llToLower(llDetectedName(i)),llToLower(sFind))==0
                    || llSubStringIndex(llToLower(llGetDisplayName(llDetectedKey(i))),llToLower(sFind))==0 ){
                    if (!bReturnFirstMatch) {
                        lButtons = [llDetectedKey(i)];
                        jump next;
                    }
                    llMessageLinked(LINK_ALL_OTHERS, DIALOG_RESPONSE, llList2String(lParams,0) + "|" + (string)llDetectedKey(i)+ "|0|" + llList2String(lParams,5), (key)llList2String(lSensorInfo,3));

                    if (llGetListLength(g_lSensorDetails) > 0)
                        dequeueSensor();
                    else g_bSensorLock=FALSE;
                    g_iSelectAviMenu = FALSE;
                    return;
                }

            }
        }
        @next;

        string sButtons=llDumpList2String(lButtons,"`");
        lParams=llListReplaceList(lParams,[sButtons],3,3);

        llMessageLinked(LINK_THIS,DIALOG,llDumpList2String(lParams,"|"),(key)llList2String(lSensorInfo,3));

        if (llGetListLength(g_lSensorDetails) > 0)
            dequeueSensor();
        else g_bSensorLock=FALSE;
    }

    no_sensor() {
        list lSensorInfo=llList2List(g_lSensorDetails,0,3);
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,3);

        list lParams=llParseStringKeepNulls(llList2String(lSensorInfo,2), ["|"], []);
        lParams=llListReplaceList(lParams,[""],3,3);

        llMessageLinked(LINK_THIS,DIALOG,llDumpList2String(lParams,"|"),(key)llList2String(lSensorInfo,3));

        if (llGetListLength(g_lSensorDetails) > 0)
            dequeueSensor();
        else {
            g_iSelectAviMenu = FALSE;
            g_bSensorLock=FALSE;
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == SENSORDIALOG){





            g_lSensorDetails+=[iSender, iNum, sStr, kID];
            if (! g_bSensorLock){
                g_bSensorLock=TRUE;
                dequeueSensor();
            }
        } else if (iNum == DIALOG) {



            if (iSender != llGetLinkNumber()) g_iSelectAviMenu = FALSE;
            list lParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kRCPT = llGetOwnerKey((key)llList2String(lParams, 0));
            integer iIndex = llListFindList(g_lRemoteMenus, [kRCPT]);
            if (~iIndex) {
                if (llKey2Name(kRCPT)=="") {
                    llHTTPRequest(llList2String(g_lRemoteMenus, iIndex+1), [HTTP_METHOD, "POST"], sStr+"|"+(string)kID);
                    return;
                } else g_lRemoteMenus = llListReplaceList(g_lRemoteMenus, [], iIndex, iIndex+1);
            }
            string sPrompt = llList2String(lParams, 1);
            integer iPage = (integer)llList2String(lParams, 2);
            if (iPage < 0 ) {
                g_iSelectAviMenu = TRUE;
                iPage = 0;
            }
            list lButtons = llParseString2List(llList2String(lParams, 3), ["`"], []);
            if (llList2String(lButtons,0) == "colormenu please") {
                lButtons = llList2ListStrided(g_lColors,0,-1,2);
                g_iColorMenu = TRUE;
            }
            integer iDigits=-1;
            list ubuttons = llParseString2List(llList2String(lParams, 4), ["`"], []);
            integer iAuth = CMD_ZERO;
            if (llGetListLength(lParams)>=6) iAuth = llList2Integer(lParams, 5);

            ClearUser(kRCPT);
            Dialog(kRCPT, sPrompt, lButtons, ubuttons, iPage, kID, iDigits, iAuth,"");
        }
        else if (llGetSubString(sStr, 0, 10) == "remotemenu:") {
            if (iNum == CMD_OWNER || iNum == CMD_TRUSTED) {
                string sCmd = llGetSubString(sStr, 11, -1);

                if (llGetSubString(sCmd, 0, 3) == "url:") {
                    integer iIndex = llListFindList(g_lRemoteMenus, [kID]);
                    if (~iIndex)
                        g_lRemoteMenus = llListReplaceList(g_lRemoteMenus, [kID, llGetSubString(sCmd, 4, -1)], iIndex, iIndex+1);
                    else
                        g_lRemoteMenus += [kID, llGetSubString(sCmd, 4, -1)];
                    llMessageLinked(LINK_ALL_OTHERS, iNum, "menu", kID);
                } else if (llGetSubString(sCmd, 0, 2) == "off") {
                    integer iIndex = llListFindList(g_lRemoteMenus, [kID]);
                    if (~iIndex)
                        g_lRemoteMenus = llListReplaceList(g_lRemoteMenus, [], iIndex, iIndex+1);
                }
                else if (llGetSubString(sCmd, 0, 8) == "response:") {
                    list lParams = llParseString2List(llGetSubString(sCmd, 9, -1), ["|"], []);

                    llMessageLinked(LINK_ALL_OTHERS, DIALOG_RESPONSE, llList2String(lParams, 0) + "|" + llList2String(lParams, 1) + "|" + llList2String(lParams, 2), llList2String(lParams, 3));
                } else if (llGetSubString(sCmd, 0, 7) == "timeout:")
                    llMessageLinked(LINK_ALL_OTHERS, DIALOG_TIMEOUT, "", llGetSubString(sCmd, 8, -1));
            }
        }
        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sSettingToken + SPAMSWITCH) MRSBUN = llParseString2List(sValue, [","], []);
            else if (sToken == g_sGlobalToken+"DeviceType") g_sDeviceType = sValue;
            else if (sToken == g_sGlobalToken+"DeviceName") {
                g_sDeviceName = sValue;
                llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_NAME,g_sDeviceName]);
            } else if (sToken == g_sGlobalToken+"WearerName") {
                if (llSubStringIndex(sValue, "secondlife:///app/agent"))
                    g_sWearerName =  "["+NameURI(g_kWearer)+" " + sValue + "]";
                else g_sWearerName = sValue;
            } else if (sToken == g_sGlobalToken+"prefix"){
                if (sValue != "") g_sPrefix=sValue;
            } else if (sToken == g_sGlobalToken+"channel") g_iListenChan = (integer)sValue;
            else if (sToken == "auth_owner")
                g_lOwners = llParseString2List(sValue, [","], []);
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if (iNum == NOTIFY)    Notify(kID,llGetSubString(sStr,1,-1),(integer)llGetSubString(sStr,0,0));
        else if (iNum == SAY)         Say(llGetSubString(sStr,1,-1),(integer)llGetSubString(sStr,0,0));
        else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
            else if (sStr == "LINK_REQUEST") llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_DIALOG","");
        } else if (iNum==NOTIFY_OWNERS) NotifyOwners(sStr,(string)kID);
        else if (iNum == 451 && kID == "sec") FailSafe(1);
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    listen(integer iChan, string sName, key kID, string sMessage) {
        integer iMenuIndex = llListFindList(g_lMenus, [iChan]);
        if (~iMenuIndex) {
            key kMenuID = llList2Key(g_lMenus, iMenuIndex + 1);
            key kAv = llList2Key(g_lMenus, iMenuIndex + 4);
            string sPrompt = llList2String(g_lMenus, iMenuIndex + 5);

            list items = llParseString2List(llList2String(g_lMenus, iMenuIndex + 6), ["|"], []);
            list ubuttons = llParseString2List(llList2String(g_lMenus, iMenuIndex + 7), ["|"], []);
            integer iPage = llList2Integer(g_lMenus, iMenuIndex + 8);
            integer iDigits = llList2Integer(g_lMenus, iMenuIndex + 9);
            integer iAuth = llList2Integer(g_lMenus, iMenuIndex + 10);
            string sExtraInfo = llList2String(g_lMenus, iMenuIndex + 11);

            RemoveMenuStride(iMenuIndex);

            if (sMessage == MORE) Dialog(kID, sPrompt, items, ubuttons, ++iPage, kMenuID, iDigits, iAuth,sExtraInfo);
            else if (sMessage == PREV) Dialog(kID, sPrompt, items, ubuttons, --iPage, kMenuID, iDigits, iAuth, sExtraInfo);
            else if (sMessage == BLANK) Dialog(kID, sPrompt, items, ubuttons, iPage, kMenuID, iDigits, iAuth, sExtraInfo);
            else {
                g_iSelectAviMenu = FALSE;
                string sAnswer;
                integer iIndex = llListFindList(ubuttons, [sMessage]);
                if (iDigits && !~iIndex) {
                    integer iBIndex = (integer) llGetSubString(sMessage, 0, iDigits);
                    sAnswer = llList2String(items, iBIndex);
                } else if (g_iColorMenu) {
                    integer iColorIndex  =llListFindList(llList2ListStrided(g_lColors,0,-1,2),[sMessage]);
                    if (~iColorIndex) sAnswer = llList2String(llList2ListStrided(llDeleteSubList(g_lColors,0,0),0,-1,2),iColorIndex);
                    else sAnswer = sMessage;
                    g_iColorMenu = FALSE;
                } else sAnswer = sMessage;
                if (sAnswer == "") sAnswer = " ";
                llMessageLinked(LINK_ALL_OTHERS, DIALOG_RESPONSE, (string)kAv + "|" + sAnswer + "|" + (string)iPage + "|" + (string)iAuth, kMenuID);
            }
        }
    }

    timer() {
        CleanList();

        if (!llGetListLength(g_lMenus) && !llGetListLength(g_lSensorDetails)) {

            g_iSelectAviMenu = FALSE;
            llSetTimerEvent(0.0);
        }
    }

    changed(integer iChange){
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) FailSafe(0);


    }
}
