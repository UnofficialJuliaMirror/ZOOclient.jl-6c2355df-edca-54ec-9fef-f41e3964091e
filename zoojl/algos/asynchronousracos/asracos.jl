module asracos

importall aracos_common, racos_common, objective, parameter, zoo_global, solution,
  racos_classification, tool_function, sracos

using Base.Dates.now

export ASRacos, asracos_opt!

type ASRacos
  arc::ARacosCommon

  function ASRacos(core_num)
    return new(ARacosCommon(core_num))
  end
end

# @async remote_do(updater, p, asracos, parameter.budget, ub, strategy)
function updater(asracos::ASRacos, budget,  ub, strategy)
  # println("in updater")
  t = 0
  arc = asracos.arc
  rc = arc.rc
  while(t <= budget)
    t += 1
    # println("updater before take solution")
    sol = take!(arc.result_set)
    # println("updater after take solution")
    bad_ele = replace(rc.positive_data, sol, "pos")
    replace(rc.negative_data, bad_ele, "neg", strategy=strategy)
    rc.best_solution = rc.positive_data[1]
    if rand(rng, Float64) < rc.parameter.probability
      classifier = RacosClassification(rc.objective.dim, rc.positive_data,
        rc.negative_data, ub=ub)
      # println(classifier)
      # zoolog("before classification")
      mixed_classification(classifier)
      # zoolog("after classification")
      solution, distinct_flag = distinct_sample_classifier(rc, classifier, data_num=rc.parameter.train_size)
    else
      solution, distinct_flag = distinct_sample(rc, rc.objective.dim)
    end
    #painc stop
    if isnull(solution)
      zoolog("ERROR: solution null")
      break
    end
    # println("updater before sample")
    put!(arc.sample_set, solution)
    # println("updater after sample")
  end
  arc.is_finish = true
  put!(arc.asyn_result, rc.best_solution)
end

function computer(asracos::ASRacos, objective::Objective)
  # println("in computer")
  arc = asracos.arc
  while arc.is_finish == false
    # println("computer before take")
    sol = take!(arc.sample_set)
    # println("computer after take")
    obj_eval(objective, sol)
    put!(arc.result_set, sol)
    # println("computer after put")
  end
end

function asracos_opt!(asracos::ASRacos, objective::Objective, parameter::Parameter;
  strategy="WR", ub=1)
  arc = asracos.arc
  rc = arc.rc
  rc.objective = objective
  rc.parameter = parameter
  init_attribute!(rc)
  init_sample_set!(arc, ub)
  addprocs(parameter.core_num + 1)
  first = true
  is_finish = false
  for p in workers()
    if first
      # updater(asracos, parameter.budget, ub, strategy)
      remote_do(updater, p, asracos, parameter.budget, ub, strategy)
      first = false
      # println("updater begin")
    else
      remote_do(computer, p, asracos, objective)
      # computer(asracos, objective)
      # println("computer begin")
    end
  end
  # print("Finish workers")
  result = take!(arc.asyn_result)
  return result
end

end