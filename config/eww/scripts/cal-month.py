#!/usr/bin/env python3
"""Emit a month grid as JSON for the eww calendar.

Arg: month offset from the current month (0 = this month, -1 = previous, …).
The header fields (today_*) always describe *today*; only the grid/title move
with the offset.
"""
import calendar, datetime, json, sys

offset = int(sys.argv[1]) if len(sys.argv) > 1 else 0
today = datetime.date.today()

# current month + offset, wrapping years correctly
y = today.year + (today.month - 1 + offset) // 12
m = (today.month - 1 + offset) % 12 + 1

weeks = []
for week in calendar.Calendar(firstweekday=0).monthdatescalendar(y, m):
    weeks.append([
        {"d": d.day, "cur": int(d.month == m), "today": int(d == today)}
        for d in week
    ])

print(json.dumps({
    "title": datetime.date(y, m, 1).strftime("%B %Y"),
    "today_weekday": today.strftime("%A"),
    "today_date": today.strftime("%-d %B %Y"),
    "weeks": weeks,
}))
