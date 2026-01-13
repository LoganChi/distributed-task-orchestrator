# Task Initialization: 任务隔离与目录管理

## 概述

每个编排任务都会在独立的目录中运行，避免任务间相互覆盖。目录结构采用时间戳命名，支持任务历史追溯。

---

## 目录结构设计

```
.orchestrator/
├── tasks/
│   ├── task-20250114-143022-code-review/
│   │   ├── meta.json              # 任务元数据
│   │   ├── master_plan.md
│   │   ├── agent_tasks/
│   │   │   ├── agent-01.md
│   │   │   └── agent-02.md
│   │   └── results/
│   │       ├── agent-01-result.md
│   │       └── agent-02-result.md
│   ├── task-20250114-151045-security-scan/
│   └── task-20250114-161230-api-test/
├── latest -> tasks/task-20250114-161230-api-test  # 符号链接
├── active_tasks.json            # 活跃任务注册表
└── archived/                    # 归档的已完成任务
```

---

## 任务 ID 生成规则

### 格式

```
task-{YYYYMMDD}-{HHMMSS}-{slug}
```

- **日期时间**：精确到秒，确保唯一性
- **slug**：可选的语义化标识（如 code-review、security-scan）
- **示例**：`task-20250114-143022-code-review`

### 生成函数

```powershell
function New-TaskId {
    param(
        [string]$Slug = ""
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $taskId = "task-$timestamp"

    if ($Slug) {
        # 清理 slug：只保留字母、数字、连字符
        $cleanSlug = $Slug -replace '[^a-zA-Z0-9-]', ''
        $taskId = "$taskId-$cleanSlug"
    }

    return $taskId
}

# 使用示例
$taskId = New-TaskId -Slug "code-review"
# 输出: task-20250114-143022-code-review
```

---

## 初始化流程

### Phase 0: 任务初始化

```powershell
# ============================================
# Distributed Task Orchestrator - 初始化
# ============================================

param(
    [string]$Slug = "",              # 语义化任务标识
    [string]$Description = "",       # 任务描述
    [switch]$Force = $false          # 强制创建（覆盖检测）
)

# 1. 生成任务 ID
$taskId = New-TaskId -Slug $Slug
$taskDir = ".orchestrator/tasks/$taskId"

# 2. 检测冲突
if (Test-Path $taskDir) {
    if (-not $Force) {
        Write-Error "任务目录已存在: $taskDir"
        Write-Host "使用 -Force 参数覆盖现有任务" -ForegroundColor Yellow
        exit 1
    }
    Remove-Item $taskDir -Recurse -Force
}

# 3. 创建目录结构
$directories = @(
    $taskDir,
    "$taskDir/agent_tasks",
    "$taskDir/results"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# 4. 生成任务元数据
$meta = @{
    taskId = $taskId
    slug = $Slug
    description = $Description
    createdAt = (Get-Date -Format "o")
    status = "initialized"
    workingDirectory = $taskDir
} | ConvertTo-Json -Depth 10

$meta | Out-File "$taskDir/meta.json" -Encoding UTF8

# 5. 更新活跃任务注册表
$orchestratorRoot = ".orchestrator"
if (-not (Test-Path $orchestratorRoot)) {
    New-Item -ItemType Directory -Path $orchestratorRoot -Force | Out-Null
}

# 更新 active_tasks.json
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

# 6. 更新 latest 符号链接
$latestLink = "$orchestratorRoot/latest"

# Windows 需要管理员权限创建符号链接，或使用目录链接
# 检测是否有管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    # 删除旧的链接
    if (Test-Path $latestLink) {
        (Get-Item $latestLink).Delete()
    }

    # 创建新的符号链接
    cmd /c mklink /D "$latestLink" "$taskDir" | Out-Null
} else {
    # 非管理员模式：复制 latest 目录
    if (Test-Path $latestLink) {
        Remove-Item $latestLink -Recurse -Force
    }
    Copy-Item -Path $taskDir -Destination $latestLink -Recurse
}

# 7. 输出初始化结果
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  任务初始化成功" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "任务 ID:       $taskId" -ForegroundColor Yellow
Write-Host "工作目录:      $taskDir" -ForegroundColor Yellow
Write-Host "快捷访问:      $latestLink" -ForegroundColor Yellow
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  1. 编辑 $latestLink/master_plan.md 定义任务" -ForegroundColor White
Write-Host "  2. 运行执行脚本启动并行处理" -ForegroundColor White
Write-Host ""
```

