param(
  [string[]]$Monkey = @("all"),
  [ValidateSet("interactive","automatic","report")]
  [string]$Mode = "interactive"
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $PSCommandPath
$ReportDir = Join-Path $ScriptDir "reports"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ReportFile = Join-Path $ReportDir ("chaos-report-" + $Timestamp + ".md")
$LogFile = Join-Path $ReportDir ("chaos-" + $Timestamp + ".log")

if (-not (Test-Path $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null }

function CreateEmptyFile { param([string]$p) New-Item -ItemType File -Path $p -Force | Out-Null }
CreateEmptyFile $LogFile
CreateEmptyFile $ReportFile

function Log { param([string]$M, [string]$C="White") Write-Host ("[" + (Get-Date -Format "HH:mm:ss") + "] $M") -ForegroundColor $C; Add-Content -Path $LogFile -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] $M") }
function Info  { param([string]$M) Log "[INFO] $M" Blue }
function Ok    { param([string]$M) Log "[OK] $M" Green }
function Warn  { param([string]$M) Log "[WARN] $M" Yellow }
function Err   { param([string]$M) Log "[ERR] $M" Red }
function Step  { param([string]$M) $line = ("=" * 50); Write-Host "" -NoNewline; Write-Host $line -ForegroundColor Cyan; Write-Host ("  " + $M) -ForegroundColor Cyan; Write-Host $line -ForegroundColor Cyan }

function ContainerId { param([string]$N) docker ps --filter ("name=" + $N) --format "{{.ID}}" | Select-Object -First 1 }

function ShouldRun {
  param([string]$Message)
  if ($Mode -eq "automatic") { return $true }
  if ($Mode -eq "report") { Warn ("[DRY-RUN] Would: " + $Message); return $false }
  $response = Read-Host ("? " + $Message + " [y/N]")
  return ($response -match "^[yYsS]")
}

# -------------------------------------------------------
# CHAOS MONKEY
# -------------------------------------------------------
function Invoke-ChaosMonkey {
  Step "CHAOS MONKEY"

  $running = docker ps --format "{{.Names}}" | Where-Object { $_ -match "educonnect" }
  $count = ($running | Measure-Object).Count
  Info ("Running containers: " + $count)

  $toKill = [Math]::Max(1, [Math]::Floor($count * 30 / 100))
  $targets = $running | Get-Random -Count $toKill

  foreach ($target in $targets) {
    Info ("Killing: " + $target)
    if (ShouldRun ("Kill " + $target + "?")) {
      docker kill $target 2>$null | Out-Null
      Ok ("Killed: " + $target)
      Add-Content -Path $ReportFile -Value ("- Killed " + $target)
    }
  }

  Step "Observing system..."
  Start-Sleep -Seconds 3
  $alive = docker ps --format "{{.Names}}" | Where-Object { $_ -match "educonnect" }
  Info ("Surviving: " + (($alive | Measure-Object).Count))
}

# -------------------------------------------------------
# DOCTOR MONKEY
# -------------------------------------------------------
function Invoke-DoctorMonkey {
  Step "DOCTOR MONKEY"

  $containers = docker ps --format "{{.Names}}" | Where-Object { $_ -match "educonnect" }
  foreach ($c in $containers) {
    $health = docker inspect $c --format "{{.State.Health.Status}}" 2>$null
    if ($health -eq "unhealthy") { Err ("Unhealthy: " + $c) }
    elseif ($health -eq "healthy") { Ok ("Healthy: " + $c) }

    $restarts = docker inspect $c --format "{{.RestartCount}}" 2>$null
    if ([int]$restarts -gt 0) { Warn ($c + " restarted " + $restarts + " times") }
  }

  Step "Resource Usage"
  foreach ($c in $containers) {
    $stats = docker stats $c --no-stream --format "{{.CPUPerc}}|{{.MemPerc}}" 2>$null
    if ($stats) {
      $parts = $stats -split '\|'
      $cpu = [int]($parts[0] -replace '%','')
      $mem = [int]($parts[1] -replace '%','')
      if ($cpu -gt 80) { Warn ($c + ": CPU " + $cpu + "%") }
      if ($mem -gt 80) { Warn ($c + ": MEM " + $mem + "%") }
    }
  }
}

# -------------------------------------------------------
# GORILLA MONKEY
# -------------------------------------------------------
function Invoke-GorillaMonkey {
  param([string]$Group = "mysql")
  Step "GORILLA MONKEY"

  $groups = @{ mysql = @("mysql-user","mysql-content","mysql-sync","mysql-analytics","mysql-reports") }
  $groups.redis = @("redis")
  $groups.ai = @("ollama","ms-06-ai")
  $groups.frontend = @("frontend","api-gateway")

  $targets = $groups[$Group]
  if (-not $targets) { Err ("Unknown group: " + $Group); return }

  Info ("Taking down group: " + $Group)
  foreach ($t in $targets) {
    $cid = ContainerId $t
    if ($cid) {
      if (ShouldRun ("Kill " + $t + "?")) {
        docker kill $cid 2>$null | Out-Null
        Ok ("Killed: " + $t)
      }
    }
  }
  Start-Sleep -Seconds 3
  Info ("Restoring " + $Group + "...")
  foreach ($t in $targets) {
    docker compose -p "educonnect" up -d $t 2>$null
  }
}

# -------------------------------------------------------
# CONFORMITY MONKEY
# -------------------------------------------------------
function Invoke-ConformityMonkey {
  Step "CONFORMITY MONKEY"

  $services = docker compose -p "educonnect" ps --services 2>$null
  foreach ($svc in $services) {
    $cid = docker ps --filter ("name=" + $svc) --format "{{.ID}}" | Select-Object -First 1
    if (-not $cid) { continue }
    $policy = docker inspect $cid --format "{{.HostConfig.RestartPolicy.Name}}" 2>$null
    if ($policy -notin "unless-stopped","always") {
      Warn ($svc + " restart policy is " + $policy)
    }
  }
  Ok "Conformity check complete"
}

# -------------------------------------------------------
# SECURITY MONKEY
# -------------------------------------------------------
function Invoke-SecurityMonkey {
  Step "SECURITY MONKEY"

  $containers = docker ps --format "{{.Names}}" | Where-Object { $_ -match "educonnect" }
  foreach ($c in $containers) {
    $ports = docker port $c 2>$null
    if ($ports) {
      foreach ($p in $ports) {
        if ($p -match "0\.0\.0\.0") { Warn ($c + " exposes port globally: " + $p) }
      }
    }
    $user = docker inspect $c --format "{{.Config.User}}" 2>$null
    if ([string]::IsNullOrEmpty($user) -or $user -eq "root") { Warn ($c + " runs as root") }
  }
}

# -------------------------------------------------------
# JANITOR MONKEY
# -------------------------------------------------------
function Invoke-JanitorMonkey {
  Step "JANITOR MONKEY"

  $exitedList = docker ps -a -q --filter "status=exited"
  $exitedCount = 0; if ($exitedList) { $exitedCount = @($exitedList).Count }
  if ($exitedCount -gt 0) {
    Info ("Found " + $exitedCount + " exited containers")
    if (ShouldRun ("Remove " + $exitedCount + " exited containers?")) {
      docker container prune -f 2>$null | Out-Null
      Ok ("Removed " + $exitedCount + " containers")
    }
  }

  $danglingList = docker images -q -f "dangling=true"
  $danglingCount = 0; if ($danglingList) { $danglingCount = @($danglingList).Count }
  if ($danglingCount -gt 0) {
    Info ("Found " + $danglingCount + " dangling images")
    if (ShouldRun ("Remove " + $danglingCount + " dangling images?")) {
      docker image prune -f 2>$null | Out-Null
      Ok ("Removed " + $danglingCount + " images")
    }
  }
}

# =======================================================
# MAIN
# =======================================================
Write-Host ("=" * 54) -ForegroundColor Magenta
Write-Host "   EDUCONNECT CHAOS ENGINEERING TOOLKIT" -ForegroundColor Magenta
Write-Host ("=" * 54) -ForegroundColor Magenta
Write-Host ("> Mode:    " + $Mode) -ForegroundColor White
Write-Host ("> Report:  " + $ReportFile) -ForegroundColor White
Write-Host ("> Log:     " + $LogFile) -ForegroundColor White
Write-Host ""

Add-Content -Path $ReportFile -Value ("# Chaos Engineering Report")
Add-Content -Path $ReportFile -Value ("")
Add-Content -Path $ReportFile -Value ("**Date:** " + (Get-Date))
Add-Content -Path $ReportFile -Value ("**Mode:** " + $Mode)
Add-Content -Path $ReportFile -Value ("**Platform:** Windows (PowerShell)")
Add-Content -Path $ReportFile -Value ("")

$monkeysToRun = @()
if (($Monkey -eq "all") -or ($Monkey -contains "all")) {
  $monkeysToRun = @("chaos","doctor","gorilla","conformity","security","janitor")
} else {
  $monkeysToRun = $Monkey
}

foreach ($m in $monkeysToRun) {
  switch ($m) {
    "chaos"      { Invoke-ChaosMonkey }
    "doctor"     { Invoke-DoctorMonkey }
    "gorilla"    { Invoke-GorillaMonkey }
    "conformity" { Invoke-ConformityMonkey }
    "security"   { Invoke-SecurityMonkey }
    "janitor"    { Invoke-JanitorMonkey }
    default      { Warn ("Unknown monkey: " + $m) }
  }
}

Write-Host ""
Write-Host "Chaos Engineering run complete." -ForegroundColor Green
Write-Host ("   Report: " + $ReportFile) -ForegroundColor White

