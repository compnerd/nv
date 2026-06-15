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
  @inline(__always)
  var duration: Duration { .seconds(self.end - self.start) }
}

internal protocol NinjaLog {
  associatedtype Entry: NinjaLogEntry
  var entries: [Entry] { get }
  init(parse lines: inout NinjaLogIterator, base time: TimeInterval)
}

internal enum NinjaLogParser {
  internal static func load(at url: consuming URL) throws -> some NinjaLog {
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
  private static let delimiter = UInt8(ascii: "\n")
  private static let chunkSize = SystemInfo.PageSize

  private let handle: FileHandle
  private var buffer: Array<UInt8>
  private var exhausted: Bool

  internal init(at url: consuming URL) throws {
    self.handle = try FileHandle(forReadingFrom: url)
    self.buffer = []
    self.exhausted = false
  }

  internal mutating func next() -> String? {
    guard !self.exhausted else { return nil }

    while true {
      if let index = buffer.firstIndex(of: NinjaLogIterator.delimiter) {
        var line = buffer.withUnsafeBufferPointer { buffer in
          String(UnsafeBufferPointer(start: buffer.baseAddress, count: index).span)
        }
        buffer.removeSubrange(..<(index + 1))
        if line.last == "\r" { line.removeLast() }
        return line
      }

      let chunk = handle.readData(ofLength: NinjaLogIterator.chunkSize)
      if chunk.isEmpty {
        exhausted = true
        guard !buffer.isEmpty else { return nil }
        var line = buffer.withUnsafeBufferPointer { buffer in
          String(buffer.span)
        }
        buffer.removeAll(keepingCapacity: false)
        if line.last == "\r" { line.removeLast() }
        return line.isEmpty ? nil : line
      }

      buffer.append(contentsOf: chunk)
    }
  }
}
