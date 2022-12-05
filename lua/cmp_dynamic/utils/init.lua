local floor = math.floor

local utils = {}

---floor division
---@param a integer
---@param b integer
---@return integer
function utils.idiv(a, b)
  return floor(a / b)
end

---@param v number
---@param min number
---@param max number
function utils.assert_range(v, min, max)
  assert(min <= v and v <= max, ("out of range [%s:%s]: %s"):format(min, max, v))
end

---Gregorian
---@param year integer
---@param month integer 1-12
---@param date integer
---@return integer day 0 is Sunday, 6 is Saturday.
function utils.zeller(year, month, date)
  if month <= 2 then
    year = year - 1
    month = month + 12
  end
  local C = floor(year / 100)
  local Y = year % 100
  local Gamma = -2 * C + floor(C / 4)
  local h = (date + floor(26 * (month + 1) / 10) + Y + floor(Y / 4) + Gamma + 6) % 7
  return h
end

---@param year integer
---@return boolean
function utils.is_leap_year(year)
  if year % 400 == 0 then
    return true
  elseif year % 100 == 0 then
    return false
  elseif year % 4 == 0 then
    return true
  else
    return false
  end
end

---@param year integer
---@param month integer
---@return integer
function utils.end_date(year, month)
  if vim.tbl_contains({ 1, 3, 5, 7, 8, 10, 12 }, month) then
    return 31
  elseif month ~= 2 then
    return 30
  elseif utils.is_leap_year(year) then
    return 29
  else
    return 28
  end
end

---@param year integer
---@return integer
function utils.ydates(year)
  return utils.is_leap_year(year) and 366 or 365
end

---Calculate ydate from year, month, and date.
---'ydate' is the total number of days (from 1 to 366) with January 1 as 1.
---@param year integer
---@param month integer
---@param date integer
---@return integer ydate
function utils.ymd_to_ydate(year, month, date)
  local ydate = 0
  for i = 1, month - 1 do
    ydate = ydate + utils.end_date(year, i)
  end
  ydate = ydate + date
  return ydate
end

---Calculate month and date from year and ydate.
---'ydate' is the total number of days (from 1 to 366) with January 1 as 1.
---@param year integer
---@param ydate integer
---@return integer month
---@return integer date
function utils.ydate_to_md(year, ydate)
  local month = 0
  while true do
    month = month + 1
    local end_date = utils.end_date(year, month)
    if end_date < ydate then
      ydate = ydate - end_date
    else
      break
    end
  end
  return month, ydate
end

return utils
