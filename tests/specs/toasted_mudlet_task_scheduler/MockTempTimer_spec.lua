local MockTempTimer = require "toasted_mudlet_task_scheduler.MockTempTimer"

describe("MockTempTimer", function()
    before_each(function()
        MockTempTimer:reset()
        MockTempTimer:install()
    end)

    after_each(function()
        MockTempTimer:reset()
        MockTempTimer:uninstall()
    end)

    it("schedules and fires a timer after advancing time", function()
        local fired = false
        tempTimer(0.5, function()
            fired = true
        end)
        MockTempTimer:advanceTime(0.4)
        assert.is_false(fired)
        MockTempTimer:advanceTime(0.1)
        assert.is_true(fired)
    end)

    it("fires multiple timers in chronological order", function()
        local order = {}
        tempTimer(0.2, function()
            table.insert(order, "first")
        end)
        tempTimer(0.5, function()
            table.insert(order, "second")
        end)
        tempTimer(0.3, function()
            table.insert(order, "third")
        end)
        MockTempTimer:advanceTime(0.2)
        assert.same({"first"}, order)
        MockTempTimer:advanceTime(0.1)
        assert.same({"first", "third"}, order)
        MockTempTimer:advanceTime(0.2)
        assert.same({"first", "third", "second"}, order)
    end)

    it("supports timer cancellation with killTimer", function()
        local fired = false
        local id = tempTimer(0.2, function()
            fired = true
        end)
        killTimer(id)
        MockTempTimer:advanceTime(0.3)
        assert.is_false(fired)
    end)

    it("restores original tempTimer and killTimer on uninstall", function()
        local origTempTimer = function()
        end
        local origKillTimer = function()
        end
        _G.tempTimer = origTempTimer
        _G.killTimer = origKillTimer
        MockTempTimer:install()
        MockTempTimer:uninstall()
        assert.is_true(_G.tempTimer == origTempTimer)
        assert.is_true(_G.killTimer == origKillTimer)
    end)

    it("handles string callbacks via loadstring", function()
        _G.someGlobal = 0
        tempTimer(0.1, "someGlobal = 42")
        MockTempTimer:advanceTime(0.1)
        assert.are.equal(42, _G.someGlobal)
        _G.someGlobal = nil
    end)

    it("returns unique timer IDs", function()
        local id1 = tempTimer(1, function()
        end)
        local id2 = tempTimer(1, function()
        end)
        assert.not_equal(id1, id2)
    end)

    it("getPendingTimers returns only active timers", function()
        local id1 = tempTimer(0.2, function()
        end)
        local id2 = tempTimer(0.5, function()
        end)
        killTimer(id1)
        local pending = MockTempTimer:getPendingTimers()
        assert.are.equal(1, #pending)
        assert.are.equal(id2, pending[1].id)
    end)
end)
