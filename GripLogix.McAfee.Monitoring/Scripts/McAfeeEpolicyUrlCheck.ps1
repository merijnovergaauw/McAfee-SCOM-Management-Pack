## Author: Merijn Overgaauw, GripLogix Consulting

#==================================================================================
## Get parameters
param($name, $url, $contentChecked, $computerName, $tcpPort, $debug)


## Constants used for event logging
$SCRIPT_NAME			= 'McAfeeePolicyUrlCheck.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4

$SCRIPT_STARTED			= 1951
$PROPERTYBAG_CREATED	= 1952
$ERROR_GENERATED        = 1953
$SCRIPT_ENDED			= 1955

#==================================================================================
# Sub:		LogDebugEvent
# Purpose:	Logs an informational event to the Operations Manager event log
#			only if Debug argument is true
#==================================================================================
function Log-DebugEvent
{
	param($eventNo,$message)

	$message = "`n" + $message
	if ($debug -eq $true)
	{
		$api.LogScriptEvent($SCRIPT_NAME,$eventNo,$EVENT_LEVEL_INFO,$message)
	}
}
#==================================================================================
# Sub:		Get-Url
# Purpose:	Get (SSL) web page from url and ignore any SSL errors. This function 
#			can be used when no Powershell version 3.0 or higher has been installed.
#			In that case you cannot use the Invoke-WebRequest cmdlet.
#==================================================================================
function Get-Url
{
	param($url)
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
	$wc = New-Object System.Net.WebClient
	$src = $wc.downloadstring($url)
	Return $src
}
#==================================================================================
# Sub:		Test-Port
# Purpose:	Use this function to test port connectivity in case the server does not 
#			have the cmdlet Test-NetConnection, which requires Powershell 3 or 
#			higher.
#==================================================================================
function Test-Port

{
    Param(
        [parameter(ParameterSetName='ComputerName', Position=0)]
        [string]
        $ComputerName,

        [parameter(ParameterSetName='IP', Position=0)]
        [System.Net.IPAddress]
        $IPAddress,

        [parameter(Mandatory=$true , Position=1)]
        [int]
        $Port

        )

    $RemoteServer = If ([string]::IsNullOrEmpty($ComputerName)) {$IPAddress} Else {$ComputerName};

    $test = New-Object System.Net.Sockets.TcpClient;
    Try
        {
        $test.Connect($RemoteServer, $Port)
        "True"
        }
    Catch
    {
        "False"
    }  
    
}
#===============================================================================

## Start script by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'
$message = "Script started"
Log-DebugEvent $SCRIPT_STARTED $message

## Request WEB Page.
Try {$response = Get-Url $url -ErrorAction Stop}		
Catch 
	{
	$debugInfo = $debugInfo + "Error occured for Get-Url for web page $name with url $url`n Error: $_. - `n"
	$tcpPortCheck = Test-Port -ComputerName localhost -Port $tcpPort
	}

## Content Check
If ($response)	
	{	
	$match = Select-String -InputObject $response -pattern $contentChecked -SimpleMatch
	If ($match) {$contentpatternCheckResult = "SUCCESS"; $debugInfo = $debugInfo + "Response has been compared to following text: $contentChecked; match succeeded - `n"}
	Else {$contentpatternCheckResult = "FAILED"; $debugInfo = $debugInfo + "Response has been compared to following text: $contentChecked; match failed - `n"}		
	}
Else {$contentpatternCheckResult = "FAILED"; $debugInfo = $debugInfo + "Error: No response retreived from $url to compare with the following text: $contentChecked - `n"}

## Create a property bag.
$bag = $api.CreatePropertyBag()

## Put the gathered statistics into the property bag.
$bag.AddValue('ContentMatch',$contentpatternCheckResult)
$bag.AddValue('TCPportCheck',$tcpPortCheck)
If ($debug -eq $true) {$bag.AddValue('Debug',$debugInfo)}

$message = "$name`nContent Match: $contentpatternCheckResult`nDebug: $debugInfo"
Log-DebugEvent $PROPERTYBAG_CREATED $message

## Return the property bag.
$bag
$message = "Script ended."
Log-DebugEvent $SCRIPT_ENDED $message

