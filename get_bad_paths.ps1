$ErrorActionPreference = "Stop"

add-pssnapin VMware.VimAutomation.Core

# Use these commmands to enter credentials and create a secure password file:
# $pw = read-host “Enter Password” –AsSecureString
# ConvertFrom-SecureString $pw | out-file "C:\path\to\password\file\here\textfile.txt"

$pwdSec = Get-Content "C:\path\to\password\file\here\textfile.txt" | ConvertTo-SecureString

$bPswd = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwdSec)
$pswd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bPswd)


$vcenter_server = "servername"
$vcenter_user = "domain\userid"

Function Send-Mail  {

    $ol = New-Object -comObject Outlook.Application
    $mail = $ol.CreateItem(0)
    $Mail.Recipients.Add("username@email.com")
    $Mail.Subject = "Could not connect to vsphere"
    $Mail.HTMLBody =  "Could not connect to vSphere - maybe your creds expired for the Bad Paths report script"
    $Mail.Send()

}


try {
            
        Connect-VIServer -Server $vcenter_server -Protocol https -User $vcenter_user -Password $pswd

        }

Catch {

        Send-Mail
        
}

 }

$deadpaths = @()

ForEach ($vmhost in (Get-Datacenter "Your vSphere datacenter name here" | Get-Vmhost | Sort))  { 

    $deadpaths += Get-ScsiLun -vmhost $vmhost | `

        Get-ScsiLunPath | `

            where {$_.State -eq "Dead"} | `

                Select @{n="vmhost";e={$vmhost}},ScsiLun,State

}


if ( $deadpaths.count -gt 0 ) {

    $ol = New-Object -comObject Outlook.Application
    $mail = $ol.CreateItem(0)
    $Mail.Recipients.Add("username@email.com")
    $Mail.Subject = "vSphere Bad Paths Report"
    $Mail.HTMLBody = $($deadpaths | ConvertTo-HTML | Out-String)
    $Mail.Send()

}