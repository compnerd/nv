// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

extension NinjaLogVersion6 {
  internal struct BuildEntry: NinjaLogEntry {
    internal let start: TimeInterval
    internal let end: TimeInterval
    internal let target: String
    internal let hash: String

    private enum CodingKeys: String, CodingKey {
      case start, end, target, hash
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(start, forKey: .start)
      try container.encode(end, forKey: .end)
      try container.encode(target, forKey: .target)
      try container.encode(hash, forKey: .hash)
    }

    @inline(__always)
    internal init(_ line: consuming String, base time: TimeInterval) throws {
      /// start time (ms) [base], end time (ms) [base], restat mtime (ms) [epoch] (0 = none), path, hash (command murmur2)
      var rest = line[...]

      guard let t0 = rest.firstIndex(of: "\t") else { throw NVError.Parser }
      guard let start = TimeInterval(rest[..<t0]) else { throw NVError.Parser }
      self.start = (start / 1000.0) + time
      rest = rest[rest.index(after: t0)...]

      guard let t1 = rest.firstIndex(of: "\t") else { throw NVError.Parser }
      guard let end = TimeInterval(rest[..<t1]) else { throw NVError.Parser }
      self.end = (end / 1000.0) + time
      rest = rest[rest.index(after: t1)...]

      guard let t2 = rest.firstIndex(of: "\t") else { throw NVError.Parser }
      rest = rest[rest.index(after: t2)...]

      guard let t3 = rest.firstIndex(of: "\t") else { throw NVError.Parser }
      self.target = String(rest[..<t3])
      self.hash = String(rest[rest.index(after: t3)...])
    }
  }
}

extension NinjaLogVersion6.BuildEntry: Equatable {
  public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    return lhs.hash == rhs.hash
  }
}

extension NinjaLogVersion6.BuildEntry: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.hash)
  }
}

internal struct NinjaLogVersion6: NinjaLog {
  internal let entries: [BuildEntry]

  internal init(parse lines: inout NinjaLogIterator, base time: TimeInterval) {
    var seen = Set<String>()
    var entries = Array<BuildEntry>()
    for line in lines {
      if line.isEmpty || line.first == "#" { continue }
      guard let entry = try? BuildEntry(line, base: time) else { continue }
      if seen.insert(entry.hash).inserted { entries.append(entry) }
    }
    self.entries = entries
  }
}
