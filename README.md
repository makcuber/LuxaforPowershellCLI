# LuxaforPowershellCLI
A Powershell CLI script for controlling a Luxafor LED Status Flag using the Luxafor WebHook REST API

WebHook API information is available on the Luxafor website: https://luxafor.com/webhook-api/

Installation
------------
1. Install the official Luxafore app for Windows 10 (https://luxafor.com/download/)
2. Clone the repo to your local machine
3. Generate a WebHook in the Luxafor app and copy it to the luxps.ps1 script in the repo
4. Run the script using the parameters outlined below

Help Menu
---------
 
NOTE: You must manually set the correct WebHook LuxID in this script before running

Parameters:

-colour <colour>  :  Set a specific colour
 
-blink <colour>   :  Trigger a blink event to a specific colour
 
-pattern <pattern>:  Trigger a pattern event

-service          :  Enable service mode that changes the colour based on the machines Screen Lock state
