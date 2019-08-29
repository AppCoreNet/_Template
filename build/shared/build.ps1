[CmdletBinding()]
param (
  [Parameter(ValueFromRemainingArguments=$True)]
  [string[]] $Arguments
)

$ErrorActionPreference = "Stop"

$ToolsPath = Join-Path $PSScriptRoot "build" -Resolve | Join-Path -ChildPath "tools"
$Cake = Join-Path $ToolsPath "dotnet-cake"
$CakeVersion = "0.34.1"
$CakeArgs = @("--paths_tools=$ToolsPath")

function Exec {
  param ([ScriptBlock] $ScriptBlock)
  & $ScriptBlock
  If ($LASTEXITCODE -ne 0) {
    Write-Error "Execution failed with exit code $LASTEXITCODE"
  }
}

# dotnet tool fails on hosted macOS agent
# https://github.com/dotnet/cli/issues/9114
If ($IsMacOS) {
  $env:DOTNET_ROOT="$(dirname "$(readlink "$(command -v dotnet)")")"
  Write-Host $env:DOTNET_ROOT
}

# bootstrap cake
If (!(Test-Path "$ToolsPath/.store/cake.tool")) {
  Exec { & dotnet tool install --tool-path $ToolsPath Cake.Tool --version $CakeVersion }
  Exec { & $Cake @CakeArgs --bootstrap }
}

# build
Exec { & $Cake @CakeArgs @Arguments }
