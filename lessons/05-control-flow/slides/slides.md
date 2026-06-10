## Lesson 05
### Control flow

Branch with `if`, loop with `for` — then build FizzBuzz.

Note:
Goal: write a numeric for loop and an if/elseif/else ladder.

---

## if / elseif / else

```lua
if score >= 90 then
  grade = "A"
elseif score >= 80 then
  grade = "B"
else
  grade = "C"
end
```

No parentheses around the condition; `then` … `end`.

---

## Conditions

```lua
a == b    -- equal
a ~= b    -- not equal   (not !=)
a < b   a <= b   a > b   a >= b
```

Only `nil` and `false` are falsy (from L02) — `if x then` runs for `0` and `""` too.

---

## Numeric for

```lua
for i = 1, 5 do print(i) end    -- 1 2 3 4 5
for i = 10, 1, -1 do end         -- count down (step -1)
for i = 1, 0 do end              -- never runs (start > stop)
```

---

## while and repeat

```lua
while n > 0 do
  n = n - 1
end

local k = 0
repeat
  k = k + 1
until k >= 3                     -- runs at least once
```

---

## Generic for (a teaser)

```lua
for index, value in ipairs(list) do end
for key, value in pairs(tbl) do end
```

Iterates tables — the full story is Lesson 08.

---

## break, and the missing continue

```lua
for i = 1, 10 do
  if done then break end         -- exit the loop
end
```

Lua has no `continue`. Use `if/else`, or jump to a label:

```lua
for i = 1, 10 do
  if skip(i) then goto next end
  process(i)
  ::next::
end
```

---

## The exercise — FizzBuzz

```lua
for i = 1, n do
  if i % 15 == 0 then token = "FizzBuzz"
  elseif i % 3 == 0 then token = "Fizz"
  elseif i % 5 == 0 then token = "Buzz"
  else token = tostring(i) end
  -- join tokens with "\n"
end
```

Check `% 15` first!  `make test-lesson LESSON=05-control-flow`

---

## What's next

**Lesson 06 — Functions & testing.**
