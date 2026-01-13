# Workflow: Detailed Distributed Task Orchestration Workflow

## Complete Execution Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Submits Complex Request                  │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ Phase 0: Task Initialization (with Isolation)                    │
│ ┌───────────────────────────────────────────────────────────┐   │
│ │ 0.1 Generate unique task ID (timestamp + optional slug)   │   │
│ │ 0.2 Create isolated task directory                        │   │
│ │ 0.3 Initialize task metadata (meta.json)                  │   │
│ │ 0.4 Update active tasks registry                          │   │
│ │ 0.5 Create/update latest symlink                          │   │
│ └───────────────────────────────────────────────────────────┘   │
│ 📄 Output: .orchestrator/tasks/task-TIMESTAMP[-SLUG]/            │
│          .orchestrator/latest -> tasks/task-TIMESTAMP[-SLUG]     │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ Phase 1: Task Analysis and Decomposition                         │
│ ┌───────────────────────────────────────────────────────────┐   │
│ │ 1.1 Parse user intent                                      │   │
│ │ 1.2 Identify dependencies (build DAG)                      │   │
│ │ 1.3 Break down into atomic tasks                           │   │
│ │ 1.4 Define Input/Output for each task                      │   │
│ └───────────────────────────────────────────────────────────┘   │
│ 📄 Output: .orchestrator/latest/master_plan.md                   │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ Phase 2: Agent Assignment and Status Marking                     │
│ ┌───────────────────────────────────────────────────────────┐   │
│ │ 2.1 Assign Agent ID for each task                          │   │
│ │ 2.2 Create task status table                               │   │
│ │ 2.3 Generate Agent task files                              │   │
│ │ 2.4 Initialize status as "Pending"                         │   │
│ └───────────────────────────────────────────────────────────┘   │
│ 📄 Output: .orchestrator/latest/agent_tasks/agent-XX.md          │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ Phase 3: Parallel Execution                                      │
│ ┌───────────────────────────────────────────────────────────┐   │
│ │ 3.1 Identify parallelizable task groups                    │   │
│ │ 3.2 Choose execution method (simulated / CLI)              │   │
│ │ 3.3 Execute tasks with no dependencies                     │   │
│ │ 3.4 Execute subsequent tasks after dependencies complete   │   │
│ │ 3.5 Record execution logs                                  │   │
│ └───────────────────────────────────────────────────────────┘   │
│ 📄 Output: .orchestrator/latest/results/agent-XX-result.md       │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ Phase 4: Result Aggregation and Integration                      │
│ ┌───────────────────────────────────────────────────────────┐   │
│ │ 4.1 Collect all Agent results                              │   │
│ │ 4.2 Verify result completeness                             │   │
│ │ 4.3 Merge results according to dependency order            │   │
│ │ 4.4 Generate final output                                  │   │
│ └───────────────────────────────────────────────────────────┘   │
│ 📄 Output: .orchestrator/latest/final_output.md                  │
└─────────────────────────────────┬───────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│ Phase 5: Task Cleanup (Optional)                                 │
│ ┌───────────────────────────────────────────────────────────┐   │
│ │ 5.1 Archive or delete completed task                       │   │
│ │ 5.2 Update active tasks registry                          │   │
│ │ 5.3 Remove from latest symlink                            │   │
│ └───────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 0: Task Initialization (with Isolation)

### 0.1 Generate Task ID

```powershell
# Generate unique task ID
function New-TaskId {
    param([string]$Slug = "")

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $taskId = "task-$timestamp"

    if ($Slug) {
        $cleanSlug = $Slug -replace '[^a-zA-Z0-9-]', ''
        $taskId = "$taskId-$cleanSlug"
    }

    return $taskId
}

# Examples
New-TaskId                              # → task-20250114-143022
New-TaskId -Slug "code-review"          # → task-20250114-143022-code-review
New-TaskId -Slug "security-audit-v2"    # → task-20250114-143022-security-audit-v2
```

### 0.2 Directory Structure Creation

```powershell
# Create isolated task directory
$taskId = New-TaskId -Slug "code-review"
$taskDir = ".orchestrator/tasks/$taskId"

# Directory structure
$directories = @(
    $taskDir,
    "$taskDir/agent_tasks",
    "$taskDir/results"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Result:
# .orchestrator/tasks/task-20250114-143022-code-review/
# ├── agent_tasks/
# └── results/
```

### 0.3 Task Metadata Creation

```powershell
# Create meta.json
$meta = @{
    taskId = $taskId
    slug = "code-review"
    description = "Review TypeScript code for quality and security"
    createdAt = (Get-Date -Format "o")  # ISO 8601 format
    status = "initialized"
    workingDirectory = $taskDir
} | ConvertTo-Json -Depth 10

$meta | Out-File "$taskDir/meta.json" -Encoding UTF8
```

### 0.4 Update Active Tasks Registry

