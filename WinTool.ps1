$HidePowershellWindow = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $HidePowershellWindow -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$ErrorActionPreference = 'SilentlyContinue'
$wshell = New-Object -ComObject Wscript.Shell
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	Exit
}

#Color Palette for heart.ico
##C40E61 - bright pink
##FFE082 - yellow
##F8BBD0 - light pink

Function MakeForm {

#Sets the information inside "About this computer"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "Manufacturer" -Type String -Value "Optimized by Alerion"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "SupportURL" -Type String -Value "https://github.com/alerion921"

#Downloads my heart icon from my github to be able to use it as an app icon and a shortcut icon :)
$iconPath = 'C:\Windows\heart.ico'
$url = "https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/Files/heart.ico"
Invoke-WebRequest -Uri $url -OutFile $iconPath

#Creates the shortcut for the script to be run easily
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\WinTool.lnk")
$Shortcut.IconLocation = "C:\Windows\heart.ico" # icon index 0
$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.WorkingDirectory = "C:\Windows\System32\WindowsPowerShell\v1.0\"
$Shortcut.Arguments = "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/WinTool.ps1'))"
$Shortcut.Save()

#This part makes sure the shortcut is automaticly starting as administrator so that there will be no errors..
$bytes = [System.IO.File]::ReadAllBytes("$Home\Desktop\WinTool.lnk")
$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
[System.IO.File]::WriteAllBytes("$Home\Desktop\WinTool.lnk", $bytes)


##C40E61 - bright pink
##FFE082 - yellow
##F8BBD0 - light pink

if ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme") -eq '0') {
    $frontcolor = [System.Drawing.ColorTranslator]::FromHtml("#182C36")
    $backcolor = [System.Drawing.ColorTranslator]::FromHtml("#5095B5")
    $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#346075")
} elseif ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme") -eq '1') {
    $frontcolor =[System.Drawing.ColorTranslator]::FromHtml("#C40E61")
    $backcolor = [System.Drawing.ColorTranslator]::FromHtml("#FFE082")
    $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#F8BBD0")
}

if ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme") -eq '0') {
    $frontcolor = [System.Drawing.ColorTranslator]::FromHtml("#182C36")
    $backcolor = [System.Drawing.ColorTranslator]::FromHtml("#5095B5")
    $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#346075")
} elseif ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme") -eq '1') {
    $frontcolor =[System.Drawing.ColorTranslator]::FromHtml("#C40E61")
    $backcolor = [System.Drawing.ColorTranslator]::FromHtml("#FFE082")
    $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#F8BBD0")
}


#Form Design
$Form                            = New-Object system.Windows.Forms.Form
$Form.text                       = "WinTool by Alerion"
$Form.StartPosition              = "CenterScreen"
$Form.TopMost                    = $false
$Form.BackColor                  = $backcolor
$Form.ForeColor                  = $frontcolor
$Form.AutoScaleDimensions        = '192, 192'
$Form.AutoScaleMode              = "Dpi"
$Form.AutoSize                   = $True
$Form.AutoScroll                 = $True
$Form.FormBorderStyle            = 'FixedSingle'

# GUI Icon
$iconBase64                      = [Convert]::ToBase64String((Get-Content "C:\Windows\heart.ico" -Encoding Byte))
$iconBytes                       = [Convert]::FromBase64String($iconBase64)
$stream                          = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
$stream.Write($iconBytes, 0, $iconBytes.Length)
$Form.Icon                       = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())
$Form.Width                      = $objImage.Width
$Form.Height                     = $objImage.Height
$Form.MinimizeBox                = $false;
$Form.MaximizeBox                = $false;

$Panel1                          = New-Object system.Windows.Forms.Panel
$Panel1.height                   = 440
$Panel1.width                    = 220
$Panel1.location                 = New-Object System.Drawing.Point(10,0)

$Panel2                          = New-Object system.Windows.Forms.Panel
$Panel2.height                   = 440
$Panel2.width                    = 220
$Panel2.location                 = New-Object System.Drawing.Point(240,0)

$Panel3                          = New-Object system.Windows.Forms.Panel
$Panel3.height                   = 440
$Panel3.width                    = 220
$Panel3.location                 = New-Object System.Drawing.Point(470,0)

$Panel4                          = New-Object system.Windows.Forms.Panel
$Panel4.height                   = 440
$Panel4.width                    = 230
$Panel4.location                 = New-Object System.Drawing.Point(700,0)

$Panel5                          = New-Object system.Windows.Forms.Panel
$Panel5.height                   = 110
$Panel5.width                    = 910
$Panel5.location                 = New-Object System.Drawing.Point(10,440)

#######################################################################################################
# Tweaks starts here
#######################################################################################################

$performancetweaks               = New-Object system.Windows.Forms.Label
$performancetweaks.text          = "Performance Tweaks"
$performancetweaks.AutoSize      = $false
$performancetweaks.width         = 220
$performancetweaks.height        = 35
$performancetweaks.TextAlign     = "MiddleCenter"
$performancetweaks.location      = New-Object System.Drawing.Point(0,10)
$performancetweaks.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$performancetweaks.ForeColor     = $frontcolor 

$essentialtweaks                 = New-Object system.Windows.Forms.Button
$essentialtweaks.text            = "Essential Tweaks"
$essentialtweaks.width           = 220
$essentialtweaks.height          = 65
$essentialtweaks.location        = New-Object System.Drawing.Point(0,45)
$essentialtweaks.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$essentialtweaks.BackColor       = $frontcolor 
$essentialtweaks.ForeColor       = $backcolor
$essentialtweaks.FlatStyle       = "Flat"
$essentialtweaks.FlatAppearance.MouseOverBackColor = $hovercolor

$essentialundo                   = New-Object system.Windows.Forms.Button
$essentialundo.text              = "Undo Essential Tweaks"
$essentialundo.width             = 220
$essentialundo.height            = 65
$essentialundo.location          = New-Object System.Drawing.Point(0,115)
$essentialundo.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$essentialundo.BackColor         = $frontcolor 
$essentialundo.ForeColor         = $backcolor
$essentialundo.FlatStyle         = "Flat"
$essentialundo.FlatAppearance.MouseOverBackColor = $hovercolor

$gamingtweaks                    = New-Object system.Windows.Forms.Button
$gamingtweaks.text               = "Gaming Tweaks"
$gamingtweaks.width              = 220
$gamingtweaks.height             = 65
$gamingtweaks.location           = New-Object System.Drawing.Point(0,185)
$gamingtweaks.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$gamingtweaks.BackColor          = $frontcolor 
$gamingtweaks.ForeColor          = $backcolor
$gamingtweaks.FlatStyle          = "Flat"
$gamingtweaks.FlatAppearance.MouseOverBackColor = $hovercolor

$securitypatches                 = New-Object system.Windows.Forms.Button
$securitypatches.text            = "Patch Security"
$securitypatches.width           = 220
$securitypatches.height          = 65
$securitypatches.location        = New-Object System.Drawing.Point(0,255)
$securitypatches.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$securitypatches.BackColor       = $frontcolor 
$securitypatches.ForeColor       = $backcolor
$securitypatches.FlatStyle       = "Flat"
$securitypatches.FlatAppearance.MouseOverBackColor = $hovercolor

$onedrive                        = New-Object system.Windows.Forms.Button
$onedrive.text                   = "Remove OneDrive"
$onedrive.width                  = 220
$onedrive.height                 = 30
$onedrive.location               = New-Object System.Drawing.Point(0,325)
$onedrive.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$onedrive.BackColor              = $frontcolor 
$onedrive.ForeColor              = $backcolor
$onedrive.FlatStyle              = "Flat"
$onedrive.FlatAppearance.MouseOverBackColor = $hovercolor

$InstallOneDrive                 = New-Object system.Windows.Forms.Button
$InstallOneDrive.text            = "Restore OneDrive"
$InstallOneDrive.width           = 220
$InstallOneDrive.height          = 30
$InstallOneDrive.location        = New-Object System.Drawing.Point(0,360)
$InstallOneDrive.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$InstallOneDrive.BackColor       = $frontcolor 
$InstallOneDrive.ForeColor       = $backcolor
$InstallOneDrive.FlatStyle       = "Flat"
$InstallOneDrive.FlatAppearance.MouseOverBackColor = $hovercolor

$killedge                        = New-Object system.Windows.Forms.Button
$killedge.text                   = "Remove Microsoft Edge"
$killedge.width                  = 220
$killedge.height                 = 30
$killedge.location               = New-Object System.Drawing.Point(0,395)
$killedge.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$killedge.BackColor              = $frontcolor 
$killedge.ForeColor              = $backcolor
$killedge.FlatStyle              = "Flat"
$killedge.FlatAppearance.MouseOverBackColor = $hovercolor

#######################################################################################################
# Tweaks ends here
#######################################################################################################
# Fixes starts here
#######################################################################################################

$fixes                           = New-Object system.Windows.Forms.Label
$fixes.text                      = "Fixes"
$fixes.AutoSize                  = $false
$fixes.width                     = 220
$fixes.height                    = 35
$fixes.TextAlign                 = "MiddleCenter"
$fixes.location                  = New-Object System.Drawing.Point(0,10)
$fixes.Font                      = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$fixes.ForeColor                 = $frontcolor 

$errorscanner                    = New-Object system.Windows.Forms.Button
$errorscanner.text               = "Error Scanner"
$errorscanner.width              = 220
$errorscanner.height             = 30
$errorscanner.location           = New-Object System.Drawing.Point(0,45)
$errorscanner.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$errorscanner.BackColor          = $frontcolor 
$errorscanner.ForeColor          = $backcolor
$errorscanner.FlatStyle          = "Flat"
$errorscanner.FlatAppearance.MouseOverBackColor = $hovercolor

##PLACEHOLDER
$changedns = New-Object system.Windows.Forms.ComboBox
$changedns.text = ""
$changedns.width               = 220
$changedns.height              = 30
$changedns.autosize = $true
[void] $changedns.Items.Add('Google')
[void] $changedns.Items.Add('Cloud Flare')
[void] $changedns.Items.Add('Level3')
[void] $changedns.Items.Add('Open DNS')
# Select the default value
$changedns.SelectedIndex = 0
$changedns.location            = New-Object System.Drawing.Point(0,80)
$changedns.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$changedns.BackColor           = $frontcolor 
$changedns.ForeColor           = $backcolor
$changedns.FlatStyle           = "Flat"
$changedns.BorderStyle         = "Flat"

$resetnetwork                       = New-Object system.Windows.Forms.Button
$resetnetwork.text               = "Reset Network"
$resetnetwork.width              = 220
$resetnetwork.height             = 30
$resetnetwork.location           = New-Object System.Drawing.Point(0,115)
$resetnetwork.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$resetnetwork.BackColor          = $frontcolor 
$resetnetwork.ForeColor          = $backcolor
$resetnetwork.FlatStyle          = "Flat"
$resetnetwork.FlatAppearance.MouseOverBackColor = $hovercolor

$laptopnumlock                   = New-Object system.Windows.Forms.Button
$laptopnumlock.text              = "Laptop Numlock Fix"
$laptopnumlock.width             = 220
$laptopnumlock.height            = 30
$laptopnumlock.location          = New-Object System.Drawing.Point(0,150)
$laptopnumlock.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$laptopnumlock.BackColor         = $frontcolor 
$laptopnumlock.ForeColor         = $backcolor
$laptopnumlock.FlatStyle         = "Flat"
$laptopnumlock.FlatAppearance.MouseOverBackColor = $hovercolor

$removeENkeyboard                 = New-Object system.Windows.Forms.Button
$removeENkeyboard.text            = "Force NOR Keyboard"
$removeENkeyboard.width           = 220
$removeENkeyboard.height          = 30
$removeENkeyboard.location        = New-Object System.Drawing.Point(0,185)
$removeENkeyboard.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$removeENkeyboard.BackColor       = $frontcolor 
$removeENkeyboard.ForeColor       = $backcolor
$removeENkeyboard.FlatStyle       = "Flat"
$removeENkeyboard.FlatAppearance.MouseOverBackColor = $hovercolor

#######################################################################################################
# Fixes ends here
#######################################################################################################
# Old menus starts here
#######################################################################################################

$oldmenu                         = New-Object system.Windows.Forms.Label
$oldmenu.text                    = "Classic Menus"
$oldmenu.AutoSize                = $false
$oldmenu.width                   = 220
$oldmenu.height                  = 35
$oldmenu.TextAlign               = "MiddleCenter"
$oldmenu.location                = New-Object System.Drawing.Point(0,220)
$oldmenu.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$oldmenu.ForeColor               = $frontcolor 

$ncpa                            = New-Object system.Windows.Forms.Button
$ncpa.text                       = "Network Panel"
$ncpa.width                      = 220
$ncpa.height                     = 30
$ncpa.location                   = New-Object System.Drawing.Point(0,255)
$ncpa.Font                       = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$ncpa.BackColor                  = $frontcolor 
$ncpa.ForeColor                  = $backcolor
$ncpa.FlatStyle                  = "Flat"
$ncpa.FlatAppearance.MouseOverBackColor = $hovercolor

$oldcontrolpanel                 = New-Object system.Windows.Forms.Button
$oldcontrolpanel.text            = "Control Panel"
$oldcontrolpanel.width           = 220
$oldcontrolpanel.height          = 30
$oldcontrolpanel.location        = New-Object System.Drawing.Point(0,290)
$oldcontrolpanel.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$oldcontrolpanel.BackColor       = $frontcolor 
$oldcontrolpanel.ForeColor       = $backcolor
$oldcontrolpanel.FlatStyle       = "Flat"
$oldcontrolpanel.FlatAppearance.MouseOverBackColor = $hovercolor

$oldsoundpanel                   = New-Object system.Windows.Forms.Button
$oldsoundpanel.text              = "Sound Panel"
$oldsoundpanel.width             = 220
$oldsoundpanel.height            = 30
$oldsoundpanel.location          = New-Object System.Drawing.Point(0,325)
$oldsoundpanel.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$oldsoundpanel.BackColor         = $frontcolor 
$oldsoundpanel.ForeColor         = $backcolor
$oldsoundpanel.FlatStyle         = "Flat"
$oldsoundpanel.FlatAppearance.MouseOverBackColor = $hovercolor

$oldsystempanel                  = New-Object system.Windows.Forms.Button
$oldsystempanel.text             = "System Panel"
$oldsystempanel.width            = 220
$oldsystempanel.height           = 30
$oldsystempanel.location         = New-Object System.Drawing.Point(0,360)
$oldsystempanel.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$oldsystempanel.BackColor        = $frontcolor 
$oldsystempanel.ForeColor        = $backcolor
$oldsystempanel.FlatStyle        = "Flat"
$oldsystempanel.FlatAppearance.MouseOverBackColor = $hovercolor

$oldpower                        = New-Object system.Windows.Forms.Button
$oldpower.text                   = "Power Panel"
$oldpower.width                  = 220
$oldpower.height                 = 30
$oldpower.location               = New-Object System.Drawing.Point(0,395)
$oldpower.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$oldpower.BackColor              = $frontcolor 
$oldpower.ForeColor              = $backcolor
$oldpower.FlatStyle              = "Flat"
$oldpower.FlatAppearance.MouseOverBackColor = $hovercolor

#######################################################################################################
# Old menus ends here
#######################################################################################################
# Windows update starts here
#######################################################################################################

$windowsupdate                   = New-Object system.Windows.Forms.Label
$windowsupdate.text              = "Windows Update"
$windowsupdate.AutoSize          = $false
$windowsupdate.width             = 220
$windowsupdate.height            = 35
$windowsupdate.TextAlign         = "MiddleCenter"
$windowsupdate.location          = New-Object System.Drawing.Point(0,10)
$windowsupdate.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$windowsupdate.ForeColor         = $frontcolor 

$defaultwindowsupdate            = New-Object system.Windows.Forms.Button
$defaultwindowsupdate.text       = "Default Settings"
$defaultwindowsupdate.width      = 220
$defaultwindowsupdate.height     = 30
$defaultwindowsupdate.location   = New-Object System.Drawing.Point(0,45)
$defaultwindowsupdate.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$defaultwindowsupdate.BackColor  = $frontcolor 
$defaultwindowsupdate.ForeColor  = $backcolor
$defaultwindowsupdate.FlatStyle  = "Flat"
$defaultwindowsupdate.FlatAppearance.MouseOverBackColor = $hovercolor


$securitywindowsupdate           = New-Object system.Windows.Forms.Button
$securitywindowsupdate.text      = "Security Updates Only"
$securitywindowsupdate.width     = 220
$securitywindowsupdate.height    = 30
$securitywindowsupdate.location  = New-Object System.Drawing.Point(0,80)
$securitywindowsupdate.Font      = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$securitywindowsupdate.BackColor = $frontcolor 
$securitywindowsupdate.ForeColor = $backcolor
$securitywindowsupdate.FlatStyle = "Flat"
$securitywindowsupdate.FlatAppearance.MouseOverBackColor = $hovercolor


$windowsupdatefix                = New-Object system.Windows.Forms.Button
$windowsupdatefix.text           = "Windows Update Reset"
$windowsupdatefix.width          = 220
$windowsupdatefix.height         = 30
$windowsupdatefix.location       = New-Object System.Drawing.Point(0,115)
$windowsupdatefix.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$windowsupdatefix.BackColor      = $frontcolor 
$windowsupdatefix.ForeColor      = $backcolor
$windowsupdatefix.FlatStyle      = "Flat"
$windowsupdatefix.FlatAppearance.MouseOverBackColor = $hovercolor


#######################################################################################################
# Windows update ends here
#######################################################################################################
# Microsoft store starts here
#######################################################################################################

$microsoftstore                  = New-Object system.Windows.Forms.Label
$microsoftstore.text             = "Microsoft Store"
$microsoftstore.AutoSize         = $false
$microsoftstore.width            = 220
$microsoftstore.height           = 35
$microsoftstore.TextAlign        = "MiddleCenter"
$microsoftstore.ForeColor        = $frontcolor 
$microsoftstore.location         = New-Object System.Drawing.Point(0,150)
$microsoftstore.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$removebloat                     = New-Object system.Windows.Forms.Button
$removebloat.text                = "Remove MS Store Apps"
$removebloat.width               = 220
$removebloat.height              = 30
$removebloat.location            = New-Object System.Drawing.Point(0,185)
$removebloat.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$removebloat.BackColor           = $frontcolor 
$removebloat.ForeColor           = $backcolor
$removebloat.FlatStyle           = "Flat"
$removebloat.FlatAppearance.MouseOverBackColor = $hovercolor

