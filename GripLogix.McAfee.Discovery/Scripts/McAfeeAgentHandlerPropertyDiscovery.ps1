## Author: Merijn Overgaauw, GripLogix Consulting

param($SourceId, $ManagedEntityId, $InstallPath, $SearchFileInstallPath, $SearchPattern, $StripPattern, $ComputerName)

$params = "$SourceId, $ManagedEntityId, $SearchFolder, $ComputerName"
$debug = $true

# Constants used for event logging
$SCRIPT_NAME			= 'McAfeeAgentHandlerPropertyDiscovery.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4

$SCRIPT_STARTED			= 981
$PROPERTYBAG_CREATED	= 982
$ERROR_GENERATED        = 983
$INFO_GENERATED         = 984
$SCRIPT_ENDED			= 985

#==================================================================================
# Sub:		LogDebugEvent
# Purpose:	Logs an informational event to the Operations Manager event log
#			only if Debug argument is true
#==================================================================================
function Log-DebugEvent
	{
		param($eventNo,$message)

		$message = "`n" + $message
		if ($debug)
		{
			$api.LogScriptEvent($SCRIPT_NAME,$eventNo,$EVENT_LEVEL_INFO,$message)
		}
	}
#==================================================================================

# Start script.
$API = New-Object -comObject 'MOM.ScriptAPI'
$DiscoveryData = $API.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)

$message = "$SCRIPT_NAME script started.`nParameters: $params"
Log-DebugEvent $SCRIPT_STARTED $message

$SearchFilePath = $InstallPath -replace ":.*"
$SearchFilePath = $SearchFilePath + $SearchFileInstallPath

Try
	{
	$Data = Select-String $SearchFilePath -Pattern $SearchPattern -ErrorAction Stop
	$Data = $Data -replace $StripPattern
	}
Catch
	{
	$errorMessage = "Select-String for $SearchFilePath failed`nError: $_.`nDiscovered Data is: $Data" 
	Log-DebugEvent $ERROR_GENERATED $errorMessage
	}

Switch -Wildcard ($SearchPattern)
{
    "*database.name*" 
		{
		$Instance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeAgentHandler']$")
		$Instance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $ComputerName)
		$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeAgentHandler']/Database$", $Data)
		}
	"*server.name*" 
		{
		$Instance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeAgentHandler']$")
		$Instance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $ComputerName)
		$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeAgentHandler']/DatabaseServer$", $Data)
		}
	"*version*" 
		{
		$Instance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeAgentHandler']$")
		$Instance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $ComputerName)
		$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeAgentHandler']/Version$", $Data)
		}
    default 
		{
		$errorMessage = "$SearchPattern is not a valid SearchPattern for $SCRIPT_NAME script."
		Log-DebugEvent $ERROR_GENERATED $errorMessage
		}
}

$DiscoveryData.AddInstance($Instance)

$DiscoveryData

$message = "$SCRIPT_NAME script ended.`nParameters: $params`nDiscovered Data for $SearchPattern is: $Data"
Log-DebugEvent $SCRIPT_ENDED $message