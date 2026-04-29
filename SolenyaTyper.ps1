# SolenyaTyper.ps1 (v3)
# Bypasses client-side paste restrictions with modifier-combo support.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);' -Name 'NativeMethods' -Namespace 'User32'

# --- State Management ---
$SolenyaState = @{
    HotKeyVal     = 0
    RequiresCtrl  = $false
    RequiresShift = $false
    RequiresAlt   = $false
    HotKeyName    = "None"
    Typing        = $false
    WasDown       = $false
    IsArmed       = $false
}

# --- UI Setup ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Solenya Typer"
$form.Size = New-Object System.Drawing.Size(320, 130)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.Opacity = 0.85
$form.FormBorderStyle = 'FixedToolWindow'
$form.BackColor = "Black"
$form.ForeColor = "LimeGreen"

$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "Waiting for hotkey configuration..."
$labelTitle.Location = New-Object System.Drawing.Point(10, 10)
$labelTitle.AutoSize = $true
$form.Controls.Add($labelTitle)

$labelClip = New-Object System.Windows.Forms.Label
$labelClip.Text = "Clipboard: (empty)"
$labelClip.Location = New-Object System.Drawing.Point(10, 35)
$labelClip.Size = New-Object System.Drawing.Size(280, 20)
$form.Controls.Add($labelClip)

$hotkeyBox = New-Object System.Windows.Forms.TextBox
$hotkeyBox.Text = "Click here & press a key/combo to bind..."
$hotkeyBox.Location = New-Object System.Drawing.Point(10, 60)
$hotkeyBox.Size = New-Object System.Drawing.Size(280, 20)
$hotkeyBox.BackColor = "DarkSlateGray"
$hotkeyBox.ForeColor = "White"
$form.Controls.Add($hotkeyBox)

# --- Binding Logic ---
$hotkeyBox.Add_KeyDown({
    $_.SuppressKeyPress = $true 
    
    # Ignore if ONLY a modifier is pressed. Wait for the primary key.
    if ($_.KeyCode -eq 'ControlKey' -or $_.KeyCode -eq 'ShiftKey' -or $_.KeyCode -eq 'Menu') { return }
    
    $SolenyaState.HotKeyVal = $_.KeyValue
    $SolenyaState.RequiresCtrl = $_.Control
    $SolenyaState.RequiresShift = $_.Shift
    $SolenyaState.RequiresAlt = $_.Alt
    
    # Construct the display name
    $name = ""
    if ($_.Control) { $name += "Ctrl + " }
    if ($_.Shift) { $name += "Shift + " }
    if ($_.Alt) { $name += "Alt + " }
    $name += $_.KeyCode.ToString()
    
    $SolenyaState.HotKeyName = $name
    
    # Initialize edge-detection flags to prevent immediate firing
    $SolenyaState.WasDown = $true
    $SolenyaState.IsArmed = $false 
    
    # Update UI
    $hotkeyBox.Text = "Bound to: [$name]"
    $hotkeyBox.BackColor = "Black"
    $hotkeyBox.ForeColor = "Cyan"
    $labelTitle.Text = "Ready. Release keys to arm."
    
    $form.ActiveControl = $labelTitle 
})

# --- Function to Type Text Safely ---
function Invoke-GhostType {
    $clipText = [System.Windows.Forms.Clipboard]::GetText()
    if ([string]::IsNullOrEmpty($clipText)) { return }

    $escapedText = $clipText -replace '([+^%~{}()])', '{$1}'
    Start-Sleep -Milliseconds 100 
    [System.Windows.Forms.SendKeys]::SendWait($escapedText)
}

# --- Main Timer Loop ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100 
$timer.Add_Tick({
    
    # Update Clipboard Preview
    if ([System.Windows.Forms.Clipboard]::ContainsText()) {
        $text = [System.Windows.Forms.Clipboard]::GetText()
        $text = $text -replace "`n|`r", " " 
        if ($text.Length -gt 35) { $text = $text.Substring(0, 35) + "..." }
        $labelClip.Text = "Clip: $text"
    } else {
        $labelClip.Text = "Clip: (No text found)"
    }

    # Monitor hardware interrupts
    if ($SolenyaState.HotKeyVal -ne 0) {
        
        # Check current state of target keys (0x8000 mask verifies the high bit is set, meaning currently depressed)
        $isDown = ([User32.NativeMethods]::GetAsyncKeyState($SolenyaState.HotKeyVal) -band 0x8000) -eq 0x8000
        $ctrlDown = ([User32.NativeMethods]::GetAsyncKeyState(0x11) -band 0x8000) -eq 0x8000
        $shiftDown = ([User32.NativeMethods]::GetAsyncKeyState(0x10) -band 0x8000) -eq 0x8000
        $altDown = ([User32.NativeMethods]::GetAsyncKeyState(0x12) -band 0x8000) -eq 0x8000
        
        # Validate exact modifier match
        $modsMatch = ($ctrlDown -eq $SolenyaState.RequiresCtrl) -and 
                     ($shiftDown -eq $SolenyaState.RequiresShift) -and 
                     ($altDown -eq $SolenyaState.RequiresAlt)

        if ($isDown -and $modsMatch) {
            $SolenyaState.WasDown = $true
        } else {
            # Keys have been released. Trigger if armed.
            if ($SolenyaState.WasDown) {
                if ($SolenyaState.IsArmed -and -not $SolenyaState.Typing) {
                    $SolenyaState.Typing = $true
                    $labelTitle.Text = "Typing..."
                    $labelTitle.ForeColor = "Red"
                    $form.Refresh()
                    
                    Invoke-GhostType
                    
                    $labelTitle.Text = "Ready. Press [$($SolenyaState.HotKeyName)] to type."
                    $labelTitle.ForeColor = "LimeGreen"
                    $SolenyaState.Typing = $false
                } else {
                    # This handles the release event immediately after binding
                    $SolenyaState.IsArmed = $true
                    $labelTitle.Text = "Ready. Press [$($SolenyaState.HotKeyName)] to type."
                }
            }
            $SolenyaState.WasDown = $false
        }
    }
})

# --- Execution ---
$timer.Start()
$form.ShowDialog() | Out-Null
$timer.Stop()
$timer.Dispose()
$form.Dispose()
