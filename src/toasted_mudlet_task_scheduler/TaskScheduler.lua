--- TaskScheduler class for managing and running asynchronous tasks.
-- @classmod toasted_mudlet_task_scheduler.TaskScheduler

local TaskRunner = require "toasted_mudlet_task_scheduler.TaskRunner"
local uuid = require "uuid"

uuid.set_rng(function(n)
    local t = {}
    for i = 1, n do
        t[i] = string.char(math.random(0, 255))
    end
    return table.concat(t)
end)

local TaskScheduler = {}
TaskScheduler.__index = TaskScheduler

--- Create a new TaskScheduler instance.
-- @return TaskScheduler instance
function TaskScheduler:new()
    local instance = setmetatable({
        tasks = {}
    }, self)
    return instance
end

--- Schedule a new task for execution.
-- @tparam function task The task function to execute. Should return (isComplete, result, newState).
-- @tparam[opt] function onComplete Callback to invoke when the task completes or errors. Receives (success, result).
-- @tparam[opt=0.1] number interval Time in seconds between task steps.
-- @treturn string The unique task ID.
function TaskScheduler:schedule(task, onComplete, interval)
    interval = interval or 0.1
    local id = uuid()
    local runner = TaskRunner:new(task, function(success, result)
        self.tasks[id] = nil
        if onComplete then
            onComplete(success, result)
        end
    end, interval)
    self.tasks[id] = runner
    runner:start(nil)
    return id
end

--- Cancel a running task.
-- @tparam string taskId The ID of the task to cancel.
-- @treturn boolean True if the task was found and canceled, false otherwise.
function TaskScheduler:cancel(taskId)
    local runner = self.tasks[taskId]
    if runner then
        runner:stop()
        self.tasks[taskId] = nil
        return true
    end
    return false
end

--- Retrieve a running task by ID.
-- @tparam string taskId The ID of the task.
-- @treturn TaskRunner|nil The TaskRunner instance, or nil if not found.
function TaskScheduler:getTask(taskId)
    return self.tasks[taskId]
end

--- List all currently scheduled task IDs.
-- @treturn table Array of task IDs.
function TaskScheduler:listTasks()
    local ids = {}
    for id, _ in pairs(self.tasks) do
        table.insert(ids, id)
    end
    return ids
end

return TaskScheduler
