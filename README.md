# SwiftConstraint
A constraint programming library written in [Swift](https://swift.org), based on [python-constraint](https://labix.org/python-constraint). Note that this library was written as an exercise to learn Swift, see the related projects for other supported options.

You will need to instantiate a [`Problem`](https://github.com/timpalpant/SwiftConstraint/blob/master/ConstraintSolver/Problem.swift#L169),
comprised of [`Variables`](https://github.com/timpalpant/SwiftConstraint/blob/master/ConstraintSolver/Problem.swift#L111)
over a possible [`Domain`](https://github.com/timpalpant/SwiftConstraint/blob/master/ConstraintSolver/Problem.swift#L101),
and constrained by [`Constraints`](https://github.com/timpalpant/SwiftConstraint/blob/master/ConstraintSolver/Constraint.swift#L33). Several different
types of constraints are [`built in`](https://github.com/timpalpant/SwiftConstraint/blob/master/ConstraintSolver/Constraint.swift#L66), including:
* AllDifferentConstraint
* AllEqualConstraint
* MaxSumConstraint
* ExactSumConstraint
* MinSumConstraint
* DifferenceConstraint
* AbsDifferenceConstraint
* ProductConstraint
* QuotientConstraint
* InvertibleQuotientConstraint
* InSetConstraint
* NotInSetConstraint
* SomeInSetConstraint
* SomeNotInSetConstraint

These constraints are implemented generically for types satisfying the `Hashable` or [`Arithmetic`](https://github.com/timpalpant/SwiftConstraint/blob/master/ConstraintSolver/NumericTypes.swift#L11) protocols.

## Examples

### Simple

Define two integer variables `m`, `n`, over the domain `d = {1..10}` that must sum to exactly 4

```swift
  d = Domain<Int>(values: 1...10)
  m = Variable<Int>(domain: d)
  n = Variable<Int>(domain: d)
  c = ExactSumConstraint<Int>(variables: [m, n], sum: 4)
  p = Problem<Int>()
  p.variables.append(m)
  p.variables.append(n)
  p.constraints.append(c)
  
  # Solve the problem with the BacktrackingSolver.
  let solver = BacktrackingSolver()
  solver.solve(p)
  
  # Print all valid solutions (assignments of x and y).
  for sol in p.solutions {
    print("x:", sol[0], "y:", sol[1], "separator: " ")
  }
```

### Sudoku

Given a Sudoku "board" defined as an N^2 list of integers (0 if not yet filled in),
initialize a Problem with the Sudoku puzzle constraints, and use the BacktrackingSolver
to solve it:

```swift
public class SudokuPuzzle {
  let board: [Int]
  var problem: Problem<Int>
  let size: Int
  
  public init(board: [Int]) {
    self.board = board
    size = Int(sqrt(Double(board.count)))
    problem = Problem<Int>()
    self.init_variables()
    self.init_constraints()
  }
  
  func init_variables() {
    let domain = Domain<Int>(values: 1...size)
    for _ in 1...size {
      for _ in 1...size {
        problem.variables.append(Variable<Int>(domain: domain))
      }
    }
  }
  
  func init_constraints() {
    // Rows must be all different
    for i in 0..<size {
      let row = Array(problem.variables[i*size..<(i+1)*size])
      let c = AllDifferentConstraint(variables: row)
      problem.constraints.append(c)
    }
    
    // Cols must be all different
    for j in 0..<size {
      let col = (0..<size).map { i in self.problem.variables[i*self.size+j] }
      let c = AllDifferentConstraint(variables: col)
      problem.constraints.append(c)
    }
    
    // Boxes must be all diferent
    for i in 0..<3 {
      for j in 0..<4 {
        var box: [Variable<Int>] = []
        for k in 0..<4 {
          for l in 0..<3 {
            let row = 3*j + l
            let col = 4*i + k
            let index = row*size + col
            box.append(problem.variables[index])
          }
        }
        let c = AllDifferentConstraint(variables: box)
        problem.constraints.append(c)
      }
    }
    
    // Pre-specified numbers
    for (i, v) in board.enumerate() {
      if v != 0 { // has a value
        let c = InSetConstraint(variables: [problem.variables[i]], set: [v])
        problem.constraints.append(c)
      }
    }
  }
  
  public func solution() -> [Int]? {
    let solver = BacktrackingSolver(forwardCheck: true)
    solver.solve(problem)
    return problem.solutions.first
  }
}
```

# Related projects

* https://github.com/davecom/SwiftCSP
