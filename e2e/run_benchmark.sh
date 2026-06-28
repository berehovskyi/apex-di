#!/usr/bin/env bash
set -euo pipefail

target_org=""
iterations="200"
samples="1"
scenario="all"

usage() {
    cat <<'EOF'
Usage: e2e/run_benchmark.sh [options]

Options:
  -o, --target-org ORG   Salesforce org alias/username. Uses the CLI default org when omitted.
  -i, --iterations N     Iteration count. Default: 200
  -n, --samples N        Separate Apex transactions per scenario. Default: 1
  -s, --scenario NAME    Scenario name or all. Default: all
  -h, --help             Show this help

Environment:
  SF_BIN                 Salesforce CLI executable. Default: sf.cmd if found, else sf
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--target-org)
            target_org="$2"
            shift 2
            ;;
        -i|--iterations)
            iterations="$2"
            shift 2
            ;;
        -n|--samples)
            samples="$2"
            shift 2
            ;;
        -s|--scenario)
            scenario="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if ! [[ "$samples" =~ ^[1-9][0-9]*$ ]]; then
    echo "Samples must be a positive integer." >&2
    exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
artifacts_dir="$script_dir/.artifacts/apex-di"
run_id="$(date -u +"%Y%m%dT%H%M%SZ")"
run_dir="$artifacts_dir/$run_id"
metadata_file="$run_dir/run.meta.txt"

selected_scripts=()
if [[ "$scenario" == "all" ]]; then
    shopt -s nullglob
    selected_scripts=("$script_dir"/benchmarks/*.apex)
    shopt -u nullglob
    if [[ ${#selected_scripts[@]} -eq 0 ]]; then
        echo "No benchmark scenarios found in $script_dir/benchmarks." >&2
        exit 2
    fi
else
    script_path="$script_dir/benchmarks/$scenario.apex"
    if [[ ! -f "$script_path" ]]; then
        echo "Unknown scenario: $scenario" >&2
        exit 2
    fi
    selected_scripts+=("$script_path")
fi

sf_bin="${SF_BIN:-}"
if [[ -z "$sf_bin" ]]; then
    if command -v sf.cmd >/dev/null 2>&1; then
        sf_bin="sf.cmd"
    else
        sf_bin="sf"
    fi
fi

if ! command -v node >/dev/null 2>&1; then
    echo "node is required to consolidate benchmark artifacts." >&2
    exit 2
fi

cd "$repo_root"
mkdir -p "$run_dir"
tmp_dir="$(mktemp -d)"
results_tsv="$tmp_dir/results.tsv"

cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

{
    echo "run_id=$run_id"
    echo "suite=apex-di"
    echo "target_org=${target_org:-<sf default>}"
    echo "iterations=$iterations"
    echo "samples=$samples"
    echo "scenario=$scenario"
    echo "scripts=${selected_scripts[*]}"
    echo "sf_bin=$sf_bin"
} > "$metadata_file"

echo "Writing benchmark artifacts to $run_dir"

for script_path in "${selected_scripts[@]}"; do
    scenario_name="$(basename "$script_path" .apex)"
    expanded_script="$tmp_dir/$scenario_name.apex"
    sed "s/__ITERATIONS__/$iterations/g" "$script_path" > "$expanded_script"

    for ((sample = 1; sample <= samples; sample++)); do
        apex_log="$tmp_dir/$scenario_name.$sample.apex.log"
        sf_args=(apex run --file "$expanded_script")
        if [[ -n "$target_org" ]]; then
            sf_args+=(--target-org "$target_org")
        fi

        if ! "$sf_bin" "${sf_args[@]}" 2>&1 | tee "$apex_log"; then
            cp "$expanded_script" "$run_dir/failure.$scenario_name.$sample.apex"
            cp "$apex_log" "$run_dir/failure.$scenario_name.$sample.apex.log"
            echo "Scenario failed. Diagnostic artifacts were written to $run_dir" >&2
            exit 1
        fi

        marker_count="$(grep -E -c "\\|USER_DEBUG\\|.*DI_BENCHMARK_JSON " "$apex_log" || true)"
        if [[ "$marker_count" == "0" ]]; then
            cp "$expanded_script" "$run_dir/failure.$scenario_name.$sample.apex"
            cp "$apex_log" "$run_dir/failure.$scenario_name.$sample.apex.log"
            echo "Benchmark JSON marker was not found. Diagnostic artifacts were written to $run_dir" >&2
            exit 1
        fi

        grep -E "\\|USER_DEBUG\\|.*DI_BENCHMARK_JSON " "$apex_log" | while IFS= read -r line; do
            key="$(printf '%s\n' "$line" | sed -E 's/^.*DI_BENCHMARK_JSON ([^ ]+) .*/\1/')"
            json="$(printf '%s\n' "$line" | sed -E 's/^.*DI_BENCHMARK_JSON [^ ]+ //')"
            printf '%s\t%s\t%s\n' "$sample" "$key" "$json" >> "$results_tsv"
            echo "Benchmark JSON: $key (sample $sample/$samples)"
        done
    done
done

node - "$run_dir" "$results_tsv" <<'NODE'
const fs = require('fs');
const path = require('path');

const runDir = process.argv[2];
const resultsTsv = process.argv[3];
const runId = path.basename(runDir);
const lines = fs.readFileSync(resultsTsv, 'utf8').split(/\r?\n/).filter(Boolean);

if (lines.length === 0) {
    throw new Error('No benchmark result rows were captured.');
}

const reports = lines.map((line) => {
    const firstSeparator = line.indexOf('\t');
    const secondSeparator = line.indexOf('\t', firstSeparator + 1);
    if (firstSeparator < 0 || secondSeparator < 0) {
        throw new Error(`Malformed benchmark result row: ${line}`);
    }
    return {
        sample: Number(line.slice(0, firstSeparator)),
        key: line.slice(firstSeparator + 1, secondSeparator),
        report: JSON.parse(line.slice(secondSeparator + 1)),
    };
});

const rows = reports.flatMap(({ sample, report }) =>
    (report.metrics || []).map((metric) => ({
        sample,
        scenario: report.scenario,
        metric: metric.name,
        iterations: metric.iterations,
        cpuMs: metric.cpuMs,
        msPerIteration: metric.iterations ? metric.cpuMs / metric.iterations : null,
        heapBytes: metric.heapBytes,
        checksum: metric.checksum,
        moduleCount: report.moduleCount,
        providerCount: report.providerCount,
    })),
).sort((left, right) => left.metric.localeCompare(right.metric));

const median = (values) => {
    const sorted = [...values].sort((left, right) => left - right);
    const middle = Math.floor(sorted.length / 2);
    return sorted.length % 2 === 0 ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle];
};

