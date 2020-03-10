### Check PowerShell version (v3+ required)
$vers = $PSVersionTable.PSVersion.Major
if ($vers -lt 3) {
	Write-Output "This script requires PowerShell version 3 or newer."
	exit
}


### Phase 1 ###

Write-Output "Phase 1: Scan C: volume for errors..."
try {
	$volumeOK = Repair-Volume -DriveLetter C -Scan | Out-String
	if ($volumeOK.Contains("NoErrorsFound")) {
		Write-Output "Volume scan successful."
	} else {
		Write-Output "Volume is corrupt and requires repair. Attempting spotfix now..."
		$volumeRepair = Repair-Volume -DriveLetter C -Spotfix | Out-String
		if ($volumeRepair.Contains("NoErrorsFound")) {
			Write-Output "Volume has been successfully repaired."
		} else {
			Write-Output "Volume was not able to be repaired. Moving on..."
		}
	}
} catch {
	Write-Output "Failed to execute Phase 1."
}


### Phase 2 ###

Write-Output "Phase 2: DISM Scan and Repair"
try {

	#Initial DISM scan to see if their is component corruption
	$DISMState = Repair-WindowsImage -ScanHealth -Online

	#Check results of initial scan
	if ($DISMState.ImageHealthState -eq "Healthy") {
		Write-Output "Windows image is in healthy state."
		if ($DISMState.RestartNeeded -eq $True) {
			Write-Output "Restart is required."
		}
	} else {

		#If unhealthy state, attempt to repair (DISM /Online /Cleanup-image /RestoreHealth)
		Write-Output "Windows image is in unhealthy state and needs to be repaired."
		Write-Output "Attempting Windows image repair now..."
		$DISMState = Repair-WindowsImage -RestoreHealth -Online
		if ($DISMState.ImageHealthState -eq "Healthy") {
			Write-Output "Windows image has been successfully repaired."

		} else {

			#If /RestoreHealth doesn't work, run /StartComponentCleanup in last ditch effort
			Write-Output "Windows image was not able to be repaired."
			Write-Output "Beginning DISM's StartComponentCleanup..."
			dism.exe /Online /Cleanup-Image /StartComponentCleanup
			$DISMState = Repair-WindowsImage -ScanHealth -Online
			if ($DISMState.ImageHealthState -eq "Healthy") {
				Write-Output "Windows image is in healthy state."
			} else {
				Write-Output "This did not work"
			}
		}
		if ($DISMState.RestartNeeded -eq $True) {
			Write-Output "Restart is required."
		}
	}
} catch {
	Write-Output "Failed to execute Phase 2."
}


### Phase 3 ###

Write-Output "Phase 3: SFC scan"
try {
	$SFCResult = sfc /scannow
	# Because this isn't a PowerShell command, we can't grab the output as neatly
	# The next few lines should strip away all of the SFC output except for the end result
	$SFCResultParsed = ($SFCResult -split '' | Where-Object {$_ -and [byte][char]$_ -ne 0}) -join '' 
	$SFCResultParsed = $SFCResultParsed -Replace "Verification \d+\% complete.",""
	$SFCResultParsed = $SFCResultParsed -Replace "Beginning system scan.",""
	$SFCResultParsed = $SFCResultParsed -Replace "This process will take some time.",""
	$SFCResultParsed = $SFCResultParsed -Replace "Beginning verification phase of system scan.",""
	Write-Output $SFCResultParsed
} catch {
	Write-Output "Failed to execute Phase 3."
}