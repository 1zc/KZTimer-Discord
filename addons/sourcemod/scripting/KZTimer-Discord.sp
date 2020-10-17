#include <sourcemod>
#include <kztimer>
#include <multicolors>
#include <discord>

ConVar g_dcRecordAnnounceDiscord = null;	
ConVar g_dcUrl_thumb = null;

char g_szSteamID[MAXPLAYERS+1][32];
char g_szSteamName[MAXPLAYERS+1][32];
char g_szMapName[128];

#define PREFIX "\x01[\x03KZT-DISCORD\x01]"

public Plugin myinfo =
{
    name        =    "KZTimer Discord Webhooks",
    author        =    "Infra",
    description    =    "Discord webhook announcements for KZTimer map records.",
    version        =    "1.0.0",
	url        =    "https://gflclan.com/profile/45876-infra/" // https://github.com/1zc
};

public void OnPluginStart()
{
    RegAdminCmd("sm_discordTest", Command_DiscordTest, ADMFLAG_ROOT);

    g_dcRecordAnnounceDiscord = CreateConVar("ck_announce_records_discord", "", "Web hook link to announce records to discord.");
    g_dcUrl_thumb = CreateConVar("ck_discord_url_thumb", "https://d2u7y93d5eagqt.cloudfront.net/mapImages/", "The base url of where the Discord thumb images are stored. Leave blank to disable.");

    AutoExecConfig(true, "KZTimer-Discord");
}

public KZTimer_TimerStoppedValid(int client, int teleports, int rank, float time)
{
	if (rank == 1)
	{
		char timeStr[32];
		char formattedName[128];

		GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], sizeof(g_szSteamID[]), true);
		GetClientName(client, g_szSteamName[client], sizeof(g_szSteamName[]));
		GetCurrentMap(g_szMapName, 128);

		FormatTimeFloat(client, time, 3, timeStr, sizeof(timeStr));
		Format(formattedName, sizeof(formattedName), g_szSteamName[client]);

		if (teleports > 0)
		{
			// TP TIME
			sendDiscordTPAnnouncement(formattedName, g_szMapName, timeStr, teleports);
		}

		else
		{
			// PRO TIME
			sendDiscordPROAnnouncement(formattedName, g_szMapName, timeStr);
		}
	}
}

public void sendDiscordPROAnnouncement(char szName[128], char szMapName[128], char szTime[32])
{
	char webhook[1024];
	GetConVarString(g_dcRecordAnnounceDiscord, webhook, 1024);
	if (StrEqual(webhook, ""))
	{
		return;
	}

	DiscordWebHook hook = new DiscordWebHook(webhook);
	hook.SlackMode = true;
	
	//Create the embed message
	MessageEmbed Embed = new MessageEmbed();

	char szTimeDiscord[128];
	Format(szTimeDiscord, sizeof(szTimeDiscord), "%s", szTime);
	Embed.SetColor("#ff2222");
	Embed.SetTitle("New PRO Server Record!");
	Embed.AddField("Player:", szName, true);
	Embed.AddField("Map:", szMapName, true);
	Embed.AddField("Record:", szTimeDiscord, false);
	Embed.SetFooter("KZTimer - Map Records");
	Embed.SetFooterIcon("https://infra.s-ul.eu/Hird3SHc");
	
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

public void sendDiscordTPAnnouncement(char szName[128], char szMapName[128], char szTime[32], int szTPNumInt)
{
	char webhook[1024];
	GetConVarString(g_dcRecordAnnounceDiscord, webhook, 1024);
	if (StrEqual(webhook, ""))
	{
		return;
	}

	DiscordWebHook hook = new DiscordWebHook(webhook);
	hook.SlackMode = true;
	
	//Create the embed message
	MessageEmbed Embed = new MessageEmbed();
	
	char szTPNum[4];
	IntToString(szTPNumInt, szTPNum, 4);

	char szTimeDiscord[128];
	Format(szTimeDiscord, sizeof(szTimeDiscord), "%s", szTime);
	Embed.SetColor("#09ff00");
	Embed.SetTitle("New TP Server Record!");
	Embed.AddField("Player:", szName, true);
	Embed.AddField("Map:", szMapName, true);
	Embed.AddField("Record:", szTimeDiscord, false);
	Embed.AddField("# of TPs:", szTPNum, false);
	Embed.SetFooter("KZTimer - Map Records");
	Embed.SetFooterIcon("https://infra.s-ul.eu/Hird3SHc");
	
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
	sendDiscordPROAnnouncement("Test Player", "kz_lego", "00:42.69");
	CPrintToChat(client, "%s \x02Sent test PRO record to Discord.", PREFIX);
	sendDiscordTPAnnouncement("Test Player", "kz_lego", "00:42.69", 69);
	CPrintToChat(client, "%s \x02Sent test TP record to Discord.", PREFIX);
	return Plugin_Handled;
}

void FormatTimeFloat(int client, float time, int type, char[] string, int length)
{
	if (!IsValidClient(client))
		return;
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

public bool IsValidClient(int client)
{
    if(client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
        return true;
    return false;
}