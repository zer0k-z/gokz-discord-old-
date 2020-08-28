static ArrayList aMsg = null;
static ArrayList aWebhook = null;
static Handle hTimer = null;
static bool bSending;
static bool bSlowdown;

// Webhook fetching
bool GetWebHook(const char[] sWebhook, char[] sUrl, int iLength)
{
	KeyValues kv = new KeyValues("Discord");
	
	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/gokz-discord.cfg");

	if (!FileExists(sFile))
	{
		SetFailState("[GetWebHook] \"%s\" not found!", sFile);
		return false;
	}

	kv.ImportFromFile(sFile);

	if (!kv.GotoFirstSubKey())
	{
		SetFailState("[GetWebHook] Can't find webhook for \"%s\"!", sFile);
		return false;
	}
	
	char sBuffer[64];
	
	do
	{
		kv.GetSectionName(sBuffer, sizeof(sBuffer));
		
		if(StrEqual(sBuffer, sWebhook, false))
		{
			kv.GetString("url", sUrl, iLength);
			delete kv;
			return true;
		}
	}
	while (kv.GotoNextKey());
	
	delete kv;
	
	return false;
}

// Storing and bSending functions
void DiscordSendMessage(char sMessage[16384])
{
	char sUrl[512];
	if(!GetWebHook("Webhook", sUrl, sizeof(sUrl)))
	{
		LogError("Error: Webhook: %s - Url: %s", "Webhook", sUrl);
		return;
	}   
	char sWebhook[64];
	
	Format(sWebhook,sizeof(sWebhook),"Webhook");
	StoreMsg(sWebhook, sMessage);

}


void StoreMsg(char sWebhook[64], char sMessage[16384])
{
	char sUrl[512];
	if(!GetWebHook(sWebhook, sUrl, sizeof(sUrl)))
	{
		LogError("Webhook config not found or invalid! Webhook: %s Url: %s", sWebhook, sUrl);
		LogError("Message: %s", sMessage);
		return;
	}
	
	// If the message dosn't start with a '{' it's not for a JSON formated message, lets fix that!
	if(StrContains(sMessage, "{") != 0)
		Format(sMessage, sizeof(sMessage), "{\"content\":\"%s\"}", sMessage);
	
	if (aWebhook == null)
	{
		aWebhook = new ArrayList(64);
		aMsg = new ArrayList(4096);
	}
	
	aWebhook.PushString(sWebhook);
	aMsg.PushString(sMessage);
}

void SendNextMsg()
{
	// We are still waiting for a reply from our last msg
	if(bSending)
		return;
	
	// Nothing to send
	if(aWebhook == null || aWebhook.Length < 1)
		return;
	
	char sWebhook[64]
	aWebhook.GetString(0, sWebhook, sizeof(sWebhook));
	
	char sMessage[16384];
	aMsg.GetString(0, sMessage, sizeof(sMessage));
	
	char sUrl[512];
	if(!GetWebHook(sWebhook, sUrl, sizeof(sUrl)))
	{
		LogError("Webhook config not found or invalid! Webhook: %s Url: %s", sWebhook, sUrl);
		LogError("Message: %s", sMessage);
		return;
	}

	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sUrl);
	if(!hRequest || !SteamWorks_SetHTTPCallbacks(hRequest, view_as<SteamWorksHTTPRequestCompleted>(OnRequestComplete)) 
				|| !SteamWorks_SetHTTPRequestRawPostBody(hRequest, "application/json", sMessage, strlen(sMessage))
				|| !SteamWorks_SendHTTPRequest(hRequest))
	{
		delete hRequest;
		LogError("SendNextMsg: Failed To Send Message");
		return;
	}
	
	// Don't Send new messages aslong we wait for a reply from this one
	bSending = true;
}

int OnRequestComplete(Handle hRequest, bool bFailed, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	// This should not happen!
	if(bFailed || !bRequestSuccessful)
	{
		LogError("[OnRequestComplete] Request failed");
	}
	// Seems like the API is busy or too many message send recently
	else if(eStatusCode == k_EHTTPStatusCode429TooManyRequests || eStatusCode == k_EHTTPStatusCode500InternalServerError)
	{
		if(!bSlowdown)
			RestartMessageTimer(true);
	}
	// Wrong msg format, API doesn't like it
	else if(eStatusCode == k_EHTTPStatusCode400BadRequest)
	{
		char sMessage[16384];
		aMsg.GetString(0, sMessage, sizeof(sMessage));
		
		LogError("[OnRequestComplete] Bad Request! Error Code: [400]. Check your message, the API doesn't like it! Message: \"%s\"", sMessage); 
		
		// Remove it, the API will never accept it like this.
		aWebhook.Erase(0);
		aMsg.Erase(0);
	}
	else if(eStatusCode == k_EHTTPStatusCode200OK || eStatusCode == k_EHTTPStatusCode204NoContent)
	{
		if(bSlowdown)
			RestartMessageTimer(false);
			
		aWebhook.Erase(0);
		aMsg.Erase(0);
	}
	// Unknown error
	else 
	{
		LogError("[OnRequestComplete] Error Code: [%d]", eStatusCode);
			
		aWebhook.Erase(0);
		aMsg.Erase(0);
	}
	
	delete hRequest;
	bSending = false;
}

// Timer functions

Action Timer_SendNextMessage(Handle timer, any data)
{
	SendNextMsg();
	return Plugin_Continue;
}

void RestartMessageTimer(bool slowdown)
{
	bSlowdown = slowdown;
	
	if(hTimer != null)
		delete hTimer;
	
	hTimer = CreateTimer(bSlowdown ? 1.0 : 0.1, Timer_SendNextMessage, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void DisableTimer()
{
    hTimer = null;
}

