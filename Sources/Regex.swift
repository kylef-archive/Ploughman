import Foundation


public struct RegexMatch {
  let checkingResult: NSTextCheckingResult
  let value: String

  init(checkingResult: NSTextCheckingResult, value: String) {
    self.checkingResult = checkingResult
    self.value = value
  }

  public var groups: [String] {
    return (0..<checkingResult.numberOfRanges).map {
      let range = checkingResult.rangeAtIndex($0)
      return NSString(string: value).substringWithRange(range)
    }
  }
}

struct Regex : CustomStringConvertible {
  let expression: NSRegularExpression

  init(expression: String) throws {
    self.expression = try NSRegularExpression(pattern: expression, options: [.CaseInsensitive])
  }

  var description: String {
    return expression.pattern
  }

  func matches(value: String) -> RegexMatch? {
    let matches = expression.matchesInString(value, options: NSMatchingOptions(), range: NSRange(location: 0, length: value.characters.count))
    if let match = matches.first {
      return RegexMatch(checkingResult: match, value: value)
    }

    return nil
  }
}
