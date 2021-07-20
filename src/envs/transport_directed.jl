module TransportDirectedModule

import ..GridWorlds as GW
import Random
import ..TransportUndirectedModule as TUM

mutable struct TransportDirected{R, RNG} <: GW.AbstractGridWorldGame
    env::TUM.TransportUndirected{R, RNG}
    agent_direction::Int
end

const NUM_OBJECTS = TUM.NUM_OBJECTS
const AGENT = TUM.AGENT
const WALL = TUM.WALL
const GEM = TUM.GEM
const TARGET = TUM.TARGET

CHARACTERS = ('☻', '█', '♦', '✖', '→', '↑', '←', '↓', '⋅')

GW.get_tile_map_height(env::TransportDirected) = size(env.env.tile_map, 2)
GW.get_tile_map_width(env::TransportDirected) = size(env.env.tile_map, 3)

function GW.get_tile_pretty_repr(env::TransportDirected, i::Integer, j::Integer)
    object = findfirst(@view env.env.tile_map[:, i, j])
    if isnothing(object)
        return CHARACTERS[end]
    elseif object == AGENT
        return CHARACTERS[NUM_OBJECTS + 1 + env.agent_direction]
    else
        return CHARACTERS[object]
    end
end

const NUM_ACTIONS = 6
GW.get_action_keys(env::TransportDirected) = ('w', 's', 'a', 'd', 'p', 'l')
GW.get_action_names(env::TransportDirected) = (:MOVE_FORWARD, :MOVE_BACKWARD, :TURN_LEFT, :TURN_RIGHT, :PICK_UP, :DROP)

function TransportDirected(; R = Float32, height = 8, width = 8, rng = Random.GLOBAL_RNG)
    env = TUM.TransportUndirected(R = R, height = height, width = width, rng = rng)
    agent_direction = rand(rng, 0:GW.NUM_DIRECTIONS-1)
    env = TransportDirected(env, agent_direction)
    GW.reset!(env)
    return env
end

function GW.reset!(env::TransportDirected)
    GW.reset!(env.env)
    env.agent_direction = rand(env.env.rng, 0:GW.NUM_DIRECTIONS-1)
    return nothing
end

function GW.act!(env::TransportDirected, action)
    @assert action in 1:NUM_ACTIONS "Invalid action $(action)"

    inner_env = env.env
    tile_map = inner_env.tile_map
    agent_position = inner_env.agent_position
    agent_direction = env.agent_direction

    if action in 1:2
        if action == 1
            new_agent_position = CartesianIndex(GW.move_forward(agent_direction, agent_position.I...))
        else
            new_agent_position = CartesianIndex(GW.move_backward(agent_direction, agent_position.I...))
        end

        if !tile_map[WALL, new_agent_position]
            tile_map[AGENT, agent_position] = false
            inner_env.agent_position = new_agent_position
            tile_map[AGENT, new_agent_position] = true
        end
    elseif action == 3
        env.agent_direction = GW.turn_left(agent_direction)
    elseif action == 4
        env.agent_direction = GW.turn_right(agent_direction)
    elseif action == 5 && tile_map[GEM, agent_position]
        tile_map[GEM, agent_position] = false
        inner_env.has_gem = true
    elseif action == 6 && inner_env.has_gem
        inner_env.has_gem = false
        inner_env.gem_position = agent_position
        tile_map[GEM, agent_position] = true
    end

    if tile_map[GEM, inner_env.target_position]
        inner_env.reward = inner_env.terminal_reward
        inner_env.done = true
    else
        inner_env.reward = zero(inner_env.reward)
        inner_env.done = false
    end

    return nothing
end

function Base.show(io::IO, ::MIME"text/plain", env::TransportDirected)
    str = GW.get_tile_map_pretty_repr(env)
    str = str * "\nreward = $(env.env.reward)\ndone = $(env.env.done)\nhas_gem = $(env.env.has_gem)"
    print(io, str)
    return nothing
end

end # module
