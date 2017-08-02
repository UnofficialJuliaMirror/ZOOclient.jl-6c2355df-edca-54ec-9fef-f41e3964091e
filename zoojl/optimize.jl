# main function
module optimize

importall aracos_optimization, objective, parameter, racos_optimization

export zoo_min

function zoo_min(obj::Objective, par::Parameter)
  if par.asynchronous == true
    algorithm = asyn_opt!
  else
    algorithm = opt!
  end
  optimizer = RacosOptimization()
  result = algorithm(optimizer, obj, par)
  return result
end

end