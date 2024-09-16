# ExtractLogicAppsTracking

A PowerShell script to help you find Logic Apps executions without tracking configured. Use PowerShell version 7+

## Tracking in Logic Apps

You **can** and _should_ configure Logic Apps to send data to Log Analytics, and if you are setting up a new flow you should consider what to track.

## How does this help?

Logic Apps tracks all information for an execution, which is great. Now, you only have to find the execution. If your Logic App runs 5 times a day, that is not a problem, but if it runs 50 000 times a day you do not want to look into each and everyone to find that missing order.

## How does this work?

Logic Apps exposes APIs and this PS script calls these APIs to get Trigger history (script only works on data in triggers for now), it gets the execution information of that trigger and search for what you need in the tracked information. If the execution is found, the run ID and metadata is saved to disk. You can then easily get the run ID from the file and search for it in the portal.

## What you have to do

Update the settingsfile with information on what you need to search for, you hit enter and then you wait.

## The files

**AzureSettings.json** Contains information on where you want to search, and what to search for.

**SearchTriggers.ps1** The PowerShell Script. It uses the settings from AzureSettings.json which must be in the same folder.

# Documentation

More information can be found in the [here](Documentation.md)