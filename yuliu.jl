using DataFrames, LinearAlgebra
using XLSX
using TimerOutputs

include("rainflow.jl")

const to = TimerOutput()

# 1. 读取 Excel 数据
filename = "./doc/附件1-疲劳评估数据.xlsx"  # 请替换为实际文件名
df = DataFrame(XLSX.readtable(filename, "主轴扭矩"))  # 读取 Excel 表格中的数据

# 假设数据中有两列，分别是时间和应力
time = df[1:100, "T(s)"]  # 替换为 Excel 中的实际列名
for i in 1:100
    stress = df[1:100, "WT$i"]  # 替换为 Excel 中的实际列名
    # stress = df[1:100, "WT1"]  # 替换为 Excel 中的实际列名

    @timeit to "Rainflow cycle counting algorithm" begin
    cycles, cycles_info = rainflow(stress)
    end

    LN = cal_equivalent_fatigue(cycles)
    println(LN)

    total_damage = calculate_cumulative_damage(cycles)
    println("Total Cumulative Fatigue Damage: ", total_damage)
end

wave_length = Float64[]
for (cycle,cycle_info) in zip(cycles,cycles_info)
    push!(wave_length,(cycle_info[3]-cycle_info[1])/cycle[1])
end



show(to)