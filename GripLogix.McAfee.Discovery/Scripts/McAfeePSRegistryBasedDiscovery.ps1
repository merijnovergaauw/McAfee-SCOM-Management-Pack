## Author: Merijn Overgaauw, GripLogix Consulting

param($SourceId, $ManagedEntityId, $InstanceType, $regKeyPath, $ComputerName)

$params = "$SourceId, $ManagedEntityId, $InstanceType, $regKeyPath, $ComputerName"
$debug = $true

# Constants used for event logging
$SCRIPT_NAME			= 'McAfeeRegistryBasedDiscovery.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4

$SCRIPT_STARTED			= 991
$RELATIONSHIP_CREATED	= 992
$ERROR_GENERATED        = 993
$INFO_GENERATED         = 994
$SCRIPT_ENDED			= 995

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

# Start script.
$API = New-Object -comObject 'MOM.ScriptAPI'
$DiscoveryData = $API.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)

$message = "$SCRIPT_NAME script started.`nParameters: $params"
Log-DebugEvent $SCRIPT_STARTED $message

Switch ($InstanceType)
	{
	"EndPointSecurity" 
		{
		$regData = Get-ItemProperty -path $regKeyPath
		If ($regData)
			{
			$version = $regData.Version
			$hotfixVersion = $regData.HotfixVersion
			$patchVersion = $regData.PatchVersion
			$installedPath = $regData.'Install Path'

			$Instance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeEndPointSecurity']$")
			$Instance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $ComputerName)
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeEndPointSecurity']/Version$", "$version")
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeEndPointSecurity']/HotfixVersion$", "$hotfixVersion")
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeEndPointSecurity']/PatchVersion$", "$patchVersion")
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeEndPointSecurity']/InstalledPath$", "$installedPath")
			$Instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $ComputerName)

			$DiscoveryData.AddInstance($Instance)
			}
		}

	"McShield" 
		{
		$regData = Get-ItemProperty -path $regKeyPath
		If ($regData)
			{
			$version = $regData.Version
			$hotfixVersion = $regData.HotfixVersions
			$installedPath = $regData.'Install Path'

			$Instance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeMcShield']$")
			$Instance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $ComputerName)
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeMcShield']/Version$", "$version")
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeMcShield']/HotfixVersion$", "$hotfixVersion")
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeMcShield']/InstalledPath$", "$installedPath")
			$Instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $ComputerName)

			$DiscoveryData.AddInstance($Instance)
			}

		}

	"ThreadPrevention" 
		{
		$regData = Get-ItemProperty -path $regKeyPath
		If ($regData)
			{
			$version = $regData.Version
			$hotfixVersion = $regData.HotfixVersion
			$patchVersion = $regData.PatchVersion
			$installedPath = $regData.'Install Path'

			$Instance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeThreadPrevention']$")
			$Instance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $ComputerName)
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeThreadPrevention']/PatchVersion$", "$patchVersion")
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeThreadPrevention']/HotfixVersion$", "$hotfixVersion")
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeThreadPrevention']/Version$", "$version")
			$Instance.AddProperty("$MPElement[Name='GripLogix.McAfee.McAfeeThreadPrevention']/InstallPath$", "$installedPath")
			$Instance.AddProperty("$MPElement[Name='System!System.Entity']/DisplayName$", $ComputerName)

			$DiscoveryData.AddInstance($Instance)
			}

		}
		
	}

# Return discovery data.
$DiscoveryData

$message = "$SCRIPT_NAME script ended.`nParameters: $params"
Log-DebugEvent $SCRIPT_ENDED $message