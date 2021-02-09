export Maze

mutable struct Maze{R} <: AbstractGridWorld
    world::GridWorldBase{Tuple{Empty, Wall, Goal}}
    agent::Agent
    reward::Float64
    rng::R
    terminal_reward::Float64
    goal_pos::CartesianIndex{2}
end

"""
Maze generation uses the iterative implementation of randomized depth-first search from [Wikipedia](https://en.wikipedia.org/wiki/Maze_generation_algorithm#Iterative_implementation).
"""
function Maze(; height = 9, width = 9, rng = Random.GLOBAL_RNG)
    @assert isodd(height) && isodd(width) "height and width must be odd numbers"
    vertical_range = 2:2:height-1
    horizontal_range = 2:2:width-1

    objects = (EMPTY, WALL, GOAL)
    world = GridWorldBase(objects, height, width)

    world[WALL, :, :] .= true
    for i in vertical_range, j in horizontal_range
        world[WALL, i, j] = false
        world[EMPTY, i, j] = true
    end

    goal_pos = CartesianIndex(height - 1, width - 1)
    world[GOAL, goal_pos] = true
    world[EMPTY, goal_pos] = false

    agent = Agent()
    reward = 0.0
    terminal_reward = 1.0

    env = Maze(world, agent, reward, rng, terminal_reward, goal_pos)

    RLBase.reset!(env)

    return env
end

function generate_maze!(env::Maze)
    world = get_world(env)
    rng = get_rng(env)
    height = get_height(env)
    width = get_width(env)

    vertical_range = 2:2:height-1
    horizontal_range = 2:2:width-1

    visited = falses(height, width)
    stack = DS.Stack{CartesianIndex{2}}()

    first_cell = CartesianIndex(rand(rng, vertical_range), rand(rng, horizontal_range))
    visited[first_cell] = true
    push!(stack, first_cell)

    while !isempty(stack)
        current_cell = pop!(stack)
        candidate_neighbors = get_candidate_neighbors(current_cell)
        neighbors = filter(pos -> (pos.I[1] in vertical_range) && (pos.I[2] in horizontal_range), candidate_neighbors)
        unvisited_neighbors = filter(pos -> !visited[pos], neighbors)
        if length(unvisited_neighbors) > 0
            push!(stack, current_cell)

            next_cell = rand(rng, unvisited_neighbors)

            mid_pos = CartesianIndex((current_cell.I .+ next_cell.I) .÷ 2)
            world[WALL, mid_pos] = false
            world[EMPTY, mid_pos] = true

            visited[next_cell] = true
            push!(stack, next_cell)
        end
    end

    return env
end

function get_candidate_neighbors(pos::CartesianIndex{2})
    shifts = ((-2, 0), (0, -2), (0, 2), (2, 0))
    return map(shift -> CartesianIndex(pos.I .+ shift), shifts)
end

function RLBase.reset!(env::Maze)
    world = get_world(env)
    rng = get_rng(env)
    height = get_height(env)
    width = get_width(env)

    vertical_range = 2:2:height-1
    horizontal_range = 2:2:width-1

    old_goal_pos = get_goal_pos(env)
    world[GOAL, old_goal_pos] = false
    world[EMPTY, old_goal_pos] = true

    world[WALL, :, :] .= true
    world[EMPTY, :, :] .= false
    for i in vertical_range, j in horizontal_range
        world[WALL, i, j] = false
        world[EMPTY, i, j] = true
    end

    generate_maze!(env)

    new_goal_pos = rand(rng, pos -> world[EMPTY, pos], env)

    set_goal_pos!(env, new_goal_pos)
    world[GOAL, new_goal_pos] = true
    world[EMPTY, new_goal_pos] = false

    agent_start_pos = rand(rng, pos -> world[EMPTY, pos], env)
    agent_start_dir = get_agent_start_dir(env)

    set_agent_pos!(env, agent_start_pos)
    set_agent_dir!(env, agent_start_dir)

    set_reward!(env, 0.0)

    return env
end