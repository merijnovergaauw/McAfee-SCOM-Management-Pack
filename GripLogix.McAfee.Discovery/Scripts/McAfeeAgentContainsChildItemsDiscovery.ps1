## Author: Merijn Overgaauw, GripLogix Consulting

param($SourceId, $ManagedEntityId, $InstanceType, $RegKeyMcAfeeAgent, $ComputerName)

$params = "$SourceId, $ManagedEntityId, $InstanceType, $RegKeyMcAfeeAgent, $ComputerName"
$debug = $true

# Constants used for event logging
$SCRIPT_NAME			= 'McAfeeAgentContainsChildItemsDiscovery.ps1'
$EVENT_LEVEL_ERROR 		= 1
$EVENT_LEVEL_WARNING 	= 2
$EVENT_LEVEL_INFO 		= 4

$SCRIPT_STARTED			= 961
$RELATIONSHIP_CREATED	= 962
$ERROR_GENERATED        = 963
$INFO_GENERATED         = 964
$SCRIPT_ENDED			= 965

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

# Create SCOM api.
$API = New-Object -comObject 'MOM.ScriptAPI'
$DiscoveryData = $API.CreateDiscoveryData(0, $SourceId, $ManagedEntityId)

$message = "$SCRIPT_NAME script started.`nParameters: $params"
Log-DebugEvent $SCRIPT_STARTED $message

# Check whether there is a McAfeeAgent installed on this computer. When found a containment relation between the McAfee Agent
# and targetted instance can be created.
$McAfeeAgentExist = Get-ItemProperty -path $RegKeyMcAfeeAgent

If ($McAfeeAgentExist)
	{
	$message = "McAfee Agent installed on this computer"
	Log-DebugEvent $INFO_GENERATED $message

	# Parent instance discovery.
	$ParentInstance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeAgent']$")
	$ParentInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $ComputerName)
	$DiscoveryData.AddInstance($ParentInstance)

	# Child instance discovery.
	If ($InstanceType -eq "McShield")
		{
		$ChildInstance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeMcShield']$")
		$RelationshipInstance = $DiscoveryData.CreateRelationshipInstance("$MPElement[Name='GripLogix.McAfee.Relationship.McAfeeAgentContainsMcAfeeMcShield']$")
		}

	If ($InstanceType -eq "EndPointSecurity")
		{
		$ChildInstance = $DiscoveryData.CreateClassInstance("$MPElement[Name='GripLogix.McAfee.McAfeeEndPointSecurity']$")
		$RelationshipInstance = $DiscoveryData.CreateRelationshipInstance("$MPElement[Name='GripLogix.McAfee.Relationship.McAfeeAgentContainsMcAfeeEndPointSecurity']$")
		}

	$ChildInstance.AddProperty("$MPElement[Name='Windows!Microsoft.Windows.Computer']/PrincipalName$", $ComputerName)
	$DiscoveryData.AddInstance($ChildInstance)

	# Parent/child relationshipinstance discovery.
	$RelationshipInstance.Source = $ParentInstance
	$RelationshipInstance.Target = $ChildInstance
	$DiscoveryData.AddInstance($RelationshipInstance)

	$message = "Relationship created"
	Log-DebugEvent $RELATIONSHIP_CREATED $message

	}
Else 
	{
	$message = "No McAfee Agent instance installed on this computer!"
	Log-DebugEvent $INFO_GENERATED $message
	}

# Return discovery data.
$DiscoveryData

$message = "$SCRIPT_NAME script ended.`nParameters: $params"
Log-DebugEvent $SCRIPT_ENDED $message