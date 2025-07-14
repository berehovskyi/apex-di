public virtual inherited sharing class Di {
    private static final String INVALID_CLASS_MESSAGE = 'Cannot instantiate class "{0}". Please ensure this class exists and is accessible.';
    private static final String INVALID_PROVIDER_TYPE_MESSAGE = 'Cannot create provider for "{0}". The provider type cannot be null.';
    private static final String INSTANTIATION_FAILED_MESSAGE =
        'Cannot instantiate class "{0}". ' +
        'Please ensure this class exists, is accessible, and has a public no-argument constructor.';
    private static final String UNKNOWN_PROVIDER_MESSAGE =
        'Could not find "{0}" provider in the "{1}" module' +
        ' context.' +
        '\nPotential solutions:' +
        '\n- Ensure the provider is listed in the "providers" array of the module' +
        '\n- Ensure the provider is exported from its module and imported into "{1}"' +
        '\n- Check for typos in the provider token';
    private static final String UNKNOWN_MODULE_MESSAGE =
        'Cannot find module "{0}". A module with this name ' +
        'has not been registered.' +
        '\nPotential solutions:' +
        '\n- Ensure the module class exists and is accessible' +
        '\n- Verify the module is imported where needed' +
        '\n- Check for typos in the module name';
    private static final String NULL_MODULE_MESSAGE = 'Cannot process a null module. Please provide a valid module instance.';
    private static final String INVALID_MODULE_MESSAGE = 'Invalid module "{0}". The class must extend Di.Module.';
    private static final String INVALID_MODULE_TOKEN_MESSAGE = 'Invalid module token. The token cannot be null.';
    private static final String MODULE_ALREADY_REGISTERED_MESSAGE =
        'A module with name "{0}" has already been ' +
        'registered. Use replaceModule() to override an existing module.';
    private static final String INVALID_GLOBAL_MODULE_MESSAGE =
        'Cannot register "{0}" as a global module. ' +
        'The module must return true from isGlobal() method to be registered globally.' +
        '\nDid you mean to use addModule() instead?';
    private static final String MODULE_SCOPE_MISMATCH_MESSAGE =
        'Cannot replace {0} module "{1}" with {2} module. ' +
        'The replacement module must have the same scope (global/local) as the original.';
    private static final String UNKNOWN_EXPORT_MESSAGE =
        'Cannot export "{0}" from the "{1}" module. This provider ' +
        'has not been registered in the module.' +
        '\nPlease ensure "{0}" is listed in the "providers" array before exporting it.';
    private static final String NULL_PROVIDER_MESSAGE = 'The provider cannot be null.';
    private static final String NULL_PROVIDER_FACTORY_MESSAGE = 'The provider factory cannot be null.';
    private static final String NULL_MODULE_IMPORT_MESSAGE = 'The module import cannot be null.';
    private static final String INVALID_PROVIDER_TOKEN_MESSAGE = 'Invalid provider token. The token cannot be null.';
    private static final String INVALID_MODULE_REPLACEMENT_MESSAGE = 'Cannot replace module with null. Please provide a valid module instance.';
    private static final String PROTOTYPE_SCOPE_ERROR_MESSAGE =
        'Cannot retrieve prototype-scoped provider "{0}" ' +
        'using get(). Prototype-scoped providers create a new instance on each request.' +
        '\nUse resolve() method instead to get a new instance.';
    private static final String MODULE_SHADOWING_WARNING =
        'Local module "{0}" is shadowing global module with ' +
        'the same name. The global module will be inaccessible in this context.';
    private static final String INVALID_PROVIDER_CONFIG_MESSAGE =
        'Invalid provider configuration for token "{0}". ' +
        'The provider must be one of: ClassProvider, ValueProvider, or FactoryProvider.';

    private static final Map<String, ModuleRef> MODULE_REGISTRY = new Map<String, ModuleRef>();
    private static final Map<String, ModuleRef> GLOBAL_MODULE_REGISTRY = new Map<String, ModuleRef>();
    private static final Map<String, Provider> GLOBAL_PROVIDERS = new Map<String, Provider>();

    private static Boolean hasGlobalLoadBeenAttempted = false;

    private static final Map<String, ModuleRef> globalRegistry {
        get {
            if (!hasGlobalLoadBeenAttempted) {
                hasGlobalLoadBeenAttempted = true;
                loadGlobalModules();
            }
            return GLOBAL_MODULE_REGISTRY;
        }
    }
    private static Iterable<DI_GlobalModule__mdt> mockGlobalModules {
        get;
        set {
            mockGlobalModules = value;
            hasGlobalLoadBeenAttempted = false;
        }
    }

    @TestVisible
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private Di() {
    }

    public static ModuleImport import(final String token) {
        return new ModuleImport(token);
    }

    public static ModuleImport import(final Type token) {
        return new ModuleImport(token);
    }

    public static ModuleImport import(final Module module) {
        return new ModuleImport(module);
    }

    public static ModuleRef addModule(final Module module) {
        Validate.isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

        String token = module.getToken();
        Map<String, ModuleRef> registry = module.isGlobal() ? globalRegistry : MODULE_REGISTRY;
        Validate.isTrue(
            !registry.containsKey(token),
            new InvalidModuleException(String.format(MODULE_ALREADY_REGISTERED_MESSAGE, new List<String>{ token }))
        );

        if (!module.isGlobal()) {
            warnIfGlobalModuleShadowed(token);
        }
        ModuleRef ref = new ModuleRef(module);
        registry.put(token, ref);
        module.register();

        if (module.isGlobal()) {
            addGlobalProviders(module);
        }
        return ref;
    }

    public static ModuleRef getModuleRef(final String token) {
        Validate.isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));

        if (MODULE_REGISTRY.containsKey(token)) {
            return MODULE_REGISTRY.get(token);
        }
        if (globalRegistry.containsKey(token)) {
            return globalRegistry.get(token);
        }
        Module module = forName(token);
        ModuleRef ref = new ModuleRef(module);
        Map<String, ModuleRef> registry = module.isGlobal() ? globalRegistry : MODULE_REGISTRY;
        registry.put(token, ref);
        module.register();
        return ref;
    }

    public static ModuleRef getModuleRef(final Type moduleType) {
        return getModuleRef(moduleType?.getName());
    }

    public static ModuleRef getModuleRef(final Module module) {
        Validate.isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

        String token = module.getToken();
        if (MODULE_REGISTRY.containsKey(token)) {
            return MODULE_REGISTRY.get(token);
        }
        if (globalRegistry.containsKey(token)) {
            return globalRegistry.get(token);
        }
        return addModule(module);
    }

    public static void replaceModule(final String token, final Module newModule) {
        Validate.isTrue(newModule != null, new InvalidModuleException(INVALID_MODULE_REPLACEMENT_MESSAGE));

        Module oldModule = getModuleRef(token).getModule();
        Validate.isTrue(
            oldModule.isGlobal() == newModule.isGlobal(),
            new InvalidModuleException(
                String.format(
                    MODULE_SCOPE_MISMATCH_MESSAGE,
                    new List<String>{
                        oldModule.isGlobal() ? 'global' : 'local',
                        token,
                        newModule.isGlobal() ? 'global' : 'local'
                    }
                )
            )
        );

        if (!newModule.isGlobal()) {
            warnIfGlobalModuleShadowed(token);
        }
        newModule.register();
        Map<String, ModuleRef> registry = oldModule.isGlobal() ? globalRegistry : MODULE_REGISTRY;
        if (oldModule.isGlobal()) {
            for (String exportToken : oldModule.exports()) {
                GLOBAL_PROVIDERS.remove(exportToken);
            }
            addGlobalProviders(newModule);

            // Invalidate all module caches to ensure they pick up the global change.
            for (ModuleRef ref : MODULE_REGISTRY.values()) {
                ref.clearCache();
            }
            for (ModuleRef ref : GLOBAL_MODULE_REGISTRY.values()) {
                ref.clearCache();
            }
        }
        registry.put(token, new ModuleRef(newModule));
    }

    public static void replaceModule(final Type token, final Module newModule) {
        replaceModule(token?.getName(), newModule);
    }

    public static void clear() {
        MODULE_REGISTRY.clear();
        GLOBAL_MODULE_REGISTRY.clear();
        GLOBAL_PROVIDERS.clear();
        mockGlobalModules = null;
    }

    @TestVisible
    private static void mockGlobalModules(final Iterable<DI_GlobalModule__mdt> mockModules) {
        mockGlobalModules = mockModules;
    }

    private static void warnIfGlobalModuleShadowed(String token) {
        if (globalRegistry.containsKey(token)) {
            System.debug(LoggingLevel.WARN, String.format(MODULE_SHADOWING_WARNING, new List<String>{ token })); // NOPMD
        }
    }

    private static void loadGlobalModules() {
        for (DI_GlobalModule__mdt moduleDef : getGlobalModuleDefinitions()) {
            if (!moduleDef.IsActive__c) {
                continue;
            }
            Module module = forName(moduleDef.ModuleClass__c);
            Validate.isTrue(
                module.isGlobal(),
                new InvalidModuleException(
                    String.format(INVALID_GLOBAL_MODULE_MESSAGE, new List<String>{ module.getToken() })
                )
            );

            addModule(module);
        }
    }

    private static Module forName(final String token) {
        Type moduleType = Type.forName(token);
        Validate.isTrue(
            moduleType != null,
            new UnknownModuleException(String.format(UNKNOWN_MODULE_MESSAGE, new List<String>{ token }))
        );

        Object raw = moduleType.newInstance();
        Validate.isTrue(
            raw instanceof Module,
            new InvalidModuleException(String.format(INVALID_MODULE_MESSAGE, new List<String>{ token }))
        );

        Module module = (Module) raw;
        return module;
    }

    private static Iterable<DI_GlobalModule__mdt> getGlobalModuleDefinitions() {
        if (Test.isRunningTest() && mockGlobalModules != null) {
            return mockGlobalModules;
        }
        return DI_GlobalModule__mdt.getAll().values();
    }

    private static void addGlobalProviders(Module module) {
        for (String token : module.exports()) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            Provider provider = module.getProvider(token);
            Validate.isTrue(
                provider != null,
                new UnknownExportException(
                    String.format(UNKNOWN_EXPORT_MESSAGE, new List<String>{ token, module.getToken() })
                )
            );

            GLOBAL_PROVIDERS.put(token, provider);
        }
    }

    public virtual inherited sharing class Module {
        protected final String token;
        protected final Map<String, Provider> providers = new Map<String, Provider>();
        protected final Set<String> exports = new Set<String>();
        protected Boolean isGlobal = false;

        public Module() {
            token = String.valueOf(this).substringBefore(':');
        }
        protected Module(final String token) {
            Validate.isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));
            this.token = token;
        }

        public String getToken() {
            return token;
        }

        public Provider getProvider(final String token) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            // First check local definitions
            if (providers.containsKey(token)) {
                return providers.get(token);
            }

            // Then check imported modules
            for (ModuleImport moduleImport : imports()) {
                Module module = moduleImport.resolve();
                if (!module.exports().contains(token)) {
                    continue;
                }
                Provider provider = module.getProvider(token);
                if (provider != null) {
                    providers.put(token, provider);
                    return provider;
                }
            }

            // Finally check global providers
            if (GLOBAL_PROVIDERS.containsKey(token)) {
                return GLOBAL_PROVIDERS.get(token);
            }

            throw new UnknownProviderException(
                String.format(UNKNOWN_PROVIDER_MESSAGE, new List<String>{ token, getToken() })
            );
        }

        public virtual Boolean isGlobal() {
            return isGlobal;
        }

        public virtual Set<ModuleImport> imports() {
            return new Set<ModuleImport>();
        }

        public virtual Set<Provider> providers() {
            return new Set<Provider>();
        }

        public virtual Set<String> exports() {
            return new Set<String>();
        }

        public virtual ProviderBuilder provide(final Type token) {
            return provide(token?.getName());
        }

        public virtual ProviderBuilder provide(final String token) {
            return new ProviderBuilder(token);
        }

        protected virtual Module replace(final Provider newProvider) {
            Validate.isTrue(newProvider != null, new InvalidProviderException(NULL_PROVIDER_MESSAGE));

            String token = newProvider.token;
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            if (providers.containsKey(token)) {
                providers.put(token, newProvider);
            }
            return this;
        }

        protected virtual void register() {
            providers.clear();
            exports.clear();

            for (Provider provider : providers()) {
                providers.put(provider.token, provider);
            }

            for (String token : exports()) {
                Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));
                Validate.isTrue(
                    providers.containsKey(token),
                    new UnknownExportException(
                        String.format(UNKNOWN_EXPORT_MESSAGE, new List<String>{ token, getToken() })
                    )
                );

                exports.add(token);
            }
        }

        public virtual Boolean equals(final Object obj) {
            if (obj instanceof Module) {
                return ((Module) obj).getToken().equals(token);
            }
            return false;
        }

        public virtual override Integer hashCode() {
            return System.hashCode(token);
        }
    }

    public virtual inherited sharing class DynamicModule extends Module {
        private final Set<ModuleImport> dynamicImports = new Set<ModuleImport>();
        private final Map<String, Provider> dynamicProviders = new Map<String, Provider>();
        private final Set<String> dynamicExports = new Set<String>();

        public DynamicModule(final String token) {
            super(token);
        }

        public override Set<ModuleImport> imports() {
            return dynamicImports;
        }

        public override Set<Provider> providers() {
            return new Set<Provider>(dynamicProviders.values());
        }

        public override Set<String> exports() {
            return dynamicExports;
        }

        public DynamicModule setGlobal() {
            isGlobal = true;
            return this;
        }

        public DynamicModule addImport(final ModuleImport moduleImport) {
            Validate.isTrue(moduleImport != null, new InvalidModuleException(NULL_MODULE_IMPORT_MESSAGE));

            dynamicImports.add(moduleImport);
            return this;
        }

        public DynamicModule addProvider(final Provider provider) {
            Validate.isTrue(provider != null, new InvalidProviderException(NULL_PROVIDER_MESSAGE));

            dynamicProviders.put(provider.token, provider);
            return this;
        }

        public DynamicModule addExport(final String token) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            dynamicExports.add(token);
            return this;
        }
    }

    public virtual inherited sharing class ProviderBuilder {
        public final String token { get; private set; }

        protected ProviderBuilder(String token) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            this.token = token;
        }

        public virtual ClassProvider useClass(final Type type) {
            return new ClassProvider(token, type);
        }

        public virtual ClassProvider useClass(final String type) {
            return new ClassProvider(token, type);
        }

        public virtual ValueProvider useValue(final Object value) {
            return new ValueProvider(token, value);
        }

        public virtual FactoryProvider useFactory(final Factory factory) {
            return new FactoryProvider(token, factory);
        }
    }

    public virtual inherited sharing class Provider {
        public final String token { get; private set; }
        public Scope scopeType { get; private set; }
        {
            scopeType = Scope.SINGLETON;
        }

        protected Provider(String token) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            this.token = token;
        }

        public virtual Provider scope(final Scope scopeType) {
            this.scopeType = scopeType;
            return this;
        }

        public virtual Boolean equals(final Object obj) {
            if (obj instanceof Provider) {
                return ((Provider) obj).token.equals(token);
            }
            return false;
        }

        public virtual Integer hashCode() {
            return System.hashCode(token);
        }
    }

    public virtual inherited sharing class ClassProvider extends Provider {
        public final String type { get; private set; }
        public ClassProvider(final String token, final String type) {
            super(token);
            Validate.isTrue(
                type != null,
                new InvalidProviderException(String.format(INVALID_PROVIDER_TYPE_MESSAGE, new List<String>{ token }))
            );

            this.type = type;
        }
        public ClassProvider(final String token, final Type type) {
            this(token, type?.getName());
        }
        public ClassProvider(final Type token, final Type type) {
            this(token?.getName(), type?.getName());
        }
        public ClassProvider(final Type token, final String type) {
            this(token?.getName(), type);
        }
    }

    public virtual inherited sharing class ValueProvider extends Provider {
        public final Object value { get; private set; }
        public ValueProvider(final String token, final Object value) {
            super(token);
            this.value = value;
        }
    }

    public virtual inherited sharing class FactoryProvider extends Provider {
        public final Factory factory { get; private set; }
        public FactoryProvider(final String token, final Factory factory) {
            super(token);
            Validate.isTrue(factory != null, new InvalidProviderException(NULL_PROVIDER_FACTORY_MESSAGE));

            this.factory = factory;
        }
    }

    public virtual inherited sharing class ModuleRef {
        private final Module module;
        private final Map<String, Object> cache = new Map<String, Object>();

        protected ModuleRef(Module module) {
            this.module = module;
        }

        public Module getModule() {
            return module;
        }

        public virtual Object get(final String token, final Object args) {
            Provider provider = module.getProvider(token);
            Validate.isTrue(
                provider.scopeType != Scope.PROTOTYPE,
                new InvalidScopeException(String.format(PROTOTYPE_SCOPE_ERROR_MESSAGE, new List<String>{ token }))
            );

            if (cache.containsKey(token)) {
                return cache.get(token);
            }

            Object instance = newInstance(provider, args);
            cache.put(token, instance);
            return instance;
        }

        public virtual Object get(final Type token, final Object args) {
            return get(token?.getName(), args);
        }

        public virtual Object get(final String token) {
            return get(token, null);
        }

        public virtual Object get(final Type token) {
            return get(token?.getName(), null);
        }

        public virtual Object resolve(final String token, final Object args) {
            Provider provider = module.getProvider(token);
            return newInstance(provider, args);
        }

        public virtual Object resolve(final Type token, final Object args) {
            return resolve(token?.getName(), args);
        }

        public virtual Object resolve(final String token) {
            return resolve(token, null);
        }

        public virtual Object resolve(final Type token) {
            return resolve(token?.getName(), null);
        }

        public virtual void replace(final Provider newProvider) {
            Validate.isTrue(newProvider != null, new InvalidProviderException(NULL_PROVIDER_MESSAGE));

            String token = newProvider.token;
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            module.replace(newProvider);
            cache.remove(token);
        }

        public virtual void refresh() {
            module.register();
            clearCache();
        }

        public void clearCache() {
            cache.clear();
        }

        protected virtual Object newInstance(Provider provider, Object args) {
            if (provider instanceof ClassProvider) {
                String typeName = ((ClassProvider) provider).type;
                Type providedType = Type.forName(typeName);
                Validate.isTrue(
                    providedType != null,
                    new InvalidClassException(String.format(INVALID_CLASS_MESSAGE, new List<String>{ typeName }))
                );

                Object instance;
                try {
                    instance = providedType.newInstance();
                } catch (TypeException exc) {
                    throw new InvalidClassException(
                        String.format(INSTANTIATION_FAILED_MESSAGE, new List<String>{ typeName }),
                        exc
                    );
                }
                if (instance instanceof Injectable) {
                    ((Injectable) instance).inject(this);
                }
                return instance;
            }
            if (provider instanceof ValueProvider) {
                return ((ValueProvider) provider).value;
            }
            if (provider instanceof FactoryProvider) {
                return ((FactoryProvider) provider).factory.newInstance(this, args);
            }
            throw new InvalidProviderException(
                String.format(INVALID_PROVIDER_CONFIG_MESSAGE, new List<String>{ provider.token })
            );
        }
    }

    public virtual class ModuleImport {
        protected final String token;
        protected Boolean isEager = false;
        protected Module cachedModule;

        protected ModuleImport(String token) {
            Validate.isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));

            this.token = token;
        }

        protected ModuleImport(Type type) {
            this(type?.getName());
        }

        protected ModuleImport(Module module) {
            Validate.isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

            token = module.getToken();
            cachedModule = module;
        }

        public virtual ModuleImport immediately() {
            isEager = true;
            // eagerly registers the module if it isn't already
            cachedModule = cachedModule != null
                ? Di.getModuleRef(cachedModule).getModule()
                : Di.getModuleRef(token).getModule();
            return this;
        }

        public virtual Module resolve() {
            if (cachedModule != null) {
                return isEager ? cachedModule : Di.getModuleRef(cachedModule).getModule();
            }
            return Di.getModuleRef(token).getModule();
        }

        public virtual Boolean equals(Object obj) {
            if (obj instanceof ModuleImport) {
                return ((ModuleImport) obj).token.equals(token);
            }
            return false;
        }

        public virtual Integer hashCode() {
            return System.hashCode(token);
        }
    }

    public enum Scope {
        SINGLETON,
        PROTOTYPE
    }

    public interface Factory {
        Object newInstance(final ModuleRef ref, final Object args);
    }

    public interface Injectable {
        /**
         * @description Called immediately after instantiation to inject dependencies.
         *
         * @param container The module reference to resolve dependencies from
         */
        void inject(final ModuleRef container);
    }

    public virtual class DiException extends Exception {
    }
    public virtual class InvalidModuleException extends DiException {
    }
    public virtual class UnknownModuleException extends DiException {
    }
    public virtual class UnknownProviderException extends DiException {
    }
    public virtual class UnknownExportException extends DiException {
    }
    public virtual class InvalidProviderException extends DiException {
    }
    public virtual class InvalidClassException extends DiException {
    }
    public virtual class InvalidScopeException extends DiException {
    }
}