$reinstallbloat                  = New-Object system.Windows.Forms.Button
$reinstallbloat.text             = "Reinstall MS Store Apps"
$reinstallbloat.width            = 220
$reinstallbloat.height           = 30
$reinstallbloat.location         = New-Object System.Drawing.Point(0,220)
$reinstallbloat.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$reinstallbloat.BackColor        = $frontcolor 
$reinstallbloat.ForeColor        = $backcolor
$reinstallbloat.FlatStyle        = "Flat"
$reinstallbloat.FlatAppearance.MouseOverBackColor = $hovercolor

#######################################################################################################
# Microsoft store ends here
#######################################################################################################
# Cleaning starts here
#######################################################################################################

$cleaning                        = New-Object system.Windows.Forms.Label
$cleaning.text                   = "Cleaning"
$cleaning.AutoSize               = $false
$cleaning.width                  = 220
$cleaning.height                 = 35
$cleaning.TextAlign              = "MiddleCenter"
$cleaning.ForeColor              = $frontcolor 
$cleaning.location               = New-Object System.Drawing.Point(0,255)
$cleaning.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$ultimateclean                   = New-Object system.Windows.Forms.Button
$ultimateclean.text              = "Ultimate Cleaning (needs to display output somewhereelse)"
$ultimateclean.width             = 220
$ultimateclean.height            = 30
$ultimateclean.location          = New-Object System.Drawing.Point(0,290)
$ultimateclean.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$ultimateclean.BackColor         = $frontcolor 
$ultimateclean.ForeColor         = $backcolor
$ultimateclean.FlatStyle         = "Flat"
$ultimateclean.FlatAppearance.MouseOverBackColor = $hovercolor

#######################################################################################################
# Cleaning ends here
#######################################################################################################
# Power options starts here
#######################################################################################################

$poweroptions                    = New-Object system.Windows.Forms.Label
$poweroptions.text               = "Power Options"
$poweroptions.AutoSize           = $false
$poweroptions.width              = 220
$poweroptions.height             = 35
$poweroptions.TextAlign          = "MiddleCenter"
$poweroptions.ForeColor          = $frontcolor 
$poweroptions.location           = New-Object System.Drawing.Point(0,325)
$poweroptions.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$ultimatepower                   = New-Object system.Windows.Forms.Button
$ultimatepower.text              = "Ultimate Power Plan"
$ultimatepower.width             = 220
$ultimatepower.height            = 30
$ultimatepower.location          = New-Object System.Drawing.Point(0,360)
$ultimatepower.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$ultimatepower.BackColor         = $frontcolor 
$ultimatepower.ForeColor         = $backcolor
$ultimatepower.FlatStyle         = "Flat"
$ultimatepower.FlatAppearance.MouseOverBackColor = $hovercolor

$restorepower                    = New-Object system.Windows.Forms.Button
$restorepower.text               = "Restore Power Options"
$restorepower.width              = 220
$restorepower.height             = 30
$restorepower.location           = New-Object System.Drawing.Point(0,395)
$restorepower.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$restorepower.BackColor          = $frontcolor 
$restorepower.ForeColor          = $backcolor
$restorepower.FlatStyle          = "Flat"
$restorepower.FlatAppearance.MouseOverBackColor = $hovercolor

#######################################################################################################
# Power options ends here
#######################################################################################################
# Extras starts here
#######################################################################################################

$extras                          = New-Object system.Windows.Forms.Label
$extras.text                     = "Extras"
$extras.AutoSize                 = $false
$extras.width                    = 220
$extras.height                   = 35
$extras.TextAlign                = "MiddleCenter"
$extras.location                 = New-Object System.Drawing.Point(0,10)
$extras.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$extras.ForeColor                = $frontcolor 

$getosinfo                       = New-Object system.Windows.Forms.Button
$getosinfo.text                  = "OS Info"
$getosinfo.width                 = 220
$getosinfo.height                = 30
$getosinfo.location              = New-Object System.Drawing.Point(0,45)
$getosinfo.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$getosinfo.BackColor             = $frontcolor 
$getosinfo.ForeColor             = $backcolor
$getosinfo.FlatStyle             = "Flat"
$getosinfo.FlatAppearance.MouseOverBackColor = $hovercolor

$EClipboardHistory               = New-Object system.Windows.Forms.Button
$EClipboardHistory.text          = "Enable Clipboard History"
$EClipboardHistory.width         = 220
$EClipboardHistory.height        = 30
$EClipboardHistory.location      = New-Object System.Drawing.Point(0,80)
$EClipboardHistory.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$EClipboardHistory.BackColor     = $frontcolor 
$EClipboardHistory.ForeColor     = $backcolor
$EClipboardHistory.FlatStyle     = "Flat"
$EClipboardHistory.FlatAppearance.MouseOverBackColor = $hovercolor

$ELocation                       = New-Object system.Windows.Forms.Button
$ELocation.text                  = "Enable Location Tracking"
$ELocation.width                 = 220
$ELocation.height                = 30
$ELocation.location              = New-Object System.Drawing.Point(0,115)
$ELocation.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$ELocation.BackColor             = $frontcolor 
$ELocation.ForeColor             = $backcolor
$ELocation.FlatStyle             = "Flat"
$ELocation.FlatAppearance.MouseOverBackColor = $hovercolor

$EHibernation                    = New-Object system.Windows.Forms.Button
$EHibernation.text               = "Enable Hibernation"
$EHibernation.width              = 220
$EHibernation.height             = 30
$EHibernation.location           = New-Object System.Drawing.Point(0,150)
$EHibernation.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$EHibernation.BackColor          = $frontcolor 
$EHibernation.ForeColor          = $backcolor
$EHibernation.FlatStyle          = "Flat"
$EHibernation.FlatAppearance.MouseOverBackColor = $hovercolor

$EActionCenter                   = New-Object system.Windows.Forms.Button
$EActionCenter.text              = "Enable Action Center"
$EActionCenter.width             = 220
$EActionCenter.height            = 30
$EActionCenter.location          = New-Object System.Drawing.Point(0,185)
$EActionCenter.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$EActionCenter.BackColor         = $frontcolor 
$EActionCenter.ForeColor         = $backcolor
$EActionCenter.FlatStyle         = "Flat"
$EActionCenter.FlatAppearance.MouseOverBackColor = $hovercolor

$ECortana                        = New-Object system.Windows.Forms.Button
$ECortana.text                   = "Enable Cortana"
$ECortana.width                  = 220
$ECortana.height                 = 30
$ECortana.location               = New-Object System.Drawing.Point(0,220)
$ECortana.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$ECortana.BackColor              = $frontcolor 
$ECortana.ForeColor              = $backcolor
$ECortana.FlatStyle              = "Flat"
$ECortana.FlatAppearance.MouseOverBackColor = $hovercolor

$dualboottime                    = New-Object system.Windows.Forms.Button
$dualboottime.text               = "Set Time to UTC"
$dualboottime.width              = 220
$dualboottime.height             = 30
$dualboottime.location           = New-Object System.Drawing.Point(0,255)
$dualboottime.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$dualboottime.BackColor          = $frontcolor 
$dualboottime.ForeColor          = $backcolor
$dualboottime.FlatStyle          = "Flat"
$dualboottime.FlatAppearance.MouseOverBackColor = $hovercolor

#######################################################################################################
# Extras ends here
#######################################################################################################
# Visual tweaks starts here
#######################################################################################################

$visualtweaks                    = New-Object system.Windows.Forms.Label
$visualtweaks.text               = "Visual Tweaks"
$visualtweaks.AutoSize           = $false
$visualtweaks.width              = 220
$visualtweaks.height             = 35
$visualtweaks.TextAlign          = "MiddleCenter"
$visualtweaks.ForeColor          = $frontcolor 
$visualtweaks.location           = New-Object System.Drawing.Point(0,290)
$visualtweaks.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$darkmode                        = New-Object system.Windows.Forms.Button
$darkmode.text                   = "Dark Mode"
$darkmode.width                  = 220
$darkmode.height                 = 30
$darkmode.location               = New-Object System.Drawing.Point(0,325)
$darkmode.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$darkmode.BackColor              = $frontcolor 
$darkmode.ForeColor              = $backcolor
$darkmode.FlatStyle              = "Flat"
$darkmode.FlatAppearance.MouseOverBackColor = $hovercolor

$lightmode                       = New-Object system.Windows.Forms.Button
$lightmode.text                  = "Light Mode"
$lightmode.width                 = 220
$lightmode.height                = 30
$lightmode.location              = New-Object System.Drawing.Point(0,360)
$lightmode.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
$lightmode.BackColor             = $frontcolor 
$lightmode.ForeColor             = $backcolor
$lightmode.FlatStyle             = "Flat"
$lightmode.FlatAppearance.MouseOverBackColor = $hovercolor

