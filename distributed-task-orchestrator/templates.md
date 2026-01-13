# Templates: Distributed Task Orchestration Template Collection

## Important: Task Isolation

All templates below use `.orchestrator/latest/` as the working directory. In your scripts, always resolve to the actual task directory:

```powershell
# Get the actual task directory (resolve symlink)
$taskDir = if (Test-Path ".orchestrator/latest") {
    if ((Get-Item ".orchestrator/latest").LinkType -eq "SymbolicLink") {
        (Get-Item ".orchestrator/latest").Target
    } else {
        ".orchestrator/latest"
    }
} else {
    Write-Error "No active task found. Run initialization first."
    exit 1
}

$masterPlan = "$taskDir/master_plan.md"
$agentTasksDir = "$taskDir/agent_tasks"
$resultsDir = "$taskDir/results"
```

---

## 1. Master Plan File Template (master_plan.md)

```markdown
# 🎯 Distributed Task Plan

## Task Meta
- **Task ID**: task-20250114-143022-code-review
- **Created**: 2025-01-14 14:30:22
- **Status**: 🟡 Initialized
- **Working Directory**: .orchestrator/tasks/task-20250114-143022-code-review/

---

## Original Request
> [Complete content of user's original request]

## Goal Definition
**Primary Goal**: [One sentence describing the final result to achieve]
**Success Criteria**: [How to determine task completion]

---

## 📋 Task Decomposition

### Dependency Graph
```
[Use ASCII diagram or describe dependencies between tasks]
```

### Task List

| Task ID | Task Name | Description | Dependencies | Priority | Est. Time |
|---------|-----------|-------------|--------------|----------|-----------|
| T-01 | [Name] | [Brief description] | None | P0 | 1min |
| T-02 | [Name] | [Brief description] | T-01 | P1 | 2min |
| T-03 | [Name] | [Brief description] | T-01 | P1 | 3min |
| T-04 | [Name] | [Brief description] | T-02,T-03 | P2 | 2min |

---

## 🤖 Agent Assignment

| Task ID | Agent | Status | Start Time | End Time | Retries |
|---------|-------|--------|------------|----------|---------|
| T-01 | Agent-01 | 🟡 Pending | - | - | 0 |
| T-02 | Agent-02 | 🟡 Pending | - | - | 0 |
| T-03 | Agent-03 | 🟡 Pending | - | - | 0 |
| T-04 | Agent-04 | ⏸️ Waiting | - | - | 0 |

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
- Total tasks: 4
- Completed: 0
- In progress: 0
- Waiting: 4
- Failed: 0

---

## 📝 Execution Log

### [YYYY-MM-DD HH:MM:SS] Initialization
- Task plan created
- Assigned N Agents

---

## ⚠️ Error Log

| Time | Agent | Task ID | Error Type | Description | Resolution |
|------|-------|---------|------------|-------------|------------|
| - | - | - | - | - | - |

---

## 📦 Final Output

**Output Location**: `.orchestrator/latest/final_output.md`
**Status**: Pending generation
```

---

## 2. Agent Task File Template (agent-XX.md)

```markdown
# 🤖 Agent-XX Task Assignment

## Task Information
- **Task ID**: T-XX
- **Parent Task ID**: task-20250114-143022-code-review
- **Task Name**: [Task name]
- **Priority**: P1
- **Estimated Time**: 3 minutes

---

## 📥 Input

### Parameter List
| Parameter | Type | Source | Value/Description |
|-----------|------|--------|-------------------|
| param1 | string | User input | [Value] |
| param2 | file | T-01 output | .orchestrator/latest/results/agent-01-result.md |

### Context Information
[Any background information helpful for completing the task]

---

## 🎯 Task Description

[Detailed description of task to complete]

### Specific Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

---

## 📤 Expected Output

### Output Format
[Describe expected output format: text/JSON/Markdown etc.]

### Output Example
```
[Provide example of output format]
```

### Output Location
`.orchestrator/latest/results/agent-XX-result.md`

---

## ⚠️ Constraints

- [Constraint 1: e.g., cannot modify original files]
- [Constraint 2: e.g., must use specific format]
- [Constraint 3: e.g., time limit]

---

## 💡 Execution Hints

[Any hints or suggestions to help Agent complete the task better]
```

---

## 3. Agent Result File Template (agent-XX-result.md)

