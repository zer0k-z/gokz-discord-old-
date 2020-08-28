# GOKZ - Discord Module

An optional module for GOKZ that posts server records to a Discord channel using webhooks. 

## Installing ##
 * Make sure your server is up to date.
 * Install GOKZ and all the dependencies if you didn't do it yet.
 * Download and extract gokz-discord.zip from the ``Download`` tab to ``csgo``
 * Get your webhook URL from your Discord server and replace ``WEBHOOK_URL`` with yours in ``csgo/addons/sourcemod/configs/gokz-discord.cfg``.

### How do I create a Webhook URL? ###

As a server administrator, go on ``Server Settings``  then ``Integrations`` then ``Webhooks``. Click on ``New Webhook``, choose the name of your webhook and its channel, then click on ``Copy Webhook URL`` to obtain the link. 

Changing the webhook's name or channel will **not** alter the link.

### Dependencies ###
 * [GOKZ](https://bitbucket.org/kztimerglobalteam/gokz)  with core, localdb and localranks modules
 * [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556)
 * [SMJansson](https://forums.alliedmods.net/showthread.php?t=184604)
 
If your GOKZ server is global, it already has all the required dependencies. Note that your server does **not** need to be global in order to use this plugin.

### Missing features ###
 * Support for multiple webhooks
 * Support for a custom thumbnail server
 * Easy way to disable the plugin

If any feature is highly requested, I will try to work on it.

### Problems? ###

If you have any question, mention me zer0.k#2613 or go on the [my Discord channel](https://discord.gg/d79CR3M). Or send me a message through Steam, that works too.

---
Special thanks to zealain for answering all of my dumb questions, Ruto for fixing all of my dumb errors and Zach47 for the thumbnail server.