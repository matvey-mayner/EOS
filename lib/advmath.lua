local advmath = {}

function advmath.map(value, low, high, low_2, high_2)
    local relative_value = (value - low) / (high - low)
    local scaled_value = low_2 + (high_2 - low_2) * relative_value
    return scaled_value
end

function advmath.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

function advmath.clampMap(value, low, high, low_2, high_2)
    return advmath.map(advmath.clamp(value, low, high), low, high, low_2, high_2)
end

return advmath