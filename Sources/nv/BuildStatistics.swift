// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

internal struct BuildStatistics {
  internal typealias Target = (target: String, duration: Duration)

  let slowest: InlineArray<5, Target?>
  let parallelism: (peak: Int, occupancy: Double, efficiency: Double)
  let stats: (min: Duration, max: Duration, average: Duration, median: Duration, p95: Duration, dispersion: Duration)
  let targets: Int
  let time: (cpu: Duration, wall: Duration, serial: Duration)
  let execution: (start: TimeInterval, end: TimeInterval)
}

extension BuildStatistics {
  static let zero = BuildStatistics(slowest: InlineArray(repeating: nil),
                                    parallelism: (peak: 0, occupancy: 0.0, efficiency: 0.0),
                                    stats: (min: .zero, max: .zero,
                                            average: .zero, median: .zero,
                                            p95: .zero, dispersion: .zero),
                                    targets: 0,
                                    time: (cpu: .zero, wall: .zero, serial: .zero),
                                    execution: (start: 0, end: 0))
}
