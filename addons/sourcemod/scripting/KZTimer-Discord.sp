#include <sourcemod>
#include <kztimer>
#include <colorvariables>
#include <discord>
#pragma newdecls required
#pragma semicolon 1

ConVar g_dcRecordAnnounceDiscord;	
ConVar g_dcUrl_thumb;
ConVar g_dcFooterText;
ConVar g_dcFooterIconUrl;
ConVar g_dcEmbedPROColor;
ConVar g_dcEmbedTPColor;
ConVar g_dcBotUsername;

char g_szMapName[128];

#define PREFIX "\x01[\x03KZT-DISCORD\x01]"

public Plugin myinfo =
{
	name		=	"KZTimer Discord Webhooks",
	author		=	"Infra",
	description	=	"Discord webhook announcements for KZTimer map records.",
	version		=	"1.0.1",
	url			=	"https://github.com/1zc"
};


public void OnPluginStart()
{
	RegAdminCmd("sm_discordTest", Command_DiscordTest, ADMFLAG_ROOT);

	g_dcRecordAnnounceDiscord = CreateConVar("kzt_discord_announce", "", "Web hook link to announce records to discord.", FCVAR_PROTECTED);
	g_dcUrl_thumb = CreateConVar("kzt_discord_thumb", "https://d2u7y93d5eagqt.cloudfront.net/mapImages/", "The base url of where the Discord thumb images are stored. Leave blank to disable.");
	g_dcBotUsername = CreateConVar("kzt_discord_username", "", "Username of the bot");
	g_dcFooterText = CreateConVar("kzt_discord_footer_text", "KZTimer - Map Records", "The text that appears at the footer of the embeded message.");
	g_dcFooterIconUrl = CreateConVar("kzt_discord_footer_icon_url", "https://infra.s-ul.eu/Hird3SHc", "The url to the icon that appears at the footer of the embeded message.");
	g_dcEmbedPROColor = CreateConVar("kzt_discord_pro_color", "#ff2222", "The color of the embed of PRO records.");
	g_dcEmbedTPColor = CreateConVar("kzt_discord_tp_color", "#09ff00", "The color of the embed of TP records.");

	AutoExecConfig(true, "KZTimer-Discord");
}


public void KZTimer_TimerStopped(int client, int teleports, float time, int record)
{
	if (record == 1 && IsValidClient(client, true))
	{
		char timeStr[32], 
			formattedName[256], 
			szSteamID[64];

		GetClientAuthId(client, AuthId_SteamID64, szSteamID, sizeof szSteamID, true);
		Format( formattedName, sizeof formattedName , "[%N](http://www.steamcommunity.com/profiles/%s)", client, szSteamID );
		GetCurrentMap(g_szMapName, 128);

		FormatTimeFloat(time, 3, timeStr, sizeof(timeStr));

		sendDiscordAnnouncement(formattedName, g_szMapName, timeStr, teleports);
	}
}


stock void sendDiscordAnnouncement(const char[] szName, char szMapName[128], char szTime[32], int teleports = 0)
{
	char webhook[1024], 
		szFooterText[256], 
		szFooterIconUrl[1024], 
		szColor[16], 
		szTPNum[4], 
		szBotUsername[256];

	GetConVarString(g_dcRecordAnnounceDiscord, webhook, 1024);
	if (StrEqual(webhook, ""))
		return;

	GetConVarString(g_dcFooterText, szFooterText, sizeof szFooterText);
	GetConVarString(g_dcFooterIconUrl, szFooterIconUrl, sizeof szFooterIconUrl);
	GetConVarString(g_dcBotUsername, szBotUsername, sizeof szBotUsername);

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
		Embed.SetTitle("New TP Server Record!");
	else
		Embed.SetTitle("New PRO Server Record!");
	
	Embed.AddField("Player:", szName, true);
	Embed.AddField("Map:", szMapName, true);
	Embed.AddField("Record:", szTimeDiscord, false);
	if(teleports > 0)
	{
		IntToString(teleports, szTPNum, sizeof szTPNum);
		Embed.AddField("# of TPs:", szTPNum, false);
	}

	if (!StrEqual(szFooterText, ""))
		Embed.SetFooter(szFooterText);
	
	if (!StrEqual(szFooterText, ""))
		Embed.SetFooter(szFooterText);
	
	if(!StrEqual(szFooterIconUrl, ""))
		Embed.SetFooterIcon(szFooterIconUrl);
	
	char szUrlThumb[1024];
	GetConVarString(g_dcUrl_thumb, szUrlThumb, 1024);
	StrCat(szUrlThumb, sizeof(szUrlThumb), szMapName);
	StrCat(szUrlThumb, sizeof(szUrlThumb), ".jpg");
	Embed.SetThumb(szUrlThumb);

	//Send the message
	hook.Embed(Embed);
	hook.Send();
	delete hook;
}


public Action Command_DiscordTest(int client, int args)
{
	sendDiscordAnnouncement("Test Player", "kz_lego", "00:42.69");
	CPrintToChat(client, "%s {green}Sent test PRO record to Discord.", PREFIX);
	sendDiscordAnnouncement("Test Player", "kz_lego", "00:42.69", 69);
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