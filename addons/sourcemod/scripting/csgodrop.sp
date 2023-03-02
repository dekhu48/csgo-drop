#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <ripext>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <discord>
#include <SteamWorks>

#pragma newdecls required

public Plugin myinfo = {
	name = "CSGO Drop",
	author = "schwarper",
	description = "CSGO Drop",
	version = "0.0.3",
	url = "https://steamcommunity.com/id/schwarper & schwarper#9569"
};

enum struct CSGODrop {
	Address aDropForAllPlayersPatch;
	Handle hMatchEndDrop;
	Handle hAttemptTimer;
	Handle hDropFailedTimer;
	int iOffset;
}

CSGODrop g_eCSGODrop;

#include "csgodrop/cvars.sp"
#include "csgodrop/keyvalues.sp"
#include "csgodrop/discord.sp"
#include "csgodrop/telegram.sp"
#include "csgodrop/file.sp"

public void OnPluginStart() {
	OnPluginStart_Cvars();
	OnPluginStart_File();

	LoadTranslations("csgodrop.phrases");
	LoadGameData();
}

public void OnPluginEnd() {
	if(g_eCSGODrop.aDropForAllPlayersPatch != Address_Null) {
		StoreToAddress(g_eCSGODrop.aDropForAllPlayersPatch, 0x01, NumberType_Int8);
	}
}

public void OnMapStart() {
	PrecacheSound("ui/panorama/case_awarded_1_uncommon_01.wav");
}

void CreateAttemptTimer() {
	if(g_eCSGODrop.hAttemptTimer != null) {
		delete g_eCSGODrop.hAttemptTimer;
	}

	if(g_eCSGODrop.aDropForAllPlayersPatch != Address_Null && cvar.drop_attempt_time.FloatValue) {
		g_eCSGODrop.hAttemptTimer = CreateTimer(cvar.drop_attempt_time.FloatValue, Timer_Attempt, _, TIMER_REPEAT);
	}
}

Action Timer_Attempt(Handle timer) {
	if(cvar.show_attempts.BoolValue) {
		g_eCSGODrop.hDropFailedTimer = CreateTimer(1.2, Timer_AttemptFailed);
		ChatAll("%t", "Trying Drop");
	}

	if(g_eCSGODrop.iOffset == 1) {
		SDKCall(g_eCSGODrop.hMatchEndDrop, 0xDEADC0DE, false);
	}
	else {
		SDKCall(g_eCSGODrop.hMatchEndDrop, false);
	}

	return Plugin_Continue;
}

Action Timer_AttemptFailed(Handle timer) {
	g_eCSGODrop.hDropFailedTimer = null;
	ChatAll("%t", "Drop Attempt Failed");

	return Plugin_Continue;
}

void LoadGameData() {
	GameData gGameData;

	if((gGameData = LoadGameConfigFile("csgodrop")) == INVALID_HANDLE) {
		SetFailState("%T", "Error GameData", LANG_SERVER);
		return;
	}

	if((g_eCSGODrop.iOffset = gGameData.GetOffset("OS")) == -1) {
		SetFailState("%T", "Error OS", LANG_SERVER);
		return;
	}

	StartPrepSDKCall(g_eCSGODrop.iOffset == 1 ? SDKCall_Raw : SDKCall_Static);
	PrepSDKCall_SetFromConf(gGameData, SDKConf_Signature, "CCSGameRules::RewardMatchEndDrops");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);

	if((g_eCSGODrop.hMatchEndDrop = EndPrepSDKCall()) == INVALID_HANDLE) {
		SetFailState("%T", "Error RewardMatchEndDrops", LANG_SERVER);
		return;
	}

	DynamicDetour dRecordPlayerItemDrop;

	if((dRecordPlayerItemDrop = DynamicDetour.FromConf(gGameData, "CCSGameRules::RecordPlayerItemDrop")) == null) {
		SetFailState("%T", "Error RecordPlayerItemDrop", LANG_SERVER);
		return;
	}

	if((dRecordPlayerItemDrop.Enable(Hook_Post, DynamicDetour_RecordPlayerItemDrop)) == false) {
		SetFailState("%T", "Error RecordPlayerItemDrop Enable", LANG_SERVER);
		return;
	}

	if((g_eCSGODrop.aDropForAllPlayersPatch = gGameData.GetAddress("DropForAllPlayersPatch")) == Address_Null) {
		SetFailState("%T", "Error DropForAllPlayersPatch Address", LANG_SERVER);
		return;
	}

	if((LoadFromAddress(g_eCSGODrop.aDropForAllPlayersPatch, NumberType_Int32) & 0xFFFFFF) == 0x1F883) {
		g_eCSGODrop.aDropForAllPlayersPatch += view_as<Address>(2);
		StoreToAddress(g_eCSGODrop.aDropForAllPlayersPatch, 0xFF, NumberType_Int8);
	}
	else {
		g_eCSGODrop.aDropForAllPlayersPatch = Address_Null;
		SetFailState("%T", "Error DropForAllPlayersPatch Load", LANG_SERVER);
		return;
	}
}

