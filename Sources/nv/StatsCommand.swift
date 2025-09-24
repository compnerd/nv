// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser

internal struct StatsCommand: ParsableCommand {
  static var configuration: CommandConfiguration {
      CommandConfiguration(commandName: "stats",
                           abstract: "Show build statistics and metrics")
  }

  @OptionGroup
  var command: NV

  @Option(name: [.short, .long],
          help: "Output format: detailed, brief")
  var format: StatisticsFormat = .detailed

  public func run() throws {
    let file = try NinjaLogParser.load(at: command.logfile)
    let entries = file.entries
    try format.output(statistics: entries.statistics)
  }
}
