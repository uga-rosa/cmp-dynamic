local utils = require("cmp_dynamic.utils")
local assert_range = utils.assert_range

---@class date_data
---@field year integer
---@field month integer
---@field date integer
---@field hours integer
---@field minutes integer
---@field seconds integer
---@field day integer
---@field ydate integer

---@alias month_name { full: string[], short: string[] }
---@alias day_name { full: string[], short: string[] }
---@alias am_pm_name string[] # { am, pm }

---@class Date
---@field private _data date_data
---@field private _month_name day_name
---@field private _day_name day_name
local Date = {
    _month_name = {
        full = {
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December",
        },
        short = {
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "Jun",
            "Jul",
            "Aug",
            "Sep",
            "Oct",
            "Nov",
            "Dec",
        },
    },
    _day_name = {
        full = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" },
        short = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
    },
    _am_pm_name = { "AM", "PM" },
}
Date.__index = Date

---Month is 1-index
---@param ... integer #year, month, day, hour, min, sec
---@return Date
function Date.new(...)
    ---@type date_data
    local data
    if select("#", ...) == 0 then
        ---@diagnostic disable-next-line
        local t = os.date("*t")
        ---@cast t table
        data = {
            year = t.year,
            month = t.month,
            date = t.day,
            hours = t.hour,
            minutes = t.min,
            seconds = t.sec,
            ydate = t.yday,
        }
    else
        data = {
            year = select(1, ...),
            month = select(2, ...) or 1,
            date = select(3, ...) or 1,
            hours = select(4, ...) or 0,
            minutes = select(5, ...) or 0,
            seconds = select(6, ...) or 0,
        }
        data.ydate = utils.ymd_to_ydate(data.year, data.month, data.date)
    end
    data.day = utils.zeller(data.year, data.month, data.date)
    return setmetatable({ _data = data }, Date)
end

---@param str string
---@return string
function Date:format(str)
    local year = self._data.year
    local month = self._data.month
    local date = self._data.date
    local day = self._data.day
    local hours = self._data.hours
    local minutes = self._data.minutes
    local seconds = self._data.seconds

    str = str:gsub("%%Y", year) -- 2022
    str = str:gsub("%%y", year % 100) -- 22

    str = str:gsub("%%m", ("%02d"):format(month)) -- 01, 12
    str = str:gsub("%%B", self._month_name.full[month]) -- "January", "December"
    str = str:gsub("%%b", self._month_name.short[month]) -- "Jan", "Dec"

    str = str:gsub("%%d", ("%02d"):format(date)) -- 01, 31
    str = str:gsub("%%e", ("%2d"):format(date)) -- " 1", "31"
    -- str = str:gsub("%%j", ?) -- yday; 1, 366
    str = str:gsub("%%A", self._day_name.full[day + 1]) -- "Sunday", "Saturday"
    str = str:gsub("%%a", self._day_name.short[day + 1]) -- "Sun", "Sat"
    str = str:gsub("%%w", day) -- day; Sunday is 0, Saturday is 6.

    local h = hours % 12
    h = h == 0 and 12 or h
    str = str:gsub("%%H", ("%02d"):format(hours)) -- 00, 23
    str = str:gsub("%%h", ("%02d"):format(h)) -- 01, 12
    str = str:gsub("%%k", ("%2d"):format(hours)) -- " 0", "23"
    str = str:gsub("%%l", ("%2d"):format(h)) -- " 1", "12"
    str = str:gsub("%%p", hours < 12 and self._am_pm_name[1] or self._am_pm_name[2]) -- AM, PM

    str = str:gsub("%%M", ("%02d"):format(minutes)) -- 00, 59

    str = str:gsub("%%S", ("%02d"):format(seconds)) -- 00, 59

    return str
end

---@return boolean
function Date:is_leap_year()
    return utils.is_leap_year(self._data.year)
end

---Returns a Date at the end of the month
---@param n integer|nil
---@return integer
function Date:end_date(n)
    if n then
        self:month(n)
    end
    return utils.end_date(self._data.year, self._data.month)
end

function Date:_clamp_date()
    local end_date = self:end_date()
    if self._data.date > end_date then
        self:date(end_date)
    end
end

---Setter if an argument is given, getter if not.
---@param n integer
---@return Date
---@overload fun(self: Date): integer
function Date:year(n)
    if n == nil then
        ---@diagnostic disable-next-line
        return self._data.year
    end
    self._data.year = n
    return self
end

---Setter if an argument is given, getter if not.
---1-index
---@param n integer
---@return Date
---@overload fun(self: Date): integer
function Date:month(n)
    if n == nil then
        ---@diagnostic disable-next-line
        return self._data.month
    end
    assert_range(n, 1, 12)
    self._data.month = n

    self:_clamp_date()

    return self
end

---Setter if an argument is given, getter if not.
---1-index but maximum depends on the month.
---@param n integer
---@return Date
---@overload fun(self: Date): integer
function Date:date(n)
    if n == nil then
        ---@diagnostic disable-next-line
        return self._data.date
    end
    local end_date = self:end_date()
    assert_range(n, 1, end_date)
    local date_diff = n - self._data.date
    self._data.date = n
    self._data.day = (self._data.day + date_diff) % 7
    return self
end

