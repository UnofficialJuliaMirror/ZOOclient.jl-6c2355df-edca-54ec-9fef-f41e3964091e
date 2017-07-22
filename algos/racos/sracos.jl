module Racos

using RacosCommon

using Objective

using Parameter

using ZooGlobal

using Base.Dates.now

using Solution

using RacosClassification
type SRacos
  rc::RacosCommon
  function SRacos()
    return new(RacosCommon())
  end
end

function sracos_opt!(sracos::SRacos, objective::Objective, parameter::Parameter;
  strategy="WR", ub=1)
  rc = racos.rc
  clear!(rc)
  rc.objective = objective
  rc.parameter = parameter
  init_attribute!(rc)
  i = 0
  iteration_num = rc.parameter.budget - rc.parameter.train_size
  time_log1 = now()
  while i < iteration_num
    if rand(rng, Float64) < rc.parameter.probability
      classifier = RacosClassification(rc.objective.dim, rc.positive_data,
        rc.negative_data, ub=ub)
      mixed_classification(classifier)
      solution, distinct_flag = distinct_sample_classifier(classifier, data_num=rc.parameter.train_size)
    else
      solution, distinct_flag = distinct_sample(rc.objective.dim)
    end
    #painc stop
    if isnull(solution)
      return rc.best_solution
    end
    if !distinct_flag
      continue
    end
    obj_eval(objective, solution)
  end

      push!(rc.data, solution)
      j += 1
    end
    selection!(rc)
    rc.best_solution = rc.positive_data[0]
    # display expected running time
    if i == 4:
      time_log2 = now()
      # second
      expected_time = t * (Dates.value(time_log2 - time_log1) / 1000) / 5
      if !isnull(rc.parameter.time_budget)
        expected_time = min(expected_time, rc.parameter.time_budget)
      end
      if expected_time > 5
        zoolog(string("expected remaining running time: ", convert_time(expected_time)))
      end
    end
    # time budget check
    if !isnull(rc.parameter.time_budget)
      if expected_time >= rc.parameter.time_budget
        zoolog("time_budget runs out")
        return rc.best_solution
      end
    end
    # terminal_value check
    if !isnull(rc.parameter.terminal_value)
      if rc.best_solution.value <= rc.parameter.terminal_value
        zoolog("terminal_value function value reached")
        return rc.best_solution
      end
    end
  end
  return rc.best_solution
end

function replace(iset, x, iset_type; strategy="WR")
  if strategy == "WR"
    return strategy_wr(iset, x, iset_type)
  elseif strategy == "RR"
    return strategy_rr(iset, x)
  elseif strategy == "LM"
    best_sol = find_min(iset)
    return strategy_lm(iset, best_sol, x)
  zoolog("No such strategy")
  end

# Find first element larger than x
function binary_search(iset, x, ibegin::Int64, iend::Int64)
  x_value = x.value
  if x_value <= iset[ibegin].value
    return ibegin
  end
  if x_value >= iset[end].value
    return iend + 1
  end
  if iend == ibegin + 1
    return iend
  end
  mid = div(ibegn + iend, 2)
  if x_value <= iset[mid].value
    return binary_search(iset, x, ibegin, mid)
  else
    return binary_search(iset, x, mid, iend)
  end
end

function strategy_wr(iset, x, iset_type)
  if iset_type == "pos"
    index = binary_search(iset, x, 1, length(iset))
    inset!(iset, index, x)
    worst_ele = pop!(iset)
  else
    worst
  end
end

end