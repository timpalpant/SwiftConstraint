//
//  Constraint.swift
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

// A constraint that acts on Variables of type T
public class Constraint<T: Hashable> {
  let variables: [Variable<T>]
  
  init(variables: [Variable<T>]) {
    self.variables = variables
    for variable in variables {
      variable.constraints.append(self)
    }
  }
  
  public func evaluate(_ forwardCheck: Bool=false) -> Bool {
    return false
  }
  
  public func preprocess() -> Bool {
    if variables.count == 1 {
      let variable = variables.first!
      var domain = variable.domain
      for value in domain {
        variable.assignment = value
        // TODO: do we need to set it back to nil?
        if !evaluate() {
          domain.remove(value)
        }
      }
      
      return true
    }
    
    return false
  }
}

public class AllDifferentConstraint<T: Hashable> : Constraint<T> {
  public override init(variables: [Variable<T>]) {
    super.init(variables: variables)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    var seen = Set<T>()
    for variable in variables {
      if let value = variable.assignment {
        if seen.contains(value) {
          return false
        }
        seen.add(value)
      }
    }
    
    if forwardCheck {
      for variable in variables {
        if variable.assignment == nil {
          var domain = variable.domain
          for value in seen {
            if domain.contains(value) {
              domain.hideValue(value)
              if domain.isEmpty {
                return false
              }
            }
          }
        }
      }
    }
    
    return true
  }
}

public class AllEqualConstraint<T: Hashable> : Constraint<T> {
  public override init(variables: [Variable<T>]) {
    super.init(variables: variables)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    var singlevalue: T? = nil
    for variable in variables {
      if singlevalue == nil {
        singlevalue = variable.assignment
      } else if let value = variable.assignment {
        if value != singlevalue {
          return false
        }
      }
    }
    
    if forwardCheck {
      if let sv = singlevalue {
        for variable in variables {
          if variable.assignment == nil {
            var domain = variable.domain
            if !domain.contains(sv) {
              return false
            }
            for value in domain {
              if value != sv {
                domain.hideValue(value)
              }
            }
          }
        }
      }
    }
    
    return true
  }
}

public class SumConstraint<T where T:Hashable, T:Arithmetic> : Constraint<T> {
  let sum: T
  
  init(variables: [Variable<T>], sum: T) {
    self.sum = sum
    super.init(variables: variables)
  }
}

public class MaxSumConstraint<T where T:Hashable, T:Arithmetic> : SumConstraint<T> {
  public override init(variables: [Variable<T>], sum: T) {
    super.init(variables: variables, sum: sum)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    let maxsum = self.sum
    var sum: T = 0
    for variable in variables {
      if let value = variable.assignment {
        sum = sum + value
      }
    }
    
    if sum > maxsum {
      return false
    }
    
    if forwardCheck {
      for variable in variables {
        if variable.assignment == nil {
          var domain = variable.domain
          for value in domain {
            if sum+value > maxsum {
              domain.hideValue(value)
            }
          }
          if domain.isEmpty {
            return false
          }
        }
      }
    }
    
    return true
  }
  
  public override func preprocess() -> Bool {
    let finished = super.preprocess()
    
    for variable in variables {
      var domain = variable.domain
      for value in domain {
        if value > sum {
          domain.remove(value)
        }
      }
    }
    
    return finished
  }
}

public class ExactSumConstraint<T where T:Hashable, T:Arithmetic> : SumConstraint<T> {
  public override init(variables: [Variable<T>], sum: T) {
    super.init(variables: variables, sum: sum)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    let exactsum = self.sum
    var sum: T = 0
    var missing = false
    for variable in variables {
      if let value = variable.assignment {
        sum = sum + value
      } else {
        missing = true
      }
      
      if sum > exactsum {
        return false
      }
      
      if forwardCheck && missing {
        for variable in variables {
          if variable.assignment == nil {
            var domain = variable.domain
            for value in domain {
              if sum+value > exactsum {
                domain.hideValue(value)
              }
            }
            if domain.isEmpty {
              return false
            }
          }
        }
      }
    }
    
    return missing ? sum <= exactsum : sum == exactsum
  }
  
  public override func preprocess() -> Bool {
    let finished = super.preprocess()

    for variable in variables {
      var domain = variable.domain
      for value in domain {
        if value > sum {
          domain.remove(value)
        }
      }
    }
  
    return finished
  }
}

public class MinSumConstraint<T where T:Hashable, T:Arithmetic> : SumConstraint<T> {
  public override init(variables: [Variable<T>], sum: T) {
    super.init(variables: variables, sum: sum)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    let minsum = self.sum
    var sum: T = 0
    for variable in variables {
      if let value = variable.assignment {
        sum = sum + value
      } else {
        return true
      }
    }
    
    return sum >= minsum
  }
}

public class DifferenceConstraint<T where T:Hashable, T:Subtractable> : Constraint<T> {
  let difference: T
  var minuend: Variable<T> {
    return variables[0]
  }
  var subtrahend: Variable<T> {
    return variables[1]
  }

  public init(minuend: Variable<T>, subtrahend: Variable<T>, difference: T) {
    self.difference = difference
    super.init(variables: [minuend, subtrahend])
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    if let m = minuend.assignment {
      if let s = subtrahend.assignment {
        return diff(m, subtrahend: s) == difference
      }
    }
    
    return true
  }
  
  func diff(minuend: T, subtrahend: T) -> T {
    return minuend - subtrahend
  }
}

