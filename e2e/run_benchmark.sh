#!/usr/bin/env bash
set -euo pipefail

target_org=""
iterations="200"
scenario="all"

usage() {
    cat <<'EOF'
Usage: e2e/run_benchmark.sh [options]

Options:
  -o, --target-org ORG   Salesforce org alias/username. Uses the CLI default org when omitted.
  -i, --iterations N     Iteration count. Default: 200
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

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
artifacts_dir="$script_dir/.artifacts/apex-di"
run_id="$(date -u +"%Y%m%dT%H%M%SZ")"
run_dir="$artifacts_dir/$run_id"
metadata_file="$run_dir/run.meta.txt"

scenarios=(
    hot_lookup
    provider_width
    cold_first_resolution
    dependency_depth
    module_fanout
    compiled_vs_lazy
    scope_context
    prototype_resolution
    provider_replacement
    cycle_validation
    global_lookup
    module_import_depth
    ambiguity_validation
    cold_split
    cold_construct_split
)

selected_scripts=()
if [[ "$scenario" == "all" ]]; then
    for scenario_name in "${scenarios[@]}"; do
        selected_scripts+=("$script_dir/benchmarks/$scenario_name.apex")
    done
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
    echo "scenario=$scenario"
    echo "scripts=${selected_scripts[*]}"
    echo "sf_bin=$sf_bin"
} > "$metadata_file"

echo "Writing benchmark artifacts to $run_dir"

for script_path in "${selected_scripts[@]}"; do
    scenario_name="$(basename "$script_path" .apex)"
    expanded_script="$tmp_dir/$scenario_name.apex"
    apex_log="$tmp_dir/$scenario_name.apex.log"

    sed "s/__ITERATIONS__/$iterations/g" "$script_path" > "$expanded_script"
    sf_args=(apex run --file "$expanded_script")
    if [[ -n "$target_org" ]]; then
        sf_args+=(--target-org "$target_org")
    fi

    if ! "$sf_bin" "${sf_args[@]}" 2>&1 | tee "$apex_log"; then
        cp "$expanded_script" "$run_dir/failure.$scenario_name.apex"
        cp "$apex_log" "$run_dir/failure.$scenario_name.apex.log"
        echo "Scenario failed. Diagnostic artifacts were written to $run_dir" >&2
        exit 1
    fi

    marker_count="$(grep -E -c "\\|USER_DEBUG\\|.*DI_BENCHMARK_JSON " "$apex_log" || true)"
    if [[ "$marker_count" == "0" ]]; then
        cp "$expanded_script" "$run_dir/failure.$scenario_name.apex"
        cp "$apex_log" "$run_dir/failure.$scenario_name.apex.log"
        echo "Benchmark JSON marker was not found. Diagnostic artifacts were written to $run_dir" >&2
        exit 1
    fi

    grep -E "\\|USER_DEBUG\\|.*DI_BENCHMARK_JSON " "$apex_log" | while IFS= read -r line; do
        key="$(printf '%s\n' "$line" | sed -E 's/^.*DI_BENCHMARK_JSON ([^ ]+) .*/\1/')"
        json="$(printf '%s\n' "$line" | sed -E 's/^.*DI_BENCHMARK_JSON [^ ]+ //')"
        printf '%s\t%s\n' "$key" "$json" >> "$results_tsv"
        echo "Benchmark JSON: $key"
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
    const separator = line.indexOf('\t');
    if (separator < 0) {
        throw new Error(`Malformed benchmark result row: ${line}`);
    }
    return {
        key: line.slice(0, separator),
        report: JSON.parse(line.slice(separator + 1)),
    };
});

const rows = reports.flatMap(({ report }) =>
    (report.metrics || []).map((metric) => ({
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

const formatNumber = (value, digits = 3) => (value == null ? 'n/a' : Number(value).toFixed(digits));
let markdown = '# Apex DI Benchmark Results\n\n';
markdown += `Artifact directory: \`${runId}\`\n\n`;
markdown += 'CPU values are Apex governor CPU deltas from one run. Treat them as relative signals, not lab-grade absolutes.\n\n';
markdown += '| Metric | Iterations | CPU ms | ms/op | Heap bytes | Checksum |\n';
markdown += '| --- | ---: | ---: | ---: | ---: | ---: |\n';
for (const row of rows) {
    markdown += `| ${row.metric} | ${row.iterations} | ${row.cpuMs} | ${formatNumber(row.msPerIteration)} | ${row.heapBytes} | ${row.checksum} |\n`;
}

fs.writeFileSync(path.join(runDir, 'results.json'), JSON.stringify({ artifactDirectory: runId, reports, rows }, null, 2) + '\n');
fs.writeFileSync(path.join(runDir, 'results.md'), markdown);
console.log(`Results: ${path.join(runDir, 'results.json')}`);
console.log(`Report: ${path.join(runDir, 'results.md')}`);
NODE
