// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

#if os(Windows)
import WindowsCore
#else
import POSIXCore
#endif

internal protocol NinjaLogEntryEncoder {
  static func encode<Entries: Collection>(_ entries: borrowing Entries) throws -> Data
      where Entries.Element: NinjaLogEntry
}

extension Data {
  fileprivate mutating func write(row fields: borrowing Span<String>) {
    for index in 0 ..< fields.count {
      append(contentsOf: fields[index].utf8)
      if index < fields.count - 1 {
        append(UInt8(ascii: ","))
      }
    }
    append(UInt8(ascii: "\n"))
  }
}

private struct EntryCollection<C: Collection>: Encodable where C.Element: Encodable {
  let base: C
  func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    for element in base { try container.encode(element) }
  }
}

internal struct CSVEncoder: NinjaLogEntryEncoder {
  private static let headers: InlineArray<_, String> =
      ["target", "start", "end", "duration (ms)", "hash"]

  private static func escape(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
      return "\"\(field.replacing("\"", with: "\"\""))\""
    }
    return field
  }

  internal static func encode<Entries: Collection>(_ entries: borrowing Entries) throws -> Data
      where Entries.Element: NinjaLogEntry {
    var data = Data()
    data.reserveCapacity(SystemInfo.PageSize)

    data.write(row: headers.span)
    for entry in copy entries {
      let row: InlineArray<_, String> = [
        escape(entry.target),
        String(entry.start),
        String(entry.end),
        String(Int64(entry.duration.seconds * 1000)),
        escape((entry as? NinjaLogVersion6.BuildEntry)?.hash ?? ""),
      ]
      data.write(row: row.span)
    }

    return data
  }
}

internal struct PrettyPrintedEncoder: NinjaLogEntryEncoder {
  private static let style: Duration.UnitsFormatStyle =
      .units(allowed: [.hours, .minutes, .seconds, .milliseconds])

  internal static func encode<Entries: Collection>(_ entries: borrowing Entries) throws -> Data
      where Entries.Element: NinjaLogEntry {
    var data = Data()
    data.reserveCapacity(SystemInfo.PageSize)

    for entry in copy entries {
      data.append(contentsOf: entry.target.utf8)
      data.append(UInt8(ascii: " "))
      data.append(UInt8(ascii: "("))
      data.append(contentsOf: entry.duration.formatted(style).utf8)
      data.append(UInt8(ascii: ")"))
      data.append(UInt8(ascii: "\n"))
    }
    return data
  }
}

internal struct LogEntryJSONEncoder: NinjaLogEntryEncoder {
  internal static func encode<Entries: Collection>(_ entries: borrowing Entries) throws -> Data
      where Entries.Element: NinjaLogEntry {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .secondsSince1970
    return try encoder.encode(EntryCollection(base: copy entries))
  }
}