---Setter if an argument is given, getter if not.
---Day of the week; 0 is Sunday and 6 is Saturday
---[0:6]
---@param n integer
---@return Date
---@overload fun(self: Date): integer
function Date:day(n)
    if n == nil then
        ---@diagnostic disable-next-line
        return self._data.day
    end
    assert_range(n, 0, 6)
    local pre_day = self._data.day
    local date_diff = n - pre_day
    self._data.day = n
    self:add_date(date_diff)
    return self
end

---Setter if an argument is given, getter if not.
---'ydate' is total number of days (from 1 to 366) with January 1 as 1.
---@param n integer
---@return Date
---@overload fun(self: Date): integer
function Date:ydate(n)
    if n == nil then
        ---@diagnostic disable-next-line
        return self._data.ydate
    end
    assert_range(n, 1, utils.ydates(self._data.year))

    local ydate_diff = n - self._data.ydate
    self._data.ydate = n
    self._data.month, self._data.date = utils.ydate_to_md(self._data.year, n)
    self._data.day = (self._data.day + ydate_diff) % 7

    return self
end

---Setter if an argument is given, getter if not.
---[0:23]
---@param n integer
---@return Date
---@overload fun(self: Date): integer
function Date:hours(n)
    if n == nil then
        ---@diagnostic disable-next-line
        return self._data.hours
    end
    assert_range(n, 0, 23)
    self._data.hours = n
    return self
end

---Setter if an argument is given, getter if not.
---[0:59]
---@param n integer
---@return Date
---@overload fun(self: Date): integer
function Date:minutes(n)
    if n == nil then
        ---@diagnostic disable-next-line
        return self._data.minutes
    end
    assert_range(n, 0, 59)
    self._data.minutes = n
    return self
end

---Setter if an argument is given, getter if not.
---[0:59]
---@param n integer
---@return Date
---@overload fun(self: Date): integer
function Date:seconds(n)
    if n == nil then
        ---@diagnostic disable-next-line
        return self._data.seconds
    end
    assert_range(n, 0, 59)
    self._data.seconds = n
    return self
end

---@param n integer
---@return Date
function Date:add_year(n)
    vim.validate({ n = { n, "n" } })
    if n == 0 then
        return self
    end

    local pre_year = self._data.year
    self._data.year = self._data.year + n
    if
        utils.is_leap_year(pre_year)
        and self._data.month == 2
        and self._data.date == 29
        and not self:is_leap_year()
    then
        self._data.date = 28
    end

    return self
end

---@param n integer
---@return Date
function Date:add_month(n)
    vim.validate({ n = { n, "n" } })
    if n == 0 then
        return self
    end

    local new_month = self._data.month + n
    self:add_year(utils.idiv(new_month, 12))
    self:month(new_month % 12)

    return self
end

---@param n integer
---@return Date
function Date:add_date(n)
    vim.validate({ n = { n, "n" } })
    if n == 0 then
        return self
    end

    local ydate = self._data.ydate + n
    local year = self._data.year
    while ydate > utils.ydates(year) do
        ydate = ydate - utils.ydates(year)
        year = year + 1
    end
    while ydate <= 0 do
        year = year - 1
        ydate = ydate + utils.ydates(year)
    end

    self:year(year)
    self:ydate(ydate)

    return self
end

---@param n integer
---@return Date
function Date:add_hours(n)
    vim.validate({ n = { n, "n" } })
    if n == 0 then
        return self
    end

    local new_hours = self._data.hours + n
    self:add_date(utils.idiv(new_hours, 24))
    self:hours(new_hours % 24)

    return self
end

---@param n integer
---@return Date
function Date:add_minutes(n)
    vim.validate({ n = { n, "n" } })
    if n == 0 then
        return self
    end

    local new_minutes = self._data.minutes + n
    self:add_hours(utils.idiv(new_minutes, 60))
    self:minutes(new_minutes % 60)

    return self
end

---@param n integer
---@return Date
function Date:add_seconds(n)
    vim.validate({ n = { n, "n" } })
    if n == 0 then
        return self
    end

    local new_seconds = self._data.seconds + n
    self:add_minutes(utils.idiv(new_seconds, 60))
    self:seconds(new_seconds % 60)

    return self
end

---@param tbl month_name
function Date:set_month_name(tbl)
    vim.validate({
        tbl = { tbl, "t" },
        ["tbl.full"] = { tbl.full, "t", true },
        ["tbl.short"] = { tbl.short, "t", true },
    })
    if tbl.full then
        assert(#tbl.full == 12, "The length of tbl.full must be 7.")
    end
    if tbl.short then
        assert(#tbl.short == 12, "The length of tbl.short must be 7.")
    end
    self._month_name = tbl
end

---@param tbl day_name
function Date:set_day_name(tbl)
    vim.validate({
        tbl = { tbl, "t" },
        ["tbl.full"] = { tbl.full, "t", true },
        ["tbl.short"] = { tbl.short, "t", true },
    })
    if tbl.full then
        assert(#tbl.full == 7, "The length of tbl.full must be 7.")
    end
    if tbl.short then
        assert(#tbl.short == 7, "The length of tbl.short must be 7.")
    end
    self._day_name = tbl
end

---@param tbl am_pm_name
function Date:set_am_pm_name(tbl)
    vim.validate({
        tbl = { tbl, "t" },
        am = { tbl[1], "s" },
        pm = { tbl[2], "s" },
    })
    self._am_pm_name = tbl
end

return Date
