#include <sourcemod>
#include <kztimer>
#include <colorvariables>
#include <discord>
#include <ripext>
#pragma newdecls required
#pragma semicolon 1

HTTPClient httpClient;

ConVar g_dcRecordAnnounceDiscord;	
ConVar g_dcUrl_thumb;
ConVar g_dcFooterText;
ConVar g_dcFooterIconUrl;
ConVar g_dcEmbedPROColor;
ConVar g_dcEmbedTPColor;
ConVar g_dcBotUsername;
ConVar g_cvHostname;
ConVar g_cvSteamWebAPIKey;

char g_szPictureURL[1024],
	g_szApiKey[64];

#define PREFIX "\x01[\x03KZT-DISCORD\x01]"

public Plugin myinfo =
{
	name		=	"KZTimer Discord Webhooks",
	author		=	"Infra, improved by Sarrus",
	description	=	"Discord webhook announcements for KZTimer map records.",
	version		=	"1.1.0",
	url			=	"https://github.com/1zc"
};


public void OnPluginStart()
{
	RegAdminCmd("sm_discordTest", Command_DiscordTest, ADMFLAG_ROOT);

	g_dcRecordAnnounceDiscord = CreateConVar("kzt_discord_announce", "", "Web hook link to announce records to discord.", FCVAR_PROTECTED);
	g_dcUrl_thumb = CreateConVar("kzt_discord_thumb", "https://d2u7y93d5eagqt.cloudfront.net/mapImages/", "The base url of where the Discord thumb images are stored. Leave blank to disable.");
	g_dcBotUsername = CreateConVar("kzt_discord_username", "", "Username of the bot");
	g_dcFooterText = CreateConVar("kzt_discord_footer_text", "KZTimer - Map Records", "The text that appears at the footer of the embeded message. Leave blank for server hostname.");
	g_dcFooterIconUrl = CreateConVar("kzt_discord_footer_icon_url", "https://infra.s-ul.eu/Hird3SHc", "The url to the icon that appears at the footer of the embeded message.");
	g_dcEmbedPROColor = CreateConVar("kzt_discord_pro_color", "#ff2222", "The color of the embed of PRO records.");
	g_dcEmbedTPColor = CreateConVar("kzt_discord_tp_color", "#09ff00", "The color of the embed of TP records.");
	g_cvSteamWebAPIKey = CreateConVar("kzt_discord_steam_api_key", "", "Allows the use of the player profile picture, leave blank to disable. The key can be obtained here: https://steamcommunity.com/dev/apikey", FCVAR_PROTECTED);
	g_cvHostname = FindConVar("hostname");
	
	GetConVarString(g_cvSteamWebAPIKey, g_szApiKey, sizeof g_szApiKey);

	AutoExecConfig(true, "KZTimer-Discord");
}


public void KZTimer_TimerStopped(int client, int teleports, float time, int record)
{
	if (record == 1 && IsValidClient(client, true))
	{
		if(StrEqual(g_szApiKey, ""))
			sendDiscordAnnouncement(client, time, teleports);
		else
			GetProfilePictureURL(client, teleports, time);
	}
}

