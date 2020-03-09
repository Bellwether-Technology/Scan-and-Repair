### Phase 1 ###

Write-Output "Phase 1: Scan C: volume for errors..." -ForegroundColor Blue -BackgroundColor White
try {
	$volumeOK = Repair-Volume -DriveLetter C -Scan | Out-String
	if ($volumeOK.Contains("NoErrorsFound")) {
		Write-Output "Volume scan successful." -ForegroundColor Green
	} else {
		Write-Output "Volume is corrupt and requires repair. Attempting spotfix now..." -ForegroundColor Red
		$volumeRepair = Repair-Volume -DriveLetter C -Spotfix | Out-String
		if ($volumeRepair.Contains("NoErrorsFound")) {
			Write-Output "Volume has been successfully repaired." -ForegroundColor Green
		} else {
			Write-Output "Volume was not able to be repaired. Moving on..." -ForegroundColor Red
		}
	}
} catch {
	Write-Output "Failed to execute Phase 1."
}



### Phase 2 ###

Write-Output "Phase 2: DISM Scan and Repair" -ForegroundColor Blue -BackgroundColor White
try {

	#Initial DISM scan to see if their is component corruption
	$DISMState = Repair-WindowsImage -ScanHealth -Online

	#Check results of initial scan
	if ($DISMState.ImageHealthState -eq "Healthy") {
		Write-Output "Windows image is in healthy state." -ForegroundColor Green
		if ($DISMState.RestartNeeded -eq $True) {
			Write-Output "Restart is required." -ForegroundColor Yellow
		}
	} else {

		#If unhealthy state, attempt to repair (DISM /Online /Cleanup-image /RestoreHealth)
		Write-Output "Windows image is in unhealthy state and needs to be repaired." -ForegroundColor Red
		Write-Output "Attempting Windows image repair now..." -ForegroundColor Yellow
		$DISMState = Repair-WindowsImage -RestoreHealth -Online
		if ($DISMState.ImageHealthState -eq "Healthy") {
			Write-Output "Windows image has been successfully repaired." -ForegroundColor Green

		} else {

			#If /RestoreHealth doesn't work, run /StartComponentCleanup in last ditch effort
			Write-Output "Windows image was not able to be repaired." -ForegroundColor Red
			Write-Output "Beginning DISM's StartComponentCleanup..." -ForegroundColor Yellow
			dism.exe /Online /Cleanup-Image /StartComponentCleanup
			$DISMState = Repair-WindowsImage -ScanHealth -Online
			if ($DISMState.ImageHealthState -eq "Healthy") {
				Write-Output "Windows image is in healthy state." -ForegroundColor Green
			} else {
				Write-Output "This did not work" -ForegroundColor Red
			}
		}
		if ($DISMState.RestartNeeded -eq $True) {
			Write-Output "Restart is required." -ForegroundColor Yellow
		}
	}
} catch {
	Write-Output "Failed to execute Phase 2."
}