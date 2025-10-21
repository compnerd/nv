// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

private struct Event {
  enum Kind {
    case start
    case end
  }

  let target: String
  let kind: Kind
  let time: TimeInterval
}

extension BuildStatistics {
  fileprivate static func calculate<Entries: Collection>(from entries: Entries)
      -> BuildStatistics where Entries.Element: NinjaLogEntry {
    guard entries.isEmpty == false else { return .zero }
    let count = entries.count

    // Pre-allocate arrays with known capacity for better performance.
    var durations: [Duration] = []
    var events: [Event] = []
    var targets: [BuildStatistics.Target] = []

    durations.reserveCapacity(count)
    events.reserveCapacity(count * 2)
    targets.reserveCapacity(count)

    // Single pass to collect raw data.
    var time = (min: TimeInterval.infinity, max: -TimeInterval.infinity)
    var cputime = Duration.zero

    for entry in entries {
      let duration = entry.duration

      durations.append(duration)
      targets.append(BuildStatistics.Target(entry.target, duration))

      events.append(Event(target: entry.target, kind: .start, time: entry.start))
      events.append(Event(target: entry.target, kind: .end, time: entry.end))

      cputime += duration
      time.min = min(time.min, entry.start)
      time.max = max(time.max, entry.end)
    }

    // Derived metrics from collected data.
    let walltime = Duration.seconds(time.max - time.min)
    let average = cputime / Double(count)
    let efficiency = walltime == .zero ? 0.0 : cputime / walltime

    let width = events.sorted { lhs, rhs in
      if lhs.time == rhs.time {
        return switch (lhs.kind, rhs.kind) {
        case (.end, .start): true
        case (.start, .end): false
        case (.start, .start), (.end, .end): false
        }
      }
      return lhs.time < rhs.time
    }.reduce(into: (current: 0, max: 0)) { width, event in
      width.current = width.current + (event.kind == .start ? 1 : -1)
      width.max = max(width.max, width.current)
    }.max

    // Calculate standard deviation
    let avg = average.components.seconds
    let variance = durations.lazy.map { duration in
      let difference = Double(duration.components.seconds - avg)
      return difference * difference
    }.reduce(0.0, +) / Double(count)

    // Sort arrays for statistical calculations.
    durations.sort()
    targets.sort { $0.duration > $1.duration }

    return BuildStatistics(outliers: (fastest: Array(targets.suffix(5).reversed()),
                                      slowest: Array(targets.prefix(5))),
                           parallelism: (cores: width, efficiency: efficiency),
                           stats: (min: durations.first!, max: durations.last!,
                                   average: average,
                                   median: durations[durations.count / 2],
                                   p95: durations[min(Int(Double(count) * 0.95), count - 1)],
                                   dispersion: .seconds(sqrt(variance))),
                           targets: count,
                           time: (cpu: cputime, wall: walltime),
                           execution: (start: time.min, end: time.max))
  }
}

extension Collection where Element: NinjaLogEntry {
  internal var statistics: BuildStatistics {
    return .calculate(from: self)
  }
}