```markdown
# 📤 Agent-XX Execution Result

## Execution Summary
- **Task ID**: T-XX
- **Status**: ✅ Success / ❌ Failed
- **Start Time**: YYYY-MM-DD HH:MM:SS
- **End Time**: YYYY-MM-DD HH:MM:SS
- **Duration**: X.Xs

---

## 📋 Execution Process

### Step 1: [Step name]
- Action: [Action performed]
- Result: [Action result]

### Step 2: [Step name]
- Action: [Action performed]
- Result: [Action result]

---

## 📦 Output Result

[Actual output content]

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Items processed | X |
| Successful | X |
| Warnings | X |
| Errors | X |

---

## ⚠️ Warnings and Errors

### Warnings
- [Warning information]

### Errors
- [Error information and how it was handled]

---

## 📎 Additional Information

[Any extra information useful for subsequent tasks]
```

---

## 4. Final Output File Template (final_output.md)

```markdown
# 📊 Distributed Task Execution Report

## Task Meta
- **Task ID**: task-20250114-143022-code-review
- **Completed**: 2025-01-14 14:35:45
- **Total Duration**: 5m 23s
- **Status**: ✅ Success

---

## Execution Summary

| Metric | Value |
|--------|-------|
| Total tasks | N |
| Successful tasks | X |
| Failed tasks | Y |
| Total duration | Zs |
| Parallel efficiency | XX% |

---

## 🎯 Original Goal

> [User's original request]

---

## ✅ Completion Status

### Task Completion Details

| Task ID | Task Name | Agent | Status | Duration |
|---------|-----------|-------|--------|----------|
| T-01 | [Name] | Agent-01 | ✅ | 1.2s |
| T-02 | [Name] | Agent-02 | ✅ | 2.3s |
| T-03 | [Name] | Agent-03 | ✅ | 1.8s |
| T-04 | [Name] | Agent-04 | ✅ | 0.9s |

---

## 📦 Integrated Results

[Final result logically integrated from each Agent's output]

### Part One: [Title]
[Processing result from Agent-01]

### Part Two: [Title]
[Merged results from Agent-02 and Agent-03]

### Part Three: [Title]
[Processing result from Agent-04]

---

## 📈 Key Findings/Recommendations

1. [Finding/Recommendation 1]
2. [Finding/Recommendation 2]
3. [Finding/Recommendation 3]

---

## ⚠️ Notes

- [Items requiring user attention]
- [Suggested follow-up actions]

---

## 📝 Execution Timeline

```
[Timeline visualization]
T-01: ████████ (1.2s)
T-02:          ████████████ (2.3s)
T-03:          █████████ (1.8s)
T-04:                         █████ (0.9s)
─────────────────────────────────────────→ Time
0s                                      4.2s
```

---

## 📎 Appendix

### A. Detailed Agent Outputs
- [Agent-01 Result](./results/agent-01-result.md)
- [Agent-02 Result](./results/agent-02-result.md)
- [Agent-03 Result](./results/agent-03-result.md)
- [Agent-04 Result](./results/agent-04-result.md)

### B. Error Log
[List any errors here]
```

---

## 5. CLI Launch Script Templates

### Windows PowerShell (run-agents.ps1)

