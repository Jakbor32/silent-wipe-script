<#
================= ENVIRONMENT INFO =================
PSVersion        : 7.5.2
ActiveDirectory  : 1.0.1.0
Microsoft.Graph  : 2.29.1
PnP.PowerShell   : 3.1.0
===================================================

================= INSTALL COMMANDS =================
# Run once if module is missing

# --- Active Directory ---
# On Windows 10/11:
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

# On Windows Server:
Install-WindowsFeature RSAT-AD-PowerShell

# --- Other modules from PSGallery ---
Install-Module Microsoft.Graph -Scope AllUsers
Install-Module PnP.PowerShell -Scope AllUsers
===================================================

================= IMPORT COMMANDS =================
Import-Module ActiveDirectory
Import-Module Microsoft.Graph
Import-Module PnP.PowerShell
===================================================
#>


# ================= MODULE CHECK =====================
$requiredModules = @("ActiveDirectory", "Microsoft.Graph", "PnP.PowerShell")

foreach ($m in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Module $m is missing. Please install it before running this script." -ForegroundColor Red
    }
    else {
        try {
            Import-Module $m -ErrorAction Stop
            Write-Host "Module $m loaded successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to import module $m : $_" -ForegroundColor Red
        }
    }
}

# ================= PREVENT SLEEP =====================
Add-Type -Namespace WinAPI -Name PowerControl -MemberDefinition @"
  [DllImport("kernel32.dll")]
  public static extern uint SetThreadExecutionState(uint esFlags);
"@

$ES_CONTINUOUS = [System.UInt32]::Parse("80000000", 'HexNumber')
$ES_SYSTEM_REQUIRED = [System.UInt32]::Parse("00000001", 'HexNumber')
$ES_DISPLAY_REQUIRED = [System.UInt32]::Parse("00000002", 'HexNumber')

$flags = $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED
[WinAPI.PowerControl]::SetThreadExecutionState($flags)

# ================= PARAMETERS =====================
# Replace placeholders (your_cert_thumbprint_here, your_tenant_id_here, etc.) with actual values before running
$certThumbprint = "your_cert_thumbprint_here"
$tenantId = "your_tenant_id_here"
$clientId = "your_client_id_here"
$siteUrl = "https://yourtenant.sharepoint.com/sites/your-site"
$daysInactive = 30
$logPath = "C:\SilentWipeScript\log.txt"

# Clearing the local log
if (Test-Path $logPath) { Clear-Content -Path $logPath }
else { New-Item -ItemType File -Path $logPath -Force | Out-Null }

function Write-Log($msg, [switch]$ErrorLog) {
    $prefix = if ($ErrorLog) { "### ERROR ###" } else { "INFO" }
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $prefix - $msg"
    Add-Content -Path $logPath -Value $line
    Write-Host $line
}

# ================= CONNECTIONS =====================
try {
    Connect-MgGraph -Scopes User.ReadWrite.all
    Write-Log "Connected to Microsoft Graph"
}
catch {
    Write-Log "Failed to connect to Graph: $_" -ErrorLog
}

try {
    Connect-PnPOnline -ClientId $clientId -Url $siteUrl -Tenant $tenantId -Thumbprint $certThumbprint
    Write-Log "Connected to SharePoint"
}
catch {
    Write-Log "Failed to connect to SharePoint: $_" -ErrorLog
}


