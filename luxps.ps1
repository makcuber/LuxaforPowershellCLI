#Dev: Jonathan Brunath
#Contact: mak.programming.labs@gmail.com
#Desc: CLI tool for setting colour of Luxafor LED Status Flag, with option for running as background process that sets colour on screen lock

param([boolean]$verbose)

#The WebHook ID will load from the configPath file defined below, make sure you update this file if you re-generate the ID
$global:luxID = ""

#Duration inbetween Lock status scans
$scanPeriod = 5

#Toggle Console output
$global:echoOn = $verbose

#Config Path defaults to same directory as the script

$configPath = "$PSScriptRoot/luxid.conf"

#Count of how many times an error has looped
$global:errorLoopCount=0

#API info: https://luxafor.com/webhook-api/
$APIurl = @{
    solid = "https://api.luxafor.com/webhook/v1/actions/solid_color" #accepts any colour in colours array
    blink = "https://api.luxafor.com/webhook/v1/actions/blink" #accepts any colour in colours array
    pattern = "https://api.luxafor.com/webhook/v1/actions/pattern" #accepts any pattern in pattern array
}

#Colour Definitions
$lockColour = "red"
$onlineColour = "green"
$busyColour = "blue"

$colours = "red", "green", "yellow", "blue", "white", "cyan", "magenta"
$patterns = "police", "traffic lights", "random 1", "random 2", "random 3", "random 4", "random 5"
$extraWindowsOnlyPatterns = "rainbow", "sea", "white wave", "synthetic"

#Functions
function echoVerbose {
    #Write-Host $global:echoOn
    if ($global:echoOn -eq $true) {
        Write-Host $args[0]
        #return $true
    } else {
        #return $false
    }
}

function verifyLuxID {
    Param([Boolean]$writeID=$false,[string]$testLuxID,[int]$errorLoop)
    if ($testLuxID -eq "") {
        if ($writeID) { 
            Write-Host "Error: No Webhook ID provided"
            $global:errorLoopCount++
            echoVerbose "ErrorLoop: $errorLoop"
            genConfig -error $true
        } else {
            Write-Host "Error: Config file is empty"    
            genConfig
        }
    } else {
        $global:luxID = $testLuxID
    }

    #the errorLoop check prevents the config from being writen multiple times if there was an error getting input from the user
    if ($writeID -and ($errorLoop -eq $errorLoopCount) ) {
        Out-File -FilePath $configPath -InputObject $testLuxID
        Write-Host "Wrote webhook ID to config file" 
        $global:luxID = $testLuxID
    }
    echoVerbose "ErrorLoop: $errorLoop" 
}
function genConfig {
    #get LuxID from user via CLI, write to config file
    Write-Host ""
    Write-Host "Generate a Luxafor webhook ID from the Luxafor app"
    Write-Host "In v2 of the app, this is located under General>Webhook"
    Write-Host ""
    $testLuxID = Read-Host "Enter your Luxafor Webhook ID"
    verifyLuxID -writeID $true -testLuxID $testLuxID -errorLoop $global:errorLoopCount
}
function config {
    Write-Host ""
    if ((Test-Path -Path $configPath) -eq $true) {
        Write-Host "Config file found ($configPath)"
        $testLuxID = $(Get-Content -Path $configPath)
        echoVerbose "Imported LuxID: $testLuxID"

        #add luxID valiation here
        verifyLuxID -testLuxID $testLuxID

        Write-Host "LuxID Set: $($global:luxID)"
        Write-Host ""
    } else {
        Write-Host "Error: No config file found"
        genConfig
    }
}

function validateItem {
    Param($item,$array)
    $isValid = $false

    echoVerbose $item
    foreach ($testItem in $array) {
        if ($testItem -eq $item) {
            echoVerbose "Test Item: $testItem"
            $isValid = $true
            break
        }
    }
    echoVerbose $isValid
    return $isValid
}
function validateColour {
	[alias("validateColor")]
	Param([Alias("color")][string]$colour)
    return $(validateItem -item $colour -array $colours)
}
function validatePattern {
    Param([string]$pattern)
    return $(validateItem -item $pattern -array $patterns)
}
function listArray {
    Param($array)
    foreach ($item in $array) {
        Write-Host " - $item"
    }
    Write-Host ""
}
function listColours {
	[alias("listColors")]
	Param()
    listArray -array $colours
}
function listPatterns {
    listArray -array $patterns
}
function setColour {
    [alias("setColor")]
	Param([Alias("color")][string]$colour)
    
    if ((validateColour -colour $colour) -eq $true) {
        $jsonData = @{
            userId = "$global:luxID" #must be in quotes
            actionFields = @{ color = "$colour" }
        } | ConvertTo-Json
        
        $params = @{
            Uri         = $APIurl['solid']
            Method      = 'POST'
            Body        = $jsonData #already in json format
            ContentType = 'application/json'
        }

        $result=Invoke-RestMethod @params -UseDefaultCredentials
    } else {
        Write-Host "Error: Invalid Colour ($colour)"
        Write-Host "Valid colours are: "
        listColours
    }
}