```powershell
# Distributed Task Orchestration - Agent Launch Script (with task isolation)
# Usage: .\run-agents.ps1 [-Parallel] [-MaxJobs 5] [-TaskDir path]

param(
    [switch]$Parallel = $false,
    [int]$MaxJobs = 4,
    [string]$TaskDir = ""
)

# Resolve task directory (default to latest)
if ([string]::IsNullOrEmpty($TaskDir)) {
    if (-not (Test-Path ".orchestrator/latest")) {
        Write-Error "No active task found in .orchestrator/latest"
        Write-Host "Run initialization first to create a task."
        exit 1
    }
    $TaskDir = ".orchestrator/latest"
}

$agentTasksDir = "$TaskDir/agent_tasks"
$resultDir = "$TaskDir/results"

# Ensure result directory exists
if (-not (Test-Path $resultDir)) {
    New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
}

# Get all task files
$taskFiles = Get-ChildItem "$agentTasksDir/*.md" | Sort-Object Name

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "       🚀 Distributed Task Orchestration - Agent Executor" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Task Directory: $TaskDir" -ForegroundColor Gray
Write-Host "Found $($taskFiles.Count) tasks" -ForegroundColor Yellow
Write-Host "Parallel mode: $Parallel (Max concurrency: $MaxJobs)" -ForegroundColor Yellow
Write-Host ""

if ($Parallel) {
    # Parallel execution
    $jobs = foreach ($file in $taskFiles) {
        $agentId = $file.BaseName
        Start-Job -Name $agentId -ScriptBlock {
            param($taskPath, $resultPath, $agentName)
            $task = Get-Content $taskPath -Raw
            $startTime = Get-Date

            try {
                $result = claude -p $task 2>&1
                $endTime = Get-Date
                $duration = ($endTime - $startTime).TotalSeconds

                # Write result
                @"
# Agent Execution Result

## Execution Info
- Agent: $agentName
- Status: ✅ Success
- Start: $startTime
- End: $endTime
- Duration: $duration seconds

## Output

$result
"@ | Out-File $resultPath -Encoding UTF8

                return @{
                    Agent = $agentName
                    Status = "Success"
                    Duration = $duration
                }
            }
            catch {
                $endTime = Get-Date
                @"
# Agent Execution Result

## Execution Info
- Agent: $agentName
- Status: ❌ Failed
- Start: $startTime
- End: $endTime
- Error: $($_.Exception.Message)
"@ | Out-File $resultPath -Encoding UTF8

                return @{
                    Agent = $agentName
                    Status = "Failed"
                    Error = $_.Exception.Message
                }
            }
        } -ArgumentList $file.FullName, "$resultDir/$agentId-result.md", $agentId
    }
    
    Write-Host "Waiting for all tasks to complete..." -ForegroundColor Yellow
    $jobs | Wait-Job | Out-Null
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                   Execution Complete" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
    
    foreach ($job in $jobs) {
        $result = Receive-Job $job
        if ($result.Status -eq "Success") {
            Write-Host "✅ $($result.Agent): Success ($([math]::Round($result.Duration, 2))s)" -ForegroundColor Green
        } else {
            Write-Host "❌ $($result.Agent): Failed - $($result.Error)" -ForegroundColor Red
        }
    }
    
    $jobs | Remove-Job
}
else {
    # Serial execution
    foreach ($file in $taskFiles) {
        $agentId = $file.BaseName
        Write-Host "▶ Executing $agentId..." -ForegroundColor Cyan

        $task = Get-Content $file.FullName -Raw
        $startTime = Get-Date

        try {
            $result = claude -p $task 2>&1
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds

            $result | Out-File "$resultDir/$agentId-result.md" -Encoding UTF8
            Write-Host "  ✅ Completed ($([math]::Round($duration, 2))s)" -ForegroundColor Green
        }
        catch {
            Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Results saved to: $resultDir" -ForegroundColor Yellow
Write-Host "Final output location: $TaskDir/final_output.md" -ForegroundColor Yellow
```

### Bash Script (run-agents.sh)

```bash
#!/bin/bash

# Distributed Task Orchestration - Agent Launch Script (with task isolation)
# Usage: ./run-agents.sh [-p] [-j 4] [-t task_dir]

PARALLEL=false
MAX_JOBS=4
TASK_DIR=""

# Parse arguments
while getopts "pj:t:" opt; do
    case $opt in
        p) PARALLEL=true ;;
        j) MAX_JOBS=$OPTARG ;;
        t) TASK_DIR=$OPTARG ;;
    esac
done

# Resolve task directory (default to latest)
if [ -z "$TASK_DIR" ]; then
    if [ ! -L ".orchestrator/latest" ] && [ ! -d ".orchestrator/latest" ]; then
        echo "Error: No active task found in .orchestrator/latest"
        echo "Run initialization first to create a task."
        exit 1
    fi
    TASK_DIR=".orchestrator/latest"
fi

AGENT_TASKS_DIR="$TASK_DIR/agent_tasks"
RESULT_DIR="$TASK_DIR/results"

# Ensure result directory exists
mkdir -p "$RESULT_DIR"

echo "═══════════════════════════════════════════════════"
echo "       🚀 Distributed Task Orchestration - Agent Executor"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Task Directory: $TASK_DIR"
echo ""

task_count=$(ls -1 "$AGENT_TASKS_DIR"/*.md 2>/dev/null | wc -l)
echo "Found $task_count tasks"
echo "Parallel mode: $PARALLEL (Max concurrency: $MAX_JOBS)"
echo ""

run_agent() {
    local task_file=$1
    local result_dir=$2
    local agent_id=$(basename "$task_file" .md)
    local result_file="$result_dir/${agent_id}-result.md"

    local start_time=$(date +%s)

    if claude -p "$(cat "$task_file")" > "$result_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo "✅ $agent_id: Success (${duration}s)"
    else
        echo "❌ $agent_id: Failed"
    fi
}

export -f run_agent

if $PARALLEL; then
    export RESULT_DIR
    ls -1 "$AGENT_TASKS_DIR"/*.md | parallel -j "$MAX_JOBS" run_agent {} "$RESULT_DIR"
else
    for task_file in "$AGENT_TASKS_DIR"/*.md; do
        run_agent "$task_file" "$RESULT_DIR"
    done
fi

echo ""
echo "Results saved to: $RESULT_DIR"
echo "Final output location: $TASK_DIR/final_output.md"
```

