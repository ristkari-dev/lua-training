## Lesson 04
### Operators & expressions

Build a whole conditional out of nothing but operators.

Note:
Goal: the arithmetic set, and/or as your only if, .. and #, bitwise, precedence.

---

## Arithmetic

```lua
7 / 2       -- 3.5   (/ is ALWAYS a float)
7 // 2      -- 3     (floor division)
7 % 2       -- 1     (remainder)
-7 // 2     -- -4    (floors toward negative infinity)
-1 % 60     -- 59    (the remainder matches)
```

Note:
// and % agree: the remainder takes the divisor's sign.

---

## ^ is the odd one

```lua
2^3         -- 8.0    (a float, even here)
2^3^2       -- 512.0  (right-associative: 2^(3^2))
-2^2        -- -4.0   (^ binds tighter than unary minus)
(-2)^2      -- 4.0
```

---

## Relational

```lua
"10" == 10  -- false  (different types are never equal)
"10" < 10   -- error: attempt to compare string with number
10 == 10.0  -- true   (same number, different subtype)
```

`==`  `~=`  `<`  `<=`  `>`  `>=`

---

## Logical

```lua
1 and 2     -- 2      (returns an OPERAND, not a boolean)
nil and 2   -- nil    (short-circuits)
nil or 5    -- 5
0 or 5      -- 0      (0 is truthy — only nil and false are falsy)
```

---

## a and b or c — your only if

```lua
pages == 1 and "" or "s"
```

Reads as: if `pages == 1` then `""` else `"s"`.

Until Lesson 05, this is your whole conditional toolkit.

---

## The idiom's one trap

It only works when the middle value can never be `false` or `nil`.

```lua
local flag = true
flag and false or true    -- true   (not false)
```

Note:
false and nil are exactly the two values the idiom cannot carry. Choose strings or numbers.

---

## .. joins, and coerces

```lua
"a" .. "b" .. "c"   -- "abc"
1 .. 2              -- "12"   (numbers coerce to strings)
"5" + 1             -- 6      (and strings coerce in arithmetic)
```

`..` is right-associative.

---

## # measures bytes

```lua
#"hello"    -- 5
#"Äiti"     -- 5   (4 characters, 5 bytes)
#5          -- error: attempt to get length of a number value
```

Note:
# counts bytes, not characters. utf8.len comes in Lesson 17.

---

## Bitwise (new in 5.4)

```lua
3 & 5       -- 1    (and)
3 | 5       -- 7    (or)
3 ~ 5       -- 6    (xor)
~0          -- -1   (not — unary)
1 << 3      -- 8    (shift left)
16 >> 2     -- 4    (shift right)
3.5 & 1     -- error: number has no integer representation
```

---

## Precedence

From tightest to loosest:

```lua
^
not  #  -  ~      (unary)
*  /  //  %
+  -
..
<<  >>
&
~
|
<  >  <=  >=  ~=  ==
and
or
```

`+` and `..` bind tighter than `and`/`or` — so the idiom needs parentheses.
`&` binds tighter than `~`, which binds tighter than `|`.
`&` binds tighter than `~=`.

---

## The exercise — page_label

```lua
local pages = items // per_page + (items % per_page == 0 and 0 or 1)
return pages .. " page" .. (pages == 1 and "" or "s")
```

Both pairs of parentheses are required. Operators only — no `math`.

```bash
make test-lesson LESSON=04-operators
```

---

## What's next

**Lesson 05 — Control flow.** `if` finally arrives.
