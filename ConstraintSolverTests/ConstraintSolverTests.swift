//
//  ConstraintSolverTests.swift
//  ConstraintSolverTests
//
//  Created by Timothy Palpant on 7/29/14.
//  Copyright (c) 2014 Timothy Palpant. All rights reserved.
//

import XCTest
import ConstraintSolver

class ConstraintSolverTests: XCTestCase {
  var s: Set<Int>!
  var d: Domain<Int>!
  var v: Variable<Int>!
  var c: Constraint<Int>!
  var p: Problem<Int>!
  
  override func setUp() {
    super.setUp()
    d = Domain<Int>(values: 1...10)
    v = Variable<Int>(domain: d)
    c = MaxSumConstraint<Int>(variables: [v], sum: 4)
    p = Problem<Int>()
    p.variables.append(v)
    p.constraints.append(c)
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testDomain() {
    XCTAssertFalse(d.isEmpty, "Domain is not empty")
    XCTAssertTrue(d.contains(4), "4 is in domain")
    XCTAssertFalse(d.contains(-1), "-1 is not in domain")
    XCTAssertFalse(d.contains(11), "11 is not in domain")
    XCTAssertEqual(d.count, 10, "10 elements in domain")
  }
  
  func testVariable() {
    XCTAssertEqual(v.constraints.count, 1, "Variable has 1 constraint")
    XCTAssert(v.assignment == nil, "Variable has no assignment")
    v.assignment = 4
    XCTAssertEqual(v.assignment!, 4, "Variable has assignment 4")
  }
  
  func testConstraint() {
    v.assignment = 3
    XCTAssertTrue(c.evaluate(false), "Constraint is satisfied when v = 3")
    v.assignment = 5
    XCTAssertFalse(c.evaluate(false), "Constraint is not satisified when v = 5")
    v.assignment = 1
    XCTAssertTrue(c.evaluate(false), "Constraint is satisfied when v = 1")
  }
  
  func testRecursiveBacktrackingSolver() {
    let solver = RecursiveBacktrackingSolver()
    solver.solve(p)
    XCTAssertEqual(p.solutions.count, 4, "Problem has 4 solutions")
    for sol in p.solutions {
      for v in sol {
        XCTAssertLessThanOrEqual(v, 4, "Solutions are <= 4")
      }
    }
  }
  
  func testBacktrackingSolver() {
    let solver = BacktrackingSolver()
    solver.solve(p)
    XCTAssertEqual(p.solutions.count, 4, "Problem has 4 solutions")
    for sol in p.solutions {
      for v in sol {
        XCTAssertLessThanOrEqual(v, 4, "Solutions are <= 4")
      }
    }
  }
  
  func testBacktrackingSolver2D() {
    let v2 = Variable<Int>(domain: d)
    let c2 = ExactSumConstraint<Int>(variables: [v,v2], sum: 6)
    p.variables.append(v2)
    p.constraints.append(c2)
    
    let solver = BacktrackingSolver()
    solver.solve(p)
    XCTAssertEqual(p.solutions.count, 4, "Problem has 4 solutions")
    for sol in p.solutions {
      XCTAssertLessThanOrEqual(sol[0], 4, "First element is <= 4")
      XCTAssertEqual(sol[0]+sol[1], 6, "Solutions total 6")
    }
  }
  
  func testMinConflictsSolver() {
    let solver = MinConflictsSolver()
    solver.solve(p)
    XCTAssertEqual(p.solutions.count, 1, "MinConflictsSolver only finds 1 solution")
    for sol in p.solutions {
      for v in sol {
        XCTAssertLessThanOrEqual(v, 4, "Solution is <= 4")
      }
    }
  }
  
  //func testPerformanceExample() {
    // This is an example of a performance test case.
  //  self.measureBlock() {
      // Put the code you want to measure the time of here.
  //  }
  //}
  
}
