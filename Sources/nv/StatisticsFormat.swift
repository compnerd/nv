// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser

internal enum StatisticsFormat: String, CaseIterable, ExpressibleByArgument {
  case detailed
  case brief
}

private var kTimeFormat: Duration.UnitsFormatStyle {
  .units(allowed: [.hours, .minutes, .seconds, .milliseconds])
}

extension StatisticsFormat {
  internal func output(statistics: BuildStatistics) throws {
    switch self {
    case .detailed:
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

      Slowest targets:
      \(statistics.outliers.slowest.map { build in
          "  \(build.target) (\(build.duration.formatted(kTimeFormat)))"
        }.joined(separator: "\n"))

      Fastest targets:
      \(statistics.outliers.fastest.map { build in
          "  \(build.target) (\(build.duration.formatted(kTimeFormat)))"
      }.joined(separator: "\n"))

      Parallelization Analysis:
      =========================
      Estimated cores used: \(statistics.parallelism.cores)
      Parallelization efficiency: \(String(format: "%.2f%%", statistics.parallelism.efficiency * 100))
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
