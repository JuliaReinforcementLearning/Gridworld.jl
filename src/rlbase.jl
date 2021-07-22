struct RLBaseEnv{E} <: RLBase.AbstractEnv
    env::E
end

Base.show(io::IO, mime::MIME"text/plain", env::RLBaseEnv{E}) where {E <: AbstractGridWorld} = show(io, mime, env.env)
Play.play!(terminal::REPL.Terminals.UnixTerminal, env::RLBaseEnv{E}; file_name::Union{Nothing, AbstractString} = nothing) where {E <: AbstractGridWorld} = Play.play!(terminal, env.env, file_name = file_name)
Play.play!(env::RLBaseEnv{E}; file_name = nothing) where {E <: AbstractGridWorld} = Play.play!(REPL.TerminalMenus.terminal, env.env, file_name = file_name)
get_action_names(env::RLBaseEnv{E}) where {E <: AbstractGridWorld} = get_action_names(env.env)
