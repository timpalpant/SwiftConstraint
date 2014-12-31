//
//  Problem.swift
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


// Protocol representing a set of possible values for a variable
// The domain will be pruned by solvers for the given problem
public protocol Domain {
  func isEmpty() -> Bool
  func resetState()
  func pushState()
  func popState()
  func hideValue(value: Any)
  func remove(value: Any)
}

// A variable with its associated Domain
public protocol Variable {
  // the Domain that this Variable can take
  func getDomain() -> Domain
  // the current value of this Variable, if any
  func getAssignment() -> Any?
  func setAssignment(value: Any?)
  // the set of Constraints that involve this Variable
  func getConstraints() -> [Constraint]
}

// Protocol representing a problem,
// from which you can extract solutions with a solver
public protocol Problem {
  mutating func reset()
  
  mutating func addVariable(variable: Variable)
  mutating func addVariables(variables: SequenceOf<Variable>)
  
  func getSolution() -> Solution?
  func getSolutions() -> GeneratorOf<Solution>
}

// A Domain of Hashable type T, implemented as a Set
public class DomainOf<T: Hashable> : Domain, SequenceType {
  private var _values: Set<T>
  private var _hidden: [T]
  private var _states: [Int]
  
  public var count: Int {
    get {
      return _values.count
    }
  }
  
  init(values: Set<T>) {
    _values = values
    _hidden = []
    _states = []
  }
  
  public func isEmpty() -> Bool {
    return count == 0
  }
  
  public func generate() -> GeneratorOf<T> {
    return _values.generate()
  }
  
  public func resetState() {
    _values.extend(_hidden)
    _hidden.removeAll()
    _states.removeAll()
  }
  
  public func pushState() {
    _states.append(_values.count)
  }
  
  public func popState() {
    var diff = _states.removeLast() - _values.count
    if diff > 0 {
      _values.extend(_hidden[_hidden.count-diff..<_hidden.count])
      for i in _hidden.count-diff..<_hidden.count {
        _hidden.removeLast()
      }
    }
  }
  
  public func hideValue(value: Any) {
    if let popped = _values.remove(value as T) {
      _hidden.append(popped)
    }
  }
  
  public func remove(value: Any) {
    _values.remove(value as T)
  }
  
  public func contains(value: T) -> Bool {
    return _values.contains(value)
  }
}

public class VariableOf<T: Hashable> : Variable {
  public var domain: DomainOf<T>
  public var assignment: T?
  public var constraints: [ConstraintOf<T>]
  
  init(domain: DomainOf<T>) {
    self.domain = domain
    constraints = []
  }
  
  public func getDomain() -> Domain {
    return domain
  }
  
  public func getAssignment() -> Any? {
    return assignment
  }
  
  public func setAssignment(value: Any?) {
    self.assignment = value as T?
  }
  
  public func getConstraints() -> [Constraint] {
    return constraints
  }
}

public protocol Summable {
  func +(lhs: Self, rhs: Self) -> Self
}

public protocol Multipliable {
  func *(lhs: Self, rhs: Self) -> Self
}

public protocol Numeric : Comparable, Summable, Multipliable, IntegerLiteralConvertible { }
extension Int : Numeric { }
extension Float : Numeric { }
extension Double : Numeric { }
public class NumericVariable<T where T:Hashable, T:Numeric> : VariableOf<T> { }

public class ConstrainedProblem : Problem {
  private var variables : [Variable]
  private var constraints : [Constraint]
  public var solver : Solver
  
  public init(solver: Solver) {
    self.solver = solver
    variables = []
    constraints = []
  }
  
  public convenience init() {
    self.init(solver: BacktrackingSolver())
  }
  
  public func reset() {
    constraints.removeAll()
    variables.removeAll()
  }

  public func addVariable(variable: Variable) {
    variables.append(variable)
  }
    
  public func addVariables(variables: SequenceOf<Variable>) {
    for variable in variables {
      addVariable(variable)
    }
  }
  
  public func addConstraint(constraint: Constraint) {
    constraints.append(constraint)
  }
  
  public func getSolution() -> Solution? {
    return solver.getSolution(variables, constraints: constraints)
  }
  
  public func getSolutions() -> GeneratorOf<Solution> {
    return solver.getSolutions(variables, constraints: constraints)
  }
}
