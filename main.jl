using Gadfly
using DataFrames

include("utils.jl")

const df_transaction = readtable("./data/transactions.csv")
const df_student     = readtable("./data/students.csv")

df_transaction[:datetime] = map(x->DateTime(x, "yyyy/mm/dd HH:MM:SS"), df_transaction[:datetime])

#==== 总览 ====#
plot(df_student, x=:grade,  Scale.x_discrete, Geom.histogram, Guide.title("grade of students"))
plot(df_student, x=:gender, Scale.x_discrete, Geom.histogram, Guide.title("gender of students"))
plot(df_student, x=:major,  Scale.x_discrete, Geom.histogram, Guide.title("major of students"))
plot(df_student, x=:honors, Scale.x_discrete, Geom.histogram, Guide.title("honors of students"))

plot(df_transaction[[:position, :amount]] |> groupby(:position) |> sum |> sortby(:amount_sum),
     x=:position, y=:amount_sum, Geom.bar, Guide.title("consumption in diffrent places"))

#==== 存款 ====#
df_temp = df_transaction[(df_transaction[:category].=="存款") | (df_transaction[:category].=="银行转账"),
                         [:id, :datetime, :position, :amount, :balance]]
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
