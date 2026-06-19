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
    private static final String MODULE_TOKEN_MISMATCH_MESSAGE =
        'Cannot replace module "{0}" with module "{1}". ' + 'The replacement module token must match the target token.';
    private static final String MODULE_CONTEXT_MISMATCH_MESSAGE =
        'Module instance "{0}" is already registered in another application context. ' +
        'Create a separate module instance per context.';
    private static final String UNKNOWN_EXPORT_MESSAGE =
        'Cannot export "{0}" from the "{1}" module. This provider ' +
        'has not been registered in the module.' +
        '\nPlease ensure "{0}" is listed in the "providers" array before exporting it.';
    private static final String DUPLICATE_GLOBAL_PROVIDER_MESSAGE =
        'Cannot export global provider "{0}" from the "{1}" module. ' +
        'This token is already exported by the "{2}" module.';
    private static final String AMBIGUOUS_IMPORTED_PROVIDER_MESSAGE =
        'Cannot resolve provider "{0}" in the "{1}" module context. ' +
        'This token is exported by both "{2}" and "{3}".';
    private static final String NULL_PROVIDER_MESSAGE = 'The provider cannot be null.';
    private static final String NULL_PROVIDER_FACTORY_MESSAGE = 'The provider factory cannot be null.';
    private static final String NULL_MODULE_IMPORT_MESSAGE = 'The module import cannot be null.';
    private static final String INVALID_PROVIDER_TOKEN_MESSAGE = 'Invalid provider token. The token cannot be null.';
    private static final String INVALID_MODULE_REPLACEMENT_MESSAGE = 'Cannot replace module with null. Please provide a valid module instance.';
    private static final String PROTOTYPE_SCOPE_ERROR_MESSAGE =
        'Cannot retrieve prototype-scoped provider "{0}" ' +
        'using get(). Prototype-scoped providers create a new instance on each request.' +
        '\nUse resolve() method instead to get a new instance.';
    private static final String SCOPED_ROOT_ACCESS_ERROR_MESSAGE =
        'Cannot access scoped provider "{0}" from the root module. ' +
        'Scoped providers require an active scope cache.' +
        '\nUse createScope() method instead to create a ScopeRef.';
    private static final String NULL_SCOPE_CONTEXT_MESSAGE = 'Cannot create a scope with a null ScopeContext.';
    private static final String INVALID_PROVIDER_CONFIG_MESSAGE =
        'Invalid provider configuration for token "{0}". ' +
        'The provider must be one of: ClassProvider, ValueProvider, FactoryProvider or ExistingProvider.';
    private static final String CIRCULAR_DEPENDENCY_MESSAGE = 'Circular dependency detected for provider "{0}". Resolution path: {1}';
    private static final String CIRCULAR_REEXPORT_MESSAGE = 'Circular module reexport detected for module "{0}". Registration path: {1}';
    private static final String CIRCULAR_MODULE_IMPORT_MESSAGE = 'Circular module import detected for module "{0}".';
    private static final String INVALID_OPERATION_MESSAGE = 'This operation is not supported for this provider type.';
    private static final String INVALID_DEVELOPER_NAME_MESSAGE = 'The developer name for a metadata provider cannot be blank.';
    private static final String MISSING_METADATA_PROVIDER_MESSAGE = 'Provider for token "{0}" is configured to use Custom Metadata record "{1}", but a record with that DeveloperName was not found.';
    private static final String INACTIVE_METADATA_PROVIDER_MESSAGE = 'Provider for token "{0}" is defined by Custom Metadata record "{1}", but the record is inactive.';
    private static final String INVALID_FACTORY_CLASS_MESSAGE = 'Class "{0}" provided by factory provider "{1}" does not implement the Di.Factory interface.';
    private static final String INVALID_METADATA_SCOPE_MESSAGE =
        'Invalid metadata scope "{0}" for provider "{1}" using Custom Metadata record "{2}". ' +
        'Allowed values are SINGLETON, PROTOTYPE, and SCOPED.';
    private static final String ARGS_NOT_SUPPORTED_MESSAGE = 'Arguments are only supported for FactoryProvider.';
    private static final String GET_ARGS_NOT_SUPPORTED_MESSAGE = 'Runtime arguments are not supported by get(). Use resolve() when passing arguments.';
    private static final String NOT_INJECTABLE_MESSAGE = 'The instance does not implement the Di.Injectable interface.';

    private static final ApplicationContext DEFAULT_CONTEXT = new ApplicationContext();

    @TestVisible
    private static Boolean hasGlobalLoadBeenAttempted {
        get {
            return DEFAULT_CONTEXT.hasGlobalLoadBeenAttempted;
        }
    }

    @TestVisible
    private Di() {
    }

    public static ApplicationContext createContext() {
        return new ApplicationContext();
    }

    public static ModuleRef getModuleRef(final Module module) {
        return DEFAULT_CONTEXT.getModuleRef(module);
    }

    public static ModuleRef getModuleRef(final String token) {
        return DEFAULT_CONTEXT.getModuleRef(token);
    }

    public static ModuleRef getModuleRef(final Type moduleType) {
        return DEFAULT_CONTEXT.getModuleRef(moduleType);
    }

    public static ModuleRef addModule(final Module module) {
        return DEFAULT_CONTEXT.addModule(module);
    }

    public static void replaceModule(final String token, final Module newModule) {
        DEFAULT_CONTEXT.replaceModule(token, newModule);
    }

    public static void replaceModule(final Type token, final Module newModule) {
        DEFAULT_CONTEXT.replaceModule(token, newModule);
    }

    public static ModuleImport import(final Module module) {
        return new ModuleImport(module);
    }

    public static ModuleImport import(final String token) {
        return new ModuleImport(token);
    }

    public static ModuleImport import(final Type token) {
        return DEFAULT_CONTEXT.import(token);
    }

    public static void clear() {
        DEFAULT_CONTEXT.clear();
    }

    @TestVisible
    private static void mockGlobalModules(final Iterable<DI_GlobalModule__mdt> mockModules) {
        DEFAULT_CONTEXT.mockGlobalModules(mockModules);
    }

    @TestVisible
    private static void mockProviders(final Map<String, DI_Provider__mdt> providerByDeveloperName) {
        DEFAULT_CONTEXT.mockProviders(providerByDeveloperName);
    }

    public virtual class ApplicationContext {
        private final Map<String, ModuleRef> moduleRegistry = new Map<String, ModuleRef>();
        private final Map<String, ModuleRef> globalModuleRegistry = new Map<String, ModuleRef>();
        private final Map<String, ProviderBinding> globalProviderBindings = new Map<String, ProviderBinding>();
        private final Map<String, Map<String, ProviderBinding>> visibleProvidersByModuleKey = new Map<String, Map<String, ProviderBinding>>();
        private final List<String> moduleRegistrationPath = new List<String>();

        @TestVisible
        private Boolean hasGlobalLoadBeenAttempted = false;
        private Integer graphRevision = 0;
        private Integer globalBindingIndexRevision = -1;
        private Boolean hasGlobalLoadFailed = false;
        private Boolean isCompiled = false;
        private Boolean isLoadingGlobalModules = false;
        private Iterable<DI_GlobalModule__mdt> mockGlobalModules;
        private Map<String, DI_Provider__mdt> mockProviders;
        private Map<String, DI_Provider__mdt> providerDefinitionByDeveloperName;

        private final Map<String, ModuleRef> globalRegistry {
            get {
                if (!hasGlobalLoadBeenAttempted && !isLoadingGlobalModules) {
                    loadGlobalModules();
                }
                return globalModuleRegistry;
            }
        }

        public virtual ModuleRef getModuleRef(final Module module) {
            isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

            String token = module.getToken();
            ModuleRef ref = findRegisteredModuleRef(module);
            if (ref == null) {
                return addModule(module);
            }

            isTrue(
                ref.getModule() === module,
                new InvalidModuleException(String.format(MODULE_ALREADY_REGISTERED_MESSAGE, new List<String>{ token }))
            );
            return ref;
        }

        public virtual ModuleRef getModuleRef(final String token) {
            isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));

            ModuleRef ref = findModuleRef(token);
            if (ref != null) {
                return ref;
            }

            Module module = create(token);
            return findModuleRef(module.getToken()) ?? addModule(module);
        }

        public virtual ModuleRef getModuleRef(final Type moduleType) {
            return getModuleRef(moduleType?.getName());
        }

        public virtual ModuleRef addModule(final Module module) {
            isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));
            markGraphChanged();

            String token = module.getToken();
            Map<String, ModuleRef> registry = module.isGlobal() ? globalRegistry : moduleRegistry;
            isTrue(
                !registry.containsKey(token),
                new InvalidModuleException(String.format(MODULE_ALREADY_REGISTERED_MESSAGE, new List<String>{ token }))
            );

            ModuleRef ref = new ModuleRef(this, module);
            registry.put(token, ref);
            try {
                module.register(this);
                if (module.isGlobal()) {
                    validateGlobalProviderBindings();
                }
                return ref;
            } catch (Exception exc) {
                if (registry.get(token) === ref) {
                    registry.remove(token);
                }
                module.clearContext(this);
                markGraphChanged();
                throw exc;
            }
        }

        public virtual void replaceModule(final String token, final Module newModule) {
            isTrue(newModule != null, new InvalidModuleException(INVALID_MODULE_REPLACEMENT_MESSAGE));
            isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));
            isTrue(
                token.equals(newModule.getToken()),
                new InvalidModuleException(
                    String.format(MODULE_TOKEN_MISMATCH_MESSAGE, new List<String>{ token, newModule.getToken() })
                )
            );

            markGraphChanged();
            ModuleRef oldRef = getModuleRef(token);
            Module oldModule = oldRef.getModule();
            String oldRegistryToken = oldRef.registryToken;
            isTrue(
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

            Map<String, ModuleRef> registry = oldModule.isGlobal() ? globalRegistry : moduleRegistry;
            ModuleRef newRef = new ModuleRef(this, newModule);
            newRef.registryToken = token;
            newModule.register(this);
            if (oldModule.isGlobal()) {
                if (!oldRegistryToken.equals(token)) {
                    registry.remove(oldRegistryToken);
                }
                registry.put(token, newRef);
                try {
                    validateGlobalProviderBindings();
                    clearAllModuleCaches();
                } catch (Exception exc) {
                    registry.remove(token);
                    registry.put(oldRegistryToken, oldRef);
                    newModule.clearContext(this);
                    markGraphChanged();
                    throw exc;
                }
            } else {
                if (!oldRegistryToken.equals(token)) {
                    registry.remove(oldRegistryToken);
                }
                registry.put(token, newRef);
                clearAllModuleCaches();
            }
        }

        public virtual void replaceModule(final Type token, final Module newModule) {
            replaceModule(token?.getName(), newModule);
        }

        public virtual ModuleImport import(final Module module) {
            return new ModuleImport(this, module);
        }

        public virtual ModuleImport import(final String token) {
            return new ModuleImport(this, token);
        }

        public virtual ModuleImport import(final Type token) {
            return import(token?.getName());
        }

        public virtual ApplicationContext compile() {
            invalidateCompiledGraph();
            Map<String, Map<String, ProviderBinding>> compiledProvidersByModuleKey = new Map<String, Map<String, ProviderBinding>>();
            globalRegistry.size();

            for (ModuleRef ref : snapshotModuleRefs(moduleRegistry)) {
                compileModule(ref.getModule(), compiledProvidersByModuleKey, new Set<String>());
            }
            for (ModuleRef ref : snapshotModuleRefs(globalModuleRegistry)) {
                compileModule(ref.getModule(), compiledProvidersByModuleKey, new Set<String>());
            }
            addImplicitGlobalProviders(compiledProvidersByModuleKey);

            visibleProvidersByModuleKey.putAll(compiledProvidersByModuleKey);
            isCompiled = true;
            return this;
        }

        public virtual void clear() {
            markGraphChanged();
            clearModuleContexts(moduleRegistry);
            clearModuleContexts(globalModuleRegistry);
            moduleRegistry.clear();
            globalModuleRegistry.clear();
            globalProviderBindings.clear();
            globalBindingIndexRevision = graphRevision;
            mockGlobalModules = null;
            hasGlobalLoadBeenAttempted = false;
            hasGlobalLoadFailed = false;
            mockProviders = null;
            providerDefinitionByDeveloperName = null;
        }

        @TestVisible
        private void mockGlobalModules(final Iterable<DI_GlobalModule__mdt> mockModules) {
            markGraphChanged();
            mockGlobalModules = mockModules;
            hasGlobalLoadBeenAttempted = false;
            hasGlobalLoadFailed = false;
        }

        @TestVisible
        private void mockProviders(final Map<String, DI_Provider__mdt> providerByDeveloperName) {
            markGraphChanged();
            providerDefinitionByDeveloperName = null;
            mockProviders = providerByDeveloperName;
        }

        protected Module resolveImport(final ModuleImport moduleImport) {
            if (moduleImport.cachedModule != null) {
                return getModuleRef(moduleImport.cachedModule).getModule();
            }
            return getModuleRef(moduleImport.getToken()).getModule();
        }

        private ProviderBinding getVisibleProviderBinding(final Module module, final String token) {
            Map<String, ProviderBinding> visibleProviders = visibleProvidersByModuleKey.get(getModuleKey(module));
            return visibleProviders == null ? null : visibleProviders.get(token);
        }

        private ProviderBinding indexVisibleProviderBinding(
            final Module module,
            final String token,
            final ProviderBinding binding
        ) {
            String moduleKey = getModuleKey(module);
            Map<String, ProviderBinding> visibleProviders = visibleProvidersByModuleKey.get(moduleKey);
            if (visibleProviders == null) {
                visibleProviders = new Map<String, ProviderBinding>();
                visibleProvidersByModuleKey.put(moduleKey, visibleProviders);
            }
            visibleProviders.put(token, binding);
            return binding;
        }

        private Boolean hasCompiledGraph() {
            return isCompiled;
        }

        private ModuleRef findModuleRef(String token) {
            ModuleRef ref = moduleRegistry.get(token);
            if (ref == null) {
                ref = globalRegistry.get(token);
            }
            return ref;
        }

        private ModuleRef findRegisteredModuleRef(final Module module) {
            return getLoadedRegistry(module).get(module.getToken());
        }

        protected Map<String, ModuleRef> getLoadedRegistry(final Module module) {
            return module.isGlobal() ? globalRegistry : moduleRegistry;
        }

        private void clearModuleContexts(final Map<String, ModuleRef> registry) {
            for (ModuleRef ref : registry.values()) {
                ref.getModule().clearContext(this);
            }
        }

        private void invalidateCompiledGraph() {
            visibleProvidersByModuleKey.clear();
            isCompiled = false;
        }

        private void markGraphChanged() {
            graphRevision++;
            invalidateCompiledGraph();
        }

        private List<ModuleRef> snapshotModuleRefs(final Map<String, ModuleRef> registry) {
            return new List<ModuleRef>(registry.values());
        }

        private String getModuleKey(final Module module) {
            return (module.isGlobal() ? 'global:' : 'local:') + module.getToken();
        }

        private Map<String, ProviderBinding> compileModule(
            final Module module,
            final Map<String, Map<String, ProviderBinding>> compiledProvidersByModuleKey,
            final Set<String> compilingModuleKeys
        ) {
            String moduleKey = getModuleKey(module);
            if (compiledProvidersByModuleKey.containsKey(moduleKey)) {
                return compiledProvidersByModuleKey.get(moduleKey);
            }

            isTrue(
                !compilingModuleKeys.contains(moduleKey),
                new InvalidModuleException(
                    String.format(CIRCULAR_MODULE_IMPORT_MESSAGE, new List<String>{ module.getToken() })
                )
            );
            compilingModuleKeys.add(moduleKey);
            try {
                Map<String, ProviderBinding> visibleProviders = new Map<String, ProviderBinding>();
                Set<String> localProviderTokens = new Set<String>();
                ModuleRef owner = getRegisteredModuleRef(module);

                for (Provider provider : module.providers.values()) {
                    localProviderTokens.add(provider.getToken());
                    visibleProviders.put(provider.getToken(), new ProviderBinding(provider, owner));
                }

                Set<ModuleImport> searchScope = new Set<ModuleImport>();
                searchScope.addAll(module.imports() ?? new Set<ModuleImport>());
                searchScope.addAll(module.reexports() ?? new Set<ModuleImport>());
                for (ModuleImport moduleImport : searchScope) {
                    Module importedModule = resolveImport(moduleImport);
                    Map<String, ProviderBinding> importedProviders = compileModule(
                        importedModule,
                        compiledProvidersByModuleKey,
                        compilingModuleKeys
                    );
                    for (String token : importedModule.exports) {
                        if (localProviderTokens.contains(token)) {
                            continue;
                        }
                        ProviderBinding provider = importedProviders.get(token);
                        isTrue(
                            provider != null,
                            new UnknownExportException(
                                String.format(
                                    UNKNOWN_EXPORT_MESSAGE,
                                    new List<String>{ token, importedModule.getToken() }
                                )
                            )
                        );
                        ProviderBinding selectedProvider = visibleProviders.get(token);
                        if (selectedProvider == null) {
                            visibleProviders.put(token, provider);
                            continue;
                        }
                        isTrue(
                            selectedProvider.getOwner() === provider.getOwner(),
                            new InvalidProviderException(
                                String.format(
                                    AMBIGUOUS_IMPORTED_PROVIDER_MESSAGE,
                                    new List<String>{
                                        token,
                                        module.getToken(),
                                        selectedProvider.getOwner().getModule().getToken(),
                                        provider.getOwner().getModule().getToken()
                                    }
                                )
                            )
                        );
                    }
                }

                compiledProvidersByModuleKey.put(moduleKey, visibleProviders);
                return visibleProviders;
            } finally {
                compilingModuleKeys.remove(moduleKey);
            }
        }

        private void addImplicitGlobalProviders(
            final Map<String, Map<String, ProviderBinding>> compiledProvidersByModuleKey
        ) {
            Map<String, ProviderBinding> globalBindings = getGlobalProviderBindings(false);
            for (String moduleKey : compiledProvidersByModuleKey.keySet()) {
                Map<String, ProviderBinding> visibleProviders = compiledProvidersByModuleKey.get(moduleKey);
                for (String token : globalBindings.keySet()) {
                    if (!visibleProviders.containsKey(token)) {
                        visibleProviders.put(token, globalBindings.get(token));
                    }
                }
            }
        }

        private void loadGlobalModules() {
            Map<String, ModuleRef> previousGlobalRegistry = new Map<String, ModuleRef>(globalModuleRegistry);
            Boolean previousLoadAttempted = hasGlobalLoadBeenAttempted;
            isLoadingGlobalModules = true;
            try {
                for (DI_GlobalModule__mdt moduleDef : getGlobalModuleDefinitions()) {
                    if (!moduleDef.IsActive__c) {
                        continue;
                    }
                    Module module = create(moduleDef.ModuleClass__c);
                    isTrue(
                        module.isGlobal(),
                        new InvalidModuleException(
                            String.format(INVALID_GLOBAL_MODULE_MESSAGE, new List<String>{ module.getToken() })
                        )
                    );

                    addModule(module);
                }
                hasGlobalLoadBeenAttempted = true;
                hasGlobalLoadFailed = false;
            } catch (Exception exc) {
                globalModuleRegistry.clear();
                globalModuleRegistry.putAll(previousGlobalRegistry);
                hasGlobalLoadBeenAttempted = previousLoadAttempted;
                hasGlobalLoadFailed = true;
                markGraphChanged();
                throw exc;
            } finally {
                isLoadingGlobalModules = false;
            }
        }

        private Iterable<DI_GlobalModule__mdt> getGlobalModuleDefinitions() {
            return shouldUseMock(mockGlobalModules) ? mockGlobalModules : DI_GlobalModule__mdt.getAll().values();
        }

        protected Map<String, DI_Provider__mdt> getProviderDefinitions() {
            if (providerDefinitionByDeveloperName == null) {
                providerDefinitionByDeveloperName = shouldUseMock(mockProviders)
                    ? mockProviders
                    : DI_Provider__mdt.getAll();
            }
            return providerDefinitionByDeveloperName;
        }

        private void validateGlobalProviderBindings() {
            getGlobalProviderBindings(false);
        }

        private ProviderBinding getImplicitGlobalProviderBinding(final String token) {
            return getGlobalProviderBindings(!hasGlobalLoadFailed).get(token);
        }

        private Map<String, ProviderBinding> getGlobalProviderBindings(final Boolean loadGlobals) {
            if (loadGlobals) {
                globalRegistry.size();
            }
            if (globalBindingIndexRevision == graphRevision) {
                return globalProviderBindings;
            }

            Map<String, ProviderBinding> candidateBindings = new Map<String, ProviderBinding>();
            for (ModuleRef ref : globalModuleRegistry.values()) {
                Module module = ref.getModule();
                for (String token : module.exports ?? new Set<String>()) {
                    addGlobalProviderBinding(candidateBindings, module, token);
                }
            }

            globalProviderBindings.clear();
            globalProviderBindings.putAll(candidateBindings);
            globalBindingIndexRevision = graphRevision;
            return globalProviderBindings;
        }

        private void addGlobalProviderBinding(
            final Map<String, ProviderBinding> globalBindings,
            final Module module,
            final String token
        ) {
            isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            ProviderBinding provider = module.getProviderBinding(token, false);
            isTrue(
                provider != null,
                new UnknownExportException(
                    String.format(UNKNOWN_EXPORT_MESSAGE, new List<String>{ token, module.getToken() })
                )
            );

            ProviderBinding existingProvider = globalBindings.get(token);
            String existingModuleToken = existingProvider == null
                ? null
                : existingProvider.getOwner().getModule().getToken();
            isTrue(
                existingProvider == null || existingProvider.getOwner() === provider.getOwner(),
                new InvalidProviderException(
                    String.format(
                        DUPLICATE_GLOBAL_PROVIDER_MESSAGE,
                        new List<String>{ token, module.getToken(), existingModuleToken }
                    )
                )
            );

            globalBindings.put(token, provider);
        }

        protected void clearAllModuleCaches() {
            for (ModuleRef ref : moduleRegistry.values()) {
                ref.clearCache();
            }
            for (ModuleRef ref : globalModuleRegistry.values()) {
                ref.clearCache();
            }
        }

        protected ModuleRef getRegisteredModuleRef(final Module module) {
            ModuleRef ref = findRegisteredModuleRef(module);
            return ref ?? getModuleRef(module);
        }

        protected void assertNoCircularReexport(final String token) {
            isTrue(
                !moduleRegistrationPath.contains(token),
                new InvalidModuleException(
                    String.format(
                        CIRCULAR_REEXPORT_MESSAGE,
                        new List<String>{ token, String.join(moduleRegistrationPath, ' -> ') + ' -> ' + token }
                    )
                )
            );
        }

        protected void pushRegistration(final String token) {
            moduleRegistrationPath.add(token);
        }

        protected void popRegistration() {
            moduleRegistrationPath.remove(moduleRegistrationPath.size() - 1);
        }
    }

    private static Module create(final String token) {
        Type moduleType = Type.forName(token);
        isTrue(
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
        isTrue(
            raw instanceof Module,
            new InvalidModuleException(String.format(INVALID_MODULE_MESSAGE, new List<String>{ token }))
        );

        Module module = (Module) raw;
        return module;
    }

    private static Object instantiate(final String typeName) {
        isTrue(
            typeName != null,
            new InvalidClassException(String.format(INVALID_CLASS_MESSAGE, new List<String>{ 'null' }))
        );

        Type providedType = Type.forName(typeName);
        isTrue(
            providedType != null,
            new InvalidClassException(String.format(INVALID_CLASS_MESSAGE, new List<String>{ typeName }))
        );

        return instantiate(providedType);
    }

    private static Object instantiate(final Type type) {
        isTrue(type != null, new InvalidClassException(NULL_PROVIDER_FACTORY_MESSAGE));
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
        isTrue(
            raw instanceof Factory,
            new InvalidClassException(String.format(INVALID_FACTORY_CLASS_MESSAGE, new List<String>{ typeName, token }))
        );

        return (Factory) raw;
    }

    private static Boolean shouldUseMock(final Object mock) {
        return Test.isRunningTest() && mock != null;
    }

    private static void isTrue(final Boolean condition, final Exception exc) {
        if (condition ?? false) {
            return;
        }
        throw exc;
    }

    private class ProviderBinding {
        private final Provider provider;
        private final ModuleRef owner;

        private ProviderBinding(final Provider provider, final ModuleRef owner) {
            this.provider = provider;
            this.owner = owner;
        }

        private Provider getProvider() {
            return provider;
        }

        private ModuleRef getOwner() {
            return owner;
        }
    }

    private class ResolutionContext {
        private final Boolean inCall;
        private final List<String> resolutionPath;

        private ResolutionContext(final Boolean inCall, final List<String> resolutionPath) {
            this.inCall = inCall;
            this.resolutionPath = new List<String>(resolutionPath);
        }
    }

    public abstract inherited sharing class Module {
        protected final String token;
        protected final Map<String, Provider> providers = new Map<String, Provider>();
        protected final Set<String> exports = new Set<String>();
        protected Boolean isGlobal = false;
        private ApplicationContext context;

        protected Module() {
            token = String.valueOf(this).substringBefore(':');
        }

        protected Module(final String token) {
            isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));

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

        private ApplicationContext getContext() {
            return context ?? DEFAULT_CONTEXT;
        }

        private void setContext(final ApplicationContext context) {
            isTrue(
                this.context == null || this.context === context,
                new InvalidModuleException(String.format(MODULE_CONTEXT_MISMATCH_MESSAGE, new List<String>{ token }))
            );
            this.context = context;
        }

        private void clearContext(final ApplicationContext context) {
            if (this.context === context) {
                this.context = null;
            }
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
            return getProviderBinding(token).getProvider();
        }

        private ProviderBinding getProviderBinding(final String token) {
            return getProviderBinding(token, true);
        }

        private ProviderBinding getProviderBinding(final String token, final Boolean includeGlobals) {
            isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            ProviderBinding visibleProvider = getContext().getVisibleProviderBinding(this, token);
            if (visibleProvider != null) {
                return visibleProvider;
            }
            isTrue(
                !getContext().hasCompiledGraph(),
                new UnknownProviderException(
                    String.format(UNKNOWN_PROVIDER_MESSAGE, new List<String>{ token, getToken() })
                )
            );

            // First check local definitions
            if (hasProvider(token)) {
                return getContext()
                    .indexVisibleProviderBinding(
                        this,
                        token,
                        new ProviderBinding(providers.get(token), getContext().getRegisteredModuleRef(this))
                    );
            }

            // Then check imported and re-exported modules
            Set<ModuleImport> searchScope = new Set<ModuleImport>();
            if (imports() != null) {
                searchScope.addAll(imports());
            }
            if (reexports() != null) {
                searchScope.addAll(reexports());
            }

            ProviderBinding selectedProvider;
            for (ModuleImport moduleImport : searchScope) {
                Module module = getContext().resolveImport(moduleImport);
                if (!module.hasExport(token)) {
                    continue;
                }
                ProviderBinding provider = module.getProviderBinding(token);
                if (selectedProvider == null) {
                    selectedProvider = provider;
                    continue;
                }
                isTrue(
                    selectedProvider.getOwner() === provider.getOwner(),
                    new InvalidProviderException(
                        String.format(
                            AMBIGUOUS_IMPORTED_PROVIDER_MESSAGE,
                            new List<String>{
                                token,
                                getToken(),
                                selectedProvider.getOwner().getModule().getToken(),
                                provider.getOwner().getModule().getToken()
                            }
                        )
                    )
                );
            }
            if (selectedProvider != null) {
                return getContext().indexVisibleProviderBinding(this, token, selectedProvider);
            }

            // Finally check implicit global module exports.
            if (includeGlobals) {
                ProviderBinding globalProvider = getContext().getImplicitGlobalProviderBinding(token);
                if (globalProvider != null) {
                    return getContext().indexVisibleProviderBinding(this, token, globalProvider);
                }
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
            isTrue(newProvider != null, new InvalidProviderException(NULL_PROVIDER_MESSAGE));

            String token = newProvider.getToken();
            isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));
            isTrue(
                hasProvider(token),
                new UnknownProviderException(
                    String.format(UNKNOWN_PROVIDER_MESSAGE, new List<String>{ token, getToken() })
                )
            );

            providers.put(token, newProvider);
            return this;
        }

        protected virtual void register(final ApplicationContext context) {
            setContext(context);
            context.pushRegistration(getToken());
            try {
                registerInternal();
            } finally {
                context.popRegistration();
            }
        }

        private void registerInternal() {
            providers.clear();
            exports.clear();

            for (Provider provider : providers() ?? new Set<Provider>()) {
                providers.put(provider.getToken(), provider);
            }

            for (String token : exports() ?? new Set<String>()) {
                isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));
                isTrue(
                    hasProvider(token),
                    new UnknownExportException(
                        String.format(UNKNOWN_EXPORT_MESSAGE, new List<String>{ token, getToken() })
                    )
                );

                exports.add(token);
            }

            for (ModuleImport moduleImport : imports() ?? new Set<ModuleImport>()) {
                if (moduleImport.isEager) {
                    getContext().resolveImport(moduleImport);
                }
            }

            for (ModuleImport reexport : reexports() ?? new Set<ModuleImport>()) {
                String reexportToken = reexport.getToken();
                getContext().assertNoCircularReexport(reexportToken);
                Module reexportedModule = getContext().resolveImport(reexport);
                getContext().assertNoCircularReexport(reexportedModule.getToken());
                for (String token : reexportedModule.exports) {
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
            isTrue(moduleImport != null, new InvalidModuleException(NULL_MODULE_IMPORT_MESSAGE));

            dynamicImports.add(moduleImport);
            return this;
        }

        public DynamicModule addProvider(final Provider provider) {
            isTrue(provider != null, new InvalidProviderException(NULL_PROVIDER_MESSAGE));

            dynamicProviders.put(provider.getToken(), provider);
            return this;
        }

        public DynamicModule addExport(final String token) {
            isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            dynamicExports.add(token);
            return this;
        }

        public DynamicModule addReexport(final ModuleImport moduleImport) {
            isTrue(moduleImport != null, new InvalidModuleException(NULL_MODULE_IMPORT_MESSAGE));

            dynamicReexports.add(moduleImport);
            return this;
        }
    }

    public virtual inherited sharing class ProviderBuilder {
        protected final String token;

        protected ProviderBuilder(final String token) {
            isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

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
            return new FactoryProvider(token, factoryType);
        }

        public virtual FactoryProvider useFactory(final Type factoryType) {
            return new FactoryProvider(token, factoryType);
        }

        public virtual ExistingProvider useExisting(final String existingToken) {
            return new ExistingProvider(token, existingToken);
        }

        public virtual ExistingProvider useExisting(final Type existingToken) {
            return new ExistingProvider(token, existingToken);
        }

        public virtual CustomMetadataTypesProvider useMetadata(final String developerName) {
            return new CustomMetadataTypesProvider(token, developerName);
        }
    }

    public abstract inherited sharing class Provider {
        protected final String token;
        protected Scope scopeType = Scope.SINGLETON;

        protected Provider(String token) {
            isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

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
            isTrue(
                type != null,
                new InvalidProviderException(String.format(INVALID_PROVIDER_TYPE_MESSAGE, new List<String>{ token }))
            );

            typeName = type;
        }

        public ClassProvider(final String token, final Type type) {
            this(token, type?.getName());
        }

        public ClassProvider(final Type token, final String type) {
            this(token?.getName(), type);
        }

        public ClassProvider(final Type token, final Type type) {
            this(token?.getName(), type?.getName());
        }

        public override Object resolve(final Container container, final Object args) {
            isTrue(args == null, new InvalidProviderException(ARGS_NOT_SUPPORTED_MESSAGE));
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

        public ValueProvider(final Type token, final Object value) {
            this(token?.getName(), value);
        }

        public override Object resolve(final Container container, final Object args) {
            isTrue(args == null, new InvalidProviderException(ARGS_NOT_SUPPORTED_MESSAGE));
            return value;
        }
    }

    public virtual inherited sharing class FactoryProvider extends Provider {
        protected final Factory factory;

        public FactoryProvider(final String token, final Factory factory) {
            super(token);
            isTrue(factory != null, new InvalidProviderException(NULL_PROVIDER_FACTORY_MESSAGE));

            this.factory = factory;
        }

        public FactoryProvider(final String token, final String factoryType) {
            this(token, validateFactory(instantiate(factoryType), factoryType, token));
        }

        public FactoryProvider(final String token, final Type factoryType) {
            this(token, factoryType?.getName());
        }

        public FactoryProvider(final Type token, final Factory factory) {
            this(token?.getName(), factory);
        }

        public FactoryProvider(final Type token, final String factoryType) {
            this(token?.getName(), factoryType);
        }

        public FactoryProvider(final Type token, final Type factoryType) {
            this(token?.getName(), factoryType);
        }

        public override Object resolve(final Container container, final Object args) {
            return factory.newInstance(container, args);
        }
    }

    public virtual inherited sharing class ExistingProvider extends Provider {
        protected final String existing;

        public ExistingProvider(final String token, final String existing) {
            super(token);
            isTrue(existing != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            this.existing = existing;
        }

        public ExistingProvider(final String token, final Type existing) {
            this(token, existing?.getName());
        }

        public ExistingProvider(final Type token, final String existing) {
            this(token?.getName(), existing);
        }

        public ExistingProvider(final Type token, final Type existing) {
            this(token?.getName(), existing?.getName());
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
            isTrue(!String.isBlank(developerName), new InvalidProviderException(INVALID_DEVELOPER_NAME_MESSAGE));

            this.developerName = developerName;
        }

        public override Scope getScope() {
            return getScope(DEFAULT_CONTEXT);
        }

        protected Scope getScope(final ApplicationContext context) {
            Map<String, DI_Provider__mdt> providerDefinitionByDeveloperName = context.getProviderDefinitions();
            if (providerDefinitionByDeveloperName.containsKey(developerName)) {
                DI_Provider__mdt definition = providerDefinitionByDeveloperName.get(developerName);
                if (!String.isBlank(definition?.Scope__c)) {
                    return parseMetadataScope(definition);
                }
            }
            return super.getScope();
        }

        public String getExisting() {
            return getExisting(DEFAULT_CONTEXT);
        }

        protected String getExisting(final ApplicationContext context) {
            DI_Provider__mdt definition = getDefinition(context);
            return definition.Type__c == 'Existing' ? definition.Value__c : null;
        }

        private DI_Provider__mdt getDefinition(final ApplicationContext context) {
            DI_Provider__mdt definition = context.getProviderDefinitions().get(developerName);
            isTrue(
                definition != null,
                new InvalidProviderException(
                    String.format(MISSING_METADATA_PROVIDER_MESSAGE, new List<String>{ token, developerName })
                )
            );
            isTrue(
                definition.IsActive__c,
                new InvalidProviderException(
                    String.format(INACTIVE_METADATA_PROVIDER_MESSAGE, new List<String>{ token, developerName })
                )
            );
            return definition;
        }

        private Scope parseMetadataScope(final DI_Provider__mdt definition) {
            try {
                return Scope.valueOf(definition.Scope__c);
            } catch (Exception exc) {
                throw new InvalidProviderException(
                    String.format(
                        INVALID_METADATA_SCOPE_MESSAGE,
                        new List<String>{ definition.Scope__c, token, developerName }
                    )
                );
            }
        }

        public override Object resolve(final Container container, final Object args) {
            DI_Provider__mdt definition = getDefinition(container.context);
            Scope scopeType = !String.isBlank(definition.Scope__c) ? parseMetadataScope(definition) : this.scopeType;
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
                    provider = new FactoryProvider(token, value);
                }
                when 'Existing' {
                    throw new InvalidProviderException(INVALID_OPERATION_MESSAGE);
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
        protected ApplicationContext context;
        protected Container parent;
        protected Module module;
        protected final List<String> resolutionPath = new List<String>();
        protected Boolean inCall = false;

        protected Container(final ApplicationContext context, final Container parent, final Module module) {
            isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

            this.context = context ?? DEFAULT_CONTEXT;
            this.parent = parent;
            this.module = module;
        }

        protected abstract Object getInstance(final Provider provider, final Object args);

        protected abstract Boolean hasInCache(final String token);

        public Module getModule() {
            return module;
        }

        public virtual Object get(final String token, final Object args) {
            isTrue(args == null, new InvalidProviderException(GET_ARGS_NOT_SUPPORTED_MESSAGE));
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

        public virtual Object inject(final Object instance) {
            isTrue(instance instanceof Injectable, new InvalidClassException(NOT_INJECTABLE_MESSAGE));
            return autowire(instance);
        }

        protected virtual Object getInternal(final String token, final Object args) {
            validateAndAddPath(token);
            try {
                ProviderBinding binding = module.getProviderBinding(token);
                Provider provider = binding.getProvider();
                isTrue(
                    getProviderScope(provider) !== Scope.PROTOTYPE,
                    new InvalidScopeException(
                        String.format(PROTOTYPE_SCOPE_ERROR_MESSAGE, new List<String>{ provider.getToken() })
                    )
                );

                Container resolutionContainer = getResolutionContainer(binding.getOwner());
                if (provider instanceof ExistingProvider) {
                    return getInternalFrom(resolutionContainer, ((ExistingProvider) provider).getExisting(), args);
                }
                if (provider instanceof CustomMetadataTypesProvider) {
                    String existing = ((CustomMetadataTypesProvider) provider).getExisting(context);
                    if (existing != null) {
                        return getInternalFrom(resolutionContainer, existing, args);
                    }
                }
                return getInstanceFrom(resolutionContainer, provider, args);
            } finally {
                popIfMatches(token);
            }
        }

        protected virtual Object resolveInternal(final String token, final Object args) {
            validateAndAddPath(token);
            try {
                ProviderBinding binding = module.getProviderBinding(token);
                Provider provider = binding.getProvider();
                Container resolutionContainer = getResolutionContainer(binding.getOwner());
                if (provider instanceof ExistingProvider) {
                    return resolveInternalFrom(resolutionContainer, ((ExistingProvider) provider).getExisting(), args);
                }
                if (provider instanceof CustomMetadataTypesProvider) {
                    String existing = ((CustomMetadataTypesProvider) provider).getExisting(context);
                    if (existing != null) {
                        return resolveInternalFrom(resolutionContainer, existing, args);
                    }
                }
                return resolveInstanceFrom(resolutionContainer, provider, args);
            } finally {
                popIfMatches(token);
            }
        }

        protected Object newInstance(final Provider provider, final Object args) {
            return provider.resolve(this, args);
        }

        protected Scope getProviderScope(final Provider provider) {
            if (provider instanceof CustomMetadataTypesProvider) {
                return ((CustomMetadataTypesProvider) provider).getScope(context);
            }
            return provider.getScope();
        }

        protected virtual Object resolveInstance(final Provider provider, final Object args) {
            return autowire(newInstance(provider, args));
        }

        protected virtual Object autowire(final Object instance) {
            if (instance instanceof Injectable) {
                ((Injectable) instance).inject(this);
            }
            return instance;
        }

        protected virtual Container getResolutionContainer(final ModuleRef owner) {
            return owner === this ? this : owner;
        }

        private Object getInternalFrom(final Container target, final String token, final Object args) {
            if (target === this) {
                return getInternal(token, args);
            }
            return target.getInternalWithContext(token, args, this);
        }

        private Object resolveInternalFrom(final Container target, final String token, final Object args) {
            if (target === this) {
                return resolveInternal(token, args);
            }
            return target.resolveInternalWithContext(token, args, this);
        }

        private Object getInstanceFrom(final Container target, final Provider provider, final Object args) {
            if (target === this) {
                return getInstance(provider, args);
            }
            return target.getInstanceWithContext(provider, args, this);
        }

        private Object resolveInstanceFrom(final Container target, final Provider provider, final Object args) {
            if (target === this) {
                return resolveInstance(provider, args);
            }
            return target.resolveInstanceWithContext(provider, args, this);
        }

        private Object getInternalWithContext(final String token, final Object args, final Container source) {
            ResolutionContext previous = inheritResolutionContext(source);
            try {
                return getInternal(token, args);
            } finally {
                restoreResolutionContext(previous);
            }
        }

        private Object resolveInternalWithContext(final String token, final Object args, final Container source) {
            ResolutionContext previous = inheritResolutionContext(source);
            try {
                return resolveInternal(token, args);
            } finally {
                restoreResolutionContext(previous);
            }
        }

        private Object getInstanceWithContext(final Provider provider, final Object args, final Container source) {
            ResolutionContext previous = inheritResolutionContext(source);
            try {
                return getInstance(provider, args);
            } finally {
                restoreResolutionContext(previous);
            }
        }

        private Object resolveInstanceWithContext(final Provider provider, final Object args, final Container source) {
            ResolutionContext previous = inheritResolutionContext(source);
            try {
                return resolveInstance(provider, args);
            } finally {
                restoreResolutionContext(previous);
            }
        }

        private ResolutionContext inheritResolutionContext(final Container source) {
            ResolutionContext previous = new ResolutionContext(inCall, resolutionPath);
            inCall = true;
            resolutionPath.clear();
            resolutionPath.addAll(source.resolutionPath);
            return previous;
        }

        private void restoreResolutionContext(final ResolutionContext previous) {
            inCall = previous.inCall;
            resolutionPath.clear();
            resolutionPath.addAll(previous.resolutionPath);
        }

        protected virtual void validateAndAddPath(final String token) {
            isTrue(
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
        protected String registryToken;
        protected final Map<String, Object> cache = new Map<String, Object>();

        public ModuleRef(final Module module) {
            this(DEFAULT_CONTEXT, module);
        }

        protected ModuleRef(final ApplicationContext context, final Module module) {
            super(context, null, module);
            registryToken = module.getToken();
        }

        public virtual ScopeRef createScope() {
            return createScope(new ScopeContext());
        }

        public virtual ScopeRef createScope(final ScopeContext scopeContext) {
            isTrue(scopeContext != null, new InvalidScopeException(NULL_SCOPE_CONTEXT_MESSAGE));
            refreshIfModuleChanged();
            return new ScopeRef(this, module, scopeContext);
        }

        public virtual void replace(final Provider newProvider) {
            isTrue(newProvider != null, new InvalidProviderException(NULL_PROVIDER_MESSAGE));

            String token = newProvider.getToken();
            isTrue(token != null, new InvalidProviderException(INVALID_PROVIDER_TOKEN_MESSAGE));

            refreshIfModuleChanged();
            context.markGraphChanged();
            module.replace(newProvider);
            cache.remove(token);
        }

        public virtual override Object resolve(final String token, final Object args) {
            return super.resolve(token, args);
        }

        public virtual void refresh() {
            refreshIfModuleChanged();
            context.markGraphChanged();
            module.register(context);
            if (module.isGlobal()) {
                context.validateGlobalProviderBindings();
                context.clearAllModuleCaches();
                return;
            }
            clearCache();
        }

        public virtual void clearCache() {
            cache.clear();
        }

        protected virtual override Object getInstance(final Provider provider, final Object args) {
            Scope providerScope = getProviderScope(provider);
            isTrue(
                providerScope !== Scope.SCOPED,
                new InvalidScopeException(
                    String.format(SCOPED_ROOT_ACCESS_ERROR_MESSAGE, new List<String>{ provider.getToken() })
                )
            );
            String key = provider.getToken();
            if (args == null && providerScope == Scope.SINGLETON && cache.containsKey(key)) {
                return cache.get(key);
            }
            Object instance = newInstance(provider, args);
            if (args == null && providerScope == Scope.SINGLETON) {
                cache.put(key, instance);
            }
            try {
                return autowire(instance);
            } catch (Exception e) {
                if (args == null && providerScope == Scope.SINGLETON) {
                    cache.remove(key);
                }
                throw e;
            }
        }

        protected override Object resolveInstance(final Provider provider, final Object args) {
            isTrue(
                getProviderScope(provider) !== Scope.SCOPED,
                new InvalidScopeException(
                    String.format(SCOPED_ROOT_ACCESS_ERROR_MESSAGE, new List<String>{ provider.getToken() })
                )
            );
            return super.resolveInstance(provider, args);
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

        protected override Object getInternal(final String token, final Object args) {
            refreshIfModuleChanged();
            return super.getInternal(token, args);
        }

        protected override Object resolveInternal(final String token, final Object args) {
            refreshIfModuleChanged();
            return super.resolveInternal(token, args);
        }

        private void refreshIfModuleChanged() {
            ModuleRef currentRef = getCurrentRegisteredRef();
            if (currentRef != null && currentRef !== this && currentRef.getModule() !== module) {
                module = currentRef.getModule();
                clearCache();
            }
        }

        private ModuleRef getCurrentRegisteredRef() {
            return context.getLoadedRegistry(module).get(registryToken);
        }
    }

    public virtual class ScopeContext {
        private final Map<String, Map<String, Object>> scopedCacheByOwner = new Map<String, Map<String, Object>>();

        public virtual void clear() {
            scopedCacheByOwner.clear();
        }

        private Boolean contains(final Module ownerModule, final String providerToken) {
            Map<String, Object> scopedCache = scopedCacheByOwner.get(getOwnerKey(ownerModule));
            return scopedCache != null && scopedCache.containsKey(providerToken);
        }

        private Object get(final Module ownerModule, final String providerToken) {
            Map<String, Object> scopedCache = scopedCacheByOwner.get(getOwnerKey(ownerModule));
            return scopedCache == null ? null : scopedCache.get(providerToken);
        }

        private void put(final Module ownerModule, final String providerToken, final Object instance) {
            String ownerKey = getOwnerKey(ownerModule);
            Map<String, Object> scopedCache = scopedCacheByOwner.get(ownerKey);
            if (scopedCache == null) {
                scopedCache = new Map<String, Object>();
                scopedCacheByOwner.put(ownerKey, scopedCache);
            }
            scopedCache.put(providerToken, instance);
        }

        private void remove(final Module ownerModule, final String providerToken) {
            Map<String, Object> scopedCache = scopedCacheByOwner.get(getOwnerKey(ownerModule));
            if (scopedCache != null) {
                scopedCache.remove(providerToken);
            }
        }

        private String getOwnerKey(final Module ownerModule) {
            return (ownerModule.isGlobal() ? 'global:' : 'local:') + ownerModule.getToken();
        }
    }

    public virtual class ScopeRef extends Container {
        protected final ScopeContext scopeContext;
        protected final Map<String, ScopeRef> ownerScopes = new Map<String, ScopeRef>();

        protected ScopeRef(final ModuleRef parent, final Module module, final ScopeContext scopeContext) {
            super(parent.context, parent, module);
            this.scopeContext = scopeContext;
        }

        public override Object resolve(final String token, final Object args) {
            return super.resolve(token, args);
        }

        public virtual void clearCache() {
            scopeContext.clear();
            ownerScopes.clear();
        }

        protected virtual override Object getInstance(final Provider provider, final Object args) {
            if (getProviderScope(provider) === Scope.SCOPED) {
                String key = provider.getToken();
                if (args == null && scopeContext.contains(module, key)) {
                    return scopeContext.get(module, key);
                }
                Object instance = newInstance(provider, args);
                if (args == null) {
                    scopeContext.put(module, key, instance);
                }
                try {
                    return autowire(instance);
                } catch (Exception e) {
                    if (args == null) {
                        scopeContext.remove(module, key);
                    }
                    throw e;
                }
            }
            return parent.getInstance(provider, args);
        }

        protected override Object getInternal(final String token, final Object args) {
            refreshIfModuleChanged();
            return super.getInternal(token, args);
        }

        protected override Object resolveInternal(final String token, final Object args) {
            refreshIfModuleChanged();
            return super.resolveInternal(token, args);
        }

        protected override Boolean hasInCache(final String token) {
            return scopeContext.contains(module, token);
        }

        protected override Container getResolutionContainer(final ModuleRef owner) {
            String ownerToken = owner.getModule().getToken();
            if (owner === parent) {
                return this;
            }

            String ownerScopeKey = (owner.getModule().isGlobal() ? 'global:' : 'local:') + ownerToken;
            ScopeRef ownerScope = ownerScopes.get(ownerScopeKey);
            if (ownerScope == null || ownerScope.parent !== owner) {
                ownerScope = owner.createScope(scopeContext);
                ownerScopes.put(ownerScopeKey, ownerScope);
            }
            return ownerScope;
        }

        protected override void validateAndAddPath(String token) {
            if (hasInCache(token) || parent.hasInCache(token)) {
                return;
            }
            super.validateAndAddPath(token);
        }

        private void refreshIfModuleChanged() {
            ModuleRef currentRef = ((ModuleRef) parent).getCurrentRegisteredRef();
            if (currentRef != null && currentRef !== parent) {
                parent = currentRef;
                module = currentRef.getModule();
                clearCache();
            }
        }
    }

    public virtual class ModuleImport {
        protected ApplicationContext context;
        protected final String token;
        protected Boolean isEager = false;
        protected Module cachedModule;

        protected ModuleImport(final String token) {
            this(DEFAULT_CONTEXT, token);
        }

        protected ModuleImport(final ApplicationContext context, final String token) {
            isTrue(token != null, new InvalidModuleException(INVALID_MODULE_TOKEN_MESSAGE));

            this.context = context ?? DEFAULT_CONTEXT;
            this.token = token;
        }

        protected ModuleImport(final Module module) {
            this(DEFAULT_CONTEXT, module);
        }

        protected ModuleImport(final ApplicationContext context, final Module module) {
            isTrue(module != null, new InvalidModuleException(NULL_MODULE_MESSAGE));

            this.context = context ?? DEFAULT_CONTEXT;
            token = module.getToken();
            cachedModule = module;
        }

        public String getToken() {
            return token;
        }

        public virtual ModuleImport immediately() {
            isEager = true;
            return this;
        }

        public virtual Module resolve() {
            return context.resolveImport(this);
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
