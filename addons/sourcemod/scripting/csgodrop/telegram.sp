void SendTelegramInfo(int client, const char[] sItemName, const char[] sItemPrice) {
    if(cvarchar.telegram_token[0] == EOS) {
        return;
    }

    char temp[PLATFORM_MAX_PATH];

    FormatEx(temp, sizeof(temp), "%T", "Dropped an Item Telegram Text", LANG_SERVER, client, sItemName, sItemPrice);

    if(temp[0] != EOS) {
		char stemp[PLATFORM_MAX_PATH];
		FormatEx(stemp, sizeof(stemp), "https://api.telegram.org/bot%s/sendMessage?", cvarchar.telegram_token);

		Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, stemp);
		SteamWorks_SetHTTPRequestNetworkActivityTimeout(request, 10);

		SteamWorks_SetHTTPRequestGetOrPostParameter(request, "text", temp);
		SteamWorks_SetHTTPRequestGetOrPostParameter(request, "chat_id", cvarchar.telegram_chat_id);

		SteamWorks_SetHTTPRequestContextValue(request, 5);

		SteamWorks_SetHTTPCallbacks(request, HTTPRequest_Callback);

		bool bRequest = SteamWorks_SendHTTPRequest(request);

		if(!bRequest) {
			request.Close();
			return;
		}

		SteamWorks_PrioritizeHTTPRequest(request);
	}
}

void HTTPRequest_Callback(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode) {
	hRequest.Close();
}