stock void sendDiscordAnnouncement(int client, float time, int teleports = 0)
{
	char webhook[1024], 
		szFooterText[256], 
		szFooterIconUrl[1024], 
		szColor[16], 
		szTPNum[4], 
		szBotUsername[256],
		szUrlThumb[1024],
		szTitleBuffer[512],
		szName[1024],
		szSteamID[64],
		szMapName[128],
		szTime[32];
	
	FormatTimeFloat(time, 3, szTime, sizeof szTime);

	GetCurrentMap(szMapName, sizeof szMapName);
	RemoveWorkshop(szMapName, sizeof szMapName);

	GetClientAuthId(client, AuthId_SteamID64, szSteamID, sizeof szSteamID, true);
	Format( szName, sizeof szName , "[%N](http://www.steamcommunity.com/profiles/%s)", client, szSteamID );
	
	GetConVarString(g_dcRecordAnnounceDiscord, webhook, sizeof webhook);
	if (StrEqual(webhook, ""))
		return;

	GetConVarString(g_dcFooterText, szFooterText, sizeof szFooterText);
	GetConVarString(g_dcFooterIconUrl, szFooterIconUrl, sizeof szFooterIconUrl);
	GetConVarString(g_dcBotUsername, szBotUsername, sizeof szBotUsername);
	GetConVarString(g_dcUrl_thumb, szUrlThumb, 1024);
	
	StrCat(szUrlThumb, sizeof(szUrlThumb), szMapName);
	StrCat(szUrlThumb, sizeof(szUrlThumb), ".jpg");

	if(teleports > 0)
		GetConVarString(g_dcEmbedTPColor, szColor, sizeof szColor);
	else
		GetConVarString(g_dcEmbedPROColor, szColor, sizeof szColor);

	DiscordWebHook hook = new DiscordWebHook(webhook);
	hook.SlackMode = true;

	if(!StrEqual(szBotUsername, ""))
		hook.SetUsername( szBotUsername );
	
	
	//Create the embed message
	MessageEmbed Embed = new MessageEmbed();

	char szTimeDiscord[128];
	Format(szTimeDiscord, sizeof(szTimeDiscord), "%s", szTime);
	Embed.SetColor(szColor);
	if(teleports > 0)
		Format( szTitleBuffer, sizeof szTitleBuffer , "__**New Server Record**__ | **%s** - **%s**", szMapName, "TP" );
	else
		Format( szTitleBuffer, sizeof szTitleBuffer , "__**New Server Record**__ | **%s** - **%s**", szMapName, "PRO" );
	Embed.SetTitle(szTitleBuffer);
	
	Embed.AddField("Player:", szName, true);
	Embed.AddField("Record:", szTimeDiscord, true);

	if(teleports > 0)
	{
		IntToString(teleports, szTPNum, sizeof szTPNum);
		Embed.AddField("# of TPs:", szTPNum, true);
	}

	// If the convar for the footer text is empty, add the server's hostname
	if (StrEqual(szFooterText, ""))
		GetConVarString(g_cvHostname, szFooterText, sizeof szFooterText);
	Embed.SetFooter(szFooterText);
	
	if(!StrEqual(szFooterIconUrl, ""))
		Embed.SetFooterIcon(szFooterIconUrl);
	
	if(StrEqual(g_szPictureURL, ""))
		Embed.SetThumb(szUrlThumb);
	else
	{
		Embed.SetImage(szUrlThumb);
		Embed.SetThumb(g_szPictureURL);
	}
	
	

	//Send the message
	hook.Embed(Embed);
	hook.Send();
	PrintToServer("Sent");
	delete hook;
}


public Action Command_DiscordTest(int client, int args)
{
	KZTimer_TimerStopped(client, 0, 42.69, 1);
	CPrintToChat(client, "%s {green}Sent test PRO record to Discord.", PREFIX);
	KZTimer_TimerStopped(client, 69, 42.69, 1);
	CPrintToChat(client, "%s {green}Sent test TP record to Discord.", PREFIX);
	return Plugin_Handled;
}


