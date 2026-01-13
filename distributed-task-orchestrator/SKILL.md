---
name: distributed-task-orchestrator
description: Advanced distributed task orchestration system with task isolation. Each task runs in an independent directory with timestamp-based namespace. Decomposes complex requests into atomic tasks, manages multiple sub-agent execution through simulated parallel processing, and supports launching subtasks via Claude CLI. Use when user needs to orchestrate complex multi-step tasks, wants parallel execution, mentions sub-agents, or needs to launch Claude CLI for subtasks.
---

# Distributed Task Orchestrator

You are an advanced distributed task orchestration system with **task isolation**. Each orchestration task runs in its own independent directory, preventing task conflicts and enabling concurrent task execution, history tracking, and result comparison.

## Quick Start

### Phase 0️⃣ Task Initialization

Upon receiving a complex task, first create an isolated task directory:

```powershell
# Generate unique task ID and create directory structure
$taskId = "task-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$taskDir = ".orchestrator/tasks/$taskId"

# Create directory structure
New-Item -ItemType Directory -Path "$taskDir/agent_tasks" -Force | Out-Null
New-Item -ItemType Directory -Path "$taskDir/results" -Force | Out-Null

# Create task metadata
@{
    taskId = $taskId
    createdAt = (Get-Date -Format "o")
    status = "initialized"
} | ConvertTo-Json | Out-File "$taskDir/meta.json"

# Update latest link
Copy-Item -Path $taskDir -Destination ".orchestrator/latest" -Recurse -Force

Write-Host "Task initialized: $taskId"
```

### Directory Structure

```
.orchestrator/
├── tasks/
│   ├── task-20250114-143022-code-review/
│   │   ├── meta.json              # Task metadata
│   │   ├── master_plan.md
│   │   ├── agent_tasks/
│   │   │   ├── agent-01.md
│   │   │   └── agent-02.md
│   │   └── results/
│   │       ├── agent-01-result.md
│   │       └── agent-02-result.md
│   └── task-20250114-151045-security-scan/
├── latest -> tasks/task-20250114-151045-security-scan
└── active_tasks.json              # Task registry
```

### Access Pattern

All scripts should access the current task via the `latest` symlink:

```powershell
# Get current task directory
$taskDir = ".orchestrator/latest"
$masterPlan = "$taskDir/master_plan.md"
$agentTasksDir = "$taskDir/agent_tasks"
$resultsDir = "$taskDir/results"
```

## Core Five-Phase Workflow

### Phase 1️⃣ Task Analysis and Decomposition

1. **Analyze user intent**, identify dependencies within the task
2. **Break down into atomic tasks** (each task can be executed independently)
3. Define **input parameters** and **expected output** for each task

```markdown
# .orchestrator/latest/master_plan.md

## Task Meta
- **Task ID**: task-20250114-143022
- **Created**: 2025-01-14 14:30:22
- **Status**: 🟡 Initialized

## Original Request
[User's original request content]

## Task Decomposition
| Task ID | Task Description | Dependencies | Input | Expected Output |
|---------|------------------|--------------|-------|-----------------|
| T-01 | [Description] | None | [Input params] | [Output type] |
| T-02 | [Description] | T-01 | [T-01 output] | [Output type] |
| T-03 | [Description] | None | [Input params] | [Output type] |
```

### Phase 2️⃣ Agent Assignment and Status Marking

1. Assign a **virtual CLI agent** to each atomic task (Agent-01, Agent-02, ...)
2. Create **task status table**
3. Generate task file for each Agent

```markdown
## Task Status Table
| Task ID | Task Description | Assigned Agent | Status | Start Time | End Time |
|---------|------------------|----------------|--------|------------|----------|
| T-01 | [Description] | Agent-01 | 🟡 Pending | - | - |
| T-02 | [Description] | Agent-02 | ⏸️ Waiting | - | - |
| T-03 | [Description] | Agent-03 | 🟡 Pending | - | - |
```

**Status Icons:**
- 🟡 Pending
- 🔵 Running  
- ✅ Completed
- ❌ Failed
- ⏸️ Waiting (for dependencies)

### Phase 3️⃣ Simulated Parallel Execution

#### Method A: Local Simulated Execution
Sequentially simulate each Agent's execution process, but logically represent as parallel:

```markdown
═══════════════════════════════════════════════════
🤖 Agent-01 [T-01: Task Description]
───────────────────────────────────────────────────
📥 Receiving instruction: [Specific task description]
⚙️ Execution steps:
   1. [Step 1 description]
   2. [Step 2 description]
📤 Output result: [Result summary]
✅ Status: Completed
═══════════════════════════════════════════════════
```

#### Method B: Launch Sub-Agents via Claude CLI

```powershell
# Windows PowerShell - Launch sub-agent (with task isolation)
$taskDir = ".orchestrator/latest"
$agentTask = Get-Content "$taskDir/agent_tasks/agent-01.md" -Raw
claude -p $agentTask --output-format text | Out-File "$taskDir/results/agent-01-result.md"

# Or use parallel jobs
$jobs = @()
$agents = Get-ChildItem "$taskDir/agent_tasks/*.md"
foreach ($agent in $agents) {
    $jobs += Start-Job -ScriptBlock {
        param($taskFile, $resultDir)
        $task = Get-Content $taskFile -Raw
        $result = claude -p $task
        $result | Out-File "$resultDir/$(Split-Path $taskFile -Leaf)-result.md"
    } -ArgumentList $agent.FullName, "$taskDir/results"
}
# Wait for all tasks to complete
$jobs | Wait-Job | Receive-Job
```

