--- TaskRunner class for executing tasks in steps with intervals.
-- @classmod toasted_task_scheduler.TaskRunner

local TaskRunner = {}
TaskRunner.__index = TaskRunner

--- Create a new TaskRunner instance.
-- @tparam function task The task function to execute. Signature: `function(state) -> isComplete, result, newState`.
-- @tparam function onComplete Callback invoked on completion: `function(success, result)`.
-- @tparam[opt=0.1] number interval Time (in seconds) between task steps.
-- @treturn TaskRunner New TaskRunner instance.
function TaskRunner:new(task, onComplete, interval)
    local instance = setmetatable({
        running = false, -- Whether the task is currently running
        task = task, -- The task function to execute
        onComplete = onComplete, -- Completion callback
        interval = interval or 0.1, -- Time between steps
        state = nil, -- Current task state (persisted between steps)
        steps = 0 -- Number of steps executed
    }, self)
    return instance
end

--- Start executing the task.
-- @tparam[opt] any initialState Initial state to pass to the task function.
function TaskRunner:start(initialState)
    self.running = true
    self.state = initialState
    self.steps = 0
    self:_runStep()
end

--- Stop the task execution.
-- Does not trigger the onComplete callback.
function TaskRunner:stop()
    self.running = false
end

--- Execute a single step of the task.
-- Handles task execution, state management, and scheduling of next step.
function TaskRunner:_runStep()
    if not self.running then
        return
    end

    self.steps = self.steps + 1

    local success, isComplete, result, newState = pcall(function()
        return self.task(self.state)
    end)

    self.state = newState

    if not success then
        -- pcall not successful: isComplete contains error message
        if self.onComplete then
            self.onComplete(false, isComplete)
        end
        self:stop()
        return
    end

    if isComplete then
        -- pcall successful
        if self.onComplete then
            self.onComplete(true, result)
        end
        self:stop()
    else
        -- Schedule next step
        tempTimer(self.interval, function()
            self:_runStep()
        end)
    end
end

return TaskRunner
