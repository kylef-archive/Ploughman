#if os(OSX) || os(tvOS) || os(watchOS) || os(iOS)
  import Darwin.libc
#else
  import Glibc
#endif


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


func echo(_ content: [CustomStringConvertible]) {
  print(content.map { $0.description }.joined(separator: "") + ANSI.Reset.description)
}

class Reporter {
  func report(_ name: String, closure: (FeatureReporter) -> ()) {
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

  func report(_ name: String, closure: (ScenarioReporter) -> ()) {
    let reporter = ScenarioReporter(name: name)
    closure(reporter)
    reporter.print()
  }
}

extension Step : CustomStringConvertible {
  public var description: String {
    switch self {
    case .given(let given):
      return "Given \(given)"
    case .when(let when):
      return "When \(when)"
    case .then(let then):
      return "Then \(then)"
    }
  }
}

struct StepReport {
  let step: Step
  let failure: Error?

  init(step: Step, failure: Error? = nil) {
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

  func report(step: Step, failure: Error? = nil) {
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