---

## 任务管理命令

### 列出所有任务

```powershell
function Get-OrchestratorTasks {
    param(
        [string]$Status = "all"  # all, active, completed, archived
    )

    $activeTasksFile = ".orchestrator/active_tasks.json"

    if (-not (Test-Path $activeTasksFile)) {
        Write-Host "没有找到任务记录" -ForegroundColor Yellow
        return
    }

    $tasks = Get-Content $activeTasksFile | ConvertFrom-Json

    # 过滤状态
    if ($Status -ne "all") {
        # 实际应用中需要根据任务状态过滤
        # 这里简化处理
    }

    # 输出任务列表
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  任务列表" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($task in $tasks) {
        $statusIcon = switch ($task.status) {
            "initialized" { "🟡" }
            "running" { "🔵" }
            "completed" { "✅" }
            "failed" { "❌" }
            default { "⚪" }
        }

        Write-Host "$statusIcon $($task.taskId)" -ForegroundColor White
        Write-Host "   描述: $($task.description)" -ForegroundColor Gray
        Write-Host "   创建: $($task.createdAt)" -ForegroundColor Gray
        Write-Host "   目录: $($task.taskDir)" -ForegroundColor Gray
        Write-Host ""
    }
}

# 使用示例
Get-OrchestratorTasks -Status "active"
```

### 切换到指定任务

```powershell
function Set-OrchestratorTask {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId
    )

    $activeTasksFile = ".orchestrator/active_tasks.json"

    if (-not (Test-Path $activeTasksFile)) {
        Write-Error "没有找到任务记录"
        return
    }

    $tasks = Get-Content $activeTasksFile | ConvertFrom-Json
    $task = $tasks | Where-Object { $_.taskId -eq $TaskId }

    if (-not $task) {
        Write-Error "任务不存在: $TaskId"
        return
    }

    # 更新 latest 链接
    $latestLink = ".orchestrator/latest"
    $taskDir = $task.taskDir

    if (Test-Path $latestLink) {
        Remove-Item $latestLink -Recurse -Force
    }

    Copy-Item -Path $taskDir -Destination $latestLink -Recurse

    Write-Host "已切换到任务: $TaskId" -ForegroundColor Green
    Write-Host "工作目录: $taskDir" -ForegroundColor Yellow
}

# 使用示例
Set-OrchestratorTask -TaskId "task-20250114-143022-code-review"
```

### 清理旧任务

