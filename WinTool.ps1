# Import the ShowWindow function from user32.dll to manipulate the PowerShell window state.
# This allows us to hide the PowerShell console window.
$HidePowershellWindow = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'

# Add the ShowWindow method to the PowerShell runtime as a .NET class.
add-type -name win -member $HidePowershellWindow -namespace native

# Retrieve the current process's main window handle and hide it (state = 0).
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

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
$pathDocuments      = [Environment]::GetFolderPath("MyDocuments")           # Path to the Documents folder
#$pathPictures       = [Environment]::GetFolderPath("MyPictures")            # Path to the Pictures folder
#$pathAppdataLocal   = [Environment]::GetFolderPath("LocalApplicationData")  # Path to the local AppData folder
#$pathAppdataRoaming = [Environment]::GetFolderPath("ApplicationData")       # Path to the roaming AppData folder
#$pathWindows        = [Environment]::GetFolderPath("Windows")               # Path to the Windows folder
#$pathSystem         = [Environment]::GetFolderPath("System")                # Path to the System folder (e.g., System32)
####################################################################################

function EnsureChocolatey {
    # Create Progress Form for feedback
    $ProgressForm = New-Object System.Windows.Forms.Form
    $ProgressForm.Text = "Processing..."
    $ProgressForm.Size = New-Object System.Drawing.Size(400, 100)
    $ProgressForm.StartPosition = "CenterScreen"

    $ProgressLabel = New-Object System.Windows.Forms.Label
    $ProgressLabel.AutoSize = $true
    $ProgressLabel.Location = New-Object System.Drawing.Point(10, 10)
    $ProgressLabel.Text = "Initializing..."
    $ProgressForm.Controls.Add($ProgressLabel)

    # Show the form
    $ProgressForm.Show()

    # Function to update progress label text safely
    function UpdateProgress {
        param (
            [string]$Message
        )
        # Ensure the update occurs on the UI thread
        $ProgressLabel.Invoke([Action]{ 
            $ProgressLabel.Text = $Message
            $ProgressLabel.Refresh()
        })
    }

    # Check if Chocolatey is installed
    if (!(Test-Path "C:\ProgramData\chocolatey\choco.exe")) {
        [System.Windows.Forms.MessageBox]::Show(
            "Chocolatey is not installed. Installing now...", 
            "Installing Chocolatey", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        # Install Chocolatey
        try {
            UpdateProgress -Message "Installing Chocolatey..."
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Error installing Chocolatey: $_", 
                "Error", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            $ProgressForm.Close()
            return $false
        }
    }

    # Update Chocolatey to ensure it's up to date
    try {
        UpdateProgress -Message "Updating Chocolatey..."
        Start-Process -FilePath "choco" -ArgumentList "upgrade chocolatey -y" -NoNewWindow -Wait
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error updating Chocolatey: $_", 
            "Error", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        $ProgressForm.Close()
        return $false
    }

    # Close the Progress Form after completion
    UpdateProgress -Message "Chocolatey installation and update complete."
    Start-Sleep -Seconds 2
    $ProgressForm.Close()
    return $true
}

function ShowAppSelectionForm {
    # Define the application selection form
    $appSelectionForm = New-Object System.Windows.Forms.Form
    $appSelectionForm.Text = "Select Applications"
    $appSelectionForm.StartPosition = "CenterScreen"
    $appSelectionForm.Size = New-Object System.Drawing.Size(400, 600)

    # Define the application list
    $applications = @(
        @{ Name = "Brave Browser"; Path = "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"; Chocolatey = "brave" },
        @{ Name = "Dropbox"; Path = "C:\Program Files (x86)\Dropbox\Client\Dropbox.exe"; Chocolatey = "dropbox" },
        @{ Name = "7-Zip"; Path = "C:\Program Files\7-Zip\7z.exe"; Chocolatey = "7zip" },
        @{ Name = "Malwarebytes"; Path = "C:\Program Files\Malwarebytes\Anti-Malware\mbam.exe"; Chocolatey = "malwarebytes" },
        @{ Name = "Steam"; Path = "C:\Program Files (x86)\Steam\steam.exe"; Chocolatey = "steam" },
        @{ Name = "Discord"; Path = "$env:APPDATA\Local\Discord\update.exe"; Chocolatey = "discord" },
        @{ Name = "Visual Studio Code"; Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Code.exe"; Chocolatey = "vscode" }
    )

    # Dynamically add checkboxes for applications
    $yPosition = 20
    $checkboxes = @()  # To store checkbox references

    foreach ($app in $applications) {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Text = $app.Name
        $checkbox.Location = New-Object System.Drawing.Point(20, $yPosition)
        $checkbox.Width = 350
        $appSelectionForm.Controls.Add($checkbox)
        $checkboxes += $checkbox
        $app.Checkbox = $checkbox  # Store checkbox reference for later processing
        $yPosition += 30
    }

    # Adjust form height dynamically based on the number of checkboxes
    $appSelectionForm.Size = New-Object System.Drawing.Size(400, $yPosition + 100)

    # Add OK Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Location = New-Object System.Drawing.Point(50, $yPosition)
    $okButton.Add_Click({
        $selectedApps = $applications | Where-Object { $_.Checkbox.Checked }
        $appSelectionForm.Hide() # Hide the form temporarily
        InstallOrUninstallApplications -SelectedApps $selectedApps

        # After task completion, show the form again
        $appSelectionForm.ShowDialog()
    })
    $appSelectionForm.Controls.Add($okButton)

    # Add Reset Button
    $resetButton = New-Object System.Windows.Forms.Button
    $resetButton.Text = "Reset"
    $resetButton.Size = New-Object System.Drawing.Size(100, 30)
    $resetButton.Location = New-Object System.Drawing.Point(150, $yPosition)
    $resetButton.Add_Click({
        foreach ($checkbox in $checkboxes) {
            $checkbox.Checked = $false
        }
    })
    $appSelectionForm.Controls.Add($resetButton)

    # Add Cancel Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Location = New-Object System.Drawing.Point(250, $yPosition)
    $cancelButton.Add_Click({
        $appSelectionForm.Close()
    })
    $appSelectionForm.Controls.Add($cancelButton)

    # Show the form
    [void]$appSelectionForm.ShowDialog()
}

function InstallOrUninstallApplications {
    param (
        [array]$SelectedApps
    )

    # Ensure Chocolatey is available
    if (-not (EnsureChocolatey)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Chocolatey is not available. Aborting process.", 
            "Error", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }

    # Create progress form
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = "Processing Applications"
    $progressForm.Size = New-Object System.Drawing.Size(400, 150)
    $progressForm.StartPosition = "CenterScreen"

    $progressLabel = New-Object System.Windows.Forms.Label
    $progressLabel.AutoSize = $true
    $progressLabel.Location = New-Object System.Drawing.Point(10, 10)
    $progressLabel.Text = "Starting..."
    $progressForm.Controls.Add($progressLabel)

    $progressForm.Show()

    # Update progress safely
    function UpdateProgress {
        param ([string]$Message)
        $progressLabel.Invoke([Action]{
            $progressLabel.Text = $Message
            $progressLabel.Refresh()
        })
    }

    # Helper function to check if an app is installed
    function IsAppInstalled {
        param ([string]$AppName, [string]$AppPath)

        # Check using Chocolatey
        $installedPackages = choco list --local-only | Select-String -Pattern "^\s*$AppName\s+"
        if ($installedPackages) {
            return $true
        }

        # Check file path as fallback
        if ($AppPath -and (Test-Path $AppPath)) {
            return $true
        }

        return $false
    }

    $isCancelled = $false  # Track if the user cancels the operation

    # Process each application
    foreach ($app in $SelectedApps) {
        $isInstalled = IsAppInstalled -AppName $app.Chocolatey -AppPath $app.Path

        if ($isInstalled) {
            # Application already installed, prompt for uninstallation
            $uninstallPrompt = [System.Windows.Forms.MessageBox]::Show(
                "$($app.Name) is already installed. Do you want to uninstall it?", 
                "Uninstall $($app.Name)?", 
                [System.Windows.Forms.MessageBoxButtons]::YesNo, 
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($uninstallPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    UpdateProgress "Uninstalling $($app.Name)..."
                    Start-Process -FilePath "choco" -ArgumentList "uninstall $($app.Chocolatey) -y --force" -NoNewWindow -Wait
                    if (-not (IsAppInstalled -AppName $app.Chocolatey -AppPath $app.Path)) {
                        [System.Windows.Forms.MessageBox]::Show(
                            "$($app.Name) has been uninstalled successfully.", 
                            "Uninstallation Complete", 
                            [System.Windows.Forms.MessageBoxButtons]::OK, 
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                    } else {
                        throw "Uninstallation failed for $($app.Name)."
                    }
                } catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Error uninstalling $($app.Name): $_", 
                        "Error", 
                        [System.Windows.Forms.MessageBoxButtons]::OK, 
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            } else {
                # User cancelled uninstallation
                UpdateProgress "Exiting..."
                $isCancelled = $true
                break
            }
        } else {
            # Prompt before installation
            $installPrompt = [System.Windows.Forms.MessageBox]::Show(
                "Do you want to install $($app.Name)?", 
                "Install $($app.Name)?", 
                [System.Windows.Forms.MessageBoxButtons]::YesNo, 
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($installPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    UpdateProgress "Installing $($app.Name)..."

                    # Start Chocolatey installation
                    $chocoProcess = Start-Process -FilePath "choco" -ArgumentList "install $($app.Chocolatey) -y --force" -NoNewWindow -Wait -PassThru

                    # Check Chocolatey process exit code
                    if ($chocoProcess.ExitCode -eq 0 -and (IsAppInstalled -AppName $app.Chocolatey -AppPath $app.Path)) {
                        [System.Windows.Forms.MessageBox]::Show(
                            "$($app.Name) has been installed successfully.", 
                            "Installation Complete", 
                            [System.Windows.Forms.MessageBoxButtons]::OK, 
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                    } else {
                        throw "Installation failed for $($app.Name)."
                    }
                } catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Error installing $($app.Name): $_", 
                        "Error", 
                        [System.Windows.Forms.MessageBoxButtons]::OK, 
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            } else {
                # User cancelled installation
                UpdateProgress "Exiting..."
                $isCancelled = $true
                break
            }
        }
    }

    if (-not $isCancelled) {
        UpdateProgress "All tasks completed."
        Start-Sleep -Seconds 2
    }

    $progressForm.Invoke([Action]{ $progressForm.Close() })

    # Return control to the application selection form
    ShowAppSelectionForm
}

Function MakeForm {
    if ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme") -eq '0') {
        $frontcolor = [System.Drawing.ColorTranslator]::FromHtml("#182C36")
        $backcolor = [System.Drawing.ColorTranslator]::FromHtml("#5095B5")
        $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#346075")
    }
    elseif ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme") -eq '1') {
        $frontcolor = [System.Drawing.ColorTranslator]::FromHtml("#C40E61")
        $backcolor = [System.Drawing.ColorTranslator]::FromHtml("#FFE082")
        $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#F8BBD0")
    }

    if ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme") -eq '0') {
        $frontcolor = [System.Drawing.ColorTranslator]::FromHtml("#182C36")
        $backcolor = [System.Drawing.ColorTranslator]::FromHtml("#5095B5")
        $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#346075")
    }
    elseif ((Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme") -eq '1') {
        $frontcolor = [System.Drawing.ColorTranslator]::FromHtml("#C40E61")
        $backcolor = [System.Drawing.ColorTranslator]::FromHtml("#FFE082")
        $hovercolor = [System.Drawing.ColorTranslator]::FromHtml("#F8BBD0")
    }

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

    $xButton = New-Object system.Windows.Forms.Button
    $xButton.text = "X"
    $xButton.width = 25
    $xButton.height = 25
    $xButton.location = New-Object System.Drawing.Point(1125, 10)
    $xButton.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $xButton.BackColor = $frontcolor 
    $xButton.ForeColor = $backcolor
    $xButton.FlatStyle = "Flat"
    $xbutton.BorderStyle = 0
    $xButton.FlatAppearance.MouseOverBackColor = $hovercolor
    $xButton.TabStop = $false

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

    $Panel1 = New-Object system.Windows.Forms.Panel
    $Panel1.height = 440
    $Panel1.width = 220
    $Panel1.location = New-Object System.Drawing.Point(10, 100)

    $Panel2 = New-Object system.Windows.Forms.Panel
    $Panel2.height = 440
    $Panel2.width = 220
    $Panel2.location = New-Object System.Drawing.Point(240, 100)

    $Panel3 = New-Object system.Windows.Forms.Panel
    $Panel3.height = 440
    $Panel3.width = 220
    $Panel3.location = New-Object System.Drawing.Point(470, 100)

    $Panel4 = New-Object system.Windows.Forms.Panel
    $Panel4.height = 440
    $Panel4.width = 230
    $Panel4.location = New-Object System.Drawing.Point(700, 100)

    $Panel5 = New-Object system.Windows.Forms.Panel
    $Panel5.height = 440
    $Panel5.width = 230
    $Panel5.location = New-Object System.Drawing.Point(930, 100)

    $Panel6 = New-Object system.Windows.Forms.Panel
    $Panel6.height = 330
    $Panel6.width = 1140
    $Panel6.location = New-Object System.Drawing.Point(10, 540)

    #######################################################################################################
    # Tweaks starts here
    #######################################################################################################

    $performancetweaks = New-Object system.Windows.Forms.Label
    $performancetweaks.text = "Performance Tweaks"
    $performancetweaks.AutoSize = $false
    $performancetweaks.width = 220
    $performancetweaks.height = 35
    $performancetweaks.TextAlign = "MiddleCenter"
    $performancetweaks.location = New-Object System.Drawing.Point(0, 10)
    $performancetweaks.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
    $performancetweaks.ForeColor = $frontcolor 

    $essentialtweaks = New-Object system.Windows.Forms.Button
    $essentialtweaks.text = "Essential Tweaks"
    $essentialtweaks.width = 220
    $essentialtweaks.height = 65
    $essentialtweaks.location = New-Object System.Drawing.Point(0, 45)
    $essentialtweaks.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $essentialtweaks.BackColor = $frontcolor 
    $essentialtweaks.ForeColor = $backcolor
    $essentialtweaks.FlatStyle = "Flat"
    $essentialtweaks.FlatAppearance.MouseOverBackColor = $hovercolor

    $essentialundo = New-Object system.Windows.Forms.Button
    $essentialundo.text = "Undo Essential Tweaks"
    $essentialundo.width = 220
    $essentialundo.height = 65
    $essentialundo.location = New-Object System.Drawing.Point(0, 115)
    $essentialundo.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $essentialundo.BackColor = $frontcolor 
    $essentialundo.ForeColor = $backcolor
    $essentialundo.FlatStyle = "Flat"
    $essentialundo.FlatAppearance.MouseOverBackColor = $hovercolor

    $gamingtweaks = New-Object system.Windows.Forms.Button
    $gamingtweaks.text = "Gaming Tweaks"
    $gamingtweaks.width = 220
    $gamingtweaks.height = 65
    $gamingtweaks.location = New-Object System.Drawing.Point(0, 185)
    $gamingtweaks.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $gamingtweaks.BackColor = $frontcolor 
    $gamingtweaks.ForeColor = $backcolor
    $gamingtweaks.FlatStyle = "Flat"
    $gamingtweaks.FlatAppearance.MouseOverBackColor = $hovercolor

    $securitypatches = New-Object system.Windows.Forms.Button
    $securitypatches.text = "Patch Security (Caution!)"
    $securitypatches.width = 220
    $securitypatches.height = 65
    $securitypatches.location = New-Object System.Drawing.Point(0, 255)
    $securitypatches.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $securitypatches.BackColor = $frontcolor 
    $securitypatches.ForeColor = $backcolor
    $securitypatches.FlatStyle = "Flat"
    $securitypatches.FlatAppearance.MouseOverBackColor = $hovercolor

    if((Test-Path "$env:programdata\Microsoft OneDrive") -or (Test-Path "C:\Program Files (x86)\Microsoft OneDrive") -or (Test-Path "C:\Program Files\Microsoft OneDrive")) {
        $onedrive = New-Object system.Windows.Forms.Button
        $onedrive.text = "Remove OneDrive"
        $onedrive.width = 220
        $onedrive.height = 30
        $onedrive.location = New-Object System.Drawing.Point(0, 325)
        $onedrive.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
        $onedrive.BackColor = $frontcolor 
        $onedrive.ForeColor = $backcolor
        $onedrive.FlatStyle = "Flat"
        $onedrive.FlatAppearance.MouseOverBackColor = $hovercolor
    }
    else {
        $onedrive = New-Object system.Windows.Forms.Button
        $onedrive.text = "Restore OneDrive"
        $onedrive.width = 220
        $onedrive.height = 30
        $onedrive.location = New-Object System.Drawing.Point(0, 325)
        $onedrive.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
        $onedrive.BackColor = $frontcolor 
        $onedrive.ForeColor = $backcolor
        $onedrive.FlatStyle = "Flat"
        $onedrive.FlatAppearance.MouseOverBackColor = $hovercolor 
    }

    if(Test-Path "$env:programdata\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk") {
        $killedge = New-Object system.Windows.Forms.Button
        $killedge.text = "Remove Microsoft Edge"
        $killedge.width = 220
        $killedge.height = 30
        $killedge.location = New-Object System.Drawing.Point(0, 360)
        $killedge.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
        $killedge.BackColor = $frontcolor 
        $killedge.ForeColor = $backcolor
        $killedge.FlatStyle = "Flat"
        $killedge.FlatAppearance.MouseOverBackColor = $hovercolor
    }
    else {
        $killedge = New-Object system.Windows.Forms.Button
        $killedge.text = "Restore Microsoft Edge"
        $killedge.width = 220
        $killedge.height = 30
        $killedge.location = New-Object System.Drawing.Point(0, 360)
        $killedge.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
        $killedge.BackColor = $frontcolor 
        $killedge.ForeColor = $backcolor
        $killedge.FlatStyle = "Flat"
        $killedge.FlatAppearance.MouseOverBackColor = $hovercolor
    }

    if(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}") {    
        $removehomegallery = New-Object system.Windows.Forms.Button
        $removehomegallery.text = "Remove Home and Gallery"
        $removehomegallery.width = 220
        $removehomegallery.height = 30
        $removehomegallery.location = New-Object System.Drawing.Point(0, 395)
        $removehomegallery.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
        $removehomegallery.BackColor = $frontcolor 
        $removehomegallery.ForeColor = $backcolor
        $removehomegallery.FlatStyle = "Flat"
        $removehomegallery.FlatAppearance.MouseOverBackColor = $hovercolor
    }
    else {    
        $removehomegallery = New-Object system.Windows.Forms.Button
        $removehomegallery.text = "Restore Home and Gallery"
        $removehomegallery.width = 220
        $removehomegallery.height = 30
        $removehomegallery.location = New-Object System.Drawing.Point(0, 395)
        $removehomegallery.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
        $removehomegallery.BackColor = $frontcolor 
        $removehomegallery.ForeColor = $backcolor
        $removehomegallery.FlatStyle = "Flat"
        $removehomegallery.FlatAppearance.MouseOverBackColor = $hovercolor
    }

    #######################################################################################################
    # Tweaks ends here
    #######################################################################################################
    # Fixes starts here
    #######################################################################################################

    $fixes = New-Object system.Windows.Forms.Label
    $fixes.text = "Fixes"
    $fixes.AutoSize = $false
    $fixes.width = 220
    $fixes.height = 35
    $fixes.TextAlign = "MiddleCenter"
    $fixes.location = New-Object System.Drawing.Point(0, 10)
    $fixes.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
    $fixes.ForeColor = $frontcolor 

    $errorscanner = New-Object system.Windows.Forms.Button
    $errorscanner.text = "Error Scanner"
    $errorscanner.width = 220
    $errorscanner.height = 30
    $errorscanner.location = New-Object System.Drawing.Point(0, 45)
    $errorscanner.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $errorscanner.BackColor = $frontcolor 
    $errorscanner.ForeColor = $backcolor
    $errorscanner.FlatStyle = "Flat"
    $errorscanner.FlatAppearance.MouseOverBackColor = $hovercolor

    $changedns = New-Object system.Windows.Forms.ComboBox
    $changedns.text = ""
    $changedns.width = 220
    $changedns.height = 30
    $changedns.autosize = $true



    @('          Change DNS Here', 
      '               Google DNS', 
      '            Cloudflare DNS', 
      '               Level3 DNS', 
      '                 OpenDNS', 
      '         Restore Default DNS'
      ) | ForEach-Object { [void] $changedns.Items.Add($_) }

    $changedns.SelectedIndex = 0   # Select the default value
    $changedns.location = New-Object System.Drawing.Point(0, 80)
    $changedns.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $changedns.BackColor = $frontcolor 
    $changedns.ForeColor = $backcolor

    $changedns.ReadOnly = $true
    $changedns.SelectionLength = 0;

    $resetnetwork = New-Object system.Windows.Forms.Button
    $resetnetwork.text = "Reset Network"
    $resetnetwork.width = 220
    $resetnetwork.height = 30
    $resetnetwork.location = New-Object System.Drawing.Point(0, 115)
    $resetnetwork.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $resetnetwork.BackColor = $frontcolor 
    $resetnetwork.ForeColor = $backcolor
    $resetnetwork.FlatStyle = "Flat"
    $resetnetwork.FlatAppearance.MouseOverBackColor = $hovercolor

    $forcenorkeyboard = New-Object system.Windows.Forms.Button
    $forcenorkeyboard.text = "Force NO/NB Language"
    $forcenorkeyboard.width = 220
    $forcenorkeyboard.height = 30
    $forcenorkeyboard.location = New-Object System.Drawing.Point(0, 150)
    $forcenorkeyboard.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $forcenorkeyboard.BackColor = $frontcolor 
    $forcenorkeyboard.ForeColor = $backcolor
    $forcenorkeyboard.FlatStyle = "Flat"
    $forcenorkeyboard.FlatAppearance.MouseOverBackColor = $hovercolor

    $dualboottime = New-Object system.Windows.Forms.Button
    $dualboottime.text = "Set Time to UTC"
    $dualboottime.width = 220
    $dualboottime.height = 30
    $dualboottime.location = New-Object System.Drawing.Point(0, 185)
    $dualboottime.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $dualboottime.BackColor = $frontcolor 
    $dualboottime.ForeColor = $backcolor
    $dualboottime.FlatStyle = "Flat"
    $dualboottime.FlatAppearance.MouseOverBackColor = $hovercolor

    #######################################################################################################
    # Fixes ends here
    #######################################################################################################
    # Old menus starts here
    #######################################################################################################

    $oldmenu = New-Object system.Windows.Forms.Label
    $oldmenu.text = "Classic Menus"
    $oldmenu.AutoSize = $false
    $oldmenu.width = 220
    $oldmenu.height = 35
    $oldmenu.TextAlign = "MiddleCenter"
    $oldmenu.location = New-Object System.Drawing.Point(0, 220)
    $oldmenu.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
    $oldmenu.ForeColor = $frontcolor 

    $ncpa = New-Object system.Windows.Forms.Button
    $ncpa.text = "Network Panel"
    $ncpa.width = 220
    $ncpa.height = 30
    $ncpa.location = New-Object System.Drawing.Point(0, 255)
    $ncpa.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $ncpa.BackColor = $frontcolor 
    $ncpa.ForeColor = $backcolor
    $ncpa.FlatStyle = "Flat"
    $ncpa.FlatAppearance.MouseOverBackColor = $hovercolor

    $oldcontrolpanel = New-Object system.Windows.Forms.Button
    $oldcontrolpanel.text = "Control Panel"
    $oldcontrolpanel.width = 220
    $oldcontrolpanel.height = 30
    $oldcontrolpanel.location = New-Object System.Drawing.Point(0, 290)
    $oldcontrolpanel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $oldcontrolpanel.BackColor = $frontcolor 
    $oldcontrolpanel.ForeColor = $backcolor
    $oldcontrolpanel.FlatStyle = "Flat"
    $oldcontrolpanel.FlatAppearance.MouseOverBackColor = $hovercolor

    $oldsoundpanel = New-Object system.Windows.Forms.Button
    $oldsoundpanel.text = "Sound Panel"
    $oldsoundpanel.width = 220
    $oldsoundpanel.height = 30
    $oldsoundpanel.location = New-Object System.Drawing.Point(0, 325)
    $oldsoundpanel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $oldsoundpanel.BackColor = $frontcolor 
    $oldsoundpanel.ForeColor = $backcolor
    $oldsoundpanel.FlatStyle = "Flat"
    $oldsoundpanel.FlatAppearance.MouseOverBackColor = $hovercolor

    $oldsystempanel = New-Object system.Windows.Forms.Button
    $oldsystempanel.text = "System Panel"
    $oldsystempanel.width = 220
    $oldsystempanel.height = 30
    $oldsystempanel.location = New-Object System.Drawing.Point(0, 360)
    $oldsystempanel.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $oldsystempanel.BackColor = $frontcolor 
    $oldsystempanel.ForeColor = $backcolor
    $oldsystempanel.FlatStyle = "Flat"
    $oldsystempanel.FlatAppearance.MouseOverBackColor = $hovercolor

    $oldpower = New-Object system.Windows.Forms.Button
    $oldpower.text = "Power Panel"
    $oldpower.width = 220
    $oldpower.height = 30
    $oldpower.location = New-Object System.Drawing.Point(0, 395)
    $oldpower.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $oldpower.BackColor = $frontcolor 
    $oldpower.ForeColor = $backcolor
    $oldpower.FlatStyle = "Flat"
    $oldpower.FlatAppearance.MouseOverBackColor = $hovercolor

    #######################################################################################################
    # Old menus ends here
    #######################################################################################################
    # Windows update starts here
    #######################################################################################################

    $windowsupdate = New-Object system.Windows.Forms.Label
    $windowsupdate.text = "Windows Update"
    $windowsupdate.AutoSize = $false
    $windowsupdate.width = 220
    $windowsupdate.height = 35
    $windowsupdate.TextAlign = "MiddleCenter"
    $windowsupdate.location = New-Object System.Drawing.Point(0, 10)
    $windowsupdate.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
    $windowsupdate.ForeColor = $frontcolor 

    $defaultwindowsupdate = New-Object system.Windows.Forms.Button
    $defaultwindowsupdate.text = "Default Settings"
    $defaultwindowsupdate.width = 220
    $defaultwindowsupdate.height = 30
    $defaultwindowsupdate.location = New-Object System.Drawing.Point(0, 45)
    $defaultwindowsupdate.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $defaultwindowsupdate.BackColor = $frontcolor 
    $defaultwindowsupdate.ForeColor = $backcolor
    $defaultwindowsupdate.FlatStyle = "Flat"
    $defaultwindowsupdate.FlatAppearance.MouseOverBackColor = $hovercolor

    $securitywindowsupdate = New-Object system.Windows.Forms.Button
    $securitywindowsupdate.text = "Security Updates Only"
    $securitywindowsupdate.width = 220
    $securitywindowsupdate.height = 30
    $securitywindowsupdate.location = New-Object System.Drawing.Point(0, 80)
    $securitywindowsupdate.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $securitywindowsupdate.BackColor = $frontcolor 
    $securitywindowsupdate.ForeColor = $backcolor
    $securitywindowsupdate.FlatStyle = "Flat"
    $securitywindowsupdate.FlatAppearance.MouseOverBackColor = $hovercolor

    $windowsupdatefix = New-Object system.Windows.Forms.Button
    $windowsupdatefix.text = "Windows Update Reset"
    $windowsupdatefix.width = 220
    $windowsupdatefix.height = 30
    $windowsupdatefix.location = New-Object System.Drawing.Point(0, 115)
    $windowsupdatefix.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $windowsupdatefix.BackColor = $frontcolor 
    $windowsupdatefix.ForeColor = $backcolor
    $windowsupdatefix.FlatStyle = "Flat"
    $windowsupdatefix.FlatAppearance.MouseOverBackColor = $hovercolor

    #######################################################################################################
    # Windows update ends here
    #######################################################################################################
    # Microsoft store starts here
    #######################################################################################################

    $microsoftstore = New-Object system.Windows.Forms.Label
    $microsoftstore.text = "Microsoft Store"
    $microsoftstore.AutoSize = $false
    $microsoftstore.width = 220
    $microsoftstore.height = 35
    $microsoftstore.TextAlign = "MiddleCenter"
    $microsoftstore.ForeColor = $frontcolor 
    $microsoftstore.location = New-Object System.Drawing.Point(0, 150)
    $microsoftstore.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $removebloat = New-Object system.Windows.Forms.Button
    $removebloat.text = "Remove MS Store Apps"
    $removebloat.width = 220
    $removebloat.height = 30
    $removebloat.location = New-Object System.Drawing.Point(0, 185)
    $removebloat.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $removebloat.BackColor = $frontcolor 
    $removebloat.ForeColor = $backcolor
    $removebloat.FlatStyle = "Flat"
    $removebloat.FlatAppearance.MouseOverBackColor = $hovercolor

    $reinstallbloat = New-Object system.Windows.Forms.Button
    $reinstallbloat.text = "Reinstall MS Store Apps"
    $reinstallbloat.width = 220
    $reinstallbloat.height = 30
    $reinstallbloat.location = New-Object System.Drawing.Point(0, 220)
    $reinstallbloat.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $reinstallbloat.BackColor = $frontcolor 
    $reinstallbloat.ForeColor = $backcolor
    $reinstallbloat.FlatStyle = "Flat"
    $reinstallbloat.FlatAppearance.MouseOverBackColor = $hovercolor

    #######################################################################################################
    # Microsoft store ends here
    #######################################################################################################
    # Cleaning starts here
    #######################################################################################################

    $cleaning = New-Object system.Windows.Forms.Label
    $cleaning.text = "Cleaning"
    $cleaning.AutoSize = $false
    $cleaning.width = 220
    $cleaning.height = 35
    $cleaning.TextAlign = "MiddleCenter"
    $cleaning.ForeColor = $frontcolor 
    $cleaning.location = New-Object System.Drawing.Point(0, 255)
    $cleaning.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $ultimateclean = New-Object system.Windows.Forms.Button
    $ultimateclean.text = "Ultimate Cleaning"
    $ultimateclean.width = 220
    $ultimateclean.height = 30
    $ultimateclean.location = New-Object System.Drawing.Point(0, 290)
    $ultimateclean.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $ultimateclean.BackColor = $frontcolor 
    $ultimateclean.ForeColor = $backcolor
    $ultimateclean.FlatStyle = "Flat"
    $ultimateclean.FlatAppearance.MouseOverBackColor = $hovercolor

    #######################################################################################################
    # Cleaning ends here
    #######################################################################################################
    # Visual Tweaks starts here
    #######################################################################################################

    $visualtweaks = New-Object system.Windows.Forms.Label
    $visualtweaks.text = "Visual Tweaks"
    $visualtweaks.AutoSize = $false
    $visualtweaks.width = 220
    $visualtweaks.height = 35
    $visualtweaks.TextAlign = "MiddleCenter"
    $visualtweaks.ForeColor = $frontcolor 
    $visualtweaks.location = New-Object System.Drawing.Point(0, 325)
    $visualtweaks.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

    $darkmode = New-Object system.Windows.Forms.Button
    $darkmode.text = "Dark Mode"
    $darkmode.width = 220
    $darkmode.height = 30
    $darkmode.location = New-Object System.Drawing.Point(0, 360)
    $darkmode.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $darkmode.BackColor = $frontcolor 
    $darkmode.ForeColor = $backcolor
    $darkmode.FlatStyle = "Flat"
    $darkmode.FlatAppearance.MouseOverBackColor = $hovercolor

    $lightmode = New-Object system.Windows.Forms.Button
    $lightmode.text = "Light Mode"
    $lightmode.width = 220
    $lightmode.height = 30
    $lightmode.location = New-Object System.Drawing.Point(0, 395)
    $lightmode.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $lightmode.BackColor = $frontcolor 
    $lightmode.ForeColor = $backcolor
    $lightmode.FlatStyle = "Flat"
    $lightmode.FlatAppearance.MouseOverBackColor = $hovercolor

    #######################################################################################################
    # Visual Tweaks ends here
    #######################################################################################################
    # Install Apps starts here
    #######################################################################################################

    $extras = New-Object system.Windows.Forms.Label
    $extras.text = "Install Apps"
    $extras.AutoSize = $false
    $extras.width = 220
    $extras.height = 35
    $extras.TextAlign = "MiddleCenter"
    $extras.location = New-Object System.Drawing.Point(0, 10)
    $extras.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
    $extras.ForeColor = $frontcolor 

    $bravebrowser = New-Object system.Windows.Forms.CheckBox
    $bravebrowser.text = "Brave Browser"
    $bravebrowser.width = 220
    $bravebrowser.location = New-Object System.Drawing.Point(0, 40)
    $bravebrowser.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $dropbox = New-Object system.Windows.Forms.CheckBox
    $dropbox.text = "Dropbox"
    $dropbox.width = 220
    $dropbox.location = New-Object System.Drawing.Point(0, 60)
    $dropbox.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $7zip = New-Object system.Windows.Forms.CheckBox
    $7zip.text = "7-Zip"
    $7zip.width = 220
    $7zip.location = New-Object System.Drawing.Point(0, 80)
    $7zip.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $malwarebytes = New-Object system.Windows.Forms.CheckBox
    $malwarebytes.text = "Malwarebytes"
    $malwarebytes.width = 220
    $malwarebytes.location = New-Object System.Drawing.Point(0, 100)
    $malwarebytes.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $steam = New-Object system.Windows.Forms.CheckBox
    $steam.text = "Steam Client"
    $steam.width = 220
    $steam.location = New-Object System.Drawing.Point(0, 120)
    $steam.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $discord = New-Object system.Windows.Forms.CheckBox
    $discord.text = "Discord"
    $discord.width = 220
    $discord.location = New-Object System.Drawing.Point(0, 140)
    $discord.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $teamviewer = New-Object system.Windows.Forms.CheckBox
    $teamviewer.text = "Teamviewer"
    $teamviewer.width = 220
    $teamviewer.location = New-Object System.Drawing.Point(0, 160)
    $teamviewer.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $epicgames = New-Object system.Windows.Forms.CheckBox
    $epicgames.text = "Epic Games Launcher"
    $epicgames.width = 220
    $epicgames.location = New-Object System.Drawing.Point(0, 180)
    $epicgames.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $githubdesktop = New-Object system.Windows.Forms.CheckBox
    $githubdesktop.text = "Github Desktop"
    $githubdesktop.width = 220
    $githubdesktop.location = New-Object System.Drawing.Point(0, 200)
    $githubdesktop.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $visualstudiocode = New-Object system.Windows.Forms.CheckBox
    $visualstudiocode.text = "Visual Studio Code"
    $visualstudiocode.width = 220
    $visualstudiocode.location = New-Object System.Drawing.Point(0, 220)
    $visualstudiocode.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $qbittorrent = New-Object System.Windows.Forms.CheckBox
    $qbittorrent.text = "qBittorrent"
    $qbittorrent.width = 220
    $qbittorrent.location = New-Object System.Drawing.Point(0, 240)
    $qbittorrent.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $notepad = New-Object System.Windows.Forms.CheckBox
    $notepad.text = "Notepad++"
    $notepad.width = 220
    $notepad.location = New-Object System.Drawing.Point(0, 260)
    $notepad.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $foxit = New-Object System.Windows.Forms.CheckBox
    $foxit.text = "Foxit PDF Reader"
    $foxit.width = 220
    $foxit.location = New-Object System.Drawing.Point(0, 280)
    $foxit.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $spotify = New-Object System.Windows.Forms.CheckBox
    $spotify.text = "Spotify"
    $spotify.width = 220
    $spotify.location = New-Object System.Drawing.Point(0, 300)
    $spotify.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $ds4windows = New-Object System.Windows.Forms.CheckBox
    $ds4windows.text = "DS4Windows"
    $ds4windows.width = 220
    $ds4windows.location = New-Object System.Drawing.Point(0, 320)
    $ds4windows.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $bakkes = New-Object System.Windows.Forms.CheckBox
    $bakkes.text = "Bakkesmod"
    $bakkes.width = 220
    $bakkes.location = New-Object System.Drawing.Point(0, 340)
    $bakkes.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

    $updatebutton = New-Object system.Windows.Forms.Button
    $updatebutton.text = "Update Apps"
    $updatebutton.width = 220
    $updatebutton.height = 30
    $updatebutton.location = New-Object System.Drawing.Point(0, 360)
    $updatebutton.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $updatebutton.BackColor = $frontcolor 
    $updatebutton.ForeColor = $backcolor
    $updatebutton.FlatStyle = "Flat"
    $updatebutton.FlatAppearance.MouseOverBackColor = $hovercolor

    $okbutton = New-Object system.Windows.Forms.Button
    $okbutton.text = "Install"
    $okbutton.width = 105
    $okbutton.height = 30
    $okbutton.location = New-Object System.Drawing.Point(0, 395)
    $okbutton.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $okbutton.BackColor = $frontcolor 
    $okbutton.ForeColor = $backcolor
    $okbutton.FlatStyle = "Flat"
    $okbutton.FlatAppearance.MouseOverBackColor = $hovercolor

    $resetbutton = New-Object system.Windows.Forms.Button
    $resetbutton.text = "Reset"
    $resetbutton.width = 105
    $resetbutton.height = 30
    $resetbutton.location = New-Object System.Drawing.Point(115, 395)
    $resetbutton.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $resetbutton.BackColor = $frontcolor 
    $resetbutton.ForeColor = $backcolor
    $resetbutton.FlatStyle = "Flat"
    $resetbutton.FlatAppearance.MouseOverBackColor = $hovercolor

    #######################################################################################################
    # Install Apps ends here
    #######################################################################################################
    # Result box starts here
    #######################################################################################################

    $ResultTextWrapper = New-Object system.Windows.Forms.TextBox
    $ResultTextWrapper.multiline = $true
    $ResultTextWrapper.ReadOnly = $true
    $ResultTextWrapper.AutoSize = $true
    $ResultTextWrapper.width = 1140
    $ResultTextWrapper.height = 320
    $ResultTextWrapper.location = New-Object System.Drawing.Point(0, 0)
    $ResultTextWrapper.BorderStyle = "FixedSingle"
    $ResultTextWrapper.BackColor = $backcolor 
    $ResultTextWrapper.ForeColor = $frontcolor 

    $ResultText = New-Object system.Windows.Forms.TextBox
    $ResultText.multiline = $true
    $ResultText.ReadOnly = $true
    $ResultText.AutoSize = $true
    $ResultText.width = 1110 #This needs to patch the padding so substract if needed
    $ResultText.height = 300 #This needs to patch the padding so substract if needed
    $ResultText.location = New-Object System.Drawing.Point(10, 10) #Padding is defined here
    $ResultText.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)
    $ResultText.BorderStyle = 0
    $ResultText.BackColor = $backcolor 
    $ResultText.ForeColor = $frontcolor 

    #######################################################################################################
    # Result box ends here
    #######################################################################################################
    # placeholder starts here
    #######################################################################################################

    $Mischeader = New-Object system.Windows.Forms.Label
    $Mischeader.text = "System Information"
    $Mischeader.AutoSize = $false
    $Mischeader.width = 220
    $Mischeader.height = 35
    $Mischeader.TextAlign = "MiddleCenter"
    $Mischeader.location = New-Object System.Drawing.Point(0, 10)
    $Mischeader.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
    $Mischeader.ForeColor = $frontcolor 

    $ClearRAMcache = New-Object system.Windows.Forms.Button
    $ClearRAMcache.text = "RAM Cache Shortcut"
    $ClearRAMcache.width = 220
    $ClearRAMcache.height = 30
    $ClearRAMcache.location = New-Object System.Drawing.Point(0, 45)
    $ClearRAMcache.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $ClearRAMcache.BackColor = $frontcolor 
    $ClearRAMcache.ForeColor = $backcolor
    $ClearRAMcache.FlatStyle = "Flat"
    $ClearRAMcache.FlatAppearance.MouseOverBackColor = $hovercolor

    $godmode = New-Object system.Windows.Forms.Button
    $godmode.text = "Godmode Shortcut"
    $godmode.width = 220
    $godmode.height = 30
    $godmode.location = New-Object System.Drawing.Point(0, 80)
    $godmode.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $godmode.BackColor = $frontcolor 
    $godmode.ForeColor = $backcolor
    $godmode.FlatStyle = "Flat"
    $godmode.FlatAppearance.MouseOverBackColor = $hovercolor

    $HardwareInfo = New-Object system.Windows.Forms.Button
    $HardwareInfo.text = "Hardware Info"
    $HardwareInfo.width = 220
    $HardwareInfo.height = 30
    $HardwareInfo.location = New-Object System.Drawing.Point(0, 115)
    $HardwareInfo.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $HardwareInfo.BackColor = $frontcolor 
    $HardwareInfo.ForeColor = $backcolor
    $HardwareInfo.FlatStyle = "Flat"
    $HardwareInfo.FlatAppearance.MouseOverBackColor = $hovercolor

    $antivirusInfo = New-Object system.Windows.Forms.Button
    $antivirusInfo.text = "Anti-Virus Status"
    $antivirusInfo.width = 220
    $antivirusInfo.height = 30
    $antivirusInfo.location = New-Object System.Drawing.Point(0, 150)
    $antivirusInfo.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $antivirusInfo.BackColor = $frontcolor 
    $antivirusInfo.ForeColor = $backcolor
    $antivirusInfo.FlatStyle = "Flat"
    $antivirusInfo.FlatAppearance.MouseOverBackColor = $hovercolor


    $SystemInfo = New-Object system.Windows.Forms.Button
    $SystemInfo.text = "System Info"
    $SystemInfo.width = 220
    $SystemInfo.height = 30
    $SystemInfo.location = New-Object System.Drawing.Point(0, 185)
    $SystemInfo.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $SystemInfo.BackColor = $frontcolor 
    $SystemInfo.ForeColor = $backcolor
    $SystemInfo.FlatStyle = "Flat"
    $SystemInfo.FlatAppearance.MouseOverBackColor = $hovercolor

    $placeholder7 = New-Object system.Windows.Forms.Label
    $placeholder7.text = "Placeholder Header"
    $placeholder7.AutoSize = $false
    $placeholder7.width = 220
    $placeholder7.height = 35
    $placeholder7.TextAlign = "MiddleCenter"
    $placeholder7.location = New-Object System.Drawing.Point(0, 220)
    $placeholder7.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
    $placeholder7.ForeColor = $frontcolor 

    $placeholder8 = New-Object system.Windows.Forms.Button
    $placeholder8.text = "Placeholder"
    $placeholder8.width = 220
    $placeholder8.height = 30
    $placeholder8.location = New-Object System.Drawing.Point(0, 255)
    $placeholder8.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $placeholder8.BackColor = $frontcolor 
    $placeholder8.ForeColor = $backcolor
    $placeholder8.FlatStyle = "Flat"
    $placeholder8.FlatAppearance.MouseOverBackColor = $hovercolor

    $placeholder9 = New-Object system.Windows.Forms.Button
    $placeholder9.text = "Placeholder"
    $placeholder9.width = 220
    $placeholder9.height = 30
    $placeholder9.location = New-Object System.Drawing.Point(0, 290)
    $placeholder9.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $placeholder9.BackColor = $frontcolor 
    $placeholder9.ForeColor = $backcolor
    $placeholder9.FlatStyle = "Flat"
    $placeholder9.FlatAppearance.MouseOverBackColor = $hovercolor

    $placeholder10 = New-Object system.Windows.Forms.Button
    $placeholder10.text = "Placeholder"
    $placeholder10.width = 220
    $placeholder10.height = 30
    $placeholder10.location = New-Object System.Drawing.Point(0, 325)
    $placeholder10.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $placeholder10.BackColor = $frontcolor 
    $placeholder10.ForeColor = $backcolor
    $placeholder10.FlatStyle = "Flat"
    $placeholder10.FlatAppearance.MouseOverBackColor = $hovercolor

    $selectAppsButton  = New-Object system.Windows.Forms.Button
    $selectAppsButton.text = "Install Applications"
    $selectAppsButton.width = 220
    $selectAppsButton.height = 30
    $selectAppsButton.location = New-Object System.Drawing.Point(0, 360)
    $selectAppsButton.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $selectAppsButton.BackColor = $frontcolor 
    $selectAppsButton.ForeColor = $backcolor
    $selectAppsButton.FlatStyle = "Flat"
    $selectAppsButton.FlatAppearance.MouseOverBackColor = $hovercolor

    # Button to Open Customization Form
    $btnOpenCustomization = New-Object system.Windows.Forms.Button
    $btnOpenCustomization.text = "Customize About Info"
    $btnOpenCustomization.width = 220
    $btnOpenCustomization.height = 30
    $btnOpenCustomization.location = New-Object System.Drawing.Point(0, 395)
    $btnOpenCustomization.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)
    $btnOpenCustomization.BackColor = $frontcolor 
    $btnOpenCustomization.ForeColor = $backcolor
    $btnOpenCustomization.FlatStyle = "Flat"
    $btnOpenCustomization.FlatAppearance.MouseOverBackColor = $hovercolor

    #######################################################################################################
    # Placeholder ends here
    #######################################################################################################

    $Form.controls.AddRange(@(
            $xButton,
            $createShortcutGit,
            $CreateShortcutTool,
            $wintoollogo,
            $supportWintool,
            $Panel1, 
            $Panel2, 
            $Panel3, 
            $Panel4, 
            $Panel5,
            $Panel6
        ))

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
            $visualtweaks, #header for the section below
            $darkmode,
            $lightmode
        ))

    $Panel4.controls.AddRange(@(
            $extras, #header for the section below
            $bravebrowser,
            $dropbox,
            $7zip,
            $malwarebytes,
            $teamviewer,
            $steam,
            $discord,
            $epicgames, 
            $githubdesktop,
            $visualstudiocode,
            $qbittorrent,
            $updatebutton,
            $okbutton,
            $resetbutton,
            $notepad,
            $foxit,
            $spotify,
            $ds4windows,
            $bakkes
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

    $Panel6.controls.AddRange(@(
            $ResultText,
            $ResultTextWrapper
        ))

    #Check if Chocolatey is installed
    if (Test-Path "$env:ProgramData\Chocolatey") {
         $ResultText.text = 
        "Welcome to the WinTool by Alerion, this is a powerfull tool so make sure you read the instructions on GitHub before you get going. 
        `r`n  List of things that are required in order for this to run smoothly:
        --->  Chocolatey App Automation - Already installed!
        --->  Administrator Elevation - (This script should do this automaticly, but first time an elevated promt is needed)
        --->  Windows 10 or Windows 11 - All builds are supported!
                    
          Enjoy this free tool!
        "
    }  
    else {
        $ResultText.text = 
       "Welcome to the WinTool by Alerion, this is a powerfull tool so make sure you read the instructions on GitHub before you get going. 
       `r`n  List of things that are required in order for this to run smoothly:
       --->  Chocolatey App Automation - Will install automaticly upon choosing an app to install!
       --->  Administrator Elevation - (This script should do this automaticly, but first time an elevated promt is needed)
       --->  Windows 10 or Windows 11 - All builds are supported!
                   
         Enjoy this free tool!
       "
   }  


   $selectAppsButton.Add_Click({
    # Call the function to show the app selection form
    ShowAppSelectionForm
})

## Customize About this computer, new form that allows the users to customize default Windows properties within the About this computer section.

# Event handler for opening the customization form
$btnOpenCustomization.Add_Click({
    # Secondary Customization Form
    $customForm = New-Object System.Windows.Forms.Form
    $customForm.Text = "Customize About This Computer"
    $customForm.Size = New-Object System.Drawing.Size(500, 400)
    $customForm.StartPosition = "CenterScreen"

    # Label for Manufacturer
    $labelManufacturer = New-Object System.Windows.Forms.Label
    $labelManufacturer.Text = "Manufacturer:"
    $labelManufacturer.Location = New-Object System.Drawing.Point(10, 20)
    $labelManufacturer.Size = New-Object System.Drawing.Size(100, 20)
    $customForm.Controls.Add($labelManufacturer)

    # Textbox for Manufacturer
    $textManufacturer = New-Object System.Windows.Forms.TextBox
    $textManufacturer.Location = New-Object System.Drawing.Point(120, 20)
    $textManufacturer.Size = New-Object System.Drawing.Size(350, 20)
    $customForm.Controls.Add($textManufacturer)

    # Label for Support URL
    $labelSupportURL = New-Object System.Windows.Forms.Label
    $labelSupportURL.Text = "Support URL:"
    $labelSupportURL.Location = New-Object System.Drawing.Point(10, 60)
    $labelSupportURL.Size = New-Object System.Drawing.Size(100, 20)
    $customForm.Controls.Add($labelSupportURL)

    # Textbox for Support URL
    $textSupportURL = New-Object System.Windows.Forms.TextBox
    $textSupportURL.Location = New-Object System.Drawing.Point(120, 60)
    $textSupportURL.Size = New-Object System.Drawing.Size(350, 20)
    $customForm.Controls.Add($textSupportURL)

    # Label for Background Image
    $labelBackground = New-Object System.Windows.Forms.Label
    $labelBackground.Text = "Background Image:"
    $labelBackground.Location = New-Object System.Drawing.Point(10, 100)
    $labelBackground.Size = New-Object System.Drawing.Size(120, 20)
    $customForm.Controls.Add($labelBackground)

    # Textbox to Display Selected Background Image Path
    $textBackgroundPath = New-Object System.Windows.Forms.TextBox
    $textBackgroundPath.Location = New-Object System.Drawing.Point(120, 100)
    $textBackgroundPath.Size = New-Object System.Drawing.Size(250, 20)
    $customForm.Controls.Add($textBackgroundPath)

    # Button to Browse Background Image
    $btnBrowseImage = New-Object System.Windows.Forms.Button
    $btnBrowseImage.Text = "Browse"
    $btnBrowseImage.Location = New-Object System.Drawing.Point(380, 100)
    $btnBrowseImage.Size = New-Object System.Drawing.Size(90, 25)
    $customForm.Controls.Add($btnBrowseImage)

    # Event handler for browsing background image
    $btnBrowseImage.Add_Click({
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.Filter = "Image Files (*.bmp, *.jpg, *.jpeg, *.png)|*.bmp;*.jpg;*.jpeg;*.png"
        If ($fileDialog.ShowDialog() -eq "OK") {
            $textBackgroundPath.Text = $fileDialog.FileName
        }
    })

    # Button to Apply Settings
    $btnApply = New-Object System.Windows.Forms.Button
    $btnApply.Text = "Apply"
    $btnApply.Location = New-Object System.Drawing.Point(120, 150)
    $btnApply.Size = New-Object System.Drawing.Size(100, 30)
    $customForm.Controls.Add($btnApply)

    # Button to Close Customization Form
    $btnCloseCustom = New-Object System.Windows.Forms.Button
    $btnCloseCustom.Text = "Close"
    $btnCloseCustom.Location = New-Object System.Drawing.Point(230, 150)
    $btnCloseCustom.Size = New-Object System.Drawing.Size(100, 30)
    $customForm.Controls.Add($btnCloseCustom)

    # Event handler for Apply button
    $btnApply.Add_Click({
        # Get the values from the textboxes
        $manufacturer = $textManufacturer.Text
        $supportURL = $textSupportURL.Text
        $backgroundPath = $textBackgroundPath.Text

        # Validate and Apply Manufacturer and Support URL
        If (-not [string]::IsNullOrWhiteSpace($manufacturer)) {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "Manufacturer" -Type String -Value $manufacturer
        }
        If (-not [string]::IsNullOrWhiteSpace($supportURL)) {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" -Name "SupportURL" -Type String -Value $supportURL
        }

        # Validate and Set Background Image
        If (-not [string]::IsNullOrWhiteSpace($backgroundPath) -and (Test-Path $backgroundPath)) {
            Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
            [Wallpaper]::SystemParametersInfo(0x0014, 0, $backgroundPath, 0x0001 -bor 0x0002)
        }

        # Show confirmation
        [System.Windows.Forms.MessageBox]::Show("Information updated successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    })

    # Event handler for Close button
    $btnCloseCustom.Add_Click({
        $customForm.Close()
    })

    # Show the Customization Form as a modal dialog
    $customForm.ShowDialog()
})



    ##DNS CHANGER TEST HERE
    $changedns.add_SelectedIndexChanged({
            $selected = $changedns.SelectedIndex

            switch ($selected) {
                1 {
                    $ResultText.text = "DNS set to Google on all network adapters. `r`n Ready for Next Task!"
                    $DNS1 = "8.8.8.8"
                    $DNS2 = "8.8.4.4"
                    $dns = "$DNS1", "$DNS2"
                    $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
                    $Interfaces.SetDNSServerSearchOrder($dns) | Out-Null
                }
                2 {
                    $ResultText.text = "DNS set to Cloudflare on all network adapters. `r`n Ready for Next Task!"
                    $DNS1 = "1.1.1.1"
                    $DNS2 = "1.0.0.1"
                    $dns = "$DNS1", "$DNS2"
                    $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
                    $Interfaces.SetDNSServerSearchOrder($dns) | Out-Null
                }
                3 {
                    $ResultText.text = "DNS set to Level3 on all network adapters. `r`n Ready for Next Task!"
                    $DNS1 = "4.2.2.2"
                    $DNS2 = "4.2.2.1"
                    $dns = "$DNS1", "$DNS2"
                    $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
                    $Interfaces.SetDNSServerSearchOrder($dns) | Out-Null
                }
                4 {
                    $ResultText.text = "DNS set to OpenDNS on all network adapters. `r`n Ready for Next Task!"
                    $DNS1 = "208.67.222.222"
                    $DNS2 = "208.67.220.220"
                    $dns = "$DNS1", "$DNS2"
                    $Interfaces = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
                    $Interfaces.SetDNSServerSearchOrder($dns) | Out-Null
                }
                5 {
                    $ResultText.text = "Not sure why this would be needed since Cloudflare provides the fastest DNS connection..."
                    $regcachclean = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Reset DNS to Windows Default, this will break any VPNs too?" , 4)
                    if ($regcachclean -eq 'Yes') {
                        $Interface = [System.Management.ManagementClass]::new("Win32_NetworkAdapterConfiguration").GetInstances()
                        $interface | Remove-NetRoute -AddressFamily IPv4 -Confirm:$false
                        $interface | Set-NetIPInterface -Dhcp Enabled
                        $interface | Set-DnsClientServerAddress -ResetServerAddresses
                        $ResultText.text = "The Network Adapters has been reset properly. `r`n Ready for Next Task!"
                    }
                }
                default {
                    $ResultText.text = "You need to press an option to change the DNS Address to your liking :)"
                }
            }
        })
    
        $errorscanner.Add_Click({
            $ResultText.text = "System error scan has started, select your options and wait..."
        
            # Load Windows Forms for MessageBox
            [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        
            # Function to initiate system scans
            function Start-SystemScan {
                param (
                    [string]$scanType,
                    [string]$scanCommand
                )
        
                $name = "$scanType - Offload Process"
                $host.ui.RawUI.WindowTitle = $name
        
                try {
                    # Start the scan process
                    Start-Process cmd.exe -ArgumentList "/c $scanCommand" -Wait
                    $ResultText.text = "$scanType scan completed successfully. You may need to restart your system."
                } catch {
                    $ResultText.text = "Error during $scanType scan: $_"
                }
            }
        
            # SFC Scan
            $sfcConfirmation = [System.Windows.Forms.MessageBox]::Show('This may take a while, are you sure?', 'Run SFC Scan now?', [System.Windows.Forms.MessageBoxButtons]::YesNo)
            if ($sfcConfirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
                Start-SystemScan -scanType 'SFC Scannow' -scanCommand 'sfc /scannow'
            }
        
            # DISM Scan
            $dismConfirmation = [System.Windows.Forms.MessageBox]::Show('This may take a while, are you sure?', 'Initiate DISM Scans?', [System.Windows.Forms.MessageBoxButtons]::YesNo)
            if ($dismConfirmation -eq [System.Windows.Forms.DialogResult]::Yes) {
                Start-SystemScan -scanType 'DISM Error Scanner' -scanCommand 'DISM /Online /Cleanup-Image /ScanHealth'
                Start-SystemScan -scanType 'DISM Check Health' -scanCommand 'DISM /Online /Cleanup-Image /CheckHealth'
                Start-SystemScan -scanType 'DISM Restore Health' -scanCommand 'DISM /Online /Cleanup-Image /RestoreHealth'
            }
        
            if ($?) {
                $ResultText.text = "System error scans have been initiated. Please wait for them to complete and then restart your computer."
            }
        })
        


    $ultimateclean.Add_Click({
	
            $ResultText.text = "Cleaning initiated, empty folders will be skipped automaticly..." 

            [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

            $Form.text = "WinTool by Alerion - Initializing Ultimate Cleaning..."

            $ResultText.text = "Creating a restore point named: WinTool-Ultimate-Cleaning-Restorepoint, incase something bad happens.."
            Enable-ComputerRestore -Drive "C:\"
            Checkpoint-Computer -Description "WinTool-Ultimate-Cleaning-Restorepoint" -RestorePointType "MODIFY_SETTINGS"

            $componentcache = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Clean Shadow Copies cache and Windows Store Component cache?" , 4)

            if ($componentcache -eq 'Yes') {
                $ResultText.text = "Windows Store Component cache is being cleaned, please be patient..."
                
                # Delete shadow copies and cleanup component store in one go
                vssadmin delete shadows /all | Out-Null
                cmd /c DISM /Online /Cleanup-Image /AnalyzeComponentStore | Out-Null
                cmd /c DISM /Online /Cleanup-Image /spsuperseded | Out-Null
                cmd /c DISM /Online /Cleanup-Image /StartComponentCleanup | Out-Null
                
                $ResultText.text = "Shadow copies and Windows Store component cache cleaned..."
                
                # Clean unnecessary Windows Store caches efficiently
                $Key = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" | 
                       Where-Object { $_.Name -ne "DownloadsFolder" }
                
                $Form.text = "WinTool by Alerion - Please wait, Ultimate Cleaning in progress..."
                $ResultText.text = "Cleaning unnecessary Windows Store caches..."
            
                # Update registry in bulk without unnecessary looping and checking
                foreach ($result in $Key) {
                    $Regkey = 'HKLM:' + $result.Name.Substring(18)
                    New-ItemProperty -Path $Regkey -Name 'StateFlags0001' -Value 2 -PropertyType DWORD -Force -EA SilentlyContinue | Out-Null
                }
            
                # Clear BCCache if necessary
                Clear-BCCache -Force -ErrorAction SilentlyContinue
            }

            $regcachclean = [System.Windows.Forms.MessageBox]::Show('Are you sure?', "Clean up a collection of useless registry files?", [System.Windows.Forms.MessageBoxButtons]::YesNo)

            if ($regcachclean -eq [System.Windows.Forms.DialogResult]::Yes) {
                # List of registry paths to clean
                $regPaths = @(
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
                
                # Remove registry paths in bulk
                foreach ($path in $regPaths) {
                    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                }
                
                # Stop and restart explorer.exe
                Stop-Process -ProcessName explorer -Force -ErrorAction SilentlyContinue
                taskkill /F /IM explorer.exe
                
                # Wait for a moment before clearing Explorer-related files
                Start-Sleep -Seconds 3
                
                # Clean up local explorer-related files
                $localPaths = @(
                    "$env:LocalAppData\Microsoft\Windows\Explorer",
                    "$env:LocalAppData\Microsoft\Windows\Recent",
                    "$env:LocalAppData\Microsoft\Windows\Recent\AutomaticDestinations",
                    "$env:LocalAppData\Microsoft\Windows\Recent\CustomDestinations"
                )

                foreach ($path in $localPaths) {
                    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                }
                
                # Restart explorer.exe
                Start-Process explorer.exe
                
                # Final delay and message update
                Start-Sleep -Seconds 3
                $ResultText.text = "Windows registry junk files deleted successfully..."
            }

            $Users = Get-ChildItem "$env:systemdrive\Users" | Select-Object Name
            $users = $Users.Name 

            # Clear Inetpub Logs Folder
            if (Test-Path "C:\inetpub\logs\LogFiles\") {
                $ResultText.text = "Clearing Inetpub Logs Folder..." 
                $Folders = Get-ChildItem -Path "C:\inetpub\logs\LogFiles\" | Select-Object Name
                foreach ($Folder in $Folders) {
                    $folder = $Folder.Name
                    Remove-Item -Path "C:\inetpub\logs\LogFiles\$Folder\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                }
                $ResultText.text = "Deleted Inetpub Logs Folder..." 
            }

            if (Test-Path "$env:LocalAppData\Microsoft\Teams\") {
                # Delete Microsoft Teams Previous Version files
                $ResultText.text = "Clearing Microsoft Teams previous versions..." 
                Foreach ($user in $Users) {
                    if (Test-Path "C:\Users\$user\AppData\Local\Microsoft\Teams\") {
                        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Teams\previous\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Teams\stage\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                    } 
                }
                $ResultText.text = "Deleted old Microsoft Teams versions..." 
            }

            if (Test-Path "$env:LocalAppData\TechSmith\SnagIt") {
                # Delete SnagIt Crash Dump files
                $ResultText.text = "Clearing SnagIt crash dumps..." 
                Foreach ($user in $Users) {
                    if (Test-Path "C:\Users\$user\AppData\Local\TechSmith\SnagIt") {
                        Remove-Item -Path "C:\Users\$user\AppData\Local\TechSmith\SnagIt\CrashDumps\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                    } 
                }
        
                $ResultText.text = "Deleted SnagIt crash dumps..." 
            }

            if (Test-Path "C:\Program Files (x86)\Dropbox\Client") {
                $Dropboxclean = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Delete all Dropbox Caches?" , 4)
                if ($Dropboxclean -eq 'Yes') {
                    # Clear Dropbox Cache
                    $ResultText.text = "Clearing Dropbox Cache..." 
                    Foreach ($user in $Users) {
                        if (Test-Path "C:\Users\$user\Dropbox\") {
                            Remove-Item -Path "C:\Users\$user\Dropbox\.dropbox.cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                            Remove-Item -Path "C:\Users\$user\Dropbox*\.dropbox.cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                        }
                    }
                    $ResultText.text = "Dropbox caches deleted..." 
                }
            }
            else {
                Start-Sleep -s 2
                $ResultText.text = "No Dropbox installation can be found.. Skipping clean..." 
            }

            # Clear HP Support Assistant Installation Folder
            if (Test-Path "C:\swsetup") {
                Remove-Item -Path "C:\swsetup" -Force -ErrorAction SilentlyContinue -Verbose
            } 

            $DeleteOldDownloads = [System.Windows.Forms.MessageBox]::Show('Are you sure?' , "Delete User files from Download folder?" , 4)
            # Delete files from Downloads folder
            if ($DeleteOldDownloads -eq 'Yes') { 
                $ResultText.text = "Deleting files from User Download folder..." 
                Foreach ($user in $Users) {
                    $UserDownloads = "C:\Users\$user\Downloads"
                    $OldFiles = Get-ChildItem -Path "$UserDownloads\" -Recurse -File -ErrorAction SilentlyContinue
                    foreach ($file in $OldFiles) {
                        Remove-Item -Path "$UserDownloads\$file" -Force -ErrorAction SilentlyContinue -Verbose
                    }
                }
                Start-Sleep -s 2
                $ResultText.text = "All files in the User Download folder have been deleted..." 
            }

            # Delete files from Azure Log folder
            if (Test-Path "C:\WindowsAzure\Logs") {
                $ResultText.text = "Deleting files from Azure Log folder..." 
                $AzureLogs = "C:\WindowsAzure\Logs"
                $OldFiles = Get-ChildItem -Path "$AzureLogs\" -Recurse -File -ErrorAction SilentlyContinue
                foreach ($file in $OldFiles) {
                    Remove-Item -Path "$AzureLogs\$file" -Force -ErrorAction SilentlyContinue -Verbose
                }
                $ResultText.text = "Azure log files removed..." 
            } 

            if (Test-Path "$env:LocalAppData\Microsoft\Office") {
                # Delete files from Office Cache Folder
                $ResultText.text = "Clearing Office Cache Folder..." 
                Foreach ($user in $Users) {
                    $officecache = "C:\Users\$user\AppData\Local\Microsoft\Office\16.0\GrooveFileCache"
                    if (Test-Path $officecache) {
                        $OldFiles = Get-ChildItem -Path "$officecache\" -Recurse -File -ErrorAction SilentlyContinue
                        foreach ($file in $OldFiles) {
                            Remove-Item -Path "$officecache\$file" -Force -ErrorAction SilentlyContinue -Verbose
                        }
                    } 
                }
                $ResultText.text = "Office cache has been cleared..." 
            }

            # Delete files from LFSAgent Log folder https://www.lepide.com/
            if (Test-Path "$env:windir\LFSAgent\Logs") {
                $ResultText.text = "Deleting files from LFSAgent Log folder..." 
                $LFSAgentLogs = "$env:windir\LFSAgent\Logs"
                $OldFiles = Get-ChildItem -Path "$LFSAgentLogs\" -Recurse -File -ErrorAction SilentlyContinue
                foreach ($file in $OldFiles) {
                    Remove-Item -Path "$LFSAgentLogs\$file" -Force -ErrorAction SilentlyContinue -Verbose
                }
                $ResultText.text = "LFSAgent log folder has been deleted..." 
            }         

            # Delete SOTI MobiController Log files
            if (Test-Path "C:\Program Files (x86)\SOTI\MobiControl") {
                $ResultText.text = "Deleting SOTI MobiController Log files..." 
                $SotiLogFiles = Get-ChildItem -Path "C:\Program Files (x86)\SOTI\MobiControl" | Where-Object { ($_.name -like "*Device*.log" -or $_.name -like "*Server*.log" ) }
                foreach ($File in $SotiLogFiles) {
                    Remove-Item -Path "C:\Program Files (x86)\SOTI\MobiControl\$($file.name)" -Force -ErrorAction SilentlyContinue -Verbose
                }
                $ResultText.text = "SOTI MobiController log files removed..." 
            }

            # Delete old Cylance Log files
            if (Test-Path "C:\Program Files\Cylance\Desktop") {
                $ResultText.text = "Deleting Cylance Log files..." 
                $OldCylanceLogFiles = Get-ChildItem -Path "C:\Program Files\Cylance\Desktop" | Where-Object name -Like "cylog-*.log"
                foreach ($File in $OldCylanceLogFiles) {
                    Remove-Item -Path "C:\Program Files\Cylance\Desktop\$($file.name)" -Force -ErrorAction SilentlyContinue -Verbose
                }
                $ResultText.text = "Cylance log files deleted..." 
            }

            $getSize = "{0:N2} " -f ((@(

                        if (Test-Path "$env:windir\Prefetch") {
(Get-ChildItem "$env:windir\Prefetch" -Force -Recurse  | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:windir\SoftwareDistribution.bak") {
    (Get-ChildItem "$env:windir\SoftwareDistribution.bak" -Force -Recurse  | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:windir\Temp") {
(Get-ChildItem "$env:windir\Temp" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:windir\Logs\CBS") {
(Get-ChildItem "$env:windir\Logs\CBS" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemdrive\Windows.old") {
(Get-ChildItem "$env:systemdrive\Windows.old" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:ProgramData\Microsoft\Windows\RetailDemo") {
(Get-ChildItem "$env:ProgramData\Microsoft\Windows\RetailDemo" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:LOCALAPPDATA\AMD") {
(Get-ChildItem "$env:LOCALAPPDATA\AMD" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:windir\..\AMD\") {
(Get-ChildItem "$env:windir\..\AMD\" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:LOCALAPPDATA\NVIDIA\DXCache") {
(Get-ChildItem "$env:LOCALAPPDATA\NVIDIA\DXCache" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:LOCALAPPDATA\NVIDIA\GLCache") {
(Get-ChildItem "$env:LOCALAPPDATA\NVIDIA\GLCache" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:APPDATA\..\locallow\Intel\ShaderCache") {
(Get-ChildItem "$env:APPDATA\..\locallow\Intel\ShaderCache"-Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemdrive\Intel") {
(Get-ChildItem "$env:systemdrive\Intel" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemdrive\PerfLogs") {
(Get-ChildItem "$env:systemdrive\PerfLogs" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemdrive\Temp") {
(Get-ChildItem "$env:systemdrive\Temp" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemdrive\Drivers") {
(Get-ChildItem "$env:systemdrive\Drivers" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemdrive\Scripts") {
(Get-ChildItem "$env:systemdrive\Scripts" -Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemdrive\Script") {
(Get-ChildItem "$env:systemdrive\Script"-Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemdrive\Nvidia") {
(Get-ChildItem "$env:systemdrive\Nvidia"-Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:LOCALAPPDATA\temp") {
    (Get-ChildItem "$env:LOCALAPPDATA\temp"-Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemroot\System32\Catroot2.bak") {
    (Get-ChildItem "$env:systemroot\System32\Catroot2.bak"-Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                        if (Test-Path "$env:systemroot\SoftwareDistribution.bak") {
    (Get-ChildItem "$env:systemroot\SoftwareDistribution.bak"-Force -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }

                    ) | Measure-Object -Sum).Sum / 1GB)

            if ($getSize -gt 0.1) {
                $ResultText.text = "Folders for System, User and Common Temp Files contain: ", ("{0:N2} GB" -f $getSize) 
                $CleanKnownTemp = [System.Windows.Forms.MessageBox]::Show('Are you sure?' + "`r`n`n" + 'Total size: ' + ("{0:N2} GB" -f $getSize) , "Clear all System, User and Common Temp Files?" , 4)
            }
            else {
                Start-Sleep -s 3
                $ResultText.text = "No need to clean the System, User and Common Temp folders right now..." 
            }

            if ($CleanKnownTemp -eq 'Yes') {
                # Clear Common Temp Folders
                $ResultText.text = "Clearing Common Temp Folders..." 
                Foreach ($user in $Users) {
                    Remove-Item -Path "$env:systemdrive\Users\$user\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                    Remove-Item -Path "$env:systemdrive\Users\$user\AppData\Local\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                    Remove-Item -Path "$env:systemdrive\Users\$user\AppData\Local\Microsoft\Windows\AppCache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                    Remove-Item -Path "$env:systemdrive\Users\$user\cookies\*.*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                    Remove-Item -Path "$env:systemdrive\Users\$user\Local Settings\Temporary Internet Files\*.*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                    Remove-Item -Path "$env:systemdrive\Users\$user\recent\*.*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                }

                # Clear Windows Temp Folder
                $ResultText.text = "Clearing Windows Temp, Logs and Prefetch Folders..." 
                Remove-Item -Path "$env:systemroot\SoftwareDistribution.bak" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:systemroot\System32\Catroot2.bak" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:systemdrive\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:windir\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:windir\Logs\CBS\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:systemdrive\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:ProgramData\Microsoft\Windows\RetailDemo" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:LOCALAPPDATA\AMD" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:windir/../AMD/" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:LOCALAPPDATA\NVIDIA\DXCache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:LOCALAPPDATA\NVIDIA\GLCache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "$env:APPDATA\..\locallow\Intel\ShaderCache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

                # Clear Custom folders
                Remove-Item -Path "C:\Intel" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "C:\PerfLogs" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "C:\Temp" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "C:\Drivers" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "C:\Scripts" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "C:\Script" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "C:\Nvidia" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

                # Only grab log files sitting in the root of the Logfiles directory
                $Sys32Files = Get-ChildItem -Path "$env:windir\System32\LogFiles" | Where-Object { ($_.name -like "*.log") }
                foreach ($File in $Sys32Files) {
                    Remove-Item -Path "$env:windir\System32\LogFiles\$($file.name)" -Force -ErrorAction SilentlyContinue -Verbose
                }

                $ResultText.text = "All System, User and Common Temp Files have been deleted successfully..." 
            } 

            # Get the size of the Windows Updates folder (SoftwareDistribution)
            $WUfoldersize = (Get-ChildItem "$env:windir\SoftwareDistribution" -Recurse | Measure-Object Length -s).sum / 1Gb

            # Ask the user if they would like to clean the Windows Update folder
            if ($WUfoldersize -gt 0.2) {
                $ResultText.text = "The Software Distribution folder is", ("{0:N2} GB" -f $WUFoldersize) 
                $CleanWU = [System.Windows.Forms.MessageBox]::Show('Are you sure?' + "`r`n`n" + 'Total size: ' + ("{0:N2} GB" -f $WUFoldersize) , "Do you want clean the Software Distribution folder?" , 4)
            }
            else {
                Start-Sleep -s 3
                $ResultText.text = "There is no need for cleaning Software Distribution folder right now..." 
            }

            if ($CleanWU -eq 'Yes') { 
                $ResultText.text = "Restarting Windows Update Service and Deleting SoftwareDistribution Folder"
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
                $ResultText.text = "SoftwareDistribution folder removed, reinitiate Windows Update to reaquire updates..." 
            }

            $binfoldersize = (Get-ChildItem "C:\`$Recycle.Bin" -Recurse | Measure-Object Length -s).sum / 1Gb
            if ($binfoldersize -gt 0.2) {
                $ResultText.text = "The Recycling Bing is", ("{0:N2} GB" -f $binfoldersize) 
                $CleanBin = [System.Windows.Forms.MessageBox]::Show('Are you sure?' + "`r`n`n" + 'Total size: ' + ("{0:N2} GB" -f $binfoldersize) , "Would you like to empty the Recycle Bin for All Users?" , 4)
            }
            else {
                $ResultText.text = "There is no need for cleaning the Recycling Bin right now..." 
            }

            if ($Cleanbin -eq 'Yes') {
                $ResultText.text = "Cleaning Recycle Bin..." 
                $ErrorActionPreference = 'SilentlyContinue'
                $RecycleBin = "C:\`$Recycle.Bin"
                $BinFolders = Get-ChildItem $RecycleBin -Directory -Force

                Foreach ($Folder in $BinFolders) {
                    # Translate the SID to a User Account
                    $objSID = New-Object System.Security.Principal.SecurityIdentifier ($folder)
                    try {
                        $objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
                        $ResultText.text = "Cleaning $objUser Recycle Bin..." 
                    }
                    # If SID cannot be Translated, Throw out the SID instead of error
                    catch {
                        $objUser = $objSID.Value
                        $ResultText.text = "$objUser"
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
                $ResultText.text = "Recycle Bin has been emptied..." 
            }

            $SuperCleanOffload = [System.Windows.Forms.MessageBox]::Show('This may take over an hour to complete, are you sure you want to continue?', "Launch Superdeep Cleaner?" , 4)
            if ($SuperCleanOffload -eq 'Yes') {

                $OffloadScript = {
                    $name = 'Superdeep Cleaner - Offload Process'
                    $host.ui.RawUI.WindowTitle = $name
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

                $ResultText.text = "Clearing Temporary hidden system files, a new window will open, let that run in the background..." 
            }
            $ResultText.text = "Standard cleaning process has been completed. `r`n  Superdeep Cleaner will still be running if you you pressed yes on that, but the window will close once completed. `r`n `r`n Ready for Next Task!" 
            $Form.text = "WinTool by Alerion"
        })

    $forcenorkeyboard.Add_Click({
            $ResultText.text = "Removing secondary en-US keyboard settings nb-NO to default."

            Set-WinUserLanguageList -LanguageList nb-NO, nb-NO -Force

            Start-Sleep -s 5

            $1 = Get-WinUserLanguageList
            $1.RemoveAll( { $args[0].LanguageTag -clike 'us*' } )
            Set-WinUserLanguageList $1 -Force

            $2 = Get-WinUserLanguageList
            $2.RemoveAll( { $args[0].LanguageTag -clike 'en*' } )
            Set-WinUserLanguageList $2 -Force

            $ResultText.text = "Secondary keyboard removed and Norwegian keyboard layout has been forced to be default."
        })

        Add-Type -AssemblyName System.Windows.Forms

        $essentialtweaks.Add_Click({
            $Form.text = "WinTool by Alerion - Initializing Essential Tweaks... `r`n" 
            $ResultText.text = "Activating Essential Tweaks... Please Wait... `r`n"
        
            # Create Restore Point
            $ResultText.text += "Creating a restore point... `r`n"
            Enable-ComputerRestore -Drive "C:\" | Out-Null
            Checkpoint-Computer -Description "WinTool-Essential-Tweaks-Restorepoint" -RestorePointType "MODIFY_SETTINGS"
        
            # Adjust Visual Effects
            $ResultText.text += "Adjusting visual effects for performance... `r`n"
            Start-Sleep -Seconds 1
            $visualEffects = @{
                "HKCU:\Control Panel\Desktop" = @{"DragFullWindows"="0"; "MenuShowDelay"="200"; "UserPreferencesMask"=([byte[]](144, 18, 3, 128, 16, 0, 0, 0))}
                "HKCU:\Control Panel\Desktop\WindowMetrics" = @{"MinAnimate"="0"}
                "HKCU:\Control Panel\Keyboard" = @{"KeyboardDelay"=0}
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" = @{"ListviewAlphaSelect"=0; "ListviewShadow"=0; "TaskbarAnimations"=0; "VisualFXSetting"=3}
                "HKCU:\Software\Microsoft\Windows\DWM" = @{"EnableAeroPeek"=0}
            }
            foreach ($path in $visualEffects.Keys) {
                foreach ($name in $visualEffects[$path].Keys) {
                    Set-ItemProperty -Path $path -Name $name -Value $visualEffects[$path][$name] | Out-Null
                }
            }
        
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
        
            # Disable Background Apps
            $ResultText.text += "Disabling Background Application Access... `r`n"
            Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" |
                Where-Object { $_.PSChildName -notlike "Microsoft.Windows.Cortana*" } |
                ForEach-Object {
                    Set-ItemProperty -Path $_.PSPath -Name "Disabled" -Value 1
                    Set-ItemProperty -Path $_.PSPath -Name "DisabledByUser" -Value 1
                }
        
            # Prompt for Linux Subsystem Removal
            $ResultText.text += "Prompting for Linux Subsystem removal... `r`n"
            $linuxPrompt = [System.Windows.Forms.MessageBox]::Show("Do you want to remove the Linux Subsystem (WSL)?", "Remove WSL", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($linuxPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                $ResultText.text += "Uninstalling Linux Subsystem... `r`n"
                Disable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
            } else {
                $ResultText.text += "Skipped Linux Subsystem removal. `r`n"
            }
        
            # Prompt for Teams Removal
            $ResultText.text += "Prompting for Microsoft Teams removal... `r`n"
            $teamsPrompt = [System.Windows.Forms.MessageBox]::Show("Do you want to remove Microsoft Teams?", "Remove Microsoft Teams", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($teamsPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
                $ResultText.text += "Removing pre-installed Microsoft Teams... `r`n"
                Get-AppxPackage MicrosoftTeams* | Remove-AppxPackage -ErrorAction SilentlyContinue
            } else {
                $ResultText.text += "Skipped Microsoft Teams removal. `r`n"
            }
        
            # Enable Performance Power Plan
            $ResultText.text += "Enabling Highest Performance Power Plan... `r`n"
            $powerPlanUrl = "https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/Files/Bitsum-Highest-Performance.pow"
            $powerPlanPath = "$Env:windir\system32\Bitsum-Highest-Performance.pow"
            Invoke-WebRequest -Uri $powerPlanUrl -OutFile $powerPlanPath -ErrorAction SilentlyContinue
            powercfg -import $powerPlanPath e6a66b66-d6df-666d-aa66-66f66666eb66 | Out-Null
            powercfg -setactive e6a66b66-d6df-666d-aa66-66f66666eb66 | Out-Null
        
            # Restart Explorer
            $ResultText.text += "Restarting Explorer for changes to take effect... `r`n"
            Stop-Process -Name explorer -Force
            Start-Sleep -Seconds 2
            Start-Process explorer
        
            $ResultText.text = "Essential Tweaks Completed. Ready for the next task!"
            $Form.text = "WinTool by Alerion"
        })
        

    $dualboottime.Add_Click({
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Type DWord -Value 1
            $ResultText.text = " Time set to UTC for consistent time in Dual Boot Systems. `r`n Ready for Next Task!"
        })

    $essentialundo.Add_Click({
            $Form.text = "WinTool by Alerion - Initializing Essentials Undo... `r`n" 
            $ResultText.text = " Creating Restore Point named: WinTool-EssentialTweaksUndo-Restorepoint in case something goes wrong... `r`n" 
            Enable-ComputerRestore -Drive "C:\"
            Checkpoint-Computer -Description "WinTool-EssentialTweaksUndo-Restorepoint" -RestorePointType "MODIFY_SETTINGS"

            $ResultText.text += " Disabling Windows 10 context menu... `r`n" 
            New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Force

            $ResultText.text += " Enabling recently added apps from Start Menu... `r`n" 
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Type DWord -Value 0

            $ResultText.text += " Re-Installing Linux Subsystem... `r`n" 
            If ([System.Environment]::OSVersion.Version.Build -eq 14393) {
                # 1607 needs developer mode to be enabled
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Type DWord -Value 1
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Type DWord -Value 1
            }
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null

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

            if (!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Power Saver")) { powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a }
            if (!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Balanced")) { powercfg -duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e }
            if (!(Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -Like "Ultimate Performance")) { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 }
            $ResultText.text = " Restored all power plans: Power Saver, Balanced, and Ultimate Performance."

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

            $ResultText.text += " Re-Enabling Chat, Widgets and Centering Start Menu... `r`n" 
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

            $ResultText.text += " Explorer view reset back to Home menu... `r`n" 
            # Default Explorer view to Home
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -type Dword -Value 0
            
            $ResultText.text += " Hiding Windows system folders that were previously shown ... `r`n" 
            # Show hidden files, folders and system files that are hidden
            Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden"  -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden"  -ErrorAction SilentlyContinue

            $ResultText.text += " Explorer is restarting, screen flashes might occur... `r`n" 
            #Restart Explorer so that the taskbar can update and not look break :D
            Stop-Process -name explorer
            Start-Sleep -s 5
            Start-Process -name explorer

            $ResultText.text = " Essential Undo Completed. `r`n Ready for Next Task!"
            $Form.text = "WinTool by Alerion"
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

            #This line reinstalls all of the bloatware that was removed
            Get-AppxPackage -AllUsers | ForEach-Object { Add-AppxPackage -Verbose -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" } 

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
   
            #Re-enables scheduled tasks that were disabled when running the Debloat switch
            $ResultText.text = " Enabling scheduled tasks that were disabled"
            Get-ScheduledTask XblGameSaveTaskLogon | Enable-ScheduledTask 
            Get-ScheduledTask  XblGameSaveTask | Enable-ScheduledTask 
            Get-ScheduledTask  Consolidator | Enable-ScheduledTask 
            Get-ScheduledTask  UsbCeip | Enable-ScheduledTask 
            Get-ScheduledTask  DmClient | Enable-ScheduledTask 
            Get-ScheduledTask  DmClientOnScenarioDownload | Enable-ScheduledTask 

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
            # Check if OneDrive is installed
            if ((Test-Path "$env:programdata\Microsoft OneDrive") -or 
                (Test-Path "C:\Program Files (x86)\Microsoft OneDrive") -or 
                (Test-Path "C:\Program Files\Microsoft OneDrive")) {
                
                $confirmOneDrive = [System.Windows.Forms.MessageBox]::Show(
                    "This may take a while, are you sure you want to proceed?", 
                    "Remove OneDrive?", 
                    [System.Windows.Forms.MessageBoxButtons]::YesNo, 
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
        
                if ($confirmOneDrive -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $Form.text = "WinTool by Alerion - Removing OneDrive..."
                    $ResultText.text = "Uninstalling OneDrive..."
        
                    # Attempt to uninstall OneDrive
                    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup.exe"
                    if (Test-Path $regPath) {
                        $uninstallString = Get-ItemPropertyValue -Path $regPath -Name "UninstallString"
                        $oneDriveExe, $oneDriveArgs = $uninstallString.Split(" ")
                        Start-Process -FilePath $oneDriveExe -ArgumentList "$oneDriveArgs /silent" -NoNewWindow -Wait
                    }
        
                    # Check if uninstallation succeeded
                    if (-not (Test-Path $regPath)) {
                        $Form.text = "WinTool by Alerion - Cleaning Up..."
                        $ResultText.text = "OneDrive has been removed. Cleaning up leftover files..."
        
                        # Remove leftover files and registry entries
                        foreach ($path in @(
                            "$env:localappdata\Microsoft\OneDrive",
                            "$env:localappdata\OneDrive",
                            "$env:programdata\Microsoft OneDrive",
                            "$env:systemdrive\OneDriveTemp",
                            "C:\Program Files\Microsoft OneDrive",
                            "C:\Program Files (x86)\Microsoft OneDrive",
                            "C:\Users\Default\OneDrive",
                            "$env:userprofile\OneDrive"
                        )) {
                            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $path
                        }
        
                        reg delete "HKEY_CURRENT_USER\Software\Microsoft\OneDrive" -f
                        Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
                        Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
        
                        # Remove scheduled tasks
                        Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ErrorAction SilentlyContinue |
                            Unregister-ScheduledTask -Confirm:$false
        
                        Start-Process "explorer.exe"
                        $Form.text = "WinTool by Alerion - OneDrive Removed"
                        $ResultText.text = "OneDrive has been completely removed. Ready for the next task!"
                    } else {
                        $ResultText.text = "Something went wrong during the uninstallation of OneDrive. Ready for the next task."
                    }
                } else {
                    $Form.text = "WinTool by Alerion - Operation Cancelled"
                    $ResultText.text = "OneDrive removal was cancelled. Ready for the next task!"
                }
        
            } else {
                # Prompt to reinstall OneDrive if not found
                $confirmReinstall = [System.Windows.Forms.MessageBox]::Show(
                    "OneDrive is not currently installed. Would you like to reinstall it?", 
                    "Reinstall OneDrive?", 
                    [System.Windows.Forms.MessageBoxButtons]::YesNo, 
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
        
                if ($confirmReinstall -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $Form.text = "WinTool by Alerion - Reinstalling OneDrive..."
                    $ResultText.text = "Downloading and reinstalling OneDrive. Please wait..."
                    
                    # Start OneDrive installer
                    $installerUrl = "https://go.microsoft.com/fwlink/p/?LinkId=248256"  # OneDrive installer URL
                    $installerPath = "$env:temp\OneDriveSetup.exe"
        
                    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -ErrorAction SilentlyContinue
                    Start-Process -FilePath $installerPath -ArgumentList "/silent" -NoNewWindow -Wait
        
                    $Form.text = "WinTool by Alerion - OneDrive Reinstalled"
                    $ResultText.text = "OneDrive has been successfully reinstalled. Ready for the next task!"
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

    $resetbutton.Add_Click({
            $bravebrowser.Checked = $false
            $dropbox.Checked = $false
            $7zip.Checked = $false
            $malwarebytes.Checked = $false
            $steam.Checked = $false
            $discord.Checked = $false
            $teamviewer.Checked = $false
            $epicgames.Checked = $false
            $githubdesktop.Checked = $false
            $visualstudiocode.Checked = $false
            $qbittorrent.Checked = $false
            $notepad.Checked = $false
            $foxit.Checked = $false
            $spotify.Checked = $false
            $ds4windows.Checked = $false
            $bakkes.Checked = $false

            [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

            $forcereinstallchoco = [System.Windows.Forms.MessageBox]::Show('Do you also want to force a re-install of Chocolatey?' , "Ready to re-install Chocolatey?" , 4)
            if ($forcereinstallchoco -eq 'Yes') {
                # Resets/Removed chocolatey in case of failure.
                Remove-Item -Path "C:\ProgramData\chocolatey" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
                Remove-Item -Path "C:\ProgramData\ChocolateyHttpCache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

                Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                
                if (choco list --lo -r -e chocolatey-core.extension) {
                    $ResultText.text = " Chocolatey Core Extension is already installed. `r`n Ready for next task!"
                }
                else {
                    choco install chocolatey-core.extension -y -force
                    $ResultText.text = " Chocolatey Core Extension was installed. `r`n Ready for next task!"
                }    
                
                $ResultText.text = " Chocolatey Re-install completed! `r`n Ready for next task!"
            }
        })

    $updatebutton.Add_Click({
           [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

            $chocoupdate = [System.Windows.Forms.MessageBox]::Show('This may take a while, are you sure?' , "Ready to update apps with Chocolatey?" , 4)
            if ($chocoupdate -eq 'Yes') {
                $chocoupdate = {
                    $name = 'Chocolatey is updating all your apps that require an update - Please wait...'
                    $host.ui.RawUI.WindowTitle = $name
                    
                    choco update all -y --force
                }

                Start-Process cmd.exe -ArgumentList "-NoLogo -NoProfile -ExecutionPolicy ByPass $chocoupdate"
                $ResultText.text = " Updating all installed applications `r`n Stay tuned until UI is responsive again!"
            }
        })

    $bravepath = Test-Path "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
    $dropboxpath = Test-Path "C:\Program Files (x86)\Dropbox\Client\Dropbox.exe"
    $7zippath = Test-Path "C:\Program Files\7-Zip\7z.exe"

   $okbutton.Add_Click({

    if(!(Test-Path "C:\ProgramData\chocolatey")) {
        $ResultText.text = " Chocolatey is installing! `r`n Stay tuned until UI is responsive again!"
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        if (choco list --lo -r -e chocolatey-core.extension) {
            $ResultText.text = " Chocolatey Core Extension is already installed. `r`n Ready for next task!"
            Write-Host " Chocolatey Core Extension is already installed. `r`n Ready for next task!"
        }
        else {
            choco install chocolatey-core.extension -y -force
            Write-Host " Chocolatey Core Extension was installed. `r`n Ready for next task!"
            $ResultText.text = " Chocolatey Core Extension was installed. `r`n Ready for next task!"
        }

        $ResultText.text = " Chocolatey was installed! `r`n Ready for next task!"
    }
    elseif(Test-Path "C:\ProgramData\chocolatey\choco.exe") {
        $ResultText.text = " Making sure Chocolatey is up to date! `r`n Stay tuned until UI is responsive again!"
        choco upgrade chocolatey
        $ResultText.text = " Chocolatey updated sucessfully! `r`n Ready for next task!"
    }
    elseif((Test-Path "C:\ProgramData\chocolatey\lib") -and (!(Test-Path "C:\ProgramData\chocolatey\choco.exe"))) {
        $ResultText.text = " Files missing, re-installing Chocolatey! `r`n Stay tuned until UI is responsive again!"

         # Resets/Removed chocolatey in case of failure.
         Remove-Item -Path "C:\ProgramData\chocolatey" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
         Remove-Item -Path "C:\ProgramData\ChocolateyHttpCache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        choco install chocolatey-core.extension -y -force
        $ResultText.text = " Chocolatey Re-install completed! `r`n Ready for next task!"
    }

        if ($bravebrowser.Checked) {
            if ($bravepath) {
                $ResultText.text = " Brave Browser was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install brave -y --force
                
                if (choco list --lo -r -e brave) {
                    $ResultText.text = " Brave Browser has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Brave Browser failed to install. `r`n Ready for next task!"
                }    
            }
        }

        if ($dropbox.Checked) {
            if ($dropboxpath) {
                $ResultText.text = " Dropbox was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install dropbox -y --force

                if (choco list --lo -r -e dropbox) {
                    $ResultText.text = " Dropbox has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Dropbox failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($7zip.Checked) {
            if ($7zippath) {
                $ResultText.text = " 7-Zip was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install 7zip -y --force

                if (choco list --lo -r -e 7zip) {
                    $ResultText.text = " 7zip has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " 7zip failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($malwarebytes.Checked) {  
            if (Test-Path "C:\Program Files\Malwarebytes\Anti-Malware\mbam.exe") {
                $ResultText.text = " Malwarebytes was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install Malwarebytes -y --force

                if (choco list --lo -r -e Malwarebytes) {
                    $ResultText.text = " Malwarebytes has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Malwarebytes failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($steam.Checked) {
            if (Test-Path "C:\Program Files (x86)\Steam\steam.exe") {
                $ResultText.text = " Steam Client was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install steam -y --force

                if (choco list --lo -r -e steam) {
                    $ResultText.text = " Steam has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Steam failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($discord.Checked) {
            if (Test-Path ~\AppData\Local\Discord\update.exe) {
                $ResultText.text = " Discord was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install discord -y --force

                if (choco list --lo -r -e discord) {
                    $ResultText.text = " Discord has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Discord failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($teamviewer.Checked) {
            if (Test-Path "C:\Program Files\TeamViewer\TeamViewer.exe") {
                $ResultText.text = " Teamviewer was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install teamviewer -y --force

                if (choco list --lo -r -e teamviewer) {
                        $ResultText.text = " Teamviewer has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Teamviewer failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($epicgames.Checked) {
            if (Test-Path "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe") {
                $ResultText.text = " Epic Games Launcher was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install epicgameslauncher -y --force
                
                if (choco list --lo -r -e epicgameslauncher) {
                    $ResultText.text = " Epic Games Launcher has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Epic Games Launcher failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($githubdesktop.Checked) {
            if (Test-Path ~\AppData\Local\GitHubDesktop\GitHubDesktop.exe) {
                $ResultText.text = " Github Desktop was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install github-desktop -y --force
                
                if (choco list --lo -r -e github-desktop) {
                    $ResultText.text = " Github Desktop has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Github Desktop failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($visualstudiocode.Checked) {
            if (Test-Path "~\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\") {
                $ResultText.text = " Visual Studio Code was already Installed.  `r`n Ready for next task!"
            }  
            else {
                choco install vscode -y --force
                
                if (choco list --lo -r -e vscode) {
                    $ResultText.text = " Visual Studio Code has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Visual Studio Code failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($qbittorrent.Checked) {
            if (Test-Path "C:\Program Files\qBittorrent\qbittorrent.exe") {
                $ResultText.text = " qBittorrent was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install qbittorrent -y --force
                
                if (choco list --lo -r -e qbittorrent) {
                    $ResultText.text = " qBittorrent has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " qBittorrent failed to install. `r`n Ready for next task!"
                } 
            }
        }

        if ($notepad.Checked) {
            if (Test-Path "C:\Program Files\Notepad++\notepad++.exe") {
                $ResultText.text = " Notepad++ is was already Installed. `r`n Ready for next task!"
                
            }
            else {
                choco install notepadplusplus -y --force

                if (choco list --lo -r -e notepadplusplus) {
                    $ResultText.text = " Notepad++ has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Notepad++ failed to install. `r`n Ready for next task!"
                }    
            }
        }

        if ($foxit.Checked) {
            if (Test-Path "C:\Program Files (x86)\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe") {
                $ResultText.text = " Foxit PDF Reader was already Installed. `r`n Ready for next task!"
            }  
            else {
                choco install foxitreader -y --force
                
                if (choco list --lo -r -e foxitreader) {
                    $ResultText.text = " Foxit PDF Reader has been installed. `r`n Ready for next task!"
                }
                else {
                    $ResultText.text = " Foxit PDF Reader failed to install. `r`n Ready for next task!"
                }
            }
        }

            if ($spotify.Checked) {
                if (Test-Path "~\AppData\Roaming\Spotify\Spotify.exe") {
                    $ResultText.text = " Spotify was already Installed. `r`n Ready for next task!"
                }  
                else {
                    choco install spotify -y --force

                    if (choco list --lo -r -e spotify) {
                        $ResultText.text = " Spotify has been installed. `r`n Ready for next task!"
                    }
                    else {
                        $ResultText.text = " Spotify failed to install. `r`n Ready for next task!"
                    }
                }
            }

            if ($ds4windows.Checked) {
                if (Test-Path "C:\ProgramData\chocolatey\bin\DS4Windows.exe") {
                    $ResultText.text = " DS4 Windows was already Installed. `r`n Ready for next task!"
                }  
                else {
                    choco install ds4windows -y --force
                    
                    if (choco list --lo -r -e ds4windows) {
                        $ResultText.text = " DS4 Windows has been installed. `r`n Ready for next task!"
                    }
                    else {
                        $ResultText.text = " DS4 Windows failed to install. `r`n Ready for next task!"
                    }
                }
            }

            if ($bakkes.Checked) {

                if (Test-Path "$pathDocuments\Bakkesmod.zip") {
                    $ResultText.text = " Bakkesmod Already Downloaded. `r`n Ready for next task!"
                }  
                else {
                    # Download bakkesmod from source destination
                    Invoke-WebRequest "https://github.com/bakkesmodorg/BakkesModInjectorCpp/releases/latest/download/BakkesModSetup.zip" -OutFile "$pathDocuments\Bakkesmod.zip"
                    
                    # Install 7zip module
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
                    Set-PSRepository -Name 'PSGallery' -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted
                    Install-Module -Name 7Zip4PowerShell -Force

                    # Extract file
                    $sourcefile = "$pathDocuments\Bakkesmod.zip"
                    Expand-7Zip -ArchiveFileName $sourcefile -TargetPath "~\AppData\Roaming\"

                    $ResultText.text = " Bakkesmod has been downloaded and extracted, files can be found in your $pathDocuments. `r`n Stay tuned until UI is responsive again!"
                }
            }
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
            $iconPath = 'C:\Windows\heart.ico'
            $url = "https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/Files/heart.ico"
            Invoke-WebRequest -Uri $url -OutFile $iconPath

            $WshShell = New-Object -comObject WScript.Shell #needed for Script Host things like making shortcuts

            if (!(Test-Path "$pathDesktop\WinTool.lnk")){ 
                $Shortcut = $WshShell.CreateShortcut("$pathDesktop\WinTool.lnk")
                $Shortcut.IconLocation = "C:\Windows\heart.ico" # icon index 0
                $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                $Shortcut.WorkingDirectory = "C:\Windows\System32\WindowsPowerShell\v1.0\"
                $Shortcut.Arguments = "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alerion921/WinTool-for-Win11/main/WinTool.ps1'))"
                $Shortcut.Save()

                #This part makes sure the shortcut is automaticly starting as administrator so that there will be no errors..
                $bytes = [System.IO.File]::ReadAllBytes("$pathDesktop\WinTool.lnk")
                $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
                [System.IO.File]::WriteAllBytes("$pathDesktop\WinTool.lnk", $bytes)

                $ResultText.text = "WinTool shortcut has been created and can be found at: $pathDesktop"
            }
            else {
                $ResultText.text = "Failed to create WinTool shortcut it might already exist, please try again!"
            }
        })

        $createShortcutGit.Add_Click({
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
        
            # Check if the .URL shortcut already exists
            if (!(Test-Path "$pathDesktop\Alerion921's Github.URL")) {
                try {
                    # Create the URL shortcut
                    $shortcutContent = @"
        [InternetShortcut]
        URL=https://github.com/alerion921/WinTool-for-Win11
        IconFile=$iconPath
     IconIndex=0
"@
                    $shortcutPath = "$pathDesktop\Alerion921's Github.URL"
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

    $Form.ShowDialog() | Out-Null
}
MakeForm