function GetLoginToken(){ param($azureSettings)

    $authBody = @{
        'Client_Id' = $azureSettings.Client_Id
        'client_Secret' = $azureSettings.client_Secret
        'resource' = $azureSettings.resource
        'grant_type' = $azureSettings.grant_type
    }

    $tenantId = $azureSettings.tenantId

    $uri = "https://login.microsoftonline.com/$($tenantId)/oauth2/token"
    result = Invoke-RestMethod -Uri $uri -ContentType "multipart/form-data" -Form $authBody -Method Post
    ConvertTo-SecureString $result."access_token" -asplaintext -force
}