Basic usage!

Press essential tweaks, this now includes all needed for the optimal setup as long as you disabled all the tracking shit from Microsoft when you setup your OS.

Gaming Tweaks can be applied if you are configurating a GamingPC

Patch Security is for paranoid people and will prolly be removed, it blocks alot of usefull stuff like running Scripts so i would avoid this myself.

Remove MS Store Apps is time consuming but will remove all the bloatware includes in a fresh Windows Install and also Unpin all those from the Start Menu.

Disabled the option to remove the notification area since this can be usefull and you can just set Alerts/Notifications to silent or alarms only.

Alternativly you can use the Ultimate Cleaner to clean up (this is a feature i suggest to from time to time to clear variants of caches and themp files after some usage) 

Also added Winget app installation so the software i recommend and use the most is easier available when setting up a fresh OS install.

Paste this command into Powershell (admin):

Shortest:
```
iwr -useb  https://t.ly/uObQL | iex
```
Longest: 
```
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/WinTool.ps1'))
```
Or, shorter:
```
iwr -useb  https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/WinTool.ps1 | iex
```

Some credits here to:

https://github.com/christitustech

https://github.com/DaddyMadu

https://github.com/simeononsecurity

https://github.com/gordonbay


Since this started out as a fork from ChrisTitusTech i give credit but it has been heavily modified since.. so it does not qualify as a fork no more since i have added countless improvements...