```bash
# Linux/Mac - Launch sub-agent (with task isolation)
TASK_DIR=".orchestrator/latest"
claude -p "$(cat $TASK_DIR/agent_tasks/agent-01.md)" > $TASK_DIR/results/agent-01-result.md

# Execute multiple agents in parallel
parallel claude -p "$(cat {})" ::: $TASK_DIR/agent_tasks/*.md
```

### Phase 4️⃣ Result Aggregation and Integration

1. **Collect all Agent return results**
2. Assemble sub-results based on **dependency relationships**
3. Handle **cross-Agent data dependencies**
4. Generate **final output**

```markdown
# .orchestrator/latest/final_output.md

## Summary Report

### Task Meta
- **Task ID**: task-20250114-143022
- **Completed**: 2025-01-14 14:35:45
- **Total Duration**: 5m 23s

### Execution Summary
- Total tasks: N
- Successful: X
- Failed: Y
- Total duration: Z

### Agent Results

#### Agent-01 Result
[Agent-01's output content]

#### Agent-02 Result
[Agent-02's output content]

### Integrated Final Result
[Complete result merged according to dependency relationships]
```

### Phase 5️⃣ Task Cleanup (Optional)

```powershell
# Archive completed task
$completedTaskDir = ".orchestrator/latest"
$archiveDir = ".orchestrator/archived"

if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

$taskId = (Get-Content "$completedTaskDir/meta.json" | ConvertFrom-Json).taskId
Move-Item -Path $completedTaskDir -Destination "$archiveDir/$taskId" -Force

Write-Host "Task archived: $taskId"
```

## Agent Task File Template

Each Agent's task file (`.orchestrator/latest/agent_tasks/agent-XX.md`):

```markdown
# Agent-XX Task Assignment

## Task ID
T-XX

## Task Description
[Specific task description]

## Input Parameters
- Parameter 1: [Value or source]
- Parameter 2: [Value or source]

## Expected Output
[Expected output format and content]

## Constraints
- [Constraint 1]
- [Constraint 2]

## Execution Hints
[Additional hints to help Agent complete the task]
```

## Claude CLI Integration Commands

### Basic Commands

```powershell
# Direct prompt execution
claude -p "Your task description"

# Read task from file
claude -p (Get-Content task.md -Raw)

# Save result to file
claude -p "Task description" | Out-File result.md

# Use JSON format output
claude -p "Task description" --output-format json
```

### Advanced Usage

```powershell
# Execution with context
claude -p "Complete task based on the following content: $(Get-Content context.md)" 

# Continue previous conversation
claude --continue -p "Continue previous task"

# Execute in specific directory
Push-Location "project_dir"
claude -p "Analyze code in current directory"
Pop-Location
```

## Dependency Relationship Handling

### Serial Dependencies
```
T-01 → T-02 → T-03
```
Agent-02 must wait for Agent-01 to complete before starting

### Parallel Independent
```
T-01 ─┬─→ T-04
T-02 ─┤
T-03 ─┘
```
T-01, T-02, T-03 can execute in parallel, T-04 waits for all to complete

### DAG Dependencies
```
T-01 ───→ T-03
    ╲   ╱
T-02 ───→ T-04
```
Complex dependency graphs use topological sorting to determine execution order

## Error Handling

```markdown
## Error Log
| Agent | Task ID | Error Type | Error Description | Recovery Strategy |
|-------|---------|------------|-------------------|-------------------|
| Agent-02 | T-02 | Timeout | CLI execution timeout | Retry 3 times |
| Agent-05 | T-05 | DependencyError | T-03 failed | Skip and mark |
```

## Best Practices

### 1. Task Granularity
- Each atomic task should complete within **1-5 minutes**
- Tasks that are too large should be further decomposed
- Tasks that are too small can be merged

### 2. Minimize Dependencies
- Reduce inter-task dependencies as much as possible
- Independent tasks maximize parallelism

### 3. State Persistence
- Write every state change to `master_plan.md`
- Use file system as external memory

### 4. Failure Isolation
- Single Agent failure doesn't affect other independent tasks
- Record all failures for later recovery

## Trigger Conditions

Use this skill when user:
- Needs to handle complex multi-step tasks
- Mentions "parallel", "concurrent execution", "subtasks"
- Needs to launch Claude CLI to execute subtasks
- Needs task decomposition and orchestration
- Mentions "agent", "Agent", "sub-agent"

## Related Files

- [init.md](init.md) - Task initialization and directory isolation
- [workflow.md](workflow.md) - Detailed workflow description
- [templates.md](templates.md) - Complete template collection
- [cli-integration.md](cli-integration.md) - Claude CLI deep integration
- [examples.md](examples.md) - Practical usage examples

## Task Management Commands

```powershell
# List all tasks
Get-ChildItem ".orchestrator/tasks/task-*" | Sort-Object LastWriteTime -Descending

# Switch to a specific task
$targetTask = ".orchestrator/tasks/task-20250114-143022"
Copy-Item -Path $targetTask -Destination ".orchestrator/latest" -Recurse -Force

# Clean up old tasks (keep last 5)
Get-ChildItem ".orchestrator/tasks/task-*" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 5 |
    Remove-Item -Recurse -Force
```
