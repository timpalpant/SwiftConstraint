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

// A Domain of Hashable type T, implemented as a Set
public class Domain<T: Hashable> : SequenceType {
  private var values: Set<T>
  private var hidden: [T]
  private var states: [Int]
  
  public var count: Int {
    return values.count
  }
  
  public var isEmpty: Bool {
    return count == 0
  }
  
  public var elements: [T] {
    return Array(values)
  }
  
  public init<S: SequenceType where S.Generator.Element == T>(values: S) {
    self.values = Set<T>(values)
    hidden = []
    states = []
  }
  
  public convenience init(domain: Domain<T>) {
    self.init(values: domain.values)
  }
  
  public func generate() -> GeneratorOf<T> {
    return GeneratorOf<T>(elements.generate())
  }
  
  public func resetState() {
    values.unionInPlace(hidden)
    hidden.removeAll()
    states.removeAll()
  }
  
  public func pushState() {
    states.append(values.count)
  }
  
  public func popState() {
    var diff = states.removeLast() - values.count
    if diff > 0 {
      values.unionInPlace(hidden[hidden.count-diff..<hidden.count])
      for i in hidden.count-diff..<hidden.count {
        hidden.removeLast()
      }
    }
  }
  
  public func hideValue(value: T) {
    if let popped = values.remove(value) {
      hidden.append(popped)
    }
  }
  
  public func remove(value: T) {
    values.remove(value)
  }
  
  public func contains(value: T) -> Bool {
    return values.contains(value)
  }
}

// MARK: Printable

extension Domain : Printable, DebugPrintable {
  public var description: String {
    return "Domain(\(self.values))"
  }
  
  public var debugDescription: String {
    return description
  }
}

public class Variable<T: Hashable> {
  public var domain: Domain<T>
  public var assignment: T? {
    willSet {
      if let v = newValue {
        assert(domain.contains(v), "Attempting to set variable to value not in its Domain")
      }
    }
  }
  
  public var constraints: [Constraint<T>]
  
  public init(domain: Domain<T>) {
    self.domain = Domain<T>(domain: domain)
    constraints = []
  }
}

// MARK: Printable

extension Variable : Printable, DebugPrintable {
  public var description: String {
    return "Variable(\(self.assignment))"
  }
  
  public var debugDescription: String {
    return description
  }
}

public class ScaledVariable<T where T: Hashable, T: Multiplicable> : Variable<T> {
  let multiplier: T
  var _inner_value: T?
  
  public init(domain: Domain<T>, multiplier: T) {
    self.multiplier = multiplier
    super.init(domain: domain)
  }
  
  public override var assignment: T? {
    get {
      if let iv = self._inner_value {
        return multiplier*iv
      }
      
      return nil
    }
    
    set {
      if let v = newValue {
        assert(domain.contains(v), "Attempting to set variable to value not in its Domain")
      }
      
      self._inner_value = newValue
    }
  }
}

public class Problem<T: Hashable> {
  public var variables: [Variable<T>] = []
  public var constraints: [Constraint<T>] = []
  public var solutions: [[T]] = []
  
  public init() { }
  
  public func reset() {
    solutions.removeAll()
    for variable in variables {
      variable.assignment = nil
    }
  }
  
  public func preprocess() {
    for constraint in constraints {
      constraint.preprocess()
    }
  
    self.reset()
  }
}
