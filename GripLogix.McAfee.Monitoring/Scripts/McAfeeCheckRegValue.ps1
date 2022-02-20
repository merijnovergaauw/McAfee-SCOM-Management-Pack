## Author: Merijn Overgaauw, GripLogix Consulting

# Get parameters
param($regKeyPath, $regValue, $debug)

# Constants used for event logging
$SCRIPT_NAME			= 'CheckRegValue.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4

$SCRIPT_STARTED			= 941
$PROPERTYBAG_CREATED	= 942
$ERROR_GENERATED        = 943
$SCRIPT_ENDED			= 945

#==================================================================================
# Sub:		LogDebugEvent
# Purpose:	Logs an informational event to the Operations Manager event log
#			only if Debug argument is true
#==================================================================================
Function Log-DebugEvent
{
	param($eventNo,$message)

	$message = "`n" + $message
	if ($debug -eq $true)
	{
		$api.LogScriptEvent($SCRIPT_NAME,$eventNo,$EVENT_LEVEL_INFO,$message)
	}
}
#=====================================================================================
# Convert epoch timestamp into human timestamp.
Function get-epochdate ($epochdate) { [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($epochdate)) }
#=====================================================================================

# Start script by setting up API object.
$api = New-Object -comObject 'MOM.ScriptAPI'
$message = "Script started with parameters $regKeyPath, $regValue, $debug"
Log-DebugEvent $SCRIPT_STARTED $message

# Get regValue data.
Try {$regData = Get-ItemProperty -path $regKeyPath -ErrorAction Stop}
Catch 
	{
		$errorMessage = "Get-ItemProperty for $regKeyPath failed`nError: $_."
		Log-DebugEvent $ERROR_GENERATED $errorMessage
	}

$regValueData = $regData."$regValue"
$error = "-"
If ($regValueData -eq "") {$regValueData = 0}
If ($regValueData -eq $null) {$regValueData = -999; $error = "ERROR: Registry Value object does not exist!"}
	
# Put the gathered data into the property bag.
$bag = $api.CreatePropertyBag()
$bag.AddValue($regValue,$regValueData)
$bag.AddValue('Error',$error)

$message = "Property bag created.
	$regValue : $regValueData
	Error : $error"
Log-DebugEvent $PROPERTYBAG_CREATED $message

$bag
$message = "Script ended $regKeyPath, $regValue, $debug"
Log-DebugEvent $SCRIPT_ENDED $message