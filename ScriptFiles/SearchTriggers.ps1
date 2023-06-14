# Login as a user
Connect-AzAccount

# Get the token, and convert it to a secure string
$authToken = Get-AzAccessToken | Select-Object -ExpandProperty Token
$authToken = ConvertTo-SecureString $authToken -asplaintext -force

# Get seetings data
$azureSettings = Get-Content -Path '.\myAzureSettings.json' | ConvertFrom-Json

# Get some config values
$numberOfItems = $azureSettings.maxNumberItemPerCall
if ( $numberOfItems -gt 250 ) { $numberOfItems = 250 } #250 items is the maximum

$searchKey = $azureSettings.bodyFieldToSearch
$searchList = $azureSettings.searchList
$filterStart = $azureSettings.searchFromDateTime.tostring('yyyy-MM-ddTHH:mm:ssZ')
$filterEnd = $azureSettings.searchToDateTime.tostring('yyyy-MM-ddTHH:mm:ssZ')
$triggerName = $azureSettings.triggerName

# Create the first URI
$uri = "https://management.azure.com/subscriptions/$($azureSettings.subscriptionId)/resourceGroups/$($azureSettings.resourceGroup)/providers/Microsoft.Logic/workflows/$($azureSettings.workFlowName)/triggers/$($triggerName)/histories?api-version=2016-06-01"
$uri = $uri + '&$top=' + $numberOfItems
$uri = $uri + '&$filter=StartTime gt '+ $filterStart + ' and StartTime lt ' + $filterEnd

do {
    
    # Call the Logic APPs API for the trigger executions
    $response = Invoke-RestMethod -Uri $uri -Method Get -Authentication Bearer -Token $authToken

    $triggerList = $response."value"
    $nextLink = $response."nextLink"

    Write-Host "Got back $($triggerList.count) items"

    $loopcounter = 1

    # Loop thru all the executions in the list
    foreach($currentItem in $triggerList)
    {    
        $triggerProperties = $currentItem."properties"

        $triggerOutputsLink = $triggerProperties."outputsLink"

        # Get the tracked data in the trigger
        $triggerInfo = Invoke-RestMethod -Uri $triggerOutputsLink.uri -Method Get

        # Get the tracked value of the searched key for the current item. 
        $searchValue = $triggerInfo.body.$searchKey

        # Try to find the tracked value in the list of searchable items
        if ($searchList.Contains($searchValue))
        {
            Write-Host "Found $($searchValue)! Saving..."
            $filename = ".\OutFiles\$($searchValue)_$($triggerProperties.run.name).json"
            $triggerInfo | ConvertTo-Json  | New-Item -Path $filename -ItemType File -Force
        }

        # Show Progress
        Write-Host "$($loopcounter) of $($triggerList.count) processed"
        $loopcounter++
    }

    # If there is more data to get from the APIs, they send back a link to the next call.
    # If there is no more data, the value will be null and the loop stops.
    $uri = $nextLink

} until (!$nextLink)

Write-Host "===== Job's done! ====="
