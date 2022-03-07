
Paste this command into Powershell (admin):
```
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/WinTool.ps1'))
```
Or, shorter:
```
iwr -useb  https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/WinTool.ps1 | iex
```

