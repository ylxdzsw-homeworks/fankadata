using Gadfly
using DataFrames

df_transaction = readtable("./data/transactions.csv")
df_student     = readtable("./data/students.csv", eltypes=[UTF8String, UTF8String, UTF8String, Int, UTF8String, UTF8String])

df_transaction[:datetime] = map(x->DateTime(x, "yyyy/mm/dd HH:MM:SS"), df_transaction[:datetime])

pwd()
