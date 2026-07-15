Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$profilesPath = Join-Path (Split-Path -Parent $scriptDir) "profiles.conf"

if (-not (Test-Path $profilesPath)) {
    [System.Windows.Forms.MessageBox]::Show("Profiles file not found:`n$profilesPath")
    exit
}

$profiles = @()
Get-Content $profilesPath | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    $parts = $line -split '\|'
    if ($parts.Count -ge 2) {
        $profiles += [PSCustomObject]@{
            Label      = $parts[0].Trim()
            Resolution = $parts[1].Trim()
            App        = if ($parts.Count -ge 3) { $parts[2].Trim() } else { "" }
        }
    }
}

if ($profiles.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("No profiles found in:`n$profilesPath")
    exit
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "scrcpy Launcher"
$form.Size = New-Object System.Drawing.Size(320, ([Math]::Min(500, 130 + 20 * $profiles.Count)))
$form.StartPosition = "CenterScreen"
$form.Topmost = $true
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$listBox = New-Object System.Windows.Forms.ListBox
foreach ($p in $profiles) {
    $listBox.Items.Add($p.Label) | Out-Null
}
$listBox.SetSelected(0, $true)
$listBox.Dock = "Top"
$listBox.Height = 200
$form.Controls.Add($listBox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "Launch"
$okButton.Dock = "Bottom"
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($okButton)
$form.AcceptButton = $okButton

$result = $form.ShowDialog()

if ($result -ne [System.Windows.Forms.DialogResult]::OK -or $null -eq $listBox.SelectedItem) {
    exit
}

$selected = $profiles | Where-Object { $_.Label -eq $listBox.SelectedItem } | Select-Object -First 1

$scrcpyArgs = @("--new-display=$($selected.Resolution)")
if ($selected.App) {
    $scrcpyArgs += "--start-app=+$($selected.App)"
}
Start-Process scrcpy -ArgumentList $scrcpyArgs
