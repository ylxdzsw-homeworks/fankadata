using DataFrames
using ProgressMeter

include("utils.jl")

df = readtable("./data/transactions.csv")

df[:datetime] = map(x->DateTime(x, "yyyy/mm/dd HH:MM:SS"), df[:datetime])
df = df[df[:category].=="持卡人消费", [:datetime, :id, :position]]
df[:count] = 1

# 删除两个月消费不超过50次的同学
temp = df[[:id, :count]] |> groupby(:id) |> sum
temp = temp[temp[:count_sum] .> 50, :id]

df = @time df[Bool[x in temp for x in df[:id]], :]

students = df[:id] |> unique
nstudents = length(students)

relations = zeros(Int, nstudents, nstudents)

df[:id] = @time map(x->findfirst(Vector{ASCIIString}(students), x), df[:id])

# 吃饭
# 同时同地吃饭，关系+2，否则关系-2
# 早餐1
# a刷了至少2次卡，b没吃饭，则关系+4
restaurant = ["学苑楼商务网关", "硕果园（工大商店）", "学士楼商务网关", "学子楼商务网关", "九食堂商务网关", "四食堂商务网关", "五食堂商务网关", "土木楼网关"]
df_temp = df[Bool[x in restaurant for x in df[:position]], :]
df_temp[:date] = map(Date, df_temp[:datetime])
df_temp[:time] = map(df_temp[:datetime]) do x
    x = Dates.hour(x)
    if 6 <= x <= 9
        "breakfast"
    elseif 10 <= x <= 14
        "lunch"
    elseif 16 <= x <= 20
        "dinner"
    else
        "other"
    end
end
df_temp = df_temp[df_temp[:time].!="other", :]
df_temp[:tp] = map(df_temp[:datetime]) do x Dates.hour(x) * 12 + div(Dates.minute(x), 5) end |> Vector{Int}
df_temp = join(df_temp[[:date, :time, :id, :tp, :position]] |> groupby([:date, :time, :id]) |> minimum,
               df_temp[[:date, :time, :id, :count]] |> groupby([:date, :time, :id]) |> sum,
               on=[:date, :time, :id], kind=:left)
names!(df_temp, [:date, :time, :id, :tp, :position, :count])

@showprogress 1 "Computing..." for i in df_temp |> groupby([:date, :time])
    δ = i[1, :time] == "breakfast" ? 1 : 2
    for j in i |> groupby(:position), k in 1:nrow(j)
        a = abs(j[:tp] .- j[k,:tp]) .< 2
        relations[j[k, :id], j[a, :id]] += 2δ
        relations[j[k, :id], i[:, :id]] -= δ
        if j[k, :count] >= 2
            relations[j[k, :id], setdiff(1:nstudents, i[:, :id])] += 4
        end
    end
end

# 洗澡
# 同地点同时段洗澡，关系+1
bath = ["一校区水控新", "二区水控", "15公寓浴池", "土木楼水控"]
df_temp = df[Bool[x in bath for x in df[:position]], [:datetime, :position, :id]]
df_temp[:date] = map(Date, df_temp[:datetime])
df_temp = df_temp[[:datetime, :date, :position, :id]] |> groupby([:id, :date]) |> minimum
df_temp[:tp] = map(df_temp[:datetime_minimum]) do x Dates.hour(x) * 12 + div(Dates.minute(x), 5) end |> Vector{Int}
delete!(df_temp, :datetime_minimum)
names!(df_temp, [:id, :date, :position, :tp])

@time for i in df_temp |> groupby([:date, :position])
    for j in 1:nrow(i)
        a = abs(i[:tp] .- i[j,:tp]) .< 3
        relations[i[j, :id], i[a, :id]] += 1
    end
end

# 超市
# 同地点同时段超市购物，关系+1
mall = ["超市商务子系统", "学子超市园丁总店", "学子便利海河店", "学子超市园丁分店"]

df_temp = df[Bool[x in mall for x in df[:position]], [:datetime, :id, :position]]
df_temp[:tp] = map(df_temp[:datetime]) do x Dates.hour(x) *30 + div(Dates.minute(x), 2) end |> Vector{Int}
df_temp[:date] = map(Date, df_temp[:datetime])

@time for i in df_temp |> groupby([:date, :position])
    for j in 1:nrow(i)
        a = abs(i[:tp] .- i[j,:tp]) .< 2
        relations[i[j, :id], i[a, :id]] += 1
    end
end

# result
@time for i in 1:nstudents, j in 1:i
    relations[i, j] += relations[j, i]
    relations[j, i] = 0
end

top100 = sortperm(relations[:], rev=true)[1:100]
result = DataFrame(A = students[div(top100, nstudents)],
                   B = students[top100 % nstudents],
                   rel = relations[top100])

writetable("data/relations.csv", result)
