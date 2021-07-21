abstract type AbstractGridWorldGame end

#####
##### Game logic methods
#####

reset!(env::AbstractGridWorldGame) = error("Method not implemented for $(typeof(env))")
act!(env::AbstractGridWorldGame) = error("Method not implemented for $(typeof(env))")

#####
##### Optional methods for pretty printing, playing, etc...
#####

get_tile_pretty_repr(env::AbstractGridWorldGame, i::Integer, j::Integer) = error("Method not implemented for $(typeof(env))")
get_sub_tile_map_pretty_repr(env::AbstractGridWorldGame, position::CartesianIndex{2}) = error("Method not implemented for $(typeof(env))")
get_action_keys(env::AbstractGridWorldGame) = error("Method not implemented for $(typeof(env))")
get_action_names(env::AbstractGridWorldGame) = error("Method not implemented for $(typeof(env))")
get_tile_map_height(env::AbstractGridWorldGame) = error("Method not implemented for $(typeof(env))")
get_tile_map_width(env::AbstractGridWorldGame) = error("Method not implemented for $(typeof(env))")

function get_tile_map_pretty_repr(env::AbstractGridWorldGame)
    height_tile_map = get_tile_map_height(env)
    width_tile_map = get_tile_map_width(env)

    str = ""

    for i in 1:height_tile_map
        for j in 1:width_tile_map
            str = str * get_tile_pretty_repr(env, i, j)
        end
        if i < height_tile_map
            str = str * "\n"
        end
    end

    return str
end

function get_window_size(env::AbstractGridWorldGame)
    height = get_tile_map_height(env)
    width = get_tile_map_width(env)
    return (2 * (height ÷ 4) + 1, 2 * (width ÷ 4) + 1)
end

function get_sub_tile_map_pretty_repr(env::AbstractGridWorldGame, window_size)
    height_sub_tile_map, width_sub_tile_map = window_size

    str = ""

    for i in 1:height_sub_tile_map
        for j in 1:width_sub_tile_map
            str = str * get_sub_tile_map_pretty_repr(env, window_size, CartesianIndex(i, j))
        end
        if i < height_sub_tile_map
            str = str * "\n"
        end
    end

    return str
end


#####
##### Sub tile map
#####

function get_window_region((i, j), (m, n))
    temp1 = m ÷ 2
    temp2 = i - temp1
    temp3 = n ÷ 2
    temp4 = j - temp3
    return CartesianIndices((temp2 : temp2 + m - 1, temp4 : temp4 + n - 1))
end

function get_sub_tile_map(tile_map, position, window_size)
    num_objects = size(tile_map, 1)
    sub_tile_map = falses(num_objects, window_size...)
    get_sub_tile_map!(sub_tile_map, tile_map, position, window_size)
    return sub_tile_map
end

function get_sub_tile_map!(sub_tile_map, tile_map, position, window_size)
    _, height, width = size(tile_map)

    window_region = get_window_region(position.I, window_size)

    valid_region = CartesianIndices((1 : height, 1 : width))

    @views for key in keys(window_region)
        pos = window_region[key]
        if pos in valid_region
            sub_tile_map[:, key] .= tile_map[:, pos]
        end
    end

    return nothing
end

function get_window_region((i, j), (m, n), direction)
    if direction == RIGHT_DIRECTION
        temp1 = n - 1
        temp2 = temp1 ÷ 2
        temp3 = i - temp2
        return CartesianIndices((temp3 : temp3 + temp1, j : j + m - 1))
    elseif direction == UP_DIRECTION
        temp1 = n - 1
        temp2 = temp1 ÷ 2
        temp3 = j - temp2
        return CartesianIndices((i - m + 1 : i, temp3 : temp3 + temp1))
    elseif direction == LEFT_DIRECTION
        temp1 = n - 1
        temp2 = temp1 ÷ 2
        temp3 = i - temp2
        return CartesianIndices((temp3 : temp3 + temp1, j - m + 1 : j))
    else
        temp1 = n - 1
        temp2 = temp1 ÷ 2
        temp3 = j - temp2
        return CartesianIndices((i : i + m - 1, temp3 : temp3 + temp1))
    end
end

function map_index((i,j), (m, n), direction)
    if direction == RIGHT_DIRECTION
        return (j, n-i+1)
    elseif direction == UP_DIRECTION
        return (m-i+1, n-j+1)
    elseif direction == LEFT_DIRECTION
        return (m-j+1, i)
    else
        return (i,j)
    end
end

function get_sub_tile_map(tile_map, position, window_size, direction)
    num_objects = size(tile_map, 1)
    sub_tile_map = falses(num_objects, window_size...)
    get_sub_tile_map!(sub_tile_map, tile_map, position, window_size, direction)
    return sub_tile_map
end

function get_sub_tile_map!(sub_tile_map, tile_map, position, window_size, direction)
    _, height, width = size(tile_map)

    window_region = get_window_region(position.I, window_size, direction)

    valid_region = CartesianIndices((1 : height, 1 : width))

    @views for key in keys(window_region)
        pos = window_region[key]
        if pos in valid_region
            sub_tile_map[:, map_index(key.I, window_size, direction)...] .= tile_map[:, pos]
        end
    end

    return nothing
end
