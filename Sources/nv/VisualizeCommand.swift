// Copyright © 2025 Saleem Abdulrasool <compnerd@compnerd.org>. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser
import Foundation
@preconcurrency
import Mustache
import HeapModule

private struct BuildTask {
  public let id: Int
  public let target: String
  public let lane: Int
  public let start: Double
  public let end: Double
}

private struct BuildLane {
  public let id: Int
  public var description: String
}

private struct Event {
  public enum Kind {
    case start
    case end
  }

  public let id: Int
  public let target: String
  public let kind: Kind
  public let timestamp: Double
}

extension Event: Comparable {
  public static func < (_ lhs: Event, _ rhs: Event) -> Bool {
    if lhs.timestamp == rhs.timestamp {
      return switch (lhs.kind, rhs.kind) {
      case (.end, .start): false
      case (.start, .end): true
      case (.start, .start), (.end, .end): false
      }
    }
    return lhs.timestamp < rhs.timestamp
  }
}

extension Collection where Element: NinjaLogEntry {
  fileprivate var tasks: ([BuildTask], [BuildLane]) {
    var events: [Event] = []
    events.reserveCapacity(self.count * 2)

    for entry in self.enumerated() {
      events.append(Event(id: entry.offset, target: entry.element.target,
                          kind: .start, timestamp: entry.element.start))
      events.append(Event(id: entry.offset, target: entry.element.target,
                          kind: .end, timestamp: entry.element.end))
    }
    events.sort()

    var lanes: Heap<Int> = Heap()
    var count = -1

    var active: [Int:(lane: Int, start: Double)] = [:]
    active.reserveCapacity(self.count)

    var tasks: [BuildTask] = []
    tasks.reserveCapacity(self.count)

    for event in events {
      switch event.kind {
      case .start:
        if lanes.min == nil { count += 1 }
        active[event.id] = (lanes.popMin() ?? count, event.timestamp)

      case .end:
        guard let info = active.removeValue(forKey: event.id) else {
          fatalError("Task (\(event.id)) ended without starting")
        }
        lanes.insert(info.lane)

        tasks.append(BuildTask(id: event.id,
                               target: event.target,
                               lane: info.lane,
                               start: info.start,
                               end: event.timestamp))
      }
    }

    return (tasks.sorted(by: { $0.id < $1.id }), (0 ... count).map {
      BuildLane(id: $0, description: "Lane \($0 + 1)")
    })
  }
}

internal struct VisualizeCommand: ParsableCommand {
  static var configuration: CommandConfiguration {
      CommandConfiguration(commandName: "visualize",
                           abstract: "Visualize build statistics and metrics")
  }

  @OptionGroup
  var command: NV

  private func template() throws -> Mustache {
    guard let url = Bundle.module.url(forResource: "visualization",
                                      withExtension: "html") else {
      throw CocoaError(.fileNoSuchFile, userInfo: [
        NSLocalizedDescriptionKey: "Could not locate visualization template"
      ])
    }
    return try Mustache(String(contentsOf: url, encoding: .utf8))
  }

  public func run() throws {
    let file = try NinjaLogParser.load(at: command.logfile)
    let entries = file.entries

    let (tasks, lanes) = entries.tasks

    let statistics = entries.statistics
    let temporary = FileManager.default.temporaryDirectory
                                    .appending(path: UUID().uuidString,
                                               directoryHint: .notDirectory)
                                    .appendingPathExtension("htm")
    let kTimeStyle =
        Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes, .seconds],
                                  width: .abbreviated)
    try template().render(object: [
      "targets": entries.count,
      "wall_time": statistics.time.wall.formatted(kTimeStyle),
      "cpu_time": statistics.time.cpu.formatted(kTimeStyle),
      "core_count": statistics.parallelism.cores,
      "efficiency": String(format: "%.2f%%",
                           statistics.parallelism.efficiency * 100.0),
      "average_time": statistics.stats.average.formatted(kTimeStyle),
      "groups": lanes.enumerated().map { index, lane in
        ["id": lane.id, "label": lane.description, "last": index == lanes.count - 1]
      },
      "tasks": tasks.enumerated().map { index, task in
        [
          "id": task.id,
          "title": task.target,
          "content": URL(fileURLWithPath: task.target).lastPathComponent,
          "start": task.start * 1000,
          "end": task.end * 1000,
          "group": task.lane,
          "last": index == tasks.count - 1,
          "target": task.target,
          "duration": task.end - task.start,
        ]
      },
      "bottlenecks": statistics.outliers.slowest.enumerated().map { index, task in
        [
          "rank": index + 1,
          "target": URL(fileURLWithPath: task.target).lastPathComponent,
          "full_target": task.target,
          "duration": task.duration.formatted(kTimeStyle),
        ]
      },
      "min_time": statistics.execution.start * 1000,
      "max_time": statistics.execution.end * 1000,
    ]).data(using: .utf8)?.write(to: temporary, options: .atomic)

#if os(macOS)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [temporary.path]
    try process.run()
#elseif os(Windows)
    guard let SystemRoot = ProcessInfo.processInfo.environment["SystemRoot"] else {
      throw CocoaError(.fileNoSuchFile, userInfo: [
        NSLocalizedDescriptionKey: "Could not locate SystemRoot environment variable"
      ])
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: SystemRoot)
        .appending(path: "Sysnative", directoryHint: .isDirectory)
        .appending(path: "rundll32.exe", directoryHint: .notDirectory)
    process.arguments = ["shell32.dll,ShellExec_RunDLL", temporary.absoluteString]
    try process.run()
#else
    print("Generated visualization at: \(temporary.path)")
#endif
  }
}
