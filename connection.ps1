#IP address of OneView
$IP = "192.168.1.110" 

# OneView Credentials
$username = "Administrator" 
$password = "P@ssw0rd"

$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
     
Connect-OVMgmt -appliance $IP -Credential $credentials