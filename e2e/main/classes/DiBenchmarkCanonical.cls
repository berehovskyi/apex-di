public without sharing class DiBenchmarkCanonical {
    private static final Integer DEFAULT_ITERATIONS = 200;
    private static final Integer HOT_PROVIDER_COUNT = 4;
    private static final Integer PROVIDER_WIDTH_MEDIUM = 25;
    private static final Integer PROVIDER_WIDTH_LARGE = 575;
    private static final Integer MODULE_FANOUT_COUNT = 25;
    private static final Integer MODULE_FANOUT_PROVIDER_COUNT = 5;
    private static final Integer DEPENDENCY_DEPTH = 10;
    private static final Integer MODULE_IMPORT_DEPTH = 10;
    private static final Integer MAX_COLD_ITERATIONS = 20;
    private static final Integer MAX_COLD_PROFILE_ITERATIONS = 10;
    private static final Integer MAX_VALIDATION_ITERATIONS = 25;
    private static final String LIBRARY = 'apex-di';

    public class BenchmarkReport {
        public String library;
        public String scenario;
        public Integer requestedIterations;
        public Integer moduleCount;
        public Integer providerCount;
        public String note = 'CPU and heap are transaction-local governor deltas. Treat as relative baselines.';
        public List<BenchmarkMetric> metrics = new List<BenchmarkMetric>();

        public BenchmarkReport(final String scenario, final Integer requestedIterations) {
            library = DiBenchmarkCanonical.LIBRARY;
            this.scenario = scenario;
            this.requestedIterations = requestedIterations;
        }
    }

    public class BenchmarkMetric {
        public String name;
        public Integer iterations;
        public Integer cpuMs;
        public Integer heapBytes;
        public String checksum;

        public BenchmarkMetric(
            final String name,
            final Integer iterations,
            final Integer cpuMs,
            final Integer heapBytes,
            final String checksum
        ) {
            this.name = name;
            this.iterations = iterations;
            this.cpuMs = cpuMs;
            this.heapBytes = heapBytes;
            this.checksum = checksum;
        }
    }

    private class Sample {
        private final Integer cpuMs = Limits.getCpuTime();
        private final Integer heapBytes = Limits.getHeapSize();
    }

    public static String run(final String scenario, final Integer requestedIterations) {
        Integer iterations = normalizeIterations(requestedIterations);
        BenchmarkReport report = new BenchmarkReport(scenario, iterations);

        if (scenario == 'hot_lookup') {
            report.moduleCount = 1;
            report.providerCount = HOT_PROVIDER_COUNT;
            report.metrics.add(measureHotLookup(HOT_PROVIDER_COUNT, iterations, 'hot_lookup'));
        } else if (scenario == 'provider_width') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.add(measureHotLookup(PROVIDER_WIDTH_MEDIUM, iterations, 'provider_width_25'));
            report.metrics.add(measureHotLookup(100, iterations, 'provider_width_100'));
            report.metrics.add(measureHotLookup(PROVIDER_WIDTH_LARGE, iterations, 'provider_width_575'));
        } else if (scenario == 'cold_first_resolution') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.add(measureColdFirstResolution(cap(iterations, MAX_COLD_ITERATIONS)));
        } else if (scenario == 'cold_split') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.addAll(measureColdSplit(cap(iterations, MAX_COLD_ITERATIONS)));
        } else if (scenario == 'cold_construct_split') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.addAll(measureColdConstructSplit(cap(iterations, MAX_COLD_ITERATIONS)));
        } else if (scenario == 'dynamic_module_cold') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.addAll(measureDynamicModuleCold(cap(iterations, MAX_COLD_PROFILE_ITERATIONS)));
        } else if (scenario == 'class_module_cold') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.addAll(measureClassModuleCold(cap(iterations, MAX_COLD_PROFILE_ITERATIONS)));
        } else if (scenario == 'dynamic_module_cold_split') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.addAll(measureDynamicModuleColdSplitProfile(cap(iterations, MAX_COLD_PROFILE_ITERATIONS)));
        } else if (scenario == 'class_module_cold_split') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.addAll(measureClassModuleColdSplitProfile(cap(iterations, MAX_COLD_PROFILE_ITERATIONS)));
        } else if (scenario == 'dependency_depth') {
            report.moduleCount = 1;
            report.providerCount = DEPENDENCY_DEPTH;
            report.metrics.add(measureDependencyDepth(iterations));
        } else if (scenario == 'module_fanout') {
            report.moduleCount = MODULE_FANOUT_COUNT + 1;
            report.providerCount = MODULE_FANOUT_COUNT * MODULE_FANOUT_PROVIDER_COUNT;
            report.metrics.add(measureModuleFanout(iterations));
        } else if (scenario == 'compiled_vs_lazy') {
            report.moduleCount = 1;
            report.providerCount = PROVIDER_WIDTH_LARGE;
            report.metrics.add(measureHotLookup(PROVIDER_WIDTH_LARGE, iterations, 'compiled_vs_lazy_lazy'));
            report.metrics.add(measureCompiledHotLookup(PROVIDER_WIDTH_LARGE, iterations));
        } else if (scenario == 'scope_context') {
            report.moduleCount = 1;
            report.providerCount = 1;
            report.metrics.add(measureScopedContext(iterations));
        } else if (scenario == 'prototype_resolution') {
            report.moduleCount = 1;
            report.providerCount = 1;
            report.metrics.add(measurePrototypeResolution(iterations));
        } else if (scenario == 'provider_replacement') {
            report.moduleCount = 1;
            report.providerCount = 1;
            report.metrics.add(measureProviderReplacement(cap(iterations, MAX_COLD_ITERATIONS)));
        } else if (scenario == 'cycle_validation') {
            report.moduleCount = 2;
            report.providerCount = 0;
            report.metrics.add(measureCycleValidation(cap(iterations, MAX_VALIDATION_ITERATIONS)));
        } else if (scenario == 'global_lookup') {
            report.moduleCount = 2;
            report.providerCount = 1;
            report.metrics.add(measureGlobalLookup(iterations));
        } else if (scenario == 'module_import_depth') {
            report.moduleCount = MODULE_IMPORT_DEPTH;
            report.providerCount = 1;
            report.metrics.add(measureModuleImportDepth(iterations));
        } else if (scenario == 'ambiguity_validation') {
            report.moduleCount = 3;
            report.providerCount = 2;
            report.metrics.add(measureAmbiguityValidation(cap(iterations, MAX_VALIDATION_ITERATIONS)));
        } else {
            report.note = 'Unknown scenario: ' + scenario;
        }

        return JSON.serialize(report);
    }

    private static BenchmarkMetric measureHotLookup(
        final Integer providerCount,
        final Integer iterations,
        final String metricName
    ) {
        Di.ApplicationContext context = newContext();
        Di.ModuleRef app = buildWidthGraph(context, providerCount);
        app.get('order');

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) app.get('order');
        }
        return finish(metricName, iterations, sample, checksum);
    }

    private static BenchmarkMetric measureCompiledHotLookup(final Integer providerCount, final Integer iterations) {
        Di.ApplicationContext context = newContext();
        Di.ModuleRef app = buildWidthGraph(context, providerCount);
        context.compile();
        app.get('order');

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) app.get('order');
        }
        return finish('compiled_vs_lazy_compiled', iterations, sample, checksum);
    }

    private static BenchmarkMetric measureColdFirstResolution(final Integer iterations) {
        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) buildWidthGraph(newContext(), PROVIDER_WIDTH_LARGE).get('order');
        }
        return finish('cold_first_resolution_575', iterations, sample, checksum);
    }

    private static List<BenchmarkMetric> measureColdSplit(final Integer iterations) {
        Integer constructCpu = 0;
        Integer registerCpu = 0;
        Integer firstGetCpu = 0;
        Integer constructHeap = 0;
        Integer registerHeap = 0;
        Integer checksum = 0;
        for (Integer i = 0; i < iterations; i++) {
            Integer t0 = Limits.getCpuTime();
            Integer h0 = Limits.getHeapSize();
            Di.ApplicationContext context = newContext();
            Di.DynamicModule module = new Di.DynamicModule('ApexColdSplit');
            module.addProvider(module.provide('gateway').useValue(7));
            module.addProvider(module.provide('logger').useValue(3));
            module.addProvider(module.provide('order').useFactory(new OrderFactory()));
            for (Integer j = 0; j < PROVIDER_WIDTH_LARGE - 3; j++) {
                module.addProvider(module.provide('filler_' + j).useValue(0));
            }
            Integer t1 = Limits.getCpuTime();
            Integer h1 = Limits.getHeapSize();
            Di.ModuleRef ref = context.addModule(module);
            Integer t2 = Limits.getCpuTime();
            Integer h2 = Limits.getHeapSize();
            checksum += (Integer) ref.get('order');
            Integer t3 = Limits.getCpuTime();

            constructCpu += t1 - t0;
            registerCpu += t2 - t1;
            firstGetCpu += t3 - t2;
            constructHeap += h1 - h0;
            registerHeap += h2 - h1;
        }
        return new List<BenchmarkMetric>{
            new BenchmarkMetric(
                'cold_split_construct',
                iterations,
                constructCpu,
                constructHeap,
                String.valueOf(checksum)
            ),
            new BenchmarkMetric('cold_split_register', iterations, registerCpu, registerHeap, ''),
            new BenchmarkMetric('cold_split_first_get', iterations, firstGetCpu, 0, '')
        };
    }

    private static List<BenchmarkMetric> measureColdConstructSplit(final Integer iterations) {
        Integer width = PROVIDER_WIDTH_LARGE - 3;
        Integer tokenCpu = 0;
        Integer provideCpu = 0;
        Integer useValueCpu = 0;
        Integer addProviderCpu = 0;
        Long sink = 0;
        for (Integer i = 0; i < iterations; i++) {
            Integer a0 = Limits.getCpuTime();
            for (Integer j = 0; j < width; j++) {
                sink += ('filler_' + j).length();
            }
            Integer a1 = Limits.getCpuTime();

            Di.DynamicModule mb = new Di.DynamicModule('ConstructSplitB');
            Integer b0 = Limits.getCpuTime();
            for (Integer j = 0; j < width; j++) {
                mb.provide('filler_' + j);
            }
            Integer b1 = Limits.getCpuTime();

            Di.DynamicModule mc = new Di.DynamicModule('ConstructSplitC');
            Integer c0 = Limits.getCpuTime();
            for (Integer j = 0; j < width; j++) {
                mc.provide('filler_' + j).useValue(0);
            }
            Integer c1 = Limits.getCpuTime();

            Di.DynamicModule md = new Di.DynamicModule('ConstructSplitD');
            Integer d0 = Limits.getCpuTime();
            for (Integer j = 0; j < width; j++) {
                md.addProvider(md.provide('filler_' + j).useValue(0));
            }
            Integer d1 = Limits.getCpuTime();

            tokenCpu += a1 - a0;
            provideCpu += b1 - b0;
            useValueCpu += c1 - c0;
            addProviderCpu += d1 - d0;
        }
        return new List<BenchmarkMetric>{
            new BenchmarkMetric('construct_a_token_concat', iterations, tokenCpu, 0, String.valueOf(sink)),
            new BenchmarkMetric('construct_b_provide', iterations, provideCpu, 0, ''),
            new BenchmarkMetric('construct_c_provide_usevalue', iterations, useValueCpu, 0, ''),
            new BenchmarkMetric('construct_d_full_addprovider', iterations, addProviderCpu, 0, '')
        };
    }

    private static List<BenchmarkMetric> measureDynamicModuleCold(final Integer iterations) {
        List<BenchmarkMetric> metrics = new List<BenchmarkMetric>();
        for (Integer providerCount : new List<Integer>{ 25, 100, PROVIDER_WIDTH_LARGE }) {
            metrics.add(measureDynamicModuleColdTotal(providerCount, iterations));
        }
        return metrics;
    }

    private static List<BenchmarkMetric> measureClassModuleCold(final Integer iterations) {
        List<BenchmarkMetric> metrics = new List<BenchmarkMetric>();
        for (Integer providerCount : new List<Integer>{ 25, 100, PROVIDER_WIDTH_LARGE }) {
            metrics.add(measureClassModuleColdTotal(providerCount, iterations));
        }
        return metrics;
    }

    private static List<BenchmarkMetric> measureDynamicModuleColdSplitProfile(final Integer iterations) {
        List<BenchmarkMetric> metrics = new List<BenchmarkMetric>();
        for (Integer providerCount : new List<Integer>{ 25, 100, PROVIDER_WIDTH_LARGE }) {
            metrics.addAll(measureDynamicModuleColdSplit(providerCount, iterations));
        }
        return metrics;
    }

    private static List<BenchmarkMetric> measureClassModuleColdSplitProfile(final Integer iterations) {
        List<BenchmarkMetric> metrics = new List<BenchmarkMetric>();
        for (Integer providerCount : new List<Integer>{ 25, 100, PROVIDER_WIDTH_LARGE }) {
            metrics.addAll(measureClassModuleColdSplit(providerCount, iterations));
        }
        return metrics;
    }

    private static BenchmarkMetric measureDynamicModuleColdTotal(
        final Integer providerCount,
        final Integer iterations
    ) {
        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) buildWidthGraph(newContext(), providerCount).get('order');
        }
        return finish('dynamic_cold_total_' + providerCount, iterations, sample, checksum);
    }

    private static List<BenchmarkMetric> measureDynamicModuleColdSplit(
        final Integer providerCount,
        final Integer iterations
    ) {
        Integer constructCpu = 0;
        Integer registerCpu = 0;
        Integer firstGetCpu = 0;
        Integer constructHeap = 0;
        Integer registerHeap = 0;
        Integer checksum = 0;
        for (Integer i = 0; i < iterations; i++) {
            Integer t0 = Limits.getCpuTime();
            Integer h0 = Limits.getHeapSize();
            Di.ApplicationContext context = newContext();
            Di.DynamicModule module = newDynamicWidthModule(providerCount);
            Integer t1 = Limits.getCpuTime();
            Integer h1 = Limits.getHeapSize();
            Di.ModuleRef ref = context.addModule(module);
            Integer t2 = Limits.getCpuTime();
            Integer h2 = Limits.getHeapSize();
            checksum += (Integer) ref.get('order');
            Integer t3 = Limits.getCpuTime();

            constructCpu += t1 - t0;
            registerCpu += t2 - t1;
            firstGetCpu += t3 - t2;
            constructHeap += h1 - h0;
            registerHeap += h2 - h1;
        }
        return new List<BenchmarkMetric>{
            new BenchmarkMetric(
                'dynamic_split_construct_' + providerCount,
                iterations,
                constructCpu,
                constructHeap,
                String.valueOf(checksum)
            ),
            new BenchmarkMetric('dynamic_split_register_' + providerCount, iterations, registerCpu, registerHeap, ''),
            new BenchmarkMetric('dynamic_split_first_get_' + providerCount, iterations, firstGetCpu, 0, '')
        };
    }

    private static BenchmarkMetric measureClassModuleColdTotal(final Integer providerCount, final Integer iterations) {
        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) buildClassWidthGraph(newContext(), providerCount).get('order');
        }
        return finish('class_cold_total_' + providerCount, iterations, sample, checksum);
    }

    private static List<BenchmarkMetric> measureClassModuleColdSplit(
        final Integer providerCount,
        final Integer iterations
    ) {
        Integer constructCpu = 0;
        Integer registerCpu = 0;
        Integer firstGetCpu = 0;
        Integer constructHeap = 0;
        Integer registerHeap = 0;
        Integer checksum = 0;
        for (Integer i = 0; i < iterations; i++) {
            Integer t0 = Limits.getCpuTime();
            Integer h0 = Limits.getHeapSize();
            Di.ApplicationContext context = newContext();
            ClassWidthModule module = new ClassWidthModule(providerCount);
            Integer t1 = Limits.getCpuTime();
            Integer h1 = Limits.getHeapSize();
            Di.ModuleRef ref = context.addModule(module);
            Integer t2 = Limits.getCpuTime();
            Integer h2 = Limits.getHeapSize();
            checksum += (Integer) ref.get('order');
            Integer t3 = Limits.getCpuTime();

            constructCpu += t1 - t0;
            registerCpu += t2 - t1;
            firstGetCpu += t3 - t2;
            constructHeap += h1 - h0;
            registerHeap += h2 - h1;
        }
        return new List<BenchmarkMetric>{
            new BenchmarkMetric(
                'class_split_construct_' + providerCount,
                iterations,
                constructCpu,
                constructHeap,
                String.valueOf(checksum)
            ),
            new BenchmarkMetric('class_split_register_' + providerCount, iterations, registerCpu, registerHeap, ''),
            new BenchmarkMetric('class_split_first_get_' + providerCount, iterations, firstGetCpu, 0, '')
        };
    }

    private static BenchmarkMetric measureDependencyDepth(final Integer iterations) {
        Di.ApplicationContext context = newContext();
        Di.DynamicModule module = new Di.DynamicModule('ApexDepthModule');
        for (Integer i = 0; i < DEPENDENCY_DEPTH; i++) {
            module.addProvider(module.provide('node_' + i).useFactory(new DepthFactory(i, DEPENDENCY_DEPTH)));
        }
        Di.ModuleRef ref = context.addModule(module);

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) ref.resolve('node_0');
        }
        return finish('dependency_depth_' + DEPENDENCY_DEPTH, iterations, sample, checksum);
    }

    private static BenchmarkMetric measureModuleFanout(final Integer iterations) {
        Di.ApplicationContext context = newContext();
        Di.DynamicModule app = new Di.DynamicModule('ApexModuleFanoutApp');
        String target = 'm' + (MODULE_FANOUT_COUNT - 1) + '_p' + (MODULE_FANOUT_PROVIDER_COUNT - 1);

        for (Integer m = 0; m < MODULE_FANOUT_COUNT; m++) {
            Di.DynamicModule imported = new Di.DynamicModule('ApexFanoutModule' + m);
            for (Integer p = 0; p < MODULE_FANOUT_PROVIDER_COUNT; p++) {
                String token = 'm' + m + '_p' + p;
                imported.addProvider(imported.provide(token).useValue(1)).addExport(token);
            }
            app.addImport(context.import(imported));
        }

        Di.ModuleRef ref = context.addModule(app);
        ref.get(target);

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) ref.get(target);
        }
        return finish('module_fanout_' + MODULE_FANOUT_COUNT, iterations, sample, checksum);
    }

    private static BenchmarkMetric measureGlobalLookup(final Integer iterations) {
        Di.ApplicationContext context = newContext();
        Di.DynamicModule globalModule = new Di.DynamicModule('ApexGlobalLookupModule');
        globalModule.addProvider(globalModule.provide('globalValue').useValue(1)).addExport('globalValue');
        context.addGlobalModule(globalModule);
        Di.ModuleRef consumer = context.addModule(new Di.DynamicModule('ApexGlobalLookupConsumer'));
        consumer.get('globalValue');

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) consumer.get('globalValue');
        }
        return finish('global_lookup', iterations, sample, checksum);
    }

    private static BenchmarkMetric measureScopedContext(final Integer iterations) {
        Di.ApplicationContext context = newContext();
        Di.DynamicModule module = new Di.DynamicModule('ApexScopedModule');
        module.addProvider(module.provide('scoped').useClass(ScopedValue.class).scope(Di.Scope.SCOPED));
        Di.ScopeRef scope = context.addModule(module).createScope();
        scope.get('scoped');

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += ((ScopedValue) scope.get('scoped')).value();
        }
        return finish('scope_context', iterations, sample, checksum);
    }

    private static BenchmarkMetric measurePrototypeResolution(final Integer iterations) {
        Di.ApplicationContext context = newContext();
        Di.DynamicModule module = new Di.DynamicModule('ApexPrototypeModule');
        module.addProvider(module.provide('prototype').useClass(PrototypeValue.class).scope(Di.Scope.PROTOTYPE));
        Di.ModuleRef ref = context.addModule(module);

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += ((PrototypeValue) ref.resolve('prototype')).value();
        }
        return finish('prototype_resolution', iterations, sample, checksum);
    }

    private static BenchmarkMetric measureProviderReplacement(final Integer iterations) {
        Di.ApplicationContext context = newContext();
        Di.DynamicModule module = new Di.DynamicModule('ApexReplacementModule');
        module.addProvider(module.provide('value').useValue(1));
        context.addModule(module).get('value');

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            Integer value = Math.mod(i, 2) == 0 ? 2 : 1;
            context.replaceProvider(module.getToken(), new Di.ValueProvider('value', value));
            checksum += (Integer) context.getModuleRef(module.getToken()).get('value');
        }
        return finish('provider_replacement', iterations, sample, checksum);
    }

    private static BenchmarkMetric measureCycleValidation(final Integer iterations) {
        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            Di.ApplicationContext context = newContext();
            Di.DynamicModule a = new Di.DynamicModule('ApexCycleA');
            Di.DynamicModule b = new Di.DynamicModule('ApexCycleB');
            a.addImport(context.import('ApexCycleB'));
            b.addImport(context.import('ApexCycleA'));
            context.addModule(a);
            context.addModule(b);
            try {
                context.compile();
            } catch (Di.InvalidModuleException ex) {
                checksum++;
            }
        }
        return finish('cycle_validation', iterations, sample, checksum);
    }

    private static BenchmarkMetric measureModuleImportDepth(final Integer iterations) {
        Di.ApplicationContext context = newContext();
        List<Di.DynamicModule> modules = new List<Di.DynamicModule>();
        for (Integer i = 0; i < MODULE_IMPORT_DEPTH; i++) {
            modules.add(new Di.DynamicModule('ApexImportDepth' + i));
        }

        Di.DynamicModule leaf = modules[MODULE_IMPORT_DEPTH - 1];
        leaf.addProvider(leaf.provide('leaf').useValue(1)).addExport('leaf');
        for (Integer i = MODULE_IMPORT_DEPTH - 2; i >= 0; i--) {
            modules[i].addReexport(context.import(modules[i + 1]));
        }

        Di.ModuleRef ref = context.addModule(modules[0]);
        ref.get('leaf');

        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            checksum += (Integer) ref.get('leaf');
        }
        return finish('module_import_depth_' + MODULE_IMPORT_DEPTH, iterations, sample, checksum);
    }

    private static BenchmarkMetric measureAmbiguityValidation(final Integer iterations) {
        Integer checksum = 0;
        Sample sample = new Sample();
        for (Integer i = 0; i < iterations; i++) {
            Di.ApplicationContext context = newContext();
            Di.DynamicModule left = new Di.DynamicModule('ApexAmbiguousLeft');
            left.addProvider(left.provide('ambiguous').useValue(1)).addExport('ambiguous');
            Di.DynamicModule right = new Di.DynamicModule('ApexAmbiguousRight');
            right.addProvider(right.provide('ambiguous').useValue(2)).addExport('ambiguous');
            Di.DynamicModule app = new Di.DynamicModule('ApexAmbiguousApp');
            app.addImport(context.import(left));
            app.addImport(context.import(right));

            try {
                context.addModule(app).get('ambiguous');
            } catch (Di.InvalidProviderException ex) {
                checksum++;
            }
        }
        return finish('ambiguity_validation', iterations, sample, checksum);
    }

    private static Di.ModuleRef buildWidthGraph(final Di.ApplicationContext context, final Integer providerCount) {
        return context.addModule(newDynamicWidthModule(providerCount));
    }

    private static Di.DynamicModule newDynamicWidthModule(final Integer providerCount) {
        Di.DynamicModule module = new Di.DynamicModule('ApexWidth' + providerCount);
        module.addProvider(module.provide('gateway').useValue(7));
        module.addProvider(module.provide('logger').useValue(3));
        module.addProvider(module.provide('order').useFactory(new OrderFactory()));
        for (Integer i = 0; i < providerCount - 3; i++) {
            module.addProvider(module.provide('filler_' + i).useValue(0));
        }
        return module;
    }

    private static Di.ModuleRef buildClassWidthGraph(final Di.ApplicationContext context, final Integer providerCount) {
        return context.addModule(new ClassWidthModule(providerCount));
    }

    private static BenchmarkMetric finish(
        final String name,
        final Integer iterations,
        final Sample sample,
        final Object checksum
    ) {
        return new BenchmarkMetric(
            name,
            iterations,
            Limits.getCpuTime() - sample.cpuMs,
            Limits.getHeapSize() - sample.heapBytes,
            String.valueOf(checksum)
        );
    }

    private static Di.ApplicationContext newContext() {
        return Di.createContext(new EmptyMetadataSource());
    }

    private static Integer normalizeIterations(final Integer requestedIterations) {
        return requestedIterations == null || requestedIterations < 1 ? DEFAULT_ITERATIONS : requestedIterations;
    }

    private static Integer cap(final Integer value, final Integer maxValue) {
        return value > maxValue ? maxValue : value;
    }

    private class EmptyMetadataSource implements Di.MetadataSource {
        public Map<String, Di.MetadataModuleDefinition> getModules() {
            return new Map<String, Di.MetadataModuleDefinition>();
        }

        public Map<String, Di.ProviderDefinition> getProviders() {
            return new Map<String, Di.ProviderDefinition>();
        }
    }

    private class ClassWidthModule extends Di.Module {
        private final Integer providerCount;

        private ClassWidthModule(final Integer providerCount) {
            super('ApexClassWidth' + providerCount);
            this.providerCount = providerCount;
        }

        public override Set<Di.Provider> providers() {
            Set<Di.Provider> providers = new Set<Di.Provider>{
                provide('gateway').useValue(7),
                provide('logger').useValue(3),
                provide('order').useFactory(new OrderFactory())
            };
            for (Integer i = 0; i < providerCount - 3; i++) {
                providers.add(provide('filler_' + i).useValue(0));
            }
            return providers;
        }
    }

    public class OrderFactory implements Di.Factory {
        public Object newInstance(final Di.Container ref, final Object args) {
            return (Integer) ref.get('gateway') + (Integer) ref.get('logger');
        }
    }

    public class DepthFactory implements Di.Factory {
        private final Integer index;
        private final Integer depth;

        public DepthFactory(final Integer index, final Integer depth) {
            this.index = index;
            this.depth = depth;
        }

        public Object newInstance(final Di.Container ref, final Object args) {
            if (index == depth - 1) {
                return 1;
            }
            return 1 + (Integer) ref.resolve('node_' + (index + 1));
        }
    }

    public class ScopedValue {
        public Integer value() {
            return 1;
        }
    }

    public class PrototypeValue {
        public Integer value() {
            return 1;
        }
    }
}
