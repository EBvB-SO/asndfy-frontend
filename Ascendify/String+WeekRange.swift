//
//  String+WeekRange.swift
//  Ascendify
//
//  Created by Ellis Barker on 06/08/2025.
//

import Foundation

private let _weekRangeRegex: NSRegularExpression = {
  // compile once
  return try! NSRegularExpression(
    pattern: "Week(?:s)? (\\d+)-(\\d+)",
    options: .caseInsensitive
  )
}()

extension String {
  /// If the string contains “Week X-Y” or “Weeks X-Y”, returns X..<(Y+1).
  func extractWeekRange() -> Range<Int>? {
    let nsRange = NSRange(startIndex..<endIndex, in: self)
    guard let match = _weekRangeRegex.firstMatch(in: self, options: [], range: nsRange),
          let loR = Range(match.range(at: 1), in: self),
          let hiR = Range(match.range(at: 2), in: self),
          let lo  = Int(self[loR]),
          let hi  = Int(self[hiR])
    else { return nil }
    return lo..<(hi + 1)
  }
}
