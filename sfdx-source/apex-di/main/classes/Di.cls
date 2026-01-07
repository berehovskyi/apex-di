public virtual inherited sharing class Di {
    private static final String INVALID_CLASS_MESSAGE = 'Cannot instantiate class "{0}". Please ensure this class exists and is accessible.';
    private static final String INVALID_PROVIDER_TYPE_MESSAGE = 'Cannot create provider for "{0}". The provider type cannot be null.';
    private static final String INSTANTIATION_FAILED_MESSAGE =
        'Cannot instantiate class "{0}". ' +
        'Please ensure this class exists, is accessible, and has a public no-argument constructor.';
    private static final String UNKNOWN_PROVIDER_MESSAGE =
        'Could not find "{0}" provider in the "{1}" module ' +
        'context.' +
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
    private static final String INVALID_PROVIDER_CONFIG_MESSAGE =
        'Invalid provider configuration for token "{0}". ' +
        'The provider must be one of: ClassProvider, ValueProvider, FactoryProvider or ExistingProvider.';
    private static final String CIRCULAR_DEPENDENCY_MESSAGE = 'Circular dependency detected for provider "{0}". Resolution path: {1}';
    private static final String INVALID_OPERATION_MESSAGE = 'This operation is not supported for this provider type.';
    private static final String INVALID_DEVELOPER_NAME_MESSAGE = 'The developer name for a metadata provider cannot be blank.';
    private static final String MISSING_METADATA_PROVIDER_MESSAGE = 'Provider for token "{0}" is configured to use Custom Metadata record "{1}", but a record with that DeveloperName was not found.';
    private static final String INACTIVE_METADATA_PROVIDER_MESSAGE = 'Provider for token "{0}" is defined by Custom Metadata record "{1}", but the record is inactive.';
    private static final String INVALID_FACTORY_CLASS_MESSAGE = 'Class "{0}" provided by factory provider "{1}" does not implement the Di.Factory interface.';
    private static final String ARGS_NOT_SUPPORTED_MESSAGE = 'Arguments are only supported for FactoryProvider.';

    private static final Map<String, ModuleRef> MODULE_REGISTRY = new Map<String, ModuleRef>();
    private static final Map<String, ModuleRef> GLOBAL_MODULE_REGISTRY = new Map<String, ModuleRef>();
    private static final Map<String, Provider> GLOBAL_PROVIDERS = new Map<String, Provider>();

    @TestVisible
    private static Boolean hasGlobalLoadBeenAttempted = false;
    private static Map<String, DI_Provider__mdt> mockProviders;

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
    private static Map<String, DI_Provider__mdt> providerDefinitionByDeveloperName {
        get {
            if (providerDefinitionByDeveloperName == null) {
                providerDefinitionByDeveloperName = getProviders();
            }
            return providerDefinitionByDeveloperName;
        }
        set;
    }

    @TestVisible
    @SuppressWarnings('PMD.EmptyStatementBlock')
    private Di() {
    }

    public static ModuleRef getModuleRef(final Module module) {
        Validate.isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

        String token = module.getToken();
        return findModuleRef(token) ?? addModule(module);
    }

    public static ModuleRef getModuleRef(final String token) {
        Validate.isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));

        return findModuleRef(token) ?? getModuleRef(create(token));
    }

    public static ModuleRef getModuleRef(final Type moduleType) {
        return getModuleRef(moduleType?.getName());
    }

    public static ModuleRef addModule(final Module module) {
        Validate.isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

        String token = module.getToken();
        Map<String, ModuleRef> registry = module.isGlobal() ? globalRegistry : MODULE_REGISTRY;
        Validate.isTrue(
            !registry.containsKey(token),
            new InvalidModuleException(String.format(MODULE_ALREADY_REGISTERED_MESSAGE, new List<String>{ token }))
        );

        ModuleRef ref = new ModuleRef(module);
        registry.put(token, ref);
        module.register();
        if (module.isGlobal()) {
            addGlobalProviders(module);
        }
        return ref;
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

        newModule.register();
        Map<String, ModuleRef> registry = oldModule.isGlobal() ? globalRegistry : MODULE_REGISTRY;
        if (oldModule.isGlobal()) {
            for (String exportToken : oldModule.exports ?? new Set<String>()) {
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

    public static ModuleImport import(final Module module) {
        return new ModuleImport(module);
    }

    public static ModuleImport import(final String token) {
        return new ModuleImport(token);
    }

    public static ModuleImport import(final Type token) {
        return import(token?.getName());
    }

    public static void clear() {
        MODULE_REGISTRY.clear();
        GLOBAL_MODULE_REGISTRY.clear();
        GLOBAL_PROVIDERS.clear();
        mockGlobalModules = null;
        hasGlobalLoadBeenAttempted = false;
        mockProviders = null;
        providerDefinitionByDeveloperName = null;
    }

    @TestVisible
    private static void mockGlobalModules(final Iterable<DI_GlobalModule__mdt> mockModules) {
        mockGlobalModules = mockModules;
    }

    @TestVisible
    private static void mockProviders(final Map<String, DI_Provider__mdt> providerByDeveloperName) {
        providerDefinitionByDeveloperName = null;
        mockProviders = providerByDeveloperName;
    }

    private static ModuleRef findModuleRef(String token) {
        if (MODULE_REGISTRY.containsKey(token)) {
            return MODULE_REGISTRY.get(token);
        }
        if (globalRegistry.containsKey(token)) {
            return globalRegistry.get(token);
        }
        return null;
    }

    private static void loadGlobalModules() {
        for (DI_GlobalModule__mdt moduleDef : getGlobalModuleDefinitions()) {
            if (!moduleDef.IsActive__c) {
                continue;
            }
            Module module = create(moduleDef.ModuleClass__c);
            Validate.isTrue(
                module.isGlobal(),
                new InvalidModuleException(
                    String.format(INVALID_GLOBAL_MODULE_MESSAGE, new List<String>{ module.getToken() })
                )
            );

            addModule(module);
        }
    }

    private static Module create(final String token) {
        Type moduleType = Type.forName(token);
        Validate.isTrue(
            moduleType != null,
            new UnknownModuleException(String.format(UNKNOWN_MODULE_MESSAGE, new List<String>{ token }))
        );

        Object raw;
        try {
            raw = moduleType.newInstance();
        } catch (TypeException exc) {
            throw new InvalidModuleException(
                String.format(INSTANTIATION_FAILED_MESSAGE, new List<String>{ token }),
                exc
            );
        }
        Validate.isTrue(
            raw instanceof Module,
            new InvalidModuleException(String.format(INVALID_MODULE_MESSAGE, new List<String>{ token }))
        );

        Module module = (Module) raw;
        return module;
    }

    private static Object instantiate(final String typeName) {
        Validate.isTrue(
            typeName != null,
            new InvalidClassException(String.format(INVALID_CLASS_MESSAGE, new List<String>{ 'null' }))
        );

        Type providedType = Type.forName(typeName);
        Validate.isTrue(
            providedType != null,
            new InvalidClassException(String.format(INVALID_CLASS_MESSAGE, new List<String>{ typeName }))
        );

        return instantiate(providedType);
    }

    private static Object instantiate(final Type type) {
        Validate.isTrue(type != null, new InvalidClassException(NULL_PROVIDER_FACTORY_MESSAGE));
        try {
            return type.newInstance();
        } catch (Exception exc) {
            throw new InvalidClassException(
                String.format(INSTANTIATION_FAILED_MESSAGE, new List<String>{ type.getName() }),
                exc
            );
        }
    }

    private static Factory validateFactory(final Object raw, final String typeName, final String token) {
        Validate.isTrue(
            raw instanceof Factory,
            new InvalidClassException(
                String.format(INVALID_FACTORY_CLASS_MESSAGE, new List<String>{ typeName, token })
            )
        );

        return (Factory) raw;
    }

    private static Boolean shouldUseMock(final Object mock) {
        return Test.isRunningTest() && mock != null;
    }

    private static Iterable<DI_GlobalModule__mdt> getGlobalModuleDefinitions() {
        return shouldUseMock(mockGlobalModules) ? mockGlobalModules : DI_GlobalModule__mdt.getAll().values();
    }

    private static Map<String, DI_Provider__mdt> getProviders() {
        return shouldUseMock(mockProviders) ? mockProviders : DI_Provider__mdt.getAll();
    }

    private static void addGlobalProviders(Module module) {
        for (String token : module.exports ?? new Set<String>()) {
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

    public abstract inherited sharing class Module {
        protected final String token;
        protected final Map<String, Provider> providers = new Map<String, Provider>();
        protected final Set<String> exports = new Set<String>();
        protected Boolean isGlobal = false;

        protected Module() {
            token = String.valueOf(this).substringBefore(':');
        }

        protected Module(final String token) {
            Validate.isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));

            this.token = token;
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

        public virtual Set<ModuleImport> reexports() {
            return new Set<ModuleImport>();
        }

        public String getToken() {
            return token;
        }

        public Boolean hasImport(final String token) {
            for (ModuleImport moduleImport : imports() ?? new Set<ModuleImport>()) {
                if (moduleImport.getToken().equals(token)) {
                    return true;
                }
            }
            return false;
        }

        public Boolean hasProvider(final String token) {
            return providers.containsKey(token);
        }

        public Boolean hasExport(final String token) {
            return exports.contains(token);
        }

        public virtual Provider getProvider(final String token) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            // First check local definitions
            if (hasProvider(token)) {
                return providers.get(token);
            }

            // Then check imported and re-exported modules
            Set<ModuleImport> searchScope = new Set<ModuleImport>();
            if (imports() != null) {
                searchScope.addAll(imports());
            }
            if (reexports() != null) {
                searchScope.addAll(reexports());
            }

            for (ModuleImport moduleImport : searchScope) {
                Module module = moduleImport.resolve();
                if (!module.hasExport(token)) {
                    continue;
                }
                Provider provider = module.getProvider(token);
                if (provider != null) {
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

        public virtual ProviderBuilder provide(final Type token) {
            return provide(token?.getName());
        }

        public virtual ProviderBuilder provide(final String token) {
            return new ProviderBuilder(token);
        }

        protected virtual Module replace(final Provider newProvider) {
            Validate.isTrue(newProvider != null, new InvalidProviderException(NULL_PROVIDER_MESSAGE));

            String token = newProvider.getToken();
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            if (hasProvider(token)) {
                providers.put(token, newProvider);
            }
            return this;
        }

        protected virtual void register() {
            providers.clear();
            exports.clear();

            for (Provider provider : providers() ?? new Set<Provider>()) {
                providers.put(provider.getToken(), provider);
            }

            for (String token : exports() ?? new Set<String>()) {
                Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));
                Validate.isTrue(
                    hasProvider(token),
                    new UnknownExportException(
                        String.format(UNKNOWN_EXPORT_MESSAGE, new List<String>{ token, getToken() })
                    )
                );

                exports.add(token);
            }

            for (ModuleImport reexport : reexports() ?? new Set<ModuleImport>()) {
                Module reexportedModule = reexport.resolve();
                for (String token : reexportedModule.exports() ?? new Set<String>()) {
                    exports.add(token);
                }
            }
        }

        public Boolean equals(final Object obj) {
            if (obj instanceof Module) {
                return ((Module) obj).getToken().equals(token);
            }
            return false;
        }

        public Integer hashCode() {
            return System.hashCode(token);
        }
    }

    public virtual inherited sharing class DynamicModule extends Module {
        private final Set<ModuleImport> dynamicImports = new Set<ModuleImport>();
        private final Map<String, Provider> dynamicProviders = new Map<String, Provider>();
        private final Set<String> dynamicExports = new Set<String>();
        private final Set<ModuleImport> dynamicReexports = new Set<ModuleImport>();

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

        public override Set<ModuleImport> reexports() {
            return dynamicReexports;
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

            dynamicProviders.put(provider.getToken(), provider);
            return this;
        }

        public DynamicModule addExport(final String token) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            dynamicExports.add(token);
            return this;
        }

        public DynamicModule addReexport(final ModuleImport moduleImport) {
            Validate.isTrue(moduleImport != null, new InvalidModuleException(NULL_MODULE_IMPORT_MESSAGE));

            dynamicReexports.add(moduleImport);
            return this;
        }
    }

    public virtual inherited sharing class ProviderBuilder {
        protected final String token;

        protected ProviderBuilder(final String token) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            this.token = token;
        }

        public virtual ClassProvider useClass(final String type) {
            return new ClassProvider(token, type);
        }

        public virtual ClassProvider useClass(final Type type) {
            return new ClassProvider(token, type);
        }

        public virtual ValueProvider useValue(final Object value) {
            return new ValueProvider(token, value);
        }

        public virtual FactoryProvider useFactory(final Factory factory) {
            return new FactoryProvider(token, factory);
        }

        public virtual FactoryProvider useFactory(final String factoryType) {
            return new FactoryProvider(token, validateFactory(instantiate(factoryType), factoryType, token));
        }

        public virtual FactoryProvider useFactory(final Type factoryType) {
            return new FactoryProvider(token, validateFactory(instantiate(factoryType), factoryType.getName(), token));
        }

        public virtual ExistingProvider useExisting(final String existingToken) {
            return new ExistingProvider(token, existingToken);
        }

        public virtual ExistingProvider useExisting(final Type existingToken) {
            return useExisting(existingToken?.getName());
        }

        public virtual CustomMetadataTypesProvider useMetadata(final String developerName) {
            return new CustomMetadataTypesProvider(token, developerName);
        }
    }

    public abstract inherited sharing class Provider {
        protected final String token;
        protected Scope scopeType = Scope.SINGLETON;

        protected Provider(String token) {
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            this.token = token;
        }

        public abstract Object resolve(final Container container, final Object args);

        public String getToken() {
            return token;
        }

        public virtual Scope getScope() {
            return scopeType;
        }

        public virtual Provider scope(final Scope scopeType) {
            this.scopeType = scopeType;
            return this;
        }

        public Boolean equals(final Object obj) {
            if (obj instanceof Provider) {
                return ((Provider) obj).getToken().equals(token);
            }
            return false;
        }

        public Integer hashCode() {
            return System.hashCode(token);
        }
    }

    public virtual inherited sharing class ClassProvider extends Provider {
        protected final String typeName;

        public ClassProvider(final String token, final String type) {
            super(token);
            Validate.isTrue(
                type != null,
                new InvalidProviderException(String.format(INVALID_PROVIDER_TYPE_MESSAGE, new List<String>{ token }))
            );

            typeName = type;
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

        public override Object resolve(final Container container, final Object args) {
            Validate.isTrue(args == null, new InvalidProviderException(ARGS_NOT_SUPPORTED_MESSAGE));
            return instantiate(typeName);
        }

        public String getType() {
            return typeName;
        }
    }

    public virtual inherited sharing class ValueProvider extends Provider {
        protected final Object value;

        public ValueProvider(final String token, final Object value) {
            super(token);
            this.value = value;
        }

        public override Object resolve(final Container container, final Object args) {
            Validate.isTrue(args == null, new InvalidProviderException(ARGS_NOT_SUPPORTED_MESSAGE));
            return value;
        }
    }

    public virtual inherited sharing class FactoryProvider extends Provider {
        protected final Factory factory;

        public FactoryProvider(final String token, final Factory factory) {
            super(token);
            Validate.isTrue(factory != null, new InvalidProviderException(NULL_PROVIDER_FACTORY_MESSAGE));

            this.factory = factory;
        }

        public override Object resolve(final Container container, final Object args) {
            return factory.newInstance(container, args);
        }
    }

    public virtual inherited sharing class ExistingProvider extends Provider {
        protected final String existing;

        public ExistingProvider(final String token, final String existing) {
            super(token);
            Validate.isTrue(existing != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            this.existing = existing;
        }

        public String getExisting() {
            return existing;
        }

        public override Object resolve(final Container container, final Object args) {
            throw new InvalidProviderException(INVALID_OPERATION_MESSAGE);
        }
    }

    public virtual inherited sharing class CustomMetadataTypesProvider extends Provider {
        protected final String developerName;

        public CustomMetadataTypesProvider(final String token, final String developerName) {
            super(token);
            Validate.isTrue(
                !String.isBlank(developerName),
                new InvalidProviderException(INVALID_DEVELOPER_NAME_MESSAGE)
            );

            this.developerName = developerName;
        }

        public override Scope getScope() {
            if (providerDefinitionByDeveloperName.containsKey(developerName)) {
                DI_Provider__mdt definition = providerDefinitionByDeveloperName.get(developerName);
                if (!String.isBlank(definition?.Scope__c)) {
                    return Scope.valueOf(definition.Scope__c);
                }
            }
            return super.getScope();
        }

        public override Object resolve(final Container container, final Object args) {
            DI_Provider__mdt definition = providerDefinitionByDeveloperName.get(developerName);
            Validate.isTrue(
                definition != null,
                new InvalidProviderException(
                    String.format(MISSING_METADATA_PROVIDER_MESSAGE, new List<String>{ token, developerName })
                )
            );
            Validate.isTrue(
                definition.IsActive__c,
                new InvalidProviderException(
                    String.format(INACTIVE_METADATA_PROVIDER_MESSAGE, new List<String>{ token, developerName })
                )
            );

            Scope scopeType = !String.isBlank(definition.Scope__c)
                ? Scope.valueOf(definition.Scope__c)
                : this.scopeType;
            // Runtime args have the highest priority
            Object factoryArgs = args ?? definition.Args__c;
            String typeName = definition.Type__c;
            String value = definition.Value__c;
            Provider provider;
            switch on typeName {
                when 'Class' {
                    provider = new ClassProvider(token, value);
                }
                when 'Value' {
                    provider = new ValueProvider(token, value);
                }
                when 'Factory' {
                    provider = new FactoryProvider(token, validateFactory(instantiate(value), value, token));
                }
                when 'Existing' {
                    try {
                        return container.get(value, factoryArgs);
                    } catch (InvalidScopeException e) {
                        return container.resolve(value, factoryArgs);
                    }
                }
                when else {
                    throw new InvalidProviderException(
                        String.format(INVALID_PROVIDER_CONFIG_MESSAGE, new List<String>{ token })
                    );
                }
            }

            return provider.scope(scopeType).resolve(container, factoryArgs);
        }
    }

    public abstract inherited sharing class Container {
        protected Container parent;
        protected Module module;
        protected final List<String> resolutionPath = new List<String>();
        protected Boolean inCall = false;

        protected Container(final Container parent, final Module module) {
            Validate.isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

            this.parent = parent;
            this.module = module;
        }

        protected abstract Object getInstance(final Provider provider, final Object args);

        protected abstract Boolean hasInCache(final String token);

        public Module getModule() {
            return module;
        }

        public virtual Object get(final String token, final Object args) {
            if (!inCall) {
                startResolution();
                try {
                    return getInternal(token, args);
                } finally {
                    endResolution();
                }
            }
            return getInternal(token, args);
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
            if (!inCall) {
                startResolution();
                try {
                    return resolveInternal(token, args);
                } finally {
                    endResolution();
                }
            }
            return resolveInternal(token, args);
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

        protected virtual Object getInternal(final String token, final Object args) {
            validateAndAddPath(token);
            try {
                Provider provider = module.getProvider(token);
                Validate.isTrue(
                    provider.getScope() !== Scope.PROTOTYPE,
                    new InvalidScopeException(
                        String.format(PROTOTYPE_SCOPE_ERROR_MESSAGE, new List<String>{ provider.getToken() })
                    )
                );

                if (provider instanceof ExistingProvider) {
                    return getInternal(((ExistingProvider) provider).getExisting(), args);
                }
                return getInstance(provider, args);
            } finally {
                popIfMatches(token);
            }
        }

        protected virtual Object resolveInternal(final String token, final Object args) {
            validateAndAddPath(token);
            try {
                Provider provider = module.getProvider(token);
                if (provider instanceof ExistingProvider) {
                    return resolveInternal(((ExistingProvider) provider).getExisting(), args);
                }
                return newInstance(provider, args);
            } finally {
                popIfMatches(token);
            }
        }

        protected Object newInstance(final Provider provider, final Object args) {
            return provider.resolve(this, args);
        }

        protected virtual Object inject(final Object instance) {
            if (instance instanceof Injectable) {
                ((Injectable) instance).inject(this);
            }
            return instance;
        }

        protected virtual void validateAndAddPath(final String token) {
            Validate.isTrue(
                !resolutionPath.contains(token),
                new CircularDependencyException(
                    String.format(
                        CIRCULAR_DEPENDENCY_MESSAGE,
                        new List<String>{ token, String.join(resolutionPath, ' -> ') + ' -> ' + token }
                    )
                )
            );

            resolutionPath.add(token);
        }

        private void startResolution() {
            inCall = true;
            resolutionPath.clear();
        }

        private void endResolution() {
            inCall = false;
            resolutionPath.clear();
        }

        private void popIfMatches(String token) {
            Integer lastIndex = resolutionPath.size() - 1;
            if (!resolutionPath.isEmpty() && resolutionPath[lastIndex].equals(token)) {
                resolutionPath.remove(lastIndex);
            }
        }
    }

    public virtual class ModuleRef extends Container {
        protected final Map<String, Object> cache = new Map<String, Object>();

        public ModuleRef(final Module module) {
            super(null, module);
        }

        public virtual ScopeRef createScope() {
            return new ScopeRef(this, module);
        }

        public virtual void replace(final Provider newProvider) {
            Validate.isTrue(newProvider != null, new InvalidProviderException(NULL_PROVIDER_MESSAGE));

            String token = newProvider.getToken();
            Validate.isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            module.replace(newProvider);
            cache.remove(token);
        }

        public virtual void refresh() {
            module.register();
            clearCache();
        }

        public virtual void clearCache() {
            cache.clear();
        }

        protected virtual override Object getInstance(final Provider provider, final Object args) {
            String key = provider.getToken();
            if (args == null && provider.getScope() == Scope.SINGLETON && cache.containsKey(key)) {
                return cache.get(key);
            }
            Object instance = newInstance(provider, args);
            if (args == null && provider.getScope() == Scope.SINGLETON) {
                cache.put(key, instance);
            }
            try {
                return inject(instance);
            } catch (Exception e) {
                if (args == null && provider.getScope() == Scope.SINGLETON) {
                    cache.remove(key);
                }
                throw e;
            }
        }

        public virtual override Object resolve(final String token, final Object args) {
            Object instance = super.resolve(token, args);
            return inject(instance);
        }

        protected override Boolean hasInCache(final String token) {
            return cache.containsKey(token);
        }

        protected override void validateAndAddPath(String token) {
            if (hasInCache(token)) {
                return;
            }
            super.validateAndAddPath(token);
        }
    }

    public virtual class ScopeRef extends Container {
        protected final Map<String, Object> scopedCache = new Map<String, Object>();

        protected ScopeRef(final ModuleRef parent, final Module module) {
            super(parent, module);
        }

        protected virtual override Object getInstance(final Provider provider, final Object args) {
            if (provider.getScope() === Scope.SCOPED) {
                String key = provider.getToken();
                if (args == null && scopedCache.containsKey(key)) {
                    return scopedCache.get(key);
                }
                Object instance = newInstance(provider, args);
                if (args == null) {
                    scopedCache.put(key, instance);
                }
                try {
                    return inject(instance);
                } catch (Exception e) {
                    if (args == null) {
                        scopedCache.remove(key);
                    }
                    throw e;
                }
            }
            return parent.getInstance(provider, args);
        }

        public override Object resolve(final String token, final Object args) {
            Object instance = super.resolve(token, args);
            return inject(instance);
        }

        protected override Object getInternal(final String token, final Object args) {
            refreshIfModuleChanged();
            return super.getInternal(token, args);
        }

        protected override Object resolveInternal(final String token, final Object args) {
            refreshIfModuleChanged();
            return super.resolveInternal(token, args);
        }

        private void refreshIfModuleChanged() {
            ModuleRef currentRef = Di.getModuleRef(module.getToken());
            if (currentRef !== parent) {
                parent = currentRef;
                module = currentRef.getModule();
                clearCache();
            }
        }

        public virtual void clearCache() {
            scopedCache.clear();
        }

        protected override Boolean hasInCache(final String token) {
            return scopedCache.containsKey(token);
        }

        protected override void validateAndAddPath(String token) {
            if (hasInCache(token) || parent.hasInCache(token)) {
                return;
            }
            super.validateAndAddPath(token);
        }
    }

    public virtual class ModuleImport {
        protected final String token;
        protected Boolean isEager = false;
        protected Module cachedModule;

        protected ModuleImport(final String token) {
            Validate.isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));

            this.token = token;
        }

        protected ModuleImport(final Module module) {
            Validate.isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

            token = module.getToken();
            cachedModule = module;
        }

        public String getToken() {
            return token;
        }

        public virtual ModuleImport immediately() {
            isEager = true;
            // eagerly registers the module if it isn't already
            if (cachedModule != null) {
                Di.getModuleRef(cachedModule);
            } else {
                Di.getModuleRef(token).getModule();
            }
            return this;
        }

        public virtual Module resolve() {
            if (cachedModule != null) {
                cachedModule.register();
                return cachedModule;
            }
            return Di.getModuleRef(token).getModule();
        }

        public Boolean equals(Object obj) {
            if (obj instanceof ModuleImport) {
                return ((ModuleImport) obj).getToken().equals(token);
            }
            return false;
        }

        public Integer hashCode() {
            return System.hashCode(token);
        }
    }

    public enum Scope {
        SINGLETON,
        PROTOTYPE,
        SCOPED
    }

    public interface Factory {
        Object newInstance(final Container ref, final Object args);
    }

    public interface Injectable {
        /**
         * @description Called immediately after instantiation to inject dependencies.
         *
         * @param container The module reference to resolve dependencies from
         */
        void inject(final Container container);
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
    public virtual class CircularDependencyException extends DiException {
    }
}