public class AbsDifferenceConstraint<T where T:Hashable, T:Subtractable, T:SignedNumberType> : DifferenceConstraint<T> {
  public override init(minuend: Variable<T>, subtrahend: Variable<T>, difference: T) {
    super.init(minuend: minuend, subtrahend: subtrahend, difference: difference)
  }
  
  override func diff(minuend: T, subtrahend: T) -> T {
    return abs(minuend - subtrahend)
  }
}

public class ProductConstraint<T where T:Hashable, T:Multiplicable, T:IntegerLiteralConvertible> : Constraint<T> {
  let product: T
  
  public init(variables: [Variable<T>], product: T) {
    self.product = product
    super.init(variables: variables)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    let assigned = variables.filter { $0.assignment != nil }
    if assigned.count < variables.count {
      return true // some variables missing assignment
    }
    
    let values = assigned.map { v in v.assignment! }
    let p = reduce(values, 1, {$0 * $1})
    return p == product
  }
}

public class QuotientConstraint<T where T:Hashable, T:Divisible, T:Comparable> : Constraint<T> {
  let quotient: T
  var dividend: Variable<T> {
    return variables[0]
  }
  var divisor: Variable<T> {
    return variables[1]
  }

  public init(dividend: Variable<T>, divisor: Variable<T>, quotient: T) {
    self.quotient = quotient
    super.init(variables: [dividend, divisor])
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    if let x = dividend.assignment {
      if let y = divisor.assignment {
        return x/y == quotient
      }
    }
    
    return true
  }
}

public class InvertibleQuotientConstraint<T where T:Hashable, T:Divisible, T:Comparable> : QuotientConstraint<T> {
  public override init(dividend: Variable<T>, divisor: Variable<T>, quotient: T) {
    super.init(dividend: dividend, divisor: divisor, quotient: quotient)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    if let x = dividend.assignment {
      if let y = divisor.assignment {
        return (x/y == quotient) || (y/x == quotient)
      }
    }
    
    return true
  }
}

public class SetConstraint<T: Hashable> : Constraint<T> {
  let set: Set<T>
  
  init<S: SequenceType where S.Generator.Element == T>(variables: [Variable<T>], set: S) {
    self.set = Set<T>(set)
    super.init(variables: variables)
  }
}

public class InSetConstraint<T: Hashable> : SetConstraint<T> {
  public override init<S: SequenceType where S.Generator.Element == T>(variables: [Variable<T>], set: S) {
    super.init(variables: variables, set: set)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    return true
  }
  
  public override func preprocess() -> Bool {
    for variable in variables {
      var domain = variable.domain
      for value in domain {
        if !set.contains(value) {
          domain.remove(value)
        }
      }
    }
    
    return true
  }
}

public class NotInSetConstraint<T: Hashable> : SetConstraint<T> {
  public override init<S: SequenceType where S.Generator.Element == T>(variables: [Variable<T>], set: S) {
    super.init(variables: variables, set: set)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    return true
  }
  
  public override func preprocess() -> Bool {
    for variable in variables {
      var domain = variable.domain
      for value in domain {
        if set.contains(value) {
          domain.remove(value)
        }
      }
    }
    
    return true
  }
}

public class SomeInSetConstraint<T: Hashable> : SetConstraint<T> {
  let n: Int
  let exact: Bool
  
  public init<S: SequenceType where S.Generator.Element == T>(variables: [Variable<T>], set: S, n: Int=1, exact: Bool=false) {
    self.n = n
    self.exact = exact
    super.init(variables: variables, set: set)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    var missing = 0
    var found = 0
    for variable in variables {
      if let value = variable.assignment {
        found += Int(set.contains(value))
      } else {
        missing++
      }
    }
    
    if missing > 0 {
      if exact {
        if !(found <= n && n <= missing+found) {
          return false
        }
      } else {
        if n > missing+found {
          return false
        }
      }
      
      if forwardCheck && n-found == missing {
        // All unassigned variables must be assigned to values in the set
        for variable in variables {
          if variable.assignment == nil {
            var domain = variable.domain
            for value in domain {
              if !set.contains(value) {
                domain.hideValue(value)
              }
            }
            if domain.isEmpty {
              return false
            }
          }
        }
      }
    } else {
      if exact {
        if found != n {
          return false
        }
      } else {
        if found < n {
          return false
        }
      }
    }
    
    return true
  }
}

public class SomeNotInSetConstraint<T: Hashable> : SetConstraint<T> {
  let n: Int
  let exact: Bool
  
  public init<S: SequenceType where S.Generator.Element == T>(variables: [Variable<T>], set: S, n: Int=1, exact: Bool=false) {
    self.n = n
    self.exact = exact
    super.init(variables: variables, set: set)
  }
  
  public override func evaluate(_ forwardCheck: Bool=false) -> Bool {
    var missing = 0
    var found = 0
    for variable in variables {
      if let value = variable.assignment {
        found += Int(set.contains(value))
      } else {
        missing++
      }
    }
    
    if missing > 0 {
      if exact {
        if !(found <= n && n <= missing+found) {
          return false
        }
      } else {
        if n > missing+found {
          return false
        }
      }
      
      if forwardCheck && n-found == missing {
        // All unassigned variables must be assigned to values not in the set
        for variable in variables {
          if variable.assignment == nil {
            var domain = variable.domain
            for value in domain {
              if set.contains(value) {
                domain.hideValue(value)
              }
            }
            if domain.isEmpty {
              return false
            }
          }
        }
      }
    } else {
      if exact {
        if found != n {
          return false
        }
      } else {
        if found < n {
          return false
        }
      }
    }
    
    return true
  }
}

