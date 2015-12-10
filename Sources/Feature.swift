import Foundation
import PathKit


public enum Step {
  case Given(String)
  case When(String)
  case Then(String)
}


public struct Scenario {
  public let name: String
  public var steps: [Step]

  public let file: Path
  public let line: Int

  init(name: String, steps: [Step], file: Path, line: Int) {
    self.name = name
    self.steps = steps
    self.file = file
    self.line = line
  }
}


struct ParseError : ErrorType, CustomStringConvertible {
  let description: String

  init(_ message: String) {
    description = message
  }
}

enum ParseState {
  case Unknown
  case Feature
  case Scenario
  case Given
  case When
  case Then
  case And

  init?(value: String) {
    if value == "feature" {
      self = .Feature
    } else if value == "scenario" {
      self = .Scenario
    } else if value == "given" {
      self = .Given
    } else if value == "when" {
      self = .When
    } else if value == "then" {
      self = .Then
    } else if value == "and" {
      self = .And
    } else {
      return nil
    }
  }

  func toStep(value: String) -> Step? {
    switch self {
    case .Given:
      return .Given(value)
    case .When:
      return .When(value)
    case .Then:
      return .Then(value)
    default:
      return nil
    }
  }
}

public struct Feature {
  public let name: String
  public let scenarios: [Scenario]

  public static func parse(paths: [Path]) throws -> [Feature] {
    var features: [Feature] = []

    for path in paths {
      let content: String = try path.read()
      var line = 0
      var state = ParseState.Unknown
      var scenario: Scenario?

      var featureName: String?
      var scenarios: [Scenario] = []

      func commitFeature() {
        commitScenario()

        if let featureName = featureName {
          features.append(Feature(name: featureName, scenarios: scenarios))
        }

        featureName = nil
        scenarios = []
      }

      func commitScenario() {
        if let scenario = scenario {
          scenarios.append(scenario)
        }

        scenario = nil
      }

      func handleComponent(key: String, _ value: String) throws {
        if var newState = ParseState(value: key.lowercaseString) {
          if newState == .And {
            newState = state
          }

          if newState == .Unknown {
            throw ParseError("Invalid content `\(key.lowercaseString)` on line \(line) of \(path)")
          }

          if newState == .Feature {
            commitFeature()
            featureName = value
          } else if newState == .Scenario {
            commitScenario()
            scenario = Scenario(name: value, steps: [], file: path, line: line)
          } else if let step = newState.toStep(value) {
            scenario?.steps.append(step)
          }

          state = newState
        } else {
          throw ParseError("Invalid content on line \(line) of \(path)")
        }
      }

      for content in content.componentsSeparatedByString("\n") {
        ++line

        let contents = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if contents.isEmpty {
          continue
        }
        let tokens = contents.split(":", maxSplit: 1)
        if tokens.count == 2 {
          let key = String(tokens[0]).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
          let value = String(tokens[1]).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
          try handleComponent(key, value)
        } else {
          let tokens = contents.split(" ", maxSplit: 1)
          if tokens.count == 2 {
            let key = String(tokens[0]).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let value = String(tokens[1]).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            try handleComponent(key, value)
          } else {
            throw ParseError("Invalid content on line \(line) of \(path)")
          }
        }
      }

      commitFeature()
    }

    return features
  }

  init(name: String, scenarios: [Scenario]) {
    self.name = name
    self.scenarios = scenarios
  }
}

extension String {
  func split(character: Character, maxSplit: Int) -> [String] {
    return characters.split(maxSplit) { $0 == character }
                     .map(String.init)
  }
}
