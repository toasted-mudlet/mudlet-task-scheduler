local pkg = require "toasted_mudlet_task_scheduler"

describe("toasted_mudlet_task_scheduler package init", function()
    it("includes TaskScheduler", function()
        assert.is_table(pkg.TaskScheduler)
        assert.is_function(pkg.TaskScheduler.new)
        assert.is_function(pkg.TaskScheduler.schedule)
    end)

    it("includes TaskRunner", function()
        assert.is_table(pkg.TaskRunner)
        assert.is_function(pkg.TaskRunner.new)
        assert.is_function(pkg.TaskRunner.start)
    end)

    it("includes MockTempTimer", function()
        assert.is_table(pkg.MockTempTimer)
        assert.is_function(pkg.MockTempTimer.install)
    end)
end)