const rowsByMetric = new Map();
for (const row of rows) {
    if (!rowsByMetric.has(row.metric)) {
        rowsByMetric.set(row.metric, []);
    }
    rowsByMetric.get(row.metric).push(row);
}

const medians = [...rowsByMetric.entries()].sort().map(([metric, metricRows]) => {
    const msValues = metricRows.map((row) => row.msPerIteration);
    const checksums = [...new Set(metricRows.map((row) => String(row.checksum)))];
    return {
        metric,
        samples: metricRows.length,
        iterations: metricRows[0].iterations,
        medianCpuMs: median(metricRows.map((row) => row.cpuMs)),
        medianMsPerIteration: median(msValues),
        minMsPerIteration: Math.min(...msValues),
        maxMsPerIteration: Math.max(...msValues),
        medianHeapBytes: median(metricRows.map((row) => row.heapBytes)),
        checksum: checksums.length === 1 ? checksums[0] : checksums.join('/'),
    };
});

const formatNumber = (value, digits = 3) => (value == null ? 'n/a' : Number(value).toFixed(digits));
let markdown = '# Apex DI Benchmark Results\n\n';
markdown += `Artifact directory: \`${runId}\`\n\n`;
markdown += 'Values are medians across separate Apex transactions. Treat governor deltas as relative signals, not lab-grade absolutes.\n\n';
markdown += '| Metric | Samples | Iterations | Median CPU ms | Median ms/op | Min | Max | Median heap | Checksum |\n';
markdown += '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n';
for (const result of medians) {
    markdown += `| ${result.metric} | ${result.samples} | ${result.iterations} | ${formatNumber(result.medianCpuMs, 1)} | ${formatNumber(result.medianMsPerIteration)} | ${formatNumber(result.minMsPerIteration)} | ${formatNumber(result.maxMsPerIteration)} | ${formatNumber(result.medianHeapBytes, 0)} | ${result.checksum} |\n`;
}

fs.writeFileSync(
    path.join(runDir, 'results.json'),
    JSON.stringify({ artifactDirectory: runId, reports, medians, rows }, null, 2) + '\n',
);
fs.writeFileSync(path.join(runDir, 'results.md'), markdown);
console.log(`Results: ${path.join(runDir, 'results.json')}`);
console.log(`Report: ${path.join(runDir, 'results.md')}`);
NODE
