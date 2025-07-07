--- TaskScheduler class for managing and running asynchronous tasks with
--- singleton and tagging support.
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

function TaskScheduler:new()
    local instance = setmetatable({
        tasks = {}, -- [id] = {runner=TaskRunner, tag=string, singleton=bool, queue=table}
        tagIndex = {} -- [tag] = id
    }, self)
    return instance
end

--- Schedule a new task for execution.
-- @tparam function task The task function to execute. Should return (isComplete, result, newState).
-- @tparam[opt] function onComplete Callback to invoke when the task completes or errors. Receives (success, result).
-- @tparam[opt=0.1] number interval Time in seconds between task steps.
-- @tparam[opt] table opts Optional options: {tag=string, singleton=bool, singletonPolicy="ignore"|"replace"|"queue"}
-- @treturn string|nil The unique task ID, or nil if not scheduled (ignore/queue policy).
function TaskScheduler:schedule(task, onComplete, interval, opts)
    interval = interval or 0.1
    opts = opts or {}
    local tag = opts.tag
    local singleton = opts.singleton
    local singletonPolicy = opts.singletonPolicy or "replace"

    if singleton and tag then
        local existingId = self.tagIndex[tag]
        if existingId then
            local entry = self.tasks[existingId]
            if singletonPolicy == "ignore" then
                return nil
            elseif singletonPolicy == "replace" then
                self:cancel(existingId)
            elseif singletonPolicy == "queue" then
                entry.queue = entry.queue or {}
                table.insert(entry.queue, {
                    task = task,
                    onComplete = onComplete,
                    interval = interval,
                    opts = opts
                })
                return nil
            else
                error("Unknown singletonPolicy: " .. tostring(singletonPolicy))
            end
        end
    end

    local id = uuid()
    local function completion(success, result)
        local entry = self.tasks[id]
        self.tasks[id] = nil
        if tag then
            self.tagIndex[tag] = nil
        end
        if onComplete then
            onComplete(success, result)
        end

        if entry and entry.queue and #entry.queue > 0 then
            local nextTask = table.remove(entry.queue, 1)
            self:schedule(nextTask.task, nextTask.onComplete, nextTask.interval, nextTask.opts)
        end
    end

    local runner = TaskRunner:new(task, completion, interval)

    self.tasks[id] = {
        runner = runner,
        tag = tag,
        singleton = singleton,
        queue = nil
    }
    if tag then
        self.tagIndex[tag] = id
    end
    runner:start(nil)
    return id
end

--- Cancel a running task.
-- @tparam string taskId The ID of the task to cancel.
-- @treturn boolean True if the task was found and canceled, false otherwise.
function TaskScheduler:cancel(taskId)
    local entry = self.tasks[taskId]
    if entry then
        entry.runner:stop()
        if entry.tag then
            self.tagIndex[entry.tag] = nil
        end
        self.tasks[taskId] = nil

        if entry.queue and #entry.queue > 0 then
            local nextTask = table.remove(entry.queue, 1)
            self:schedule(nextTask.task, nextTask.onComplete, nextTask.interval, nextTask.opts)
        end
        return true
    end
    return false
end

--- Cancel all tasks with a given tag.
-- @tparam string tag The tag to cancel.
-- @treturn number The number of tasks canceled.
function TaskScheduler:cancelByTag(tag)
    local count = 0
    for id, entry in pairs(self.tasks) do
        if entry.tag == tag then
            self:cancel(id)
            count = count + 1
        end
    end
    return count
end

--- Retrieve a running task by ID.
-- @tparam string taskId The ID of the task.
-- @treturn TaskRunner|nil The TaskRunner instance, or nil if not found.
function TaskScheduler:getTask(taskId)
    local entry = self.tasks[taskId]
    return entry and entry.runner or nil
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

--- List all tasks with a given tag.
-- @tparam string tag The tag to filter by.
-- @treturn table Array of task IDs with the given tag.
function TaskScheduler:listTasksByTag(tag)
    local ids = {}
    for id, entry in pairs(self.tasks) do
        if entry.tag == tag then
            table.insert(ids, id)
        end
    end
    return ids
end

return TaskScheduler
