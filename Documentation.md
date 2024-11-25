# Short walkthru

If you think you know this, this is the TLDR;

- Create a copy of the AzureSettings.json file and name it `myAzureSettings.json` (important)
- Update information in the settings-file.
- The setting bodyFieldToSearch is the name of the trigger body property you wish to search. Only first level properies are supported.
- The searchlist is an array of all the values you wish to match.
- Run the SeachTriggers.ps1 and watch it work.
- A search-hit will save a file to a folder in the same directory.
- The name of the file is the body level property and the Logic App RunID.

# Documentation

## Login To Azure

You have to use a user account that has rights to read trigger history of the Logic App you are interested in. The script will open up a web browser and use the token returned by Azure.

## Understanding the settings

In order to make the script work you should create a copy of the `AzureSettings.json` file and name it `myAzureSettings.json`. This makes sure your settings are not commited to the GIT repo as this file is the .gitignore file. The name is also hardcoded into the PS script.

There are several parts of the file.

### Logic App Info

This part is used in the API-calls to get data from the right Logic App.

- `subscriptionId`: The ID of the subscription the Logic App is located in.
- `resourceGroup`: The name of the resource group the Logic App is located in.
- `workFlowName`: The name of the Logic App you want to search triggers for.
- `triggerName`: The name of the trigger. Use `request` (or sometimes `manual`) for a HTTP-based trigger. For others, look in the trigger history for the trigger name. It is in the `Workflow URL` field.
- `bodyFieldToSearch`: The name of the JSON property you want to search in, in the trigger body. More info below.
- `maxNumberItemPerCall`: The number of items (runs) you want to get per call. The API will send back a maximum of 250 items. This number is somtimes called page size. A large number speeds up the process, but might have a negative impact on memory and CPU. My suggestion is that you use a large number.
- `searchFromDateTime`: To limit the number of runs you search thru you must set a time frame. This value is the 'from'. Runs must have executed after this value. The script is configured to follow the ISO standard of `yyyy-MM-ddTHH:mm:ssZ` and the time sent to the API must be in UTC timezone.
- `searchToDateTime`: The same restrictions apply as for `searchFromDateTime`. This must be larger than the FromDate.
- `searchlist`: This is a json string array of the values you want to look for. I think it works for integers as well.

Configured correctly, this part should look similar to this

```json
"subscriptionId" : "782ebdc9-e486-42d8-95fb-111444888222",
"resourceGroup" : "OrderFlow-PROD-RG",
"workFlowName" : "OrderFlow-PROD",
"bodyFieldToSearch" : "OrderId",
"maxNumberItemPerCall" : 50,
"searchFromDateTime" : "2024-09-05T00:00:00Z",
"searchToDateTime" : "2024-09-05T23:59:59Z",
"searchList" : [
  "A-41105"
]
```

This looks in for order number `A-41105` in the `OrderId` field for all executions of `OrderFlow-PROD` on the `9th of Seåtember 2024`. The page size is `50`.

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

### New from September 24

You can now also do a full string search of the value in a body property. If, for instance, you have a property called `payload` and the value of the payload is an XML-document, you can search that XML-document for any value.

Searching for the invoice ID `ABC1234` in an XML-document inside a property called `payload` results in this configuration:

```json
"bodyFieldToSearch": "payload",
"searchList" : [
  "ABC1234"
]
```

### New from October 24

If you do not have any properties in the body and want to search the body property, just set the `bodyFieldToSearch` to an empty string.

```json
"bodyFieldToSearch": "",
"searchList" : [
  "ABC1234"
]
```

### New from December 24

The start time and the client tracking ID is now part of the output file.

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