if ((Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect") -eq '1') {
    $performancefx                   = New-Object system.Windows.Forms.Button
    $performancefx.text              = "Optimize Performance"
    $performancefx.width             = 220
    $performancefx.height            = 30
    $performancefx.location          = New-Object System.Drawing.Point(0,395)
    $performancefx.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
    $performancefx.BackColor         = $frontcolor 
    $performancefx.ForeColor         = $backcolor
    $performancefx.FlatStyle         = "Flat"
    $performancefx.FlatAppearance.MouseOverBackColor = $hovercolor
} elseif ((Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect") -eq '0') {
    $appearancefx                    = New-Object system.Windows.Forms.Button
    $appearancefx.text               = "Optimize Apperance"
    $appearancefx.width              = 220
    $appearancefx.height             = 30
    $appearancefx.location           = New-Object System.Drawing.Point(0,395)
    $appearancefx.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',12)
    $appearancefx.BackColor          = $frontcolor 
    $appearancefx.ForeColor          = $backcolor
    $appearancefx.FlatStyle          = "Flat"
    $appearancefx.FlatAppearance.MouseOverBackColor = $hovercolor
}

#######################################################################################################
# Visual tweaks ends here
#######################################################################################################
# Result/Current Status box starts here
#######################################################################################################
$currentstatus                   = New-Object system.Windows.Forms.Label
$currentstatus.text              = "* Current Status *"
$currentstatus.AutoSize          = $true
$currentstatus.width             = 25
$currentstatus.height            = 10
$currentstatus.location          = New-Object System.Drawing.Point(350,455)
$currentstatus.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',24)

$ResultText                      = New-Object system.Windows.Forms.TextBox
$ResultText.multiline            = $true
$ResultText.ReadOnly             = $true
$ResultText.AutoSize             = $true
$ResultText.width                = 910
$ResultText.height               = 100
$ResultText.location             = New-Object System.Drawing.Point(0, 0)
$ResultText.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$ResultText.BorderStyle          = "FixedSingle"
$ResultText.BackColor            = $backcolor 
$ResultText.ForeColor            = $frontcolor 

#######################################################################################################
# Result/Current Status box ends here
#######################################################################################################

$Form.controls.AddRange(@(
    $Panel1, 
    $Panel2, 
    $Panel3, 
    $Panel4, 
    $Panel5
))

$Panel1.controls.AddRange(@(
    $performancetweaks, #header for the bellow selection
    $essentialtweaks,
    $essentialundo,
    $gamingtweaks,
    $securitypatches, 
    $onedrive,
    $InstallOneDrive,
    $killedge
))

$Panel2.controls.AddRange(@(
    $fixes,
    $ncpa,
    $oldcontrolpanel,
    $oldsoundpanel,
    $oldsystempanel,
    $oldpower,
    $errorscanner,
    $changedns,
    $oldmenu,
    $resetnetwork,
    $laptopnumlock,
    $removeENkeyboard
))

$Panel3.controls.AddRange(@(
    $defaultwindowsupdate,
    $securitywindowsupdate,
    $windowsupdatefix,
    $removebloat,
    $reinstallbloat,
    $windowsupdate,
    $microsoftstore,
    $cleaning,
    $ultimateclean,
    $poweroptions, 
    $ultimatepower,
    $restorepower
))

$Panel4.controls.AddRange(@(
    $extras,#header for the bellow selection
    $getosinfo,
    $EClipboardHistory,
    $ELocation,
    $EHibernation,
    $dualboottime,
    $EActionCenter,
    $ECortana,
    $visualtweaks,#header for the bellow selection
    $darkmode,
    $lightmode,
    $performancefx,
    $appearancefx
))

$Panel5.controls.AddRange(@(
    $ResultText
    #$currentstatus
))


##DNS CHANGER TEST HERE
$changedns.Add_Click({
If ( $changedns.text -eq 'Google' ) { 
    $ResultText.text = "`r`n" +"  Setting DNS to Google for all connections..."
    $DC = "8.8.8.8"
    $Internet = "8.8.4.4"
    $dns = "$DC", "$Internet"
    $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
    $Interfaces.SetDNSServerSearchOrder($dns) | Out-Null
}
If ( $changedns.text -eq 'Cloud Flare' ) { 
    $ResultText.text = "`r`n" +"  Setting DNS to Cloud Flare for all connections..."
    $DC = "1.1.1.1"
    $Internet = "1.0.0.1"
    $dns = "$DC", "$Internet"
    $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
    $Interfaces.SetDNSServerSearchOrder($dns) | Out-Null
}
If ( $changedns.text -eq 'Level3' ) { 
    $ResultText.text = "`r`n" +"  Setting DNS to Level3 for all connections..."
    $DC = "4.2.2.2"
    $Internet = "4.2.2.1"
    $dns = "$DC", "$Internet"
    $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
    $Interfaces.SetDNSServerSearchOrder($dns) | Out-Null
}
If ( $changedns.text -eq 'Open DNS' ) { 
    $ResultText.text = "`r`n" +"  Setting DNS to Open DNS for all connections..."
    $DC = "208.67.222.222"
    $Internet = "208.67.220.220"
    $dns = "$DC", "$Internet"
    $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
    $Interfaces.SetDNSServerSearchOrder($dns) | Out-Null
}
})

$EActionCenter.Add_Click({
    $ResultText.text = "`r`n" +"  Trying to re-enable Action Center..."

    Stop-Process -ProcessName explorer -Force	
    taskkill /F /IM explorer.exe
    Start-Sleep -Seconds 3

	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue

    Start-Process explorer.exe	

    $ResultText.text = "`r`n" + "  Action Center has been successfully re-enabled..."
})

$ECortana.Add_Click({
    $ResultText.text = "`r`n" +"  Trying to re-enable Cortana..."

    Stop-Process -ProcessName explorer -Force	
    taskkill /F /IM explorer.exe
    Start-Sleep -Seconds 3

	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -ErrorAction SilentlyContinue
	If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore")) {
		New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Force | Out-Null
	}
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type DWord -Value 0
	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ErrorAction SilentlyContinue
    $ResultText.text = "`r`n" + "  Restoring Windows Search..."
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value "1"
	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -ErrorAction SilentlyContinue
    $ResultText.text = "`r`n" + "  Restoring and Starting Windows Search Service..."
    Set-Service "WSearch" -StartupType Automatic
    Start-Service "WSearch" -WarningAction SilentlyContinue
    $ResultText.text = "`r`n" + "  Restoring Windows Search taskbar widget..."
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 1
    
    Start-Process explorer.exe	

    $ResultText.text = "`r`n" + "  Cortana has been successfully re-enabled..."
})


$getosinfo.Add_Click({
    $ResultText.text = "`r`n" + "  Gathering data please wait for the data to show up..."

    $name=(Get-WmiObject Win32_OperatingSystem).caption
    $bit=(Get-WmiObject Win32_OperatingSystem).OSArchitecture
    $ver=(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    $myIP=(Invoke-WebRequest -uri "https://api.ipify.org/").Content
    $licence=(Get-WmiObject -query "select * from SoftwareLicensingService").OA3xOriginalProductKey

    $ResultText.text =  "`r`n" + 
                        "  Username: " + $env:UserName + "`r`n" + 
                        "  OS: " + $name, " Build: " + $ver, "Arch: " + $bit, "`r`n" + 
                        "  External IP: " + $myIP, "`r`n" + 
                        "  Licence: " + $licence
})
    
$errorscanner.Add_Click({
    $ResultText.text = "`r`n" + "  System error scan has started, select your options then, Please Wait..." 
    
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

        $sfcscando = [System.Windows.Forms.MessageBox]::Show('This may take a while, are you sure?' , "Run SFC Scan now?" , 4)
        if ($sfcscando -eq 'Yes') {
            $sfcscan = {
                $name='SFC Scannow - Offload Process'
                $host.ui.RawUI.WindowTitle = $name
                cmd /c sfc /scannow
                $ResultText.text = "`r`n" + "  SFC scan is now running, you can abort the process but it's not recommended.." 
            }

            Start-Process cmd.exe -ArgumentList "-NoLogo -NoProfile -ExecutionPolicy ByPass $sfcscan"
        }

        $dismscansinit = [System.Windows.Forms.MessageBox]::Show('This may take a while, are you sure?' , "Initiate DISM Scans?" , 4)
        if ($dismscansinit -eq 'Yes') { 
            $dismscan = {
                $name='DISM Error Scanner - Offload Process'
                $host.ui.RawUI.WindowTitle = $name
                cmd /c DISM /Online /Cleanup-Image /ScanHealth
                cmd /c DISM /Online /Cleanup-Image /CheckHealth
                cmd /c DISM /Online /Cleanup-Image /RestoreHealth
                $ResultText.text = "`r`n" + "  DISM Scan, Check and Restore Health are now running, you can abort the process but it's not recommended.. (Restart after completion)" 
            }

            Start-Process cmd.exe -ArgumentList "-NoLogo -NoProfile -ExecutionPolicy ByPass $dismscan"
        }
    
    if($?) { $ResultText.text = "`r`n" + "  System error scans has been initiated wait for it to complete then do a restart -  Ready for Next Task..." }
})


$ultimateclean.Add_Click({
	
    $ResultText.text = "`r`n" + "  Cleaning initiated.." 

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    $componentcache = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Clean the component cache that is used by Windows Store?" , 4)
    if ($componentcache -eq 'Yes') {
        vssadmin delete shadows /all | Out-Null
        Checkpoint-Computer -Description "Windows_Optimisation_Pack Cleaner" -RestorePointType MODIFY_SETTINGS 
        $Key = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches
        ForEach($result in $Key)
        {If($result.name -eq "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\DownloadsFolder"){}Else{
        $Regkey = 'HKLM:' + $result.Name.Substring( 18 )
        New-ItemProperty -Path $Regkey -Name 'StateFlags0001' -Value 2 -PropertyType DWORD -Force -EA 0 | Out-Null}}
        cmd /c DISM /Online /Cleanup-Image /AnalyzeComponentStore
        cmd /c DISM /Online /Cleanup-Image /spsuperseded
        cmd /c DISM /Online /Cleanup-Image /StartComponentCleanup
        Clear-BCCache -Force -ErrorAction SilentlyContinue
        $ResultText.text = "`r`n" + "  Component Store Caches have been cleared successfully..." 
    }

    $regcachclean = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Clean up a collection of useless registry files?" , 4)
    if ($regcachclean -eq 'Yes') {
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Managed\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Unmanaged\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\usbflags\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Nla\Cache\Intranet\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose 
        
        Stop-Process -ProcessName explorer -Force	
        taskkill /F /IM explorer.exe
        Start-Sleep -Seconds 3
                
        Remove-Item -Path "$env:LocalAppData\Microsoft\Windows\Explorer" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "$env:LocalAppData\Microsoft\Windows\Recent" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "$env:LocalAppData\Microsoft\Windows\Recent\AutomaticDestinations" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "$env:LocalAppData\Microsoft\Windows\Recent\CustomDestinations" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

        Start-Process explorer.exe	

        $ResultText.text = "`r`n" + "  Windows registry junk files deleted successfully..." 
    }

    $Users = Get-ChildItem "$env:systemdrive\Users" | Select-Object Name
    $users = $Users.Name 

    # Clear Inetpub Logs Folder
    if (Test-Path "C:\inetpub\logs\LogFiles\") {
        $ResultText.text = "`r`n" + "  Clearing Inetpub Logs Folder..." 
        $Folders = Get-ChildItem -Path "C:\inetpub\logs\LogFiles\" | Select-Object Name
        foreach ($Folder in $Folders) {
            $folder = $Folder.Name
            Remove-Item -Path "C:\inetpub\logs\LogFiles\$Folder\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        }
        $ResultText.text = "`r`n" + "  Deleted Inetpub Logs Folder..." 
    }

    if (Test-Path "$env:LocalAppData\Microsoft\Teams\") {
        # Delete Microsoft Teams Previous Version files
        $ResultText.text = "`r`n" + " Clearing Microsoft Teams previous versions..." 
        Foreach ($user in $Users) {
            if (Test-Path "C:\Users\$user\AppData\Local\Microsoft\Teams\") {
                Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Teams\previous\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Teams\stage\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            } 
        }
        $ResultText.text = "`r`n" + "  Deleted old Microsoft Teams versions..." 
    }

    if (Test-Path "$env:LocalAppData\TechSmith\SnagIt") {
        # Delete SnagIt Crash Dump files
        $ResultText.text = "`r`n" + " Clearing SnagIt crash dumps..." 
        Foreach ($user in $Users) {
            if (Test-Path "C:\Users\$user\AppData\Local\TechSmith\SnagIt") {
                Remove-Item -Path "C:\Users\$user\AppData\Local\TechSmith\SnagIt\CrashDumps\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            } 
        }
        
        $ResultText.text = "`r`n" + "  Deleted SnagIt crash dumps..." 
    }

    if (!(Test-Path "C:\Program Files (x86)\Dropbox\Client")){
        $ResultText.text = "`r`n" + " Dropbox is not installed & Folders can't be found.. Skipping clean..." 
    }  
    else {
        $Dropboxclean = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Delete all Dropbox Caches?" , 4)
        if ($Dropboxclean -eq 'Yes') {
            # Clear Dropbox
            $ResultText.text = "`r`n" + " Clearing Dropbox Cache..." 
            Foreach ($user in $Users) {
                if (Test-Path "C:\Users\$user\Dropbox\") {
                    Remove-Item -Path "C:\Users\$user\Dropbox\.dropbox.cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                    Remove-Item -Path "C:\Users\$user\Dropbox*\.dropbox.cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                }
            }
            $ResultText.text = "`r`n" + "  Dropbox caches deleted..." 
        }
    }

    # Clear HP Support Assistant Installation Folder
    if (Test-Path "C:\swsetup") {
        Remove-Item -Path "C:\swsetup" -Force -ErrorAction SilentlyContinue -Verbose
    } 

    $DeleteOldDownloads = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Delete User files from Download folder?" , 4)
    # Delete files from Downloads folder
    if ($DeleteOldDownloads -eq 'Yes') { 
        $ResultText.text = "`r`n" + " Deleting files from User Downloads folder..." 
        Foreach ($user in $Users) {
            $UserDownloads = "C:\Users\$user\Downloads"
            $OldFiles = Get-ChildItem -Path "$UserDownloads\" -Recurse -File -ErrorAction SilentlyContinue
            foreach ($file in $OldFiles) {
                Remove-Item -Path "$UserDownloads\$file" -Force -ErrorAction SilentlyContinue -Verbose
            }
        }
        $ResultText.text = "`r`n" + "  All files in the user download folder have been deleted..." 
    }

    # Delete files from Azure Log folder
    if (Test-Path "C:\WindowsAzure\Logs") {
        $ResultText.text = "`r`n" + " Deleting files from Azure Log folder..." 
        $AzureLogs = "C:\WindowsAzure\Logs"
        $OldFiles = Get-ChildItem -Path "$AzureLogs\" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $OldFiles) {
            Remove-Item -Path "$AzureLogs\$file" -Force -ErrorAction SilentlyContinue -Verbose
        }
        $ResultText.text = "`r`n" + "  Azure log files removed..." 
    } 

    if (Test-Path "$env:LocalAppData\Microsoft\Office") {
        # Delete files from Office Cache Folder
        $ResultText.text = "`r`n" + "  Clearing Office Cache Folder..." 
        Foreach ($user in $Users) {
            $officecache = "C:\Users\$user\AppData\Local\Microsoft\Office\16.0\GrooveFileCache"
            if (Test-Path $officecache) {
                $OldFiles = Get-ChildItem -Path "$officecache\" -Recurse -File -ErrorAction SilentlyContinue
                foreach ($file in $OldFiles) {
                    Remove-Item -Path "$officecache\$file" -Force -ErrorAction SilentlyContinue -Verbose
                }
            } 
        }
        $ResultText.text = "`r`n" + "  Office cache has been cleared..." 
    }

    # Delete files from LFSAgent Log folder https://www.lepide.com/
    if (Test-Path "$env:windir\LFSAgent\Logs") {
        $ResultText.text = "`r`n" + "  Deleting files from LFSAgent Log folder..." 
        $LFSAgentLogs = "$env:windir\LFSAgent\Logs"
        $OldFiles = Get-ChildItem -Path "$LFSAgentLogs\" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($file in $OldFiles) {
            Remove-Item -Path "$LFSAgentLogs\$file" -Force -ErrorAction SilentlyContinue -Verbose
        }
        $ResultText.text = "`r`n" + "  LFSAgent log folder has been deleted..." 
    }         

    # Delete SOTI MobiController Log files
    if (Test-Path "C:\Program Files (x86)\SOTI\MobiControl") {
        $ResultText.text = "`r`n" + "  Deleting SOTI MobiController Log files..." 
        $SotiLogFiles = Get-ChildItem -Path "C:\Program Files (x86)\SOTI\MobiControl" | Where-Object { ($_.name -like "*Device*.log" -or $_.name -like "*Server*.log" ) }
        foreach ($File in $SotiLogFiles) {
            Remove-Item -Path "C:\Program Files (x86)\SOTI\MobiControl\$($file.name)" -Force -ErrorAction SilentlyContinue -Verbose
        }
        $ResultText.text = "`r`n" + "  SOTI MobiController log files removed..." 
    }

    # Delete old Cylance Log files
    if (Test-Path "C:\Program Files\Cylance\Desktop") {
        $ResultText.text = "`r`n" + "  Deleting Cylance Log files..." 
        $OldCylanceLogFiles = Get-ChildItem -Path "C:\Program Files\Cylance\Desktop" | Where-Object name -Like "cylog-*.log"
        foreach ($File in $OldCylanceLogFiles) {
            Remove-Item -Path "C:\Program Files\Cylance\Desktop\$($file.name)" -Force -ErrorAction SilentlyContinue -Verbose
        }
        $ResultText.text = "`r`n" + "  Cylance log files deleted..." 
    }


    $CleanKnownTemp = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Clear all System, User and Common Temp Files?" , 4)
    if ($CleanKnownTemp -eq 'Yes') {
        # Clear User Temp Folders
        $ResultText.text = "`r`n" + "  Clearing User Temp Folders..." 
        Foreach ($user in $Users) {
            Remove-Item -Path "$env:systemdrive\Users\$user\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "$env:systemdrive\Users\$user\AppData\Local\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "$env:systemdrive\Users\$user\AppData\Local\Microsoft\Windows\AppCache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "$env:systemdrive\Users\$user\cookies\*.*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "$env:systemdrive\Users\$user\Local Settings\Temporary Internet Files\*.*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "$env:systemdrive\Users\$user\recent\*.*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        }

        # Clear Windows Temp Folder
        $ResultText.text = "`r`n" + "  Clearing Windows Temp, Logs and Prefetch Folders..." 
        Remove-Item -Path "$env:systemdrive\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "$env:windir\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "$env:windir\Logs\CBS\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "$env:ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "$env:systemdrive\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        #old above -- bellow is test
        Get-ChildItem -Path $env:temp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse 
        Get-ChildItem -Path $env:windir\Temp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse 
        Get-ChildItem -Path $env:windir\Prefetch -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse 
        Get-ChildItem -Path $env:SystemRoot\SoftwareDistribution\Download -Recurse -Force | Remove-Item -Recurse -Force
        Get-ChildItem -Path $env:ProgramData\Microsoft\Windows\RetailDemo -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse
        Get-ChildItem -Path $env:LOCALAPPDATA\AMD -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse
        Get-ChildItem -Path $env:windir/../AMD/ -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse 
        Get-ChildItem -Path $env:LOCALAPPDATA\NVIDIA\DXCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse
        Get-ChildItem -Path $env:LOCALAPPDATA\NVIDIA\GLCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse
        Get-ChildItem -Path $env:APPDATA\..\locallow\Intel\ShaderCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse

        Start-Process cleanmgr.exe /sagerun:1 -Wait

        # Only grab log files sitting in the root of the Logfiles directory
        $Sys32Files = Get-ChildItem -Path "$env:windir\System32\LogFiles" | Where-Object { ($_.name -like "*.log")}
        foreach ($File in $Sys32Files) {
            Remove-Item -Path "$env:windir\System32\LogFiles\$($file.name)" -Force -ErrorAction SilentlyContinue -Verbose
        }

        $ResultText.text = "`r`n" + "  All System, User and Common Temp Files have been deleted successfully..." 
    }     

     # Get the size of the Windows Updates folder (SoftwareDistribution)
     $WUfoldersize = (Get-ChildItem "$env:windir\SoftwareDistribution" -Recurse | Measure-Object Length -s).sum / 1Gb

     # Ask the user if they would like to clean the Windows Update folder
     if ($WUfoldersize -gt 0.5) {
         $ResultText.text = "`r`n" + "  The Software Distribution folder is", ("{0:N2} GB" -f $WUFoldersize) 
         $CleanWU = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Do you want clean the Software Distribution folder?" , 4)
     }

    if ($CleanWU -eq 'Yes') { 
        $ResultText.text = "`r`n" + "  Restarting Windows Update Service and Deleting SoftwareDistribution Folder"
        # Stop the Windows Update service
        try {
            Stop-Service -Name wuauserv
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "$ErrorMessage" 
        }
        # Delete the folder
        Remove-Item "$env:windir\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Start-Sleep -s 3

        # Start the Windows Update service
        try {
            Start-Service -Name wuauserv
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "$ErrorMessage" 
        }
        $ResultText.text = "`r`n" + "  SoftwareDistribution folder removed, reinitiate Windows Update to reaquire updates..." 
    }

    $CleanBin = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Would you like to empty the Recycle Bin for All Users?" , 4)
    if ($Cleanbin -eq 'Yes') {
        $ResultText.text = "`r`n" + "  Cleaning Recycle Bin..." 
        $ErrorActionPreference = 'SilentlyContinue'
        $RecycleBin = "C:\`$Recycle.Bin"
        $BinFolders = Get-ChildItem $RecycleBin -Directory -Force

        Foreach ($Folder in $BinFolders) {
            # Translate the SID to a User Account
            $objSID = New-Object System.Security.Principal.SecurityIdentifier ($folder)
            try {
                $objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
                $ResultText.text = "`r`n" + "  Cleaning $objUser Recycle Bin..." 
            }
            # If SID cannot be Translated, Throw out the SID instead of error
            catch {
                $objUser = $objSID.Value
                $ResultText.text = "`r`n" + "  $objUser"
            }
            $Files = @()

            if ($PSVersionTable.PSVersion -Like "*2*") {
                $Files = Get-ChildItem $Folder.FullName -Recurse -Force
            }
            else {
                $Files = Get-ChildItem $Folder.FullName -File -Recurse -Force
                $Files += Get-ChildItem $Folder.FullName -Directory -Recurse -Force
            }

            $FileTotal = $Files.Count

            for ($i = 1; $i -le $Files.Count; $i++) {
                $FileName = Select-Object -InputObject $Files[($i - 1)]
                Write-Progress -Activity "Recycle Bin Clean-up" -Status "Attempting to Delete File [$i / $FileTotal]: $FileName" -PercentComplete (($i / $Files.count) * 100) -Id 1
                Remove-Item -Path $Files[($i - 1)].FullName -Recurse -Force
            }
            Write-Progress -Activity "Recycle Bin Clean-up" -Status "Complete" -Completed -Id 1
        }
        $ResultText.text = "`r`n" + "  Recycle Bin has been emptied..." 
    }
    
    $SuperCleanOffload = [System.Windows.Forms.MessageBox]::Show('This may take over an hour to complete, are you sure you want to continue?' , "Launch Superdeep Cleaner?" , 4)
    if ($SuperCleanOffload -eq 'Yes') {

         $OffloadScript = {
            $name='Superdeep Cleaner - Offload Process'
            $host.ui.RawUI.WindowTitle = $name
            $ResultText.text = "`r`n" + "  This offload process makes the WinTool app not crash..." 
            $ResultText.text = "`r`n" + "  Deleting temporary system files that can be hard to remove, also removes Windows.old folder if it exists..." 
            cmd /C del /f /s /q %systemdrive%\*.tmp
            cmd /C del /f /s /q %systemdrive%\*._mp
            cmd /C del /f /s /q %systemdrive%\*.log
            cmd /C del /f /s /q %systemdrive%\*.gid
            cmd /C del /f /s /q %systemdrive%\*.chk
            cmd /C del /f /s /q %systemdrive%\*.old
            cmd /C del /f /s /q %windir%\*.bak
            cmd /C del /f /s /q %systemdrive%\Windows.old
        }
       
        Start-Process powershell.exe -ArgumentList "-NoLogo -NoProfile -ExecutionPolicy ByPass $OffloadScript"

        $ResultText.text = "`r`n" + "  Clearing Temporary hidden system files, a new window will open, let that run in the background..." 
    }
    $ResultText.text = "`r`n" + "  Cleaning process has been completed - Ready for Next Task..." 
})

$ultimatepower.Add_Click({
    $ResultText.text = "`r`n" + "  Enabling and Activating Highest Performance Power Plan..."
	Invoke-WebRequest -Uri "https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/Files/Bitsum-Highest-Performance.pow" -OutFile "$Env:windir\system32\Bitsum-Highest-Performance.pow" -ErrorAction SilentlyContinue
	powercfg -import "$Env:windir\system32\Bitsum-Highest-Performance.pow" e6a66b66-d6df-666d-aa66-66f66666eb66 | Out-Null
	powercfg -setactive e6a66b66-d6df-666d-aa66-66f66666eb66 | Out-Null
    $ResultText.text = "`r`n" + "  Enabled & Activated Highest Performance Power Plan - Ready for Next Task..."
})

$laptopnumlock.Add_Click({
    $ResultText.text = "`r`n" + "  Trying to disable numlock by force..."
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 0
    Add-Type -AssemblyName System.Windows.Forms
    If (([System.Windows.Forms.Control]::IsKeyLocked('NumLock'))) {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.SendKeys('{NUMLOCK}')
        $ResultText.text = "`r`n" + "  Numlock bug has been fixed - Ready for Next Task..."
    }
})

$essentialtweaks.Add_Click({
    $ResultText.text = "`r`n" + "  Activating Essential Tweaks... Please Wait"
    $ResultText.text = "`r`n" + "  Creating a restore point incase something bad happens.."
    Enable-ComputerRestore -Drive "C:\"
    Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"

    $ResultText.text += "`r`n" + "  Running O&O Shutup with Recommended Settings"
    Import-Module BitsTransfer
    Start-BitsTransfer -Source "https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/Files/ooshutup10.cfg" -Destination ooshutup10.cfg
    Start-BitsTransfer -Source "https://github.com/alerion921/WinTool-for-10-11/blob/main/Files/OOSU10.exe" -Destination OOSU10.exe
    ./OOSU10.exe ooshutup10.cfg /quiet

    $ResultText.text += "`r`n" + "  Uninstalling Linux Subsystem..."
	If ([System.Environment]::OSVersion.Version.Build -eq 14393) {
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Type DWord -Value 0
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Type DWord -Value 0
	}
	Disable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null

    $ResultText.text += "`r`n" + "  Enabling Windows 10 context menu..."
    New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Name "InprocServer32" -Force
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Type String -Value ""
    
    $ResultText.text += "`r`n" + "  Enabling Custom QOL fixes..."
	New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" | Out-Null
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Type DWord -Value 0 | Out-Null #disable annoying Get even more out of Windows
	Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility" -Name "DynamicScrollbars" -Type DWord -Value 0 #disable Hide Scroll bars
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "SmoothScroll" -Type DWord -Value 0 #disable smooth scrolling 
	Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "TaskbarNoMultimon"
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "TaskbarNoMultimon"
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "MMTaskbarMode" -Type DWord -Value 2 #Show taskbar buttons only on taskbar where window is open

    $ResultText.text += "`r`n" + "  Removing recently added apps from Start Menu..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Type DWord -Value 1 #Disable start menu RecentlyAddedApps

    $ResultText.text += "`r`n" + "  Disabling UAC..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Type DWord -Value 0

    $ResultText.text += "`r`n" + "  Disabling Sticky Keys..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type DWord -Value 506
    
    $ResultText.text += "`r`n" + "  Disabling Telemetry..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\ProgramDataUpdater" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Autochk\Proxy" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" | Out-Null

    $ResultText.text += "`r`n" + "  Disabling Wi-Fi Sense..."
    If (!(Test-Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting")) {
        New-Item -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0

    $ResultText.text += "`r`n" + "  Disabling Application suggestions..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 0
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 1

    $ResultText.text += "`r`n" + "  Disabling Activity History..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 0
    
    $ResultText.text += "`r`n" + "  Disabling Location Tracking..."
    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Deny"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0

    $ResultText.text += "`r`n" + "  Disabling automatic Maps updates..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 0

    $ResultText.text += "`r`n" + "  Disabling Feedback..."
    If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClient" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null

    $ResultText.text += "`r`n" + "  Disabling Tailored Experiences..."
    If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
        New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 1

    $ResultText.text += "`r`n" + "  Disabling Advertising ID..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 1

    $ResultText.text += "`r`n" + "  Disabling Error reporting..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 1
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Windows Error Reporting\QueueReporting" | Out-Null

    $ResultText.text += "`r`n" + "  Restricting Windows Update P2P only to local network..."
    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 1
   
    $ResultText.text += "`r`n" + "  Stopping and disabling Diagnostics Tracking Service..."
    Stop-Service "DiagTrack" -WarningAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled

    $ResultText.text += "`r`n" + "  Stopping and disabling WAP Push Service..."
    Stop-Service "dmwappushservice" -WarningAction SilentlyContinue
    Set-Service "dmwappushservice" -StartupType Disabled

    $ResultText.text += "`r`n" + "  Enabling F8 boot menu options..."
    bcdedit /set `{current`} bootmenupolicy Legacy | Out-Null

    $ResultText.text += "`r`n" + "  Stopping and disabling Home Groups services..."
    Stop-Service "HomeGroupListener" -WarningAction SilentlyContinue
    Set-Service "HomeGroupListener" -StartupType Disabled
    Stop-Service "HomeGroupProvider" -WarningAction SilentlyContinue
    Set-Service "HomeGroupProvider" -StartupType Disabled

    $ResultText.text += "`r`n" + "  Disabling Remote Assistance..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0

    $ResultText.text += "`r`n" + "  Disabling Storage Sense..."
    Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Recurse -ErrorAction SilentlyContinue

    $ResultText.text += "`r`n" + "  Stopping and disabling Superfetch service..."
    Stop-Service "SysMain" -WarningAction SilentlyContinue
    Set-Service "SysMain" -StartupType Disabled

    $ResultText.text += "`r`n" + "  Disabling Hibernation..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -Type Dword -Value 0
    If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 0

    $ResultText.AppendText($ResultText.Text);
    $ResultText.CaretIndex = $ResultText.Text.Length;
    $ResultText.ScrollToEnd();

    $ResultText.text += "`r`n" + "  Showing task manager details..."
    $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
    Do {
        Start-Sleep -Milliseconds 100
        $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
    } Until ($preferences)
    Stop-Process $taskmgr
    $preferences.Preferences[28] = 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -Type Binary -Value $preferences.Preferences

    $ResultText.text += "`r`n" + "  Showing file operations details..."
    If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type DWord -Value 1

    $ResultText.text += "`r`n" + "  Hiding Task View button..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0

    $ResultText.text += "`r`n" + "  Hiding People icon..."
    If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 0

    $ResultText.text += "`r`n" + "  Show tray icons..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Type DWord -Value 1

    $ResultText.text += "`r`n" +"  Disabling Widgets, Chat, Search and Setting Start Button to left side..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0

    $ResultText.text += "`r`n" +"  Disable News and Interests"
    New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 0 -Force

    #Removes Widgets/Split apps bs from taskbar
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Type DWord -Value 0 -Force
    New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Type DWord -Value 0 -Force

    # Removes Chat from the Taskbar
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Type DWord -Value 0 -Force
    New-ItemProperty "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" -Name "ChatIcon" -Type DWord -Value 3 -Force

    # Removes Teams installation aswell
    Get-AppxPackage MicrosoftTeams* | Remove-AppxPackage

    # Default StartMenu alignment 0=Left on win 10
    New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Type DWord -Value 0 -Force

    $ResultText.text += "`r`n" +"  Enabling NumLock after startup..."
    If (!(Test-Path "HKU:")) {
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
    }
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 2147483650
    Add-Type -AssemblyName System.Windows.Forms
    If (!([System.Windows.Forms.Control]::IsKeyLocked('NumLock'))) {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.SendKeys('{NUMLOCK}')
    }

    $ResultText.text += "`r`n" +"  Quality of Life Tweaks"
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1

    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse -ErrorAction SilentlyContinue

	# Network Tweaks
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type DWord -Value 20

    # Group svchost.exe processes
    $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value $ram -Force

    # Remove "News and Interest" from taskbar
    Set-ItemProperty -Path  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 2

    # remove "Meet Now" button from taskbar
    If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force | Out-Null
    }

    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Type DWord -Value 1

    $ResultText.text += "`r`n" +"  Removing AutoLogger file and restricting directory..."
    $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
    If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
        Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
    }
    icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null

    $ResultText.text += "`r`n" +"  Stopping and disabling Diagnostics Tracking Service..."
    Stop-Service "DiagTrack"
    Set-Service "DiagTrack" -StartupType Disabled

    $ResultText.text += "`r`n" +"  Disabling Microsoft Usertracking..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoInstrumentation" -Type DWord -Value 1 #disable microsoft usertracking

    $ResultText.text += "`r`n" +"  Showing known file extensions..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0

    # Service tweaks to Manual 

    $services = @(
    "diagnosticshub.standardcollector.service"   # Microsoft (R) Diagnostics Hub Standard Collector Service
    "DiagTrack"                                  # Diagnostics Tracking Service
    "DPS"
    "dmwappushservice"                           # WAP Push Message Routing Service (see known issues)
    "lfsvc"                                      # Geolocation Service
    "MapsBroker"                                 # Downloaded Maps Manager
    "NetTcpPortSharing"                          # Net.Tcp Port Sharing Service
    "RemoteAccess"                               # Routing and Remote Access
    "RemoteRegistry"                             # Remote Registry
    "SharedAccess"                               # Internet Connection Sharing (ICS)
    "TrkWks"                                     # Distributed Link Tracking Client
    #"WbioSrvc"                                   # Windows Biometric Service (required for Fingerprint reader / facial detection)
    #"WlanSvc"                                    # WLAN AutoConfig
    "WMPNetworkSvc"                              # Windows Media Player Network Sharing Service
    #"wscsvc"                                     # Windows Security Center Service
    "WSearch"                                    # Windows Search
    "XblAuthManager"                             # Xbox Live Auth Manager
    "XblGameSave"                                # Xbox Live Game Save Service
    "XboxNetApiSvc"                              # Xbox Live Networking Service
    "XboxGipSvc"                                 #Disables Xbox Accessory Management Service
    "ndu"                                        # Windows Network Data Usage Monitor
    "WerSvc"                                     #disables windows error reporting
    #"Spooler"                                    #Disables your printer
    "Fax"                                        #Disables fax
    "fhsvc"                                      #Disables fax histroy
    "gupdate"                                    #Disables google update
    "gupdatem"                                   #Disable another google update
    "stisvc"                                     #Disables Windows Image Acquisition (WIA)
    "AJRouter"                                   #Disables (needed for AllJoyn Router Service)
    "MSDTC"                                      # Disables Distributed Transaction Coordinator
    "WpcMonSvc"                                  #Disables Parental Controls
    "PhoneSvc"                                   #Disables Phone Service(Manages the telephony state on the device)
    "PrintNotify"                                #Disables Windows printer notifications and extentions
    "PcaSvc"                                     #Disables Program Compatibility Assistant Service
    "WPDBusEnum"                                 #Disables Portable Device Enumerator Service
    #"LicenseManager"                             #Disable LicenseManager(Windows store may not work properly)
    "seclogon"                                   #Disables  Secondary Logon(disables other credentials only password will work)
    "SysMain"                                    #Disables sysmain
    "lmhosts"                                    #Disables TCP/IP NetBIOS Helper
    "wisvc"                                      #Disables Windows Insider program(Windows Insider will not work)
    "FontCache"                                  #Disables Windows font cache
    "RetailDemo"                                 #Disables RetailDemo whic is often used when showing your device
    "ALG"                                        # Disables Application Layer Gateway Service(Provides support for 3rd party protocol plug-ins for Internet Connection Sharing)
    #"BFE"                                       #Disables Base Filtering Engine (BFE) (is a service that manages firewall and Internet Protocol security)
    #"BrokerInfrastructure"                       #Disables Windows infrastructure service that controls which background tasks can run on the system.
    "SCardSvr"                                    #Disables Windows smart card
    "EntAppSvc"                                   #Disables enterprise application management.
    "BthAvctpSvc"                                 #Disables AVCTP service (if you use  Bluetooth Audio Device or Wireless Headphones. then don't disable this)
    #"FrameServer"                                 #Disables Windows Camera Frame Server(this allows multiple clients to access video frames from camera devices.)
    "Browser"                                     #Disables computer browser
    #"BthAvctpSvc"                                 #AVCTP service (This is Audio Video Control Transport Protocol service.)
    #"BDESVC"                                      #Disables bitlocker
    "iphlpsvc"                                    #Disables ipv6 but most websites don't use ipv6 they use ipv4     
    "edgeupdate"                                  # Disables one of edge update service  
    "MicrosoftEdgeElevationService"               # Disables one of edge  service 
    "edgeupdatem"                                 # disbales another one of update service (disables edgeupdatem)                          
    "SEMgrSvc"                                    #Disables Payments and NFC/SE Manager (Manages payments and Near Field Communication (NFC) based secure elements)
    #"PNRPsvc"                                    # Disables peer Name Resolution Protocol ( some peer-to-peer and collaborative applications, such as Remote Assistance, may not function, Discord will still work)
    #"p2psvc"                                     # Disbales Peer Name Resolution Protocol(nables multi-party communication using Peer-to-Peer Grouping.  If disabled, some applications, such as HomeGroup, may not function. Discord will still work)
    #"p2pimsvc"                                   # Disables Peer Networking Identity Manager (Peer-to-Peer Grouping services may not function, and some applications, such as HomeGroup and Remote Assistance, may not function correctly.Discord will still work)
    "PerfHost"                                    #Disables  remote users and 64-bit processes to query performance .
    "BcastDVRUserService_48486de"                 #Disables GameDVR and Broadcast   is used for Game Recordings and Live Broadcasts
    "CaptureService_48486de"                      #Disables ptional screen capture functionality for applications that call the Windows.Graphics.Capture API.  
    "cbdhsvc_48486de"                             #Disables   cbdhsvc_48486de (clipboard service it disables)
    #"BluetoothUserService_48486de"                #disbales BluetoothUserService_48486de (The Bluetooth user service supports proper functionality of Bluetooth features relevant to each user session.)
    "WpnService"                                  #Disables WpnService (Push Notifications may not work )
    #"StorSvc"                                     #Disables StorSvc (usb external hard drive will not be reconised by windows)
    "RtkBtManServ"                                #Disables Realtek Bluetooth Device Manager Service
    #"QWAVE"                                       #Disables Quality Windows Audio Video Experience (audio and video might sound worse)
     #Hp services
    "HPAppHelperCap"
    "HPDiagsCap"
    "HPNetworkCap"
    "HPSysInfoCap"
    "HpTouchpointAnalyticsService"
    #hyper-v services
     "HvHost"                        
    "vmickvpexchange"
    "vmicguestinterface"
    "vmicshutdown"
    "vmicheartbeat"
    "vmicvmsession"
    "vmicrdv"
    "vmictimesync" 
    # Services which cannot be disabled
    #"WdNisSvc"
)

foreach ($service in $services) {
    # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist
    $ResultText.text += "`r`n" +"  Setting $service StartupType to Manual"
    Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Manual
}

    $ResultText.text += "`r`n" +"  Disabling Cortana..."
    If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Type DWord -Value 0
    If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type DWord -Value 1
    If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Type DWord -Value 0
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type DWord -Value 0

    $ResultText.text += "`r`n" +"  Disabling Background application access..."
    Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Exclude "Microsoft.Windows.Cortana*" | ForEach-Object { #was ForEach
        Set-ItemProperty -Path $_.PsPath -Name "Disabled" -Type DWord -Value 1
        Set-ItemProperty -Path $_.PsPath -Name "DisabledByUser" -Type DWord -Value 1
    }

    $ResultText.text += "`r`n" +"  Disabling Action Center..."
    If (!(Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
        New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessNotifications" -Type "DWORD" -Value 2 -Force
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" -Type "String" -Name Value -Value "DENY" -Force
    
    $ResultText.text += "`r`n" +"  Disabling Notification Area..."
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Type "DWord" -Name "NoAutoTrayNotify" -Value "1" -Force

    $ResultText.text += "`r`n" +"  Changing default Explorer view to This PC..."
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1

    $ResultText.text += "`r`n" +"  Forcing disabling Windows Security Notifications..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Notifications")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Notifications" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Notifications" -Name "DisableNotifications" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Notifications" -Name "DisableEnhancedNotifications" -Type DWord -Value 1
    
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -Name "DisableNotifications" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -Name "DisableEnhancedNotifications" -Type DWord -Value 1

    $ResultText.AppendText($ResultText.Text);
    $ResultText.CaretIndex = $ResultText.Text.Length;
    $ResultText.ScrollToEnd();

    #Restart Explorer so that the taskbar can update and not look break :D
    Stop-Process -name explorer
    Start-Sleep -s 5
    Start-Process -name explorer

    $ResultText.text =  "`r`n" + "  Essential Tweaks Done - Ready for Next Task..."
})

$dualboottime.Add_Click({
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Type DWord -Value 1
    $ResultText.text = "`r`n" + "  Time set to UTC for consistent time in Dual Boot Systems - Ready for Next Task..."
})

$essentialundo.Add_Click({
    $ResultText.text = "`r`n" + "  Creating Restore Point and Reverting Settings..."
    Enable-ComputerRestore -Drive "C:\"
    Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"

    $ResultText.text += "`r`n" +"  Disabling Windows 10 context menu..."
    New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Force

    $ResultText.text += "`r`n" +"  Disabling Custom QOL fixes..."
    Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -ErrorAction SilentlyContinue | Out-Null
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Type DWord -Value 0 | Out-Null -ErrorAction SilentlyContinue #disable annoying Get even more out of Windows
	Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility" -Name "DynamicScrollbars" -Type DWord -Value 1 #disable Hide Scroll bars
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "SmoothScroll" -Type DWord -Value 1 #disable smooth scrolling 
	Add-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "TaskbarNoMultimon" -ErrorAction SilentlyContinue
	Add-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "TaskbarNoMultimon" -ErrorAction SilentlyContinue

    $ResultText.text += "`r`n" +"  Enabling recently added apps from Start Menu..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Type DWord -Value 0

    $ResultText.text += "`r`n" +"  Re-Installing Linux Subsystem..."
	If ([System.Environment]::OSVersion.Version.Build -eq 14393) {
		# 1607 needs developer mode to be enabled
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Type DWord -Value 1
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Type DWord -Value 1
	}
	Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null

    $ResultText.text = "`r`n" + "  Raising UAC level..."
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 5
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Type DWord -Value 1

    $ResultText.text += "`r`n" +"Enabling Sticky Keys..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type DWord -Value 510

    $ResultText.text = "`r`n" + "  Enabling Telemetry..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Enabling Wi-Fi Sense..."
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Enabling Application suggestions..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 1
    If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent") {
        Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Enabling Activity History..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Enable Location Tracking..."
    If (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location") {
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Recurse -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Allow"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Enabling automatic Maps updates..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Enabling Feedback..."
    If (Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules") {
        Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Recurse -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Enabling Tailored Experiences..."
    If (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent") {
        Remove-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Enabling Advertising ID..."
    If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo") {
        Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Recurse -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Allow Error reporting..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Allowing Diagnostics Tracking Service..."
    Stop-Service "DiagTrack" -WarningAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Manual

    $ResultText.text = "`r`n" + "  Enabling Microsoft Usertracking..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoInstrumentation" -Type DWord -Value 0 #disable microsoft usertracking

    $ResultText.text = "`r`n" + "  Allowing WAP Push Service..."
    Stop-Service "dmwappushservice" -WarningAction SilentlyContinue
    Set-Service "dmwappushservice" -StartupType Manual

    $ResultText.text = "`r`n" + "  Allowing Home Groups services..."
    Stop-Service "HomeGroupListener" -WarningAction SilentlyContinue
    Set-Service "HomeGroupListener" -StartupType Manual
    Stop-Service "HomeGroupProvider" -WarningAction SilentlyContinue
    Set-Service "HomeGroupProvider" -StartupType Manual

    $ResultText.text = "`r`n" + "  Enabling Storage Sense..."
    New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" | Out-Null

    $ResultText.text = "`r`n" + "  Allowing Superfetch service..."
    Stop-Service "SysMain" -WarningAction SilentlyContinue
    Set-Service "SysMain" -StartupType Manual

    $ResultText.text = "`r`n" + "  Setting BIOS time to Local Time instead of UTC..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Enabling Hibernation..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -Type Dword -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 1
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -ErrorAction SilentlyContinue

    $ResultText.text = "`r`n" + "  Hiding file operations details..."
    If (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager") {
        Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Recurse -ErrorAction SilentlyContinue
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Showing Task View button..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Changing default Explorer view to Quick Access..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Unrestricting AutoLogger directory..."
    $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
    icacls $autoLoggerDir /grant:r SYSTEM:`(OI`)`(CI`)F | Out-Null

    $ResultText.text = "`r`n" + "  Hiding known file extensions..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Hide tray icons..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Type DWord -Value 1

    $ResultText.text += "`r`n" +"  Re-Enabling Chat, Widgets and Centering Start Menu..."

    # Restores Widgets to the Taskbar
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableFeeds" -Type DWord -Value 1
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue

    # Restores Chat to the Taskbar
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" -Name "ChatIcon" -Type DWord -Value 2

    # Default StartMenu alignment for Win 11 Center = 1
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Type DWord -Value 1
    
    # Recovers search to the Taskbar
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 2

    $ResultText.text = "`r`n" + "  Raising UAC level..."
	Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Exclude "Microsoft.Windows.Cortana*" | ForEach-Object { #was ForEach
		Remove-ItemProperty -Path $_.PsPath -Name "Disabled" -ErrorAction SilentlyContinue
		Remove-ItemProperty -Path $_.PsPath -Name "DisabledByUser" -ErrorAction SilentlyContinue
	}

    $ResultText.text = "`r`n" + "  Enabling Cortana..."
	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -ErrorAction SilentlyContinue
	If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore")) {
		New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Force | Out-Null
	}
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type DWord -Value 0
	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -ErrorAction SilentlyContinue
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value "1"
	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -ErrorAction SilentlyContinue
    Set-Service "WSearch" -StartupType Automatic
    Start-Service "WSearch" -WarningAction SilentlyContinue

    $ResultText.text = "`r`n" + "  Enabling Action Center..."
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Enabling Notification Area..."
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" Name "NoAutoTrayNotify" -ErrorAction SilentlyContinue

    $ResultText.text = "`r`n" + "  Changing default Explorer view to Quick Access..."
	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -ErrorAction SilentlyContinue

    $ResultText.text = "`r`n" + "  Enabling Windows Security Notifications..."
    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Notifications" -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Notifications" -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -ErrorAction SilentlyContinue

      # Service tweaks to Automatic to make sure things start up smoothly if you wanted to change things back..

    $services = @(
    "diagnosticshub.standardcollector.service"   # Microsoft (R) Diagnostics Hub Standard Collector Service
    "DiagTrack"                                  # Diagnostics Tracking Service
    "DPS"
    "dmwappushservice"                           # WAP Push Message Routing Service (see known issues)
    "lfsvc"                                      # Geolocation Service
    "MapsBroker"                                 # Downloaded Maps Manager
    "NetTcpPortSharing"                          # Net.Tcp Port Sharing Service
    "RemoteAccess"                               # Routing and Remote Access
    "RemoteRegistry"                             # Remote Registry
    "SharedAccess"                               # Internet Connection Sharing (ICS)
    "TrkWks"                                     # Distributed Link Tracking Client
    "WbioSrvc"                                   # Windows Biometric Service (required for Fingerprint reader / facial detection)
    "WlanSvc"                                    # WLAN AutoConfig
    "WMPNetworkSvc"                              # Windows Media Player Network Sharing Service
    "wscsvc"                                     # Windows Security Center Service
    "WSearch"                                    # Windows Search
    "XblAuthManager"                             # Xbox Live Auth Manager
    "XblGameSave"                                # Xbox Live Game Save Service
    "XboxNetApiSvc"                              # Xbox Live Networking Service
    "XboxGipSvc"                                 #Disables Xbox Accessory Management Service
    "ndu"                                        # Windows Network Data Usage Monitor
    "WerSvc"                                     #disables windows error reporting
    "Spooler"                                    #Disables your printer
    "Fax"                                        #Disables fax
    "fhsvc"                                      #Disables fax histroy
    "gupdate"                                    #Disables google update
    "gupdatem"                                   #Disable another google update
    "stisvc"                                     #Disables Windows Image Acquisition (WIA)
    "AJRouter"                                   #Disables (needed for AllJoyn Router Service)
    "MSDTC"                                      # Disables Distributed Transaction Coordinator
    "WpcMonSvc"                                  #Disables Parental Controls
    "PhoneSvc"                                   #Disables Phone Service(Manages the telephony state on the device)
    "PrintNotify"                                #Disables Windows printer notifications and extentions
    "PcaSvc"                                     #Disables Program Compatibility Assistant Service
    "WPDBusEnum"                                 #Disables Portable Device Enumerator Service
    "LicenseManager"                             #Disable LicenseManager(Windows store may not work properly)
    "seclogon"                                   #Disables  Secondary Logon(disables other credentials only password will work)
    "SysMain"                                    #Disables sysmain
    "lmhosts"                                    #Disables TCP/IP NetBIOS Helper
    "wisvc"                                      #Disables Windows Insider program(Windows Insider will not work)
    "FontCache"                                  #Disables Windows font cache
    "RetailDemo"                                 #Disables RetailDemo whic is often used when showing your device
    "ALG"                                        # Disables Application Layer Gateway Service(Provides support for 3rd party protocol plug-ins for Internet Connection Sharing)
    "BFE"                                       #Disables Base Filtering Engine (BFE) (is a service that manages firewall and Internet Protocol security)
    "BrokerInfrastructure"                       #Disables Windows infrastructure service that controls which background tasks can run on the system.
    "SCardSvr"                                    #Disables Windows smart card
    "EntAppSvc"                                   #Disables enterprise application management.
    "BthAvctpSvc"                                 #Disables AVCTP service (if you use  Bluetooth Audio Device or Wireless Headphones. then don't disable this)
    "FrameServer"                                 #Disables Windows Camera Frame Server(this allows multiple clients to access video frames from camera devices.)
    "Browser"                                     #Disables computer browser
    "BthAvctpSvc"                                 #AVCTP service (This is Audio Video Control Transport Protocol service.)
    "BDESVC"                                      #Disables bitlocker
    "iphlpsvc"                                    #Disables ipv6 but most websites don't use ipv6 they use ipv4     
    "edgeupdate"                                  # Disables one of edge update service  
    "MicrosoftEdgeElevationService"               # Disables one of edge  service 
    "edgeupdatem"                                 # disbales another one of update service (disables edgeupdatem)                          
    "SEMgrSvc"                                    #Disables Payments and NFC/SE Manager (Manages payments and Near Field Communication (NFC) based secure elements)
    "PNRPsvc"                                    # Disables peer Name Resolution Protocol ( some peer-to-peer and collaborative applications, such as Remote Assistance, may not function, Discord will still work)
    "p2psvc"                                     # Disbales Peer Name Resolution Protocol(nables multi-party communication using Peer-to-Peer Grouping.  If disabled, some applications, such as HomeGroup, may not function. Discord will still work)
    "p2pimsvc"                                   # Disables Peer Networking Identity Manager (Peer-to-Peer Grouping services may not function, and some applications, such as HomeGroup and Remote Assistance, may not function correctly.Discord will still work)
    "PerfHost"                                    #Disables  remote users and 64-bit processes to query performance .
    "BcastDVRUserService_48486de"                 #Disables GameDVR and Broadcast   is used for Game Recordings and Live Broadcasts
    "CaptureService_48486de"                      #Disables ptional screen capture functionality for applications that call the Windows.Graphics.Capture API.  
    "cbdhsvc_48486de"                             #Disables   cbdhsvc_48486de (clipboard service it disables)
    "WpnService"                                  #Disables WpnService (Push Notifications may not work )
    "StorSvc"                                     #Disables StorSvc (usb external hard drive will not be reconised by windows)
    "RtkBtManServ"                                #Disables Realtek Bluetooth Device Manager Service
    "QWAVE"                                       #Disables Quality Windows Audio Video Experience (audio and video might sound worse)
    "HPAppHelperCap"
    "HPDiagsCap"
    "HPNetworkCap"
    "HPSysInfoCap"
    "HpTouchpointAnalyticsService"
    "HvHost"                        
    "vmickvpexchange"
    "vmicguestinterface"
    "vmicshutdown"
    "vmicheartbeat"
    "vmicvmsession"
    "vmicrdv"
    "vmictimesync" 
)

foreach ($service in $services) {
    # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist
    $ResultText.text = "`r`n" + "  Setting $service StartupType to Automatic"
    Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Automatic
}

    #Restart Explorer so that the taskbar can update and not look break :D
    Stop-Process -name explorer
    Start-Sleep -s 5
    Start-Process -name explorer

    $ResultText.text = "`r`n" + "  Essential Undo Completed - Ready for Next Task..."
})

#Valuable Windows 10 AppX apps that most people want to keep. Protected from DeBloat All.
#Credit to /u/GavinEke for a modified version of my whitelist code
$global:WhiteListedApps = @(
    "Microsoft.WindowsCalculator"               # Microsoft removed legacy calculator
    "Microsoft.WindowsStore"                    # Issue 1
    "Microsoft.Windows.Photos"                  # Microsoft disabled/hid legacy photo viewer
    "CanonicalGroupLimited.UbuntuonWindows"     # Issue 10
    "Microsoft.Xbox.TCUI"                       # Issue 25, 91  Many home users want to play games
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"               # Issue 25, 91  Many home users want to play games
    "Microsoft.XboxIdentityProvider"            # Issue 25, 91  Many home users want to play games
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.MicrosoftStickyNotes"            # Issue 33  New functionality.
    "Microsoft.MSPaint"                         # Issue 32  This is Paint3D, legacy paint still exists in Windows 10
    "Microsoft.WindowsCamera"                   # Issue 65  New functionality.
    "\.NET"
    "Microsoft.HEIFImageExtension"              # Issue 68
    "Microsoft.ScreenSketch"                    # Issue 55: Looks like Microsoft will be axing snipping tool and using Snip & Sketch going forward
    "Microsoft.StorePurchaseApp"                # Issue 68
    "Microsoft.VP9VideoExtensions"              # Issue 68
    "Microsoft.WebMediaExtensions"              # Issue 68
    "Microsoft.WebpImageExtension"              # Issue 68
    "Microsoft.DesktopAppInstaller"             # Issue 68
    "WindSynthBerry"                            # Issue 68
    "MIDIBerry"                                 # Issue 68
    "Slack"                                     # Issue 83
    "*Nvidia*"                                  # Issue 198
    "Microsoft.MixedReality.Portal"             # Issue 195
)

#NonRemovable Apps that where getting attempted and the system would reject the uninstall, speeds up debloat and prevents 'initalizing' overlay when removing apps
$NonRemovables = Get-AppxPackage -AllUsers | Where-Object { $_.NonRemovable -eq $true } | ForEach-Object { $_.Name }
$NonRemovables += Get-AppxPackage | Where-Object { $_.NonRemovable -eq $true } | ForEach-Object { $_.Name }
$NonRemovables += Get-AppxProvisionedPackage -Online | Where-Object { $_.NonRemovable -eq $true } | ForEach-Object { $_.DisplayName }
$NonRemovables = $NonRemovables | Sort-Object -Unique

if ($NonRemovables -eq "0" ) {
    # the .NonRemovable property doesn't exist until version 18xx. Use a hard-coded list instead.
    #WARNING: only use exact names here - no short names or wildcards
    $NonRemovables = @(
        "1527c705-839a-4832-9118-54d4Bd6a0c89"
        "c5e2524a-ea46-4f67-841f-6a9465d9d515"
        "E2A4F912-2574-4A75-9BB0-0D023378592B"
        "F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE"
        "InputApp"
        "Microsoft.AAD.BrokerPlugin"
        "Microsoft.AccountsControl"
        "Microsoft.BioEnrollment"
        "Microsoft.CredDialogHost"
        "Microsoft.ECApp"
        "Microsoft.LockApp"
        "Microsoft.MicrosoftEdgeDevToolsClient"
        "Microsoft.MicrosoftEdge"
        "Microsoft.PPIProjection"
        "Microsoft.Win32WebViewHost"
        "Microsoft.Windows.Apprep.ChxApp"
        "Microsoft.Windows.AssignedAccessLockApp"
        "Microsoft.Windows.CapturePicker"
        "Microsoft.Windows.CloudExperienceHost"
        "Microsoft.Windows.ContentDeliveryManager"
        "Microsoft.Windows.Cortana"
        "Microsoft.Windows.HolographicFirstRun"         # Added 1709
        "Microsoft.Windows.NarratorQuickStart"
        "Microsoft.Windows.OOBENetworkCaptivePortal"    # Added 1709
        "Microsoft.Windows.OOBENetworkConnectionFlow"   # Added 1709
        "Microsoft.Windows.ParentalControls"
        "Microsoft.Windows.PeopleExperienceHost"
        "Microsoft.Windows.PinningConfirmationDialog"
        "Microsoft.Windows.SecHealthUI"                 # Issue 117 Windows Defender
        "Microsoft.Windows.SecondaryTileExperience"     # Added 1709
        "Microsoft.Windows.SecureAssessmentBrowser"
        "Microsoft.Windows.ShellExperienceHost"
        "Microsoft.Windows.XGpuEjectDialog"
        "Microsoft.XboxGameCallableUI"                  # Issue 91
        "Windows.CBSPreview"
        "windows.immersivecontrolpanel"
        "Windows.PrintDialog"
        "Microsoft.VCLibs.140.00"
        "Microsoft.Services.Store.Engagement"
        "Microsoft.UI.Xaml.2.0"
    )
}

$global:WhiteListedAppsRegex = $global:WhiteListedApps -join '|'

$Bloatware = @(
    #Unnecessary Windows 10 & 11 apps
    "Microsoft.3DBuilder"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.AppConnector"
    "Microsoft.BingFinance"
    "Microsoft.BingNews"
    "Microsoft.BingSports"
    "Microsoft.BingTranslator"
    "Microsoft.BingWeather"
    "Microsoft.BingFoodAndDrink"
    "Microsoft.BingHealthAndFitness"
    "Microsoft.BingTravel"
    "Microsoft.MinecraftUWP"
    "Microsoft.GamingServices"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Messaging"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.News"    
    "Microsoft.Office.Lens"
    "Microsoft.Office.Sway"
    "Microsoft.Office.Lens"                             # Issue 77
    "Microsoft.Office.OneNote"
    "Microsoft.Office.Sway"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.Print3D"
    "Microsoft.Paint"
    "Microsoft.RemoteDesktop"                           # Issue 120
    "Microsoft.SkypeApp"
    "Microsoft.Wallet"
    "Microsoft.Whiteboard"
    "Microsoft.StorePurchaseApp"
    "Microsoft.Office.Todo.List"                        # Issue 77
    "Microsoft.Whiteboard"                              # Issue 77
    "Microsoft.WindowsAlarms"
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsPhone"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.ConnectivityStore"
    "Microsoft.CommsPhone"
    "Microsoft.ScreenSketch"
    "Microsoft.MixedReality.Portal"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Microsoft.YourPhone"
    "*Microsoft.Advertising.Xaml*"
    "*Microsoft.MicrosoftStickyNotes*"
    "Microsoft.Advertising.Xaml_10.1712.5.0_x64__8wekyb3d8bbwe"
    "Microsoft.Advertising.Xaml_10.1712.5.0_x86__8wekyb3d8bbwe"

    #Add sponsored/featured apps to remove in the "*AppName*" format
    "*EclipseManager*"
    "*ActiproSoftwareLLC*"
    "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
    "*Duolingo-LearnLanguagesforFree*"
    "*PandoraMediaInc*"
    "*CandyCrush*"
    "*BubbleWitch3Saga*"
    "*Wunderlist*"
    "*Flipboard*"
    "*Twitter*"
    "*Facebook*"
    "*Royal Revolt*"
    "*Sway*"
    "*Speed Test*"
    "*Dolby*"
    "*Viber*"
    "*ACGMediaPlayer*"
    "*Netflix*"
    "*OneCalendar*"
    "*LinkedInforWindows*"
    "*HiddenCityMysteryofShadows*"
    "*Hulu*"
    "*HiddenCity*"
    "*AdobePhotoshopExpress*"
    "*HotspotShieldFreeVPN*"
    "*BytedancePte*"
    "*TikTok*"
    "*Disney*"
    "*Clipchamp*"
    "*SpotifyAB*"
    "*AmazonVideo*"
    "*Instagram*"
    "*ToDo*"
    "*Hidden City*"
    "*Roblox*"
    "*Photoshop*"
)

$removebloat.Add_Click({
        $ErrorActionPreference = 'SilentlyContinue'

        Function SystemPrep {

            $ResultText.text = "`r`n" + "  Starting Sysprep Fixes"
   
            $ResultText.text = "`r`n" + "  Adding Registry key to Disable Windows Store Automatic Updates"
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
            If (!(Test-Path $registryPath)) {
                Mkdir $registryPath
                New-ItemProperty $registryPath AutoDownload -Value 2 
            }
            Set-ItemProperty $registryPath AutoDownload -Value 2

            $ResultText.text = "`r`n" + "  Stopping InstallService"
            Stop-Service InstallService
            $ResultText.text = "`r`n" + "  Setting InstallService Startup to Disabled"
            Set-Service InstallService -StartupType Disabled
        }
        
        Function CheckDMWService {

            Param([switch]$Debloat)
  
            If (Get-Service dmwappushservice | Where-Object { $_.StartType -eq "Disabled" }) {
                Set-Service dmwappushservice -StartupType Automatic
            }

            If (Get-Service dmwappushservice | Where-Object { $_.Status -eq "Stopped" }) {
                Start-Service dmwappushservice
            } 
        }

        Function RemoveMassiveBloat {
            foreach ($Bloat in $Bloatware) {
                Get-AppxPackage -Name $Bloat| Remove-AppxPackage
                Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
                $ResultText.text = "`r`n" + "  Trying to remove $Bloat."
            }
        }

        Function DebloatAll {
            #Removes AppxPackages
            Get-AppxPackage | Where-Object { !($_.Name -cmatch $global:WhiteListedAppsRegex) -and !($NonRemovables -cmatch $_.Name) } | Remove-AppxPackage
            Get-AppxProvisionedPackage -Online | Where-Object { !($_.DisplayName -cmatch $global:WhiteListedAppsRegex) -and !($NonRemovables -cmatch $_.DisplayName) } | Remove-AppxProvisionedPackage -Online
            Get-AppxPackage -AllUsers | Where-Object { !($_.Name -cmatch $global:WhiteListedAppsRegex) -and !($NonRemovables -cmatch $_.Name) } | Remove-AppxPackage
        }
  
        #Creates a PSDrive to be able to access the 'HKCR' tree
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
  
        Function Remove-Keys {      
            $ErrorActionPreference = 'SilentlyContinue'   
            #These are the registry keys that it will delete.
          
            $Keys = @(
          
                #Remove Background Tasks
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
                "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
                "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
                "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            )
      
            #This writes the output of each key it is removing and also removes the keys listed above.
            ForEach ($Key in $Keys) {
                $ResultText.text = "`r`n" + "  Removing $Key from registry"
                Remove-Item $Key -Recurse
            }
        }
          
        Function Protect-Privacy { 
  
            #Creates a PSDrive to be able to access the 'HKCR' tree
            New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
          
            #Disables Windows Feedback Experience
            $ResultText.text = "`r`n" + "  Disabling Windows Feedback Experience program"
            $Advertising = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
            If (Test-Path $Advertising) {
                Set-ItemProperty $Advertising Enabled -Value 0
            }
            
            $ResultText.text = "`r`n" + "  Adding Registry key to prevent bloatware apps from returning"
            #Prevents bloatware applications from returning
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            If (!(Test-Path $registryPath)) {
                Mkdir $registryPath
                New-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 
            }          
      
            $ResultText.text = "`r`n" + "  Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
            $Holo = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic'    
            If (Test-Path $Holo) {
                Set-ItemProperty $Holo FirstRunSucceeded -Value 0
            }
      
            #Disables live tiles
            $ResultText.text = "`r`n" + "  Disabling live tiles"
            $Live = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'    
            If (!(Test-Path $Live)) {
                mkdir $Live  
                New-ItemProperty $Live NoTileApplicationNotification -Value 1
            }
      
            $ResultText.text = "`r`n" + "  Removing CloudStore from registry if it exists"
            $CloudStore = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore'
            If (Test-Path $CloudStore) {
                Stop-Process Explorer.exe -Force
                Remove-Item $CloudStore -Recurse -Force
                Start-Process Explorer.exe -Wait
            }

  
            #Loads the registry keys/values below into the NTUSER.DAT file which prevents the apps from redownloading. Credit to a60wattfish
            reg load HKU\Default_User C:\Users\Default\NTUSER.DAT
            Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SystemPaneSuggestionsEnabled -Value 0
            Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name PreInstalledAppsEnabled -Value 0
            Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name OemPreInstalledAppsEnabled -Value 0
            reg unload HKU\Default_User
      
            #Disables scheduled tasks that are considered unnecessary 
            $ResultText.text = "`r`n" + "  Disabling scheduled tasks"
            #Get-ScheduledTask -TaskName XblGameSaveTaskLogon | Disable-ScheduledTask
            Get-ScheduledTask -TaskName XblGameSaveTask | Disable-ScheduledTask
            Get-ScheduledTask -TaskName Consolidator | Disable-ScheduledTask
            Get-ScheduledTask -TaskName UsbCeip | Disable-ScheduledTask
            Get-ScheduledTask -TaskName DmClient | Disable-ScheduledTask
            Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Disable-ScheduledTask
        }

        Function UnpinStart {
            # https://superuser.com/a/1442733
            # Requires -RunAsAdministrator

$START_MENU_LAYOUT = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride>
        <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6" />
        </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

            $layoutFile="C:\Windows\StartMenuLayout.xml"

            #Delete layout file if it already exists
            If(Test-Path $layoutFile)
            {
                Remove-Item $layoutFile
            }

            #Creates the blank layout file
            $START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

            $regAliases = @("HKLM", "HKCU")

            #Assign the start layout and force it to apply with "LockedStartLayout" at both the machine and user level
            foreach ($regAlias in $regAliases){
                $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
                $keyPath = $basePath + "\Explorer" 
                IF(!(Test-Path -Path $keyPath)) { 
                    New-Item -Path $basePath -Name "Explorer"
                }
                Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 1
                Set-ItemProperty -Path $keyPath -Name "StartLayoutFile" -Value $layoutFile
            }

            #Restart Explorer, open the start menu (necessary to load the new layout), and give it a few seconds to process
            Stop-Process -name explorer
            Start-Sleep -s 5
            $wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('^{ESCAPE}')
            Start-Sleep -s 5

            #Enable the ability to pin items again by disabling "LockedStartLayout"
            foreach ($regAlias in $regAliases){
                $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
                $keyPath = $basePath + "\Explorer" 
                Set-ItemProperty -Path $keyPath -Name "LockedStartLayout" -Value 0
            }

            #Restart Explorer and delete the layout file
            Stop-Process -name explorer

            # Uncomment the next line to make clean start menu default for all new users
            #Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\

            Remove-Item $layoutFile
        }
        
        Function CheckInstallService {
  
            If (Get-Service InstallService | Where-Object { $_.Status -eq "Stopped" }) {  
                Start-Service InstallService
                Set-Service InstallService -StartupType Automatic 
            }
        }
  
    $ResultText.text = "`r`n" + "  Initiating Sysprep.."
    SystemPrep

    $ResultText.text = "`r`n" + "  Removing bloatware apps(This might take more than 10 minutes)"
    RemoveMassiveBloat
    DebloatAll

    $ResultText.text = "`r`n" + "  Removing leftover bloatware registry keys."
    Remove-Keys

    $ResultText.text = "`r`n" + "  Checking to see if any Allowlisted Apps were removed, and if so re-adding them."
    FixWhitelistedApps

    $ResultText.text = "`r`n" + "  Disabling unneccessary scheduled tasks, and preventing bloatware from returning."
    Protect-Privacy

    $ResultText.text = "`r`n" + "  Unpinning tiles from the Start Menu."
    UnpinStart

    $ResultText.text = "`r`n" + "  Setting the 'InstallService' Windows service back to 'Started' and the Startup Type 'Automatic'."
    CheckDMWService
    CheckInstallService

    $ResultText.text = "`r`n" + "  Finished Removing Bloatware Apps - Ready for Next Task..."
})

$reinstallbloat.Add_Click({

    $ResultText.text = "`r`n" + "  Reinstalling MS Store Apps and activating deactivated features for MS Store..."
    $ErrorActionPreference = 'SilentlyContinue'
    #This function will revert the changes you made when running the Start-Debloat function.

    #This line reinstalls all of the bloatware that was removed
    Get-AppxPackage -AllUsers | ForEach-Object { Add-AppxPackage -Verbose -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" } 

    #Tells Windows to enable your advertising information.    
    $ResultText.text = "`r`n" + "  Re-enabling key to show advertisement information"
    $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    If (Test-Path $Advertising) {
        Set-ItemProperty $Advertising  Enabled -Value 1
    }

    #Enables bloatware applications               
    $ResultText.text = "`r`n" + "  Adding Registry key to allow bloatware apps to return"
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    If (!(Test-Path $registryPath)) {
        New-Item $registryPath 
    }
    Set-ItemProperty $registryPath  DisableWindowsConsumerFeatures -Value 0 
    
    #Changes Mixed Reality Portal Key 'FirstRunSucceeded' to 1
    $ResultText.text = "`r`n" + "  Setting Mixed Reality Portal value to 1"
    $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"
    If (Test-Path $Holo) {
        Set-ItemProperty $Holo  FirstRunSucceeded -Value 1 
    }
    
    #Re-enables live tiles
    $ResultText.text = "`r`n" + "  Enabling live tiles"
    $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
    If (!(Test-Path $Live)) {
        New-Item $Live 
    }
    Set-ItemProperty $Live  NoTileApplicationNotification -Value 0 
   
    #Re-enables scheduled tasks that were disabled when running the Debloat switch
    $ResultText.text = "`r`n" + "  Enabling scheduled tasks that were disabled"
    Get-ScheduledTask XblGameSaveTaskLogon | Enable-ScheduledTask 
    Get-ScheduledTask  XblGameSaveTask | Enable-ScheduledTask 
    Get-ScheduledTask  Consolidator | Enable-ScheduledTask 
    Get-ScheduledTask  UsbCeip | Enable-ScheduledTask 
    Get-ScheduledTask  DmClient | Enable-ScheduledTask 
    Get-ScheduledTask  DmClientOnScenarioDownload | Enable-ScheduledTask 

    $ResultText.text = "`r`n" + "  Re-enabling and starting WAP Push Service"
    #Enable and start WAP Push Service
    Set-Service "dmwappushservice" -StartupType Automatic
    Start-Service "dmwappushservice"

    $ResultText.text = "`r`n" + "  Re-enabling and starting the Diagnostics Tracking Service"
    #Enabling the Diagnostics Tracking Service
    Set-Service "DiagTrack" -StartupType Automatic
    Start-Service "DiagTrack"
    $ResultText.text = "`r`n" + "  Done reverting changes!"

    #
    $ResultText.text = "`r`n" + "  Restoring 3D Objects from Explorer 'My Computer' submenu"
    $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
    If (!(Test-Path $Objects32)) {
        New-Item $Objects32
    }
    If (!(Test-Path $Objects64)) {
        New-Item $Objects64
    }

    $ResultText.text = "`r`n" + "  Finished Reinstalling Bloatware Apps - Ready for Next Task..."
})

$defaultwindowsupdate.Add_Click({
    $ResultText.text = "`r`n" + "  Enabling driver offering through Windows Update..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
    $ResultText.text = "`r`n" + "  Enabling Windows Update automatic restart..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -ErrorAction SilentlyContinue
    $ResultText.text = "`r`n" + "  Enabled driver offering through Windows Update"
    $ResultText.text = "`r`n" + "  Set Windows Updates to Stock Settings - Ready for Next Task..."
})

$securitywindowsupdate.Add_Click({
    $ResultText.text = "`r`n" + "  Disabling driver offering through Windows Update..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -Type DWord -Value 0
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
    $ResultText.text = "`r`n" + "  Disabling Windows Update automatic restart..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
    $ResultText.text = "`r`n" + "  Disabled driver offering through Windows Update"
    $ResultText.text = "`r`n" + "  Set Windows Update to Sane Settings - Ready for Next Task..."
})

$performancefx.Add_Click({
    $ResultText.text = "`r`n" + "  Adjusting visual effects for performance..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 0
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 200
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 0
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 0
    $ResultText.text = "`r`n" + "  Adjusted visual effects for performance - Ready for Next Task..."
})

$appearancefx.Add_Click({
    $ResultText.text = "`r`n" + "  Adjusting visual effects for appearance..."
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 1
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 400
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](158,30,7,128,18,0,0,0))
	Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 1
	Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 1
    $ResultText.text = "`r`n" + "  Visual effects are set for appearance (Defaults) - Ready for Next Task..."
})

$gamingtweaks.Add_Click({
    $ResultText.text = "`r`n" + "  Disabling Fullscreen Optimization..."
	Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Type DWord -Value 2
	Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Type DWord -Value 2
	Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DSEBehavior" -Type DWord -Value 2
	Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Apply Gaming Optimization Fixes..."
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Type DWord -Value 8
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Type DWord -Value 6
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Type String -Value "High"
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "SFIO Priority" -Type String -Value "High"
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ8Priority" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Forcing RAW Mouse Input and Disabling Enhance Pointer Precision..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type String -Value "0"
	Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type String -Value "0"
	Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type String -Value "0"
	Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Type String -Value "10"
	Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Type String -Value "0"
	Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseTrails" -Type String -Value "0"

    Add-Type @'
  using System; 
  using System.Runtime.InteropServices;
  using System.Drawing;
  public class DPI {  
    [DllImport("gdi32.dll")]
    static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
    public enum DeviceCap {
      VERTRES = 10,
      DESKTOPVERTRES = 117
    } 
    public static float scaling() {
      Graphics g = Graphics.FromHwnd(IntPtr.Zero);
      IntPtr desktop = g.GetHdc();
      int LogicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.VERTRES);
      int PhysicalScreenHeight = GetDeviceCaps(desktop, (int)DeviceCap.DESKTOPVERTRES);
      return (float)PhysicalScreenHeight / (float)LogicalScreenHeight;
    }
  }
'@ -ReferencedAssemblies 'System.Drawing.dll'

    $checkscreenscale = [Math]::round([DPI]::scaling(), 2) * 100
    if($checkscreenscale -eq "100") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 100%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,C0,CC,0C,00,00,00,00,00,80,99,19,00,00,00,00,00,40,66,26,00,00,00,00,00,00,33,33,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } elseif($checkscreenscale -eq "125") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 125%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,00,00,10,00,00,00,00,00,00,00,20,00,00,00,00,00,00,00,30,00,00,00,00,00,00,00,40,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } elseif($checkscreenscale -eq "150") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 150%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,30,33,13,00,00,00,00,00,60,66,26,00,00,00,00,00,90,99,39,00,00,00,00,00,C0,CC,4C,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } elseif($checkscreenscale -eq "175") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 175%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,60,66,16,00,00,00,00,00,C0,CC,2C,00,00,00,00,00,20,33,43,00,00,00,00,00,80,99,59,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } elseif($checkscreenscale -eq "200") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 200%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,90,99,19,00,00,00,00,00,20,33,33,00,00,00,00,00,B0,CC,4C,00,00,00,00,00,40,66,66,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } elseif($checkscreenscale -eq "225") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 225%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,C0,CC,1C,00,00,00,00,00,80,99,39,00,00,00,00,00,40,66,56,00,00,00,00,00,00,33,73,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } elseif($checkscreenscale -eq "250") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 250%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,00,00,20,00,00,00,00,00,00,00,40,00,00,00,00,00,00,00,60,00,00,00,00,00,00,00,80,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } elseif($checkscreenscale -eq "300") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 300%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,60,66,26,00,00,00,00,00,C0,CC,4C,00,00,00,00,00,20,33,73,00,00,00,00,00,80,99,99,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } elseif($checkscreenscale -eq "350") {
        $ResultText.text = "`r`n" + "  Windows screen scale is Detected as 350%, Applying Mouse Fix for it..."
        $YourInputX = "00,00,00,00,00,00,00,00,C0,CC,2C,00,00,00,00,00,80,99,59,00,00,00,00,00,40,66,86,00,00,00,00,00,00,33,B3,00,00,00,00,00"
        $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
        $RegPath   = 'HKCU:\Control Panel\Mouse'
        $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_"}
        $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_"}
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
        Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
    } else {
        $ResultText.text = "`r`n" + "  Screen scale is not set to traditional value, nothing has been set!"
    }

    $ResultText.text = "`r`n" + "  Enabling Gaming Mode..."
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel" -Type DWord -Value 0
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "GamePanelStartupTipIndex" -Type DWord -Value 3
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Enabling HAGS..."
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Type DWord -Value 2

    $ResultText.text = "`r`n" + "  Disabling Core Parking on current PowerPlan Ultimate Performance..."
	powercfg -attributes SUB_PROCESSOR CPMINCORES -ATTRIB_HIDE | Out-Null
	Powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 | Out-Null
	Powercfg -setactive scheme_current | Out-Null

    $ResultText.text = "`r`n" + "  Optimizing Network, applying Tweaks for no throttle and maximum speed!..."
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" -ErrorAction SilentlyContinue | Out-Null
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters" -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPER1_0SERVER" -Name "explorer.exe" -Type DWord -Value 10
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPERSERVER" -Name "explorer.exe" -Type DWord -Value 10
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "LocalPriority" -Type DWord -Value 4
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "HostsPriority" -Type DWord -Value 5
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "DnsPriority" -Type DWord -Value 6
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" -Name "NetbtPriority" -Type DWord -Value 7
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortlimit" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" -Name "Do not use NLA" -Type String -Value "1"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "Size" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type DWord -Value 20
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "MaxUserPort" -Type DWord -Value 65534
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpTimedWaitDelay" -Type DWord -Value 30
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DefaultTTL" -Type DWord -Value 64
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters" -Name "TCPNoDelay" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\Lsa" -Name "LmCompatibilityLevel" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoh" -Type DWord -Value 2
    Set-NetTCPSetting -SettingName internet -EcnCapability disabled | Out-Null
    Set-NetOffloadGlobalSetting -Chimney disabled | Out-Null
    Set-NetTCPSetting -SettingName internet -Timestamps disabled | Out-Null
    Set-NetTCPSetting -SettingName internet -MaxSynRetransmissions 2 | Out-Null
    Set-NetTCPSetting -SettingName internet -NonSackRttResiliency disabled | Out-Null
    Set-NetTCPSetting -SettingName internet -InitialRto 2000 | Out-Null
    Set-NetTCPSetting -SettingName internet -MinRto 300 | Out-Null
    Set-NetTCPSetting -SettingName Internet -AutoTuningLevelLocal normal | Out-Null
    Set-NetTCPSetting -SettingName internet -ScalingHeuristics disabled | Out-Null
    netsh int tcp set supplemental internet congestionprovider=ctcp | Out-Null
    Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing enabled | Out-Null
    Set-NetOffloadGlobalSetting -ReceiveSideScaling enabled | Out-Null
    Disable-NetAdapterLso -Name * | Out-Null
    Disable-NetAdapterChecksumOffload -Name * | Out-Null
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Energy-Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Energy Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Energy Efficient Ethernet" -DisplayValue "Off" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Ultra Low Power Mode" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "System Idle Power Saver" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Green Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Power Saving Mode" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Gigabit Lite" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "EEE" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Advanced EEE" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "ARP Offload" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "NS Offload" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Idle Power Saving" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Flow Control" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Reduce Speed On Power Down" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name * -DisplayName "Interrupt Moderation Rate" -DisplayValue "Off" -ErrorAction SilentlyContinue

    if ((Get-CimInstance -ClassName Win32_ComputerSystem).PCSystemType -ne 2)
    {
        $adapters = Get-NetAdapter -Physical | Get-NetAdapterPowerManagement | Where-Object -FilterScript {$_.AllowComputerToTurnOffDevice -ne "Unsupported"}
        foreach ($adapter in $adapters)
        {
            $adapter.AllowComputerToTurnOffDevice = "Disabled"
            $adapter | Set-NetAdapterPowerManagement
        }
    }
       Start-Sleep -s 5

    $NetworkIDS = @((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*").PSChildName)

    $ResultText.text = "`r`n" + "  Disabling Nagles Algorithm..."

    foreach ($NetworkID in $NetworkIDS) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NetworkID" -Name "TcpAckFrequency" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NetworkID" -Name "TCPNoDelay" -Type DWord -Value 1
    }

    $ResultText.text = "`r`n" + "  Forcing Windows to stop tolerating high DPC/ISR latencies..."
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" | Out-Null -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "ExitLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "ExitLatencyCheckEnabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "Latency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "LatencyToleranceDefault" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "LatencyToleranceFSVP" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "LatencyTolerancePerfOverride" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "LatencyToleranceScreenOffIR" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "LatencyToleranceVSyncEnabled" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "RtlCapabilityCheckLatency" -Type DWord -Value 1
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" | Out-Null -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultD3TransitionLatencyActivelyUsed" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultD3TransitionLatencyIdleLongTime" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultD3TransitionLatencyIdleMonitorOff" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultD3TransitionLatencyIdleNoContext" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultD3TransitionLatencyIdleShortTime" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultD3TransitionLatencyIdleVeryLongTime" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceIdle0" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceIdle0MonitorOff" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceIdle1" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceIdle1MonitorOff" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceMemory" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceNoContext" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceNoContextMonitorOff" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceOther" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultLatencyToleranceTimerPeriod" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultMemoryRefreshLatencyToleranceActivelyUsed" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultMemoryRefreshLatencyToleranceMonitorOff" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "DefaultMemoryRefreshLatencyToleranceNoContext" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "Latency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "MaxIAverageGraphicsLatencyInOneBucket" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "MiracastPerfTrackGraphicsLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "MonitorLatencyTolerance" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "MonitorRefreshLatencyTolerance" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Power" -Name "TransitionLatency" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Decreasing mouse and keyboard buffer sizes..."
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" | Out-Null -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Type DWord -Value 0x00000010
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" | Out-Null -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Type DWord -Value 0x00000010

    $ResultText.text = "`r`n" + "  Disabling DMA memory protection and cores isolation..."
    bcdedit /set vsmlaunchtype Off | Out-Null
    bcdedit /set vm No | Out-Null
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" | Out-Null -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "DisableExternalDMAUnderLock" -Type DWord -Value 0
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" | Out-Null -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -Name "HVCIMATRequired" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Disabling Process and Kernel Mitigations... (Throws an error, im unsure of why)"
    ForEach($v in (Get-Command -Name "Set-ProcessMitigation").Parameters["Disable"].Attributes.ValidValues){Set-ProcessMitigation -System -Disable $v.ToString() -ErrorAction SilentlyContinue}
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "DisableExceptionChainValidation" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "KernelSEHOPEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "EnableCfg" -Type DWord -Value 0

    $ResultText.text = "`r`n" + "  Disabling drivers get paged into virtual memory..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Enabling big system memory caching to improve microstuttering..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Forcing contiguous memory allocation in the DirectX Graphics Kernel..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "DpiMapIommuContiguous" -Type DWord -Value 1

    $ResultText.text = "`r`n" + "  Disabling High Precision Event Timer..."
    Invoke-WebRequest -Uri "https://github.com/alerion921/WinTool-for-10-11/blob/main/Files/SetTimerResolutionService.exe" -OutFile "$Env:windir\system32\SetTimerResolutionService.exe" -ErrorAction SilentlyContinue
    New-Service -name "SetTimerResolutionService" -BinaryPathName "$Env:windir\system32\SetTimerResolutionService.exe" -StartupType Automatic | Out-Null -ErrorAction SilentlyContinue
    bcdedit /set x2apicpolicy Enable | Out-Null
    bcdedit /set configaccesspolicy Default | Out-Null
    bcdedit /set MSI Default | Out-Null
    bcdedit /set usephysicaldestination No | Out-Null
    bcdedit /set usefirmwarepcisettings No | Out-Null
	bcdedit /deletevalue useplatformclock | Out-Null
    bcdedit /set disabledynamictick yes | Out-Null
    bcdedit /set useplatformtick Yes | Out-Null
    bcdedit /set tscsyncpolicy Enhanced | Out-Null
	bcdedit /timeout 10 | Out-Null
	bcdedit /set nx optout | Out-Null
	bcdedit /set bootux disabled | Out-Null
	bcdedit /set quietboot yes | Out-Null
	bcdedit /set {globalsettings} custom:16000067 true | Out-Null
	bcdedit /set {globalsettings} custom:16000069 true | Out-Null
	bcdedit /set {globalsettings} custom:16000068 true | Out-Null
	wmic path Win32_PnPEntity where "name='High precision event timer'" call disable | Out-Null

    $CheckGPU = wmic path win32_VideoController get name
    if(($CheckGPU -like "*GTX*") -or ($CheckGPU -like "*RTX*")) {
    $ResultText.text = "`r`n" + "  NVIDIA GTX/RTX Card Detected! Applying Nvidia Power Tweaks..."
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/Files/BaseProfile.nip" -OutFile "$Env:windir\system32\BaseProfile.nip" -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri "https://github.com/alerion921/WinTool-for-10-11/blob/main/Files/nvidiaProfileInspector.exe" -OutFile "$Env:windir\system32\nvidiaProfileInspector.exe" -ErrorAction SilentlyContinue
    Push-Location
    set-location "$Env:windir\system32\"
    nvidiaProfileInspector.exe /s -load "BaseProfile.nip"
    Pop-Location
    } else {
        $ResultText.text = "`r`n" + "  Nvidia GTX/RTX Card Not Detected! Skipping..."
    } 

    $CheckGPURegistryKey0 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000").DriverDesc
    $CheckGPURegistryKey1 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001").DriverDesc
    $CheckGPURegistryKey2 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002").DriverDesc
    $CheckGPURegistryKey3 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003").DriverDesc

    if(($CheckGPURegistryKey0 -like "*GTX*") -or ($CheckGPURegistryKey0 -like "*RTX*")) {
        $ResultText.text = "`r`n" + "  Nvidia GTX/RTX Card Registry Path 0000 Detected! Applying Nvidia Latency Tweaks..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "D3PCLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "F1TransitionLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "LOWLATENCY" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "Node3DLowLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "PciLatencyTimerControl" -Type DWord -Value "0x00000020"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "RMDeepL1EntryLatencyUsec" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "RmGspcMaxFtuS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "RmGspcMinFtuS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "RmGspcPerioduS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "RMLpwrEiIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "RMLpwrGrIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "RMLpwrGrRgIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "RMLpwrMsIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "VRDirectFlipDPCDelayUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "VRDirectFlipTimingMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "VRDirectJITFlipMsHybridFlipDelayUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "vrrCursorMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "vrrDeflickerMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "vrrDeflickerMaxUs" -Type DWord -Value 1
    } elseif(($CheckGPURegistryKey1 -like "*GTX*") -or ($CheckGPURegistryKey1 -like "*RTX*")) {
        $ResultText.text = "`r`n" + "  Nvidia GTX/RTX Card Registry Path 0001 Detected! Applying Nvidia Latency Tweaks..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "D3PCLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "F1TransitionLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "LOWLATENCY" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "Node3DLowLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "PciLatencyTimerControl" -Type DWord -Value "0x00000020"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "RMDeepL1EntryLatencyUsec" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "RmGspcMaxFtuS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "RmGspcMinFtuS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "RmGspcPerioduS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "RMLpwrEiIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "RMLpwrGrIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "RMLpwrGrRgIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "RMLpwrMsIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "VRDirectFlipDPCDelayUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "VRDirectFlipTimingMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "VRDirectJITFlipMsHybridFlipDelayUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "vrrCursorMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "vrrDeflickerMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" -Name "vrrDeflickerMaxUs" -Type DWord -Value 1
    } elseif(($CheckGPURegistryKey2 -like "*GTX*") -or ($CheckGPURegistryKey2 -like "*RTX*")) {
        $ResultText.text = "`r`n" + "  Nvidia GTX/RTX Card Registry Path 0002 Detected! Applying Nvidia Latency Tweaks..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "D3PCLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "F1TransitionLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "LOWLATENCY" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "Node3DLowLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "PciLatencyTimerControl" -Type DWord -Value "0x00000020"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "RMDeepL1EntryLatencyUsec" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "RmGspcMaxFtuS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "RmGspcMinFtuS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "RmGspcPerioduS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "RMLpwrEiIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "RMLpwrGrIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "RMLpwrGrRgIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "RMLpwrMsIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "VRDirectFlipDPCDelayUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "VRDirectFlipTimingMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "VRDirectJITFlipMsHybridFlipDelayUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "vrrCursorMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "vrrDeflickerMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" -Name "vrrDeflickerMaxUs" -Type DWord -Value 1
    } elseif(($CheckGPURegistryKey3 -like "*GTX*") -or ($CheckGPURegistryKey3 -like "*RTX*")) {
        $ResultText.text = "`r`n" + "  Nvidia GTX/RTX Card Registry Path 0003 Detected! Applying Nvidia Latency Tweaks..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "D3PCLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "F1TransitionLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "LOWLATENCY" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "Node3DLowLatency" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "PciLatencyTimerControl" -Type DWord -Value "0x00000020"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "RMDeepL1EntryLatencyUsec" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "RmGspcMaxFtuS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "RmGspcMinFtuS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "RmGspcPerioduS" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "RMLpwrEiIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "RMLpwrGrIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "RMLpwrGrRgIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "RMLpwrMsIdleThresholdUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "VRDirectFlipDPCDelayUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "VRDirectFlipTimingMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "VRDirectJITFlipMsHybridFlipDelayUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "vrrCursorMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "vrrDeflickerMarginUs" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003" -Name "vrrDeflickerMaxUs" -Type DWord -Value 1
    } else {
        $ResultText.text = "`r`n" + "  No NVIDIA GTX/RTX Card Registry entry Found! Skipping..."
    }

    $ResultText.text = "`r`n" + "  Disabling VBS..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Type DWord -Value 0
    
    $ResultText.text = "`r`n" + "  Gaming Tweaks Applied - Ready for Next Task..."

})