```powershell
function Remove-OrchestratorTasks {
    param(
        [int]$KeepLast = 5,              # 保留最近 N 个
        [switch]$Archive = $false,        # 归档而非删除
        [switch]$WhatIf = $false          # 预览模式
    )

    $activeTasksFile = ".orchestrator/active_tasks.json"

    if (-not (Test-Path $activeTasksFile)) {
        Write-Host "没有找到任务记录" -ForegroundColor Yellow
        return
    }

    $tasks = Get-Content $activeTasksFile | ConvertFrom-Json

    # 按创建时间排序
    $sortedTasks = $tasks | Sort-Object { [DateTime]$_.createdAt } -Descending

    # 找出需要清理的任务
    $tasksToRemove = $sortedTasks | Select-Object -Skip $KeepLast

    if ($tasksToRemove.Count -eq 0) {
        Write-Host "没有需要清理的任务" -ForegroundColor Green
        return
    }

    # 预览
    Write-Host "将清理 $($tasksToRemove.Count) 个任务:" -ForegroundColor Yellow
    foreach ($task in $tasksToRemove) {
        $action = if ($Archive) { "归档" } else { "删除" }
        Write-Host "  [$action] $($task.taskId)" -ForegroundColor Gray
    }

    if ($WhatIf) {
        return
    }

    # 确认
    $confirm = Read-Host "确认执行? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "已取消" -ForegroundColor Yellow
        return
    }

    # 执行清理
    foreach ($task in $tasksToRemove) {
        $taskDir = $task.taskDir

        if ($Archive) {
            # 归档
            $archiveDir = ".orchestrator/archived"
            if (-not (Test-Path $archiveDir)) {
                New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
            }
            Move-Item -Path $taskDir -Destination "$archiveDir/" -Force
        } else {
            # 删除
            Remove-Item -Path $taskDir -Recurse -Force
        }

        Write-Host "  ✅ 已处理: $($task.taskId)" -ForegroundColor Green
    }

    # 更新注册表
    $remainingTasks = $sortedTasks | Select-Object -First $KeepLast
    $remainingTasks | ConvertTo-Json -Depth 10 | Out-File $activeTasksFile -Encoding UTF8

    Write-Host ""
    Write-Host "清理完成，保留 $KeepLast 个最近任务" -ForegroundColor Green
}

# 使用示例
Remove-OrchestratorTasks -KeepLast 3 -WhatIf          # 预览
Remove-OrchestratorTasks -KeepLast 3 -Archive         # 归档旧任务
Remove-OrchestratorTasks -KeepLast 5                  # 直接删除
```

---

## 环境变量支持

为了让脚本更灵活，支持通过环境变量配置：

```powershell
# 可配置的环境变量
$env:ORCHESTRATOR_ROOT = if ($env:ORCHESTRATOR_ROOT) { $env:ORCHESTRATOR_ROOT } else { ".orchestrator" }
$env:ORCHESTRATOR_MAX_TASKS = if ($env:ORCHESTRATOR_MAX_TASKS) { $env:ORCHESTRATOR_MAX_TASKS } else { "10" }
$env:ORCHESTRATOR_AUTO_CLEANUP = if ($env:ORCHESTRATOR_AUTO_CLEANUP) { $env:ORCHESTRATOR_AUTO_CLEANUP } else { "false" }
```

---

## 快速开始脚本

完整的初始化脚本模板：

```powershell
# init-task.ps1 - 快速创建新任务
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Request,

    [string]$Slug = "",

    [string]$Description = ""
)

# 自动生成 slug（如果未提供）
if (-not $Slug) {
    # 从请求中提取关键词
    $keywords = @("code-review", "security", "test", "analyze", "audit", "scan")
    foreach ($keyword in $keywords) {
        if ($Request -like "*$keyword*") {
            $Slug = $keyword
            break
        }
    }
}

# 使用默认描述
if (-not $Description) {
    $Description = $Request.Substring(0, [Math]::Min(100, $Request.Length))
    if ($Request.Length -gt 100) {
        $Description += "..."
    }
}

# 加载并执行初始化
. "$PSScriptRoot/init.ps1"

# 初始化任务
$taskId = Initialize-OrchestratorTask -Slug $Slug -Description $Description

# 生成初始 master_plan
$masterPlan = @"
# 🎯 分布式任务计划

## 任务元数据
- **任务 ID**: $taskId
- **创建时间**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **状态**: 🟡 初始化

---

## 原始请求
> $Request

---

## 目标定义
**主要目标**: [请在此处定义目标]
**成功标准**: [请在此处定义成功标准]

---

## 📋 任务分解

| Task ID | 任务名称 | 描述 | 依赖关系 | 优先级 |
|---------|---------|------|----------|--------|
| T-01 | | | None | P0 |

---

## 🤖 Agent 分配

| Task ID | Agent | 状态 | 开始时间 | 结束时间 |
|---------|-------|--------|----------|----------|
| T-01 | Agent-01 | 🟡 Pending | - | - |
"@

$masterPlan | Out-File ".orchestrator/latest/master_plan.md" -Encoding UTF8

Write-Host ""
Write-Host "📝 主计划已创建: .orchestrator/latest/master_plan.md" -ForegroundColor Green
Write-Host "👉 请编辑主计划以定义任务分解" -ForegroundColor Yellow
```

