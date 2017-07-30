module racos

importall racos_common, objective, parameter, zoo_global, racos_classification

importall dimension, tool_function

using Base.Dates.now

export Racos, racos_opt!

@everywhere type Racos
  rc::RacosCommon
  function Racos()
    return new(RacosCommon())
  end
end

@everywhere function racos_opt!(racos::Racos, objective::Objective, parameter::Parameter; ub=1)
  rc = racos.rc
  clear!(rc)
  rc.objective = objective
  rc.parameter = parameter
  init_attribute!(rc)
  t = parameter.budget / parameter.negative_size
  time_log1 = now()
  for i in 1:t
    j = 0
    iteration_num = length(rc.negative_data)
    while j < iteration_num
      if rand(rng, Float64) < rc.parameter.probability
        classifier = RacosClassification(rc.objective.dim, rc.positive_data,
          rc.negative_data, ub=ub)
          mixed_classification(classifier)
          solution, distinct_flag = distinct_sample_classifier(rc, classifier, data_num=rc.parameter.train_size)
      else
        solution, distinct_flag = distinct_sample(rc, rc.objective.dim)
      end
      #painc stop
      if isnull(solution)
        return rc.best_solution
      end
      if !distinct_flag
        continue
      end
      obj_eval(objective, solution)
      push!(rc.data, solution)
      j += 1
    end
    selection!(rc)
    rc.best_solution = rc.positive_data[1]
    # display expected running time
    if i == 4
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



end