```powershell
# Update .orchestrator/active_tasks.json
$activeTasksFile = ".orchestrator/active_tasks.json"
$activeTasks = if (Test-Path $activeTasksFile) {
    Get-Content $activeTasksFile | ConvertFrom-Json
} else {
    @()
}

$activeTasks += @{
    taskId = $taskId
    slug = "code-review"
    description = "Review TypeScript code for quality and security"
    createdAt = (Get-Date -Format "o")
    taskDir = $taskDir
}

$activeTasks | ConvertTo-Json -Depth 10 | Out-File $activeTasksFile -Encoding UTF8
```

### 0.5 Create/Update Latest Symlink

```powershell
# Update .orchestrator/latest to point to new task
$latestLink = ".orchestrator/latest"
if (Test-Path $latestLink) {
    Remove-Item $latestLink -Recurse -Force
}
Copy-Item -Path $taskDir -Destination $latestLink -Recurse -Force

# Now .orchestrator/latest -> .orchestrator/tasks/task-20250114-143022-code-review/
```

---

## Phase 1: Task Analysis and Decomposition (Detailed)

### 1.1 Parse User Intent

```markdown
## Intent Analysis Checklist

### Core Objectives
- [ ] What is the primary goal?
- [ ] What are the secondary goals?
- [ ] What are the success criteria?

### Constraints
- [ ] Time constraints?
- [ ] Resource constraints?
- [ ] Technical constraints?

### Implicit Requirements
- [ ] What does the user expect but didn't explicitly state?
- [ ] Industry best practices?
```

### 1.2 Dependency Analysis

**Dependency Types:**

| Type | Description | Example |
|------|-------------|---------|
| Data Dependency | B needs A's output as input | Analyze code → Generate report |
| Sequential Dependency | B must execute after A | Create file → Write content |
| Resource Dependency | A and B compete for same resource | Write to same file simultaneously |
| No Dependency | Completely independent | Process different files separately |

**Building Dependency Graph:**

```
Example: Code Review Task

          ┌─→ [T-02: Check code style] ─┐
[T-01] ──┤                              ├──→ [T-05: Generate report]
Read code ├─→ [T-03: Security scan] ────┤
          └─→ [T-04: Performance analysis] ─┘
```

### 1.3 Atomic Task Definition

**Atomic Task Criteria:**
- ✅ Single Responsibility: Does only one thing
- ✅ Independently Executable: Doesn't depend on runtime context
- ✅ Verifiable Output: Has clear success/failure criteria
- ✅ Retriable: Can be safely retried after failure

```markdown
## Task: T-03

### Definition
- **Task Name**: Security vulnerability scan
- **Input**: Source code file list
- **Output**: Vulnerability report JSON
- **Estimated Time**: 2 minutes

### Atomicity Check
- [x] Single responsibility
- [x] Independently executable
- [x] Verifiable output
- [x] Safe to retry
```

## Phase 2: Agent Assignment (Detailed)

### 2.1 Agent ID Assignment Rules

```
Agent-{sequence}
Sequence: 01, 02, 03, ... (two-digit zero-padded)
```

### 2.2 Complete Task Status Table Fields

```markdown
| Task ID | Task Description | Agent | Status | Priority | Deps | Start | End | Retries |
|---------|------------------|-------|--------|----------|------|-------|-----|---------|
| T-01 | Read code | Agent-01 | ✅ | P0 | None | 10:00 | 10:01 | 0 |
| T-02 | Style check | Agent-02 | 🔵 | P1 | T-01 | 10:01 | - | 0 |
| T-03 | Security scan | Agent-03 | 🔵 | P1 | T-01 | 10:01 | - | 0 |
| T-04 | Performance analysis | Agent-04 | 🟡 | P1 | T-01 | - | - | 0 |
| T-05 | Generate report | Agent-05 | ⏸️ | P2 | T-02,T-03,T-04 | - | - | 0 |
```

### 2.3 Priority Definitions

| Priority | Meaning | Description |
|----------|---------|-------------|
| P0 | Critical Path | Blocks other tasks, execute first |
| P1 | High Priority | Has downstream dependencies |
| P2 | Normal | Standard priority |
| P3 | Low Priority | Can be delayed |

## Phase 3: Parallel Execution (Detailed)

### 3.1 Execution Scheduling Algorithm

```python
# Pseudocode: Topological Sort + Parallel Scheduling
def schedule_tasks(tasks, dependencies):
    ready_queue = [t for t in tasks if no_dependencies(t)]
    running = set()
    completed = set()
    
    while ready_queue or running:
        # Start all ready tasks
        for task in ready_queue:
            start_agent(task)
            running.add(task)
        ready_queue.clear()
        
        # Wait for any task to complete
        finished = wait_any(running)
        completed.add(finished)
        running.remove(finished)
        
        # Check for newly ready tasks
        for task in tasks:
            if task not in completed and task not in running:
                if all_deps_complete(task, completed):
                    ready_queue.append(task)
```

### 3.2 Simulated Execution Output Format

