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

    it("does not schedule a new task with singletonPolicy='ignore' if one is running", function()
        local scheduler = TaskScheduler:new()
        local completed = false

        local id1 = scheduler:schedule(function(state)
            return false, nil, state
        end, function()
            completed = true
        end, 0.1, {
            tag = "ignore",
            singleton = true,
            singletonPolicy = "ignore"
        })

        local id2 = scheduler:schedule(function(state)
            return true, "should not run", state
        end, function()
            completed = true
        end, 0.1, {
            tag = "ignore",
            singleton = true,
            singletonPolicy = "ignore"
        })

        assert.is_not_nil(id1)
        assert.is_nil(id2)
        scheduler:cancel(id1)
        MockTempTimer:advanceTime(0.1)
        assert.is_false(completed)
    end)

    it("replaces the running task with singletonPolicy='replace'", function()
        local scheduler = TaskScheduler:new()
        local results = {}

        local id1 = scheduler:schedule(function(state)
            return false, "first", state
        end, function(success, res)
            results[1] = {success, res}
        end, 0.1, {
            tag = "replace",
            singleton = true,
            singletonPolicy = "replace"
        })

        local id2 = scheduler:schedule(function(state)
            return true, "second", state
        end, function(success, res)
            results[2] = {success, res}
        end, 0.1, {
            tag = "replace",
            singleton = true,
            singletonPolicy = "replace"
        })

        assert.is_not_nil(id1)
        assert.is_not_nil(id2)

        assert.is_nil(results[1])
        assert.same({true, "second"}, results[2])
    end)

    it("queues tasks with singletonPolicy='queue' and runs them in order", function()
        local scheduler = TaskScheduler:new()
        local callOrder = {}

        local id1 = scheduler:schedule(function(state)
            state = (state or 0) + 1
            return state >= 2, "first:" .. state, state
        end, function(success, res)
            table.insert(callOrder, res)
        end, 0.1, {
            tag = "queue",
            singleton = true,
            singletonPolicy = "queue"
        })

        local id2 = scheduler:schedule(function(state)
            state = (state or 0) + 1
            return state >= 1, "second:" .. state, state
        end, function(success, res)
            table.insert(callOrder, res)
        end, 0.1, {
            tag = "queue",
            singleton = true,
            singletonPolicy = "queue"
        })

        assert.is_nil(callOrder[1])
        MockTempTimer:advanceTime(0.1)
        assert.same({"first:2", "second:1"}, callOrder)
    end)

    it("supports independent tags for concurrent singleton tasks", function()
        local scheduler = TaskScheduler:new()
        local completed = {}

        local id1 = scheduler:schedule(function(state)
            return true, "A", state
        end, function(success, res)
            completed[1] = res
        end, 0.1, {
            tag = "tagA",
            singleton = true,
            singletonPolicy = "replace"
        })

        local id2 = scheduler:schedule(function(state)
            return true, "B", state
        end, function(success, res)
            completed[2] = res
        end, 0.1, {
            tag = "tagB",
            singleton = true,
            singletonPolicy = "replace"
        })

        assert.same("A", completed[1])
        assert.same("B", completed[2])
    end)

    it("removes tag from tagIndex after task completion", function()
        local scheduler = TaskScheduler:new()
        local completed = false

        local id = scheduler:schedule(function(state)
            return true, "done", state
        end, function(success, res)
            completed = true
        end, 0.1, {
            tag = "cleanup",
            singleton = true,
            singletonPolicy = "replace"
        })

        assert.is_true(completed)
        assert.is_nil(scheduler.tagIndex["cleanup"])
    end)
end)
