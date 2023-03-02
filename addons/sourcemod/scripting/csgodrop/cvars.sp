enum struct Cvar {
    ConVar tag;
    ConVar drop_attempt_time;
    ConVar show_attempts;
    ConVar ignore_nonprime;
    ConVar kick_after_drop;
    ConVar show_hudtext;
    ConVar drop_sound;
    ConVar currency;
    ConVar log_file;
    ConVar discord_webhook;
    ConVar telegram_token;
    ConVar telegram_chat_id;
}

enum struct CvarChar {
    char tag[32];
    char discord_webhook[PLATFORM_MAX_PATH];
    char telegram_token[PLATFORM_MAX_PATH];
    char telegram_chat_id[32];
}

Cvar cvar;
CvarChar cvarchar;

void OnPluginStart_Cvars() {
    cvar.tag = CreateConVar("sm_csgo_drop_tag", "Drop", "Tag appearing at the beginning of the message for chat messages. Because adding them automaticly, do not use [] signs. If you do not want tag, leave it blank.");
    cvar.drop_attempt_time = CreateConVar("sm_csgo_drop_attempt_time", "180.0", "Sets how many seconds intervals it will attempt.");
    cvar.show_attempts = CreateConVar("sm_csgo_drop_show_attempts", "1", "Shows drop attempts in chat.", _, true, 0.0, true, 1.0);
    cvar.ignore_nonprime = CreateConVar("sm_csgo_drop_ignore_nonprime", "1", "Ignores no-prime players. If no-prime player drops an item, it will not show.", _, true, 0.0, true, 1.0);
    cvar.kick_after_drop = CreateConVar("sm_csgo_drop_kick_after_drop", "0", "Kicks the person from the server after dropping an item.", _, true, 0.0, true, 1.0);
    cvar.show_hudtext = CreateConVar("sm_csgo_drop_show_hudtext", "1", "Shows a hudtext after a person dropped an item.")
    cvar.drop_sound = CreateConVar("sm_csgo_drop_sound", "2", "Plays a sound when a player dropped an item [0- disabled. | 1-to client | 2-to everyone]", _, true, 0.0, true, 2.0);
    cvar.currency = CreateConVar("sm_csgo_drop_currency", "1", "Sets the currency of the price of item.");
    cvar.log_file = CreateConVar("sm_csgo_drop_log_file", "1", "Logs player name, item name and cost to a file when a player drops an item.", _, true, 0.0, true, 1.0);
    cvar.discord_webhook = CreateConVar("sm_csgo_drop_discord_webhook", "", "Discord webhook to send item infos to discord server.");
    cvar.telegram_token = CreateConVar("sm_csgo_drop_telegram_token", "", "Telegram token to to send item infos to telegram chat.");
    cvar.telegram_chat_id = CreateConVar("sm_csgo_drop_telegram_chat_id", "", "Telegram chat id to send item infos to telegram chat.");

    OnCvarChanged(cvar.tag, NULL_STRING, NULL_STRING);
    OnCvarChanged(cvar.drop_attempt_time, NULL_STRING, NULL_STRING);
    OnCvarChanged(cvar.discord_webhook, NULL_STRING, NULL_STRING);
    OnCvarChanged(cvar.telegram_token, NULL_STRING, NULL_STRING);
    OnCvarChanged(cvar.telegram_chat_id, NULL_STRING, NULL_STRING);

    cvar.tag.AddChangeHook(OnCvarChanged);
    cvar.drop_attempt_time.AddChangeHook(OnCvarChanged);
    cvar.discord_webhook.AddChangeHook(OnCvarChanged);
    cvar.telegram_token.AddChangeHook(OnCvarChanged);
    cvar.telegram_chat_id.AddChangeHook(OnCvarChanged);

    AutoExecConfig();
}

void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    if(convar == cvar.tag) {
        convar.GetString(cvarchar.tag, sizeof(cvarchar.tag));

        if(cvarchar.tag[0] != EOS) {
            Format(cvarchar.tag, sizeof(cvarchar.tag), "[%s]", cvarchar.tag);
        }
    }
    else if(convar == cvar.drop_attempt_time) {
        CreateAttemptTimer();
    }
    else if(convar == cvar.discord_webhook) {
        convar.GetString(cvarchar.discord_webhook, sizeof(cvarchar.discord_webhook));
    }
    else if(convar == cvar.telegram_token) {
        convar.GetString(cvarchar.telegram_token, sizeof(cvarchar.telegram_token));
    }
    else if(convar == cvar.telegram_chat_id) {
        convar.GetString(cvarchar.telegram_chat_id, sizeof(cvarchar.telegram_chat_id));
    }
}