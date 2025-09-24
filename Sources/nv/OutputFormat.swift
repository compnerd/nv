// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser
import Foundation

internal enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
  case console
  case json
  case csv
}

extension OutputFormat {
  internal func output(entries: [some NinjaLogEntry], to path: String) throws {
    let data = switch self {
    case .console:
      try PrettyPrintedEncoder.encode(entries)
    case .json:
      try LogEntryJSONEncoder.encode(entries)
    case .csv:
      try CSVEncoder.encode(entries)
    }

    guard let content = String(data: data, encoding: .utf8) else {
      throw NVError.Encoder
    }

    if path == "-" {
      print(content, terminator: "")
    } else {
      try content.write(toFile: path, atomically: true, encoding: .utf8)
    }
  }
}
