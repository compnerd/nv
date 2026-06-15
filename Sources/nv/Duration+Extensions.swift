// Copyright © 2026 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

extension Duration {
  @inline(__always)
  internal var seconds: Double {
    Double(components.seconds) + Double(components.attoseconds) * 1e-18
  }
}
