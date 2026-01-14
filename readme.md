# Distributed Task Orchestrator

A powerful agent skill for orchestrating complex, multi-step tasks through distributed sub-agent execution. This skill decomposes complex user requests into atomic tasks and manages parallel execution through virtual agents, with optional integration with Claude CLI for true distributed processing.

## Table of Contents

- [Overview](#overview)
- [When to Use This Skill](#when-to-use-this-skill)
- [Quick Start](#quick-start)
- [Core Workflow](#core-workflow)
- [File Structure](#file-structure)
- [Usage Scenarios](#usage-scenarios)
- [Claude CLI Integration](#claude-cli-integration)
- [Templates](#templates)
- [Best Practices](#best-practices)
- [Related Documentation](#related-documentation)

---

## Overview

The Distributed Task Orchestrator transforms how you handle complex, multi-step tasks by:

1. **Decomposing** complex requests into independent atomic tasks
2. **Assigning** virtual agents to handle each task
3. **Executing** tasks in parallel (simulated or via CLI)
4. **Aggregating** results into a cohesive final output

### Key Features

- **Task Decomposition**: Automatically breaks down complex requests into manageable atomic tasks
- **Dependency Management**: Handles serial, parallel, and DAG dependencies between tasks
- **Virtual Agent System**: Assigns Agent-01, Agent-02, etc. to execute each task
- **Parallel Execution**: Maximizes efficiency by running independent tasks simultaneously
- **State Persistence**: Uses markdown files to track progress and maintain context
- **Claude CLI Integration**: Optionally launch real sub-agents via Claude CLI for true distributed processing
- **Error Recovery**: Automatic retry and graceful failure handling

---

## When to Use This Skill

### Recommended Use Cases


| Trigger                      | Description                                           | Example                                               |
| ---------------------------- | ----------------------------------------------------- | ----------------------------------------------------- |
| **Complex multi-step tasks** | Tasks requiring 3+ distinct steps                     | "Build a complete authentication system"              |
| **Parallel execution needs** | Independent tasks that can run simultaneously         | "Translate 5 documents to Chinese"                    |
| **Sub-agent orchestration**  | Need to coordinate multiple specialized agents        | "Analyze code for quality, security, and performance" |
| **Large-scale analysis**     | Tasks requiring analysis of multiple files/components | "Review all API endpoints in the project"             |
| **Task decomposition**       | Complex requests needing systematic breakdown         | "Refactor the entire frontend architecture"           |


### Trigger Keywords

The skill activates when users mention:

- "parallel", "simultaneously", "concurrent"
- "subtask", "sub-task", "atomic task"
- "agent", "sub-agent", "Agent-01"
- "orchestrate", "coordinate", "distribute"
- "break down", "decompose"

### When NOT to Use

- Simple, single-step tasks
- Tasks completable in < 3 steps
- Tasks with strict sequential dependencies only
- Quick questions or clarifications

---

## Quick Start

### Option A: Using the Initialization Script (Recommended)

The `init-orchestrator.ps1` script automatically sets up the entire task structure:

```powershell
# Basic usage
.\init-orchestrator.ps1 -Slug "code-review" -Description "Analyze TypeScript code quality"

# With custom agents
.\init-orchestrator.ps1 -Slug "api-test" -Agents "SecurityExpert","PerformanceAnalyst"

# With custom task names
.\init-orchestrator.ps1 -Slug "refactor" -TaskNames "Analyze","Design","Implement","Test"

# Specify task count
.\init-orchestrator.ps1 -Slug "docs" -TaskCount 5
```

This creates:
- `.orchestrator/tasks/001-code-review/` - Task directory with serial number
- `.orchestrator/latest/` - Symlink pointing to the latest task
- All required subdirectories and templates

### Option B: Manual Setup

```bash
mkdir .orchestrator
mkdir .orchestrator/agent_tasks
mkdir .orchestrator/results
```

Create `.orchestrator/master_plan.md` with your task decomposition:

```markdown
# Task Plan

## Original Request
> Analyze my TypeScript project for code quality, security, and performance

## Task Decomposition
| Task ID | Description | Dependencies | Agent |
|---------|-------------|--------------|-------|
| T-01 | Scan source files | None | Agent-01 |
| T-02 | Check code quality | T-01 | Agent-02 |
| T-03 | Security scan | T-01 | Agent-03 |
| T-04 | Performance analysis | T-01 | Agent-04 |
| T-05 | Generate report | T-02,T-03,T-04 | Agent-05 |
```

### 3. Execute and Monitor

The orchestrator will:

1. Execute T-01 first (no dependencies)
2. Run T-02, T-03, T-04 in parallel (all depend only on T-01)
3. Execute T-05 after all parallel tasks complete
4. Generate final output in `.orchestrator/latest/final_output.md`

---

## Core Workflow

### Phase 1: Task Analysis and Decomposition

1. **Analyze user intent** - Identify primary and secondary goals
2. **Build dependency graph** - Map relationships between tasks
3. **Create atomic tasks** - Each task should be independently executable
4. **Define I/O specifications** - Clear inputs and expected outputs

### Phase 2: Agent Assignment and Status Marking

1. **Assign Agent IDs** - Agent-01, Agent-02, etc.
2. **Create task status table** - Track progress
3. **Generate task files** - `.orchestrator/agent_tasks/agent-XX.md`
4. **Initialize status** - 🟡 Pending

**Status Icons:**

- 🟡 Pending - Awaiting execution
- 🔵 Running - Currently executing
- ✅ Completed - Execution successful
- ❌ Failed - Execution failed
- ⏸️ Waiting - Dependencies not satisfied
- 🔄 Retrying - Retry in progress

### Phase 3: Parallel Execution

**Method A: Simulated Execution**

```
═══════════════════════════════════════════════════
🤖 Agent-01 [T-01: Read Code]
───────────────────────────────────────────────────
📥 Instruction: Read all TypeScript files
⚙️ Execution:
   1. Scan directory structure
   2. Read file contents
📤 Output: File statistics saved
✅ Status: Completed
═══════════════════════════════════════════════════
```

**Method B: Claude CLI Execution**

```powershell
# Launch sub-agents via Claude CLI
$task = Get-Content ".orchestrator/agent_tasks/agent-01.md" -Raw
claude -p $task | Out-File ".orchestrator/results/agent-01-result.md"
```

### Phase 4: Result Aggregation

1. **Collect all results** - From `.orchestrator/results/`
2. **Verify completeness** - Ensure all tasks completed
3. **Merge by dependency order** - Combine results logically
4. **Generate final output** - `.orchestrator/final_output.md`

---

## Task Initialization

The `init-orchestrator.ps1` script automates task setup with built-in safety features.

### Features

- **Serial Numbering**: Automatic task ID generation (001, 002, 003...)
- **Concurrency Safety**: Mutex-based locking prevents race conditions
- **Atomic Operations**: Safe file writes even on concurrent access
- **Conflict Resolution**: Automatic suffix handling for duplicate slugs
- **Dynamic Configuration**: Customize agents, tasks, and count

### Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `-Slug` | string | URL-friendly identifier for the task | Required |
| `-Description` | string | Human-readable task description | "" |
| `-Request` | string | Original user request | "" |
| `-Agents` | string[] | Custom agent names | @("Agent-01", "Agent-02", "Agent-03") |
| `-TaskNames` | string[] | Custom task names | @("Analyze", "Implement", "Verify") |
| `-TaskCount` | int | Number of tasks to generate | 3 |
| `-Force` | switch | Overwrite existing task directory | false |

### Examples

```powershell
# Basic code review task
.\init-orchestrator.ps1 -Slug "code-review" -Description "Review code quality"

# API testing with custom agents
.\init-orchestrator.ps1 -Slug "api-test" -Request "Test all endpoints" -Agents "SecurityExpert","PerformanceAnalyst"

# Documentation with 5 parallel tasks
.\init-orchestrator.ps1 -Slug "docs" -TaskCount 5

# Full feature development
.\init-orchestrator.ps1 -Slug "auth-system" -Description "Implement JWT auth" `
    -TaskNames "Design","Model","API","Middleware","Frontend","Tests" `
    -Agents "BackendDev","FrontendDev","SecurityExpert","QATester"
```

### Concurrency Safety

The script includes built-in protection against concurrent initialization:

- **Mutex Lock**: 30-second timeout prevents simultaneous task creation
- **Atomic Writes**: Files written via temp + rename pattern
- **Safe Junction Handling**: Proper cleanup of symlinks before recreation

This means you can safely run multiple instances of the script without corrupting the task registry.

### Task Switching

Switch the `latest` symlink to work on a different task:

```powershell
# Switch to task 002
$task = Get-Item '.orchestrator/tasks/002-security-scan'
Remove-Item '.orchestrator/latest' -Recurse -Force
New-Item -ItemType Junction -Path '.orchestrator/latest' -Target $task.FullName -Force

# Quick command (one-liner)
$i=Get-Item '.orchestrator/latest' -Force; if(($i.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { cmd /c 'rmdir "".orchestrator\latest""' } else { cmd /c 'rmdir /S /Q "".orchestrator\latest""' }; New-Item -ItemType Junction -Path '.orchestrator/latest' -Target '.orchestrator/tasks/002-security-scan' -Force
```

---

## File Structure

### Skill Files (Reference)

```
distributed-task-orchestrator/
├── SKILL.md              # Main skill entry point
├── workflow.md           # Detailed workflow documentation
├── templates.md          # Task and status templates
├── cli-integration.md    # Claude CLI integration guide
├── examples.md           # Practical examples
├── notes.md              # Design notes
├── init.md               # Task initialization guide
└── init-orchestrator.ps1 # Task initialization script
```

### Runtime Files (Generated in User's Project)

```
[user-project]/
├── .orchestrator/
│   ├── tasks/
│   │   ├── 001-code-review/          # First task (serial number + slug)
│   │   │   ├── meta.json             # Task metadata
│   │   │   ├── master_plan.md        # Master task plan and status
│   │   │   ├── agent_tasks/
│   │   │   │   ├── Agent-01-T-01.md  # Agent-01 task description
│   │   │   │   ├── Agent-02-T-02.md  # Agent-02 task description
│   │   │   │   └── ...
│   │   │   ├── results/
│   │   │   │   ├── agent-01-result.md # Agent-01 execution result
│   │   │   │   ├── agent-02-result.md # Agent-02 execution result
│   │   │   │   └── ...
│   │   │   └── final_output.md       # Aggregated final output
│   │   ├── 002-security-scan/        # Second task
│   │   └── 003-api-test/             # Third task
│   ├── latest/                       # Symlink to most recent task
│   └── active_tasks.json             # Registry of all active tasks
```

### Task ID Format

Tasks use serial numbering for better readability and sorting:

- **Format**: `{NNN}-{slug}`
- **Example**: `001-code-review`, `002-security-scan`, `003-api-test`
- **Benefits**:
  - Natural chronological ordering
  - Easy to reference (e.g., "task 1", "task 42")
  - Conflicts auto-resolved with suffixes (`-2`, `-3`)

---

## Usage Scenarios

### Scenario 1: Codebase Analysis

**Request:** "Analyze my TypeScript project for code quality, security, and performance"

**Task Decomposition:**

```
[T-01: Code Scan] ──┬──→ [T-02: Quality Analysis]
                    ├──→ [T-03: Security Scan]
                    └──→ [T-04: Performance Analysis]
                                   ↓
                    [T-05: Generate Report] ←─────┘
```

**Execution Flow:**

1. T-01 reads all source files (1.8s)
2. T-02, T-03, T-04 run in parallel (3.2s max)
3. T-05 aggregates all findings (1.5s)
4. Total: ~6.5s (vs ~11s sequential)

### Scenario 2: Multi-Document Translation

**Request:** "Translate the 5 documents in docs/ to Chinese"

**Task Decomposition:**

```
[T-01: intro.md] ─────────────────────→ All independent
[T-02: getting-started.md] ───────────→ Maximum parallelism
[T-03: api-reference.md] ─────────────→ 
[T-04: tutorials.md] ─────────────────→
[T-05: faq.md] ───────────────────────→
```

**Execution:**

- All 5 tasks run simultaneously
- Total time: ~45s (vs ~180s sequential)
- Parallel efficiency: 4x speedup

### Scenario 3: API Endpoint Testing

**Request:** "Test all API endpoints for response time and correctness"

**Task Decomposition:**

- T-01: Test GET /api/users
- T-02: Test GET /api/users/:id
- T-03: Test POST /api/users
- T-04: Test GET /api/products
- T-05: Test GET /api/orders

**Final Report Includes:**

- Endpoints tested: 5
- Test cases: 15
- Pass rate: 93%
- Average response time: 156ms
- Failed cases with recommendations

### Scenario 4: Full-Stack Feature Development

**Request:** "Add user authentication with JWT"

**Task Decomposition:**

```
[T-01: Design DB Schema] ───→ [T-03: Implement User Model]
[T-02: Design API Spec] ────→ [T-04: Implement Auth Routes]
                                        ↓
                            [T-05: Create JWT Middleware]
                                        ↓
                            [T-06: Add Frontend Auth]
                                        ↓
                            [T-07: Write Tests]
```

---

## Claude CLI Integration

### Basic Commands

```powershell
# Direct execution
claude -p "Your task description"

# Read task from file
claude -p (Get-Content task.md -Raw)

# Save result to file
claude -p "Task description" | Out-File result.md

# JSON output format
claude -p "Task description" --output-format json
```

### Parallel Execution with PowerShell Jobs

```powershell
# Launch multiple agents in parallel
$taskFiles = Get-ChildItem ".orchestrator/agent_tasks/*.md"

$jobs = foreach ($file in $taskFiles) {
    $agentId = $file.BaseName
    Start-Job -Name $agentId -ScriptBlock {
        param($taskPath, $resultPath)
        $task = Get-Content $taskPath -Raw
        claude -p $task | Out-File $resultPath -Encoding UTF8
    } -ArgumentList $file.FullName, ".orchestrator/results/$agentId-result.md"
}

# Wait for all to complete
$jobs | Wait-Job

# Display results
$jobs | ForEach-Object {
    $status = if ($_.State -eq 'Completed') { "✅" } else { "❌" }
    Write-Host "$status $($_.Name)"
}

# Cleanup
$jobs | Remove-Job
```

### Dependency-Aware Execution

```powershell
# Define task dependencies
$taskGraph = @{
    "T-01" = @{ Agent = "Agent-01"; Deps = @() }
    "T-02" = @{ Agent = "Agent-02"; Deps = @("T-01") }
    "T-03" = @{ Agent = "Agent-03"; Deps = @("T-01") }
    "T-04" = @{ Agent = "Agent-04"; Deps = @("T-02", "T-03") }
}

# Execute in topological order with parallel batches
```

### Error Handling with Retry

```powershell
function Invoke-AgentWithRetry {
    param(
        [string]$TaskFile,
        [string]$ResultFile,
        [int]$TimeoutSeconds = 300,
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        $job = Start-Job -ScriptBlock {
            param($taskPath)
            claude -p (Get-Content $taskPath -Raw)
        } -ArgumentList $TaskFile
        
        if (Wait-Job $job -Timeout $TimeoutSeconds) {
            $result = Receive-Job $job
            Remove-Job $job
            $result | Out-File $ResultFile -Encoding UTF8
            return @{ Success = $true; Retries = $retryCount }
        }
        
        Stop-Job $job
        Remove-Job $job
        $retryCount++
    }
    
    return @{ Success = $false; Retries = $retryCount }
}
```

---

## Templates

### Master Plan Template

```markdown
# 🎯 Distributed Task Plan

## Original Request
> [User's original request]

## Goal Definition
**Primary Goal**: [Final result to achieve]
**Success Criteria**: [How to determine completion]

## Task Decomposition
| Task ID | Task Name | Description | Dependencies | Priority |
|---------|-----------|-------------|--------------|----------|
| T-01 | [Name] | [Description] | None | P0 |

## Agent Assignment
| Task ID | Agent | Status | Start Time | End Time |
|---------|-------|--------|------------|----------|
| T-01 | Agent-01 | 🟡 Pending | - | - |
```

### Agent Task Template

```markdown
# 🤖 Agent-XX Task Assignment

## Task Information
- **Task ID**: T-XX
- **Task Name**: [Name]
- **Priority**: P1
- **Estimated Time**: 3 minutes

## Input
| Parameter | Type | Source | Value |
|-----------|------|--------|-------|
| param1 | string | User input | [Value] |

## Task Description
[Detailed task description]

## Expected Output
[Format and content requirements]

## Constraints
- [Constraint 1]
- [Constraint 2]
```

### Agent Result Template

```markdown
# 📤 Agent-XX Execution Result

## Execution Summary
- **Status**: ✅ Success
- **Duration**: X.Xs

## Output
[Actual output content]

## Statistics
| Metric | Value |
|--------|-------|
| Items processed | X |
| Successful | X |
```

---

## Best Practices

### 1. Use the Initialization Script

Always prefer `init-orchestrator.ps1` over manual setup:

- **Automatic setup**: Creates all directories and files
- **Concurrency safe**: Mutex locking prevents race conditions
- **Consistent structure**: Every task follows the same format
- **Less error-prone**: No manual file creation

```powershell
# Good
.\init-orchestrator.ps1 -Slug "code-review" -Description "Review code quality"

# Avoid - manual setup is tedious and error-prone
mkdir .orchestrator/tasks/task-20241214-103000
# ... many more manual steps
```

### 2. Task Granularity

- **Ideal**: Each task completes in 1-5 minutes
- **Too large**: Break down further
- **Too small**: Consider merging

### 3. Minimize Dependencies

- Design independent tasks whenever possible
- Use files to pass intermediate results
- Avoid circular dependencies

### 3. Maximize Parallelism

- More independent tasks = greater speedup
- Recommended concurrency: 4-8 agents
- Monitor resource usage

### 4. State Persistence

- Update `master_plan.md` after every state change
- Use file system as external memory
- Log all executions and errors

### 5. Error Handling

- Isolate failures - one agent's failure shouldn't block others
- Implement automatic retry with exponential backoff
- Preserve partial results for recovery

### 6. Concurrency Safety

- Use mutex locks when multiple processes may write shared files
- Write files atomically (temp file + rename pattern)
- The `init-orchestrator.ps1` script includes these protections
- Be careful with manual concurrent access to `active_tasks.json`

### 7. Dependency Types


| Type            | Description            | Example           |
| --------------- | ---------------------- | ----------------- |
| Data Dependency | B needs A's output     | Analyze → Report  |
| Sequential      | B must follow A        | Create → Populate |
| Resource        | A and B share resource | Same file writes  |
| None            | Completely independent | Different files   |


---

## Related Documentation

- [workflow.md](distributed-task-orchestrator/workflow.md) - Detailed workflow documentation
- [templates.md](distributed-task-orchestrator/templates.md) - Complete template collection
- [cli-integration.md](distributed-task-orchestrator/distributed-task-orchestrator/cli-integration.md) - Claude CLI deep integration
- [examples.md](distributed-task-orchestrator/examples.md) - Practical examples
- [notes.md](distributed-task-orchestrator/notes.md) - Design notes

---

## Installation

This skill is located at:

```
C:\Users\{User}\.claude\skills\distributed-task-orchestrator\SKILL.md
```

The skill is automatically available when:

- User needs to orchestrate complex multi-step tasks
- User mentions parallel execution or sub-agents
- User needs to launch Claude CLI for subtasks
- User requests task decomposition

---

## Contributing

To extend or modify this skill:

1. Edit files in the `distributed-task-orchestrator/` directory
2. Update `SKILL.md` for core workflow changes
3. Add new templates to `templates.md`
4. Document new CLI patterns in `cli-integration.md`
5. Add examples to `examples.md`

---

## License

This skill is part of a personal knowledge base and skill collection.