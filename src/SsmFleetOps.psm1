Set-StrictMode -Version Latest

# =============================================================================
# ## Get-FleetInstances
#
# **Purpose**
# Return a list of target machines (“fleet”) based on a tag filter.
#
# **How it works (Mock mode)**
# - Reads `mocks/instance-data.json`
# - Filters to:
#   - instances where `tags.<TagKey> == <TagValue>`
#   - AND `ssmManaged == true` (only “managed” instances)
#
# **Inputs**
# - Mode: `Mock` or `Aws`
# - TagKey / TagValue: used to filter instance tags
# - MockPath: optional path to mock JSON file
#
# **Output**
# - Returns objects representing instances (instanceId, hostname, platform, tags, etc.)
#
# **Why it matters**
# Fleet ops always starts with *target selection*. This makes targeting repeatable.
# =============================================================================
function Get-FleetInstances {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('Mock','Aws')]
    [string]$Mode,

    [Parameter(Mandatory)]
    [string]$TagKey,

    [Parameter(Mandatory)]
    [string]$TagValue,

    [string]$MockPath = (Join-Path $PSScriptRoot '..\mocks\instance-data.json')
  )

  if ($Mode -eq 'Mock') {
    if (-not (Test-Path $MockPath)) { throw "Mock file not found: $MockPath" }
    $data = Get-Content $MockPath -Raw | ConvertFrom-Json
    return $data.instances | Where-Object { $_.tags.$TagKey -eq $TagValue -and $_.ssmManaged -eq $true }
  }

  throw "AWS mode not configured in this environment. See README 'AWS Mode' section."
}

# =============================================================================
# ## Invoke-FleetCommand
#
# **Purpose**
# Execute a remote command set against the selected fleet.
#
# **What this represents in real AWS**
# - In AWS mode, this would call SSM Run Command (SendCommand) using:
#   - a DocumentName (e.g., AWS-RunPowerShellScript or AWS-RunShellScript)
#   - target selection (often tags)
#   - the command list to run remotely
#
# **How it works (Mock mode)**
# - Does NOT actually execute commands
# - Returns a structured object that *looks like* a real “command invocation”
# - Uses a deterministic CommandId (`mock-0001`) so results can be fetched later
#
# **Inputs**
# - Commands: array of command strings
# - DocumentName: SSM document to run (default: AWS-RunPowerShellScript)
# - Comment: free text for audit/tracking
#
# **Output**
# - Returns an object containing:
#   - CommandId, DocumentName, Comment, Targets, Commands
#
# **Why it matters**
# This is the “action” step: run the operation consistently and track it.
# =============================================================================
function Invoke-FleetCommand {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('Mock','Aws')]
    [string]$Mode,

    [Parameter(Mandatory)]
    [string]$TagKey,

    [Parameter(Mandatory)]
    [string]$TagValue,

    [Parameter(Mandatory)]
    [string[]]$Commands,

    [string]$DocumentName = 'AWS-RunPowerShellScript',
    [string]$Comment = ''
  )

  if ($Mode -eq 'Mock') {
    return [pscustomobject]@{
      CommandId = 'mock-0001'
      DocumentName = $DocumentName
      Comment = $Comment
      Targets = @(@{ Key=$TagKey; Values=@($TagValue) })
      Commands = $Commands
    }
  }

  throw "AWS mode not configured in this environment. See README 'AWS Mode' section."
}

# =============================================================================
# ## Get-CommandResults
#
# **Purpose**
# Retrieve command results for each instance and export them for auditing/reporting.
#
# **How it works (Mock mode)**
# - Reads `mocks/command-results.json`
# - Filters results where `commandId == <CommandId>`
# - Writes outputs into `reports/`:
#   - Always writes JSON: `reports/<CommandId>.json`
#   - Optionally writes CSV: `reports/<CommandId>.csv`
#
# **Inputs**
# - CommandId: the command execution identifier (mock or real)
# - ExportFormat: Json or Csv
# - ReportsDir: where artifacts are saved
# - MockResultsPath: optional path to mock results JSON
#
# **Output**
# - Returns an object describing what was exported:
#   - Json path, optional Csv path, and count of result rows
#
# **Why it matters**
# Fleet ops must be auditable. Exported artifacts make outcomes reviewable and shareable.
# =============================================================================
function Get-CommandResults {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateSet('Mock','Aws')]
    [string]$Mode,

    [Parameter(Mandatory)]
    [string]$CommandId,

    [ValidateSet('Json','Csv')]
    [string]$ExportFormat = 'Json',

    [string]$ReportsDir = (Join-Path $PSScriptRoot '..\reports'),
    [string]$MockResultsPath = (Join-Path $PSScriptRoot '..\mocks\command-results.json')
  )

  if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir | Out-Null
  }

  if ($Mode -eq 'Mock') {
    if (-not (Test-Path $MockResultsPath)) { throw "Mock file not found: $MockResultsPath" }
    $data = Get-Content $MockResultsPath -Raw | ConvertFrom-Json

    $results = $data.results | Where-Object { $_.commandId -eq $CommandId }
    if (-not $results) { throw "No mock results found for CommandId: $CommandId" }

    $jsonOut = Join-Path $ReportsDir "$CommandId.json"
    $results | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonOut -Encoding utf8

    if ($ExportFormat -eq 'Csv') {
      $csvOut = Join-Path $ReportsDir "$CommandId.csv"
      $results |
        Select-Object commandId, instanceId, status, responseCode, stdout, stderr, startTime, endTime |
        Export-Csv -NoTypeInformation -Path $csvOut -Encoding utf8

      return [pscustomobject]@{ Json=$jsonOut; Csv=$csvOut; Count=$results.Count }
    }

    return [pscustomobject]@{ Json=$jsonOut; Count=$results.Count }
  }

  throw "AWS mode not configured in this environment. See README 'AWS Mode' section."
}

# =============================================================================
# ## Export-ModuleMember
#
# **Purpose**
# Controls what functions are publicly available when someone imports this module.
#
# **Why it matters**
# - Keeps the public surface area intentional
# - Prevents exposing helper/private functions (if you add them later)
# =============================================================================
Export-ModuleMember -Function Get-FleetInstances, Invoke-FleetCommand, Get-CommandResults
