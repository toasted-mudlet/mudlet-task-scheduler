package = "toasted_mudlet_task_scheduler"
version = "dev-1"

source = {
    url = "git+https://github.com/toasted-mudlet/mudlet-task-scheduler.git",
    tag = "dev-1"
}

description = {
    summary = "A lightweight task scheduler for Mudlet",
    detailed = [[
        A lightweight, slice-based task scheduler for Mudlet package development.
        Provides cooperative multitasking for long-running or periodic tasks in Mudlet.
        Uses tempTimer for step scheduling. No coroutines required.
    ]],
    homepage = "https://github.com/toasted-mudlet/mudlet_task_scheduler",
    license = "MIT"
}

dependencies = {
    "lua >= 5.1, < 5.2",
    "uuid >= 1.0.0-1"
}

build = {
    type = "builtin",
    modules = {
        ["toasted_mudlet_task_scheduler"] = "src/toasted_mudlet_task_scheduler/init.lua",
        ["toasted_mudlet_task_scheduler.TaskScheduler"] = "src/toasted_mudlet_task_scheduler/TaskScheduler.lua",
        ["toasted_mudlet_task_scheduler.TaskRunner"] = "src/toasted_mudlet_task_scheduler/TaskRunner.lua",
        ["toasted_mudlet_task_scheduler.MockTempTimer"] = "src/toasted_mudlet_task_scheduler/MockTempTimer.lua"
    }
}
