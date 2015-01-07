//
//  NumericTypes.swift
//  ConstraintSolver
//
//  Created by Timothy Palpant on 1/6/15.
//  Copyright (c) 2015 Timothy Palpant. All rights reserved.
//

import Foundation

public protocol Summable {
  func +(lhs: Self, rhs: Self) -> Self
}

public protocol Subtractable {
  func -(lhs: Self, rhs: Self) -> Self
}

public protocol Multiplicable {
  func *(lhs: Self, rhs: Self) -> Self
}

public protocol Divisible {
  func /(lhs: Self, rhs: Self) -> Self
}

public protocol Arithmetic : Comparable, Summable, IntegerLiteralConvertible { }
public protocol Numeric : Arithmetic, Subtractable, Multiplicable, Divisible { }

extension Int : Numeric { }
extension Float : Numeric { }
extension Double : Numeric { }

func sum<T, S: SequenceType where T == S.Generator.Element,
  T: protocol<IntegerLiteralConvertible, Summable>>(var s: S) -> T {
    return reduce(s, 0, {$0 + $1})
}

func product<T, S: SequenceType where T == S.Generator.Element,
  T: protocol<IntegerLiteralConvertible, Multiplicable>>(var s: S) -> T {
    return reduce(s, 1, {$0 * $1})
}