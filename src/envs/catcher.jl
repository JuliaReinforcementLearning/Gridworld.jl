export Catcher

mutable struct Catcher{R} <: AbstractGridWorld
    world::GridWorldBase{Tuple{Empty, Basket, Ball}}
    agent::Agent
    reward::Float64
    rng::R
    terminal_reward::Float64
    ball_reward::Float64
    ball_pos::CartesianIndex{2}
end

function Catcher(; height = 8, width = 8, rng = Random.GLOBAL_RNG)
    objects = (EMPTY, BASKET, BALL)
    world = GridWorldBase(objects, height, width)

    world[EMPTY, :, :] .= true

    ball_pos = CartesianIndex(1, 1)
    world[BALL, ball_pos] = true
    world[EMPTY, ball_pos] = false

    agent_start_pos = CartesianIndex(height, 1)
    agent_start_dir = CENTER
    agent = Agent(pos = agent_start_pos, dir = agent_start_dir)
    world[BASKET, agent_start_pos] = true
    world[EMPTY, agent_start_pos] = false

    reward = 0.0
    terminal_reward = -1.0
    ball_reward = 1.0

    env = Catcher(world, agent, reward, rng, terminal_reward, ball_reward, ball_pos)

    RLBase.reset!(env)

    return env
end

get_navigation_style(::Catcher) = UNDIRECTED_NAVIGATION
RLBase.StateStyle(env::Catcher) = RLBase.InternalState{Any}()
RLBase.is_terminated(env::Catcher) = (env.ball_pos[1] == get_height(env)) && !(get_world(env)[BASKET, env.ball_pos])
RLBase.action_space(env::Catcher, player::RLBase.DefaultPlayer) = (MOVE_LEFT, MOVE_RIGHT, MOVE_CENTER)

function (env::Catcher)(action::Union{MoveLeft, MoveRight, MoveCenter})
    world = get_world(env)
    height = get_height(env)
    old_agent_pos = get_agent_pos(env)
    old_ball_pos = env.ball_pos

    new_agent_pos = move(action, old_agent_pos)
    new_agent_pos = wrap_basket(env, new_agent_pos)

    new_ball_pos = move(DOWN, old_ball_pos)
    new_ball_pos = wrap_ball(env, new_ball_pos)

    world[BASKET, old_agent_pos] = false
    if !world[BALL, old_agent_pos]
        world[EMPTY, old_agent_pos] = true
    end
    set_agent_pos!(env, new_agent_pos)
    world[BASKET, new_agent_pos] = true
    world[EMPTY, new_agent_pos] = false

    world[BALL, old_ball_pos] = false
    if !world[BASKET, old_ball_pos]
        world[EMPTY, old_ball_pos] = true
    end
    env.ball_pos = new_ball_pos
    world[BALL, new_ball_pos] = true
    world[EMPTY, new_ball_pos] = false

    if new_ball_pos[1] == height
        if new_ball_pos[2] == new_agent_pos[2]
            set_reward!(env, env.ball_reward)
        else
            set_reward!(env, env.terminal_reward)
        end
    else
        set_reward!(env, 0.0)
    end

    return env
end

function RLBase.reset!(env::Catcher)
    world = get_world(env)
    rng = get_rng(env)
    height = get_height(env)
    width = get_width(env)

    old_ball_pos = env.ball_pos
    world[BALL, old_ball_pos] = false
    world[EMPTY, old_ball_pos] = true

    agent_pos = get_agent_pos(env)
    world[BASKET, agent_pos] = false
    world[EMPTY, agent_pos] = true

    new_ball_pos = CartesianIndex(1, rand(rng, 1:width))

    env.ball_pos = new_ball_pos
    world[BALL, new_ball_pos] = true
    world[EMPTY, new_ball_pos] = false

    agent_start_pos = CartesianIndex(height, rand(rng, 1:width))

    world[BASKET, agent_start_pos] = true
    world[EMPTY, agent_start_pos] = false

    agent_start_dir = get_agent_start_dir(env)

    set_agent_pos!(env, agent_start_pos)
    set_agent_dir!(env, agent_start_dir)

    set_reward!(env, 0.0)

    return env
end

show_agent_char(env::Catcher) = false

function wrap_ball(env::Catcher, pos::CartesianIndex{2})
    height = get_height(env)
    width = get_width(env)
    rng = get_rng(env)
    i = pos[1]

    if i > height
        return CartesianIndex(1, rand(rng, 1:width))
    else
        return pos
    end
end

function wrap_basket(env::Catcher, pos::CartesianIndex{2})
    height = get_height(env)
    width = get_width(env)
    i = pos[1]
    j = pos[2]

    if j < 1
        return CartesianIndex(i, width)
    elseif j > width
        return CartesianIndex(i, 1)
    else
        return pos
    end
end