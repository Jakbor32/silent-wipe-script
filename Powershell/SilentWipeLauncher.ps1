$scriptPath = "your_path_to\SilentWipeScript.ps1"

Start-Process -FilePath "pwsh.exe" `
    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" `
    -WindowStyle Hidden