# ================= HANDLING DELETE STATUS ======================
foreach ($userItem in $existingUsers) {
    $email = $userItem["email"]
    $status = $userItem["status"]

    if ([string]::IsNullOrEmpty($email) -or [string]::IsNullOrEmpty($status)) { continue }

    $statusLower = $status.ToLower()

    if ($statusLower -eq "delete") {
        try {
            $processed = $false

            # Attempting through AD
            try {
                $adUser = Get-ADUser -Filter { Mail -eq $email } -ErrorAction Stop
                Disable-ADAccount -Identity $adUser -ErrorAction Stop

                $prefix = "###_AutoWipe"
                $newName = "${prefix}_$($adUser.SamAccountName)"
                $displayName = "$prefix`_$($adUser.GivenName) $($adUser.Surname)"

                Rename-ADObject -Identity $adUser.DistinguishedName -NewName $newName -ErrorAction Stop
                Set-ADUser -Identity $adUser.DistinguishedName -DisplayName $displayName

                Write-Log "User $email disabled, renamed in AD to $newName, and DisplayName set to '$displayName'"
                $processed = $true
            }
            catch {
                Write-Log "Failed to process in AD ($email), trying through Graph: $_" -ErrorLog

                try {
                    $mgUser = Get-MgUser -Filter "mail eq '$email'"
                    if ($mgUser) {
                        Update-MgUser -UserId $mgUser.Id -AccountEnabled:$false -DisplayName "###_AutoWipe_$($mgUser.DisplayName)"
                        Write-Log "User $email disabled and renamed through Graph"
                        $processed = $true
                    }
                    else {
                        Write-Log "Failed to find user $email in Graph" -ErrorLog
                    }
                }
                catch {
                    Write-Log "Error disabling in Graph for $email - $_" -ErrorLog
                }
            }

            # Remove user from SharePoint if processed successfully
            if ($processed) {
                Remove-UserFromSharePointList -email $email
            }
        }
        catch {
            Write-Log "Failed to process delete status for $email - $_" -ErrorLog
        }
    }
    elseif ($statusLower -in @("awaiting approval", "pending")) {
        try {
            Remove-PnPListItem -List "Users" -Identity $userItem.Id -Force
            Write-Log "Removed record $email with status $status from SharePoint"
        }
        catch {
            Write-Log "Error removing $email with status $status - $_" -ErrorLog
        }
    }
}

# ================= WHITELIST =====================
$whitelist = @()
$whitelistItems = Get-PnPListItem -List "Whitelist" -Fields "email" -PageSize 1000
foreach ($item in $whitelistItems) {
    $mail = $item["email"]
    if ($mail) { $whitelist += $mail.ToLower().Trim() }
}
Write-Log "Loaded whitelist from SharePoint ($($whitelist.Count) records)"

# ================= RETRIEVING AND ITERATING =====================
$users = Get-MgUser -All -Property AccountEnabled, Mail, UserPrincipalName
$newInactiveCount = 0

foreach ($user in $users) {
    $mail = $user.Mail
    $upn = $user.UserPrincipalName
    $isEnabled = $user.AccountEnabled

    if ([string]::IsNullOrEmpty($mail)) { continue }
    if (-not $mail.ToLower().EndsWith("yourdomain.com")) { continue }

    if (-not $isEnabled) {
        Write-Log "Skipping disabled user: $mail"
        continue
    }

    $mailLower = $mail.ToLower()

    if ($whitelist -contains $mailLower) {
        Write-Log "Skipped whitelist: $mailLower"
        continue
    }

    # Check if already on the list

    $existingUsers = Get-PnPListItem -List "Users" -Fields "email", "status", "Modified"
    $existingItem = $existingUsers | Where-Object { $_["email"].ToLower() -eq $mailLower }
    if ($existingItem) {
        Write-Log "User already exists on the Users list: $mailLower"
        continue
    }

    # Logins
    try {
        $signIns = Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$upn'" -Top 10 -ErrorAction Stop
    }
    catch {
        Write-Log "Failed to retrieve sign-ins for $mailLower - $_" -ErrorLog
        continue
    }

    $isInactive = $false
    if (-not $signIns -or $signIns.Count -eq 0) {
        $isInactive = $true
    }
    else {
        $lastSignInDate = $signIns | Sort-Object CreatedDateTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty CreatedDateTime
        if ($lastSignInDate -lt (Get-Date).AddDays(-$daysInactive)) { $isInactive = $true }
    }

    if ($isInactive) {
        try {
            Add-PnPListItem -List "Users" -Values @{ "email" = $mailLower; "status" = "pending" }
            Write-Log "Added to SharePoint Users: $mailLower (pending)"
            $newInactiveCount++
        }
        catch {
            Write-Log "Error adding $mailLower to SharePoint: $_" -ErrorLog
        }
    }
    else {
        Write-Log "Active: $mailLower"
    }
}

# ============ FINAL LOGGING =====================
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = @{ "log" = "$timestamp - Checked users. Inactive: $newInactiveCount" }
try {
    Add-PnPListItem -List "Logs" -Values $logEntry
    Write-Log "Log saved to SharePoint: $($logEntry["log"])"
}
catch {
    Write-Log "Error saving final log: $_" -ErrorLog
}
