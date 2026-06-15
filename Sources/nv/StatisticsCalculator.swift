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

  // In-place sort avoids allocating a second sorted array.
  events.sort { lhs, rhs in
    lhs.time == rhs.time
      ? (lhs.kind == .end && rhs.kind == .start)
      : lhs.time < rhs.time
  }

  // Single sweep: compute peak concurrency and the total time spent at
  // concurrency == 1 (serial time). Serial time directly measures how much
  // of the build was forced to run with a single target, which indicates
  // dependency bottlenecks that extra parallelism cannot address.
  var concurrency = 0
  var peak = 0
  var serial = Duration.zero
  var cursor = time.min

  for event in events {
    if concurrency == 1 { serial += .seconds(event.time - cursor) }
    cursor = event.time
    concurrency += event.kind == .start ? 1 : -1
    if concurrency > peak { peak = concurrency }
  }
  if concurrency == 1 { serial += .seconds(time.max - cursor) }
  let occupancy = walltime == .zero ? 0.0 : cputime / walltime
  let efficiency = peak == 0 ? 0.0 : occupancy / Double(peak)

  // Sort targets ascending to derive all statistical values from a single array,
  // eliminating the separate durations array and its associated sort.
  targets.sort { $0.duration < $1.duration }

  // Use full attosecond precision when computing variance; truncating to whole
  // seconds produces meaningless results for sub-second targets.
  let mean = average.seconds
  var variance = 0.0
  for target in targets {
    let difference = target.duration.seconds - mean
    variance += difference * difference
  }
  variance /= Double(count)

  var slowest = InlineArray<5, BuildStatistics.Target?>(repeating: nil)
  for (index, target) in targets.suffix(5).reversed().enumerated() {
    slowest[index] = target
  }

  let p95 = min(Int(Double(count) * 0.95), count - 1)
  return BuildStatistics(slowest: slowest,
                         parallelism: (peak: peak, occupancy: occupancy, efficiency: efficiency),
                         stats: (min: targets.first!.duration,
                                 max: targets.last!.duration,
                                 average: average,
                                 median: targets[count / 2].duration,
                                 p95: targets[p95].duration,
                                 dispersion: .seconds(sqrt(variance))),
                         targets: count,
                         time: (cpu: cputime, wall: walltime, serial: serial),
                         execution: (start: time.min, end: time.max))
}

extension Collection where Element: NinjaLogEntry {
  @inline(__always)
  internal var statistics: BuildStatistics {
    return calculate(from: self)
  }
}
