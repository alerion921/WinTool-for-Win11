Basic usage to setup a Gaming PC with this Script:
Press "Essential Tweaks"
Press "Gaming Tweaks"
Press "Remove OneDrive"
Press "Security Updates"
Press "Remove MS Store Apps"
Press "Ultimate Power Plan"
Press "Optimize Performance"

Then at the end since Windows is a bit buggy press "Enable Action Centre" this will make sound, internet and notification area work again.

Alternativly you can use the Ultimate Cleaner to clean up (this is a feature i suggest to from time to time to clear variants of caches and themp files after some usage) 


Paste this command into Powershell (admin):
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
