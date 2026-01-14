# Distributed Task Orchestrator - Initialization Script
# This script creates a new isolated task directory with all necessary structure

param(
    [string]$Slug = "",              # Optional semantic identifier (e.g., "code-review", "security-scan")
    [string]$Description = "",       # Task description
    [string]$Request = "",           # User's original request
    [string[]]$Agents = @(),
    [string[]]$TaskNames = @(),
    [int]$TaskCount = 3,
    [switch]$Force = $false          # Force overwrite if task ID exists
)

# Function to generate unique task ID
function Get-NextTaskNumber {
    param([string]$TasksDir)

    if ([string]::IsNullOrEmpty($TasksDir) -or -not (Test-Path $TasksDir)) {
        return 1
    }

    $max = 0
    Get-ChildItem -Path $TasksDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -match '^(?<n>\d{3})-') {
            $n = [int]$matches['n']
            if ($n -gt $max) { $max = $n }
        }
    }

    return ($max + 1)
}

function New-TaskId {
    param(
        [string]$Slug = "",
        [string]$Description = "",
        [string]$TasksDir = "",
        [switch]$Force
    )

    $nameSource = if ($Slug) { $Slug } elseif ($Description) { $Description } else { "task" }
    $clean = (($nameSource -replace '[^\p{L}\p{N}-]+', '-') -replace '(^-+|-+$)', '')
    if ([string]::IsNullOrEmpty($clean)) {
        $clean = "task"
    }

    $seq = if ($Force -or [string]::IsNullOrEmpty($TasksDir)) { 1 } else { Get-NextTaskNumber -TasksDir $TasksDir }
    $seqText = "{0:D3}" -f $seq
    $baseId = "$seqText-$clean"

    if ($Force -or [string]::IsNullOrEmpty($TasksDir)) {
        return $baseId
    }

    $candidateId = $baseId
    $i = 2
    while (Test-Path (Join-Path $TasksDir $candidateId)) {
        $candidateId = "$baseId-$i"
        $i++
    }

    return $candidateId
}

# Function to validate slug
function Test-Slug {
    param([string]$Slug)

    if ([string]::IsNullOrEmpty($Slug)) {
        return $true
    }

    # Check if slug contains only valid characters
    return $Slug -match '^[a-zA-Z0-9-]+$'
}

# Validate slug
if (-not (Test-Slug -Slug $Slug)) {
    Write-Error "Invalid slug: '$Slug'. Slug can only contain letters, numbers, and hyphens."
    exit 1
}

# Orchestrator root directory
$orchestratorRoot = ".orchestrator"
$tasksDir = "$orchestratorRoot/tasks"

if (-not (Test-Path $tasksDir)) {
    New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
}

# Generate task ID
$taskId = New-TaskId -Slug $Slug -Description $Description -TasksDir $tasksDir -Force:$Force
$taskDir = "$tasksDir/$taskId"

