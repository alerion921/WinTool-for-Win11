# Import the ShowWindow function from user32.dll to manipulate the PowerShell window state.
# This allows us to hide the PowerShell console window.
#$HidePowershellWindow = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'

# Add the ShowWindow method to the PowerShell runtime as a .NET class.
#add-type -name win -member $HidePowershellWindow -namespace native

# Retrieve the current process's main window handle and hide it (state = 0).
#[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

# Enable the use of Windows Forms for potential GUI elements (not used in this script, but prepares for it).
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Set the error handling preference to silently ignore errors.
$ErrorActionPreference = 'SilentlyContinue'

# Create an object to interact with Windows Shell for launching processes.
$wshell = New-Object -ComObject Wscript.Shell

# Check if the current user has administrator privileges.
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    # If not running as administrator, restart the script with elevated permissions.
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    # Exit the current (non-elevated) instance of the script.
    Exit
}

# Global Environment folder setup here
# Retrieves commonly used folder paths using [Environment]::GetFolderPath
$pathDesktop        = [Environment]::GetFolderPath("Desktop")                # Path to the Desktop folder
#$pathDocuments      = [Environment]::GetFolderPath("MyDocuments")           # Path to the Documents folder
#$pathPictures       = [Environment]::GetFolderPath("MyPictures")            # Path to the Pictures folder
#$pathAppdataLocal   = [Environment]::GetFolderPath("LocalApplicationData")  # Path to the local AppData folder
#$pathAppdataRoaming = [Environment]::GetFolderPath("ApplicationData")       # Path to the roaming AppData folder
#$pathWindows        = [Environment]::GetFolderPath("Windows")               # Path to the Windows folder
#$pathSystem         = [Environment]::GetFolderPath("System")                # Path to the System folder (e.g., System32)
####################################################################################

function EnsureWinget {
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Winget (Windows Package Manager) is not available. Please update your Windows installation to use this script.", 
            "Winget Not Found", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
    return $true
}

function IsAppInstalled {
    param (
        [string]$AppName,
        [array]$AdditionalPaths = @()
    )

    # Base paths to check
    $basePaths = @(
        "C:\Program Files\$AppName",
        "C:\Program Files (x86)\$AppName",
        "$([Environment]::GetFolderPath('LocalApplicationData'))\$AppName",
        "$([Environment]::GetFolderPath('ApplicationData'))\$AppName"
    )

    # Include additional paths specific to certain applications
    $allPaths = $basePaths + $AdditionalPaths

    # Check each path for traditional apps
    foreach ($path in $allPaths) {
        if (Test-Path $path) {
            return $true
        }
    }

    # Check for UWP apps using Get-AppxPackage with stricter matching
    try {
        $installedPackages = Get-AppxPackage
        foreach ($package in $installedPackages) {
            # Match AppName against the Name property (case-insensitive exact match)
            if ($package.Name -ieq $AppName -or $package.PackageFullName -like "*$AppName*") {
                return $true
            }
        }
    } catch {
        Write-Warning "Failed to query UWP apps: $_"
    }

    # If no match is found
    return $false
}

