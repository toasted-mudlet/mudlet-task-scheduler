local TaskScheduler = require "toasted_mudlet_task_scheduler.TaskScheduler"
local MockTempTimer = require "toasted_mudlet_task_scheduler.MockTempTimer"

describe("TaskScheduler", function()
    before_each(function()
        MockTempTimer:reset()
        MockTempTimer:install()
    end)

    after_each(function()
        MockTempTimer:reset()
        MockTempTimer:uninstall()
    end)

    it("executes a simple task to completion", function()
        local scheduler = TaskScheduler:new()
        local result

        scheduler:schedule(function(state)
            state = (state or 0) + 1
            return state >= 2, state, state
        end, function(success, res)
            result = {success, res}
        end, 0.1)

        assert.is_nil(result)
        MockTempTimer:advanceTime(0.1)
        assert.same({true, 2}, result)
    end)

    it("handles multiple concurrent tasks independently", function()
        local scheduler = TaskScheduler:new()
        local results = {}

        scheduler:schedule(function(state)
            state = (state or 0) + 1
            return state >= 2, "A:" .. state, state
        end, function(success, res)
            results[1] = {success, res}
        end, 0.1)

        scheduler:schedule(function(state)
            state = (state or 0) + 1
            return state >= 3, "B:" .. state, state
        end, function(success, res)
            results[2] = {success, res}
        end, 0.1)

        assert.is_nil(results[1])
        assert.is_nil(results[2])

        -- Advance time in steps
        MockTempTimer:advanceTime(0.1)
        assert.same({true, "A:2"}, results[1])
        assert.is_nil(results[2])

        MockTempTimer:advanceTime(0.1)
        assert.same({true, "A:2"}, results[1])
        assert.same({true, "B:3"}, results[2])

        MockTempTimer:advanceTime(0.1)
    end)

    it("calls onComplete with failure if the task errors", function()
        local scheduler = TaskScheduler:new()
        local completed, result

        scheduler:schedule(function()
            error("fail!")
        end, function(success, res)
            completed = success
            result = res
        end, 0.1)

        MockTempTimer:advanceTime(0.1)
        assert.is_false(completed)
        assert.is_truthy(result and result:match("fail!"))
    end)

    it("does not call onComplete if task is cancelled (if supported)", function()
        local scheduler = TaskScheduler:new()
        local called = false

        local id = scheduler:schedule(function(state)
            return false, nil, state
        end, function()
            called = true
        end, 0.1)

        scheduler:cancel(id)
        MockTempTimer:advanceTime(1)
        assert.is_false(called)
    end)
end)
