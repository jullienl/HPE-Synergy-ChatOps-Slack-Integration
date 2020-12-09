﻿# -------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------

function delete-server {
    [CmdletBinding()]
    Param
    (
        # Server name
        [Parameter(Mandatory = $true)]
        $name #="win-1"
    )


    # OneView Credentials and IP
    $username = $env:OneView_username
    $password = $env:OneView_password
    $IP = $env:OneView_IP
    
    #Import-Module HPOneview.500 
    $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
 
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    # Create a hashtable for the results
    $result = @{ }

    #Connecting to the Synergy Composer
    Try {
        Connect-OVMgmt -appliance $IP -Credential $credentials | out-null
    }
    Catch {
        $env = "I cannot connect to OneView ! Check my OneView connection settings using ``find env``" 
        $result.output = "$($env)" 
        $result.success = $false
        
        return $result | ConvertTo-Json
    }

    #import-OVSSLCertificate -ApplianceConnection ($connectedSessions | ? {$_.name -eq $IP}) 

    # Added these lines to avoid the error: "The underlying connection was closed: Could not establish trust relationship for the SSL/TLS secure channel."
    # due to an invalid Remote Certificate
    add-type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


    # Verifying the SP is present
    Try { 
                
        $serverprofile = Get-OVserverprofile -Name $name -ErrorAction stop 
    }
    
    Catch {

        $result.output = "Delete error ! I cannot find the Server Profile *$($name)* in OneView !"
        # Set a failed result
        $result.success = $false

        Disconnect-OVMgmt 

        # Return the result deleting SP and conver it to json
        #$script:resultsp = $result
        return $result | ConvertTo-Json

    }

    # Turning off the server hadware and deleting the SP
    try {
                    
        $serverprofile | stop-OVServer -Force -Confirm:$false -ErrorAction Stop | Wait-OVTaskComplete | Out-Null

        Remove-OVServerProfile -ServerProfile $name -force -Confirm:$false -ErrorAction stop #| Out-Null
            
        $result.output = "*$($name)* is being deleted" 
            
        # Set a successful result
        $result.success = $true
    
    }

    catch {
        $result.output = "*$($name)* cannot be deleted, please check the OneView UI for further information"
        # Set a failed result
        $result.success = $false
    }

    # Return the result deleting SP and convert it to json
    #$script:resultsp = $result
    Disconnect-OVMgmt
    return $result | ConvertTo-Json


}