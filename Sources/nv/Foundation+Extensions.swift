// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser
import Foundation

extension URL: @retroactive ExpressibleByArgument {
  public init?(argument: String) {
    self = URL(fileURLWithPath: argument)
  }
}
