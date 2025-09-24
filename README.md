# nv - Ninja Build Analyzer and Visualizer

`nv` is a command-line utility written in Swift that helps analyze Ninja build logs. It parses `.ninja_log` files to extract build timing information and provides detailed textual output of build durations.

## Features

- **Log Parsing**: Supports Ninja log format version 6
- **Build Analysis**: Extracts start/end times and durations for each build target
- **Sorting**: Option to sort output by build duration (longest first)
- **Console Output**: Displays build targets with their execution times

## Usage

### Basic Analysis

Analyze a `.ninja_log` file (defaults to `.ninja_log` in current directory):

```bash
nv
```

Specify a custom log file:

```bash
nv analyze -logfile .ninja_log
```

### Sort by Duration

Sort targets by build time (longest first):

```bash
nv -s
```

### Build Statistics

Generate comprehensive build statistics and metrics:

```bash
# Detailed statistics summary (default)
nv stats

# Concise build overview
nv stats -f brief
```

The statistics include:
- **Basic metrics**: Total/average/median build times, min/max durations
- **Statistical analysis**: Standard deviation, 95th percentile
- **Parallelization analysis**: Estimated cores used, parallelization efficiency
- **Build efficiency**: CPU utilization, wall time vs CPU time
- **Performance insights**: Fastest/slowest targets, potential bottlenecks
- **Dependency analysis**: Critical path identification (inferred from timing)
