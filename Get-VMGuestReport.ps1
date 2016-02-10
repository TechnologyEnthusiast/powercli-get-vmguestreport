#
# Get-VMGuestReport.ps1
#

# This function accepts vCenter server and VMGuest names
# It will connect to all vCenter instances and query the VMGUest by name
# The info from each VM will be captured and stored in a report
Function Get-VMGuestReport
{
	[CmdletBinding()]
	Param ( 
		[string[]]$vCenter,
		[string[]]$VMGuest
	)
	
	# Add VimAutomation.Core and Set-PowerCLIConfiguration
	# Connect to $vCenter
	Begin
	{
		Write-Verbose "Adding VMware.VimAutomation.Core snapin and setting powercli configuration"
		Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue
		Set-PowerCLIConfiguration -InvalidCertificateAction 'Ignore' -DefaultVIServerMode 'Multiple' -DisplayDeprecationWarnings:$false -confirm:$false
		Write-Verbose "Connecting to $vCenter"
		Connect-VIServer $vCenter
		$Report = @()
	}

	# Query vCenter for VMGuest and gather data
	Process
	{
		write-verbose "Processing stuff"
		try
		{
			foreach ($VM in $VMGuest)
			{
				Write-Verbose "Attemping to locate $VM"
				$Guest = Get-View -ViewType VirtualMachine -Filter @{Name = "$VM"} | Select-Object Name, `
					@{N="PowerState"; E={$_.Runtime.PowerState}}, `
					@{N="Operating System"; E={$_.Config.GuestFullName}}, `
					@{N="CPU Sockets"; E={$_.Config.Hardware.NumCpu}}, `
					@{N="CPU Cores"; E={$_.Config.Hardware.NumCoresPerSocket}}, `
					@{N="Active RAM"; E={$_.Summary.QuickStats.GuestMemoryUsage}}, `
					@{N="Ballooned RAM"; E={$_.Summary.QuickStats.BalloonedMemory}}, `
					@{N="Total RAM"; E={$_.Config.Hardware.MemoryMB}}, `
					@{N="IP Address"; E={$_.Guest.IpAddress}}, `
					@{N="Hardware Version"; E={$_.Config.Version}}, `
					@{N="Tools Version"; E={$_.Guest.ToolsVersion}}, `
					@{N="Tools Version Status"; E={$_.Guest.ToolsVersionStatus2}}, ` # use ToolsVersionStatus2, ToolsVersionStatus was deprecated
					@{N="Tools Running Status"; E={$_.Guest.ToolsRunningStatus}}, `
					@{N="Notes"; E={$_.Config.Annotation}}, `
					@{N="HA Protected"; E={$_.Runtime.DasVmProtection.DasProtected}}, `
					@{N="Snapshot Name"; E={$_.Snapshot.RootSnapshotList.Name}}, `
					@{N="Snapshot Create Time"; E={$_.Snapshot.RootSnapshotList.CreateTime}}
					@{N="Datastore"; E={$_.Config.Datastoreurl.Name}}
					#@{N=""; E={$_.}}, `
					#@{N=""; E={$_.}}, `
					#@{N=""; E={$_.}}, `
					#@{N=""; E={$_.}}, `

					$Report += $Guest
			}
		}
		catch
		{
			Write-Verbose "Caught an exception"
		}
	}
	
	# Export report as CSV
	# Write output to console
	End
	{
		$Date = (Get-Date -Format yyyy-MM-dd.HHmm).toString()
		$Report | Export-Csv -Path "D:\VMGuest.$Date.csv" -NoTypeInformation
		$Report
		#Disconnect-VIServer $vCenter -Confirm:$false
		write-verbose "The script has finished successfully."
	}
}

#Get-VMGuestReport -vCenter $vCenter -VMGuest $VMGuest #-Verbose
