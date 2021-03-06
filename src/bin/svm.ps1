param (
  [parameter(Position=0)]
  [string] $command,
  [alias("a")][switch] $active = $false,
  [alias("l")][switch] $list = $false,
  [alias("f")][string] $from = "",
  [parameter(Position=1, ValueFromRemainingArguments=$true)]
  [string[]]$scriptArgs=@()
)

$scriptPath = $myInvocation.MyCommand.Definition

#$svmVersion = "{{VERSION}}"
$svmVersion = "0.1.0"
$svmPath = $env:USERPROFILE + "\.svm"
$versionsPath = $svmPath + "\versions\"
$versionFilePath = $svmPath + "\version"

#
# helper functions
#
function Info-Message 
{
  param (
  	[string] $message
  )
  Write-Host $("{0}" -f " $message ")
}

function Error-Message
{
  param (
  	[string] $message
  )
  Write-Host $("{0}" -f " $message ") -BackgroundColor DarkRed -ForegroundColor White
}

function Get-ActiveVersion 
{
  if (!(Test-Path $versionFilePath)) 
  {
    Error-Message "The version file cannot be found at '$($versionFilePath)'."
	  return [String]::Empty
  }
  
  $activeVersion = Get-Content $versionFilePath
  return $activeVersion.Trim()
}

function Get-InstalledVersions 
{
  $versions = @();
  
  if (!(Test-Path $versionsPath)) 
  {
    Error-Message "The versions folder cannot be found at '$($versionsPath)'."
	  return $versions
  }
  
  $activeVersion = Get-ActiveVersion  
  $versions = Get-ChildItem $versionsPath | Find-Version $activeVersion
  return $versions 
}

function Find-Version 
{
  param(
    [string] $activeVersion
  )
  
  $active = $false
  if ($_.Name -eq $activeVersion) 
  {
    $active = $true
  }
  $version = New-Object PSObject -Property @{
    Active = if ($active) { $true } else { $false }
	  Version = $_.Name
    Location = $_.FullName
  }
  return $version
}

function Confirm-Elevation
{
    $user = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $elevated = $user.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    return -NOT $elevated
}

#
# svm commands
#
function Get-SvmHelp 
{
$helpMessage = @"
 USAGE: svm <command> [options]
  
  svm install <version>
    install scriptcs version indicated by <version>
    examples:  
    > svm install 0.10.0
    > svm install 0.10.1

  svm install <version> -from <path>
    install scriptcs version from local path <path> as version <version>
    examples:  
    > svm install mybuild -from C:\scriptcs\bin\Debug

  svm install <-l|-list>
    list the scriptcs versions avaiable to install
    examples: 
    > svm install -l

  svm remove <version>
    remove installed scriptcs version indicated by <version>
    examples:
    > svm remove 0.9.0

  svm list [-a|-active]
    list the installed scriptcs versions
    -a|-active       list the active version
    examples:
    > svm list
    > svm list -a

  svm use <version>
    use the installed scriptcs version indicated by <version>
    examples:
    > svm use 0.10.0
	
"@
  Info-Message $helpMessage
}

function Get-SvmInstalled
{
  Error-Message "svm install <-l|-list> - not yet implemented ..."
}

function Install-SvmFrom
{
  param(
    [string] $version,
    [string] $path
  )
  Error-Message "svm install <version> -from <path> - not yet implemented ..."
}

function Install-Svm
{
  param(
    [string] $version
  )
  
  Error-Message "svm install <version> - not yet implemented ..."
}

function Install-Svm
{
  param(
    [string] $version
  )
  
  $version = $version.Trim()
  $versions = Get-InstalledVersions
  $versionToRemove = $versions |? { $_.Version -eq $version }
  
  if ($versionToRemove)
  {
		Remove-Item $versionToRemove.Location -Recurse -ErrorAction SilentlyContinue
		Info-Message "The scriptcs version '$($version)' has been removed from versions folder '$($versionsPath)'."	
		  
		$newActiveVersion = $versions |? { $_.Version -ne $version } | select -First 1
		if ($newActiveVersion -ne $null) 
		{
		  Set-Content -Path $versionFilePath -Force "$($newActiveVersion[0].Version)"
		  Info-Message "The active scriptcs version has been set to '$($newActiveVersion[0].Version)'."
		}
		else
		{
		  Set-Content -Path $versionFilePath -Force "__NO_ACTIVE_VERSION__"
		  Info-Message "No scriptcs versions left installed."
		}	
  }
  else
  {
    Info-Message "No scriptcs version $version available to remove."
  }
}

