// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

private struct Event {
  enum Kind {
    case start
    case end
  }

  let kind: Kind
  let time: TimeInterval
}

@inline(__always)
private func calculate<Entries: Collection>(from entries: borrowing Entries)
    -> BuildStatistics where Entries.Element: NinjaLogEntry {
  guard !entries.isEmpty else { return .zero }
  let count = entries.count

  var events = Array<Event>()
  var targets = Array<BuildStatistics.Target>()

  events.reserveCapacity(count * 2)
  targets.reserveCapacity(count)

  var time = (min: TimeInterval.infinity, max: -TimeInterval.infinity)
  var cputime = Duration.zero

  for entry in copy entries {
    let duration = entry.duration

    targets.append(BuildStatistics.Target(entry.target, duration))
    // target is not needed by the parallelism sweep — omit it from Event.
    // Zero-duration entries (start == end) are excluded: the end-before-start
    // tie-break would drive concurrency negative and corrupt peak/serial values.
    if entry.start != entry.end {
      events.append(Event(kind: .start, time: entry.start))
      events.append(Event(kind: .end, time: entry.end))
    }

    cputime += duration
    if entry.start < time.min { time.min = entry.start }
    if entry.end > time.max { time.max = entry.end }
  }

  let walltime = Duration.seconds(time.max - time.min)
  let average = cputime / Double(count)
  let efficiency = walltime == .zero ? 0.0 : cputime / walltime

  // In-place sort avoids allocating a second sorted array.
  events.sort { lhs, rhs in
    lhs.time == rhs.time
      ? (lhs.kind == .end && rhs.kind == .start)
      : lhs.time < rhs.time
  }
  let width = events.reduce(into: (current: 0, max: 0)) { width, event in
    width.current += event.kind == .start ? 1 : -1
    width.max = max(width.max, width.current)
  }.max

  // Sort targets ascending to derive all statistical values from a single array,
  // eliminating the separate durations array and its associated sort.
  targets.sort { $0.duration < $1.duration }

  let mean = Double(average.components.seconds)
  var variance = 0.0
  for target in targets {
    let difference = Double(target.duration.components.seconds) - mean
    variance += difference * difference
  }
  variance /= Double(count)

  let n = min(5, count)
  return BuildStatistics(outliers: (fastest: Array(targets.prefix(n)),
                                    slowest: Array(targets.suffix(n).reversed())),
                          parallelism: (cores: width, efficiency: efficiency),
                          stats: (min: targets.first!.duration,
                                  max: targets.last!.duration,
                                  average: average,
                                  median: targets[count / 2].duration,
                                  p95: targets[min(Int(Double(count) * 0.95), count - 1)].duration,
                                  dispersion: .seconds(sqrt(variance))),
                          targets: count,
                          time: (cpu: cputime, wall: walltime),
                          execution: (start: time.min, end: time.max))
}

extension Collection where Element: NinjaLogEntry {
  @inline(__always)
  internal var statistics: BuildStatistics {
    return calculate(from: self)
  }
}
