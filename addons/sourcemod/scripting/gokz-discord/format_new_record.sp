static char sServerName[256];
static char sMapName[32];

void UpdateVariables()
{
    GetConVarString(FindConVar("hostname"), sServerName, sizeof(sServerName));
    GetCurrentMapDisplayName(sMapName, sizeof(sMapName));
}

static char[] mapSuffix(int mode)
{
    char res[64] = "";
    if (!strcmp(gC_ModeNames[mode], "kztimer", false))
    {
        Format(res, sizeof(res), "?mode=kz_timer");
        return res;
    }
    if (!strcmp(gC_ModeNames[mode], "simplekz", false))
    {
        Format(res, sizeof(res), "?mode=kz_simple");
        return res;
    }
    if (!strcmp(gC_ModeNames[mode], "vanilla", false))
    {
        Format(res, sizeof(res), "?mode=kz_vanilla");
        return res;
    } 
    return res;
}
static Handle serverField()
{
    char result[256];
    Format(result, sizeof(result), "A new record has been set in %s!", sServerName);
    return json_string(result);
}
static Handle thumbnail()
{
    Handle result = json_object();
    char url[128];
    Format(url,sizeof(url), "https://github.com/KZGlobalTeam/map-images/raw/public/thumbnails/%s.jpg", sMapName);
    json_object_set_new(result, "url", json_string(url));
    return result;
}
static Handle playerField(int client)
{
    Handle result = json_object();
    json_object_set_new(result, "name", json_string("Player"));

    static char username[32];
    GetClientName(client, username, sizeof(username));

    static char userSteamID[128];
    GetClientAuthId(client, AuthId_SteamID64, userSteamID, sizeof(userSteamID));
    Format(userSteamID, sizeof(userSteamID), "https://steamcommunity.com/profiles/%s", userSteamID);

    static char value[256];
    Format(value, sizeof(value), "[%s](%s)", username, userSteamID);

    json_object_set_new(result, "value", json_string(value));
    
    json_object_set_new(result, "inline", json_boolean(true));
    return result;
}
static Handle mapField(int mode)
{
    Handle result = json_object();
    json_object_set_new(result, "name", json_string("Map"));
    
    static char mapURL[128];
    Format(mapURL, sizeof(mapURL), "http://kzstats.com/maps/%s%s", sMapName, mapSuffix(mode)); // Lazy hardcoding, no bonus support yet

    static char value[256];
    Format(value, sizeof(value), "[%s](%s)", sMapName, mapURL);
    json_object_set_new(result, "value", json_string(value));

    json_object_set_new(result, "inline", json_boolean(true));

    return result;
}
static Handle courseField(int course)
{
    Handle result = json_object();

    json_object_set_new(result, "name", json_string("Course"));
    if (course == 0){
        json_object_set_new(result, "value", json_string("Main"));
    }
    else
    {
        static char sCourse[16];
        Format(sCourse, sizeof(sCourse), "Bonus %i", course);
        json_object_set_new(result, "value", json_string(sCourse));
    }
    json_object_set_new(result, "inline", json_boolean(true));
    return result;
}
static Handle runtypeField(int mode, int style)
{
    Handle result = json_object();
    json_object_set_new(result, "name", json_string("Run Type"));
    
    char value[64];
    Format(value, sizeof(value), "%s, %s", gC_ModeNames[mode], gC_StyleNames[style]);
    json_object_set_new(result, "value", json_string(value));

    json_object_set_new(result, "inline", json_boolean(true));
    return result;
}
static Handle runtimeField(float runTime)
{
    Handle result = json_object();
    json_object_set_new(result, "name", json_string("Time"));
    char value[12];
    value = GOKZ_FormatTime(runTime);
    json_object_set_new(result, "value", json_string(value));
    json_object_set_new(result, "inline", json_boolean(true));
    return result;
}
static Handle teleportsField(int teleports)
{
    Handle result = json_object();
    json_object_set_new(result, "name", json_string("Teleports"));
    json_object_set_new(result, "value", json_integer(teleports));
    json_object_set_new(result, "inline", json_boolean(true));
    return result;
}
void DiscordFormatNewTime(char[] message, 
    int mSize,
    int client, 
	int course, 
	int mode, 
	int style, 
	float runTime, 
	int teleports
	)
{
    Handle h_obj = json_object();
    Handle h_embeds = json_array();
    Handle h_embed = json_object();
    Handle h_fields = json_array();

    json_object_set_new(h_obj, "content", serverField());
    // Colors
    json_object_set_new(h_embed, "color", json_integer(11645416));

    // Thumbnails
    json_object_set_new(h_embed, "thumbnail", thumbnail())
    // Fields
    json_array_append_new(h_fields, playerField(client));
    json_array_append_new(h_fields, mapField(mode));
    json_array_append_new(h_fields, courseField(course));
    json_array_append_new(h_fields, runtypeField(mode, style));
    json_array_append_new(h_fields, runtimeField(runTime));
    json_array_append_new(h_fields, teleportsField(teleports));
    
    

    // Insert fields to response
    json_object_set_new(h_embed, "fields", h_fields);
    json_array_append_new(h_embeds, h_embed);
    json_object_set_new(h_obj, "embeds", h_embeds);

    json_dump(h_obj, message, mSize);
    CloseHandle(h_obj);
}
