nprocs()<=1 && addprocs()

#==== init ====#
@everywhere begin

using DataFrames

cd(s"C:\Users\ylxdz\fuck-project\fankadata")

function basic_transform!(x::DataFrame)
    x = x[x[:状态].!="被冲正", :]
    # any(x[:状态].!="正常") && println("non-ok exists")

    delete!(x, [:姓名, :次数, :状态])
    names!(x, [:datetime, :id, :category, :position, :amount, :balance])

    # x[:datetime] = map(x->DateTime(x, "yyyy/mm/dd HH:MM:SS"), x[:datetime])
    # x[:balance] -= x[:amount] # 把余额转化为消费前的
    x
end

Base.vcat(x::DataFrame, ::Void) = x
Base.vcat(::Void, x::DataFrame) = x
Base.vcat(::Void, ::Void) = nothing

end # init

#==== main ====#
filelist = readdir("raw")

df_transaction = @time @parallel vcat for i in filelist
    try
        basic_transform!(readtable("raw/$i"))
    catch e
        println(i)
    end
end

writetable("data/transactions.csv", df_transaction)

#==== init ====#
@everywhere begin

function parse_filename(x::AbstractString)
    x = split(x, '_')[1]
    x = split(x, '-')
    DataFrame(gender = x[2],
              major  = x[3],
              degree = x[4][1:1],
              grade  = x[4][2:3],
              class  = x[4][7:8],
              id     = x[4])
end

function vcat_unique(x, y)
    y[1, :id] in x[:id] ? x : [x; y]
end

end # init

#==== main ====#
df_student = @time @parallel vcat_unique for i in filelist
    parse_filename(i)
end

writetable("data/students.csv", df_student)