function Get-ActiveSvm
{
  $versions = Get-InstalledVersions 
  $activeVersion = $versions |? { $_.Active }
  if ($activeVersion -eq $null -and $versions.Count -gt 1)
  {
    Info-Message "No active scriptcs version found."
    Info-Message "`n Consider using svm use <version> to set the active scriptcs version."
  }
  elseif ($activeVersion -eq $null -and $versions.Count -eq 0)
  {
    Info-Message "No scriptcs versions found."
    Info-Message "`n Consider using svm install <version> to install a scriptcs version."
  }
  else
  {
    Info-Message "The following is the active scriptcs version:`n"
    Info-Message $("  {0}" -f $activeVersion.Version)
  }
}

function Get-InstalledSvm
{
  $versions = Get-InstalledVersions
    
	if ($versions.Count -eq 0)
	{
	  Info-Message "No scriptcs versions found."
	  Info-Message "`n Consider using svm install <version> to install a scriptcs version."
	}
	else
	{
	  Info-Message "The following scriptcs versions are installed:`n"
      $versions |% {
	    Info-Message $("  {0,1}  {1}" -f $(if ($_.Active) { "*" } else { " " }), $_.Version)
	  }
	}
}

function Use-Svm 
{
  param(
    [string] $version
  )
  
  $version = $version.Trim()
  $versions = Get-InstalledVersions
  if ($versions.Version -notcontains $version) 
  {
    Error-Message "Version '$($version)' cannot be found in versions folder '$($versionsPath)'."	
    Info-Message "`n Consider using svm install <version> to install the scriptcs version."
	  return
  }
  
  Set-Content -Path $versionFilePath -Force "$version"
  Info-Message "Active scriptcs version set to '$($version)'."
}

#
# command switching
# 
function Parse-Command
{
  $parsedCommand = [String]::Empty
  
  if ($command -eq "install")
  {
    if (-not $active -and -not $list -and [String]::IsNullOrEmpty($from) -and $scriptArgs.Count -eq 1)
    { $parsedCommand = "install <version>" }
    if (-not $active -and -not $list -and -not [String]::IsNullOrEmpty($from) -and $scriptArgs.Count -eq 1)
    { $parsedCommand = "install <version> -from <path>" }
    if (-not $active -and $list -and [String]::IsNullOrEmpty($from) -and $scriptArgs.Count -eq 0)
    { $parsedCommand = "install -list" }
  }
  elseif ($command -eq "remove")
  {
    if (-not $active -and -not $list -and [String]::IsNullOrEmpty($from) -and $scriptArgs.Count -eq 1)
    { $parsedCommand = "remove <version>" }
  }
  elseif ($command -eq "list")
  {
    if (-not $active -and -not $list -and [String]::IsNullOrEmpty($from) -and $scriptArgs.Count -eq 0)
    { $parsedCommand = "list" }
    elseif ($active)
    { $parsedCommand = "list -active" }
  }
  elseif ($command -eq "use")
  {
    if (-not $active -and -not $list -and [String]::IsNullOrEmpty($from) -and $scriptArgs.Count -eq 1)
    { $parsedCommand = "use <version>" }
  }
  elseif ($command -eq "help")
  {
    if (-not $active -and -not $list -and [String]::IsNullOrEmpty($from) -and $scriptArgs.Count -eq 0)
    { $parsedCommand = "help" }
  }
  
  return $parsedCommand
}

try 
{
  Write-Host "`n scriptcs version manager - $svmVersion `n" -BackgroundColor DarkGray -ForegroundColor Black

  $parsedCommand = Parse-Command
  switch ($parsedCommand) 
  {	  
	  "install <version>"               {Install-Svm $scriptArgs[0]}
	  "install <version> -from <path>"  {Install-SvmFrom $scriptArgs[0] $from}
    "install -list"                   {Get-SvmInstalled}
	  "remove <version>"                {Install-Svm $scriptArgs[0]}
	  "list"         	                  {Get-InstalledSvm}
    "list -active"                    {Get-ActiveSvm}
	  "use <version>"                   {Use-Svm $scriptArgs[0]}
	  "help"                            {Get-SvmHelp}
	  default                           {Get-SvmHelp}
  }
}
catch 
{
  Error-Message $_
}
