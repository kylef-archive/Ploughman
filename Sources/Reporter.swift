import Darwin.libc


enum ANSI : String, CustomStringConvertible {
  case Red = "\u{001B}[0;31m"
  case Green = "\u{001B}[0;32m"
  case Yellow = "\u{001B}[0;33m"

  case Bold = "\u{001B}[0;1m"
  case Reset = "\u{001B}[0;0m"

  var description:String {
    if isatty(STDOUT_FILENO) > 0 {
      return rawValue
    }

    return ""
  }
}


func echo(content: [CustomStringConvertible]) {
  print(content.map { $0.description }.joinWithSeparator("") + ANSI.Reset.description)
}

class Reporter {
  func report(name: String, @noescape closure: FeatureReporter -> ()) {
    let reporter = FeatureReporter(name: name)
    print("-> \(name)")
    closure(reporter)
  }
}

class FeatureReporter {
  let name: String

  init(name: String) {
    self.name = name
  }

  func report(name: String, @noescape closure: ScenarioReporter -> ()) {
    let reporter = ScenarioReporter(name: name)
    closure(reporter)
    reporter.print()
  }
}

extension Step : CustomStringConvertible {
  public var description: String {
    switch self {
    case .Given(let given):
      return "Given \(given)"
    case .When(let when):
      return "When \(when)"
    case .Then(let then):
      return "Then \(then)"
    }
  }
}

struct StepReport {
  let step: Step
  let failure: ErrorType?

  init(step: Step, failure: ErrorType? = nil) {
    self.step = step
    self.failure = failure
  }
}

class ScenarioReporter {
  let name: String
  var reports: [StepReport] = []

  init(name: String) {
    self.name = name
  }

  func report(step: Step, failure: ErrorType? = nil) {
    reports.append(StepReport(step: step, failure: failure))
  }

  func print() {
    let didFail = !reports.filter { $0.failure != nil }.isEmpty
    if didFail {
      echo([ANSI.Red, "  -> ", name])

      for report in reports {
        if let failure = report.failure {
          echo([ANSI.Red, "    -> ", report.step])
          echo(["      ", "\(failure)\n"])
        } else {
          echo([ANSI.Green, "    -> ", report.step])
        }
      }
    } else {
      echo([ANSI.Green, "  -> ", name])
    }
  }
}
