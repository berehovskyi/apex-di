# Apex DI E2E Benchmarks

This directory contains the commit-ready, apex-di-only benchmark suite. Nothing
under `e2e/` is part of the published package.

## Layout

```text
e2e/
  benchmarks/             # apex-di execute-anonymous scenarios
  main/classes/           # DiBenchmarkCanonical only
  main/cachePartitions/   # portable zero-capacity benchmark partition
  .artifacts/apex-di/     # ignored local results
  run_benchmark.sh
```

## Scenarios

| Scenario                    | Measures                                                       |
| --------------------------- | -------------------------------------------------------------- |
| `hot_lookup`                | Repeated lookup in a warmed four-provider graph                |
| `provider_width`            | Warmed lookup across 25, 100, and 575 providers                |
| `cold_first_resolution`     | Dynamic graph construction, registration, and first resolution |
| `dependency_depth`          | Nested dependency resolution                                   |
| `module_fanout`             | Lookup across many imported modules                            |
| `compiled_vs_lazy`          | Compiled and incremental warmed lookup                         |
| `scope_context`             | Shared scoped lifetime lookup                                  |
| `prototype_resolution`      | Prototype construction                                         |
| `provider_replacement`      | Cold provider replacement                                      |
| `cycle_validation`          | Circular module validation failure                             |
| `global_lookup`             | Implicit global fallback lookup                                |
| `module_import_depth`       | Deep import and re-export traversal                            |
| `ambiguity_validation`      | Ambiguous visible-provider validation                          |
| `cold_split`                | Cold construct, registration, and first-get phases             |
| `cold_construct_split`      | Token, builder, provider, and staging costs                    |
| `dynamic_module_cold`       | Dynamic-module cold totals at 25, 100, and 575 providers       |
| `class_module_cold`         | Class-module cold totals at 25, 100, and 575 providers         |
| `dynamic_module_cold_split` | Dynamic construct, registration, and first-get phases          |
| `class_module_cold_split`   | Class construct, registration, and first-get phases            |
| `context_cache_hypothesis`  | Multi-module bootstrap versus serialized-spec hydration        |

The two cold split scenarios are diagnostics that attribute apex-di cost to
individual construction phases.

`context_cache_hypothesis` is also diagnostic rather than a library comparison.
It models 20 class modules with 10 providers each and reports normal bootstrap,
spec serialization/deserialization, an optimistic prevalidated-hydration lower
bound, hydration through the current safe registration path, and the equivalent
operations using the `local.DiBenchmark` Platform Cache partition. The committed
partition allocates 1 MB of org-cache capacity.

## Deploy

The runner never deploys metadata. Deploy the package and benchmark class
explicitly to an existing org:

```bash
sf project deploy start \
  --source-dir sfdx-source/apex-di \
  --source-dir e2e/main \
  --target-org YOUR_ORG_ALIAS \
  --test-level NoTestRun \
  --wait 60
```

## Run

The target org is optional. Omitting it uses the Salesforce CLI default org.

```bash
bash e2e/run_benchmark.sh --scenario all --iterations 200
bash e2e/run_benchmark.sh --scenario provider_width --iterations 200
bash e2e/run_benchmark.sh --target-org YOUR_ORG_ALIAS --scenario cold_split --iterations 20
bash e2e/run_benchmark.sh --scenario dynamic_module_cold --iterations 10 --samples 5
bash e2e/run_benchmark.sh --scenario class_module_cold --iterations 10 --samples 5
bash e2e/run_benchmark.sh --scenario context_cache_hypothesis --iterations 10 --samples 5
```

## Artifacts

Each run writes only three normal files under ignored
`e2e/.artifacts/apex-di/<run-id>/`:

- `run.meta.txt`
- `results.json`
- `results.md`

Failure source and logs are retained only when a scenario fails. Multi-sample
runs execute each scenario in separate Apex transactions and report medians,
minimums, and maximums. CPU and heap measurements are transaction-local
governor deltas and should be treated as relative signals rather than universal
timings.
