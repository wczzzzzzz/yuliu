using DataFrames, ExcelReaders, CSV

# 读取Excel文件
function read_excel("./华为杯/A题/附件1-疲劳评估数据.xls")
    data = DataFrame(ExcelReaders.readtable("./华为杯/A题/附件1-疲劳评估数据.xls"))
    return data
end

# 计算应力幅值
function calculate_stress_amplitudes(data)
    # 假设第二列是推力数据
    forces = data.Force
    # 计算相邻时间点之间的变化
    delta_forces = diff(forces)
    # 计算应力幅值，这里假设幅值是变化的绝对值
    stress_amplitudes = abs.(delta_forces)
    return stress_amplitudes
end

# 统计不同幅值的个数和波长
function count_amplitudes(stress_amplitudes)
    unique_amplitudes, counts = unique(stress_amplitudes, return_counts=true)
    wavelengths = 100 ./ counts # 假设每个波长对应一个周期
    return unique_amplitudes, counts, wavelengths
end

# 主函数
function main(input_file_path, output_file_path)
    data = read_excel(input_file_path)
    stress_amplitudes = calculate_stress_amplitudes(data)
    unique_amplitudes, counts, wavelengths = count_amplitudes(stress_amplitudes)
    
    # 创建一个DataFrame来存储结果
    results = DataFrame(Amplitude=unique_amplitudes, Count=counts, Wavelength=wavelengths)
    
    # 保存结果到Excel文件
    CSV.write(output_file_path, results)
    
    # 打印结果
    println(results)
    return results
end

# 假设输入和输出文件路径
input_file_path = "input_data.xlsx"
output_file_path = "output_results.xlsx"
main(input_file_path, output_file_path)


    