```
══════════════════════════════════════════════════════════════════
                    🚀 Parallel Execution Batch #1
══════════════════════════════════════════════════════════════════

┌──────────────────────────────────────────────────────────────────
│ 🤖 Agent-01 [T-01: Read Code]
├──────────────────────────────────────────────────────────────────
│ 📥 Instruction: Read all .ts files in src/ directory
│ ⚙️ Execution:
│    → Scan directory structure
│    → Read 15 TypeScript files
│    → Calculate file statistics
│ 📤 Output: 
│    - File count: 15
│    - Total lines: 2,847
│    - Saved to: .orchestrator/results/agent-01-result.md
│ ⏱️ Duration: 1.2s
│ ✅ Status: Completed
└──────────────────────────────────────────────────────────────────

══════════════════════════════════════════════════════════════════
                    🚀 Parallel Execution Batch #2
══════════════════════════════════════════════════════════════════

┌──────────────────────────────────────────────────────────────────
│ 🤖 Agent-02 [T-02: Style Check] ║ Agent-03 [T-03: Security Scan]
├──────────────────────────────────────────────────────────────────
│ [Executing in parallel...]
│ 
│ Agent-02 completed ✅ (2.1s)
│ Agent-03 completed ✅ (3.4s)
└──────────────────────────────────────────────────────────────────
```

### 3.3 CLI Execution Mode

**Windows PowerShell Parallel Execution:**

```powershell
# Method 1: Using Jobs
$taskFiles = Get-ChildItem ".orchestrator/agent_tasks/*.md"
$jobs = foreach ($file in $taskFiles) {
    $agentId = $file.BaseName
    Start-Job -Name $agentId -ScriptBlock {
        param($taskPath, $resultPath)
        $task = Get-Content $taskPath -Raw
        $result = claude -p $task
        $result | Out-File $resultPath -Encoding UTF8
    } -ArgumentList $file.FullName, ".orchestrator/results/$agentId-result.md"
}

# Wait for all to complete
$jobs | Wait-Job

# Collect results
$jobs | ForEach-Object {
    Write-Host "[$($_.Name)] Status: $($_.State)"
    Receive-Job $_
}

# Cleanup
$jobs | Remove-Job
```

**Method 2: Using Runspace Pool (More Efficient)**

```powershell
# Create Runspace Pool
$pool = [RunspaceFactory]::CreateRunspacePool(1, 5)  # Max 5 parallel
$pool.Open()

$tasks = Get-ChildItem ".orchestrator/agent_tasks/*.md"
$runspaces = @()

foreach ($task in $tasks) {
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $pool
    $ps.AddScript({
        param($taskPath)
        $content = Get-Content $taskPath -Raw
        claude -p $content
    }).AddArgument($task.FullName) | Out-Null
    
    $runspaces += [PSCustomObject]@{
        PowerShell = $ps
        Handle = $ps.BeginInvoke()
        Task = $task.BaseName
    }
}

# Wait and collect results
foreach ($rs in $runspaces) {
    $result = $rs.PowerShell.EndInvoke($rs.Handle)
    $result | Out-File ".orchestrator/results/$($rs.Task)-result.md"
    $rs.PowerShell.Dispose()
}

$pool.Close()
$pool.Dispose()
```

## Phase 4: Result Aggregation (Detailed)

### 4.1 Result Collection Check

```markdown
## Result Collection Checklist

### Expected Results
| Agent | Result File | Status |
|-------|-------------|--------|
| Agent-01 | agent-01-result.md | ✅ Exists |
| Agent-02 | agent-02-result.md | ✅ Exists |
| Agent-03 | agent-03-result.md | ❌ Missing |

### Missing Result Handling
- Agent-03: Re-execute / Mark as failed
```

### 4.2 Result Merging Strategies

**Strategy A: Simple Concatenation**
```markdown
# Final Report

## Agent-01 Output
[Content]

## Agent-02 Output
[Content]
```

**Strategy B: Structured Merge**
```markdown
# Code Review Report

## Overview
- Code style issues: 12 (from Agent-02)
- Security vulnerabilities: 3 (from Agent-03)
- Performance issues: 5 (from Agent-04)

## Detailed Findings
### Code Style
[Merge Agent-02 detailed content]

### Security
[Merge Agent-03 detailed content]
```

**Strategy C: Intelligent Merge (Requires AI Processing)**
```powershell
# Use Claude to merge multiple results
$results = Get-Content ".orchestrator/results/*.md" -Raw
$mergePrompt = @"
Please merge the following multiple subtask results into a complete report:

$results

Requirements:
1. Preserve all key information
2. Eliminate duplicate content
3. Organize in logical order
4. Generate executive summary
"@

claude -p $mergePrompt | Out-File ".orchestrator/final_output.md"
```

## State Persistence Specification

Every state change must update `master_plan.md`:

```markdown
## Execution Log

### [2025-01-12 14:30:00] Initialization
- Created task plan
- Assigned 5 Agents

### [2025-01-12 14:30:15] Batch #1 Started
- Agent-01 started executing T-01

### [2025-01-12 14:30:22] Agent-01 Completed
- T-01 completed, duration 7s
- Output saved

### [2025-01-12 14:30:22] Batch #2 Started
- Agent-02, Agent-03, Agent-04 launched in parallel

### [2025-01-12 14:30:45] Batch #2 Completed
- All parallel tasks completed

### [2025-01-12 14:30:50] Result Aggregation Completed
- Final output: .orchestrator/final_output.md
```
