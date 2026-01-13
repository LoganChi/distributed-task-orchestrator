# Distributed Task Orchestrator - Initialization Script
# This script creates a new isolated task directory with all necessary structure

param(
    [string]$Slug = "",              # Optional semantic identifier (e.g., "code-review", "security-scan")
    [string]$Description = "",       # Task description
    [string]$Request = "",           # User's original request
    [switch]$Force = $false          # Force overwrite if task ID exists
)

# Function to generate unique task ID
function New-TaskId {
    param([string]$Slug = "")

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $taskId = "task-$timestamp"

    if ($Slug) {
        # Clean slug: only keep alphanumeric and hyphens
        $cleanSlug = $Slug -replace '[^a-zA-Z0-9-]', ''
        if ($cleanSlug) {
            $taskId = "$taskId-$cleanSlug"
        }
    }

    return $taskId
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

# Generate task ID
$taskId = New-TaskId -Slug $Slug

# Orchestrator root directory
$orchestratorRoot = ".orchestrator"
$tasksDir = "$orchestratorRoot/tasks"
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
    $tasksDir,
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

# Update latest symlink
$latestLink = "$orchestratorRoot/latest"
if (Test-Path $latestLink) {
    Remove-Item $latestLink -Recurse -Force
}
Copy-Item -Path $taskDir -Destination $latestLink -Recurse -Force
Write-Host "  Updated: $latestLink" -ForegroundColor Gray

# Create master plan file
$requestText = if ($Request) { $Request } else { "[Fill in user request here]" }
$descText = if ($Description) { $Description } else { "[Task description]" }

$masterPlan = @"
# 🎯 Distributed Task Plan

## Task Meta
- **Task ID**: $taskId
- **Created**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Status**: 🟡 Initialized
- **Working Directory**: $taskDir

---

## Original Request
> $requestText

---

## Goal Definition
**Primary Goal**: $descText
**Success Criteria**: [Define how to determine task completion]

---

## 📋 Task Decomposition

### Dependency Graph
```
[Use ASCII diagram or describe dependencies between tasks]
```

### Task List

| Task ID | Task Name | Description | Dependencies | Priority | Est. Time |
|---------|-----------|-------------|--------------|----------|-----------|
| T-01 | | | None | P0 | |
| T-02 | | | T-01 | P1 | |
| T-03 | | | None | P1 | |

---

## 🤖 Agent Assignment

| Task ID | Agent | Status | Start Time | End Time | Retries |
|---------|-------|--------|------------|----------|---------|
| T-01 | Agent-01 | 🟡 Pending | - | - | 0 |
| T-02 | Agent-02 | 🟡 Pending | - | - | 0 |
| T-03 | Agent-03 | 🟡 Pending | - | - | 0 |

### Status Legend
- 🟡 Pending - Awaiting execution
- 🔵 Running - Currently executing
- ✅ Completed - Execution successful
- ❌ Failed - Execution failed
- ⏸️ Waiting - Dependencies not satisfied
- 🔄 Retrying - Retrying after failure

---

## 📊 Execution Progress

### Current Batch: #0
**Status**: Initializing

### Completion Statistics
- Total tasks: 3
- Completed: 0
- In progress: 0
- Waiting: 3
- Failed: 0

---

## 📝 Execution Log

### [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initialization
- Task plan created
- Task ID: $taskId
- Working directory: $taskDir

---

## ⚠️ Error Log

| Time | Agent | Task ID | Error Type | Description | Resolution |
|------|-------|---------|------------|-------------|------------|
| - | - | - | - | - | - |

---

## 📦 Final Output

**Output Location**: `$latestLink/final_output.md`
**Status**: Pending generation
"@

$masterPlan | Out-File "$latestLink/master_plan.md" -Encoding UTF8
Write-Host "  Created: $latestLink/master_plan.md" -ForegroundColor Gray

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
Write-Host "     $latestLink/agent_tasks/agent-01.md" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Run execution script:" -ForegroundColor White
Write-Host "     .\run-agents.ps1 -Parallel" -ForegroundColor Gray
Write-Host ""
Write-Host "Task management commands:" -ForegroundColor Cyan
Write-Host "  List all tasks:" -ForegroundColor White
Write-Host "     Get-ChildItem '.orchestrator/tasks/task-*' | Sort-Object LastWriteTime -Descending" -ForegroundColor Gray
Write-Host ""
Write-Host "  Switch to a specific task:" -ForegroundColor White
Write-Host "     Copy-Item -Path '.orchestrator/tasks/<task-id>' -Destination '.orchestrator/latest' -Recurse -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "  Clean up old tasks (keep last 5):" -ForegroundColor White
Write-Host "     Get-ChildItem '.orchestrator/tasks/task-*' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Recurse -Force" -ForegroundColor Gray
Write-Host ""