MRESReturn DynamicDetour_RecordPlayerItemDrop(DHookParam hParams) {
	if(g_eCSGODrop.hDropFailedTimer != null) {
		delete g_eCSGODrop.hDropFailedTimer;
	}

	int client;
	int accountId = hParams.GetObjectVar(1, 16, ObjectValueType_Int);

	if((client = GetClientFromAccountId(accountId)) == -1) {
		return MRES_Ignored;
	}

	if(cvar.ignore_nonprime.BoolValue && !IsClientPrime(client)) {
		return MRES_Ignored;
	}

	int defIndex = hParams.GetObjectVar(1, 20, ObjectValueType_Int);
	int paintIndex = hParams.GetObjectVar(1, 24, ObjectValueType_Int);
	int rarity = hParams.GetObjectVar(1, 28, ObjectValueType_Int);
	int quality = hParams.GetObjectVar(1, 32, ObjectValueType_Int);

	char sItemName[PLATFORM_MAX_PATH], sImageUrl[PLATFORM_MAX_PATH];

	if(ReadKeyValues(defIndex, sItemName, sizeof(sItemName), sImageUrl, sizeof(sImageUrl))) {
		DataPack pack = new DataPack();
		pack.WriteCell(client);
		pack.WriteString(sItemName);
		pack.WriteString(sImageUrl);

		HTTPRequest request = new HTTPRequest("https://steamcommunity.com/market/priceoverview");
		request.AppendQueryParam("appid", "%d", 730);
		request.AppendQueryParam("currency", "%d", cvar.currency.IntValue);
		request.AppendQueryParam("market_hash_name", "%s", sItemName);
		request.Get(Https_DropPrice, pack);
	}
	else {
		FormatEx(sItemName, sizeof(sItemName), "%T", "Unknown Item", LANG_SERVER);
		SendDropInfo(client, sItemName, sizeof(sItemName), sImageUrl, "-");
	}

	Protobuf hSendPlayerItemFound = view_as<Protobuf>(StartMessageAll("SendPlayerItemFound", USERMSG_RELIABLE));
	hSendPlayerItemFound.SetInt("entindex", client);

	Protobuf hIteminfo = hSendPlayerItemFound.ReadMessage("iteminfo");
	hIteminfo.SetInt("defindex", defIndex);
	hIteminfo.SetInt("paintindex", paintIndex);
	hIteminfo.SetInt("rarity", rarity);
	hIteminfo.SetInt("quality", quality);
	hIteminfo.SetInt("inventory", 6);
	EndMessage();

	if(cvar.kick_after_drop.BoolValue) {
		KickClient(client, "%t", "Dropped an Item Kick Reason");
		return MRES_Ignored;
	}

	if(cvar.show_hudtext.BoolValue) {
		SetHudTextParams(-1.0, 0.4, 3.0, 0, 255, 255, 255);
		ShowHudText(client, -1, "%t", "Dropped an Item HudText", cvarchar.tag);
	}

	int drop_sound = cvar.drop_sound.IntValue;

	switch(drop_sound) {
		case 2: {
			EmitSoundToAll("ui/panorama/case_awarded_1_uncommon_01.wav", SOUND_FROM_LOCAL_PLAYER, _, SNDLEVEL_NONE);
		}
		case 1: {
			EmitSoundToClient(client, "ui/panorama/case_awarded_1_uncommon_01.wav", SOUND_FROM_LOCAL_PLAYER, _, SNDLEVEL_NONE);
		}
	}

	return MRES_Ignored;
}

