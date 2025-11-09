// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

internal struct BuildStatistics {
  internal typealias Target = (target: String, duration: Duration)

  let outliers: (fastest: Array<Target>, slowest: Array<Target>)
  let parallelism: (cores: Int, efficiency: Double)
  let stats: (min: Duration, max: Duration, average: Duration, median: Duration, p95: Duration, dispersion: Duration)
  let targets: Int
  let time: (cpu: Duration, wall: Duration)
  let execution: (start: TimeInterval, end: TimeInterval)
}

extension BuildStatistics {
  static var zero: BuildStatistics {
    BuildStatistics(outliers: (fastest: [], slowest: []),
                    parallelism: (cores: 0, efficiency: 0),
                    stats: (min: .zero, max: .zero, average: .zero,
                            median: .zero, p95: .zero, dispersion: .zero),
                    targets: 0,
                    time: (cpu: .zero, wall: .zero),
                    execution: (start: 0, end: 0))
  }
}
