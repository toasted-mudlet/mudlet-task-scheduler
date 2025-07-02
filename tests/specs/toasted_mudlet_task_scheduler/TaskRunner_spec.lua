local TaskRunner = require "toasted_mudlet_task_scheduler.TaskRunner"
local MockTempTimer = require "toasted_mudlet_task_scheduler.MockTempTimer"

describe("TaskRunner", function()
    before_each(function()
        MockTempTimer:reset()
        MockTempTimer:install()
    end)

    after_each(function()
        MockTempTimer:reset()
        MockTempTimer:uninstall()
    end)

    it("executes a multi-step task and calls onComplete with success", function()
        local steps = 0
        local completed, result

        local function task(state)
            steps = steps + 1
            if steps < 3 then
                return false, nil, state
            else
                return true, "done", state
            end
        end

        local function onComplete(success, res)
            completed = success
            result = res
        end

        local runner = TaskRunner:new(task, onComplete, 0.1)
        runner:start(nil)

        -- Simulate timer ticks
        for _ = 1, 3 do
            MockTempTimer:advanceTime(0.1)
        end

        assert.is_true(completed)
        assert.are.equal("done", result)
        assert.are.equal(3, steps)
    end)

    it("calls onComplete with failure if the task errors", function()
        local completed, result

        local function errorTask()
            error("fail!")
        end

        local function onComplete(success, res)
            completed = success
            result = res
        end

        local runner = TaskRunner:new(errorTask, onComplete, 0.1)
        runner:start(nil)

        -- Simulate timer tick
        MockTempTimer:advanceTime(0.1)

        assert.is_false(completed)
        assert.is_truthy(result and result:match("fail!"))
    end)
end)
