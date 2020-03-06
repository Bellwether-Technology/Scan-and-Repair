### Phase 1 ###

Write-Host "Phase 1: Scan C: volume for errors..." -ForegroundColor Blue -BackgroundColor White
try {
	$volumeOK = Repair-Volume -DriveLetter C -Scan | Out-String
	if ($volumeOK.Contains("NoErrorsFound")) {
		Write-Host "Volume scan successful." -ForegroundColor Green
	} else {
		Write-Host "Volume is corrupt and requires repair. Attempting spotfix now..." -ForegroundColor Red
		$volumeRepair = Repair-Volume -DriveLetter C -Spotfix | Out-String
		if ($volumeRepair.Contains("NoErrorsFound")) {
			Write-Host "Volume has been successfully repaired." -ForegroundColor Green
		} else {
			Write-Host "Volume was not able to be repaired. Moving on..." -ForegroundColor Red
		}
	}
} catch {
	Write-Host "Failed to execute Phase 1."
}



### Phase 2 ###

Write-Host "Phase 2: DISM Scan and Repair" -ForegroundColor Blue -BackgroundColor White
try {
	$DISMState = Repair-WindowsImage -ScanHealth -Online
	if ($DISMState.ImageHealthState -eq "Healthy") {
		Write-Host "Windows image is in healthy state." -ForegroundColor Green
		if ($DISMState.RestartNeeded -eq $True) {
			Write-Host "Restart is required." -ForegroundColor Yellow
		}
	} else {
		Write-Host "Windows image is in unhealthy state and needs to be repaired." -ForegroundColor Red
		Write-Host "Attempting Windows image repair now..." -ForegroundColor Yellow
		$DISMState = Repair-WindowsImage -RestoreHealth -Online
		if ($DISMState.ImageHealthState -eq "Healthy") {
			Write-Host "Windows image has been successfully repaired." -ForegroundColor Green
		} else {
			Write-Host "Windows image was not able to be repaired." -ForegroundColor Red
		}
		if ($DISMState.RestartNeeded -eq $True) {
			Write-Host "Restart is required." -ForegroundColor Yellow
		}
	}
} catch {
	Write-Host "Failed to execute Phase 2."
}