void Https_DropPrice(HTTPResponse response, DataPack pack) {
	char itemprice[32], itemname[PLATFORM_MAX_PATH], imageurl[PLATFORM_MAX_PATH];

	pack.Reset();

	int client = pack.ReadCell();
	pack.ReadString(itemname, sizeof(itemname));
	pack.ReadString(imageurl, sizeof(imageurl));

	if(response.Status == HTTPStatus_OK && response.Data != null) {
		JSONObject data = view_as<JSONObject>(response.Data);
		data.GetString("median_price", itemprice, sizeof(itemprice));
		delete data;
	}

	if(itemprice[0] == EOS) {
		FormatEx(itemprice, sizeof(itemprice), "-");
	}

	SendDropInfo(client, itemname, sizeof(itemname), imageurl, itemprice);
}

void SendDropInfo(int client, char[] sItemName, int maxlen, const char[] sImageUrl, const char[] sItemPrice) {
	if(!IsClientInGame(client)) {
		return;
	}

	SendFileInfo(client, sItemName, sItemPrice);
	SendDiscordInfo(client, sItemName, maxlen, sImageUrl, sItemPrice);
	SendTelegramInfo(client, sItemName, sItemPrice);

	ChatAll("%t", "Dropped an Item Text", client, sItemName, sItemPrice);
}

int GetClientFromAccountId(int accountId) {
	for(int client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && !IsFakeClient(client) && GetSteamAccountID(client) == accountId) {
			return client;
		}
	}

	return -1;
}

bool IsClientPrime(int client) {
	if(IsFakeClient(client)) {
		return false;
	}

	if(k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, 624820)) {
		return false;
	}

	return true;
}

void ChatAll(const char[] format, any ...) {
	int len = strlen(format) + 255;
	char[] message = new char[len];

	VFormat(message, len, format, 2);
	Format(message, len, "\x01 \x02%s \x01%s", cvarchar.tag, message);
	ReplaceTextColors(message, len);

	PrintToChatAll(message);
}

void ReplaceTextColors(char[] sBuffer, int iBuffer) {
	ReplaceString(sBuffer, iBuffer, "{default}", "\x01");
	ReplaceString(sBuffer, iBuffer, "{white}", "\x01");
	ReplaceString(sBuffer, iBuffer, "{red}", "\x07");
	ReplaceString(sBuffer, iBuffer, "{lightred}", "\x0F");
	ReplaceString(sBuffer, iBuffer, "{darkred}", "\x02");
	ReplaceString(sBuffer, iBuffer, "{lightblue}", "\x0A");
	ReplaceString(sBuffer, iBuffer, "{blue}", "\x0B");
	ReplaceString(sBuffer, iBuffer, "{darkblue}", "\x0C");
	ReplaceString(sBuffer, iBuffer, "{purple}", "\x03");
	ReplaceString(sBuffer, iBuffer, "{orchid}", "\x0E");
	ReplaceString(sBuffer, iBuffer, "{yellow}", "\x09");
	ReplaceString(sBuffer, iBuffer, "{orange}", "\x09");
	ReplaceString(sBuffer, iBuffer, "{gold}", "\x10");
	ReplaceString(sBuffer, iBuffer, "{lightgreen}", "\x05");
	ReplaceString(sBuffer, iBuffer, "{green}", "\x04");
	ReplaceString(sBuffer, iBuffer, "{lime}", "\x06");
	ReplaceString(sBuffer, iBuffer, "{grey}", "\x08");
}