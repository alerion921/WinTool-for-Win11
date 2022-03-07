
Paste this command into Powershell (admin):
```
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alerion921/WinTool/master/alerion-toolbox.ps1'))
```
Or, shorter:
```
iwr -useb https://raw.githubusercontent.com/alerion921/WinTool/master/alerion-toolbox.ps1 | iex
```

