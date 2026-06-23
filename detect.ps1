Add-Type -AssemblyName PresentationFramework

# 1. Принудительно завершаем процесс Explorer
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

# 2. Функция для создания графического окна
function Show-PasswordWindow {
    # Создание формы
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Блокировка доступа"
    $form.Size = New-Object System.Drawing.Size(350, 180)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true # Окно всегда поверх остальных

    # Метка с текстом
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(310, 20)
    $label.Text = "Введите пароль для разблокировки:"
    $form.Controls.Add($label)

    # Поле ввода пароля
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(20, 50)
    $textBox.Size = New-Object System.Drawing.Size(290, 20)
    $textBox.PasswordChar = "*" # Скрывать ввод точками
    $form.Controls.Add($textBox)

    # Кнопка подтверждения
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(120, 90)
    $button.Size = New-Object System.Drawing.Size(100, 30)
    $button.Text = "Войти"
    $form.Controls.Add($button)

    # Действие при нажатии кнопки
    $button.Add_Click({
        if ($textBox.Text -eq "001") {
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Неверный пароль!", "Ошибка", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $textBox.Clear()
            $textBox.Focus()
        }
    })

    # Запрет закрытия окна крестиком или Alt+F4 до ввода пароля
    $form.Add_FormClosing({
        param($_, $e)
        if ($form.DialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
            $e.Cancel = $true
        }
    })

    # Показ окна
    $form.ShowDialog() | Out-Null
}

# Загружаем типы Windows Forms
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Вызов окна
Show-PasswordWindow

# 3. Восстановление проводника после успешного ввода
Start-Process "explorer.exe"
