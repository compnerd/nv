// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser

internal struct AnalyzeCommand: ParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(commandName: "analyze",
                         abstract: "Analyze Ninja build logs (default command)")
  }

  @OptionGroup
  var command: NV

  @Flag(name: [.customLong("sort", withSingleDash: true), .short],
        help: "Sort output by duration")
  var sort: Bool = false

  @Option(name: [.short, .long],
          help: "Output format: console, json or csv")
  var format: OutputFormat = .console

  @Option(name: [.short, .long],
          help: "Output file path (use '-' for stdout)")
  var output: String = "-"

  public func run() throws {
    let file = try NinjaLogParser.load(at: command.logfile)
    let entries = file.entries.sorted(by: { sort ? $0.duration > $1.duration : true })
    try format.output(entries: entries, to: output)
  }
}