---

## 6. Quick Initialization Template

### Initialization Script (init-orchestrator.ps1) with Task Isolation

```powershell
# Initialize distributed task orchestration with task isolation
param(
    [string]$Slug = "",              # Optional semantic identifier
    [string]$Description = "",       # Task description
    [switch]$Force = $false
)

# Generate unique task ID
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$taskId = "task-$timestamp"
if ($Slug) {
    $cleanSlug = $Slug -replace '[^a-zA-Z0-9-]', ''
    $taskId = "$taskId-$cleanSlug"
}

$orchestratorRoot = ".orchestrator"
$taskDir = "$orchestratorRoot/tasks/$taskId"

# Create directory structure
$dirs = @(
    "$orchestratorRoot/tasks",
    $taskDir,
    "$taskDir/agent_tasks",
    "$taskDir/results"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Create task metadata
$meta = @{
    taskId = $taskId
    slug = $Slug
    description = $Description
    createdAt = (Get-Date -Format "o")
    status = "initialized"
    workingDirectory = $taskDir
} | ConvertTo-Json -Depth 10

$meta | Out-File "$taskDir/meta.json" -Encoding UTF8

# Update active tasks registry
$activeTasksFile = "$orchestratorRoot/active_tasks.json"
$activeTasks = if (Test-Path $activeTasksFile) {
    Get-Content $activeTasksFile | ConvertFrom-Json
} else {
    @()
}

$activeTasks += @{
    taskId = $taskId
    slug = $Slug
    description = $Description
    createdAt = (Get-Date -Format "o")
    taskDir = $taskDir
}

$activeTasks | ConvertTo-Json -Depth 10 | Out-File $activeTasksFile -Encoding UTF8

# Update latest link
$latestLink = "$orchestratorRoot/latest"
if (Test-Path $latestLink) {
    Remove-Item $latestLink -Recurse -Force
}
Copy-Item -Path $taskDir -Destination $latestLink -Recurse -Force

# Create master plan file
$masterPlan = @"
# 🎯 Distributed Task Plan

## Task Meta
- **Task ID**: $taskId
- **Created**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Status**: 🟡 Initialized
- **Working Directory**: $taskDir

---

## Original Request
> [Fill in user request here]

## Goal Definition
**Primary Goal**: [Goal description]
**Success Criteria**: [Success criteria]

---

## 📋 Task Decomposition

| Task ID | Task Name | Description | Dependencies | Priority |
|---------|-----------|-------------|--------------|----------|
| T-01 | | | None | P0 |

---

## 🤖 Agent Assignment

| Task ID | Agent | Status | Start Time | End Time |
|---------|-------|--------|------------|----------|
| T-01 | Agent-01 | 🟡 Pending | - | - |

---

## 📝 Execution Log

### [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Initialization
- Task plan created
- Task ID: $taskId
"@

$masterPlan | Out-File "$latestLink/master_plan.md" -Encoding UTF8

# Output summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Task Initialization Complete" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Task ID:       $taskId" -ForegroundColor Yellow
Write-Host "Working Dir:   $taskDir" -ForegroundColor Yellow
Write-Host "Quick Access:  $latestLink" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit $latestLink/master_plan.md" -ForegroundColor White
Write-Host "  2. Create agent task files" -ForegroundColor White
Write-Host "  3. Run execution script" -ForegroundColor White
Write-Host ""
```
