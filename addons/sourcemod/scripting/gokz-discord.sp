#include <sourcemod>
#include <SteamWorks>
#include <smjansson>

#include <gokz/core>
#include <gokz/localdb>
#include <gokz/localranks>

public Plugin myinfo = {
	name = "GOKZ Discord Webhook", 
	author = "zer0.k", 
	description = "Sends map completions/records to a discord channel via webhook", 
	version = "1.0.0"
}

// Credit to Zach47 for the thumbnails hosting
// Credit to zipcore for most of send_message.sp

#include "gokz-discord/format_new_record.sp"
#include "gokz-discord/send_message.sp"

#pragma newdecls required
#pragma semicolon 1

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{	
	RegPluginLibrary("gokz-discord");
	return APLRes_Success;
}

public void OnMapStart()
{
	UpdateVariables();
	RestartMessageTimer(false);
}

public void OnMapEnd()
{
	DisableTimer();
}

public void GOKZ_LR_OnTimeProcessed(
	int client, 
	int steamID, 
	int mapID, 
	int course, 
	int mode, 
	int style, 
	float runTime, 
	int teleportsUsed, 
	bool firstTime, 
	float pbDiff, 
	int rank, 
	int maxRank, 
	bool firstTimePro, 
	float pbDiffPro, 
	int rankPro, 
	int maxRankPro)
{
	if (rank == 1 || rankPro == 1)
	{
		static char message[4096];
		DiscordFormatNewTime(message, sizeof(message), client, course, mode, style, runTime, teleportsUsed);
		DiscordSendMessage(message);
	}
}

