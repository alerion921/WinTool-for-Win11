First time usage (Launch Powershell.exe as Administrator)
After that a shortcut is automaticly created at the desktop for easy access! :)

Long: 
```
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/WinTool.ps1'))
```
Or, shorter:
```
iwr -useb  https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/WinTool.ps1 | iex
```

Features:
Essential Tweaks - Just provides a better look over all and removes some of the BS that was introduced with Windows 11 (Recommended!!!)

Undo Essential Tweaks - Well it does what it says it does :)

Gaming Tweaks - This function i run on my gaming PC to make sure i have the lowest latency and highest responsiveness for a smoother over all gaming experience.

Patch Security - Could be used on a server enviroment since it blocks out all scripting and known security issues, this one also works great for unsupported Operative Systems like Windows 7 or Windows XP (Not recommended for the average user!)

Remove OneDrive - Don't worry you can get it back by pressing the button bellow if you want to. (Recommended!)

Restore OneDrive - Ooof, please use Dropbox instead.

Remove Microsoft Edge - This is experimental and i would just not use it right now since it comes back regardless, might get fixed at some point :)

Error Scanner - Uses features already in Windows command line like DISM.exe or SFC to repair errors in your operative system (Rebooting to Safe Mode is recommended if you want to use this)

ChangeDNS - Bringing a more dynamic Domain Name System to you, i recommend picking Cloudflare since its the fastest one in my experience but Google's is also good!

Reset Network - Flushes and Resets all IP's and DNS'es. Very usefull if you get the Localhost "virus", that is why it's included here.

Force NO/NB Language - Had some issues where Windows would automaticly set the Keyboard Language to English based on the application i was using and found it annoying so i made a tiny script to Brute Force it to become Norwegian at all times :D

Set Time to UTC - Very usefull after replacing a BIOS Battery/Clearing CMOS or if you just want to Dualboot Windows with OSX or Linux and can't get the time zone to synchronize properly.

Classic Menus - Gives easy access to needed menus for people that want that!

Windows Update - Default settings = Restore Settings if other options was used before. The Security update is if you only want that and not the large packets Windows Update sometimes push or any extra. Windows Update reset deletes all previously downloaded updates and restarts all services and clears all registry entries that are associated with it.

Remove MS Store Apps - Highly recommended as it removes a ton of bloatware pre installed with all Windows 10/11 systems. It's magic!

Reinstall MS Store Apps - Reinstalls apps like Teams and OneDrive but does not bring back the bloatware that was pre installed, you will have to install that back yourself if you want it.

Ultimate Cleaning - A good script to delete all hidden and visible temp files for known applications without destorying any personal documents or anything like that. (This tool provides a restore point if you are in doubt about doing this, so you are safe anyways!)

Dark Mode - Easy access to enable system wide dark mode

Light Mode - Does the same as the above but with light mode instead.

Install apps---

Added a couple of my favorite apps for easy access to this list, Spotify setup is downloaded to Desktop and DS4 + Bakkesmod are downloaded to C:/Users/[YOURUSERNAME]/documents/ for storage and since they would require user interactions anways.

Update apps---

Utillity that uses winget to update all apps that you have installed now or before that are supported by winget.

Reset button just resets the checkboxes if you want to start over.

Enjoy! :) Feel free to make changes!
