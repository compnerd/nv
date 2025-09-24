// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

#if os(Windows)
import WindowsCore
#else
import POSIXCore
#endif

internal protocol NinjaLogEntry: Encodable {
  var start: TimeInterval { get }
  var end: TimeInterval { get }
  var target: String { get }
}

extension NinjaLogEntry {
  var duration: Duration { .seconds(self.end - self.start) }
}

internal protocol NinjaLog {
  associatedtype Entry: NinjaLogEntry
  var entries: [Entry] { get }
  init(parse lines: inout NinjaLogIterator, base time: TimeInterval)
}

internal enum NinjaLogParser {
  internal static func load(at url: URL) throws -> some NinjaLog {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    guard let mtime = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 else {
      throw NVError.IO
    }

    var lines = try NinjaLogIterator(at: url)
    guard let header = lines.next() else {
      throw NVError.Parser
    }

    guard let match = header.firstMatch(of: /# ninja log v(\d+)/), let version = Int(match.1) else {
      throw NVError.Parser
    }

    return switch version {
    case 6:
      NinjaLogVersion6(parse: &lines, base: mtime)
    default:
      throw NVError.UnsupportedVersion(version)
    }
  }
}

internal struct NinjaLogIterator: IteratorProtocol, Sequence {
  private static let delimiter = Data([0x0a])
  private static let chunkSize = SystemInfo.PageSize

  private let handle: FileHandle
  private var buffer: Data
  private var exhausted: Bool

  internal init(at: URL) throws {
    self.handle = try FileHandle(forReadingFrom: at)
    self.buffer = Data()
    self.exhausted = false
  }

  internal mutating func next() -> String? {
    guard !self.exhausted else { return nil }

    while true {
      if let range = buffer.range(of: Self.delimiter) {
        let data = buffer.subdata(in: buffer.startIndex ..< range.lowerBound)
        buffer.removeSubrange(buffer.startIndex ..< range.upperBound)
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
      }

      let chunk = handle.readData(ofLength: Self.chunkSize)
      if chunk.isEmpty {
        exhausted = true
        if !buffer.isEmpty, let line = String(data: buffer, encoding: .utf8) {
          buffer.removeAll()
          return line.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
      }

      buffer.append(chunk)
    }
  }
}
