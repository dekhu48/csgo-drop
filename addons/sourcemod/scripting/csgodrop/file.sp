char g_sFileName[PLATFORM_MAX_PATH];

void OnPluginStart_File() {
    BuildPath(Path_SM, g_sFileName, sizeof(g_sFileName), "logs/csgo-drop/");

    if(!DirExists(g_sFileName)) {
        CreateDirectory(g_sFileName, 511);
    }
}

void SendFileInfo(int client, const char[] sItemName, const char[] sItemPrice) {
    if(!cvar.log_file.BoolValue) {
        return;
    }

    char filename[PLATFORM_MAX_PATH];
    strcopy(filename, sizeof(filename), g_sFileName);

    char date[15];
    FormatTime(date, sizeof(date), "%d.%m.%Y.cfg", GetTime());

    char authid[MAX_AUTHID_LENGTH];
    GetClientAuthId(client, AuthId_Steam2, authid, sizeof(authid));

    StrCat(filename, sizeof(filename), date);

    File file = OpenFile(filename, "at");
    file.WriteLine("%T", "Dropped an Item File Text", LANG_SERVER, authid, client, sItemName, sItemPrice);
    delete file;
}