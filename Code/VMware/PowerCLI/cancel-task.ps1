# THIS SCRIPT NEEDS TO BE RUN TWICE

$VIServer = "fqdn"


Connect-VIServer -Server $VIServer -Protocol https -Credential (Get-Secret vcenter)


$tasks = Get-Task -Status "Running" | select Id

foreach($task in $tasks){
	Write-Host $task.Id
	
	$taskName = $task.Id

	$taskMgr = Get-View TaskManager

	if($taskMgr.RecentTask){

		$task = Get-View -Id $taskMgr.RecentTask | where {$_.Info.Name -eq $taskName}

		if('queued','running' -contains $task.Info.State -and $task.Info.Cancelable){

			$task.CancelTask()

		}

		else{

			if(-not $task.Info.Cancelable){

				Write-Host "Task not cancelable"

			}

			if('queued','running' -notcontains $task.Info.State){

				Write-Host "Task not canceled due to state $($task.Info.State)"

			}

		}

	}	
	
}

