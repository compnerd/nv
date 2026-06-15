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
  internal func output(entries: borrowing [some NinjaLogEntry], to path: String) throws {
    let data = switch self {
    case .console:
      try PrettyPrintedEncoder.encode(entries)
    case .json:
      try LogEntryJSONEncoder.encode(entries)
    case .csv:
      try CSVEncoder.encode(entries)
    }

    if path == "-" {
      FileHandle.standardOutput.write(data)
    } else {
      try data.write(to: URL(fileURLWithPath: path), options: .atomic)
    }
  }
}