$securitypatches.Add_Click({
    
    $ResultText.text = "`r`n" + "  Applying Security Patches to disable known exploits"

    $ResultText.text = "`r`n" + "  Disabling Spectre Meltdown vulnerability on this system"
    #####SPECTRE MELTDOWN#####
    #https://support.microsoft.com/en-us/help/4073119/protect-against-speculative-execution-side-channel-vulnerabilities-in
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -Type DWord -Value 72 -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverrideMask" -Type DWord -Value 3 -Force
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Virtualization" -Name "MinVmVersionForCpuBasedMitigations" -Type String -Value 1.0 -Force

    $ResultText.text = "`r`n" + "  Disabling LLMNR for additional security.."
     #Disable LLMNR
    #https://www.blackhillsinfosec.com/how-to-disable-llmnr-why-you-want-to/
    New-Item -Path "HKLM:\Software\policies\Microsoft\Windows NT\" -Name "DNSClient" -Force
    Set-ItemProperty -Path "HKLM:\Software\policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Type DWord -Value 0 -Force

    $ResultText.text = "`r`n" + "  Disabling NetBIOS.."
    #Disable NetBIOS by updating Registry
    #http://blog.dbsnet.fr/disable-netbios-with-powershell#:~:text=Disabling%20NetBIOS%20over%20TCP%2FIP,connection%2C%20then%20set%20NetbiosOptions%20%3D%202
    $key = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
    Get-ChildItem $key | ForEach-Object { 
        $ResultText.text = "`r`n" + ("Modify $key\$($_.pschildname)")
        $NetbiosOptions_Value = (Get-ItemProperty "$key\$($_.pschildname)").NetbiosOptions
        $ResultText.text = "`r`n" + ("NetbiosOptions updated value is $NetbiosOptions_Value")
    }

    #Enable SEHOP
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "DisableExceptionChainValidation" -Type "DWORD" -Value 0 -Force

     #Disable TCP Timestamps
     $ResultText.text = "`r`n" + "  TCP Timestamps deactivated.."
     netsh int tcp set global timestamps=disabled

     #Enable DEP
     $ResultText.text = "`r`n" + "  Enabling DEP.."
     BCDEDIT /set "{current}" nx OptOut
     Set-Processmitigation -System -Enable DEP
     Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoDataExecutionPrevention" -Type "DWORD" -Value 0 -Force
     Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableHHDEP" -Type "DWORD" -Value 0 -Force

    $ResultText.text = "`r`n" + "  Disabling WPAD.."
     #Disable WPAD
    #https://adsecurity.org/?p=3299
    New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\" -Name "Wpad" -Force
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" -Name "Wpad" -Force
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" -Name "WpadOverride" -Type "DWORD" -Value 1 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" -Name "WpadOverride" -Type "DWORD" -Value 1 -Force

    $ResultText.text = "`r`n" + "  Enable LSA Protection/Auditing.."
    #Enable LSA Protection/Auditing
    #https://adsecurity.org/?p=3299
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\" -Name "LSASS.exe" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\LSASS.exe" -Name "AuditLevel" -Type "DWORD" -Value 8 -Force

    $ResultText.text = "`r`n" + "  Disabling Windows Script Host.."
    #Disable Windows Script Host
    #https://adsecurity.org/?p=3299
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\" -Name "Settings" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" -Name "Enabled" -Type "DWORD" -Value 0 -Force
    
    $ResultText.text = "`r`n" + "  Disabling WDigest.."
    #Disable WDigest
    #https://adsecurity.org/?p=3299
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\SecurityProviders\Wdigest" -Name "UseLogonCredential" -Type "DWORD" -Value 0 -Force

    $ResultText.text = "`r`n" + "  Blocked Untrusted Fonts.."
    #Block Untrusted Fonts
    #https://adsecurity.org/?p=3299
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel\" -Name "MitigationOptions" -Type "QWORD" -Value "1000000000000" -Force
    
    $ResultText.text = "`r`n" + "  Disabling Office OLE.."
    #Disable Office OLE
    #https://adsecurity.org/?p=3299
    $officeversions = '16.0', '15.0', '14.0', '12.0'
    ForEach ($officeversion in $officeversions) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Office\$officeversion\Outlook\" -Name "Security" -Force
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Office\$officeversion\Outlook\" -Name "Security" -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\$officeversion\Outlook\Security\" -Name "ShowOLEPackageObj" -Type "DWORD" -Value "0" -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\$officeversion\Outlook\Security\" -Name "ShowOLEPackageObj" -Type "DWORD" -Value "0" -Force
    }

    $ResultText.text = "`r`n" + "  Disabling SMB 1.0 protocol.."
	Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

    $ResultText.text = "`r`n" + "  Disabling SMB Server.."
	Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
	Set-SmbServerConfiguration -EnableSMB2Protocol $false -Force
    #Windows Defender Configuration Files
    New-Item -Path "C:\" -Name "Temp" -ItemType "directory" -Force | Out-Null; New-Item -Path "C:\temp\" -Name "Windows Defender" -ItemType "directory" -Force | Out-Null; Copy-Item -Path .\Files\"Windows Defender Configuration Files"\* -Destination "C:\temp\Windows Defender\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    
    Start-Job -Name "Windows Defender Hardening" -ScriptBlock {
        #Enable Windows Defender Exploit Protection
        Set-ProcessMitigation -PolicyFilePath "C:\temp\Windows Defender\DOD_EP_V3.xml"
    
        #Enable Windows Defender Application Control
        #https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/select-types-of-rules-to-create
        Set-RuleOption -FilePath "C:\temp\Windows Defender\WDAC_V1_Recommended_Audit.xml" -Option 0
    
        #Windows Defender Hardening
        #https://www.powershellgallery.com/packages/WindowsDefender_InternalEvaluationSetting
        #Enable real-time monitoring
        $ResultText.text = "`r`n" + "  Enable real-time monitoring"
        Set-MpPreference -DisableRealtimeMonitoring 0
        #Enable sample submission
        $ResultText.text = "`r`n" + "  Enable sample submission"
        Set-MpPreference -SubmitSamplesConsent 2
        #Enable checking signatures before scanning
        $ResultText.text = "`r`n" + "  Enable checking signatures before scanning"
        Set-MpPreference -CheckForSignaturesBeforeRunningScan 1
        #Enable behavior monitoring
        $ResultText.text = "`r`n" + "  Enable behavior monitoring"
        Set-MpPreference -DisableBehaviorMonitoring 0
        #Enable IOAV protection
        $ResultText.text = "`r`n" + "  Enable IOAV protection"
        Set-MpPreference -DisableIOAVProtection 0
        #Enable script scanning
        $ResultText.text = "`r`n" + "  Enable script scanning"
        Set-MpPreference -DisableScriptScanning 0
        #Enable removable drive scanning
        $ResultText.text = "`r`n" + "  Enable removable drive scanning"
        Set-MpPreference -DisableRemovableDriveScanning 0
        #Enable Block at first sight
        $ResultText.text = "`r`n" + "  Enable Block at first sight"
        Set-MpPreference -DisableBlockAtFirstSeen 0
        #Enable potentially unwanted 
        $ResultText.text = "`r`n" + "  Enable potentially unwanted apps"
        Set-MpPreference -PUAProtection Enabled
        #Schedule signature updates every 8 hours
        $ResultText.text = "`r`n" + "  Schedule signature updates every 8 hours"
        Set-MpPreference -SignatureUpdateInterval 8
        #Enable archive scanning
        $ResultText.text = "`r`n" + "  Enable archive scanning"
        Set-MpPreference -DisableArchiveScanning 0
        #Enable email scanning
        $ResultText.text = "`r`n" + "  Enable email scanning"
        Set-MpPreference -DisableEmailScanning 0
        #Enable File Hash Computation
        $ResultText.text = "`r`n" + "  Enable File Hash Computation"
        Set-MpPreference -EnableFileHashComputation 1
        #Enable Intrusion Prevention System
        $ResultText.text = "`r`n" + "  Enable Intrusion Prevention System"
        Set-MpPreference -DisableIntrusionPreventionSystem $false
        #Enable Windows Defender Exploit Protection
        $ResultText.text = "`r`n" + "  Enabling Exploit Protection"
        Set-ProcessMitigation -PolicyFilePath C:\temp\"Windows Defender"\DOD_EP_V3.xml
        #Set cloud block level to 'High'
        $ResultText.text = "`r`n" + "  Set cloud block level to 'High'"
        Set-MpPreference -CloudBlockLevel High
        #Set cloud block timeout to 1 minute
        $ResultText.text = "`r`n" + "  Set cloud block timeout to 1 minute"
        Set-MpPreference -CloudExtendedTimeout 50
        $ResultText.text = "`r`n" + "  Updating Windows Defender Exploit Guard settings"
        #Enabling Controlled Folder Access and setting to block mode
        #Set-MpPreference -EnableControlledFolderAccess Enabled 
        #Enabling Network Protection and setting to block mode
        $ResultText.text = "`r`n" + "  Enabling Network Protection and setting to block mode"
        Set-MpPreference -EnableNetworkProtection Enabled
    
        #Enable Cloud-delivered Protections
        #Set-MpPreference -MAPSReporting Advanced
        #Set-MpPreference -SubmitSamplesConsent SendAllSamples
    
        #Enable Windows Defender Attack Surface Reduction Rules
        #https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/enable-attack-surface-reduction
        #https://docs.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-atp/attack-surface-reduction
        #Block executable content from email client and webmail
        Add-MpPreference -AttackSurfaceReductionRules_Ids BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550 -AttackSurfaceReductionRules_Actions Enabled
        #Block all Office applications from creating child processes
        Add-MpPreference -AttackSurfaceReductionRules_Ids D4F940AB-401B-4EFC-AADC-AD5F3C50688A -AttackSurfaceReductionRules_Actions Enabled
        #Block Office applications from creating executable content
        Add-MpPreference -AttackSurfaceReductionRules_Ids 3B576869-A4EC-4529-8536-B80A7769E899 -AttackSurfaceReductionRules_Actions Enabled
        #Block Office applications from injecting code into other processes
        Add-MpPreference -AttackSurfaceReductionRules_Ids 75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84 -AttackSurfaceReductionRules_Actions Enabled
        #Block JavaScript or VBScript from launching downloaded executable content
        Add-MpPreference -AttackSurfaceReductionRules_Ids D3E037E1-3EB8-44C8-A917-57927947596D -AttackSurfaceReductionRules_Actions Enabled
        #Block execution of potentially obfuscated scripts
        Add-MpPreference -AttackSurfaceReductionRules_Ids 5BEB7EFE-FD9A-4556-801D-275E5FFC04CC -AttackSurfaceReductionRules_Actions Enabled
        #Block Win32 API calls from Office macros
        Add-MpPreference -AttackSurfaceReductionRules_Ids 92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B -AttackSurfaceReductionRules_Actions Enabled
        #Block executable files from running unless they meet a prevalence, age, or trusted list criterion
        Add-MpPreference -AttackSurfaceReductionRules_Ids 01443614-cd74-433a-b99e-2ecdc07bfc25 -AttackSurfaceReductionRules_Actions AuditMode
        #Use advanced protection against ransomware
        Add-MpPreference -AttackSurfaceReductionRules_Ids c1db55ab-c21a-4637-bb3f-a12568109d35 -AttackSurfaceReductionRules_Actions Enabled
        #Block credential stealing from the Windows local security authority subsystem
        Add-MpPreference -AttackSurfaceReductionRules_Ids 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2 -AttackSurfaceReductionRules_Actions Enabled
        #Block process creations originating from PSExec and WMI commands
        Add-MpPreference -AttackSurfaceReductionRules_Ids d1e49aac-8f56-4280-b9ba-993a6d77406c -AttackSurfaceReductionRules_Actions AuditMode
        #Block untrusted and unsigned processes that run from USB
        Add-MpPreference -AttackSurfaceReductionRules_Ids b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4 -AttackSurfaceReductionRules_Actions Enabled
        #Block Office communication application from creating child processes
        Add-MpPreference -AttackSurfaceReductionRules_Ids 26190899-1602-49e8-8b27-eb1d0a1ce869 -AttackSurfaceReductionRules_Actions Enabled
        #Block Adobe Reader from creating child processes
        Add-MpPreference -AttackSurfaceReductionRules_Ids 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c -AttackSurfaceReductionRules_Actions Enabled
        #Block persistence through WMI event subscription
        Add-MpPreference -AttackSurfaceReductionRules_Ids e6db77e5-3df2-4cf1-b95a-636979351e5b -AttackSurfaceReductionRules_Actions Enabled
    
        $ResultText.text = "`r`n" + "  Windows defender security patches has been applied..."
    }

    Start-Job -Name "SSL Hardening" -ScriptBlock {

        #Increase Diffie-Hellman key (DHK) exchange to 4096-bit
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman" -Force 
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman" -Force -Name ServerMinKeyBitLength -Type "DWORD" -Value 0x00001000
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman" -Force -Name ClientMinKeyBitLength -Type "DWORD" -Value 0x00001000
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman" -Force -Name Enabled -Type "DWORD" -Value 0x00000001
    
        #Disable RC2 cipher
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 40/128" -Force 
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 56/128" -Force 
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 128/128" -Force 
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 40/128" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 56/128" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC2 128/128" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
    
        #Disable RC4 cipher
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128" -Force
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 64/128" -Force  
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128" -Force
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128" -Force  
        #New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 128/128" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        #New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 64/128" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        #New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 56/128" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        #New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\RC4 40/128" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
    
        #Disable DES cipher
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56" -Force
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56/56" -Force  
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\DES 56/56" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
    
        #Disable 3DES (Triple DES) cipher
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168" -Force
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168/168" -Force  
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\Triple DES 168/168" -Force -Name Enabled -Type "DWORD" -Value 0x00000000       
    
        #Disable MD5 hash function
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\MD5" -Force
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\MD5" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
    
        #Disable SHA1
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA" -Force
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
    
        #Disable null cipher
        #New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL" -Force
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\NULL" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
    
        #Force not to respond to renegotiation requests
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL" -Force -Name AllowInsecureRenegoClients -Type "DWORD" -Value 0x00000000
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL" -Force -Name AllowInsecureRenegoServers -Type "DWORD" -Value 0x00000000
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL" -Force -Name DisableRenegoOnServer -Type "DWORD" -Value 0x00000001
        #Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL" -Force -Name UseScsvForTls -Type "DWORD" -Value 0x00000001
    
        #Disable SSL v2
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client"-Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" -Force -Name Enabled -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" -Force -Name Enabled -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 1
    
        #Disable SSL v3
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"-Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" -Force -Name Enabled -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" -Force -Name Enabled -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 1
    
        #Enable TLS 1.0
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" -Force -Name Enabled -Type "DWORD" -Value 0x00000000
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 0x00000001
    
        #Enable DTLS 1.0
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.0\Server" -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.0\Client" -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.0\Server" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.0\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.0\Client" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.0\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
    
        #Enable TLS 1.1
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
    
        #Enable DTLS 1.1
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.1\Server" -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.1\Client" -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.1\Server" -Force -Name Enabled -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.1\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.1\Client" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.1\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
    
        #Enable TLS 1.2
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
    
        #Enable TLS 1.3
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server" -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client" -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
    
        #Enable DTLS 1.3
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.3\Server" -Force
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.3\Client" -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.3\Server" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.3\Server" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.3\Client" -Force -Name Enabled -Type "DWORD" -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\DTLS 1.3\Client" -Force -Name DisabledByDefault -Type "DWORD" -Value 0
    
        #Enable Strong Authentication for .NET applications (TLS 1.2)
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" -Force -Name SchUseStrongCrypto -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" -Force -Name SystemDefaultTlsVersions -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v3.0" -Force -Name SchUseStrongCrypto -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v3.0" -Force -Name SystemDefaultTlsVersions -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -Force -Name SchUseStrongCrypto -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -Force -Name SystemDefaultTlsVersions -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727" -Force -Name SchUseStrongCrypto -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727" -Force -Name SystemDefaultTlsVersions -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v3.0" -Force -Name SchUseStrongCrypto -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v3.0" -Force -Name SystemDefaultTlsVersions -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" -Force -Name SchUseStrongCrypto -Type "DWORD" -Value 0x00000001
        Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" -Force -Name SystemDefaultTlsVersions -Type "DWORD" -Value 0x00000001
    
        $ResultText.text = "`r`n" + "  SSL Hardening Activated..."
    }
    
    Start-Job -Name "SMB Optimizations and Hardening" -ScriptBlock {
        #https://docs.microsoft.com/en-us/windows/privacy/
        #https://docs.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
        #https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909
        #https://docs.microsoft.com/en-us/powershell/module/smbshare/set-smbserverconfiguration?view=win10-ps
        #SMB Optimizations
        Write-Output "SMB Optimizations"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "DisableBandwidthThrottling" -Type "DWORD" -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "FileInfoCacheEntriesMax" -Type "DWORD" -Value 1024 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "DirectoryCacheEntriesMax" -Type "DWORD" -Value 1024 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "FileNotFoundCacheEntriesMax" -Type "DWORD" -Value 2048 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type "DWORD" -Value 20 -Force
        Set-SmbServerConfiguration -EnableMultiChannel $true -Force 
        Set-SmbServerConfiguration -MaxChannelPerSession 16 -Force
        Set-SmbServerConfiguration -ServerHidden $False -AnnounceServer $False -Force
        Set-SmbServerConfiguration -EnableLeasing $false -Force
        Set-SmbClientConfiguration -EnableLargeMtu $true -Force
        Set-SmbClientConfiguration -EnableMultiChannel $true -Force
        
        #SMB Hardening
        Write-Output "SMB Hardening"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" -Name "RestrictNullSessAccess" -Type "DWORD" -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "RestrictAnonymousSAM" -Type "DWORD" -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "RequireSecuritySignature" -Value 256 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\LSA" -Name "RestrictAnonymous" -Type "DWORD" -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "NoLMHash" -Type "DWORD" -Value 1 -Force
        Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart
        Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Client" -NoRestart
        Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Server" -NoRestart
        Set-SmbClientConfiguration -RequireSecuritySignature $True -Force
        Set-SmbClientConfiguration -EnableSecuritySignature $True -Force
        Set-SmbServerConfiguration -EncryptData $True -Force 
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force 

        $ResultText.text = "`r`n" + "  SMB Optimized and Hardening Activated..."
    }

    $ResultText.text = "`r`n" + "  All known security exploits have been patched successfully & additional system hardening has been applied - Ready for Next Task..."
})