# Check if task already exists
if (Test-Path $taskDir) {
    if (-not $Force) {
        Write-Warning "Task directory already exists: $taskDir"
        $choice = Read-Host "Do you want to overwrite? (Y/N)"
        if ($choice -ne "Y") {
            Write-Host "Initialization cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    Remove-Item $taskDir -Recurse -Force
}

# Create directory structure
Write-Host "Creating task directory structure..." -ForegroundColor Cyan

$directories = @(
    $taskDir,
    "$taskDir/agent_tasks",
    "$taskDir/results"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Gray
    }
}

# Create task metadata
$meta = @{
    taskId = $taskId
    slug = $Slug
    description = $Description
    request = $Request
    createdAt = (Get-Date -Format "o")
    status = "initialized"
    workingDirectory = $taskDir
} | ConvertTo-Json -Depth 10

$meta | Out-File "$taskDir/meta.json" -Encoding UTF8
Write-Host "  Created: $taskDir/meta.json" -ForegroundColor Gray

# Update active tasks registry
$activeTasksFile = "$orchestratorRoot/active_tasks.json"
$activeTasks = if (Test-Path $activeTasksFile) {
    try {
        Get-Content $activeTasksFile | ConvertFrom-Json
    } catch {
        @()
    }
} else {
    @()
}

# Add new task to registry
$activeTasks += @{
    taskId = $taskId
    slug = $Slug
    description = $Description
    request = $Request
    createdAt = (Get-Date -Format "o")
    taskDir = $taskDir
}

$activeTasks | ConvertTo-Json -Depth 10 | Out-File $activeTasksFile -Encoding UTF8
Write-Host "  Updated: $activeTasksFile" -ForegroundColor Gray

# Create master plan file
$latestLink = "$orchestratorRoot/latest"
$requestText = if ($Request) { $Request } else { "[Fill in user request here]" }
$descText = if ($Description) { $Description } else { "[Task description]" }
$agentNames = if ($Agents -and $Agents.Count -gt 0) {
    $Agents
} else {
    1..3 | ForEach-Object { "Agent-{0:D2}" -f $_ }
}

$defaultTaskNames = @("Analyze","Implement","Verify")
$effectiveTaskNames = if ($TaskNames -and $TaskNames.Count -gt 0) { $TaskNames } else { @() }
$taskTotal = [Math]::Max(1, [Math]::Max($TaskCount, [Math]::Max($effectiveTaskNames.Count, 3)))
$getTaskName = {
    param([int]$index)
    if ($effectiveTaskNames -and $effectiveTaskNames.Count -gt $index -and -not [string]::IsNullOrEmpty($effectiveTaskNames[$index])) {
        return $effectiveTaskNames[$index]
    }
    if ($defaultTaskNames.Count -gt $index) {
        return $defaultTaskNames[$index]
    }
    return ("Task-{0:D2}" -f ($index + 1))
}

$taskListRowList = @()
for ($i = 0; $i -lt $taskTotal; $i++) {
    $taskIdText = "T-{0:D2}" -f ($i + 1)
    $taskName = & $getTaskName $i
    $deps = if ($i -eq 0) { "None" } else { "T-{0:D2}" -f $i }
    $priority = if ($i -eq 0) { "P0" } else { "P1" }
    $taskListRowList += "| $taskIdText | $taskName | | $deps | $priority | |"
}
$taskListRows = $taskListRowList -join "`n"

$agentAssignmentRowList = @()
for ($i = 0; $i -lt $taskTotal; $i++) {
    $taskIdText = "T-{0:D2}" -f ($i + 1)
    $agentName = $agentNames[$i % $agentNames.Count]
    $taskName = & $getTaskName $i
    $agentAssignmentRowList += "| $taskIdText | $agentName - $taskName | Pending | - | - | 0 |"
}
$agentAssignmentRows = $agentAssignmentRowList -join "`n"

$masterPlan = @"
# Distributed Task Plan

## Task Meta
- **Task ID**: $taskId
- **Created**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Status**: Initialized
- **Working Directory**: $taskDir

---

## Original Request
> $requestText

---

## Goal Definition
**Primary Goal**: $descText
**Success Criteria**: [Define how to determine task completion]

---

## Task Decomposition

### Dependency Graph
```
[Use ASCII diagram or describe dependencies between tasks]
```

### Task List

| Task ID | Task Name | Description | Dependencies | Priority | Est. Time |
|---------|-----------|-------------|--------------|----------|-----------|
$taskListRows

---

## Agent Assignment

| Task ID | Agent | Status | Start Time | End Time | Retries |
|---------|-------|--------|------------|----------|---------|
$agentAssignmentRows

### Status Legend
- Pending - Awaiting execution
- Running - Currently executing
- Completed - Execution successful
- Failed - Execution failed
- Waiting - Dependencies not satisfied
- Retrying - Retrying after failure

---

## Execution Progress

### Current Batch: #0
**Status**: Initializing

### Completion Statistics
- Total tasks: $taskTotal
- Completed: 0
- In progress: 0
- Waiting: $taskTotal
- Failed: 0

---

## Execution Log

### [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initialization
- Task plan created
- Task ID: $taskId
- Working directory: $taskDir

---

## Error Log

| Time | Agent | Task ID | Error Type | Description | Resolution |
|------|-------|---------|------------|-------------|------------|
| - | - | - | - | - | - |

---

## Final Output

**Output Location**: `$latestLink/final_output.md`
**Status**: Pending generation
"@

$masterPlan | Out-File "$taskDir/master_plan.md" -Encoding UTF8
Write-Host "  Created: $taskDir/master_plan.md" -ForegroundColor Gray

# Update latest pointer (junction preferred; fallback to copy)
if (Test-Path $latestLink) {
    Remove-Item $latestLink -Recurse -Force
}

$latestUpdated = $false
try {
    $resolvedTaskDir = (Resolve-Path $taskDir).Path
    New-Item -ItemType Junction -Path $latestLink -Target $resolvedTaskDir -Force | Out-Null
    $latestUpdated = $true
} catch {
    $latestUpdated = $false
}

if (-not $latestUpdated) {
    Copy-Item -Path $taskDir -Destination $latestLink -Recurse -Force
}

Write-Host "  Updated: $latestLink" -ForegroundColor Gray

# Output summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Task Initialization Complete" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Task ID:       $taskId" -ForegroundColor Yellow
Write-Host "Working Dir:   $taskDir" -ForegroundColor Yellow
Write-Host "Quick Access:  $latestLink" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit task plan:" -ForegroundColor White
Write-Host "     $latestLink/master_plan.md" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Create agent task files:" -ForegroundColor White
$firstAgent = if ($agentNames -and $agentNames.Count -gt 0) { $agentNames[0] } else { "Agent-01" }
$firstTaskIdText = "T-{0:D2}" -f 1
$firstTaskName = & $getTaskName 0
$agentFileName = ("$firstAgent-$firstTaskIdText-$firstTaskName" -replace '[\\/:*?\"<>|]+', '-') + ".md"
Write-Host "     $latestLink/agent_tasks/$agentFileName" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Run execution script:" -ForegroundColor White
Write-Host "     .\run-agents.ps1 -Parallel" -ForegroundColor Gray
Write-Host ""
Write-Host "Task management commands:" -ForegroundColor Cyan
Write-Host "  List all tasks:" -ForegroundColor White
Write-Host "     Get-ChildItem '.orchestrator/tasks/[0-9][0-9][0-9]-*' | Sort-Object LastWriteTime -Descending" -ForegroundColor Gray
Write-Host ""
Write-Host "  Switch to a specific task:" -ForegroundColor White
Write-Host "     Remove-Item '.orchestrator/latest' -Recurse -Force; New-Item -ItemType Junction -Path '.orchestrator/latest' -Target '.orchestrator/tasks/<task-id>' -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "  Clean up old tasks (keep last 5):" -ForegroundColor White
Write-Host "     Get-ChildItem '.orchestrator/tasks/[0-9][0-9][0-9]-*' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Recurse -Force" -ForegroundColor Gray
Write-Host ""
