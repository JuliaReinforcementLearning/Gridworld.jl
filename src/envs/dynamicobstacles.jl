export DynamicObstacles
using Random

mutable struct DynamicObstacles <: AbstractGridWorld
    world::GridWorldBase{Tuple{Empty,Wall,Obstacle,Goal}}
    agent_pos::CartesianIndex{2}
    agent::Agent
    num_obstacle::Int
    obs_pos_array::Array{CartesianIndex{2},1}
    n::Int
    rng::AbstractRNG
end

function DynamicObstacles(;n = 8, agent_start_pos = CartesianIndex(2,2), agent_start_dir = RIGHT, goal_pos = CartesianIndex(n-1, n-1), num_obstacle = n-3, rng = Random.GLOBAL_RNG)
    objects = (EMPTY, WALL, OBSTACLE, GOAL)
    w = GridWorldBase(objects, n, n)

    w[WALL, [1,n], 1:n] .= true
    w[WALL, 1:n, [1,n]] .= true

    obs_pos_array = Array{CartesianIndex{2},1}(undef,num_obstacle)

    env = DynamicObstacles(w, agent_start_pos, Agent(dir=agent_start_dir), num_obstacle, obs_pos_array, n, rng)

    reset!(env, agent_start_pos = agent_start_pos, agent_start_dir = agent_start_dir, goal_pos = goal_pos)

    return env
end

function (w::DynamicObstacles)(::MoveForward)
    dir = get_dir(w.agent) 
    dest = dir(w.agent_pos)
    if !w.world[WALL, dest]
        
        obstacles_replaced = 0
        
        while obstacles_replaced < w.num_obstacle
            old_pos = w.obs_pos_array[obstacles_replaced+1]
            next_pos = CartesianIndex(old_pos[1]+rand(w.rng, [-1,0,1]),old_pos[2]+rand(w.rng, [-1,0,1])) 
            if (!w.world[WALL, next_pos]) && (next_pos != CartesianIndex(w.n-1,w.n-1))
                flag = 0
                #flag indicates whether 
                #1)the new-position of the kth obstacle overlaps the new-positions of [1,k-1] obstacles
                
                for i = 0:obstacles_replaced-1
                    if (w.obs_pos_array[i+1]==next_pos)
                        
                        flag = 1
                        break
                    end
                end

                if flag == 0
                    
                    w.obs_pos_array[obstacles_replaced+1] = next_pos
                    w.world[OBSTACLE, old_pos] = false
                    w.world[EMPTY, old_pos] = true
                    obstacles_replaced += 1   
                end
            end   
        end
        #println(w.obs_pos_array)
        for obs in w.obs_pos_array
            w.world[OBSTACLE, obs] = true
            w.world[EMPTY, obs] = false
        end
        if w.world[OBSTACLE, dest]
            #end the game
            println("You crashed")
        end
            
        w.agent_pos = dest
    end
    w
end

function RLBase.reset!(w::DynamicObstacles; agent_start_pos = CartesianIndex(2, 2), agent_start_dir = RIGHT, goal_pos = CartesianIndex(size(w.world)[end] - 1, size(w.world)[end] - 1))
    n = size(w.world)[end]
    w.world[EMPTY, 2:n-1, 2:n-1] .= true
    w.world[GOAL, n-1, n-1] = true
    w.world[EMPTY, n-1, n-1] = false

    obs_pos_array = Array{CartesianIndex{2},1}(undef,w.num_obstacle)

    obstacles_placed = 0
    while obstacles_placed < w.num_obstacle
        obs_pos = CartesianIndex(rand(w.rng, 2:n-1), rand(w.rng, 2:n-1))
        if (obs_pos == agent_start_pos) || (w.world[OBSTACLE, obs_pos] == true) || (obs_pos == CartesianIndex(n-1,n-1))
            continue
        else
            w.world[OBSTACLE, obs_pos] = true
            w.world[EMPTY, obs_pos] = false
            obstacles_placed = obstacles_placed + 1
            obs_pos_array[obstacles_placed] = obs_pos
        end
    end
    return w
end