stock void FormatTimeFloat(float time, int type, char[] string, int length)
{
	char szMilli[16];
	char szSeconds[16];
	char szMinutes[16];
	char szHours[16];
	char szMilli2[16];
	char szSeconds2[16];
	char szMinutes2[16];
	int imilli;
	int imilli2;
	int iseconds;
	int iminutes;
	int ihours;
	time = FloatAbs(time);
	imilli = RoundToZero(time*100);
	imilli2 = RoundToZero(time*10);
	imilli = imilli%100;
	imilli2 = imilli2%10;
	iseconds = RoundToZero(time);
	iseconds = iseconds%60;
	iminutes = RoundToZero(time/60);
	iminutes = iminutes%60;
	ihours = RoundToZero((time/60)/60);

	if (imilli < 10)
		Format(szMilli, 16, "0%dms", imilli);
	else
		Format(szMilli, 16, "%dms", imilli);
	if (iseconds < 10)
		Format(szSeconds, 16, "0%ds", iseconds);
	else
		Format(szSeconds, 16, "%ds", iseconds);
	if (iminutes < 10)
		Format(szMinutes, 16, "0%dm", iminutes);
	else
		Format(szMinutes, 16, "%dm", iminutes);


	Format(szMilli2, 16, "%d", imilli2);
	if (iseconds < 10)
		Format(szSeconds2, 16, "0%d", iseconds);
	else
		Format(szSeconds2, 16, "%d", iseconds);
	if (iminutes < 10)
		Format(szMinutes2, 16, "0%d", iminutes);
	else
		Format(szMinutes2, 16, "%d", iminutes);
	//Time: 00m 00s 00ms
	if (type==0)
	{
		Format(szHours, 16, "%dm", iminutes);
		if (ihours>0)
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "%s:%s:%s.%s", szHours, szMinutes2,szSeconds2,szMilli2);
		}
		else
		{
			Format(string, length, "%s:%s.%s", szMinutes2,szSeconds2,szMilli2);
		}
	}
	//00m 00s 00ms
	if (type==1)
	{
		Format(szHours, 16, "%dm", iminutes);
		if (ihours>0)
		{
			Format(szHours, 16, "%dh", ihours);
			Format(string, length, "%s %s %s %s", szHours, szMinutes,szSeconds,szMilli);
		}
		else
			Format(string, length, "%s %s %s", szMinutes,szSeconds,szMilli);
	}
	else
	//00h 00m 00s 00ms
	if (type==2)
	{
		imilli = RoundToZero(time*1000);
		imilli = imilli%1000;
		if (imilli < 10)
			Format(szMilli, 16, "00%dms", imilli);
		else
		if (imilli < 100)
			Format(szMilli, 16, "0%dms", imilli);
		else
			Format(szMilli, 16, "%dms", imilli);
		Format(szHours, 16, "%dh", ihours);
		Format(string, 32, "%s %s %s %s",szHours, szMinutes,szSeconds,szMilli);
	}
	else
	//00:00:00
	if (type==3)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);
		if (ihours>0)
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "%s:%s:%s.%s", szHours, szMinutes,szSeconds,szMilli);
		}
		else
			Format(string, length, "%s:%s.%s", szMinutes,szSeconds,szMilli);
	}
	//Time: 00:00:00
	if (type==4)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);
		if (ihours>0)
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "Time: %s:%s:%s", szHours, szMinutes,szSeconds);
		}
		else
			Format(string, length, "Time: %s:%s", szMinutes,szSeconds);
	}
	if (type==5)
	{
		if (imilli < 10)
			Format(szMilli, 16, "0%d", imilli);
		else
			Format(szMilli, 16, "%d", imilli);
		if (iseconds < 10)
			Format(szSeconds, 16, "0%d", iseconds);
		else
			Format(szSeconds, 16, "%d", iseconds);
		if (iminutes < 10)
			Format(szMinutes, 16, "0%d", iminutes);
		else
			Format(szMinutes, 16, "%d", iminutes);
		if (ihours>0)
		{
			Format(szHours, 16, "%d", ihours);
			Format(string, length, "Timeleft: %s:%s:%s", szHours, szMinutes,szSeconds);
		}
		else
			Format(string, length, "Timeleft: %s:%s", szMinutes,szSeconds);
	}
}

stock bool IsValidClient(int client, bool nobots = true)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false; 
	}
	return IsClientInGame(client); 
}

stock void RemoveWorkshop(char[] szMapName, int len)
{
	int i=0;
	char szBuffer[16], szCompare[1] = "/";

	// Return if "workshop/" is not in the mapname
	if(ReplaceString(szMapName, len, "workshop/", "", true) != 1)
		return;

	// Find the index of the last /
	do
	{
		szBuffer[i] = szMapName[i];
		i++;
	}
	while(szMapName[i] != szCompare[0]);
	szBuffer[i] = szCompare[0];
	ReplaceString(szMapName, len, szBuffer, "", true);
}


stock void GetProfilePictureURL(int client, int teleports, float time) 
{
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(teleports);
	pack.WriteCell(time);
	pack.Reset();

	char szRequestBuffer[1024],
	 szSteamID[64];
	
	//GetConVarString(g_cvApiKey, szApiKey, sizeof szApiKey);
	GetClientAuthId(client, AuthId_SteamID64, szSteamID, sizeof szSteamID, true);

	GetConVarString(g_cvSteamWebAPIKey, g_szApiKey, sizeof g_szApiKey);

	Format(szRequestBuffer, sizeof szRequestBuffer, "ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s&format=json", g_szApiKey,szSteamID);
	httpClient = new HTTPClient("https://api.steampowered.com");
	httpClient.Get(szRequestBuffer, OnResponseReceived, pack);
}


stock void OnResponseReceived(HTTPResponse response, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int teleports = pack.ReadCell();
	float time = pack.ReadCell();

	if (response.Status != HTTPStatus_OK) 
		return;
	
	JSONObject objects = view_as<JSONObject>(response.Data);
	JSONObject Response = view_as<JSONObject>(objects.Get("response"));
	JSONArray players = view_as<JSONArray>(Response.Get("players"));
	int playerlen = players.Length;
	
	PrintToServer("%d", playerlen);
	JSONObject player;
	for (int i = 0; i < playerlen; i++)
	{
		player = view_as<JSONObject>(players.Get(i));
		player.GetString("avatarmedium", g_szPictureURL, sizeof(g_szPictureURL));
		delete player;
  }
	sendDiscordAnnouncement(client, time, teleports);
}