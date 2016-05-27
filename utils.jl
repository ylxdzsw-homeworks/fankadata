function sortby(x::DataFrame, col::Symbol; kwargs...)
    x[sortperm(x[col]; kwargs...), :]
end
sortby(col::Symbol; kwargs...) = x -> sortby(x, col; kwargs...)

extract(col::Symbol) = x -> x[col]
extract(col::Vector{Symbol}) = x -> x[col]
