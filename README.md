# KZTimer-Discord
A simple plugin that provides Discord webhook announcements (map record announcements) for KZTimer servers. 

![An example of what it looks like](https://infra.s-ul.eu/7luhP9Zs.png)

## Discord Channel Setup:

First, you will need to prepare a channel in your Discord server to receive these record announcements. This is fairly simple to do:
* ***Step 1:*** Edit a channel > enter the Webhooks section inside the Integrations sub-menu > Make a new webhook.
* ***Step 2:*** Customize your new webhook! I recommend naming it according to the server you're going to use the webhook for, and adding an avatar related to your servers. (Making separate webhooks, accordingly named, for each server you host is a great way to identify what server a record was set on!)
* ***Step 3:*** Copy and note down your webhook URL. You will need it for the plugin configuration later!

![Webhook Setup](https://infra.s-ul.eu/PGIRZY4W)

## Installing the Plugin on your Server:

* ***Step 1:*** Download the latest release. It will be a .ZIP file containing everything you need, so extract it and get it ready.
* ***Step 2:*** Move the "cfg" and "addons" folders in the release into your servers "csgo" folder.
* ***Step 3:*** Enter csgo/cfg/sourcemod on your server, and edit the `KZTimer-Discord.cfg` configuration file.
* ***Step 4:*** There are only two ConVars in this configuration file. The first for the webhook URL you would like these announcements to be delivered to, and the second is where the plugin retrieves images of maps. You only need to configure the first one - paste the webhook URL you copied when you created your webhook previously, and save the file.

![Plugin Install](https://infra.s-ul.eu/3j2zZOAq)

## Testing the Plugin

With that, you should be be good to go! To make sure it works, there is a command (locked to Z-Flag) that sends out test record announcements to the configured webhook.
```
sm_discordTest 
```

Feel free to hit me up with any questions/issues you have - *Infra#0001* on Discord.
Want to see the plugin in action? Check out our Discord Server's [#server-records channel!](https://discord.gg/Hj2Q54H)
