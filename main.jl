using Gadfly
using DataFrames

df_transaction = readtable("./data/transactions.csv")
df_student     = readtable("./data/students.csv")

df_transaction[:datetime] = map(x->DateTime(x, "yyyy/mm/dd HH:MM:SS"), df_transaction[:datetime])

#==== 存款 ====#
@time let
    df_temp = df_transaction[df_transaction[:category].=="存款", [:id, :datetime, :position, :amount, :balance]]
    df_temp = join(df_temp, df_student, on=:id, kind=:left)

    df_temp[:dayofmonth]  = map(Dates.dayofmonth, df_temp[:datetime])
    df_temp[:dayofweek]   = map(Dates.dayofweek,  df_temp[:datetime])

    df_temp[:times] = 1

    plot(df_temp[[:dayofmonth, :times]] |> groupby(:dayofmonth) |> sum,
         x=:dayofmonth, y=:times_sum, Guide.xticks(ticks=collect(1:31)),
         Guide.title("times of save ~ day of month"))

    plot(df_temp[[:dayofweek, :times]] |> groupby(:dayofweek) |> sum,
         x=:dayofweek, y=:times_sum, Guide.xticks(ticks=collect(1:7)),
         Scale.x_continuous(labels=x->get(Dates.english_daysofweekabbr, x, "fuck")),
         Guide.title("times of save ~ day of week"))
end
