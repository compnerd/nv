// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

extension String {
  @inline(__always)
  init(_ span: borrowing Span<UTF8.CodeUnit>) {
    self = span.withUnsafeBufferPointer { String(decoding: $0, as: UTF8.self) }
  }
}
