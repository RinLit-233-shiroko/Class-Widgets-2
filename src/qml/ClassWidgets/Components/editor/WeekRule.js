/*
 * Canonical week-rule handling for the schedule editor.
 *
 * This is a stateless helper library: it only exposes pure functions, so every
 * importer gets the same behaviour. Do not add a `.pragma library` line -- the
 * Qt JS parser used by this project rejects the directive and fails to load
 * the whole file.
 *
 * The schedule format stores a week rule in exactly four shapes:
 *
 *   "all"            every week
 *   "odd" / "even"   absolute semester week parity (单双周)
 *   <int>            position inside meta.maxWeekCycle (多周轮换), 1 ... cycle
 *   <int[]>          absolute semester weeks (指定周)
 *
 * Rules reach QML in two very different ways and both must behave identically:
 *
 *   * as a real JS value, e.g. the encoded `weeks` role of the override model;
 *   * straight from a C++ property, e.g. ScheduleEditor.days / .overrides.
 *
 * A Python list crosses the C++/QML boundary as an array-like sequence, not as
 * a JS Array: `Array.isArray()` is false, `Number()` is NaN and `String()`
 * yields "1,4" instead of "[1,4]". Every type check below therefore duck-types
 * on a numeric `length` instead of trusting `Array.isArray()`.
 */

function isList(value) {
    return !!value && typeof value === "object"
        && typeof value.length === "number"
        && typeof value.join === "function"
}

// 1-based integer, or 0 when the value cannot be used as a week number.
function naturalNumber(value) {
    if (typeof value === "boolean")
        return 0
    const number = Number(value)
    if (!isFinite(number))
        return 0
    const integer = Math.floor(number)
    return integer >= 1 ? integer : 0
}

function uniqueWeeks(value) {
    const result = []
    if (!isList(value))
        return result
    for (let i = 0; i < value.length; ++i) {
        const week = naturalNumber(value[i])
        if (week >= 1 && result.indexOf(week) === -1)
            result.push(week)
    }
    result.sort(function(left, right) { return left - right })
    return result
}

// Normalize anything into one of the four canonical shapes. An empty specific
// list stays empty ("matches no week") and never collapses into "all".
function normalize(value) {
    if (value === null || value === undefined || value === "")
        return "all"
    if (isList(value))
        return uniqueWeeks(value)
    if (typeof value === "number")
        return naturalNumber(value) >= 1 ? naturalNumber(value) : "all"
    if (typeof value === "boolean")
        return "all"

    const text = String(value).trim().toLowerCase()
    if (text === "all" || text === "week" || text === "every")
        return "all"
    if (text === "odd" || text === "even")
        return text
    if (text.charAt(0) === "[") {
        try {
            return normalize(JSON.parse(text))
        } catch (error) {
            return "all"
        }
    }
    // Legacy transport of specific weeks: a Python list stringified by the
    // QML engine as "1,4" instead of "[1,4]".
    if (text.indexOf(",") !== -1) {
        const parts = text.split(",")
        const weeks = []
        for (let i = 0; i < parts.length; ++i) {
            const week = naturalNumber(parts[i])
            if (week >= 1 && weeks.indexOf(week) === -1)
                weeks.push(week)
        }
        if (weeks.length === parts.length) {
            weeks.sort(function(left, right) { return left - right })
            return weeks
        }
    }
    const number = naturalNumber(text)
    return number >= 1 ? number : "all"
}

// "all" | "odd" | "even" | "cycle" | "specific"
function kind(value) {
    const rule = normalize(value)
    if (rule === "all" || rule === "odd" || rule === "even")
        return rule
    return isList(rule) ? "specific" : "cycle"
}

function isParity(value) {
    const type = kind(value)
    return type === "odd" || type === "even"
}

function specificWeeks(value) {
    const rule = normalize(value)
    return isList(rule) ? rule : []
}

// Absolute semester week -> cycle position, mirroring get_cycle_week().
function cycleWeek(absoluteWeek, cycle) {
    const length = Math.max(1, Math.floor(Number(cycle) || 1))
    const week = Math.floor(Number(absoluteWeek))
    if (!isFinite(week))
        return 1
    if (week >= 1)
        return ((week - 1) % length) + 1
    return (((week % length) + length) % length) + 1
}

// Cycle position -> absolute week of the currently displayed week, for rules
// that are edited as a cycle position but stored as one (多周轮换).
function matches(value, absoluteWeek, cycle) {
    const rule = normalize(value)
    if (rule === "all")
        return true
    if (rule === "odd")
        return absoluteWeek % 2 === 1
    if (rule === "even")
        return absoluteWeek % 2 === 0
    if (isList(rule))
        return rule.indexOf(absoluteWeek) !== -1
    return cycleWeek(absoluteWeek, cycle) === rule
}

function equals(left, right) {
    const a = normalize(left)
    const b = normalize(right)
    if (isList(a) || isList(b)) {
        if (!isList(a) || !isList(b) || a.length !== b.length)
            return false
        for (let i = 0; i < a.length; ++i) {
            if (a[i] !== b[i])
                return false
        }
        return true
    }
    return a === b
}

// Transport form used by the override model roles: a scalar string, or JSON
// for a specific-week list.
function encode(value) {
    const rule = normalize(value)
    return isList(rule) ? JSON.stringify(rule) : String(rule)
}

function decode(value) {
    return normalize(value)
}

// Display helper shared by the timeline list and the debugger. The caller adds
// its own translated prefix.
function describe(value) {
    const rule = normalize(value)
    if (isList(rule))
        return rule.join(", ")
    return String(rule)
}

// ── Day-of-week lists (same C++/QML boundary problem) ──────────────────────

function dayList(value) {
    if (value === null || value === undefined)
        return []
    if (isList(value))
        return uniqueDays(value)
    if (typeof value === "number")
        return naturalNumber(value) <= 7 ? [naturalNumber(value)] : []
    const text = String(value).trim()
    if (text.charAt(0) === "[") {
        try {
            return dayList(JSON.parse(text))
        } catch (error) {
            return []
        }
    }
    if (text.indexOf(",") !== -1)
        return uniqueDays(text.split(","))
    const day = naturalNumber(text)
    return day >= 1 && day <= 7 ? [day] : []
}

function uniqueDays(value) {
    const result = []
    for (let i = 0; i < value.length; ++i) {
        const day = naturalNumber(value[i])
        if (day >= 1 && day <= 7 && result.indexOf(day) === -1)
            result.push(day)
    }
    result.sort(function(left, right) { return left - right })
    return result
}

function encodeDays(value) {
    return JSON.stringify(dayList(value))
}

function dayMatches(value, dayOfWeek) {
    const days = dayList(value)
    return days.length === 0 || days.indexOf(dayOfWeek) !== -1
}

function daysEqual(left, right) {
    const a = dayList(left)
    const b = dayList(right)
    if (a.length !== b.length)
        return false
    for (let i = 0; i < a.length; ++i) {
        if (a[i] !== b[i])
            return false
    }
    return true
}
