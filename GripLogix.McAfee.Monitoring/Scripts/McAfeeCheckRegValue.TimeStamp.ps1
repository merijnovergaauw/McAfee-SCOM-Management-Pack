## Author: Merijn Overgaauw, GripLogix Consulting

# Get parameters
param($regKeyPath, $regValue, $timeStampType, $threshold, $debug)

# Constants used for event logging
$SCRIPT_NAME			= 'CheckRegValue.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4

$SCRIPT_STARTED			= 951
$PROPERTYBAG_CREATED	= 952
$ERROR_GENERATED        = 953
$SCRIPT_ENDED			= 955

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
$message = "Script started with parameters $regKeyPath, $regValue, $timeStampType, $threshold, $debug"
Log-DebugEvent $SCRIPT_STARTED $message

# Get regValue data.
Try {$timeStamp = (Get-ItemProperty -path $regKeyPath -ErrorAction Stop).$regValue}
Catch 
	{
		$errorMessage = "Get-ItemProperty for $regKeyPath failed`nError: $_."
		Log-DebugEvent $ERROR_GENERATED $errorMessage
	}

# Convert value to datetime variable.
Switch ($timeStampType)
	{
	"humanDateTimeWithoutSeparators" 
		{		
		$timeStampDate = $timeStamp -replace ".{6}$"
		$timeStampDate = $timeStampDate -replace "^.{4}", '$0/'
		$timeStampDate = $timeStampDate -replace ".{2}$", '/$0'
		$timeStampDate = [datetime]$timeStampDate
		}

	"humanDateWithSeparators" 
		{		
		$timeStampDate = [datetime]$timeStamp
		}
	
	"epoch"
		{		
		$timeStamp = get-epochdate $timeStamp
		$message = "Debug: $regKeyPath, $regValue, $timeStampType, $timeStamp"
		Log-DebugEvent $SCRIPT_ENDED $message
		$timeStampDate = get-date -DisplayHint Date $timeStamp
		}	
	}

# Determine amount of days between regValue date and currentDate.
$currentDate = Get-Date
$daysOld = (New-TimeSpan –Start $timeStampDate –End $CurrentDate).TotalDays
$daysOld = [math]::Round($daysOld,1)
	
# Put the gathered data into the property bag.
$bag = $api.CreatePropertyBag()
$bag.AddValue('TimeStampDate',$timeStampDate)
$bag.AddValue('DaysOld',$daysOld)
$bag.AddValue('ErrorMessage',$errorMessage)
$bag.AddValue('Threshold',$threshold)

$message = "DatDate is: $timeStampDate`nDaysOld is: $daysOld`nErrorMessage is: $errorMessage"
Log-DebugEvent $PROPERTYBAG_CREATED $message

$bag
$message = "Script ended $regKeyPath, $regValue, $timeStampType, $threshold, $debug"
Log-DebugEvent $SCRIPT_ENDED $message