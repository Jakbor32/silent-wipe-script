# Connecting PowerShell to Local Active Directory

## Prerequisites

- **Domain-joined machine or server** where the script will run.
- **Installed RSAT tools** with the Active Directory module for Windows PowerShell.
- **Service account** with delegated rights to:
    - Disable accounts (`Disable-ADAccount`)
    - Rename accounts (`Rename-ADObject` or `Set-ADUser`)

## PowerShell Setup

1. **Install RSAT if missing:**
     - On a server:
         ```powershell
         Add-WindowsFeature RSAT-AD-PowerShell
         ```
     - On a client:
         ```powershell
         Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
         ```

2. **Import the Active Directory module:**
     ```powershell
     Import-Module ActiveDirectory
     ```

3. **Test the connection:**
     ```powershell
     Get-ADDomain
     Get-ADUser -Filter * -ResultSetSize 1
     ```