$onedrive.Add_Click({
    $ResultText.text = "`r`n" + "  Disabling OneDrive..."
    If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1
    $ResultText.text = "`r`n" + "  Uninstalling OneDrive..."
    Stop-Process -Name "OneDrive" -ErrorAction SilentlyContinue
    Start-Sleep -s 2
    $onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    If (!(Test-Path $onedrive)) {
        $onedrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
    }
    Start-Process $onedrive "/uninstall" -NoNewWindow -Wait
    Start-Sleep -s 2
    Stop-Process -Name "explorer" -ErrorAction SilentlyContinue
    Start-Sleep -s 2
    Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue
    If (!(Test-Path "HKCR:")) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }
    Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue
    $ResultText.text = "`r`n" + "  Deleted and Disabled OneDrive - Ready for Next Task..."
})

$darkmode.Add_Click({
    $ResultText.text = "`r`n" + "  Setting dark mode to active"
    New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -PropertyType "DWord" -Name "AppsUseLightTheme" -Value "0" -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value "0"
    $ResultText.text = "`r`n" + "  Dark mode successfully activated - Ready for Next Task..."
})

$lightmode.Add_Click({
    $ResultText.text = "`r`n" + "  Switching Back to Light Mode"
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Force
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1
    $ResultText.text = "`r`n" + "  Enabled Light Mode - Ready for Next Task..."
})