function ShowAppSelectionForm {
    $frontcolor = [System.Drawing.ColorTranslator]::FromHtml("#182C36")
    $backcolor  = [System.Drawing.ColorTranslator]::FromHtml("#5095B5")
    $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#346075")

    # Array to store checkbox references
    $checkboxes = @()

    $appSelectionForm = New-Object System.Windows.Forms.Form
    $appSelectionForm.Text = "Select Applications to Install"
    $appSelectionForm.StartPosition = "CenterScreen"
    $appSelectionForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $appSelectionForm.MaximizeBox = $false # Disable the maximize button
    $appSelectionForm.MinimizeBox = $true # Optionally keep the minimize button enabled

    # Dynamically adjust size based on screen resolution
    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
    $appSelectionForm.Size = New-Object System.Drawing.Size([math]::Min($screenWidth * 0.8, 805), [math]::Min($screenHeight * 0.8, 600))

    # Create a flow layout panel for dynamic arrangement
    $flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $flowLayoutPanel.AutoScroll = $true
    $flowLayoutPanel.WrapContents = $true
    $flowLayoutPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
    $appSelectionForm.Controls.Add($flowLayoutPanel)

    function CreateCategoryPanel($category) {
        $panel = New-Object System.Windows.Forms.Panel
        $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $panel.Size = New-Object System.Drawing.Size(250, 300)

        # Add category label
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $category.Name
        $label.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
        $label.AutoSize = $true
        $label.Location = New-Object System.Drawing.Point(5, 5)
        $panel.Controls.Add($label)

        # Create a sub-panel for checkboxes
        $checkboxPanel = New-Object System.Windows.Forms.Panel
        $checkboxPanel.AutoScroll = $true
        $checkboxPanel.Size = New-Object System.Drawing.Size(240, 260)
        $checkboxPanel.Location = New-Object System.Drawing.Point(5, 25)

        foreach ($app in $category.Applications) {
            $isInstalled = IsAppInstalled -AppName $app.AppName -AdditionalPaths $app.AdditionalPaths

            $checkbox = New-Object System.Windows.Forms.CheckBox
            $checkbox.Text = $app.Name
            $checkbox.Enabled = -not $isInstalled
            $checkbox.AutoSize = $true
            $checkbox.Tag = $app # Store app details in the Tag property
            $checkbox.Dock = [System.Windows.Forms.DockStyle]::Top
            $checkboxPanel.Controls.Add($checkbox)

            # Add checkbox to global array
            $script:checkboxes += $checkbox

            # Debugging output
            Write-Host "Added checkbox for: $($app.Name) (Enabled: $($checkbox.Enabled))"
        }

        $panel.Controls.Add($checkboxPanel)
        return $panel
    }
            $categories = @(
                @{ Name = "Browsers"; Applications = @(
                    @{ Name = "Brave Browser"; AppName = "BraveSoftware"; WingetID = "Brave.Brave"; AdditionalPaths = @("Brave-Browser\Application") },
                    @{ Name = "Google Chrome"; AppName = "Google"; WingetID = "Google.Chrome"; AdditionalPaths = @("Google Chrome\Application\chrome.exe") },
                    @{ Name = "Mozilla Firefox"; AppName = "Mozilla Firefox"; WingetID = "Mozilla.Firefox"; AdditionalPaths = @("firefox.exe") },
                    @{ Name = "Microsoft Edge"; AppName = "Microsoft Edge"; WingetID = "Microsoft.Edge"; AdditionalPaths = @("Microsoft\Edge\Application\msedge.exe") },
                    @{ Name = "Opera"; AppName = "Opera Software"; WingetID = "Opera.Opera"; AdditionalPaths = @("Opera\launcher.exe") },
                    @{ Name = "Vivaldi"; AppName = "Vivaldi Technologies"; WingetID = "Vivaldi.Vivaldi"; AdditionalPaths = @("Vivaldi\Application\vivaldi.exe") },
                    @{ Name = "Tor Browser"; AppName = "The Tor Project"; WingetID = "TorProject.TorBrowser"; AdditionalPaths = @("Tor Browser\Browser\firefox.exe") }
                )},
                @{ Name = "Video Apps"; Applications = @(
                    @{ Name = "Netflix"; AppName = "Netflix"; WingetID = "9wzdncrfj3tj"; AdditionalPaths = @() },
                    @{ Name = "Disney+"; AppName = "DisneyPlus"; WingetID = "Disney.DisneyPlus"; AdditionalPaths = @() },
                    @{ Name = "Hulu"; AppName = "Hulu"; WingetID = "Hulu.HuluApp"; AdditionalPaths = @() },
                    @{ Name = "VLC Media Player"; AppName = "VideoLAN"; WingetID = "VideoLAN.VLC"; AdditionalPaths = @("VLC\vlc.exe") },
                    @{ Name = "Amazon Prime Video"; AppName = "Prime Video"; WingetID = "Amazon.PrimeVideo"; AdditionalPaths = @() },
                    @{ Name = "YouTube"; AppName = "YouTube"; WingetID = "Google.YouTube"; AdditionalPaths = @() },
                    @{ Name = "Plex"; AppName = "Plex"; WingetID = "Plex.PlexMediaServer"; AdditionalPaths = @() },
                    @{ Name = "Kodi"; AppName = "Kodi"; WingetID = "XBMCFoundation.Kodi"; AdditionalPaths = @() },
                    @{ Name = "Twitch"; AppName = "Twitch"; WingetID = "Twitch.Twitch"; AdditionalPaths = @() }
                )},
                @{ Name = "Music Apps"; Applications = @(
                    @{ Name = "Spotify"; AppName = "Spotify"; WingetID = "9ncbcszsjrsb"; AdditionalPaths = @("Spotify.exe") },
                    @{ Name = "Apple Music"; AppName = "Apple Music"; WingetID = "Apple.Music"; AdditionalPaths = @() },
                    @{ Name = "YouTube Music"; AppName = "YouTube Music"; WingetID = "YouTube.Music"; AdditionalPaths = @() },
                    @{ Name = "Amazon Music"; AppName = "Amazon Music"; WingetID = "Amazon.AmazonMusic"; AdditionalPaths = @() },
                    @{ Name = "Tidal"; AppName = "Tidal"; WingetID = "TIDAL.TIDAL"; AdditionalPaths = @() },
                    @{ Name = "Pandora"; AppName = "Pandora"; WingetID = "Pandora.Pandora"; AdditionalPaths = @() },
                    @{ Name = "Deezer"; AppName = "Deezer"; WingetID = "Deezer.Deezer"; AdditionalPaths = @() }
                )},
                @{ Name = "Social Media"; Applications = @(
                    @{ Name = "Instagram"; AppName = "Instagram"; WingetID = "9nblggh5l9xt"; AdditionalPaths = @() },
                    @{ Name = "WhatsApp Desktop"; AppName = "WhatsApp"; WingetID = "9nksqgp7f2nh"; AdditionalPaths = @() },
                    @{ Name = "Telegram"; AppName = "Telegram Desktop"; WingetID = "Telegram.TelegramDesktop"; AdditionalPaths = @("Telegram.exe") },
                    @{ Name = "Discord"; AppName = "Discord"; WingetID = "Discord.Discord"; AdditionalPaths = @("Update.exe") },
                    @{ Name = "Zoom"; AppName = "Zoom"; WingetID = "Zoom.Zoom"; AdditionalPaths = @("bin\Zoom.exe") },
                    @{ Name = "Slack"; AppName = "Slack Technologies"; WingetID = "SlackTechnologies.Slack"; AdditionalPaths = @("Slack.exe") },
                    @{ Name = "Facebook"; AppName = "Facebook"; WingetID = "Facebook.Facebook"; AdditionalPaths = @() },
                    @{ Name = "Twitter"; AppName = "Twitter"; WingetID = "Twitter.Twitter"; AdditionalPaths = @() },
                    @{ Name = "LinkedIn"; AppName = "LinkedIn"; WingetID = "LinkedIn.LinkedIn"; AdditionalPaths = @() },
                    @{ Name = "Snapchat"; AppName = "Snapchat"; WingetID = "Snapchat.Snapchat"; AdditionalPaths = @() },
                    @{ Name = "TikTok"; AppName = "TikTok"; WingetID = "TikTok.TikTok"; AdditionalPaths = @() }
                )},
                @{ Name = "Tools"; Applications = @(
                    @{ Name = "Visual Studio Code"; AppName = "Microsoft VS Code"; WingetID = "Microsoft.VisualStudioCode"; AdditionalPaths = @("$([Environment]::GetFolderPath('LocalApplicationData'))\Programs\Microsoft VS Code\Code.exe") },
                    @{ Name = "Visual Studio Community"; AppName = "Microsoft Visual Studio"; WingetID = "Microsoft.VisualStudio.2022.Community"; AdditionalPaths = @("Common7\IDE\devenv.exe") },
                    @{ Name = "GitHub Desktop"; AppName = "GitHubDesktop"; WingetID = "GitHub.GitHubDesktop"; AdditionalPaths = @("GitHubDesktop.exe") },
                    @{ Name = "Postman"; AppName = "Postman"; WingetID = "Postman.Postman"; AdditionalPaths = @() },
                    @{ Name = "PuTTY"; AppName = "PuTTY"; WingetID = "PuTTY.PuTTY"; AdditionalPaths = @() },
                    @{ Name = "Dropbox"; AppName = "Dropbox"; WingetID = "Dropbox.Dropbox"; AdditionalPaths = @() },
                    @{ Name = "TeamViewer"; AppName = "TeamViewer"; WingetID = "TeamViewer.TeamViewer"; AdditionalPaths = @() }
                )},
                @{ Name = "Utilities"; Applications = @(
                    @{ Name = "7-Zip"; AppName = "7-Zip"; WingetID = "7zip.7zip"; AdditionalPaths = @() },
                    @{ Name = "WinRAR"; AppName = "WinRAR"; WingetID = "RARLab.WinRAR"; AdditionalPaths = @("WinRAR.exe") },
                    @{ Name = "Malwarebytes"; AppName = "Malwarebytes"; WingetID = "Malwarebytes.Malwarebytes"; AdditionalPaths = @() },
                    @{ Name = "FileZilla"; AppName = "FileZilla"; WingetID = "FileZilla.Client"; AdditionalPaths = @() },
                    @{ Name = "Notion"; AppName = "Notion"; WingetID = "Notion.Notion"; AdditionalPaths = @() },
                    @{ Name = "OpenVPN"; AppName = "OpenVPN"; WingetID = "OpenVPNTechnologies.OpenVPN"; AdditionalPaths = @() },
                    @{ Name = "KeePass"; AppName = "KeePass"; WingetID = "DominikReichl.KeePass"; AdditionalPaths = @() },
                    @{ Name = "Authy"; AppName = "Authy"; WingetID = "Twilio.Authy"; AdditionalPaths = @() },
                    @{ Name = "qBittorrent"; AppName = "qBittorrent"; WingetID = "qBittorrent.qBittorrent"; AdditionalPaths = @() }
                )},
                @{ Name = "Creative Tools"; Applications = @(
                    @{ Name = "Audacity"; AppName = "Audacity"; WingetID = "Audacity.Audacity"; AdditionalPaths = @() },
                    @{ Name = "OBS Studio"; AppName = "obs-studio"; WingetID = "OBSProject.OBSStudio"; AdditionalPaths = @() },
                    @{ Name = "GIMP"; AppName = "GIMP"; WingetID = "GIMP.GIMP"; AdditionalPaths = @() },
                    @{ Name = "Blender"; AppName = "Blender"; WingetID = "BlenderFoundation.Blender"; AdditionalPaths = @() },
                    @{ Name = "Inkscape"; AppName = "Inkscape"; WingetID = "Inkscape.Inkscape"; AdditionalPaths = @() },
                    @{ Name = "Paint.NET"; AppName = "Paint.NET"; WingetID = "dotPDNLLC.paintdotnet"; AdditionalPaths = @() },
                    @{ Name = "Adobe Creative Cloud"; AppName = "Adobe Creative Cloud"; WingetID = "Adobe.CreativeCloud"; AdditionalPaths = @() },
                    @{ Name = "Canva"; AppName = "Canva"; WingetID = "Canva.Canva"; AdditionalPaths = @() },
                    @{ Name = "HandBrake"; AppName = "HandBrake"; WingetID = "HandBrake.HandBrake"; AdditionalPaths = @() }
                )},
                @{ Name = "Documents/Editing"; Applications = @(
                    @{ Name = "LibreOffice"; AppName = "LibreOffice"; WingetID = "TheDocumentFoundation.LibreOffice"; AdditionalPaths = @() },
                    @{ Name = "Foxit PDF Reader"; AppName = "Foxit Reader"; WingetID = "Foxit.FoxitReader"; AdditionalPaths = @() },
                    @{ Name = "Notepad++"; AppName = "Notepad++"; WingetID = "Notepad++.Notepad++"; AdditionalPaths = @() },
                    @{ Name = "Adobe Acrobat Reader"; AppName = "Adobe"; WingetID = "Adobe.Acrobat.Reader.64-bit"; AdditionalPaths = @("Reader\AcroRd32.exe") },
                    @{ Name = "WPS Office"; AppName = "WPS Office"; WingetID = "Kingsoft.WPSOffice"; AdditionalPaths = @() },
                    @{ Name = "OnlyOffice"; AppName = "OnlyOffice"; WingetID = "OnlyOffice.DesktopEditors"; AdditionalPaths = @() },
                    @{ Name = "Sublime Text"; AppName = "Sublime Text"; WingetID = "SublimeHQ.SublimeText"; AdditionalPaths = @() }
                )},
                @{ Name = "Gaming"; Applications = @(
                    @{ Name = "Steam"; AppName = "Steam"; WingetID = "Valve.Steam"; AdditionalPaths = @("Steam.exe") },
                    @{ Name = "Epic Games"; AppName = "Epic Games"; WingetID = "EpicGames.EpicGamesLauncher"; AdditionalPaths = @("Launcher\EpicGamesLauncher.exe") },
                    @{ Name = "Battle.net"; AppName = "Battle.net"; WingetID = "Blizzard.BattleNet"; AdditionalPaths = @("Battle.net.exe") },
                    @{ Name = "EA Play"; AppName = "EA Play"; WingetID = "ElectronicArts.EADesktop"; AdditionalPaths = @("EA Desktop\EA Desktop.exe") },
                    @{ Name = "Ubisoft Connect"; AppName = "Ubisoft"; WingetID = "Ubisoft.Connect"; AdditionalPaths = @("Ubisoft Game Launcher\UbisoftConnect.exe") },
                    @{ Name = "GOG Galaxy"; AppName = "GOG Galaxy"; WingetID = "GOG.Galaxy"; AdditionalPaths = @("GalaxyClient.exe") },
                    @{ Name = "Valorant"; AppName = "Valorant"; WingetID = "RiotGames.Valorant.EU"; AdditionalPaths = @("Valorant.exe") },
                    @{ Name = "Minecraft"; AppName = "Minecraft Launcher"; WingetID = "Mojang.MinecraftLauncher"; AdditionalPaths = @("Minecraft.exe") },
                    @{ Name = "DS4Windows"; AppName = "DS4Windows"; WingetID = "Ryochan7.DS4Windows"; AdditionalPaths = @() },
                    @{ Name = "Amazon Games"; AppName = "Amazon Games"; WingetID = "Amazon.Games"; AdditionalPaths = @() }
                )}
            )

    # Populate categories
    foreach ($category in $categories) {
        $categoryPanel = CreateCategoryPanel $category
        $flowLayoutPanel.Controls.Add($categoryPanel)
    }

    # Add buttons and progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Size = New-Object System.Drawing.Size(700, 20)
    $progressBar.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $appSelectionForm.Controls.Add($progressBar)

    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $buttonPanel.Height = 40

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Install Selected"
    $okButton.Size = New-Object System.Drawing.Size(120, 30)
    $okButton.Location = New-Object System.Drawing.Point(10, 5)
    $okButton.Add_Click({
        # Ensure Winget is available before proceeding
        if (-not (EnsureWinget)) {
            return
        }
    
        # Dynamically collect selected applications from the flow layout panel
        $selectedApps = @()
    
        foreach ($control in $flowLayoutPanel.Controls) {
            if ($control -is [System.Windows.Forms.Panel]) {
                foreach ($subControl in $control.Controls) {
                    if ($subControl -is [System.Windows.Forms.Panel]) {
                        foreach ($checkbox in $subControl.Controls) {
                            if ($checkbox -is [System.Windows.Forms.CheckBox] -and $checkbox.Checked) {
                                $selectedApps += $checkbox.Tag
                            }
                        }
                    }
                }
            }
        }
    
        if ($selectedApps.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "No applications selected for installation.",
                "No Selection",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
    
        # Debugging output
        Write-Host "Selected apps for installation:"
        $selectedApps | ForEach-Object { Write-Host " - $($_.Name)" }
    
        # Install selected applications
        InstallApplications -SelectedApps $selectedApps -ProgressBar $progressBar
    })
    $buttonPanel.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel / Exit"
    $cancelButton.Size = New-Object System.Drawing.Size(120, 30)
    $cancelButton.Location = New-Object System.Drawing.Point(140, 5)
    $cancelButton.Add_Click({
        $appSelectionForm.Close()
    })
    $buttonPanel.Controls.Add($cancelButton)

    $appSelectionForm.Controls.Add($buttonPanel)

    [void]$appSelectionForm.ShowDialog()
}

function InstallApplications {
    param (
        [array]$SelectedApps,
        [System.Windows.Forms.ProgressBar]$ProgressBar
    )

    if (-not (EnsureWinget)) {
        return
    }

    $totalApps = $SelectedApps.Count
    $ProgressBar.Maximum = $totalApps

    foreach ($app in $SelectedApps) {
        try {
            # Install the app using WingetID
            if ($app.WingetID) {
                Start-Process -FilePath "winget" -ArgumentList "install --id $($app.WingetID) --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait
            } else {
                [System.Windows.Forms.MessageBox]::Show(
                    "$($app.Name) does not have a WingetID and must be installed manually.",
                    "Manual Installation Required",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }

            # Update progress bar
            $ProgressBar.Invoke([Action]{
                $ProgressBar.PerformStep()
            })
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Error installing $($app.Name): $_", 
                "Error", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }

    # Reset progress bar after completion
    $ProgressBar.Invoke([Action]{
        $ProgressBar.Value = 0
    })
}

# Function to Add Panels
Function Add-Panel {
    param (
        [int]$Width,
        [int]$Height,
        [System.Drawing.Point]$Location
    )
    $panel = New-Object system.Windows.Forms.Panel
    $panel.Width = $Width
    $panel.Height = $Height
    $panel.Location = $Location
    #$panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    return $panel
}

function Add-Control {
    param (
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 220,
        [int]$Height = 30,
        [string]$Font = 'Microsoft Sans Serif',
        [int]$FontSize = 12,
        [System.Drawing.Color]$BackColor = [System.Drawing.ColorTranslator]::FromHtml("#182C36"),
        [System.Drawing.Color]$ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5095B5"),
        [System.Drawing.Color]$HoverColor = [System.Drawing.ColorTranslator]::FromHtml("#346075"),
        [string]$ControlType = "Button" # Default to Button, can be "Label", "ComboBox", or "CheckBox"
    )

    switch ($ControlType) {
        "Button" {
            $control = New-Object system.Windows.Forms.Button -Property @{
                Text = $Text
                Width = $Width
                Height = $Height
                Location = New-Object System.Drawing.Point($X, $Y)
                Font = New-Object System.Drawing.Font($Font, $FontSize)
                BackColor = $BackColor
                ForeColor = $ForeColor
                FlatStyle = "Flat"
            }
            $control.FlatAppearance.MouseOverBackColor = $HoverColor
        }
        "Label" {
            $control = New-Object system.Windows.Forms.Label -Property @{
                Text = $Text
                Width = $Width
                Height = $Height
                Location = New-Object System.Drawing.Point($X, $Y)
                Font = New-Object System.Drawing.Font($Font, $FontSize, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
                ForeColor = $BackColor
                TextAlign = "MiddleCenter"
                BackColor = $ForeColor # Optional: Makes the label's background visible
                AutoSize = $false
            }
        }
        "ComboBox" {
            $control = New-Object system.Windows.Forms.ComboBox -Property @{
                Width = $Width
                Height = $Height
                Location = New-Object System.Drawing.Point($X, $Y)
                Font = New-Object System.Drawing.Font($Font, $FontSize)
                FlatStyle = "Flat" # Match button style
                BackColor = $BackColor
                ForeColor = $ForeColor
            }
            $control.DropDownStyle = "DropDownList"
            $control.Refresh()
        }
        "CheckBox" {
            $control = New-Object system.Windows.Forms.CheckBox -Property @{
                Text = $Text
                Width = $Width
                Height = $Height
                Location = New-Object System.Drawing.Point($X, $Y)
                Font = New-Object System.Drawing.Font($Font, $FontSize)
                BackColor = $ForeColor
                ForeColor = $BackColor
                AutoSize = $false
            }
        }
        default {
            throw "Unsupported control type: $ControlType"
        }
    }
    return $control
}

function Initialize-Cleaning {
    param (
        [string]$Target,                    # Path to the folder or special target
        [string[]]$FileTypes = @("*.*"),   # File types to clean, default is all
        [string]$Description = "files",    # Description for user prompts
        [switch]$IsRecycleBin = $false,    # Special handling for Recycle Bin
        [switch]$IsWindowsUpdate = $false # Special handling for Windows Update folder
    )

    # Define target path for special cases
    if ($IsRecycleBin) {
        $Target = "C:\`$Recycle.Bin"
    }

    # Check if target exists
    if (Test-Path $Target) {
        # Calculate size
        $size = if ($IsRecycleBin -or $IsWindowsUpdate) {
            (Get-ChildItem -Path $Target -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        } else {
            (Get-ChildItem -Path $Target -Recurse -Include $FileTypes -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        }

        # Display size and prompt user
        if ($size -gt 0.1) {
            $prompt = [System.Windows.Forms.MessageBox]::Show(
                "The $Description in $Target contains {0:N2} GB. Do you want to clean it?" -f $size,
                "Confirm Cleaning",
                [System.Windows.Forms.MessageBoxButtons]::YesNo
            )

            if ($prompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                if ($IsRecycleBin) {
                    # Special handling for Recycle Bin
                    Write-Host "Starting cleanup of Recycle Bin..."
                    $binFolders = Get-ChildItem -Path $Target -Directory -Force
                    foreach ($folder in $binFolders) {
                        try {
                            $sid = New-Object System.Security.Principal.SecurityIdentifier($folder.Name)
                            $user = $sid.Translate([System.Security.Principal.NTAccount])
                            Write-Host "Cleaning $user's Recycle Bin..."
                            $ResultText.text = "Cleaning $user's Recycle Bin..."
                        } catch {
                            $user = $folder.Name
                            Write-Host "Cleaning Recycle Bin for SID: $user..."
                            $ResultText.text = "Cleaning Recycle Bin for SID: $user..."
                        }

                        # Delete files with progress
                        $files = Get-ChildItem -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        $totalFiles = $files.Count
                        for ($i = 0; $i -lt $totalFiles; $i++) {
                            $file = $files[$i]
                            Write-Progress -Activity "Recycle Bin Cleanup" -Status "Deleting file [$($i + 1)/$totalFiles]: $($file.Name)" -PercentComplete ((($i + 1) / $totalFiles) * 100)
                            Remove-Item -Path $file.FullName -Recurse -Force
                        }
                    }

                } elseif ($IsWindowsUpdate) {
                    # Special handling for Windows Update folder
                    Write-Host "Cleaning Windows Update folder..."
                    $ResultText.text = "Cleaning Windows Update folder..."
                    try {
                        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
                        Remove-Item -Path "$Target\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
                    } catch {
                        Write-Warning "Failed to clean Windows Update folder: $_"
                        $ResultText.text = "Failed to clean Windows Update folder."
                    }

                } else {
                    # General folder/file cleaning
                    Write-Host "Cleaning $Description in $Target..."
                    $ResultText.text = "Cleaning $Description in $Target..."
                    Get-ChildItem -Path $Target -Recurse -Include $FileTypes -ErrorAction SilentlyContinue | ForEach-Object {
                        Remove-Item -Path $_.FullName -Recurse -Force -Verbose
                    }
                }

                Write-Progress -Activity "Cleaning $Description" -Status "Complete" -Completed
                $ResultText.text = "Cleaned $Description in $Target. Freed {0:N2} GB." -f $size
                Write-Host "Cleaned $Target. Freed {0:N2} GB." -f $size
            } else {
                Write-Host "User canceled cleaning of $Target."
                $ResultText.text = "Cleaning of $Description in $Target was canceled."
            }
        } else {
            Write-Host "The $Description in $Target is negligible ({0:N2} GB). Skipping cleanup." -f $size
            $ResultText.text = "The $Description in $Target is negligible ({0:N2} GB). Skipping cleanup." -f $size
        }
    } else {
        Write-Host "Target $Target does not exist. Skipping..."
        $ResultText.text = "Target $Target does not exist. Skipping..."
    }
}


Function MakeForm {
     $frontcolor = [System.Drawing.ColorTranslator]::FromHtml("#182C36")
     $backcolor  = [System.Drawing.ColorTranslator]::FromHtml("#5095B5")
     $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#346075")

     #Form Design
     $Form = New-Object system.Windows.Forms.Form
     $Form.text = "WinTool by Alerion"
     $Form.StartPosition = "CenterScreen"
     $Form.TopMost = $false
     $Form.BackColor = $backcolor
     $Form.ForeColor = $frontcolor
     $Form.AutoScaleDimensions = '192, 192'
     $Form.AutoScaleMode = "Dpi"
     $Form.AutoSize = $True
     $Form.AutoScroll = $True
     $Form.FormBorderStyle = 0
     
    # Add Form-Level Buttons
    $xButton = New-Object system.Windows.Forms.Button
    $xButton.Text = "X"
    $xButton.Width = 25
    $xButton.Height = 25
    $xButton.Location = New-Object System.Drawing.Point(1125, 10)
    $xButton.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $xButton.BackColor = $frontcolor
    $xButton.ForeColor = $backcolor
    $xButton.FlatStyle = "Flat"
    $xButton.FlatAppearance.MouseOverBackColor = $hovercolor

    # GUI Icon
    $iconBase64 = [Convert]::ToBase64String((Get-Content "C:\Windows\heart.ico" -Encoding Byte))
    $iconBytes = [Convert]::FromBase64String($iconBase64)
    $stream = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
    $stream.Write($iconBytes, 0, $iconBytes.Length)
    $Form.Icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())
    $Form.Width = $objImage.Width
    $Form.Height = $objImage.Height
    $Form.MinimizeBox = $false;
    $Form.MaximizeBox = $false;

    $supportWintool = New-Object system.Windows.Forms.Button
    $supportWintool.text = "Support WinTool!"
    $supportWintool.width = 200
    $supportWintool.height = 25
    $supportWintool.location = New-Object System.Drawing.Point(925, 10)
    $supportWintool.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $supportWintool.BackColor = $frontcolor 
    $supportWintool.ForeColor = $backcolor
    $supportWintool.FlatStyle = "Flat"
    $supportWintool.BorderStyle = 0
    $supportWintool.FlatAppearance.MouseOverBackColor = $hovercolor
    $supportWintool.TabStop = $false

    $createShortcutGit = New-Object system.Windows.Forms.Button
    $createShortcutGit.text = "Create Github Shortcut"
    $createShortcutGit.width = 200
    $createShortcutGit.height = 25
    $createShortcutGit.location = New-Object System.Drawing.Point(725, 10)
    $createShortcutGit.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $createShortcutGit.BackColor = $frontcolor 
    $createShortcutGit.ForeColor = $backcolor
    $createShortcutGit.FlatStyle = "Flat"
    $createShortcutGit.BorderStyle = 0
    $createShortcutGit.FlatAppearance.MouseOverBackColor = $hovercolor
    $createShortcutGit.TabStop = $false

    $CreateShortcutTool = New-Object system.Windows.Forms.Button
    $CreateShortcutTool.text = "Create Desktop Shortcut"
    $CreateShortcutTool.width = 200
    $CreateShortcutTool.height = 25
    $CreateShortcutTool.location = New-Object System.Drawing.Point(525, 10)
    $CreateShortcutTool.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $CreateShortcutTool.BackColor = $frontcolor 
    $CreateShortcutTool.ForeColor = $backcolor
    $CreateShortcutTool.FlatStyle = "Flat"
    $CreateShortcutTool.BorderStyle = 0
    $CreateShortcutTool.FlatAppearance.MouseOverBackColor = $hovercolor
    $CreateShortcutTool.TabStop = $false

    $wintoollogo = New-Object System.Windows.Forms.Label
    $wintoollogo.text = "WinTool by Alerion"
    $wintoollogo.width = 600
    $wintoollogo.height = 75
    $wintoollogo.location = New-Object System.Drawing.Point(20, 20)
    $wintoollogo.Font = New-Object System.Drawing.Font('Impact', 40)
    $wintoollogo.ForeColor = $frontcolor 

    # Panels Definition
    # Uniform Height and Width for Panels
    $defaultPanelWidth = 220
    $defaultPanelHeight = 435
    $Panel1 = Add-Panel -Width $defaultPanelWidth -Height $defaultPanelHeight -Location (New-Object System.Drawing.Point(10, 100))
    $Panel2 = Add-Panel -Width $defaultPanelWidth -Height $defaultPanelHeight -Location (New-Object System.Drawing.Point(240, 100))
    $Panel3 = Add-Panel -Width $defaultPanelWidth -Height $defaultPanelHeight -Location (New-Object System.Drawing.Point(470, 100))
    $Panel4 = Add-Panel -Width $defaultPanelWidth -Height $defaultPanelHeight -Location (New-Object System.Drawing.Point(700, 100))
    $Panel5 = Add-Panel -Width $defaultPanelWidth -Height $defaultPanelHeight -Location (New-Object System.Drawing.Point(930, 100))
    $Panel6 = Add-Panel -Width 1145 -Height 200 -Location (New-Object System.Drawing.Point(10, 535))

    # Add Panels to Form
    $Form.Controls.AddRange(@($xButton, $createShortcutGit, $CreateShortcutTool, $wintoollogo, $supportWintool, $Panel1, $Panel2, $Panel3, $Panel4, $Panel5, $Panel6))

    # Main Panel that creates a perfect border hack of 2px
    $ResultTextWrapper = New-Object system.Windows.Forms.TextBox
    $ResultTextWrapper.Multiline = $true
    $ResultTextWrapper.ReadOnly = $true
    $ResultTextWrapper.Width = 1140
    $ResultTextWrapper.Height = 195
    $ResultTextWrapper.BackColor = $frontcolor
    $ResultTextWrapper.ForeColor = $backcolor
    $ResultTextWrapper.BorderStyle = 0
    $Panel6.Controls.Add($ResultTextWrapper)

    # This acts as a wrapper so we can set a padding without messing up the border in the next box
    $ResultTextFinal = New-Object system.Windows.Forms.TextBox
    $ResultTextFinal.Multiline = $true
    $ResultTextFinal.ReadOnly = $true
    $ResultTextFinal.AutoSize = $true
    $ResultTextFinal.Width = 1136 # Adjust for border size 4px diffrence idk why
    $ResultTextFinal.Height = 191 # Adjust for border size 4px diffrence idk why
    $ResultTextFinal.Location = New-Object System.Drawing.Point(2, 2) # border size
    $ResultTextFinal.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $ResultTextFinal.BorderStyle = 0
    $ResultTextFinal.BackColor = $backcolor
    $ResultTextFinal.ForeColor = $frontcolor
    $ResultTextWrapper.Controls.Add($ResultTextFinal)

    # This is where the actual text output is produced!
    $ResultText = New-Object system.Windows.Forms.TextBox
    $ResultText.Multiline = $true
    $ResultText.ReadOnly = $true
    $ResultText.AutoSize = $true
    $ResultText.Width = 1136 # Adjust for padding
    $ResultText.Height = 191 # Adjust for padding
    $ResultText.Location = New-Object System.Drawing.Point(10, 10) # Adjust padding here
    $ResultText.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $ResultText.BorderStyle = 0
    $ResultText.BackColor = $backcolor
    $ResultText.ForeColor = $frontcolor
    $ResultTextFinal.Controls.Add($ResultText)

    # Default start positions, they have to be reset for each new panel or it will be buggy..
    $YPosition = 0
    $XPosition = 0

    #spacings
    $largespacing = 70
    $normalspacing = 35
    $labelspacing = 40
    $labelspacing2 = 35

    #buttons
    $largebuttonsize = 65
    #$defaultbuttonsize = 30

    #labels 
    $labelfontsize = 10
    $labelheight = 35
    $firstlabelstartpos = 5

    #checkboxes
    #$checkboxspacing = 25
    #$checkboxheight = 26
    #$checkboxfontsize = 10

    #####################
    ## Panel 1 begins! ##
    #####################

    $performancetweaks = Add-Control -Text "Performance Tweaks" -X $XPosition -Y $firstlabelstartpos -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing

    $essentialtweaks = Add-Control -Text "Essential Tweaks" -X $XPosition -Y $YPosition -Height $largebuttonsize
    $YPosition += $largespacing

    $essentialundo = Add-Control -Text "Undo Essential Tweaks" -X $XPosition -Y $YPosition -Height $largebuttonsize
    $YPosition += $largespacing

    $gamingtweaks = Add-Control -Text "Gaming Tweaks" -X $XPosition -Y $YPosition -Height $largebuttonsize
    $YPosition += $largespacing

    $securitypatches = Add-Control -Text "Patch Security (Caution!)" -X $XPosition -Y $YPosition -Height $largebuttonsize
    $YPosition += $largespacing

    if ((Test-Path "$env:programdata\Microsoft OneDrive") -or (Test-Path "C:\Program Files (x86)\Microsoft OneDrive") -or (Test-Path "C:\Program Files\Microsoft OneDrive")) {
        $onedrive = Add-Control -Text "Remove OneDrive" -X $XPosition -Y $YPosition
    } else {
        $onedrive = Add-Control -Text "Restore OneDrive" -X $XPosition -Y $YPosition
    }
    $YPosition += $normalspacing

    if (Test-Path "$env:programdata\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk") {
        $killedge = Add-Control -Text "Remove Microsoft Edge" -X $XPosition -Y $YPosition
    } else {
        $killedge = Add-Control -Text "Restore Microsoft Edge" -X $XPosition -Y $YPosition
    }
    $YPosition += $normalspacing

    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}") {
        $removehomegallery = Add-Control -Text "Remove Home and Gallery" -X $XPosition -Y $YPosition
    } else {
        $removehomegallery = Add-Control -Text "Restore Home and Gallery" -X $XPosition -Y $YPosition
    }

    #####################
    ## Panel 2 begins! ##
    #####################

    #Reset position for next Panel
    $YPosition = 0
    $XPosition = 0

    $fixes = Add-Control -Text "Fixes" -X $XPosition -Y $firstlabelstartpos -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing

    $errorscanner = Add-Control -Text "Error Scanner" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $changedns = Add-Control -Text "" -X $XPosition -Y $YPosition -ControlType "ComboBox"
    @(
        '          Change DNS Here', 
        '               Google DNS', 
        '            Cloudflare DNS', 
        '               Level3 DNS', 
        '                 OpenDNS', 
        '         Restore Default DNS'
    ) | ForEach-Object { [void] $changedns.Items.Add($_) }
    $changedns.SelectedIndex = 0
    $YPosition += $normalspacing

    $resetnetwork = Add-Control -Text "Reset Network" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $forcenorkeyboard = Add-Control -Text "Force NO/NB Language" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $dualboottime = Add-Control -Text "Set Time to UTC" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $oldmenu = Add-Control -Text "Old Menus" -X $XPosition -Y $YPosition -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing2

    $ncpa = Add-Control -Text "Network Panel" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $oldcontrolpanel = Add-Control -Text "Control Panel" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $oldsoundpanel = Add-Control -Text "Sound Panel" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $oldsystempanel = Add-Control -Text "System Panel" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $oldpower = Add-Control -Text "Power Panel" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing
 
    #####################
    ## Panel 3 begins! ##
    #####################

    # Reset position for Panel 3
    $YPosition = 0
    $XPosition = 0

    # Add controls with consistent spacing
    $windowsupdate = Add-Control -Text "Windows Update" -X $XPosition -Y $firstlabelstartpos -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing

    $defaultwindowsupdate = Add-Control -Text "Default Settings" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $securitywindowsupdate = Add-Control -Text "Security Updates Only" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $windowsupdatefix = Add-Control -Text "Windows Update Reset" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $microsoftstore = Add-Control -Text "Microsoft Store" -X $XPosition -Y $YPosition -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing2

    $removebloat = Add-Control -Text "Remove MS Store Apps" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $reinstallbloat = Add-Control -Text "Reinstall MS Store Apps" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $cleaning = Add-Control -Text "Cleaning" -X $XPosition -Y $YPosition -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing2

    $ultimateclean = Add-Control -Text "Ultimate Cleaning" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $visualtweaks = Add-Control -Text "Visual Tweaks" -X $XPosition -Y $YPosition -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing2

    $darkmode = Add-Control -Text "Dark Mode" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $lightmode = Add-Control -Text "Light Mode" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    #####################
    ## Panel 4 begins! ##
    #####################

    # Reset position for Panel 4
    $YPosition = 0
    $XPosition = 0

    # Add Label Header
    $placedholderlabel = Add-Control -Text "Placeholder Label" -X $XPosition -Y $firstlabelstartpos -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing

    # Add CheckBoxes for Apps
    $placeholderbutton1 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $placeholderbutton2 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $placeholderbutton3 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $placeholderbutton4 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition 
    $YPosition += $normalspacing

    $placeholderbutton5 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition 
    $YPosition += $normalspacing

    $placeholderbutton6 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition 
    $YPosition += $normalspacing

    $placeholderbutton7 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition 
    $YPosition += $normalspacing

    $hibernationmenu = Add-Control -Text "Hibernation Tweaks" -X $XPosition -Y $YPosition -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing2

    $remhibernation = Add-Control -Text "Disable (No Fast Boot)" -X $XPosition -Y $YPosition 
    $YPosition += $normalspacing

    $remhibernationbutfastboot = Add-Control -Text "Reduce (Fast Boot Intact)" -X $XPosition -Y $YPosition 
    $YPosition += $normalspacing

    $restorehibernation = Add-Control -Text "Restore (Default Config)" -X $XPosition -Y $YPosition 
    $YPosition += $normalspacing

    #####################
    ## Panel 5 begins! ##
    #####################

    # Reset position for Panel 5
    $YPosition = 0
    $XPosition = 0

    # Add controls with consistent spacing
    $Mischeader = Add-Control -Text "System Information" -X $XPosition -Y $firstlabelstartpos -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing

    $ClearRAMcache = Add-Control -Text "RAM Cache Shortcut" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $godmode = Add-Control -Text "Godmode Shortcut" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $HardwareInfo = Add-Control -Text "Hardware Info" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $antivirusInfo = Add-Control -Text "Anti-Virus Status" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $SystemInfo = Add-Control -Text "System Info" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $placeholder7 = Add-Control -Text "Additional Tools" -X $XPosition -Y $YPosition -Height $labelheight -FontSize $labelfontsize -ControlType "Label"
    $YPosition += $labelspacing2

    $placeholder8 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $placeholder9 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $placeholder10 = Add-Control -Text "Placeholder" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $selectAppsButton = Add-Control -Text "Application Installer" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $btnOpenCustomization = Add-Control -Text "Customize About-PC" -X $XPosition -Y $YPosition
    $YPosition += $normalspacing

    $Panel1.controls.AddRange(@(
            $performancetweaks, #header for the section below
            $essentialtweaks,
            $essentialundo,
            $gamingtweaks,
            $securitypatches, 
            $onedrive,
            $removehomegallery,
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
            $forcenorkeyboard,
            $dualboottime
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
            $visualtweaks,
            $darkmode,
            $lightmode
        ))

    $Panel4.controls.AddRange(@(
            $placedholderlabel,
            $placeholderbutton1,
            $placeholderbutton2,
            $placeholderbutton3,
            $placeholderbutton4,
            $placeholderbutton5,
            $placeholderbutton6,
            $placeholderbutton7,
            $hibernationmenu,
            $remhibernation,
            $remhibernationbutfastboot,
            $restorehibernation
        ))

    $Panel5.controls.AddRange(@(
            $Mischeader,
            $ClearRAMcache,
            $SystemInfo,
            $HardwareInfo,
            $antivirusInfo,
            $godmode,
            $placeholder7,
            $placeholder8,
            $placeholder9,
            $placeholder10,
            $selectAppsButton,
            $btnOpenCustomization
        ))

    # Check if Winget is installed
if (Get-Command "winget" -ErrorAction SilentlyContinue) {
    $ResultText.text = @"
Welcome to WinTool by Alerion! This is a powerful tool, so be sure to read the instructions on GitHub before diving in.  
Here's what you need to ensure everything runs smoothly:
  
  --> Winget App Automation - Already installed and ready to go!  
  --> Administrator Elevation - This script handles it automatically, but the first time an elevated prompt is required.  
  --> Windows 10 or Windows 11 - Fully supported on all builds!

Enjoy this free tool and make the most of it!
"@
} else {
    $ResultText.text = @"
Welcome to WinTool by Alerion! This is a powerful tool, so be sure to read the instructions on GitHub before diving in.  
Here's what you need to ensure everything runs smoothly:
  
  --> Winget App Automation - Will be installed automatically when you choose an app!  
  --> Administrator Elevation - This script handles it automatically, but the first time an elevated prompt is required.  
  --> Windows 10 or Windows 11 - Fully supported on all builds!

Enjoy this free tool and make the most of it!
"@
}

    $selectAppsButton.Add_Click({
        ShowAppSelectionForm
    })

    function Set-DesktopBackgroundColor {
        param (
            [int]$Red,
            [int]$Green,
            [int]$Blue
        )
    
        # Validate RGB values
        if ($Red -lt 0 -or $Red -gt 255 -or $Green -lt 0 -or $Green -gt 255 -or $Blue -lt 0 -or $Blue -gt 255) {
            Write-Error "RGB values must be between 0 and 255."
            return
        }
    
        # Convert RGB to string format required by the registry
        $rgbString = "$Red $Green $Blue"
    
        # Set the desktop background color in the registry
        Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value $rgbString
    
        # Remove any existing wallpaper to apply the solid color
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value ""
    
        # Refresh the desktop to apply changes
        RUNDLL32.EXE user32.dll, UpdatePerUserSystemParameters
    }

# Event handler for opening the customization form
$btnOpenCustomization.Add_Click({
    # Secondary Customization Form
    $customForm = New-Object System.Windows.Forms.Form
    $customForm.Text = "Customize About This Computer"
    $customForm.Size = New-Object System.Drawing.Size(550, 450)
    $customForm.StartPosition = "CenterScreen"

    # Label and Textbox for Manufacturer
    $labelManufacturer = New-Object System.Windows.Forms.Label
    $labelManufacturer.Text = "Manufacturer:"
    $labelManufacturer.Location = New-Object System.Drawing.Point(10, 20)
    $labelManufacturer.Size = New-Object System.Drawing.Size(100, 20)

    $textManufacturer = New-Object System.Windows.Forms.TextBox
    $textManufacturer.Location = New-Object System.Drawing.Point(120, 20)
    $textManufacturer.Size = New-Object System.Drawing.Size(350, 20)

    # Label and Textbox for Support URL
    $labelSupportURL = New-Object System.Windows.Forms.Label
    $labelSupportURL.Text = "Support URL:"
    $labelSupportURL.Location = New-Object System.Drawing.Point(10, 60)
    $labelSupportURL.Size = New-Object System.Drawing.Size(100, 20)

    $textSupportURL = New-Object System.Windows.Forms.TextBox
    $textSupportURL.Location = New-Object System.Drawing.Point(120, 60)
    $textSupportURL.Size = New-Object System.Drawing.Size(350, 20)

    # Radio Buttons for Background Options
    $radioBackgroundImage = New-Object System.Windows.Forms.RadioButton
    $radioBackgroundImage.Text = "Set Background Image"
    $radioBackgroundImage.Location = New-Object System.Drawing.Point(10, 100)
    $radioBackgroundImage.Size = New-Object System.Drawing.Size(200, 20)

    $radioBackgroundColor = New-Object System.Windows.Forms.RadioButton
    $radioBackgroundColor.Text = "Set Desktop Color"
    $radioBackgroundColor.Location = New-Object System.Drawing.Point(10, 130)
    $radioBackgroundColor.Size = New-Object System.Drawing.Size(200, 20)

    # Textbox and Browse Button for Background Image
    $textBackgroundPath = New-Object System.Windows.Forms.TextBox
    $textBackgroundPath.Location = New-Object System.Drawing.Point(120, 160)
    $textBackgroundPath.Size = New-Object System.Drawing.Size(250, 20)
    $textBackgroundPath.Enabled = $false

    $btnBrowseImage = New-Object System.Windows.Forms.Button
    $btnBrowseImage.Text = "Browse"
    $btnBrowseImage.Location = New-Object System.Drawing.Point(380, 160)
    $btnBrowseImage.Size = New-Object System.Drawing.Size(90, 25)
    $btnBrowseImage.Enabled = $false

    # Label and Color Picker for Desktop Color
    $labelDesktopColor = New-Object System.Windows.Forms.Label
    $labelDesktopColor.Text = "Choose Color:"
    $labelDesktopColor.Location = New-Object System.Drawing.Point(10, 200)
    $labelDesktopColor.Size = New-Object System.Drawing.Size(100, 20)

    $colorPicker = New-Object System.Windows.Forms.ComboBox
    $colorPicker.Location = New-Object System.Drawing.Point(120, 200)
    $colorPicker.Size = New-Object System.Drawing.Size(350, 20)
    $colorPicker.Items.AddRange(@("Red", "Green", "Blue", "Black", "White", "Gray", "Yellow"))
    $colorPicker.Enabled = $false

    # Apply and Close Buttons
    $btnApply = New-Object System.Windows.Forms.Button
    $btnApply.Text = "Apply"
    $btnApply.Location = New-Object System.Drawing.Point(120, 250)
    $btnApply.Size = New-Object System.Drawing.Size(100, 30)

    $btnCloseCustom = New-Object System.Windows.Forms.Button
    $btnCloseCustom.Text = "Close"
    $btnCloseCustom.Location = New-Object System.Drawing.Point(230, 250)
    $btnCloseCustom.Size = New-Object System.Drawing.Size(100, 30)

    # Add controls to the form
    $customForm.Controls.Add($labelManufacturer)
    $customForm.Controls.Add($textManufacturer)
    $customForm.Controls.Add($labelSupportURL)
    $customForm.Controls.Add($textSupportURL)
    $customForm.Controls.Add($radioBackgroundImage)
    $customForm.Controls.Add($radioBackgroundColor)
    $customForm.Controls.Add($textBackgroundPath)
    $customForm.Controls.Add($btnBrowseImage)
    $customForm.Controls.Add($labelDesktopColor)
    $customForm.Controls.Add($colorPicker)
    $customForm.Controls.Add($btnApply)
    $customForm.Controls.Add($btnCloseCustom)

    # Dynamically manage visibility and enable inputs based on radio button selection
    $radioBackgroundImage.Add_CheckedChanged({
        $textBackgroundPath.Enabled = $radioBackgroundImage.Checked
        $btnBrowseImage.Enabled = $radioBackgroundImage.Checked
        $colorPicker.Enabled = -not $radioBackgroundImage.Checked
    })

    $radioBackgroundColor.Add_CheckedChanged({
        $colorPicker.Enabled = $radioBackgroundColor.Checked
        $textBackgroundPath.Enabled = -not $radioBackgroundColor.Checked
        $btnBrowseImage.Enabled = -not $radioBackgroundColor.Checked
    })

    # Event handler for browsing background image
    $btnBrowseImage.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "Image Files (*.bmp, *.jpg, *.jpeg, *.png)|*.bmp;*.jpg;*.jpeg;*.png"
        If ($fileDialog.ShowDialog() -eq "OK") {
            $textBackgroundPath.Text = $fileDialog.FileName
        }
    })

    # Event handler for Apply button
    $btnApply.Add_Click({
        # Get the values from the textboxes
        $manufacturer = $textManufacturer.Text
        $supportURL = $textSupportURL.Text
        $backgroundPath = $textBackgroundPath.Text
        $desktopColor = $colorPicker.SelectedItem

        # Validate and Apply Manufacturer and Support URL
        If (-not [string]::IsNullOrWhiteSpace($manufacturer)) {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "Manufacturer" -Type String -Value $manufacturer
        }
        If (-not [string]::IsNullOrWhiteSpace($supportURL)) {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "SupportURL" -Type String -Value $supportURL
        }

         # Apply Desktop Settings
    If ($radioBackgroundImage.Checked -and (Test-Path $backgroundPath)) {
        # Set Background Image
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
        [Wallpaper]::SystemParametersInfo(0x0014, 0, $backgroundPath, 0x0001 -bor 0x0002)
    } elseif ($radioBackgroundColor.Checked -and $desktopColor) {
        # Clear existing background image
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
        [Wallpaper]::SystemParametersInfo(0x0014, 0, "", 0x0001 -bor 0x0002)

        # Set Desktop Color using the function
        $colorMap = @{
            "Red"   = [int[]](255, 0, 0)
            "Green" = [int[]](0, 255, 0)
            "Blue"  = [int[]](0, 0, 255)
            "Black" = [int[]](0, 0, 0)
            "White" = [int[]](255, 255, 255)
            "Gray"  = [int[]](128, 128, 128)
            "Yellow"= [int[]](255, 255, 0)
        }

        if ($colorMap.ContainsKey($desktopColor)) {
            $selectedColor = $colorMap[$desktopColor]
            SetDesktopBackgroundColor $selectedColor
        } else {
            [System.Windows.Forms.MessageBox]::Show("Invalid color selection.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
        # Show confirmation
        [System.Windows.Forms.MessageBox]::Show("Settings updated successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    })

    # Event handler for Close button
    $btnCloseCustom.Add_Click({
        $customForm.Close()
    })

    # Show the Customization Form as a modal dialog
    $customForm.ShowDialog()
})


# Event handler for DNS selection
$changedns.add_SelectedIndexChanged({
    $selected = $changedns.SelectedIndex

    # Function to set DNS
    function Set-DNS {
        param (
            [string[]]$dnsAddresses
        )
        $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
        $Interfaces.SetDNSServerSearchOrder($dnsAddresses) | Out-Null
    }

    switch ($selected) {
        1 {
            $ResultText.text = "DNS set to Google on all network adapters. `r`n Ready for Next Task!"
            Set-DNS -dnsAddresses @("8.8.8.8", "8.8.4.4")
        }
        2 {
            $ResultText.text = "DNS set to Cloudflare on all network adapters. `r`n Ready for Next Task!"
            Set-DNS -dnsAddresses @("1.1.1.1", "1.0.0.1")
        }
        3 {
            $ResultText.text = "DNS set to Level3 on all network adapters. `r`n Ready for Next Task!"
            Set-DNS -dnsAddresses @("4.2.2.2", "4.2.2.1")
        }
        4 {
            $ResultText.text = "DNS set to OpenDNS on all network adapters. `r`n Ready for Next Task!"
            Set-DNS -dnsAddresses @("208.67.222.222", "208.67.220.220")
        }
        5 {
            $ResultText.text = "Resetting DNS to Windows Default. This will break any VPNs too."
            $confirmReset = [System.Windows.Forms.MessageBox]::Show('Are you sure?', 'Reset DNS to Windows Default?', [System.Windows.Forms.MessageBoxButtons]::YesNo)
            if ($confirmReset -eq [System.Windows.Forms.DialogResult]::Yes) {
                $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
                foreach ($interface in $Interfaces) {
                    $interface.SetDNSServerSearchOrder($null) | Out-Null
                }
                $ResultText.text = "DNS settings reset to Windows Default. `r`n Ready for Next Task!"
            }
        }
        6 {
            # Custom DNS Entry
            $customDnsForm = New-Object System.Windows.Forms.Form
            $customDnsForm.Text = "Custom DNS Input"
            $customDnsForm.Size = New-Object System.Drawing.Size(300, 200)
            $customDnsForm.StartPosition = "CenterScreen"

            # Label for DNS Input
            $labelDns = New-Object System.Windows.Forms.Label
            $labelDns.Text = "Enter custom DNS (comma separated):"
            $labelDns.Size = New-Object System.Drawing.Size(260, 20)
            $labelDns.Location = New-Object System.Drawing.Point(10, 10)
            $customDnsForm.Controls.Add($labelDns)

            # Textbox for DNS Input
            $textCustomDns = New-Object System.Windows.Forms.TextBox
            $textCustomDns.Size = New-Object System.Drawing.Size(260, 20)
            $textCustomDns.Location = New-Object System.Drawing.Point(10, 40)
            $customDnsForm.Controls.Add($textCustomDns)

            # Apply Button
            $btnApplyCustomDns = New-Object System.Windows.Forms.Button
            $btnApplyCustomDns.Text = "Apply"
            $btnApplyCustomDns.Size = New-Object System.Drawing.Size(100, 30)
            $btnApplyCustomDns.Location = New-Object System.Drawing.Point(50, 80)
            $btnApplyCustomDns.Add_Click({
                $customDns = $textCustomDns.Text.Split(",") | ForEach-Object { $_.Trim() }
                if ($customDns -and $customDns.Count -ge 1) {
                    Set-DNS -dnsAddresses $customDns
                    $ResultText.text = "Custom DNS set: $($customDns -join ", "). `r`n Ready for Next Task!"
                    $customDnsForm.Close()
                } else {
                    [System.Windows.Forms.MessageBox]::Show("Invalid DNS input. Please enter valid IP addresses.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            })
            $customDnsForm.Controls.Add($btnApplyCustomDns)

            # Cancel Button
            $btnCancelCustomDns = New-Object System.Windows.Forms.Button
            $btnCancelCustomDns.Text = "Cancel"
            $btnCancelCustomDns.Size = New-Object System.Drawing.Size(100, 30)
            $btnCancelCustomDns.Location = New-Object System.Drawing.Point(160, 80)
            $btnCancelCustomDns.Add_Click({
                $customDnsForm.Close()
            })
            $customDnsForm.Controls.Add($btnCancelCustomDns)

            $customDnsForm.ShowDialog()
        }
        default {
            $ResultText.text = "Please select an option to change the DNS settings."
        }
    }
})
    
# Function to start a system scan
function Start-SystemScan {
    param (
        [string]$scanType,
        [scriptblock]$scanCommand,
        [string]$logFile
    )

    $ResultText.text = "$scanType has started. Please wait..."

    try {
        # Execute the scan command and redirect output to log file
        & $scanCommand *>&1 | Tee-Object -FilePath $logFile
        $ResultText.text = "$scanType completed successfully. Please review the log at $logFile."
    } catch {
        $ResultText.text = "Error during $scanType : $_"
    }
}

$errorscanner.Add_Click({
    $ResultText.text = "System error scan has started. Please wait..."

    # Define log file paths
    $logDirectory = "$env:SystemDrive\Logs"
    $sfcLog = Join-Path -Path $logDirectory -ChildPath "SFC_Log.txt"
    $dismLog = Join-Path -Path $logDirectory -ChildPath "DISM_Log.txt"

    # Create Logs directory if it doesn't exist
    if (-not (Test-Path $logDirectory)) {
        New-Item -Path $logDirectory -ItemType Directory | Out-Null
    }

    # DISM Scan
    $dismConfirmation = [System.Windows.Forms.MessageBox]::Show('This may take a while. Do you want to proceed?', 'Initiate DISM Scan?', [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($dismConfirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-SystemScan -scanType 'DISM Restore Health' -scanCommand { Repair-WindowsImage -Online -RestoreHealth } -logFile $dismLog
    }

    # SFC Scan
    $sfcConfirmation = [System.Windows.Forms.MessageBox]::Show('This may take a while. Do you want to proceed?', 'Run SFC Scan now?', [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($sfcConfirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-SystemScan -scanType 'SFC Scannow' -scanCommand { sfc /scannow } -logFile $sfcLog
    }

    $ResultText.text = "System error scans have been completed. Please review the logs and restart your computer if necessary."
})
        


$ultimateclean.Add_Click({

    # Initial Setup
    $ResultText.text = "Cleaning initiated, empty folders will be skipped automatically..."
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $Form.text = "WinTool by Alerion - Initializing Ultimate Cleaning..."

    # Restart Explorer to free access for files cached into memory
    $ResultText.text = "Restarting Explorer to apply changes..."
    Stop-Process -ProcessName explorer -Force -ErrorAction SilentlyContinue
    taskkill /F /IM explorer.exe

    # Step 1: Create Restore Point
    $ResultText.text = "Creating a restore point named: WinTool-Ultimate-Cleaning-Restorepoint, in case something bad happens..."
    try {
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "WinTool-Ultimate-Cleaning-Restorepoint" -RestorePointType "MODIFY_SETTINGS"
        $ResultText.text = "Restore point created successfully."
    } catch {
        $ResultText.text = "Failed to create a restore point. Proceeding with cleaning."
    }

    # Step 2: Clean Shadow Copies and Component Store
    $componentCachePrompt = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to clean Shadow Copies and Windows Store Component Cache?",
        "Confirmation",
        [System.Windows.Forms.MessageBoxButtons]::YesNo
    )
    if ($componentCachePrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
        $ResultText.text = "Cleaning Windows Store Component Cache. Please be patient..."
        try {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c vssadmin delete shadows /all /quiet" -Wait -NoNewWindow
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c DISM /Online /Cleanup-Image /AnalyzeComponentStore" -Wait -NoNewWindow
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c DISM /Online /Cleanup-Image /spsuperseded" -Wait -NoNewWindow
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c DISM /Online /Cleanup-Image /StartComponentCleanup" -Wait -NoNewWindow
            $ResultText.text = "Shadow copies and Windows Store Component Cache cleaned successfully."

            # Clean unnecessary Windows Store caches
            $ResultText.text = "Cleaning unnecessary Windows Store caches..."
            $volumeCaches = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" |
                            Where-Object { $_.Name -ne "DownloadsFolder" }
            foreach ($cache in $volumeCaches) {
                $registryKey = 'HKLM:' + $cache.Name.Substring(18)
                New-ItemProperty -Path $registryKey -Name 'StateFlags0001' -Value 2 -PropertyType DWORD -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Clear-BCCache -Force -ErrorAction SilentlyContinue
            $ResultText.text = "Windows Store caches cleaned."
        } catch {
            $ResultText.text = "Error while cleaning Shadow Copies or Component Store: $_"
        }
    }

    # Step 3: Clean Registry Junk
    $regCachePrompt = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to clean up a collection of useless registry files?",
        "Confirmation",
        [System.Windows.Forms.MessageBoxButtons]::YesNo
    )
    if ($regCachePrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
        $ResultText.text = "Cleaning registry junk files. Please wait..."
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles\*",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Managed\*",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\Unmanaged\*",
            "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*",
            "HKLM:\SYSTEM\CurrentControlSet\Control\usbflags\*",
            "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Nla\Cache\Intranet\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\*",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache\*",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\*"
        )
        foreach ($path in $registryPaths) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        }
        $ResultText.text = "Registry junk files cleaned."
    }

    # Clean up local explorer-related files
    $ResultText.text = "Cleaning local explorer-related files..."
    Initialize-Cleaning -Target "$env:LocalAppData\Microsoft\Windows\Explorer" -Description "Explorer files"
    Initialize-Cleaning -Target "$env:LocalAppData\Microsoft\Windows\Recent" -Description "Recent files"
    Initialize-Cleaning -Target "$env:LocalAppData\Microsoft\Windows\Recent\AutomaticDestinations" -Description "Recent Automatic Destinations"
    Initialize-Cleaning -Target "$env:LocalAppData\Microsoft\Windows\Recent\CustomDestinations" -Description "Recent Custom Destinations"

    # Fetch user profiles
    $Users = Get-ChildItem "$env:systemdrive\Users" | Select-Object -ExpandProperty Name
    $ResultText.text = "User profiles fetched: $($Users -join ', ')"

    # Clear Inetpub Logs Folder
    if (Test-Path "C:\inetpub\logs\LogFiles\") {
        Initialize-Cleaning -Target "C:\inetpub\logs\LogFiles" -Description "Inetpub Logs Folder"
    }

    # Clear Microsoft Teams Previous Versions
    if (Test-Path "$env:LocalAppData\Microsoft\Teams\") {
        foreach ($user in $Users) {
            Initialize-Cleaning -Target "C:\Users\$user\AppData\Local\Microsoft\Teams\previous" -Description "Microsoft Teams previous versions"
            Initialize-Cleaning -Target "C:\Users\$user\AppData\Local\Microsoft\Teams\stage" -Description "Microsoft Teams staging files"
        }
    }

    # Clear SnagIt Crash Dump Files
    if (Test-Path "$env:LocalAppData\TechSmith\SnagIt") {
        foreach ($user in $Users) {
            Initialize-Cleaning -Target "C:\Users\$user\AppData\Local\TechSmith\SnagIt\CrashDumps" -Description "SnagIt crash dumps"
        }
    }

    # Clear Dropbox Cache
    if (Test-Path "C:\Program Files (x86)\Dropbox\Client") {
        $ResultText.text = "Checking Dropbox caches..."
        foreach ($user in $Users) {
            Initialize-Cleaning -Target "C:\Users\$user\Dropbox\.dropbox.cache" -Description "Dropbox cache"
        }
    } else {
        $ResultText.text = "No Dropbox installation found. Skipping Dropbox cleanup."
    }

    # Clear HP Support Assistant Installation Folder
    if (Test-Path "C:\swsetup") {
        Initialize-Cleaning -Target "C:\swsetup" -Description "HP Support Assistant installation folder"
    }

    # Clear User Downloads Folder
    foreach ($user in $Users) {
        Initialize-Cleaning -Target "C:\Users\$user\Downloads" -Description "User Downloads folder"
    }

    # Clear Azure Logs Folder
    if (Test-Path "C:\WindowsAzure\Logs") {
        Initialize-Cleaning -Target "C:\WindowsAzure\Logs" -Description "Azure Logs folder"
    }

    # Clear Office Cache
    if (Test-Path "$env:LocalAppData\Microsoft\Office") {
        foreach ($user in $Users) {
            Initialize-Cleaning -Target "C:\Users\$user\AppData\Local\Microsoft\Office\16.0\GrooveFileCache" -Description "Office Cache folder"
        }
    }

    # Clear LFSAgent Log Folder
    if (Test-Path "$env:windir\LFSAgent\Logs") {
        Initialize-Cleaning -Target "$env:windir\LFSAgent\Logs" -Description "LFSAgent Log folder"
    }

    # Clear SOTI MobiController Log Files
    if (Test-Path "C:\Program Files (x86)\SOTI\MobiControl") {
        Initialize-Cleaning -Target "C:\Program Files (x86)\SOTI\MobiControl" -FileTypes @("*.log") -Description "SOTI MobiController log files"
    }

    # Clear Cylance Log Files
    if (Test-Path "C:\Program Files\Cylance\Desktop") {
        Initialize-Cleaning -Target "C:\Program Files\Cylance\Desktop" -FileTypes @("cylog-*.log") -Description "Cylance log files"
    }

    # Inform user about the start of cleaning
    $ResultText.text = "Checking System, User, and Common Temp Folders..."

    # Common Temp Folders
    Initialize-Cleaning -Target "$env:windir\Prefetch" -Description "Prefetch files"
    Initialize-Cleaning -Target "$env:windir\Temp" -Description "Windows Temp files"
    Initialize-Cleaning -Target "$env:systemdrive\Temp" -Description "System Temp files"

    # User-Specific Temp Folders
    foreach ($user in $Users) {
        Initialize-Cleaning -Target "C:\Users\$user\AppData\Local\Temp" -Description "User Temp files"
        Initialize-Cleaning -Target "C:\Users\$user\AppData\Local\Microsoft\Windows\WER" -Description "Windows Error Reporting (WER) files"
        Initialize-Cleaning -Target "C:\Users\$user\AppData\Local\Microsoft\Windows\AppCache" -Description "App Cache files"
        Initialize-Cleaning -Target "C:\Users\$user\cookies" -Description "Cookies"
        Initialize-Cleaning -Target "C:\Users\$user\Local Settings\Temporary Internet Files" -Description "Temporary Internet Files"
        Initialize-Cleaning -Target "C:\Users\$user\recent" -Description "Recent files"
    }

    # Windows System Temp and Logs Folders
    Initialize-Cleaning -Target "$env:systemroot\SoftwareDistribution.bak" -Description "SoftwareDistribution backup files"
    Initialize-Cleaning -Target "$env:systemroot\System32\Catroot2.bak" -Description "Catroot2 backup files"
    Initialize-Cleaning -Target "$env:windir\Logs\CBS" -Description "CBS logs"
    Initialize-Cleaning -Target "$env:ProgramData\Microsoft\Windows\WER" -Description "Windows Error Reporting logs"
    Initialize-Cleaning -Target "$env:systemdrive\Windows.old" -Description "Windows.old folder"
    Initialize-Cleaning -Target "$env:ProgramData\Microsoft\Windows\RetailDemo" -Description "RetailDemo folder"

    # Vendor-Specific Caches
    Initialize-Cleaning -Target "$env:LOCALAPPDATA\AMD" -Description "AMD local cache"
    Initialize-Cleaning -Target "$env:windir/../AMD/" -Description "AMD system cache"
    Initialize-Cleaning -Target "$env:LOCALAPPDATA\NVIDIA\DXCache" -Description "NVIDIA DXCache"
    Initialize-Cleaning -Target "$env:LOCALAPPDATA\NVIDIA\GLCache" -Description "NVIDIA GLCache"
    Initialize-Cleaning -Target "$env:APPDATA\..\locallow\Intel\ShaderCache" -Description "Intel Shader Cache"

    # Custom Folders
    Initialize-Cleaning -Target "C:\Intel" -Description "Intel folder"
    Initialize-Cleaning -Target "C:\PerfLogs" -Description "Performance Logs folder"
    Initialize-Cleaning -Target "C:\Temp" -Description "Temp folder on root"
    Initialize-Cleaning -Target "C:\Drivers" -Description "Drivers folder"
    Initialize-Cleaning -Target "C:\Scripts" -Description "Scripts folder"
    Initialize-Cleaning -Target "C:\Script" -Description "Script folder"
    Initialize-Cleaning -Target "C:\Nvidia" -Description "NVIDIA folder"

    # Specific Log Files
    Initialize-Cleaning -Target "$env:windir\System32\LogFiles" -FileTypes @("*.log") -Description "System32 Log files"

    $ResultText.text = "All System, User, and Common Temp Files have been checked and cleaned as per user confirmation."

    # Perform cleanup for the Windows Updates folder (SoftwareDistribution)
    $ResultText.text = "Checking size of the SoftwareDistribution folder..."
    Initialize-Cleaning -Target "$env:windir\SoftwareDistribution" -Description "Windows Update folder (SoftwareDistribution)" -BeforeCleanScript {
        # Additional actions before cleanup (e.g., stopping the Windows Update service)
        $ResultText.text = "Stopping Windows Update service..."
        try {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            $ResultText.text = "Windows Update service stopped."
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "Failed to stop Windows Update service: $ErrorMessage"
            $ResultText.text = "Warning: Could not stop the Windows Update service. Cleanup may not proceed as expected."
        }
    } -AfterCleanScript {
        # Additional actions after cleanup (e.g., restarting the Windows Update service)
        $ResultText.text = "Restarting Windows Update service..."
        try {
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            $ResultText.text = "Windows Update service restarted successfully."
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Warning "Failed to restart Windows Update service: $ErrorMessage"
            $ResultText.text = "Warning: Could not restart the Windows Update service. Please check manually."
        }
    }

    # Empty Recycle Bin
    $ResultText.text = "Initializing Recycle Bin cleaning. Analyzing folders and calculating total size..."
    Initialize-Cleaning -IsRecycleBin -Description "Recycle Bin files" 

    # SuperDeepCleaner
    $ResultText.text = "Initializing Superdeep Cleaner. Waiting for user confirmation (WILL FREEZE FOR A GOOD WHILE HERE)..."
    
    # Prompt the user for confirmation
    $superdeepclean = [System.Windows.Forms.MessageBox]::Show(
        "Do you want to proceed with the super deep clean? This might take around 1 hour to complete.",
        "Confirmation",
        [System.Windows.Forms.MessageBoxButtons]::YesNo
    )
    
    # Handle user confirmation
    if ($superdeepclean -eq [System.Windows.Forms.DialogResult]::Yes) {
        $ResultText.text = "User confirmed. Analyzing folders and calculating total size (WILL FREEZE FOR A GOOD WHILE HERE)..."
    
        # Define patterns and folders to clean
        $patterns = @("*.tmp", "*._mp", "*.log", "*.gid", "*.chk", "*.old", "*.bak")
        $foldersToClean = @(
            "$env:systemdrive",
            "$env:windir",
            "$env:systemdrive\Windows.old"
        )
    
        # Initialize variables to collect details
        $totalSize = 0
        $folderDetails = @()
    
        # Analyze and clean each folder
        foreach ($folder in $foldersToClean) {
            if (Test-Path $folder) {
                $folderSize = 0
                foreach ($pattern in $patterns) {
                    $size = (Get-ChildItem -Path $folder -Recurse -Filter $pattern -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    $folderSize += $size
                    $totalSize += $size
                }
    
                # Convert folder size to GB
                $folderSizeGB = "{0:N2}" -f ($folderSize / 1GB)
    
                # Append details for this folder
                $folderDetails += "Folder: $folder - Size: $folderSizeGB GB"
    
                # Perform cleaning for this folder
                Initialize-Cleaning -Target $folder -Description "Superdeep Cleaning in $folder" -FileTypes $patterns
            } else {
                $folderDetails += "Folder not found: $folder"
            }
        }
    
        # Convert total size to GB
        $totalSizeGB = "{0:N2}" -f ($totalSize / 1GB)
    
        # Display completion details
        $ResultText.text = "Superdeep Cleaner completed. Total size cleaned: $totalSizeGB GB. Completed, doing a restart is recommended!
        `r`nDetails:
        `r`n- $($folderDetails -join "`n- ")`r`n"
    } else {
        # Handle cancel gracefully
        $ResultText.text = "Superdeep Cleaner was canceled by the user. No changes were made."
    }

     # Restart explorer.exe
     Start-Process explorer.exe
})

$forcenorkeyboard.Add_Click({
    $ResultText.text = "Removing secondary keyboard settings and forcing nb-NO to default..."

    # Set Norwegian as the only language/keyboard layout
    Set-WinUserLanguageList -LanguageList nb-NO -Force

    Start-Sleep -Seconds 5  # Allow time for the system to apply changes

    # Remove en-US and other 'en*' layouts if they exist
    $currentLanguages = Get-WinUserLanguageList
    $filteredLanguages = $currentLanguages.Where({ $_.LanguageTag -notlike 'en*' -and $_.LanguageTag -notlike 'us*' })
    Set-WinUserLanguageList -LanguageList $filteredLanguages -Force

    $ResultText.text = "Secondary keyboard removed. Norwegian (nb-NO) layout has been set as default."
})

        $essentialtweaks.Add_Click({
            $Form.text = "WinTool by Alerion - Initializing Essential Tweaks... `r`n"
            $ResultText.text = "Activating Essential Tweaks... Please Wait... `r`n"
        
            # Create Restore Point
            $ResultText.text += "Creating a restore point named: WinTool-Essential-Tweaks-Restorepoint... `r`n"
            try {
                Enable-ComputerRestore -Drive "C:\" | Out-Null
                Checkpoint-Computer -Description "WinTool-Essential-Tweaks-Restorepoint" -RestorePointType "MODIFY_SETTINGS"
            } catch {
                $ResultText.text += "Failed to create a restore point. Continuing without it. `r`n"
            }
        
            # Adjust Visual Effects
            $ResultText.text += "Adjusting visual effects for performance... `r`n"
            Start-Sleep -Seconds 1
            $visualEffects = @{
                "HKCU:\Control Panel\Desktop" = @{
                    "DragFullWindows" = "0"
                    "MenuShowDelay" = "200"
                    "UserPreferencesMask" = ([byte[]](144, 18, 3, 128, 16, 0, 0, 0))
                }
                "HKCU:\Control Panel\Desktop\WindowMetrics" = @{"MinAnimate" = "0"}
                "HKCU:\Control Panel\Keyboard" = @{"KeyboardDelay" = 0}
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" = @{
                    "ListviewAlphaSelect" = 0
                    "ListviewShadow" = 0
                    "TaskbarAnimations" = 0
                    "VisualFXSetting" = 3
                }
                "HKCU:\Software\Microsoft\Windows\DWM" = @{"EnableAeroPeek" = 0}
            }
            foreach ($path in $visualEffects.Keys) {
                foreach ($name in $visualEffects[$path].Keys) {
                    Set-ItemProperty -Path $path -Name $name -Value $visualEffects[$path][$name] | Out-Null
                }
            }
            $ResultText.text += "Visual effects adjusted for performance. `r`n"
        
            # Disable Cortana
            $ResultText.text += "Disabling Cortana... `r`n"
            $cortanaPaths = @(
                "HKCU:\SOFTWARE\Microsoft\Personalization\Settings",
                "HKCU:\SOFTWARE\Microsoft\InputPersonalization",
                "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
            )
            foreach ($path in $cortanaPaths) {
                if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            }
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 0
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0
            if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
                New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Cortana" -Name "IsAvailable" -Value 0
        
            # Disable Background Applications
            $ResultText.text += "Disabling background application access... `r`n"
            Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Exclude "Microsoft.Windows.Cortana*" |
                ForEach-Object {
                    Set-ItemProperty -Path $_.PsPath -Name "Disabled" -Value 1
                    Set-ItemProperty -Path $_.PsPath -Name "DisabledByUser" -Value 1
                }
        
            # Confirm Removal of Linux Subsystem
            $linuxPrompt = [System.Windows.Forms.MessageBox]::Show("Do you want to remove the Linux Subsystem (WSL)?", "Remove WSL", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($linuxPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                $ResultText.text += "Uninstalling Linux Subsystem... `r`n"
                if ([System.Environment]::OSVersion.Version.Build -eq 14393) {
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 0
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Value 0
                }
                Disable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
            } else {
                $ResultText.text += "Skipped Linux Subsystem removal. `r`n"
            }
        
            # Confirm Removal of Microsoft Teams
            $teamsPrompt = [System.Windows.Forms.MessageBox]::Show("Do you want to remove Microsoft Teams?", "Remove Microsoft Teams", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($teamsPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                $ResultText.text += "Removing pre-installed Microsoft Teams... `r`n"
                Get-AppxPackage MicrosoftTeams* | Remove-AppxPackage -ErrorAction SilentlyContinue
            } else {
                $ResultText.text += "Skipped Microsoft Teams removal. `r`n"
            }
        
            # Enable Highest Performance Power Plan
            $ResultText.text += "Enabling Highest Performance Power Plan... `r`n"
            $powerPlanUrl = "https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/Files/Bitsum-Highest-Performance.pow"
            $powerPlanPath = "$Env:windir\system32\Bitsum-Highest-Performance.pow"
            Invoke-WebRequest -Uri $powerPlanUrl -OutFile $powerPlanPath -ErrorAction SilentlyContinue
            powercfg -import $powerPlanPath e6a66b66-d6df-666d-aa66-66f66666eb66 | Out-Null
            powercfg -setactive e6a66b66-d6df-666d-aa66-66f66666eb66 | Out-Null
        
            # Enable Windows 10 Context Menu
            $ResultText.text += "Restoring Windows 10/Old context menu... `r`n"
            New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Name "InprocServer32" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" | Out-Null
        
            # Removing recently added apps and used apps from Start Menu
            $ResultText.text += "Removing recently added apps and used apps from Start Menu... `r`n"
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name "ShowFrequentList" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name "ShowRecentList" -Type DWord -Value 0

            # Disabling UAC
            $ResultText.text += "Disabling UAC... `r`n"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Type DWord -Value 0

            # Disabling Sticky Keys
            $ResultText.text += "Disabling Sticky Keys... `r`n"
            Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type DWord -Value 506

            # Hiding Task View button
            $ResultText.text += "Hiding Task View button... `r`n"
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0

            # Hiding People icon
            $ResultText.text += "Hiding People icon... `r`n"
            If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {
                New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" | Out-Null
            }
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 0

            # Showing tray icons
            $ResultText.text += "Showing tray icons... `r`n"
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Type DWord -Value 1

            # Disabling the Search box on taskbar
            $ResultText.text += "Disabling the Search box on taskbar... `r`n"
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0

            # Disabling News and Interests
            $ResultText.text += "Disabling News and Interests... `r`n"
            New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 0 -Force
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 2

            # Disabling Apps splitting on taskbar
            $ResultText.text += "Disabling Apps splitting on taskbar... `r`n"
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Type DWord -Value 0 -Force
            If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh")) {
                New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" | Out-Null
            }

            # Disables weather and news widgets
            New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Type DWord -Value 0 -Force
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableFeeds" -Type DWord -Value 0

            # Removing chat from taskbar
            $ResultText.text += "Removing chat from taskbar... `r`n"
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Type DWord -Value 0 -Force
            New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" -Name "ChatIcon" -Type DWord -Value 3 -Force

            # Adjusting taskbar alignment
            $ResultText.text += "Adjusting taskbar alignment to sane settings... `r`n"
            New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Type DWord -Value 0 -Force

            # Grouping svchost processes
            $ResultText.text += "Grouping svchost processes to free up system RAM... `r`n"
            $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value $ram -Force

            # Showing known file extensions
            $ResultText.text += "Showing known file extensions... `r`n"
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 0

            # Setting default explorer view to This PC
            $ResultText.text += "Setting default explorer view to This PC... `r`n"
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 1

            # Showing hidden system files and folders
            $ResultText.text += "Showing all hidden system files and folders... `r`n"
            New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type DWord -Value 1
            New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Type DWord -Value 1

            # Restart Explorer
            $ResultText.text += "Restarting Explorer for changes to take effect... `r`n"
            Stop-Process -Name explorer -Force
            Start-Sleep -Seconds 2
            Start-Process explorer

            $ResultText.text = "Essential Tweaks Completed. Ready for the next task!"
            $Form.text = "WinTool by Alerion"
        })
        
        $essentialundo.Add_Click({
            $Form.text = "WinTool by Alerion - Initializing Undo Essential Tweaks... `r`n"
            $ResultText.text = "Activating Undo Essential Tweaks... Please Wait... `r`n"

            # Create Restore Point
            $ResultText.text += "Creating a restore point named: WinTool-Essential-Tweaks-Undo-Restorepoint... `r`n"
            try {
                Enable-ComputerRestore -Drive "C:\" | Out-Null
                Checkpoint-Computer -Description "WinTool-Essential-Tweaks-Undo-Restorepoint" -RestorePointType "MODIFY_SETTINGS"
            } catch {
                $ResultText.text += "Failed to create a restore point. Continuing without it. `r`n"
            }

            $ResultText.text += "Disabling Windows 10 context menu... `r`n"
            Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue

            $ResultText.text += "Enabling recently added apps in Start Menu... `r`n"
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -ErrorAction SilentlyContinue

            $ResultText.text += "Preparing to reinstall Linux Subsystem... `r`n"
            $linuxPrompt = [System.Windows.Forms.MessageBox]::Show(
                "Do you want to reinstall the Linux Subsystem (WSL)?",
                "Reinstall Linux Subsystem",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($linuxPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                $ResultText.text += "Reinstalling Linux Subsystem... `r`n"
                if ([System.Environment]::OSVersion.Version.Build -eq 14393) {
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Type DWord -Value 1
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Type DWord -Value 1
                }
                Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
                $ResultText.text += "Linux Subsystem reinstalled successfully. `r`n"
            } else {
                $ResultText.text += "Skipped Linux Subsystem reinstallation. `r`n"
            }

            $ResultText.text += "Preparing to reinstall Microsoft Teams... `r`n"
            $teamsPrompt = [System.Windows.Forms.MessageBox]::Show(
                "Do you want to reinstall Microsoft Teams?",
                "Reinstall Microsoft Teams",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($teamsPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                $ResultText.text += "Reinstalling Microsoft Teams... `r`n"
                $teamsPackageUrl = "https://aka.ms/teamsdownload"
                $teamsInstallerPath = "$Env:Temp\TeamsInstaller.exe"
                Invoke-WebRequest -Uri $teamsPackageUrl -OutFile $teamsInstallerPath -ErrorAction SilentlyContinue
                Start-Process -FilePath $teamsInstallerPath -ArgumentList "/silent" -Wait
                Remove-Item -Path $teamsInstallerPath -Force -ErrorAction SilentlyContinue
                $ResultText.text += "Microsoft Teams reinstalled successfully. `r`n"
            } else {
                $ResultText.text += "Skipped Microsoft Teams reinstallation. `r`n"
            }

            $ResultText.text = " Re-Enabling Cortana... `r`n" 
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

            # Re-enabling Background Apps
            $ResultText.text += "Re-enabling background applications access... `r`n"
            $backgroundAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"

            if (Test-Path $backgroundAppsPath) {
                Get-ChildItem -Path $backgroundAppsPath | ForEach-Object {
                    Remove-ItemProperty -Path $_.PsPath -Name "Disabled" -ErrorAction SilentlyContinue
                    Remove-ItemProperty -Path $_.PsPath -Name "DisabledByUser" -ErrorAction SilentlyContinue
                }
                $ResultText.text += "Background application access has been restored. `r`n"
            } else {
                $ResultText.text += "No background application settings found to restore. `r`n"
            }

            if (!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Power Saver")) { powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a }
            if (!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Balanced")) { powercfg -duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e }
            if (!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Ultimate Performance")) { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 }
            $ResultText.text = " Restored all original power plans: Power Saver, Balanced, and Ultimate Performance."

            # Set Balanced as the active plan
            powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e

            $ResultText.text += "Balanced (Default Option) Power Plan is now set to active. `r`n"

            $ResultText.text = " Setting visual effects back to default values (Appearance)... `r`n" 
            Start-Sleep -s 1
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 1
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 400
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](158, 30, 7, 128, 18, 0, 0, 0))
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 1
            Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 1

            $ResultText.text += " Re-Enabling Task View button... `r`n" 
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 1

            $ResultText.text += " Re-Enabling People icon... `r`n" 
            If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {
                New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" | Out-Null
            }
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 1

            $ResultText.text = " Restoring UAC level... `r`n" 
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 5
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Type DWord -Value 1

            $ResultText.text = "Re-enabling Sticky Keys... `r`n" 
            Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type DWord -Value 510

            $ResultText.text = " Hiding known file extensions... `r`n" 
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 1

            $ResultText.text = " Hide tray icons... `r`n" 
            Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -ErrorAction SilentlyContinue

            # Restores Widgets to the Taskbar
            $ResultText.text += " Re-Enabling Chat, Widgets and Centering Start Menu... `r`n" 
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

            # Default Explorer view to Home
            $ResultText.text += " Explorer view reset back to Home menu... `r`n" 
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -type Dword -Value 0
            
            # Show hidden files, folders and system files that are hidden
            $ResultText.text += " Hiding Windows system folders that were previously shown ... `r`n" 
            Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden"  -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden"  -ErrorAction SilentlyContinue

            #Restart Explorer so that the taskbar can update and not look break :D
            $ResultText.text += " Explorer is restarting, screen flashes might occur... `r`n" 
            Stop-Process -name explorer
            Start-Sleep -s 5
            Start-Process -name explorer

            $ResultText.text = " Essential Undo Completed. `r`n Ready for Next Task!"
            $Form.text = "WinTool by Alerion"
        })


    $dualboottime.Add_Click({
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Type DWord -Value 1
            $ResultText.text = " Time set to UTC for consistent time in Dual Boot Systems. `r`n Ready for Next Task!"
        })

    #Valuable Windows 10 AppX apps that most people want to keep. Protected from DeBloat All.
    #Credit to /u/GavinEke for a modified version of my whitelist code
    $global:WhiteListedApps = @(
        "Microsoft.WindowsCalculator"             # Microsoft removed legacy calculator
        "Microsoft.WindowsStore"                  # Issue 1
        "Microsoft.Windows.Photos"                # Microsoft disabled/hid legacy photo viewer
        "CanonicalGroupLimited.UbuntuonWindows"   # Issue 10
        "Microsoft.Xbox.TCUI"                     # Issue 25, 91  Many home users want to play games
        "Microsoft.XboxApp"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxGamingOverlay"             # Issue 25, 91  Many home users want to play games
        "Microsoft.XboxIdentityProvider"          # Issue 25, 91  Many home users want to play games
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.MicrosoftStickyNotes"          # Issue 33  New functionality.
        "Microsoft.MSPaint"                       # Issue 32  This is Paint3D, legacy paint still exists in Windows 10
        "Microsoft.WindowsCamera"                 # Issue 65  New functionality.
        "\.NET"
        "Microsoft.HEIFImageExtension"            # Issue 68
        "Microsoft.ScreenSketch"                  # Issue 55: Looks like Microsoft will be axing snipping tool and using Snip & Sketch going forward
        "Microsoft.StorePurchaseApp"              # Issue 68
        "Microsoft.VP9VideoExtensions"            # Issue 68
        "Microsoft.WebMediaExtensions"            # Issue 68
        "Microsoft.WebpImageExtension"            # Issue 68
        "Microsoft.DesktopAppInstaller"           # Issue 68
        "WindSynthBerry"                          # Issue 68
        "MIDIBerry"                               # Issue 68
        "Slack"                                   # Issue 83
        "*Nvidia*"                                # Issue 198
        "Microsoft.MixedReality.Portal"           # Issue 195
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
            "Microsoft.Windows.HolographicFirstRun"       # Added 1709
            "Microsoft.Windows.NarratorQuickStart"
            "Microsoft.Windows.OOBENetworkCaptivePortal"  # Added 1709
            "Microsoft.Windows.OOBENetworkConnectionFlow" # Added 1709
            "Microsoft.Windows.ParentalControls"
            "Microsoft.Windows.PeopleExperienceHost"
            "Microsoft.Windows.PinningConfirmationDialog"
            "Microsoft.Windows.SecHealthUI"               # Issue 117 Windows Defender
            "Microsoft.Windows.SecondaryTileExperience"   # Added 1709
            "Microsoft.Windows.SecureAssessmentBrowser"
            "Microsoft.Windows.ShellExperienceHost"
            "Microsoft.Windows.XGpuEjectDialog"
            "Microsoft.XboxGameCallableUI"                # Issue 91
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
        "Microsoft.Office.Lens"                           # Issue 77
        "Microsoft.Office.OneNote"
        "Microsoft.Office.Sway"
        "Microsoft.OneConnect"
        "Microsoft.People"
        "Microsoft.Print3D"
        "Microsoft.Paint"
        "Microsoft.RemoteDesktop"                         # Issue 120
        "Microsoft.SkypeApp"
        "Microsoft.Wallet"
        "Microsoft.Whiteboard"
        "Microsoft.StorePurchaseApp"
        "Microsoft.Office.Todo.List"                      # Issue 77
        "Microsoft.Whiteboard"                            # Issue 77
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
            $Form.text = "WinTool by Alerion - Removing Bloatware..."
            $ResultText.text = " Hang on while Windows Bloatware is being removed"
            $ErrorActionPreference = 'SilentlyContinue'

            Function SystemPrep {

                $ResultText.text = " Starting Sysprep Fixes"
   
                $ResultText.text = " Adding Registry key to disable Windows Store Automatic Updates"
                $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
                If (!(Test-Path $registryPath)) {
                    Mkdir $registryPath
                    New-ItemProperty $registryPath AutoDownload -Value 2 
                }
                Set-ItemProperty $registryPath AutoDownload -Value 2

                $ResultText.text = " Stopping InstallService"
                Stop-Service InstallService
                $ResultText.text = " Setting InstallService Startup to Disabled"
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
                    Get-AppxPackage -Name $Bloat | Remove-AppxPackage
                    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $Bloat | Remove-AppxProvisionedPackage -Online
                    $ResultText.text = " Trying to remove $Bloat."
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
                    $ResultText.text = " Removing $Key from registry"
                    Remove-Item $Key -Recurse
                }
            }
          
            Function Protect-Privacy { 
  
                #Creates a PSDrive to be able to access the 'HKCR' tree
                New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
          
                #Disables Windows Feedback Experience
                $ResultText.text = " Disabling Windows Feedback Experience program"
                $Advertising = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
                If (Test-Path $Advertising) {
                    Set-ItemProperty $Advertising Enabled -Value 0
                }
            
                $ResultText.text = " Adding Registry key to prevent bloatware apps from returning"
                #Prevents bloatware applications from returning
                $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
                If (!(Test-Path $registryPath)) {
                    Mkdir $registryPath
                    New-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 
                }          
      
                $ResultText.text = " Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
                $Holo = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic'    
                If (Test-Path $Holo) {
                    Set-ItemProperty $Holo FirstRunSucceeded -Value 0
                }
      
                #Disables live tiles
                $ResultText.text = " Disabling live tiles"
                $Live = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'    
                If (!(Test-Path $Live)) {
                    mkdir $Live  
                    New-ItemProperty $Live NoTileApplicationNotification -Value 1
                }
      
                $ResultText.text = " Removing CloudStore from registry if it exists"
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
                $ResultText.text = " Disabling scheduled tasks"
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

                $layoutFile = "C:\Windows\StartMenuLayout.xml"

                #Delete layout file if it already exists
                If (Test-Path $layoutFile) {
                    Remove-Item $layoutFile
                }

                #Creates the blank layout file
                $START_MENU_LAYOUT | Out-File $layoutFile -Encoding ASCII

                $regAliases = @("HKLM", "HKCU")

                #Assign the start layout and force it to apply with "LockedStartLayout" at both the machine and user level
                foreach ($regAlias in $regAliases) {
                    $basePath = $regAlias + ":\SOFTWARE\Policies\Microsoft\Windows"
                    $keyPath = $basePath + "\Explorer" 
                    IF (!(Test-Path -Path $keyPath)) { 
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
                foreach ($regAlias in $regAliases) {
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
  
            $ResultText.text = " Initiating Sysprep.."
            SystemPrep

            $ResultText.text = " Removing bloatware apps(This might take more than 10 minutes)"
            RemoveMassiveBloat
            DebloatAll

            $ResultText.text = " Removing leftover bloatware registry keys."
            Remove-Keys

            $ResultText.text = " Checking to see if any Allowlisted Apps were removed, and if so re-adding them."
            FixWhitelistedApps

            $ResultText.text = " Disabling unneccessary scheduled tasks, and preventing bloatware from returning."
            Protect-Privacy

            $ResultText.text = " Unpinning tiles from the Start Menu."
            UnpinStart

            $ResultText.text = " Setting the 'InstallService' Windows service back to 'Started' and the Startup Type 'Automatic'."
            CheckDMWService
            CheckInstallService

            $ResultText.text = " Finished removing bloatware apps. `r`n Ready for Next Task!"
            $Form.text = "WinTool by Alerion"
        })

    $reinstallbloat.Add_Click({
            $Form.text = "WinTool by Alerion - Reinstalling MS Store Apps and activating deactivated features..."
            $ResultText.text = " Reinstalling MS Store Apps and activating deactivated features for MS Store..."
            $ErrorActionPreference = 'SilentlyContinue'
            #This function will revert the changes you made when running the Start-Debloat function.

            # Reinstalling all removed AppxPackages
            $ResultText.text += "`r`nReinstalling MS Store apps for all users..."
            Get-AppxPackage -AllUsers | ForEach-Object {
                try {
                    Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -Verbose
                    $ResultText.text += "`r`nReinstalled: $($_.Name)"
                } catch {
                    $ResultText.text += "`r`nFailed to reinstall: $($_.Name)"
                }
            }

            #Tells Windows to enable your advertising information.    
            $ResultText.text = " Re-enabling key to show advertisement information"
            $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            If (Test-Path $Advertising) {
                Set-ItemProperty $Advertising  Enabled -Value 1
            }

            #Enables bloatware applications               
            $ResultText.text = " Adding Registry key to allow bloatware apps to return"
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            If (!(Test-Path $registryPath)) {
                New-Item $registryPath 
            }
            Set-ItemProperty $registryPath  DisableWindowsConsumerFeatures -Value 0 
    
            #Changes Mixed Reality Portal Key 'FirstRunSucceeded' to 1
            $ResultText.text = " Setting Mixed Reality Portal value to 1"
            $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"
            If (Test-Path $Holo) {
                Set-ItemProperty $Holo  FirstRunSucceeded -Value 1 
            }
    
            #Re-enables live tiles
            $ResultText.text = " Enabling live tiles"
            $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"
            If (!(Test-Path $Live)) {
                New-Item $Live 
            }
            Set-ItemProperty $Live  NoTileApplicationNotification -Value 0 
   
            # Re-enabling scheduled tasks
            $ResultText.text += "`r`nRe-enabling scheduled tasks..."
            $tasksToEnable = @(
                "XblGameSaveTaskLogon",
                "XblGameSaveTask",
                "Consolidator",
                "UsbCeip",
                "DmClient",
                "DmClientOnScenarioDownload"
            )
            foreach ($task in $tasksToEnable) {
                try {
                    Get-ScheduledTask -TaskName $task | Enable-ScheduledTask
                } catch {
                    $ResultText.text += "`r`nFailed to enable task: $task"
                }
            }

            $ResultText.text = " Re-enabling and starting WAP Push Service"
            #Enable and start WAP Push Service
            Set-Service "dmwappushservice" -StartupType Automatic
            Start-Service "dmwappushservice"

            $ResultText.text = " Re-enabling and starting the Diagnostics Tracking Service"
            #Enabling the Diagnostics Tracking Service
            Set-Service "DiagTrack" -StartupType Automatic
            Start-Service "DiagTrack"
            $ResultText.text = " Done reverting changes!"

            #
            $ResultText.text = " Restoring 3D Objects from Explorer 'My Computer' submenu"
            $Objects32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
            $Objects64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
            If (!(Test-Path $Objects32)) {
                New-Item $Objects32
            }
            If (!(Test-Path $Objects64)) {
                New-Item $Objects64
            }

            $ResultText.text = " Finished Reinstalling Bloatware Apps. `r`n Ready for Next Task!"
            $Form.text = "WinTool by Alerion"
        })

    $defaultwindowsupdate.Add_Click({
            $ResultText.text = " Enabling driver offering through Windows Update..."
            Start-Sleep -s 1
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
            $ResultText.text = " Enabling Windows Update automatic restart..."
            Start-Sleep -s 1
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -ErrorAction SilentlyContinue
            $ResultText.text = " Enabled driver offering through Windows Update"
            Start-Sleep -s 1
            $ResultText.text = " Windows Update has been set to Default Settings. `r`n Ready for Next Task!"
        })

    $securitywindowsupdate.Add_Click({
            $ResultText.text = " Disabling driver offering through Windows Update..."
            Start-Sleep -s 1
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
            $ResultText.text = " Disabling Windows Update automatic restart..."
            Start-Sleep -s 1
            If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
                New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
            }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
            $ResultText.text = " Disabled driver offering through Windows Update"
            Start-Sleep -s 1
            $ResultText.text = " Windows Update has been set to Sane Settings. `r`n Ready for Next Task!"
        })

    $gamingtweaks.Add_Click({
            $Form.text = "WinTool by Alerion - Initializing Gaming Tweaks..."

            $ResultText.text = " Disabling Fullscreen Optimization..."
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Type DWord -Value 2
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Type DWord -Value 2
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DSEBehavior" -Type DWord -Value 2
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 0

            $ResultText.text = " Apply Gaming Optimization Fixes..."
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Type DWord -Value 8
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Type DWord -Value 6
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Type String -Value "High"
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "SFIO Priority" -Type String -Value "High"
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ8Priority" -Type DWord -Value 1

            $ResultText.text = " Forcing RAW Mouse Input and Disabling Enhance Pointer Precision..."
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
            if ($checkscreenscale -eq "100") {
                $ResultText.text = " Windows screen scale is Detected as 100%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,C0,CC,0C,00,00,00,00,00,80,99,19,00,00,00,00,00,40,66,26,00,00,00,00,00,00,33,33,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            elseif ($checkscreenscale -eq "125") {
                $ResultText.text = " Windows screen scale is Detected as 125%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,00,00,10,00,00,00,00,00,00,00,20,00,00,00,00,00,00,00,30,00,00,00,00,00,00,00,40,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            elseif ($checkscreenscale -eq "150") {
                $ResultText.text = " Windows screen scale is Detected as 150%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,30,33,13,00,00,00,00,00,60,66,26,00,00,00,00,00,90,99,39,00,00,00,00,00,C0,CC,4C,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            elseif ($checkscreenscale -eq "175") {
                $ResultText.text = " Windows screen scale is Detected as 175%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,60,66,16,00,00,00,00,00,C0,CC,2C,00,00,00,00,00,20,33,43,00,00,00,00,00,80,99,59,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            elseif ($checkscreenscale -eq "200") {
                $ResultText.text = " Windows screen scale is Detected as 200%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,90,99,19,00,00,00,00,00,20,33,33,00,00,00,00,00,B0,CC,4C,00,00,00,00,00,40,66,66,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            elseif ($checkscreenscale -eq "225") {
                $ResultText.text = " Windows screen scale is Detected as 225%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,C0,CC,1C,00,00,00,00,00,80,99,39,00,00,00,00,00,40,66,56,00,00,00,00,00,00,33,73,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            elseif ($checkscreenscale -eq "250") {
                $ResultText.text = " Windows screen scale is Detected as 250%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,00,00,20,00,00,00,00,00,00,00,40,00,00,00,00,00,00,00,60,00,00,00,00,00,00,00,80,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            elseif ($checkscreenscale -eq "300") {
                $ResultText.text = " Windows screen scale is Detected as 300%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,60,66,26,00,00,00,00,00,C0,CC,4C,00,00,00,00,00,20,33,73,00,00,00,00,00,80,99,99,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            elseif ($checkscreenscale -eq "350") {
                $ResultText.text = " Windows screen scale is Detected as 350%, Applying Mouse Fix for it..."
                $YourInputX = "00,00,00,00,00,00,00,00,C0,CC,2C,00,00,00,00,00,80,99,59,00,00,00,00,00,40,66,86,00,00,00,00,00,00,33,B3,00,00,00,00,00"
                $YourInputY = "00,00,00,00,00,00,00,00,00,00,38,00,00,00,00,00,00,00,70,00,00,00,00,00,00,00,A8,00,00,00,00,00,00,00,E0,00,00,00,00,00"
                $RegPath = 'HKCU:\Control Panel\Mouse'
                $hexifiedX = $YourInputX.Split(',') | ForEach-Object { "0x$_" }
                $hexifiedY = $YourInputY.Split(',') | ForEach-Object { "0x$_" }
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseXCurve" -Type Binary -Value (([byte[]]$hexifiedX))
                Set-ItemProperty -Path "$RegPath" -Name "SmoothMouseYCurve" -Type Binary -Value (([byte[]]$hexifiedY))
            }
            else {
                $ResultText.text = " Screen scale is not set to traditional value, nothing has been set!"
            }

            $ResultText.text = " Enabling Gaming Mode..."
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Type DWord -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel" -Type DWord -Value 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "GamePanelStartupTipIndex" -Type DWord -Value 3
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Type DWord -Value 0

            $ResultText.text = " Enabling HAGS..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Type DWord -Value 2

            $ResultText.text = " Disabling Core Parking on current PowerPlan Ultimate Performance..."
            powercfg -attributes SUB_PROCESSOR CPMINCORES -ATTRIB_HIDE | Out-Null
            Powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 | Out-Null
            Powercfg -setactive scheme_current | Out-Null

            $ResultText.text = " Optimizing Network, applying Tweaks for no throttle and maximum speed..."
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

            if ((Get-CimInstance -ClassName Win32_ComputerSystem).PCSystemType -ne 2) {
                $adapters = Get-NetAdapter -Physical | Get-NetAdapterPowerManagement | Where-Object -FilterScript { $_.AllowComputerToTurnOffDevice -ne "Unsupported" }
                foreach ($adapter in $adapters) {
                    $adapter.AllowComputerToTurnOffDevice = "Disabled"
                    $adapter | Set-NetAdapterPowerManagement
                }
            }
            Start-Sleep -s 5

            $NetworkIDS = @((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*").PSChildName)

            $ResultText.text = " Disabling Nagles Algorithm..."

            foreach ($NetworkID in $NetworkIDS) {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NetworkID" -Name "TcpAckFrequency" -Type DWord -Value 1
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$NetworkID" -Name "TCPNoDelay" -Type DWord -Value 1
            }

            $ResultText.text = " Forcing Windows to stop tolerating high DPC/ISR latencies..."
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

            $ResultText.text = " Decreasing mouse and keyboard buffer sizes..."
            New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" | Out-Null -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -Type DWord -Value 0x00000010
            New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" | Out-Null -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -Type DWord -Value 0x00000010

            $ResultText.text = " Disabling DMA memory protection and cores isolation..."
            bcdedit /set vsmlaunchtype Off | Out-Null
            bcdedit /set vm No | Out-Null
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" | Out-Null -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "DisableExternalDMAUnderLock" -Type DWord -Value 0
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" | Out-Null -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -Name "HVCIMATRequired" -Type DWord -Value 0

            $ResultText.text = " Disabling Process and Kernel Mitigations... (Throws an error, im unsure of why)"
            ForEach ($v in (Get-Command -Name "Set-ProcessMitigation").Parameters["Disable"].Attributes.ValidValues) { Set-ProcessMitigation -System -Disable $v.ToString() -ErrorAction SilentlyContinue }
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "DisableExceptionChainValidation" -Type DWord -Value 1
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "KernelSEHOPEnabled" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "EnableCfg" -Type DWord -Value 0

            $ResultText.text = " Disabling drivers get paged into virtual memory..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Type DWord -Value 1

            $ResultText.text = " Enabling big system memory caching to improve microstuttering..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Type DWord -Value 1

            $ResultText.text = " Forcing contiguous memory allocation in the DirectX Graphics Kernel..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "DpiMapIommuContiguous" -Type DWord -Value 1

            $ResultText.text = " Disabling High Precision Event Timer..."
            Invoke-WebRequest -Uri "https://github.com/alerion921/WinTool-for-Win11/blob/main/Files/SetTimerResolutionService.exe" -OutFile "$Env:windir\system32\SetTimerResolutionService.exe" -ErrorAction SilentlyContinue
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
            bcdedit /set { globalsettings } custom:16000067 true | Out-Null
            bcdedit /set { globalsettings } custom:16000069 true | Out-Null
            bcdedit /set { globalsettings } custom:16000068 true | Out-Null
            wmic path Win32_PnPEntity where "name='High precision event timer'" call disable | Out-Null

            $CheckGPU = wmic path win32_VideoController get name
            if (($CheckGPU -like "*GTX*") -or ($CheckGPU -like "*RTX*")) {
                $ResultText.text = " NVIDIA GTX/RTX Card Detected! Applying Nvidia Power Tweaks..."
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/Files/BaseProfile.nip" -OutFile "$Env:windir\system32\BaseProfile.nip" -ErrorAction SilentlyContinue
                Invoke-WebRequest -Uri "https://github.com/alerion921/WinTool-for-Win11/blob/main/Files/nvidiaProfileInspector.exe" -OutFile "$Env:windir\system32\nvidiaProfileInspector.exe" -ErrorAction SilentlyContinue
                Push-Location
                set-location "$Env:windir\system32\"
                nvidiaProfileInspector.exe /s -load "BaseProfile.nip"
                Pop-Location
            }
            else {
                $ResultText.text = " Nvidia GTX/RTX Card Not Detected! Skipping..."
            } 

            $CheckGPURegistryKey0 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000").DriverDesc
            $CheckGPURegistryKey1 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001").DriverDesc
            $CheckGPURegistryKey2 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002").DriverDesc
            $CheckGPURegistryKey3 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0003").DriverDesc

            if (($CheckGPURegistryKey0 -like "*GTX*") -or ($CheckGPURegistryKey0 -like "*RTX*")) {
                $ResultText.text = " Nvidia GTX/RTX Card Registry Path 0000 Detected! Applying Nvidia Latency Tweaks..."
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
            }
            elseif (($CheckGPURegistryKey1 -like "*GTX*") -or ($CheckGPURegistryKey1 -like "*RTX*")) {
                $ResultText.text = " Nvidia GTX/RTX Card Registry Path 0001 Detected! Applying Nvidia Latency Tweaks..."
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
            }
            elseif (($CheckGPURegistryKey2 -like "*GTX*") -or ($CheckGPURegistryKey2 -like "*RTX*")) {
                $ResultText.text = " Nvidia GTX/RTX Card Registry Path 0002 Detected! Applying Nvidia Latency Tweaks..."
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
            }
            elseif (($CheckGPURegistryKey3 -like "*GTX*") -or ($CheckGPURegistryKey3 -like "*RTX*")) {
                $ResultText.text = " Nvidia GTX/RTX Card Registry Path 0003 Detected! Applying Nvidia Latency Tweaks..."
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
            }
            else {
                $ResultText.text = " No NVIDIA GTX/RTX Card Registry entry Found! Skipping..."
            }

            $ResultText.text = " Disabling VBS..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Type DWord -Value 0
    
            $ResultText.text = " Gaming Tweaks Applied. `r`n Ready for Next Task!"
            $Form.text = "WinTool by Alerion"
        })

    $securitypatches.Add_Click({
            $Form.text = "WinTool by Alerion - Patching known Security Exploits..."
            $ResultText.text = " Applying Security Patches to disable known exploits"

            $ResultText.text = " Disabling Spectre Meltdown vulnerability on this system"
            #####SPECTRE MELTDOWN#####
            #https://support.microsoft.com/en-us/help/4073119/protect-against-speculative-execution-side-channel-vulnerabilities-in
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -Type DWord -Value 72 -Force
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverrideMask" -Type DWord -Value 3 -Force
            Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Virtualization" -Name "MinVmVersionForCpuBasedMitigations" -Type String -Value 1.0 -Force

            $ResultText.text = " Disabling LLMNR for additional security.."
            #Disable LLMNR
            #https://www.blackhillsinfosec.com/how-to-disable-llmnr-why-you-want-to/
            New-Item -Path "HKLM:\Software\policies\Microsoft\Windows NT\" -Name "DNSClient" -Force
            Set-ItemProperty -Path "HKLM:\Software\policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Type DWord -Value 0 -Force

            $ResultText.text = " Disabling NetBIOS.."
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
            $ResultText.text = " TCP Timestamps deactivated.."
            netsh int tcp set global timestamps=disabled

            #Enable DEP
            $ResultText.text = " Enabling DEP.."
            BCDEDIT /set "{current}" nx OptOut
            Set-Processmitigation -System -Enable DEP
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoDataExecutionPrevention" -Type "DWORD" -Value 0 -Force
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableHHDEP" -Type "DWORD" -Value 0 -Force

            $ResultText.text = " Disabling WPAD.."
            #Disable WPAD
            #https://adsecurity.org/?p=3299
            New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\" -Name "Wpad" -Force
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" -Name "Wpad" -Force
            Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" -Name "WpadOverride" -Type "DWORD" -Value 1 -Force
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" -Name "WpadOverride" -Type "DWORD" -Value 1 -Force

            $ResultText.text = " Enable LSA Protection/Auditing.."
            #Enable LSA Protection/Auditing
            #https://adsecurity.org/?p=3299
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\" -Name "LSASS.exe" -Force
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\LSASS.exe" -Name "AuditLevel" -Type "DWORD" -Value 8 -Force

            $ResultText.text = " Disabling Windows Script Host.."
            #Disable Windows Script Host
            #https://adsecurity.org/?p=3299
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\" -Name "Settings" -Force
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" -Name "Enabled" -Type "DWORD" -Value 0 -Force
    
            $ResultText.text = " Disabling WDigest.."
            #Disable WDigest
            #https://adsecurity.org/?p=3299
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\SecurityProviders\Wdigest" -Name "UseLogonCredential" -Type "DWORD" -Value 0 -Force

            $ResultText.text = " Blocked Untrusted Fonts.."
            #Block Untrusted Fonts
            #https://adsecurity.org/?p=3299
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel\" -Name "MitigationOptions" -Type "QWORD" -Value "1000000000000" -Force
    
            $ResultText.text = " Disabling Office OLE.."
            #Disable Office OLE
            #https://adsecurity.org/?p=3299
            $officeversions = '16.0', '15.0', '14.0', '12.0'
            ForEach ($officeversion in $officeversions) {
                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Office\$officeversion\Outlook\" -Name "Security" -Force
                New-Item -Path "HKCU:\SOFTWARE\Microsoft\Office\$officeversion\Outlook\" -Name "Security" -Force
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\$officeversion\Outlook\Security\" -Name "ShowOLEPackageObj" -Type "DWORD" -Value "0" -Force
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Office\$officeversion\Outlook\Security\" -Name "ShowOLEPackageObj" -Type "DWORD" -Value "0" -Force
            }

            $ResultText.text = " Disabling SMB 1.0 protocol.."
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

            $ResultText.text = " Disabling SMB Server.."
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
                $ResultText.text = " Enable real-time monitoring"
                Set-MpPreference -DisableRealtimeMonitoring 0
                #Enable sample submission
                $ResultText.text = " Enable sample submission"
                Set-MpPreference -SubmitSamplesConsent 2
                #Enable checking signatures before scanning
                $ResultText.text = " Enable checking signatures before scanning"
                Set-MpPreference -CheckForSignaturesBeforeRunningScan 1
                #Enable behavior monitoring
                $ResultText.text = " Enable behavior monitoring"
                Set-MpPreference -DisableBehaviorMonitoring 0
                #Enable IOAV protection
                $ResultText.text = " Enable IOAV protection"
                Set-MpPreference -DisableIOAVProtection 0
                #Enable script scanning
                $ResultText.text = " Enable script scanning"
                Set-MpPreference -DisableScriptScanning 0
                #Enable removable drive scanning
                $ResultText.text = " Enable removable drive scanning"
                Set-MpPreference -DisableRemovableDriveScanning 0
                #Enable Block at first sight
                $ResultText.text = " Enable Block at first sight"
                Set-MpPreference -DisableBlockAtFirstSeen 0
                #Enable potentially unwanted 
                $ResultText.text = " Enable potentially unwanted apps"
                Set-MpPreference -PUAProtection Enabled
                #Schedule signature updates every 8 hours
                $ResultText.text = " Schedule signature updates every 8 hours"
                Set-MpPreference -SignatureUpdateInterval 8
                #Enable archive scanning
                $ResultText.text = " Enable archive scanning"
                Set-MpPreference -DisableArchiveScanning 0
                #Enable email scanning
                $ResultText.text = " Enable email scanning"
                Set-MpPreference -DisableEmailScanning 0
                #Enable File Hash Computation
                $ResultText.text = " Enable File Hash Computation"
                Set-MpPreference -EnableFileHashComputation 1
                #Enable Intrusion Prevention System
                $ResultText.text = " Enable Intrusion Prevention System"
                Set-MpPreference -DisableIntrusionPreventionSystem $false
                #Enable Windows Defender Exploit Protection
                $ResultText.text = " Enabling Exploit Protection"
                Set-ProcessMitigation -PolicyFilePath C:\temp\"Windows Defender"\DOD_EP_V3.xml
                #Set cloud block level to 'High'
                $ResultText.text = " Set cloud block level to 'High'"
                Set-MpPreference -CloudBlockLevel High
                #Set cloud block timeout to 1 minute
                $ResultText.text = " Set cloud block timeout to 1 minute"
                Set-MpPreference -CloudExtendedTimeout 50
                $ResultText.text = " Updating Windows Defender Exploit Guard settings"
                #Enabling Controlled Folder Access and setting to block mode
                #Set-MpPreference -EnableControlledFolderAccess Enabled 
                #Enabling Network Protection and setting to block mode
                $ResultText.text = " Enabling Network Protection and setting to block mode"
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
    
                $ResultText.text = " Windows defender security patches has been applied..."
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
    
                $ResultText.text = " SSL Hardening Activated..."
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

                $ResultText.text = " SMB Optimized and Hardening Activated..."
            }

            $ResultText.text = " All known security exploits have been patched successfully & additional system hardening has been applied. `r`n Ready for Next Task!"
            $Form.text = "WinTool by Alerion"
        })

        $onedrive.Add_Click({
            Stop-Process -ProcessName sharepoint -Force -ErrorAction SilentlyContinue
            taskkill /F /IM sharepoint.exe

            Stop-Process -ProcessName explorer -Force -ErrorAction SilentlyContinue
            taskkill /F /IM Explorer.exe

            Stop-Process -ProcessName OneDrive -Force -ErrorAction SilentlyContinue
            taskkill /F /IM OneDrive.exe

            # Define potential OneDrive installation paths
            $oneDrivePaths = @(
                "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
                "C:\Program Files\Microsoft OneDrive\OneDrive.exe",
                "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe"
            )
        
            # Check if OneDrive is installed
            $oneDriveInstalled = $oneDrivePaths | Where-Object { Test-Path $_ }
        
            if ($oneDriveInstalled) {
                $confirmOneDrive = [System.Windows.Forms.MessageBox]::Show(
                    "This may take a while. Are you sure you want to proceed? (THIS HAS NOT BEEN TESTED PROPERLY. THE WORST THAT CAN HAPPEN IS THAT YOU WONT BE ABLE TO REINSTALL ONEDRIVE, WHO CARES)",
                    "Remove OneDrive?",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
        
                if ($confirmOneDrive -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $Form.text = "WinTool by Alerion - Removing OneDrive..."
                    $ResultText.text = "Uninstalling OneDrive..."
        
                    # Detect the OneDrive folder dynamically
                    $oneDriveFolder = Get-ChildItem -Path "$env:USERPROFILE" -Directory |
                    Where-Object { $_.Name -like "OneDrive*" } |
                    Select-Object -ExpandProperty FullName -First 1
                    
                    if ($oneDriveFolder) {
                        # Inform the user that files will be backed up from the detected folder
                        $ResultText.text = "Detected OneDrive folder: $oneDriveFolder. Backing up files..."
                    
                        # Standard folders and their destinations
                        $backupMappings = @(
                            @{ Source = "Desktop"; Destination = "$env:USERPROFILE\Desktop" },
                            @{ Source = "Documents"; Destination = "$env:USERPROFILE\Documents" },
                            @{ Source = "Pictures"; Destination = "$env:USERPROFILE\Pictures" },
                            @{ Source = "Downloads"; Destination = "$env:USERPROFILE\Downloads" },
                            @{ Source = "Music"; Destination = "$env:USERPROFILE\Music" },
                            @{ Source = "Videos"; Destination = "$env:USERPROFILE\Videos" },
                            @{ Source = "Favorites"; Destination = "$env:USERPROFILE\Favorites" }
                        )
                    
                        # Backup standard folders
                        foreach ($mapping in $backupMappings) {
                            $source = Join-Path -Path $oneDriveFolder -ChildPath $mapping.Source
                            $destination = $mapping.Destination
                            if (Test-Path $source) {
                                $ResultText.text = "Copying $source to $destination..."
                                Copy-Item -Path $source\* -Destination $destination -Recurse -Force -ErrorAction SilentlyContinue
                            }
                        }
                    
                        # Copy any additional folders in OneDrive to the user's profile
                        $allSubFolders = Get-ChildItem -Path $oneDriveFolder -Directory |
                            Where-Object { $backupMappings.Source -notcontains $_.Name } # Exclude standard folders already handled
                        foreach ($subFolder in $allSubFolders) {
                            $source = $subFolder.FullName
                            $destination = Join-Path -Path $env:USERPROFILE -ChildPath $subFolder.Name
                    
                            # Inform the user and copy the folder
                            $ResultText.text = "Copying additional folder $source to $destination..."
                            Copy-Item -Path $source -Destination $destination -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    
                        $ResultText.text = "Backup completed. Standard folders and additional files from OneDrive have been successfully copied."
                    } else {
                        $ResultText.text = "No OneDrive folder detected. Skipping file backup."
                    }

                    # Uninstall all variants of OneDrive using winget
                    $ResultText.text = "Detecting all installed variants of OneDrive using winget..."

                    # Get all installed packages matching 'OneDrive'
                    $oneDrivePackages = winget list | Where-Object { $_ -match "OneDrive" }

                    if ($oneDrivePackages) {
                        foreach ($package in $oneDrivePackages) {
                            $packageId = $package | ForEach-Object { ($_ -split '\s+')[0] }  # Extract the first column (ID)
                            $ResultText.text = "Uninstalling $packageId..."
                            
                            # Uninstall the package
                            Start-Process -FilePath "winget" -ArgumentList "uninstall --id $packageId --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait
                        }

                        $ResultText.text = "All detected OneDrive variants have been uninstalled."
                    } else {
                        $ResultText.text = "No OneDrive variants detected for uninstallation."
                    }
        
                    # Cleanup leftover files and registry entries
                    $ResultText.text = "Cleaning up leftover files and registry entries..."
                    $cleanupPaths = @(
                        "$env:LOCALAPPDATA\Microsoft\OneDrive",
                        "$env:LOCALAPPDATA\OneDrive",
                        "$env:PROGRAMDATA\Microsoft OneDrive",
                        "$env:SystemDrive\OneDriveTemp",
                        "C:\Program Files\Microsoft OneDrive",
                        "C:\Program Files (x86)\Microsoft OneDrive",
                        "C:\Users\Default\OneDrive",
                        "$env:USERPROFILE\OneDrive"
                    )
        
                    foreach ($path in $cleanupPaths) {
                        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $path
                    }
        
                    # Delete registry entries
                    Remove-Item -Path "HKCU:\Software\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
 
                    Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
                    Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
        
                    # Remove scheduled tasks
                    Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue |
                        Unregister-ScheduledTask -Confirm:$false
        
                    # Restore User Shell Folders
                    $ResultText.text = "Restoring user shell folders to default locations..."
                    $defaultPaths = @{
                        "{0DDD015D-B06C-45D5-8C4C-F59713854639}" = "%USERPROFILE%\Pictures"      # Pictures
                        "{374DE290-123F-4565-9164-39C4925E467B}" = "%USERPROFILE%\Downloads"    # Downloads
                        "{F42EE2D3-909F-4907-8871-4C22FC0BF756}" = "%USERPROFILE%\Documents"    # Documents
                        "Pictures" = "%USERPROFILE%\Pictures"      # Pictures
                        "My Pictures" = "%USERPROFILE%\Pictures"      # Pictures
                        "Downloads" = "%USERPROFILE%\Downloads"    # Downloads
                        "Documents" = "%USERPROFILE%\Documents"    # Documents
                        "Music" = "%USERPROFILE%\Music"        # Music
                        "Videos" = "%USERPROFILE%\Videos"       # Videos
                        "My Music" = "%USERPROFILE%\Music"        # Music
                        "My Videos" = "%USERPROFILE%\Videos"       # Videos
                        "Desktop" = "%USERPROFILE%\Desktop"      # Desktop
                        "Favorites" = "%USERPROFILE%\Favorites"    # Favorites
                        "Personal" = "%USERPROFILE%\Personal"    # Favorites
                    }
        
                    foreach ($guid in $defaultPaths.Keys) {
                        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
                        $valuePath = $defaultPaths[$guid]
                        Set-ItemProperty -Path $regPath -Name $guid -Value $valuePath
                        Write-Output "Restored $guid to $valuePath"
                    }
        
                    $Form.text = "WinTool by Alerion - OneDrive Removed"
                    $ResultText.text = "OneDrive has been completely removed. User shell folders restored. Ready for the next task!"
                } else {
                    $Form.text = "WinTool by Alerion - Operation Cancelled"
                    $ResultText.text = "OneDrive removal was cancelled. Ready for the next task!"
                }
            } else {
                # Reinstall prompt
                $confirmReinstall = [System.Windows.Forms.MessageBox]::Show(
                    "OneDrive is not currently installed. Would you like to reinstall it?",
                    "Reinstall OneDrive?",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
        
                if ($confirmReinstall -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $Form.text = "WinTool by Alerion - Reinstalling OneDrive..."
                    $ResultText.text = "Reinstalling OneDrive using winget. Please wait..."
                    Start-Process -FilePath "winget" -ArgumentList "install --id Microsoft.OneDrive -e --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait
                    $ResultText.text = "OneDrive has been successfully reinstalled."
                } else {
                    $Form.text = "WinTool by Alerion - Reinstallation Cancelled"
                    $ResultText.text = "OneDrive reinstallation was cancelled. Ready for the next task!"
                }
            }
        })

    $darkmode.Add_Click({
            $ResultText.text = " System dark mode set to active!"
            New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -PropertyType "DWord" -Name "AppsUseLightTheme" -Value "0" -Force
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value "0"
            $ResultText.text = " Dark mode successfully activated. `r`n Ready for Next Task!"
        })

    $lightmode.Add_Click({ 
            $ResultText.text = " System Light Mode set to active!"
            Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Force
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1
            $ResultText.text = " Enabled Light Mode. `r`n Ready for Next Task!"
        })

    $removehomegallery.Add_Click({
            if ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}") -or (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}")) {
                REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /f
                REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f
                #I can possibly do this to remove the onedrive apperance aswell
                $ResultText.text = " Home and Gallery Removed successfully! `r`n Ready for Next Task!"
            }
            else {
                REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /f /ve /t REG_SZ /d "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
                REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f /ve /t REG_SZ /d "CLSID_MSGraphHomeFolder"
                $ResultText.text = " Home and Gallery Restored successfully! `r`n Ready for Next Task!"
            }
        })

    $DisableNumLock.Add_Click({
            $ResultText.text = " Disable NumLock after startup..."
            Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type DWord -Value 0
            Add-Type -AssemblyName System.Windows.Forms
            If (([System.Windows.Forms.Control]::IsKeyLocked('NumLock'))) {
                $wsh = New-Object -ComObject WScript.Shell
                $wsh.SendKeys('{NUMLOCK}')
            }
            $ResultText.text = " Disable NumLock after startup. `r`n Ready for Next Task!"
        })

        Function Uninstall-WinUtilEdgeBrowser {

            <#
        
            .SYNOPSIS
                This will uninstall edge by changing the region to Ireland and uninstalling edge the changing it back
        
            #>
        
        $msedgeProcess = Get-Process -Name "msedge" -ErrorAction SilentlyContinue
        $widgetsProcess = Get-Process -Name "widgets" -ErrorAction SilentlyContinue
        # Checking if Microsoft Edge is running
        if ($msedgeProcess) {
            Stop-Process -Name "msedge" -Force
        } else {
            Write-Output "msedge process is not running."
        }
        # Checking if Widgets is running
        if ($widgetsProcess) {
            Stop-Process -Name "widgets" -Force
        } else {
            Write-Output "widgets process is not running."
        }
        
        function Uninstall-Process {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Key
            )
        
            $originalNation = [microsoft.win32.registry]::GetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', [Microsoft.Win32.RegistryValueKind]::String)
        
            # Set Nation to 84 (France) temporarily
            [microsoft.win32.registry]::SetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', 68, [Microsoft.Win32.RegistryValueKind]::String) | Out-Null
        
            # credits to he3als for the Acl commands
            $fileName = "IntegratedServicesRegionPolicySet.json"
            $pathISRPS = [Environment]::SystemDirectory + "\" + $fileName
            $aclISRPS = Get-Acl -Path $pathISRPS
            $aclISRPSBackup = [System.Security.AccessControl.FileSecurity]::new()
            $aclISRPSBackup.SetSecurityDescriptorSddlForm($acl.Sddl)
            if (Test-Path -Path $pathISRPS) {
                try {
                    $admin = [System.Security.Principal.NTAccount]$(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value
        
                    $aclISRPS.SetOwner($admin)
                    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($admin, 'FullControl', 'Allow')
                    $aclISRPS.AddAccessRule($rule)
                    Set-Acl -Path $pathISRPS -AclObject $aclISRPS
        
                    Rename-Item -Path $pathISRPS -NewName ($fileName + '.bak') -Force
                }
                catch {
                    Write-Error "[$Mode] Failed to set owner for $pathISRPS"
                }
            }
        
            $baseKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
            $registryPath = $baseKey + '\ClientState\' + $Key
        
            if (!(Test-Path -Path $registryPath)) {
                Write-Host "[$Mode] Registry key not found: $registryPath"
                return
            }
        
            Remove-ItemProperty -Path $registryPath -Name "experiment_control_labels" -ErrorAction SilentlyContinue | Out-Null
        
            $uninstallString = (Get-ItemProperty -Path $registryPath).UninstallString
            $uninstallArguments = (Get-ItemProperty -Path $registryPath).UninstallArguments
        
            if ([string]::IsNullOrEmpty($uninstallString) -or [string]::IsNullOrEmpty($uninstallArguments)) {
                Write-Host "[$Mode] Cannot find uninstall methods for $Mode"
                return
            }
        
            $uninstallArguments += " --force-uninstall --delete-profile"
        
            # $uninstallCommand = "`"$uninstallString`"" + $uninstallArguments
            if (!(Test-Path -Path $uninstallString)) {
                Write-Host "[$Mode] setup.exe not found at: $uninstallString"
                return
            }
            Start-Process -FilePath $uninstallString -ArgumentList $uninstallArguments -Wait -NoNewWindow -Verbose
        
            # Restore Acl
            if (Test-Path -Path ($pathISRPS + '.bak')) {
                Rename-Item -Path ($pathISRPS + '.bak') -NewName $fileName -Force
                Set-Acl -Path $pathISRPS -AclObject $aclISRPSBackup
            }
        
            # Restore Nation
            [microsoft.win32.registry]::SetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', $originalNation, [Microsoft.Win32.RegistryValueKind]::String) | Out-Null
        
            if ((Get-ItemProperty -Path $baseKey).IsEdgeStableUninstalled -eq 1) {
                Write-Host "[$Mode] Edge Stable has been successfully uninstalled"
            }
        }
        
        function Uninstall-Edge {
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null
        
            [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev", "AllowUninstall", 1, [Microsoft.Win32.RegistryValueKind]::DWord) | Out-Null
        
            Uninstall-Process -Key '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
        
            @( "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
               "$env:PUBLIC\Desktop",
               "$env:USERPROFILE\Desktop" ) | ForEach-Object {
                $shortcutPath = Join-Path -Path $_ -ChildPath "Microsoft Edge.lnk"
                if (Test-Path -Path $shortcutPath) {
                    Remove-Item -Path $shortcutPath -Force
                }
            }
        
        }
        
        function Uninstall-WebView {
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null
        
            # Force to use system-wide WebView2
            # [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder", "*", "%%SystemRoot%%\System32\Microsoft-Edge-WebView")
        
            Uninstall-Process -Key '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
        }
        
        function Uninstall-EdgeUpdate {
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null
        
            $registryPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
            if (!(Test-Path -Path $registryPath)) {
                Write-Host "Registry key not found: $registryPath"
                return
            }
            $uninstallCmdLine = (Get-ItemProperty -Path $registryPath).UninstallCmdLine
        
            if ([string]::IsNullOrEmpty($uninstallCmdLine)) {
                Write-Host "Cannot find uninstall methods for $Mode"
                return
            }
        
            Write-Output "Uninstalling: $uninstallCmdLine"
            Start-Process cmd.exe "/c $uninstallCmdLine" -WindowStyle Hidden -Wait
        }
        
        Uninstall-Edge
            # "WebView" { Uninstall-WebView }
            # "EdgeUpdate" { Uninstall-EdgeUpdate }
        
        
        
        
        }

    $killedge.Add_Click({
        if(Test-Path "$env:programdata\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk") {
            $Form.text = "WinTool by Alerion - Removing Microsoft Edge..."
            $ResultText.text = " Removing Microsoft Edge..."

            Uninstall-WinUtilEdgeBrowser

            #removes shortcut from programdata
            Get-ChildItem "C:\ProgramData\Microsoft\Windows\Start Menu\Programs" -Recurse  -Filter *Edge*.lnk |
            ForEach-Object {
                Remove-Item $_.FullName
            }

            $ResultText.text = " Microsoft Edge was removed completly and all shortcuts accosiated with it too. `r`n Ready for Next Task!"
            $Form.text = "WinTool by Alerion"
        } 
        else {
            choco install microsoft-edge -y --force
            $ResultText.text = " Microsoft Edge has been restored successfully. `r`n Ready for Next Task!"
        }
            
        })

    $ncpa.Add_Click({ #Network cards interface
            $ResultText.text = " Opened Network Connections..."
            cmd /c ncpa.cpl
        })

    $oldsoundpanel.Add_Click({ #Old sound control panel
            $ResultText.text = " Opened Sound Properties..."
            cmd /c mmsys.cpl
        })

    $oldcontrolpanel.Add_Click({ #Old controlpanel
            $ResultText.text = " Opened Control Panel..."
            cmd /c control
        })

    $oldsystempanel.Add_Click({ #Old system panel
            $ResultText.text = " Opened System Properties..."
            cmd /c sysdm.cpl
        })

    $oldpower.Add_Click({
            $ResultText.text = " Opened Advanced Power Options..."
            cmd /c powercfg.cpl
        })

    $olddevicemanager.Add_Click({
            $ResultText.text = " Opened Device Manager..."
            cmd /c devmgmt.msc
        })

    $oldprinters.Add_Click({
            $ResultText.text = " Opened Devices/Printers..."
            cmd /c control printers
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
            $ResultText.text = " NFS is now setup for user based NFS mounts `r`n Ready for Next Task!"
        })

        $resetnetwork.Add_Click({
            # Update UI to indicate the process has started
            $Form.text = "WinTool by Alerion - Resetting Network Settings..."
            $ResultText.text = "Resetting network settings. Please wait..."
        
            # Define commands in a sequence
            $commands = @(
                @{Command = "netsh winsock reset"; Message = "1. Winsock reset!"},
                @{Command = "netsh int ip reset"; Message = "2. IP reset!"},
                @{Command = "netsh advfirewall reset"; Message = "3. Firewall reset!"},
                @{Command = "ipconfig /release"; Message = "4. IP released!"},
                @{Command = "ipconfig /flushdns"; Message = "5. DNS flushed!"},
                @{Command = "ipconfig /renew"; Message = "6. IP renewed!"}
            )
        
            # Execute each command and update UI
            foreach ($cmd in $commands) {
                try {
                    cmd.exe /c $cmd.Command
                    $ResultText.text = $cmd.Message
                    Start-Sleep -Seconds 1
                } catch {
                    $ResultText.text = "Error: Unable to execute command: $($cmd.Command)"
                    Start-Sleep -Seconds 1
                }
            }
        
            # Finalize
            $ResultText.text = "Network settings restored to default. Please reboot your computer."
            $Form.text = "WinTool by Alerion - Network reset complete. Reboot required."
        })

        $windowsupdatefix.Add_Click({
            $Form.text = "WinTool by Alerion - Initializing Windows Update Fix..."
            $ResultText.text = "Starting Windows Update repair process..."
        
            # Step 1: Stop Windows Update Services
            $ResultText.text = "1. Stopping Windows Update services..."
            foreach ($service in @("BITS", "wuauserv", "appidsvc", "cryptsvc")) {
                Stop-Service -Name $service -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 1
        
            # Step 2: Remove QMGR Data Files
            $ResultText.text = "2. Removing QMGR Data files..."
            Remove-Item "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        
            # Step 3: Rename Software Distribution and CatRoot2 Folder
            $ResultText.text = "3. Renaming SoftwareDistribution and CatRoot2 folders..."
            foreach ($folder in @("SoftwareDistribution", "System32\Catroot2")) {
                Rename-Item -Path "$env:SystemRoot\$folder" -NewName "$folder.bak" -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 1
        
            # Step 4: Remove Old Windows Update Log
            $ResultText.text = "4. Removing old Windows Update log..."
            Remove-Item "$env:SystemRoot\WindowsUpdate.log" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        
            # Step 5: Reset Windows Update Services
            $ResultText.text = "5. Resetting Windows Update services to default settings..."
            cmd.exe /c 'sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)' | Out-Null
            cmd.exe /c 'sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)' | Out-Null
            Set-Location "$env:SystemRoot\System32"
            Start-Sleep -Seconds 1
        
            # Step 6: Register DLLs
            $ResultText.text = "6. Registering DLLs..."
            $dlls = @(
                "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll",
                "jscript.dll", "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll", 
                "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", "dssenh.dll",
                "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll",
                "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll", "wuapi.dll",
                "wuaueng.dll", "wuaueng1.dll", "wucltui.dll", "wups.dll", "wups2.dll",
                "wuweb.dll", "qmgr.dll", "qmgrprxy.dll", "wucltux.dll", "muweb.dll", "wuwebv.dll"
            )
            foreach ($dll in $dlls) {
                regsvr32.exe /s $dll
            }
            Start-Sleep -Seconds 1
        
            # Step 7: Remove WSUS Client Settings
            $ResultText.text = "7. Removing WSUS client settings..."
            foreach ($regKey in @("AccountDomainSid", "PingID", "SusClientId")) {
                REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v $regKey /f | Out-Null
            }
            Start-Sleep -Seconds 1
        
            # Step 8: Reset WinSock and HTTP Proxy
            $ResultText.text = "8. Resetting WinSock and HTTP proxy..."
            netsh winsock reset | Out-Null
            netsh winhttp reset proxy | Out-Null
            Start-Sleep -Seconds 1
        
            # Step 9: Delete All BITS Jobs
            $ResultText.text = "9. Deleting all BITS jobs..."
            Get-BitsTransfer | Remove-BitsTransfer -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        
            # Step 10: Attempt to Install the Windows Update Agent
            $ResultText.text = "10. Attempting to install the Windows Update Agent..."
            if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
                Start-Process "wusa.exe" -ArgumentList "Windows8-RT-KB2937636-x64.msu /quiet" -NoNewWindow -Wait
            } else {
                Start-Process "wusa.exe" -ArgumentList "Windows8-RT-KB2937636-x86.msu /quiet" -NoNewWindow -Wait
            }
            Start-Sleep -Seconds 1
        
            # Step 11: Start Windows Update Services
            $ResultText.text = "11. Starting Windows Update services..."
            foreach ($service in @("BITS", "wuauserv", "appidsvc", "cryptsvc")) {
                Start-Service -Name $service -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 1
        
            # Step 12: Force Discovery
            $ResultText.text = "12. Forcing update discovery..."
            cmd.exe /c 'wuauclt /resetauthorization /detectnow' | Out-Null
            Start-Sleep -Seconds 1
        
            # Completion Message
            $ResultText.text = "Windows Update has been repaired. Please reboot your computer."
            $Form.text = "WinTool by Alerion - Windows Update repaired. Reboot required."
        })

        $remhibernation.Add_Click({
            $ResultText.text = "Disabling Hibernation file completely..."
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabledDefault" -Value 0
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Value 0
            cmd.exe /c 'powercfg -h off'
            $ResultText.text = "Hibernation file removed! `r`n Ready for Next Task!"
        })

        $remhibernationbutfastboot.Add_Click({
            $ResultText.text = "Reducing Hibernation file but keeping fastboot..."
            cmd.exe /c 'powercfg hibernate size 0'
            $ResultText.text = "Resized hiberfil.sys to allow for fastboot..."
            cmd.exe /c 'powercfg /h /type reduced'
            $ResultText.text = "Hibernation file reduced! `r`n Ready for Next Task!"
        })

        $restorehibernation.Add_Click({
            $ResultText.text = "Restoring Hibernation feature..."
            cmd.exe /c 'powercfg /h /type full'
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabledDefault" -Value 1
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Value 1
            $ResultText.text = "Hibernation file restored, please reboot! `r`n Ready for Next Task!"
        })

        $ClearRAMcache.Add_Click({
            # Define Desktop Path
            $pathDesktop = [Environment]::GetFolderPath("Desktop")
            
            # Download the icon file if it doesn't already exist
            $iconPath = 'C:\Windows\heart.ico'
            $url = "https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/Files/heart.ico"
            if (-not (Test-Path $iconPath)) {
                try {
                    Invoke-WebRequest -Uri $url -OutFile $iconPath -ErrorAction SilentlyContinue
                } catch {
                    $ResultText.text = "Failed to download heart.ico file: $_"
                    return
                }
            }
        
            # Check if Desktop path is valid
            if (Test-Path $pathDesktop) {
                try {
                    # Clean up memory
                    [System.GC]::Collect()
                    [System.GC]::WaitForPendingFinalizers()
        
                    # Kill unnecessary processes
                    $unnecessaryProcesses = @("chrome", "edge")
                    foreach ($process in $unnecessaryProcesses) {
                        Get-Process $process -ErrorAction SilentlyContinue | Stop-Process -Force
                    }
        
                    # Run idle tasks cleanup
                    rundll32.exe advapi32.dll,ProcessIdleTasks
        
                    # Clear console (if required for the UI)
                    Clear-Host
        
                    # Create the Clear RAM Cache shortcut on the Desktop
                    $WshShell = New-Object -ComObject WScript.Shell
                    $Shortcut = $WshShell.CreateShortcut("$pathDesktop\Clear RAM Cache.lnk")
                    $Shortcut.IconLocation = $iconPath
                    $Shortcut.TargetPath = "$env:windir\system32\rundll32.exe"
                    $Shortcut.Arguments = "advapi32.dll,ProcessIdleTasks"
                    $Shortcut.WorkingDirectory = "$env:windir\System32"
                    $Shortcut.Save()
        
                    $ResultText.text = "Clear RAM Cache shortcut created successfully on Desktop."
                } catch {
                    $ResultText.text = "Error occurred while creating the shortcut: $_"
                }
            } else {
                $ResultText.text = "Failed to create shortcut. Desktop path is invalid or not found!"
            }
        })
        

        $SystemInfo.Add_Click({
            $OSname = (Get-WmiObject Win32_OperatingSystem).caption
            $OSbit = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
            $OSver = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
            $localIP = (Get-NetIPAddress | Where-Object{ $_.AddressFamily -eq "IPv4" -and !($_.IPAddress -match "169") -and !($_.IPAddress -match "127") }).IPAddress -join ', '
            $externalIP = (Invoke-WebRequest -uri "https://api.ipify.org/").Content
            $winLicence = (Get-WmiObject -query "select * from SoftwareLicensingService").OA3xOriginalProductKey
            $accountUsername = (Get-ChildItem Env:USERNAME).Value
            $domainName = (Get-WmiObject win32_computersystem).Domain
            $computerName = $env:computername


        
            $ResultText.text =
                "Username: "        + $accountUsername + "`r`n `r`n" + 
                "Computer Name: "   + $computerName + "`r`n `r`n" + 
                "Domain: "          + $domainName + "`r`n `r`n" + 
                "Local IP: "        + $localIP + "`r`n `r`n" + 
                "External IP: "     + $externalIP + "`r`n `r`n" + 
                "Windows Licence: " + $winLicence + "`r`n `r`n" + 
                "OS: "              + $OSname + "`r`n `r`n" + 
                "OS Build: "        + $OSver + "`r`n `r`n" +   
                "CPU Architecture: "+ $OSbit + "`r`n"
        })

        $HardwareInfo.Add_Click({

            $manufacturer = Get-WmiObject -Class Win32_ComputerSystem -Namespace "root\CIMV2"
            $bios = Get-WmiObject -Class Win32_BIOS -Namespace "root\CIMV2"
            $GPU = Get-WmiObject -Class Win32_VideoController -Filter "AdapterCompatibility != 'DisplayLink'" #AdapterDACType = Internal can also be used but need to verify that this works with external GPUs too first    
            $cpuInfo = Get-WmiObject -Class Win32_Processor -ComputerName. | Select-Object -Property [a-z]*

            $computerBrand = $manufacturer.Manufacturer
            $model           = $manufacturer.Model
            $cpuName = $cpuInfo.Name
            $cores   = $cpuInfo[0].NumberOfLogicalProcessors
            $GPUname = $GPU.Name
            $GPUdescription = $GPU.VideoProcessor
            $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" |
            Select-Object Size,FreeSpace
            $TotMem          = "$([string]([System.Math]::Round($manufacturer.TotalPhysicalMemory/1gb,2))) GB"
            $biosName        = $bios.Manufacturer
            $biosDesc        = $bios.Description
            $biosSerial      = $bios.SerialNumber
             

            $ResultText.text =
                "Manufacturer: "            + $computerBrand + "`r`n" + 
                "Model: "                   + $model + "`r`n" + 
                "Serial Number: "           + $biosSerial + "`r`n `r`n" + 
                "CPU: "                     + $cpuName + "`r`n" + 
                "CPU Cores: "               + $cores + "`r`n `r`n" +
                "GPU Name: "                + $GPUname + "`r`n" + 
                "GPU Description: "         + $GPUdescription + "`r`n `r`n" + 

                "Total RAM: "               + $TotMem + "`r`n `r`n" + 
                "OS Disk Size: "            + [Math]::Round($Disk.Size / 1GB) + " GB `r`n" +  
                "OS Disk Free Space: "      + [Math]::Round($Disk.Freespace / 1GB) + " GB `r`n `r`n" +
                "Bios: "                    + $biosName + "`r`n" +
                "Bios Description: "        + $biosDesc + "`r`n"
                
    
        })
    
        $antivirusInfo.Add_Click({
            $ResultText.text = "Detecting antivirus programs..."
        
            # Detect Malwarebytes specifically
            if (Test-Path "C:\Program Files\Malwarebytes\Anti-Malware\mbam.exe") {
                $id = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Malwarebytes" -ErrorAction SilentlyContinue).id
        
                $ResultText.text = "Malwarebytes is installed and active! You should have the best protection there is!" + 
                                   " `r`nApplication ID: $id"
            } else {
                # Detect using WMI (Windows Management Instrumentation)
                $AntiVirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue
        
                if ($AntiVirusProducts) {
                    foreach ($AntiVirusProduct in $AntiVirusProducts) {
                        # Map product states to human-readable statuses
                        switch ($AntiVirusProduct.productState) {
                            "262144" {$defstatus = "Up to date"; $rtstatus = "Disabled"}
                            "262160" {$defstatus = "Out of date"; $rtstatus = "Disabled"}
                            "266240" {$defstatus = "Up to date"; $rtstatus = "Enabled"}
                            "266256" {$defstatus = "Out of date"; $rtstatus = "Enabled"}
                            "393216" {$defstatus = "Up to date"; $rtstatus = "Disabled"}
                            "393232" {$defstatus = "Out of date"; $rtstatus = "Disabled"}
                            "397312" {$defstatus = "Up to date"; $rtstatus = "Enabled"}
                            "397328" {$defstatus = "Out of date"; $rtstatus = "Enabled"}
                            default {$defstatus = "Unknown"; $rtstatus = "Unknown"}
                        }
        
                        $ResultText.text = 
                        "Detected Antivirus Product:" + "`r`n" +
                        "Name: " + $AntiVirusProduct.displayName + "`r`n" + 
                        "Product GUID: " + $AntiVirusProduct.instanceGuid + "`r`n" +
                        "Product Executable: " + $AntiVirusProduct.pathToSignedProductExe + "`r`n" +
                        "Reporting Exe: " + $AntiVirusProduct.pathToSignedReportingExe + "`r`n" +
                        "Definition Status: " + $defstatus + "`r`n" +
                        "Real-time Protection Status: " + $rtstatus + "`r`n"
                    }
                } else {
                    # Additional checks for common antivirus programs via file paths and services
                    $knownAVs = @(
                        @{Name="Windows Defender"; Path="C:\Program Files\Windows Defender\MsMpEng.exe"},
                        @{Name="Norton Antivirus"; Path="C:\Program Files\Norton Security\Engine"},
                        @{Name="McAfee Antivirus"; Path="C:\Program Files\Common Files\McAfee"},
                        @{Name="Kaspersky"; Path="C:\Program Files (x86)\Kaspersky Lab"},
                        @{Name="Avast Antivirus"; Path="C:\Program Files\Avast Software\Avast"},
                        @{Name="AVG Antivirus"; Path="C:\Program Files\AVG\Antivirus"},
                        @{Name="Bitdefender"; Path="C:\Program Files\Bitdefender Antivirus"},
                        @{Name="ESET NOD32"; Path="C:\Program Files\ESET\ESET Security"},
                        @{Name="Sophos"; Path="C:\Program Files\Sophos\Sophos Anti-Virus"},
                        @{Name="Trend Micro"; Path="C:\Program Files\Trend Micro"}
                    )
        
                    $avFound = $false
                    foreach ($av in $knownAVs) {
                        if (Test-Path $av.Path) {
                            $ResultText.text = "Antivirus Detected: " + $av.Name + "`r`nLocation: " + $av.Path
                            $avFound = $true
                            break
                        }
                    }
        
                    # Default message if no antivirus was found
                    if (-not $avFound) {
                        $ResultText.text = "No antivirus programs were detected on this system."
                    }
                }
            }
        })        

        $godmode.Add_Click({
            If (!(Test-Path "$pathDesktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}")) { 
                New-Item -Path "$pathDesktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -ItemType Directory | Out-Null
                $ResultText.text = "Godmode shortcut has been sucessfully created and can be found at: $Home\Desktop"
            }
            else {
                $ResultText.text = "Failed to create GodMode shortcut it might already exist, please try again!"
            }
        })

        $xButton.Add_Click({
            $form.Close()
        })

        $createShortcutTool.Add_Click({
            # Define paths and icon URL
            $iconPath = 'C:\Windows\heart.ico'
            $url = "https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/Files/heart.ico"
            if (-not (Test-Path $iconPath)) {
                Invoke-WebRequest -Uri $url -OutFile $iconPath -ErrorAction SilentlyContinue
            }
        
            $WshShell = New-Object -comObject WScript.Shell # Needed for creating shortcuts
        
            # Define potential OneDrive installation paths
            $oneDrivePaths = @(
                "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
                "C:\Program Files\Microsoft OneDrive\OneDrive.exe",
                "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe"
            )
        
            # Check if OneDrive is installed
            $oneDriveInstalled = $oneDrivePaths | Where-Object { Test-Path $_ }
        
            # Determine shortcut location
            if ($oneDriveInstalled) {
                # Detect OneDrive Desktop folder dynamically
                $oneDriveFolder = Get-ChildItem -Path "$env:USERPROFILE" -Directory |
                    Where-Object { $_.Name -like "OneDrive*" } |
                    Select-Object -ExpandProperty FullName -First 1
        
                $pathDesktop = Join-Path -Path $oneDriveFolder -ChildPath "Desktop"
            } else {
                # Default to standard desktop
                $pathDesktop = [Environment]::GetFolderPath("Desktop")
            }
        
            # Define the shortcut path
            $shortcutPath = Join-Path -Path $pathDesktop -ChildPath "WinTool.lnk"
        
            # Check if the shortcut already exists
            if (!(Test-Path $shortcutPath)) {
                # Create the shortcut
                $Shortcut = $WshShell.CreateShortcut($shortcutPath)
                $Shortcut.IconLocation = $iconPath # Set the icon to heart.ico
                $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                $Shortcut.WorkingDirectory = "C:\Windows\System32\WindowsPowerShell\v1.0\"
                $Shortcut.Arguments = "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/WinTool.ps1'))"
                $Shortcut.Save()
        
                # Ensure the shortcut starts with administrative privileges
                $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
                $bytes[0x15] = $bytes[0x15] -bor 0x20 # Set byte 21 (0x15) bit 6 (0x20) ON
                [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
        
                $ResultText.text = "WinTool shortcut has been created and can be found at: $shortcutPath"
            } else {
                $ResultText.text = "Failed to create WinTool shortcut. It might already exist. Please try again!"
            }
        })

$createShortcutGit.Add_Click({
    # Define potential OneDrive installation paths
    $oneDrivePaths = @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "C:\Program Files\Microsoft OneDrive\OneDrive.exe",
        "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe"
    )

    # Check if OneDrive is installed
    $oneDriveInstalled = $oneDrivePaths | Where-Object { Test-Path $_ }

    # Determine the desktop path
    if ($oneDriveInstalled) {
        # Detect OneDrive Desktop folder dynamically
        $oneDriveFolder = Get-ChildItem -Path "$env:USERPROFILE" -Directory |
            Where-Object { $_.Name -like "OneDrive*" } |
            Select-Object -ExpandProperty FullName -First 1

        $pathDesktop = Join-Path -Path $oneDriveFolder -ChildPath "Desktop"
    } else {
        # Default to standard desktop
        $pathDesktop = [Environment]::GetFolderPath("Desktop")
    }

    # Define the icon path and URL
    $iconPath = 'C:\Windows\heart.ico'
    $url = "https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/Files/heart.ico"

    # Download the icon file if it doesn't already exist
    if (-not (Test-Path $iconPath)) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $iconPath -ErrorAction SilentlyContinue
        } catch {
            $ResultText.text = "Failed to download heart.ico file: $_"
            return
        }
    }

    # Check if the .URL shortcut already exists
    $shortcutPath = Join-Path -Path $pathDesktop -ChildPath "Alerion921's Github.URL"
    if (!(Test-Path $shortcutPath)) {
        try {
            # Create the URL shortcut
            $shortcutContent = @"
[InternetShortcut]
URL=https://github.com/alerion921/WinTool-for-Win11
IconFile=$iconPath
IconIndex=0
"@
            Set-Content -Path $shortcutPath -Value $shortcutContent -Force -ErrorAction SilentlyContinue

            $ResultText.text = "Github - WinTool URL shortcut has been created and can be found at: $pathDesktop"
        } catch {
            $ResultText.text = "Error occurred while creating the URL shortcut: $_"
        }
    } else {
        $ResultText.text = "Failed to create Github - WinTool URL shortcut. It might already exist. Please try again!"
    }
})
        
        $supportWintool.Add_Click({
            Start-Process 'https://paypal.me/KLuneborg'
        })

    $Form.ShowDialog()
}
MakeForm