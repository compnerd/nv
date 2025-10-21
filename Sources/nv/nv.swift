// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser
import Foundation

@main
internal struct NV: ParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(commandName: "nv",
                         abstract: "Ninja build log analyzer",
                         subcommands: [
                           AnalyzeCommand.self,
                           StatsCommand.self,
                           VisualizeCommand.self,
                         ],
                         defaultSubcommand: AnalyzeCommand.self)
  }

  @Option(name: [.customLong("logfile", withSingleDash: true)],
          help: "Path to the .ninja_log file")
  var logfile: URL = URL(fileURLWithPath: ".ninja_log")
}