$EClipboardHistory.Add_Click({
	$ResultText.text = "`r`n" + "  Restoring Clipboard History..."
	Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Clipboard" -Name "EnableClipboardHistory" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -ErrorAction SilentlyContinue
    $ResultText.text = "`r`n" + "  Enabled Clipboard History - Ready for Next Task..."
})

$ELocation.Add_Click({
	$ResultText.text = "`r`n" + "  Enabling Location Provider..."
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableWindowsLocationProvider" -ErrorAction SilentlyContinue
	$ResultText.text = "`r`n" + "  Enabling Location Scripting..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocationScripting" -ErrorAction SilentlyContinue
	$ResultText.text = "`r`n" + "  Enabling Location..."
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "Value" -Type String -Value "Allow"
	$ResultText.text = "`r`n" + "  Allow access to Location..."
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Allow"
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value "1"
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessLocation" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessLocation_UserInControlOfTheseApps" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessLocation_ForceAllowTheseApps" -ErrorAction SilentlyContinue
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsAccessLocation_ForceDenyTheseApps" -ErrorAction SilentlyContinue
    $ResultText.text = "`r`n" + "  Location Tracking now on - Reboot to check.."
})


$EHibernation.Add_Click({
    $ResultText.text = "`r`n" + "  Enabling Hibernation..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -Type Dword -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 1
    $ResultText.text = "`r`n" + "  Enabled Hibernation - Ready for Next Task..."
})

