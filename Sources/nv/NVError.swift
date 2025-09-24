// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import Foundation

internal enum NVError: Error {
  case IO
  case Parser
  case Encoder
  case UnsupportedVersion(Int)
}

extension NVError: CustomStringConvertible {
  var description: String {
    switch self {
    case .IO:
      return "I/O error"
    case .Parser:
      return "Parser error"
    case .Encoder:
      return "Encoder error"
    case .UnsupportedVersion(let version):
      return "Unsupported log version: \(version)"
    }
  }
}