function setCustomColour {
   [alias("setCustomColor")]
	Param([Alias("color")][string]$colour)
    $regex = $colour -Match '^[\d|A-Z|a-z]{6}$'
    if (($regex) -and $colour) {
        $jsonData = @{
            userId = "$global:luxID" #must be in qoutes
            actionFields = @{
				color = "custom"
				custom_color = $colour
			}
        } | ConvertTo-Json
        
        $params = @{
            Uri         = $APIurl['solid']
            Method      = 'POST'
            Body        = $jsonData #already in json format
            ContentType = 'application/json'
        }
        $result=Invoke-RestMethod @params -UseDefaultCredentials
	} else {
        Write-Host "Error: Invalid Custom Colour ($colour)"
        Write-Host "Valid colours are 6 symbol hex color codes."
    }
}

function setOff {
        $jsonData = @{
            userId = "$global:luxID" #must be in qoutes
            actionFields = @{
				color = "custom"
				custom_color = "000000"
			}
        } | ConvertTo-Json
        
        $params = @{
            Uri         = $APIurl['solid']
            Method      = 'POST'
            Body        = $jsonData #already in json format
            ContentType = 'application/json'
        }

        $result=Invoke-RestMethod @params -UseDefaultCredentials
}

function setBlink {
	Param([Alias("color")][string]$colour)

    if ((validateColour -colour $colour) -eq $true) {
        $jsonData = @{
            userId = "$global:luxID" #must be in qoutes
            actionFields = @{ color = $colour }
        } | ConvertTo-Json

        $params = @{
            Uri         = $APIurl['blink']
            Method      = 'POST'
            Body        = $jsonData #already in json format
            ContentType = 'application/json'
        }

        $result=Invoke-RestMethod @params -UseDefaultCredentials
    } else {
        Write-Host "Error: Invalid Colour ($colour)"
        Write-Host ""
        Write-Host "Valid colours are: "
        listColours
    }
}
function setPattern {
    Param([string]$pattern)

    if ((validatePattern -pattern $pattern) -eq $true) {
        $jsonData = @{
            userId = "$global:luxID" #must be in qoutes
            actionFields = @{ pattern = $pattern }
        } | ConvertTo-Json

        $params = @{
            Uri         = $APIurl['pattern']
            Method      = 'POST'
            Body        = $jsonData #already in json format
            ContentType = 'application/json'
        }

        $result=Invoke-RestMethod @params -UseDefaultCredentials
    } else {
        Write-Host "Error: Invalid pattern $pattern"
        Write-Host ""
        Write-Host "Valid paterns are: "
        listPatterns
    }
}    
function serviceMode {
    $onlineLock = $false
    echoVerbose "scanPeriod: $scanPeriod"
    while ($true)
    {
        start-sleep $scanPeriod
        
        $currentuser = gwmi -Class win32_computersystem | select -ExpandProperty username
        $process = get-process logonui -ea silentlycontinue
        $lockState = ($currentuser -and $process)
        Write-Host "LockState: $lockState"

        if ($lockState -eq $true) {
            $onlineLock = $false
            setColour -colour $lockColour
        } else {
            if ($onlineLock -eq $false) {
                setColour -colour $onlineColour
                $onlineLock = $true
            }
        }
        echoVerbose "OnlineLock: $onlineLock"
        echoVerbose ""
    }
}
function showHelp {
    Write-Host ""
    Write-Host "Help Menu"
    Write-Host "---------"
    Write-Host ""
    Write-Host "NOTE: You must manually set the correct WebHook LuxID in this script before running"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host " -off  : Turn off flag colour"
    Write-Host " -colour <colour>  :  Set a specific colour"
    Write-Host " -customcolour <colour>  :  Set a custom colour by hex value"
    Write-Host " -blink <colour>   :  Trigger a blink event to a specific colour"
    Write-Host " -pattern <pattern>:  Trigger a pattern event"
    Write-Host " -service          :  Enable service mode that changes the colour based on the machines Screen Lock state"
    Write-Host ""
}

#Main
#if ($verbose.GetType().FullName -eq "System.Boolean") {
#    $global:echoOn = $verbose
#    Write-Host $verbose
#    echoVerbose "Verbose: $global:echoOn"
#}
echoVerbose "echoOn: $global:echoOn"
echoVerbose "Args: $args"
echoVerbose ""

config

switch ($args[0]) {
    -off { setOff; break }
    -colour { setColour -colour $args[1]; break }
    -customcolour { setCustomcolour -colour $args[1]; break }
    -blink { setBlink -colour $args[1]; break }
    -pattern { setPattern -pattern $args[1]; break }
    -service { serviceMode; break }
    -help { showHelp; break}
    default { showHelp; break}
}
