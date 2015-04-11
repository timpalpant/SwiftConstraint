//
//  ConstraintSolver.swift
//  ConstraintSolver
//
//  Adapted from Python source by Timothy Palpant on 7/29/14.
//
//  Copyright (c) 2005-2014 - Gustavo Niemeyer <gustavo@niemeyer.net>
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//     list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

public protocol Solver {
  func solve<T: Hashable>(problem: Problem<T>, single:Bool) -> [[T]]
}

public class BacktrackingSolver : Solver {
  let forwardCheck: Bool
  
  public init(forwardCheck: Bool=true) {
    self.forwardCheck = forwardCheck
  }
  
  public func solve<T: Hashable>(problem: Problem<T>, single:Bool=false) -> [[T]] {
    problem.preprocess()
    
    var queue: [(variable: Variable<T>, values: [T], pushdomains: [Domain<T>])] = []
    var variable: Variable<T>!
    var values: [T] = []
    var pushdomains: [Domain<T>] = []
    
    while true {
      // Mix the Degree and Minimum Remaining Values (MRV) heuristics
      var lst = problem.variables.map { variable in
        (-variable.constraints.count, variable.domain.count, variable) }
      lst.sort { $0.0 == $1.0 ? $0.1 < $1.1 : $0.0 < $1.0 }
      variable = nil
      for (_, _, v) in lst {
        if v.assignment == nil {
          // Found unassigned variable
          variable = v
          values = Array(v.domain)
          pushdomains = []
          if self.forwardCheck {
            for x in problem.variables {
              if x.assignment == nil && x !== v {
                pushdomains.append(x.domain)
              }
            }
          }
          break
        }
      }
      
      if variable == nil {
        // No unassigned variables. We have a solution
        // Go back to last variable, if there is one
        let sol = problem.variables.map { v in v.assignment! }
        problem.solutions.append(sol)
        if queue.isEmpty { // last solution
          return problem.solutions
        }
        
        let t = queue.removeLast()
        variable = t.variable
        values = t.values
        pushdomains = t.pushdomains
        for domain in pushdomains {
          domain.popState()
        }
      }

      while true {
        // We have a variable. Do we have any values left?
        if values.count == 0 {
          // No. Go back to the last variable, if there is one.
          variable.assignment = nil
          while !queue.isEmpty {
            let t = queue.removeLast()
            variable = t.variable
            values = t.values
            pushdomains = t.pushdomains
            for domain in pushdomains {
              domain.popState()
            }
            if !values.isEmpty {
              break
            }
            variable.assignment = nil
          }
          
          if values.isEmpty {
            return problem.solutions
          }
        }
        
        // Got a value; check it
        variable.assignment = values.removeLast()
        for domain in pushdomains {
          domain.pushState()
        }
        
        var good = true
        for constraint in variable.constraints {
          if !constraint.evaluate(self.forwardCheck) {
            good = false
            break // Value is not good
          }
        }
        if good {
          break
        }
        
        for domain in pushdomains {
          domain.popState()
        }
      }
      
      // Push state before looking for next variable.
      queue += [(variable: variable!, values: values, pushdomains: pushdomains)]
    }
  }
}

public class RecursiveBacktrackingSolver : Solver {
  let forwardCheck: Bool
  
  public init(forwardCheck: Bool) {
    self.forwardCheck = forwardCheck
  }
  
  public convenience init() {
    self.init(forwardCheck: true)
  }
  
  private func recursiveBacktracking<T: Hashable>(var problem: Problem<T>, single:Bool=false) -> [[T]] {
    var pushdomains = [Domain<T>]()
        
    // Mix the Degree and Minimum Remaining Values (MRV) heuristics
    var lst = problem.variables.map { variable in
      (-variable.constraints.count, variable.domain.count, variable) }
    lst.sort { $0.0 == $1.0 ? $0.1 < $1.1 : $0.0 < $1.0 }
    var missing: Variable<T>?
    for (_, _, variable) in lst {
      if variable.assignment == nil {
        missing = variable
      }
    }
        
    if var variable = missing {
      pushdomains.removeAll()
      if forwardCheck {
        for v in problem.variables {
          if v.assignment == nil {
            pushdomains.append(v.domain)
          }
        }
      }
      
      for value in variable.domain {
        variable.assignment = value
        for domain in pushdomains {
          domain.pushState()
        }
        
        var good = true
        for constraint in variable.constraints {
          if !constraint.evaluate(forwardCheck) {
            good = false
            break // Value is not good
          }
        }
        
        if good { // Value is good. Recurse and get next variable
          recursiveBacktracking(problem, single: single)
          if !problem.solutions.isEmpty && single {
            return problem.solutions
          }
        }
        
        for domain in pushdomains {
          domain.popState()
        }
      }
      
      variable.assignment = nil
      return problem.solutions
    }
        
    // No unassigned variables. We have a solution
    let values = problem.variables.map { variable in variable.assignment! }
    problem.solutions.append(values)
    return problem.solutions
  }
  
  public func solve<T : Hashable>(problem: Problem<T>, single:Bool=false) -> [[T]] {
    problem.preprocess()
    return recursiveBacktracking(problem, single: single)
  }
}

func random_choice<T>(a: [T]) -> T {
  let index = Int(arc4random_uniform(UInt32(a.count)))
  return a[index]
}

func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
  let c = count(list)
  for i in 0..<(c - 1) {
    let j = Int(arc4random_uniform(UInt32(c - i))) + i
    swap(&list[i], &list[j])
  }
  return list
}

public class MinConflictsSolver : Solver {
  let steps: Int
  
  public init(steps: Int=1_000) {
    self.steps = steps
  }
  
  public func solve<T : Hashable>(problem: Problem<T>, single:Bool=false) -> [[T]] {
    problem.preprocess()
    
    // Initial assignment
    for variable in problem.variables {
      variable.assignment = random_choice(variable.domain.elements)
    }
    
    for _ in 1...self.steps {
      var conflicted = false
      let lst = shuffle(problem.variables)
      for variable in lst {
        // Check if variable is not in conflict
        var allSatisfied = true
        for constraint in variable.constraints {
          if !constraint.evaluate(false) {
            allSatisfied = false
            break
          }
        }
        if allSatisfied {
          continue
        }
        
        // Variable has conflicts. Find values with less conflicts
        var mincount = variable.constraints.count
        var minvalues: [T] = []
        for value in variable.domain {
          variable.assignment = value
          var count = 0
          for constraint in variable.constraints {
            if !constraint.evaluate(false) {
              count += 1
            }
          }
          if count == mincount {
            minvalues.append(value)
          } else if count < mincount {
            mincount = count
            minvalues.removeAll()
            minvalues.append(value)
          }
        }
        
        // Pick a random one from these values
        variable.assignment = random_choice(minvalues)
        conflicted = true
      }
      
      if !conflicted {
        let solution = problem.variables.map { variable in variable.assignment! }
        problem.solutions.append(solution)
        return problem.solutions
      }
    }
    
    return problem.solutions
  }
}