$InstallOneDrive.Add_Click({
    $ResultText.text = "`r`n" + "  Installing Onedrive. Please Wait..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -ErrorAction SilentlyContinue
    %systemroot%\SysWOW64\OneDriveSetup.exe
    $ResultText.text = "`r`n" + "  Finished Reinstalling OneDrive - Ready for Next Task..."
})

$DisableNumLock.Add_Click({
    $ResultText.text = "`r`n" + "  Disable NumLock after startup..."
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 0
    Add-Type -AssemblyName System.Windows.Forms
    If (([System.Windows.Forms.Control]::IsKeyLocked('NumLock'))) {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.SendKeys('{NUMLOCK}')
    }
    $ResultText.text = "`r`n" + "  Disable NumLock after startup... - Restart or Logout to Apply.."
})

#Add secondary en-US keyboard
$addENkeyboard.Add_Click({
    $ResultText.text = "`r`n" + "  Setting Norwegian keyboard default... - Ready for Next Task..."

    Set-WinUserLanguageList -LanguageList nb-NO, nb-NO -Force
})

# Remove secondary en-US keyboard
$removeENkeyboard.Add_Click({
    $ResultText.text = "`r`n" + "  Removing secondary en-US keyboard settings nb-NO to default... - Ready for Next Task..."

    Set-WinUserLanguageList -LanguageList nb-NO, nb-NO -Force

    Start-Sleep -s 5

    $1 = Get-WinUserLanguageList
    $1.RemoveAll( { $args[0].LanguageTag -clike 'us*' } )
    Set-WinUserLanguageList $1 -Force

    $2 = Get-WinUserLanguageList
    $2.RemoveAll( { $args[0].LanguageTag -clike 'en*' } )
    Set-WinUserLanguageList $2 -Force

})