---

## 使用示例

### 创建新任务

```powershell
# 自动生成 slug
.\init-task.ps1 -Request "分析 TypeScript 代码质量和安全问题"

# 指定 slug
.\init-task.ps1 -Slug "security-audit" -Request "对 src/ 目录进行安全审计"

# 完整参数
.\init-task.ps1 -Slug "api-test" -Description "API 端点压力测试" -Request "测试所有 API 接口"
```

### 管理任务

```powershell
# 列出所有任务
Get-OrchestratorTasks

# 切换到指定任务
Set-OrchestratorTask -TaskId "task-20250114-143022-code-review"

# 清理旧任务（预览）
Remove-OrchestratorTasks -KeepLast 3 -WhatIf

# 清理旧任务（归档模式）
Remove-OrchestratorTasks -KeepLast 3 -Archive
```

---

## 与现有脚本的兼容性

为了保证向后兼容，所有现有脚本都应支持通过 `latest` 目录访问：

```powershell
# 获取当前任务目录（兼容模式）
function Get-CurrentTaskDir {
    $latestLink = ".orchestrator/latest"

    if (Test-Path $latestLink) {
        return Resolve-Path $latestLink
    } else {
        Write-Error "没有找到活跃任务，请先运行 init-task.ps1"
        exit 1
    }
}

# 使用示例
$taskDir = Get-CurrentTaskDir
$masterPlan = "$taskDir/master_plan.md"
$agentTasksDir = "$taskDir/agent_tasks"
$resultsDir = "$taskDir/results"
```

---

## 迁移指南

如果你有现有的 `.orchestrator/` 目录，可以通过以下脚本迁移到新结构：

```powershell
# migrate-to-isolated-tasks.ps1

$oldOrchestrator = ".orchestrator"
$newOrchestratorRoot = ".orchestrator-tasks-backup"

if (Test-Path "$oldOrchestrator/master_plan.md") {
    # 生成迁移任务 ID
    $migrateId = "task-migrated-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $migrateDir = "$oldOrchestrator/tasks/$migrateId"

    # 创建新结构
    New-Item -ItemType Directory -Path "$migrateDir/agent_tasks" -Force | Out-Null
    New-Item -ItemType Directory -Path "$migrateDir/results" -Force | Out-Null

    # 移动现有文件
    Move-Item -Path "$oldOrchestrator/master_plan.md" -Destination "$migrateDir/master_plan.md" -Force

    if (Test-Path "$oldOrchestrator/agent_tasks") {
        Move-Item -Path "$oldOrchestrator/agent_tasks/*" -Destination "$migrateDir/agent_tasks/" -Force
    }

    if (Test-Path "$oldOrchestrator/results") {
        Move-Item -Path "$oldOrchestrator/results/*" -Destination "$migrateDir/results/" -Force
    }

    # 创建注册表条目
    $meta = @{
        taskId = $migrateId
        slug = "migrated"
        description = "从旧结构迁移的任务"
        createdAt = (Get-Date -Format "o")
        taskDir = $migrateDir
    }

    $activeTasksFile = "$oldOrchestrator/active_tasks.json"
    $activeTasks = @($meta)

    $activeTasks | ConvertTo-Json -Depth 10 | Out-File $activeTasksFile -Encoding UTF8

    Write-Host "✅ 迁移完成" -ForegroundColor Green
    Write-Host "任务 ID: $migrateId" -ForegroundColor Yellow
    Write-Host "目录: $migrateDir" -ForegroundColor Yellow
} else {
    Write-Host "没有找到需要迁移的任务" -ForegroundColor Yellow
}
```
