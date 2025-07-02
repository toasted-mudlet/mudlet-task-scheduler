# Toasted Mudlet Task Scheduler

A LuaRocks-packaged lightweight task scheduler for [Mudlet](https://www.mudlet.org/).  
Provides cooperative sliced task execution for Mudlet packages.

Mudlet is a free, open-source, cross-platform client for playing and scripting
MUDs (Multi-User Dungeons).

## Requirements

- [Lua 5.1](https://www.lua.org/versions.html#5.1) — Mudlet embeds Lua 5.1
- [Mudlet](https://www.mudlet.org/) — depends on the Mudlet runtime environment
- [uuid](https://luarocks.org/modules/siffiejoe/uuid) — LuaRocks library
- An **integration layer** that integrates LuaRocks dependencies into your Mudlet
  package, allowing you to use external Lua modules managed by LuaRocks.  
  See [mudlet-muddler-luarocks-starter](https://github.com/toasted-mudlet/mudlet-muddler-luarocks-starter) for a ready-to-use template and
  details on integrating LuaRocks modules with Mudlet packages

## Mudlet Environment Dependencies

This task scheduler is designed for use in **Mudlet packages**.

**Required Mudlet APIs and globals:**

- `tempTimer`  
  Used to schedule stepwise execution.

> **Note:**  
> Usage outside your package code, such as in global scripts or the Mudlet
> editor, is discouraged and, in any case, depends on your LuaRocks integration 
> layer.

## Installation

```
luarocks install toasted_mudlet_task_scheduler
```

Or, if using a custom tree:

```
luarocks install --tree=lua_modules toasted_mudlet_task_scheduler
```

Then build your Mudlet package as usual.

## Usage

### Basic usage

```
local TaskScheduler = require "toasted_mudlet_task_scheduler.TaskScheduler"

local scheduler = TaskScheduler:new()

local function myTask(state)
    local done = (state or 0) >= 10
    local result = "Step " .. tostring(state or 0)
    local newState = (state or 0) + 1
    return done, result, newState
end

local taskId = scheduler:schedule(myTask, function(success, result)
    if success then
        print("Task completed: " .. tostring(result))
    else
        print("Task failed: " .. tostring(result))
    end
end, 0.05)
```

### Wrapping a task for progress tracking and logging

You can use a wrapper function to observe or log the state at each step, without
modifying your core task logic:

```
local TaskScheduler = require "toasted_mudlet_task_scheduler.TaskScheduler"

local scheduler = TaskScheduler:new()

local function myTask(state)
    state = (state or 0) + 1
    local done = state >= 5
    local result = "Step " .. tostring(state)
    return done, result, state
end

local function withStateTracker(task, onStep)
    return function(state)
        local done, result, newState = task(state)
        onStep(state, done, result, newState)
        return done, result, newState
    end
end

local function logStep(oldState, done, result, newState)
    print(string.format(
        "[step] state was %s, result: %s, new state: %s, done? %s",
        tostring(oldState), tostring(result), tostring(newState), tostring(done)
    ))
end

scheduler:schedule(
    withStateTracker(myTask, logStep),
    function(success, finalResult)
        print("Task finished: " .. tostring(finalResult))
    end,
    0.1
)
```

## Testing

To test your scheduled code outside Mudlet, use the included `tempTimer` mock:

```
local MockTempTimer = require "toasted_mudlet_task_scheduler.MockTempTimer"

before_each(function()
    MockTempTimer:install()
    MockTempTimer:reset()
end)

after_each(function()
    MockTempTimer:uninstall()
end)
```

Advance time in your tests with `MockTempTimer:advanceTime(seconds)` to simulate 
scheduled steps.

## Attribution

If you create a new project based substantially on this task scheduler, please
consider adding the following attribution or similar for all derived code:

> This project is based on [Toasted Mudlet Task Scheduler](https://github.com/toasted-mudlet/mudlet_task_scheduler), originally
> licensed under the MIT License (see [LICENSE](LICENSE) for details). All
> original code and documentation remain under the MIT License.

## License

Copyright © 2025 github.com/toasted323

This project is licensed under the MIT License.  
See [LICENSE](LICENSE) in the root of this repository for full details.