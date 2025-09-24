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

    internal init(_ line: String, base time: TimeInterval) throws {
      /// start time (ms) [base], end time (ms) [base], restat mtime (ms) [epoch] (0 = none), path, hash (command murmur2)
      let components = line.split(separator: "\t")
      guard components.count == 5 else {
        throw NVError.Parser
      }

      guard let start = TimeInterval(components[0]) else {
        throw NVError.Parser
      }
      self.start = (start / 1000.0) + time

      guard let end = TimeInterval(components[1]) else {
        throw NVError.Parser
      }
      self.end = (end / 1000.0) + time

      // restat is ignored
      self.target = String(components[3])
      self.hash = String(components[4])
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
    let entries: [BuildEntry] = lines.compactMap {
      guard !$0.isEmpty, !$0.starts(with: /#/) else { return nil }
      return try? BuildEntry($0, base: time)
    }

    var seen = Set<BuildEntry>()
    self.entries = entries.compactMap { seen.insert($0).inserted ? $0 : nil }
  }
}
