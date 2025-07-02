local MockTempTimer = {}
MockTempTimer.timers = {}
MockTempTimer.nextTimerId = 1
MockTempTimer.currentTime = 0
MockTempTimer.originalTempTimer = nil
MockTempTimer.originalKillTimer = nil

function MockTempTimer:install()
    self.originalTempTimer = _G.tempTimer
    self.originalKillTimer = _G.killTimer
    _G.tempTimer = function(delay, callback)
        local timerId = self.nextTimerId
        self.nextTimerId = self.nextTimerId + 1
        table.insert(self.timers, {
            id = timerId,
            delay = delay,
            callback = callback,
            createdAt = self.currentTime,
            cancelled = false
        })
        return timerId
    end
    _G.killTimer = function(timerId)
        for _, timer in ipairs(self.timers) do
            if timer.id == timerId then
                timer.cancelled = true
                break
            end
        end
    end
end

function MockTempTimer:uninstall()
    if self.originalTempTimer then
        _G.tempTimer = self.originalTempTimer
        self.originalTempTimer = nil
    end
    if self.originalKillTimer then
        _G.killTimer = self.originalKillTimer
        self.originalKillTimer = nil
    end
end

function MockTempTimer:reset()
    self.timers = {}
    self.nextTimerId = 1
    self.currentTime = 0
end

function MockTempTimer:advanceTime(seconds)
    self.currentTime = self.currentTime + seconds

    table.sort(self.timers, function(a, b)
        return (a.createdAt + a.delay) < (b.createdAt + b.delay)
    end)
    local i = 1
    while i <= #self.timers do
        local timer = self.timers[i]
        if not timer.cancelled and self.currentTime >= timer.createdAt + timer.delay then
            table.remove(self.timers, i)
            if type(timer.callback) == "function" then
                timer.callback()
            elseif type(timer.callback) == "string" then
                loadstring(timer.callback)()
            end
        else
            i = i + 1
        end
    end
end

function MockTempTimer:getTime()
    return self.currentTime
end

function MockTempTimer:getPendingTimers()
    local copy = {}
    for _, timer in ipairs(self.timers) do
        if not timer.cancelled then
            table.insert(copy, timer)
        end
    end
    return copy
end

_G.MockTempTimer = MockTempTimer

return MockTempTimer
