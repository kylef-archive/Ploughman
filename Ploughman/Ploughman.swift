import Darwin.libc
import PathKit
import Commander


public struct StepHandler {
  public typealias Handler = (RegexMatch) throws -> ()

  let expression: Regex
  let handler: Handler

  init(expression: Regex, handler: Handler) {
    self.expression = expression
    self.handler = handler
  }
}


enum StepError : ErrorType, CustomStringConvertible {
  case NoMatch(Step)
  case AmbiguousMatch(Step, [StepHandler])

  var description: String {
    switch self {
    case .NoMatch:
      return "No matches found"
    case .AmbiguousMatch(let handlers):
      let matches = handlers.1.map { "       - `\($0.expression)`" }.joinWithSeparator("\n")
      return "Too many matches found:\n\(matches)"
    }
  }
}


public class Ploughman : CommandType {
  let scenario: [Scenario] = []

  init() {}

  public typealias Handler = () throws -> ()

  var befores: [Handler] = []
  var afters: [Handler] = []
  var givens: [StepHandler] = []
  var whens: [StepHandler] = []
  var thens: [StepHandler] = []

  public func before(closure: Handler) {
    befores.append(closure)
  }

  public func after(closure: Handler) {
    afters.append(closure)
  }

  public func given(expression: String, closure: StepHandler.Handler) {
    let regex = try! Regex(expression: expression)
    let handler = StepHandler(expression: regex, handler: closure)
    givens.append(handler)
  }

  public func then(expression: String, closure: StepHandler.Handler) {
    let regex = try! Regex(expression: expression)
    let handler = StepHandler(expression: regex, handler: closure)
    thens.append(handler)
  }

  public func when(expression: String, closure: StepHandler.Handler) {
    let regex = try! Regex(expression: expression)
    let handler = StepHandler(expression: regex, handler: closure)
    whens.append(handler)
  }

  public func run(parser: ArgumentParser) throws {
    var paths: [Path] = []
    while let arg = parser.shift() { paths.append(Path(arg)) }
    let features = try Feature.parse(paths)

    if features.isEmpty {
      print("No features found.")
      exit(1)
    }

    var scenarios = 0
    var failures = 0
    let reporter = Reporter()
    for feature in features {
        reporter.report(feature.name) { reporter in
        for scenario in feature.scenarios {
          ++scenarios

          reporter.report(scenario.name) { reporter in
            for step in scenario.steps {
              if !runStep(step, reporter: reporter) {
                ++failures
                break
              }
            }
          }
        }
      }
    }

    print("\n\(scenarios - failures) scenarios passed, \(failures) scenarios failed.")
    if failures > 0 {
      exit(1)
    }
  }

  func runStep(step: Step, reporter: ScenarioReporter) -> Bool {
    var failure: ErrorType? = nil

    switch step {
    case .Given(let given):
      do {
        let (handler, match) = try findGiven(step, name: given)
        try handler.handler(match)
      } catch {
        failure = error
      }
    case .When(let when):
      do {
        let (handler, match) = try findWhen(step, name: when)
        try handler.handler(match)
      } catch {
        failure = error
      }
    case .Then(let then):
      do {
        let (handler, match) = try findThen(step, name: then)
        try handler.handler(match)
      } catch {
        failure = error
      }
    }

    reporter.report(step, failure: failure)
    return failure == nil
  }

  func findGiven(step: Step, name: String) throws -> (StepHandler, RegexMatch) {
    let matchedGivens = givens.filter { $0.expression.matches(name) != nil }
    if matchedGivens.count > 1 {
      throw StepError.AmbiguousMatch(step, matchedGivens)
    } else if let given = matchedGivens.first {
      let match = given.expression.matches(name)!
      return (given, match)
    }

    throw StepError.NoMatch(step)
  }

  func findWhen(step: Step, name: String) throws -> (StepHandler, RegexMatch) {
    let matched = whens.filter { $0.expression.matches(name) != nil }
    if matched.count > 1 {
      throw StepError.AmbiguousMatch(step, matched)
    } else if let result = matched.first {
      let match = result.expression.matches(name)!
      return (result, match)
    }

    throw StepError.NoMatch(step)
  }

  func findThen(step: Step, name: String) throws -> (StepHandler, RegexMatch) {
    let matched = thens.filter { $0.expression.matches(name) != nil }
    if matched.count > 1 {
      throw StepError.AmbiguousMatch(step, matched)
    } else if let result = matched.first {
      let match = result.expression.matches(name)!
      return (result, match)
    }

    throw StepError.NoMatch(step)
  }
}


public let ploughman: Ploughman = {
  return Ploughman()
}()

public func given(expression: String, closure: StepHandler.Handler) {
  ploughman.given(expression, closure: closure)
}

public func when(expression: String, closure: StepHandler.Handler) {
  ploughman.when(expression, closure: closure)
}

public func then(expression: String, closure: StepHandler.Handler) {
  ploughman.then(expression, closure: closure)
}
