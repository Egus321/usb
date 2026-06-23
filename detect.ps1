# Переключаем на английский язык
Set-WinUILanguageOverride -Language en-US

try {
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    [System.Windows.MessageBox]::Show('hi from usb') | Out-Null
    exit 0
} catch {
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show('hi from usb') | Out-Null
        exit 0
    } catch {
        $shell = New-Object -ComObject WScript.Shell
        $shell.Popup('hi from usb', 0, 'Message', 0) | Out-Null
        exit 0
    }
}
