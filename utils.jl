function sortby(x::DataFrame, col::Symbol; kwargs...)
    x[sortperm(x[col]; kwargs...), :]
end
sortby(col::Symbol; kwargs...) = x -> sortby(x, col; kwargs...)
