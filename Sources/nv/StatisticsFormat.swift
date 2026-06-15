// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser

internal enum StatisticsFormat: String, CaseIterable, ExpressibleByArgument {
  case detailed
  case brief
}

private let kTimeFormat: Duration.UnitsFormatStyle =
    .units(allowed: [.hours, .minutes, .seconds, .milliseconds])

extension StatisticsFormat {
  internal func output(statistics: borrowing BuildStatistics) throws {
    switch self {
    case .detailed:
      let fraction = statistics.time.wall == .zero
          ? 0.0 : statistics.time.serial / statistics.time.wall
      var slowest = Array<String>()
      // TODO: replace with for-in once InlineArray conforms to Iterable (Swift 6.4)
      for index in statistics.slowest.indices {
        guard let target = statistics.slowest[index] else { break }
        slowest.append("  \(target.target) (\(target.duration.formatted(kTimeFormat)))")
      }
      print("""
      Build Statistics Summary:
      =========================
      Total targets:       \(statistics.targets)
      Average build time:  \(statistics.stats.average.formatted(kTimeFormat))
      Median build time:   \(statistics.stats.median.formatted(kTimeFormat))
      Standard deviation:  \(statistics.stats.dispersion.formatted(kTimeFormat))
      95th percentile:     \(statistics.stats.p95.formatted(kTimeFormat))
      Minimum build time:  \(statistics.stats.min.formatted(kTimeFormat))
      Maximum build time:  \(statistics.stats.max.formatted(kTimeFormat))
      CPU time:            \(statistics.time.cpu.formatted(kTimeFormat))
      Wall time:           \(statistics.time.wall.formatted(kTimeFormat))
      Serial time:         \(statistics.time.serial.formatted(kTimeFormat)) (\(String(format: "%.1f%%", fraction * 100)) of wall)

      Slowest targets:
      \(slowest.joined(separator: "\n"))

      Parallelization Analysis:
      =========================
      Peak concurrency:     \(statistics.parallelism.peak) concurrent jobs
      Average occupancy:    \(String(format: "%.1f", statistics.parallelism.occupancy)) concurrent jobs
      Parallelization efficiency: \(String(format: "%.1f%%", statistics.parallelism.efficiency * 100))
      """)

    case .brief:
      print("""
      Build Overview:
      - \(statistics.targets) targets built
      - Total time: \(statistics.time.wall.formatted(kTimeFormat))
      - Average: \(statistics.stats.average.formatted(kTimeFormat))
      - Slowest: \(statistics.stats.max.formatted(kTimeFormat))
      """)
    }
  }
}
