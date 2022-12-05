local Date = require("cmp_dynamic.utils.date")

---@param cmd string
---@return string
local function exec(cmd)
  local handle = assert(io.popen(cmd))
  local result = handle:read("*a")
  handle:close()
  return vim.trim(result)
end

---@param format string
---@return string
local function gnu_date(format)
  return exec(("date '+%s'"):format(format))
end

---@param fn function
---@param ... any
local function path(fn, ...)
  local ok = pcall(fn, ...)
  assert.is_true(ok)
end

---@param fn function
---@param ... any
local function exception(fn, ...)
  local ok = pcall(fn, ...)
  assert.is_false(ok)
end

describe("Date test", function()
  -- 2022/01/31(Mon) 12:34:56
  ---@type Date
  local date
  before_each(function()
    date = Date.new(2022, 1, 31, 12, 34, 56)
  end)

  it("format", function()
    local new_year_2022 = Date.new(2022)
    assert.equal("Sat Jan 01 00:00:00 2022", new_year_2022:format("%c"))
    assert.equal(
      "2022/22/01/January/Jan/01/ 1/Saturday/Sat/6/00/12/ 0/12/AM/00/00",
      new_year_2022:format("%Y/%y/%m/%B/%b/%d/%e/%A/%a/%w/%H/%I/%k/%l/%p/%M/%S")
    )
  end)

  it("current", function()
    local current_date = Date.new()
    local format = "%Y/%m/%d(%a) %H:%M:%S"
    assert.equal(gnu_date(format), current_date:format(format))
  end)

  describe("setter/getter", function()
    describe("happy path", function()
      it("year", function()
        assert.equal(2022, date:year())
        date:year(2000)
        assert.equal(2000, date:year())
      end)
      it("month", function()
        assert.equal(1, date:month())
        date:month(11)
        assert.equal(11, date:month())
      end)
      it("date", function()
        assert.equal(31, date:date())
        assert.equal(1, date:day())
        date:date(1)
        assert.equal(1, date:date())
        -- 2022/01/01 is Saturday.
        assert.equal(6, date:day())
      end)
      it("day", function()
        assert.equal(1, date:day())
        date:day(6)
        assert.equal("2022/02/05", date:format("%Y/%m/%d"))
      end)
      it("ydate", function()
        assert(31, date:ydate())
        date:ydate(300)
        assert.equal("2022/10/27", date:format("%Y/%m/%d"))
      end)
      it("hours", function()
        assert.equal(12, date:hours())
        date:hours(7)
        assert.equal(7, date:hours())
      end)
      it("minutes", function()
        assert.equal(34, date:minutes())
        date:minutes(7)
        assert.equal(7, date:minutes())
      end)
      it("seconds", function()
        assert.equal(56, date:seconds())
        date:seconds(7)
        assert.equal(7, date:seconds())
      end)
    end)
    describe("unhappy path", function()
      it("month", function()
        exception(date.month, date, 0)
        exception(date.month, date, 13)
      end)
      it("date", function()
        exception(date.date, date, 0)
        exception(date.date, date, 32)
        date:month(2)
        exception(date.date, date, 29)
      end)
      it("day", function()
        exception(date.day, date, -1)
        exception(date.day, date, 7)
      end)
      it("ydate", function()
        assert.equal(2022, date:year())
        exception(date.ydate, date, 0)
        exception(date.ydate, date, 366)
        date:year(2020)
        path(date.ydate, date, 366)
        exception(date.ydate, date, 367)
      end)
      it("hours", function()
        exception(date.hours, date, -1)
        exception(date.hours, date, 25)
      end)
      it("minutes", function()
        exception(date.minutes, date, -1)
        exception(date.minutes, date, 60)
      end)
      it("seconds", function()
        exception(date.seconds, date, -1)
        exception(date.seconds, date, 60)
      end)
    end)
  end)

  describe("add", function()
    it("year", function()
      date:year(2020):month(2):date(29)
      assert.equal("2020/02/29", date:format("%Y/%m/%d"))
      date:add_year(4)
      assert.equal("2024/02/29", date:format("%Y/%m/%d"))
      date:add_year(-3)
      assert.equal("2021/02/28", date:format("%Y/%m/%d"))
    end)
    it("month", function()
      assert.equal("2022/01/31", date:format("%Y/%m/%d"))
      date:add_month(-4)
      assert.equal("2021/09/30", date:format("%Y/%m/%d"))
      date:add_month(10)
      assert.equal("2022/07/30", date:format("%Y/%m/%d"))
    end)
    it("date", function()
      assert.equal("2022/01/31", date:format("%Y/%m/%d"))
      date:add_date(700)
      assert.equal("2024/01/01", date:format("%Y/%m/%d"))
      date:add_date(-700)
      assert.equal("2022/01/31", date:format("%Y/%m/%d"))
    end)
    it("hours", function()
      assert.equal("2022/01/31", date:format("%Y/%m/%d"))
      assert.equal(12, date:hours())
      date:add_hours(100) -- 4h 4m
      assert.equal("2022/02/04", date:format("%Y/%m/%d"))
      assert.equal(16, date:hours())
    end)
    it("minutes", function()
      assert.equal("2022/01/31 12:34:56", date:format("%Y/%m/%d %H:%M:%S"))
      date:add_minutes(1000) -- 16h 40m
      assert.equal("2022/02/01 05:14:56", date:format("%Y/%m/%d %H:%M:%S"))
    end)
    it("seconds", function()
      assert.equal("12:34:56", date:format("%H:%M:%S"))
      date:add_seconds(10000) -- 2h 46m 40s
      assert.equal("15:21:36", date:format("%H:%M:%S"))
    end)
  end)

  describe("set", function()
    it("month name", function()
      local month_name_jp = {
        "1月",
        "2月",
        "3月",
        "4月",
        "5月",
        "6月",
        "7月",
        "8月",
        "9月",
        "10月",
        "11月",
        "12月",
      }
      local month_tbl = { full = month_name_jp, short = month_name_jp }
      -- local
      date:set_month_name(month_tbl)
      assert.equal("1月", date:format("%B"))
      assert.equal("January", Date.new(2022, 1, 1):format("%B"))
      -- global
      Date:set_month_name(month_tbl)
      assert.equal("1月", Date.new(2022, 1, 1):format("%B"))
    end)
    it("day name", function()
      local day_tbl = {
        full = {
          "日曜日",
          "月曜日",
          "火曜日",
          "水曜日",
          "木曜日",
          "金曜日",
          "土曜日",
        },
        short = { "日", "月", "火", "水", "木", "金", "土" },
      }
      -- local
      date:set_day_name(day_tbl)
      assert.equal("月曜日/月", date:format("%A/%a"))
      assert.equal("Monday", Date.new(2022, 1, 31):format("%A"))
      -- global
      Date:set_day_name(day_tbl)
      assert.equal("月曜日/月", Date.new(2022, 1, 31):format("%A/%a"))
    end)
    it("AM/PM", function()
      local am_pm_jp = { "午前", "午後" }
      -- local
      date:set_am_pm_name(am_pm_jp)
      assert.equal("午後", date:format("%p"))
      assert.equal("PM", Date.new(2022, 1, 31, 12, 34, 56):format("%p"))
      -- global
      Date:set_am_pm_name(am_pm_jp)
      assert.equal("午後", Date.new(2022, 1, 31, 12, 34, 56):format("%p"))
    end)
  end)
end)
