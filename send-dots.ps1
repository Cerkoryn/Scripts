function send-dots {
    param($minutes = 900000)
    $myshell = New-Object -com "Wscript.Shell"
    for ($i = 0; $i -lt $minutes; $i++) {
        Start-Sleep -Seconds 45
        $myshell.sendkeys(".")
    }
}
