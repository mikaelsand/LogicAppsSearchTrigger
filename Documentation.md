# Short walkthru
If you think you know this, this is the TLDR;
- Create a copy of the AzureSettings.json file and name it myAzureSettings.json
- Get information from an App Registration, Client ID and the secret.
- Update the other information in the settings-file.
- The setting bodyFieldToSearch is the name of the trigger body property you wish to search
- The searchlist is an array of all the values you wish to match.
- Run the SeachTriggers.ps1 and watch it work.
- A search-hit will save a file to a folder in the same directory.
- The name of the file is the hit search term and the Logic App RunID.

# Documentation

## Login To Azure
To be able to access the APIs for Logic Apps, you need to login, or authenticate, your call and in order to do that, you need to get an OAUTH-token, and in order to do _that_ you need to login using some kind of credentials.

The scripts are configured to use a Registered Application (client) and a client secret (aka password). This is used in an OAUTH flow. If you don't know how to log in to Azure using APIs I suggest you start by reading [this page](https://docs.microsoft.com/en-us/rest/api/azure/#create-the-request "How to authenticate a request").

### Create an App Registration
This is documented in [this link](https://docs.microsoft.com/en-us/rest/api/azure/#register-your-client-application-with-azure-ad "Azure documentation").
Rememeber to save the **client ID** and **client secret** for later use.

When you have created your Application you need to make sure it has enough access rights to the Logic App you want to search. Making it a contributor in the same resource group is more than enough. I do not know the minimum level.

### Get the App Information
Beside the Client ID and Client secret you need the Tenant ID and the Subscription ID. 

**The tenant ID**: The tenant ID is listed in the Application Registration. The ID is a GUID. Save it for later use.



**The Subscription ID**: You should really be able to find this GUID using the portal. Its in the Overview page of the Logic App you want to search.

## Understanding the settings
In order to make the script work you should create a copy of the `AzureSettings.json` file and name it `myAzureSettings.json`. This makes sure your settings are not commited to the GIT repo as this file is the .gitignore file.

There are several parts of the file.
### Login Info
At the top of the file there are some settings related to loggin into Azure.

- `tenantId`: This is the GUID of the Azure Tenant you are trying to access.
- `grant_type`: This must be set to `client_credentials`
- `Client_Id`: The Application (Client) ID of your app.
- `client_Secret`: The password, or secret, that was generated when you created the application. If you do not have it you can easily generate a new one in the App's page. It is under Certificates and secrets in the left hand menu.
- `resource`: This is basically what you want to authenticate to. In some cases it might be different but in this case you must set it to `https://management.azure.com/`

Configured correctly, the top part should look similar to this

```json
"tenantId" : "ea1e8e1e-edaf-446b-964f-111114444777",
"grant_type": "client_credentials",
"Client_Id": "d8079907-d547-4aa0-970d-1aer245764ew",
"resource": "https://management.azure.com/",
"client_Secret": "G4rb31d_M3zz!~~",
```
If you have configured everything correctly you can run the script and the error should not be related to login or security issues.

### Logic App Info
This part is separate from the login process and is used in the API-calls to get data from the right Logic App.

- `resourceGroup`: The name of the resource group the Logic App is located in.
- `workFlowName`: The name of the Logic App you want to search in.
- `bodyFieldToSearch`: The name of the JSON property you want to search in, in the trigger body. More info below.
- `maxNumberItemPerCall`: The number of items (runs) you want to get per call. The API will send back a maximum of 250 items. This number is somtimes called  page size. A large number speeds up the process, but might have a negative impact on memory and CPU. My suggestion is that you use a large number.
- `searchFromDateTime`: To limit the number of runs you search thru you must set a time frame. This value is the 'from'. Runs must have executed after this value. The script is configured to follow the ISO standard of `yyyy-MM-ddTHH:mm:ssZ` and the time sent to the API must be in UTC-0 timezone.
- `searchToDateTime`: The same restrictions apply as for `searchFromDateTime`. This must be larger than the FromDate.
- `searchlist`: This is a json string array of the values you want to look for. I think it works for integers as well.

Configured correctly, this part should look similar to this

```json
"subscriptionId" : "782ebdc9-e486-42d8-95fb-111444888222",
"resourceGroup" : "OrderFlow-PROD-RG",
"workFlowName" : "OrderFlow-PROD",
"bodyFieldToSearch" : "OrderId",
"maxNumberItemPerCall" : 50,
"searchFromDateTime" : "2020-06-05T00:00:00Z",
"searchToDateTime" : "2020-06-05T23:59:59Z",
"searchList" : [
  "A-41105"
]
```

This looks in for order number `A-41105` in the `OrderId` field for all executions of `OrderFlow-PROD` on the `5th of June 2020`. The page size is `50`.

#### bodyFieldToSearch
If you look at a Logic App run at the top, you will see the Trigger. This is very often a HTTP Request call. If you expand the action you will see link to `Show raw outputs` under the Outputs part of the Action. If you click that link the exact payload of the trigger will show on the right side, like this:

```json
{
    "headers": {
        "Accept-Language": "en",
        "User-Agent": "azure-logic-apps/1.0,(workflow 5f96cfd745bd47468b645f50fcc3f723; version 08586185792045278767)",
       ...
        "x-ms-workflow-run-id": "08586102636111028709571538887CU01",
        "x-ms-workflow-run-tracking-id": "62c00f66-3eff-4bf5-90cc-bbf820c5990f",
        "x-ms-workflow-operation-name": "OrderFlow-PROD",
        ...
        "x-ms-workflow-resourcegroup-name": "OrderFlow-PROD-RG",
        ...        
    },
    "body": {
        "CustomerID": 2258,
        "OrderCategory": "C",
        "OrderID": "A-69298",
        "OrderTotalEuro": 45337
    }
}
```
You can find the RunId, the name of the Logic App and other metadata. At the bottom is the BODY as is was sent to the Logic App when it was executed.

In this case the properties are `CustomerID`, `OrderCategory`, `OrderID` and `OrderTotalEuro`. The search only supports searching in fields at the root level. If you where to search for all instances of Customer 2258 you would set

```json
"bodyFieldToSearch": "CustomerID",
"searchList" : [
  "2258"
]
```
Searching for orders `A-1234`, `B-2458` and `B-1212` in a field called `OrderingCustomer` you would create settings like this:

```json
"bodyFieldToSearch": "OrderingCustomer",
"searchList" : [
  "A-1234",
  "B-2458",
  "B-1212"
]
```

### APIs used
If you need additional information on the APIs used in this solution:

To get the trigger history the [Workflow Trigger Histories - List](https://docs.microsoft.com/en-us/rest/api/logic/workflowtriggerhistories/list) api is used.
To get metadata from the trigger, the outputsLink in the trigger history body is used.

## General information on the script
No error handling, what so ever.
The APIs can only return a max number of 250 rows. This limits the script to a max of 250 rows.

# Not suppored - might be coming
- Searching in an Action in a Logic App, not only the trigger.
- More advanced search, not only the root level of the payload.
- Searching the querystring. Currently the call must have been made via POST and a body for the value to be searchable.