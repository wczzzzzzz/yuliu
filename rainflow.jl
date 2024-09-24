# 筛选波峰波谷
function find_peaks_and_valleys(stress)
    peaks_and_valleys = Float64[]  # 存储波峰波谷点
    indices = Int[]

    push!(peaks_and_valleys,stress[1])
    push!(indices,1)

    # 遍历向量中除首尾外的所有数据点
    for i in 2:(length(stress) - 1)
        # 如果当前点是波峰
        if stress[i] > stress[i - 1] && stress[i] > stress[i + 1]
            push!(peaks_and_valleys, stress[i])
            push!(indices, i)
        # 如果当前点是波谷
        elseif stress[i] < stress[i - 1] && stress[i] < stress[i + 1]
            push!(peaks_and_valleys, stress[i])
            push!(indices, i)
        end
    end

    push!(peaks_and_valleys,stress[end])
    push!(indices,length(stress))

    return peaks_and_valleys, indices
end

# 2. 实现雨流计数算法
function rainflow(stresses)
    stress, indices = find_peaks_and_valleys(stresses)
    nₛ = length(stress)
    cycles = Tuple{Float64,Float64,Float64}[]
    points = zeros(Int,nₛ)
    cycles_info = Tuple{Int,Float64,Int,Float64}[]
    
    cidx = 0
    pidx = 0
    for eidx in 1:nₛ
        pidx += 1
        points[pidx] = eidx
        while pidx >= 3
            s₁ = stress[points[pidx-2]]
            s₂ = stress[points[pidx-1]]
            s₃ = stress[points[pidx]]
        
            Δs₂ = abs(s₃ - s₂)
            Δs₁ = abs(s₂ - s₁)
            
            if Δs₂ >= Δs₁
                push!(cycles_info,(indices[points[pidx-2]],s₁,indices[points[pidx-1]],s₂))
                cidx += 1
                range = Δs₁
                mean = (s₁+s₂)/2
                if pidx == 3
                    push!(cycles,(0.5,range,mean))
                    points[1] = points[2]
                    points[2] = points[3]
                    pidx = 2
                else
                    push!(cycles,(1.0,range,mean))
                    points[pidx-2] = points[pidx]
                    pidx -= 2
                end
            else
                break
            end
        end
    end
    
    for c in 1:pidx-1
        s₁ = stress[points[c]]
        s₂ = stress[points[c+1]]
        range = abs(s₁-s₂)
        mean = 0.5*(s₁+s₂)
        cidx += 1
        push!(cycles,(0.5,range,mean))
    end

    return cycles, cycles_info
end

# Goodman 修正函数
function correction(range, mean)
    σ = 5e7
    return range/(1-mean/σ)
end

# 等效疲劳函数
function cal_equivalent_fatigue(cycles::Vector{Tuple{Float64,Float64,Float64}})
    N = 42565440.4361
    m = 10
    L = 0.
    for (n,range,mean) in cycles
        range = correction(range,mean)
        L += range^m
        # L += range^m*n
    end
    return (L/N)^(1/m)
end

function SN_curve(S, m, C)
    return C * S^(-m)
end

# 定义计算累计疲劳损伤值的函数
function calculate_cumulative_damage(cycles)
    C = 9.77e70
    m = 10
    total_damage = 0.0
    fatigue_life_dict = Dict{Float64, Float64}()

    # 假设的疲劳寿命数据，可以根据实际数据进行调整
    for S in unique([cycle[2] for cycle in cycles])  # 提取唯一的应力幅值
        fatigue_life_dict[S] = SN_curve(S, m, C)  # 计算对应的疲劳寿命并存储在字典中
    end

    for (n, range, mean) in cycles
        # Goodman 曲线修正
        corrected_range = correction(range, mean)
        
        # 获取对应的疲劳寿命
        fatigue_life = fatigue_life_dict[range]
        
        # 计算每个循环的损伤
        damage = n / fatigue_life
        
        # 累加损伤
        total_damage += damage
    end

    return total_damage
end