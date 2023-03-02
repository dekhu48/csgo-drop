void SendDiscordInfo(int client, char[] sItemName, int maxlen, const char[] sImageUrl, const char[] sItemPrice) {
    if(cvarchar.discord_webhook[0] == EOS) {
        return;
    }

    char temp[PLATFORM_MAX_PATH], temp2[PLATFORM_MAX_PATH];

    DiscordWebHook hook = new DiscordWebHook(cvarchar.discord_webhook);
    hook.SlackMode = true;

    MessageEmbed embed = new MessageEmbed();
    embed.SetThumb(sImageUrl);

    static const char hexchar[] = "0123456789ABCDEF";

    FormatEx(temp2, sizeof(temp2), "#%c%c%c%c%c%c",  hexchar[GetRandomInt(0,15)],  hexchar[GetRandomInt(0,15)], hexchar[GetRandomInt(0,15)], hexchar[GetRandomInt(0,15)], hexchar[GetRandomInt(0,15)], hexchar[GetRandomInt(0,15)]);
    embed.SetColor(temp2);

    FormatEx(temp, sizeof(temp), "%T", "Discord Embed Title", LANG_SERVER);

    if(temp[0] != EOS) {
        embed.SetTitle(temp);
    }

    FormatEx(temp, sizeof(temp), "%T", "Discord Embed Field Hostname Title", LANG_SERVER);

    if(temp[0] != EOS) {
        int longIp, iPort, pieces[4];
        char hostname[PLATFORM_MAX_PATH], netIp[16];

        FindConVar("hostname").GetString(hostname, sizeof(hostname));
        longIp = FindConVar("hostip").IntValue;
        iPort = FindConVar("hostport").IntValue;

        pieces[0] = (longIp >> 24) & 0x000000FF;
        pieces[1] = (longIp >> 16) & 0x000000FF;
        pieces[2] = (longIp >> 8) & 0x000000FF;
        pieces[3] = longIp & 0x000000FF;

        FormatEx(netIp, sizeof(netIp), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
        FormatEx(temp2, sizeof(temp2), "%T", "Discord Embed Field Hostname Content", LANG_SERVER, hostname, netIp, iPort);
        embed.AddField(temp, temp2, false);
    }

    FormatEx(temp, sizeof(temp), "%T", "Discord Embed Field Player Info Title", LANG_SERVER);

    if(temp[0] != EOS) {
        char sSteamId[32],  sSteamId64[32], sName[(MAX_NAME_LENGTH + 1) * 2];

        GetClientName(client, sName, sizeof(sName));
        GetClientAuthId(client, AuthId_Steam2, sSteamId, sizeof(sSteamId));
        GetClientAuthId(client, AuthId_SteamID64, sSteamId64, sizeof(sSteamId64));

        FormatEx(temp2, sizeof(temp2), "%T", "Discord Embed Field Player Info Content", LANG_SERVER, sName, sSteamId, sSteamId64, sSteamId64);
        embed.AddField(temp, temp2, false);
    }

    if(sItemName[0] != EOS) {
        FormatEx(temp, sizeof(temp), "%T", "Discord Embed Field Item Info Title", LANG_SERVER);

        if(temp[0] != EOS) {
            char sItemNameTemp[PLATFORM_MAX_PATH];

            strcopy(sItemNameTemp, sizeof(sItemNameTemp), sItemName);
            ReplaceString(sItemNameTemp, maxlen, " ", "%20");

            FormatEx(temp2, sizeof(temp2), "%T", "Discord Embed Field Item Name", LANG_SERVER, sItemName, sItemNameTemp);
            embed.AddField(temp, temp2, false);
        }
    }

    FormatEx(temp, sizeof(temp), "%T", "Discord Embed Field Price Info Title", LANG_SERVER);

    if(temp[0] != EOS) {
        embed.AddField(temp, sItemPrice, false);
    }

    FormatTime(temp2, sizeof(temp2), "%d.%m.%Y %X", GetTime());
    FormatEx(temp, sizeof(temp), "%T", "Discord Embed Footer", LANG_SERVER, cvarchar.tag, temp2);

    if(temp[0] != EOS) {
        embed.SetFooter(temp);
    }

    hook.Embed(embed);
    hook.Send();
    delete hook;
}