// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

#if os(Windows)
import WindowsCore
#else
import POSIXCore
#endif

internal protocol NinjaLogEntryEncoder {
  static func encode<Entries: Collection>(_ entries: Entries) throws -> Data
      where Entries.Element: NinjaLogEntry
}

extension Data {
  fileprivate mutating func write(row fields: [String]) {
    let line = fields.joined(separator: ",") + "\n"
    append(contentsOf: line.utf8)
  }
}

internal struct CSVEncoder: NinjaLogEntryEncoder {
  private static var headers: [String] {
    ["target", "start", "end", "duration (ms)", "hash"]
  }

  private static func escape(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
      return "\"\(field.replacing("\"", with: "\"\""))\""
    }
    return field
  }

  internal static func encode<Entries: Collection>(_ entries: Entries) throws -> Data
      where Entries.Element: NinjaLogEntry {
    var data = Data()
    data.reserveCapacity(SystemInfo.PageSize)

    data.write(row: headers)
    for entry in entries {
      data.write(row: [
        escape(entry.target),
        String(entry.start),
        String(entry.end),
        String(entry.duration.components.seconds * 1000),
        escape((entry as? NinjaLogVersion6.BuildEntry)?.hash ?? ""),
      ])
    }

    return data
  }
}

internal struct PrettyPrintedEncoder: NinjaLogEntryEncoder {
  private static var style: Duration.UnitsFormatStyle {
    .units(allowed: [.hours, .minutes, .seconds, .milliseconds])
  }

  internal static func encode<Entries: Collection>(_ entries: Entries) throws -> Data
      where Entries.Element: NinjaLogEntry {
    var data = Data()
    data.reserveCapacity(SystemInfo.PageSize)

    for entry in entries {
      let line = "\(entry.target) (\(entry.duration.formatted(style)))\n"
      data.append(contentsOf: line.utf8)
    }
    return data
  }
}

internal struct LogEntryJSONEncoder: NinjaLogEntryEncoder {
  internal static func encode<Entries: Collection>(_ entries: Entries) throws -> Data
      where Entries.Element: NinjaLogEntry {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .secondsSince1970
    return try encoder.encode(Array(entries))
  }
}