$killedge.Add_Click({
    $ResultText.text = "`r`n" + "  Removing Microsoft Edge..."
    Invoke-WebRequest -useb https://raw.githubusercontent.com/alerion921/WinTool-for-10-11/main/Files/killedge.bat | Invoke-Expression

    #removes shortcut from programdata
    Get-ChildItem "C:\ProgramData\Microsoft\Windows\Start Menu\Programs" -Recurse  -Filter *Edge*.lnk |
    ForEach-Object {
       Remove-Item $_.FullName
    }

    $ResultText.text = "`r`n" + "  Microsoft Edge has been successfully removed - Ready for Next Task..."
})

$ncpa.Add_Click({ #Network cards interface
    $ResultText.text = "`r`n" + "  Opened Network Interfaces..."
    cmd /c ncpa.cpl
})

$oldsoundpanel.Add_Click({ #Old sound control panel
    $ResultText.text = "`r`n" + "  Opened Old Sound Panel..."
    cmd /c mmsys.cpl
})

$oldcontrolpanel.Add_Click({ #Old controlpanel
    $ResultText.text = "`r`n" + "  Opened Old Control Panel..."
    cmd /c control
})

$oldsystempanel.Add_Click({ #Old system panel
    $ResultText.text = "`r`n" + "  Opened System Properties..."
    cmd /c sysdm.cpl
})

$oldpower.Add_Click({
    $ResultText.text = "`r`n" + "  Opened Advanced Power Options..."
    cmd /c powercfg.cpl
})

$restorepower.Add_Click({
    if(!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Power Saver")){powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a}
    if(!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Balanced")){powercfg -duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e}
    if(!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Ultimate Performance")){powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61}
    $ResultText.text = "`r`n" + "  Restored all power plans: Power Saver, Balanced, and Ultimate Performance - Ready for Next Task..."
})

$NFS.Add_Click({
    Enable-WindowsOptionalFeature -Online -FeatureName "ServicesForNFS-ClientOnly" -All
    Enable-WindowsOptionalFeature -Online -FeatureName "ClientForNFS-Infrastructure" -All
    Enable-WindowsOptionalFeature -Online -FeatureName "NFS-Administration" -All
    nfsadmin client stop
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousUID" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousGID" -Type DWord -Value 0
    nfsadmin client start
    nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i
    $ResultText.text = "`r`n" + "  NFS is now setup for user based NFS mounts - Ready for Next Task..."
})

$resetnetwork.Add_Click({
    cmd /c netsh winsock reset
    $ResultText.text = "`r`n" + "  1. Winsock reset!"
    cmd /c netsh int ip reset
    $ResultText.text = "`r`n" + "  2. IP reset!"
    cmd /c netsh advfirewall reset
    $ResultText.text = "`r`n" + "  3. Firewall reset!"
    cmd /c ipconfig /release
    cmd /c ipconfig /flushdns
    $ResultText.text = "`r`n" + "  4. DNS Flushed!"
    cmd /c ipconfig /renew
    $ResultText.text = "`r`n" + "  5. IP renewed!"
    $ResultText.text = "`r`n" + "  6. Network settings restored to default! - Ready for Next Task..."
    
})

$windowsupdatefix.Add_Click({
    $ResultText.text = "`r`n" + "  1. Stopping Windows Update Services..."
    Stop-Service -Name BITS 
    Stop-Service -Name wuauserv 
    Stop-Service -Name appidsvc 
    Stop-Service -Name cryptsvc 
    
    $ResultText.text = "`r`n" + "  2. Remove QMGR Data file..."
    Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue 
    
    $ResultText.text = "`r`n" + "  3. Renaming the Software Distribution and CatRoot Folder..."
    Rename-Item $env:systemroot\SoftwareDistribution SoftwareDistribution.bak -ErrorAction SilentlyContinue #should probably delete these files with the ultimate cleaner but has not been setup yet
    Rename-Item $env:systemroot\System32\Catroot2 catroot2.bak -ErrorAction SilentlyContinue #should probably delete these files with the ultimate cleaner but has not been setup yet
    
    $ResultText.text = "`r`n" + "  4. Removing old Windows Update log..."
    Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction SilentlyContinue 
    
    $ResultText.text = "`r`n" + "  5. Resetting the Windows Update Services to defualt settings..."
    "sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 
    "sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 
    
    Set-Location $env:systemroot\system32 
    
    $ResultText.text = "`r`n" + "  6. Registering usefull DLLs..."
    regsvr32.exe /s atl.dll 
    regsvr32.exe /s urlmon.dll 
    regsvr32.exe /s mshtml.dll 
    regsvr32.exe /s shdocvw.dll 
    regsvr32.exe /s browseui.dll 
    regsvr32.exe /s jscript.dll 
    regsvr32.exe /s vbscript.dll 
    regsvr32.exe /s scrrun.dll 
    regsvr32.exe /s msxml.dll 
    regsvr32.exe /s msxml3.dll 
    regsvr32.exe /s msxml6.dll 
    regsvr32.exe /s actxprxy.dll 
    regsvr32.exe /s softpub.dll 
    regsvr32.exe /s wintrust.dll 
    regsvr32.exe /s dssenh.dll 
    regsvr32.exe /s rsaenh.dll 
    regsvr32.exe /s gpkcsp.dll 
    regsvr32.exe /s sccbase.dll 
    regsvr32.exe /s slbcsp.dll 
    regsvr32.exe /s cryptdlg.dll 
    regsvr32.exe /s oleaut32.dll 
    regsvr32.exe /s ole32.dll 
    regsvr32.exe /s shell32.dll 
    regsvr32.exe /s initpki.dll 
    regsvr32.exe /s wuapi.dll 
    regsvr32.exe /s wuaueng.dll 
    regsvr32.exe /s wuaueng1.dll 
    regsvr32.exe /s wucltui.dll 
    regsvr32.exe /s wups.dll 
    regsvr32.exe /s wups2.dll 
    regsvr32.exe /s wuweb.dll 
    regsvr32.exe /s qmgr.dll 
    regsvr32.exe /s qmgrprxy.dll 
    regsvr32.exe /s wucltux.dll 
    regsvr32.exe /s muweb.dll 
    regsvr32.exe /s wuwebv.dll 
    
    $ResultText.text = "`r`n" + "  7. Removing WSUS client settings..."
    REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f 
    REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f 
    REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f 
    
    $ResultText.text = "`r`n" + "  8. Resetting the WinSock..."
    netsh winsock reset 
    netsh winhttp reset proxy 
    
    $ResultText.text = "`r`n" + "  9. Delete all BITS jobs..."
    Get-BitsTransfer | Remove-BitsTransfer 
    
    $ResultText.text = "`r`n" + "  10. Attempting to install the Windows Update Agent..."
    if($arch -eq 64){ 
        wusa Windows8-RT-KB2937636-x64 /quiet 
    } 
    else{ 
        wusa Windows8-RT-KB2937636-x86 /quiet 
    } 
    
    $ResultText.text = "`r`n" + "  11. Starting Windows Update Services..."
    Start-Service -Name BITS 
    Start-Service -Name wuauserv 
    Start-Service -Name appidsvc 
    Start-Service -Name cryptsvc 
    
    $ResultText.text = "`r`n" + "  12. Forcing discovery..."
    wuauclt /resetauthorization /detectnow 
    
    $ResultText.text = "`r`n" + "  Process complete - Please reboot your computer.."

})

$Form.ShowDialog() | Out-Null
}
MakeForm