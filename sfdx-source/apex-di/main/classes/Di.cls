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
    private static final String MODULE_VISIBILITY_CONFLICT_MESSAGE = 'Cannot register module "{0}" as {1}. The canonical module token is already registered as {2}.';
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
    private static final String NULL_PROVIDER_SCOPE_MESSAGE = 'Provider scope cannot be null.';
    private static final String COMMITTED_PROVIDER_SCOPE_MESSAGE = 'Cannot change the scope of a committed provider. Configure provider scope before module registration.';
    private static final String SEALED_DYNAMIC_MODULE_MESSAGE = 'Cannot modify sealed dynamic module "{0}". Create a new DynamicModule instance to change its definition.';
    private static final String SCOPE_CONTEXT_MISMATCH_MESSAGE =
        'A ScopeContext cannot be shared across application contexts. ' +
        'Create a separate ScopeContext for each application context.';
    private static final String CLEARED_CONTEXT_REFERENCE_MESSAGE =
        'Cannot use this container reference because its application context was cleared. ' +
        'Request a new reference from the application context.';
    private static final String UNREGISTERED_MODULE_CONTEXT_MESSAGE =
        'Cannot access module providers because the module is not registered in an active application context ' +
        'or its application context was cleared. Register the module before requesting its providers.';
    private static final String INVALID_PROVIDER_CONFIG_MESSAGE =
        'Invalid provider configuration for token "{0}". ' +
        'The provider must be one of: ClassProvider, ValueProvider, FactoryProvider or ExistingProvider.';
    private static final String CIRCULAR_DEPENDENCY_MESSAGE = 'Circular dependency detected for provider "{0}". Resolution path: {1} -> {0}';
    private static final String CIRCULAR_REEXPORT_MESSAGE = 'Circular module reexport detected for module "{0}". Registration path: {1} -> {0}';
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
    private static final String NULL_METADATA_SOURCE_MESSAGE = 'Cannot create an application context with a null metadata source.';
    private static final String UNKNOWN_METADATA_MODULE_MESSAGE = 'Cannot find metadata module alias "{0}". Ensure an active DI_Module__mdt record exists with this DeveloperName.';
    private static final String INACTIVE_METADATA_MODULE_MESSAGE = 'Metadata module alias "{0}" is inactive. Activate its DI_Module__mdt record before resolving it.';

    private static final ApplicationContext DEFAULT_CONTEXT = new ApplicationContext();

    @TestVisible
    private static Integer guardExceptionCreationCount = 0;
    @TestVisible
    private static Integer memoRevisionMissCount = 0;

    @TestVisible
    private static Boolean hasGlobalLoadBeenAttempted {
        get {
            return DEFAULT_CONTEXT.hasGlobalLoadBeenAttempted;
        }
    }

    @TestVisible
    private Di() {
    }

    // <editor-fold desc="Static API">
    public static ApplicationContext createContext() {
        return new ApplicationContext();
    }

    public static ApplicationContext createContext(final MetadataSource metadataSource) {
        return new ApplicationContext(metadataSource);
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

    public static ModuleRef addGlobalModule(final Module module) {
        return DEFAULT_CONTEXT.addGlobalModule(module);
    }

    public static ModuleRef getMetadataModuleRef(final String developerName) {
        return DEFAULT_CONTEXT.getMetadataModuleRef(developerName);
    }

    public static void replaceModule(final String token, final Module newModule) {
        DEFAULT_CONTEXT.replaceModule(token, newModule);
    }

    public static void replaceModule(final Type token, final Module newModule) {
        DEFAULT_CONTEXT.replaceModule(token, newModule);
    }

    public static void replaceProvider(final String moduleToken, final Provider newProvider) {
        DEFAULT_CONTEXT.replaceProvider(moduleToken, newProvider);
    }

    public static void replaceProvider(final Type moduleToken, final Provider newProvider) {
        DEFAULT_CONTEXT.replaceProvider(moduleToken, newProvider);
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

    public static ModuleImport importMetadataModule(final String developerName) {
        return DEFAULT_CONTEXT.importMetadataModule(developerName);
    }

    public static void clear() {
        DEFAULT_CONTEXT.clear();
    }

    public static ContextDescription describe() {
        return DEFAULT_CONTEXT.describe();
    }
    // </editor-fold>

    // <editor-fold desc="Helpers">
    @TestVisible
    private static void mockModules(final Iterable<DI_Module__mdt> mockModules) {
        DEFAULT_CONTEXT.mockModules(mockModules);
    }

    @TestVisible
    private static void mockProviders(final Map<String, DI_Provider__mdt> providerByDeveloperName) {
        DEFAULT_CONTEXT.mockProviders(providerByDeveloperName);
    }

    private static Module create(final String token) {
        Type moduleType = Type.forName(token);
        isTrue(moduleType != null, UnknownModuleException.class, UNKNOWN_MODULE_MESSAGE, new List<String>{ token });

        Object raw;
        try {
            raw = moduleType.newInstance();
        } catch (TypeException exc) {
            throw new InvalidModuleException(
                String.format(INSTANTIATION_FAILED_MESSAGE, new List<String>{ token }),
                exc
            );
        }
        isTrue(raw instanceof Module, InvalidModuleException.class, INVALID_MODULE_MESSAGE, new List<String>{ token });

        Module module = (Module) raw;
        return module;
    }

    private static Object instantiate(final String typeName) {
        isTrue(typeName != null, InvalidClassException.class, INVALID_CLASS_MESSAGE, new List<String>{ 'null' });

        Type providedType = Type.forName(typeName);
        isTrue(providedType != null, InvalidClassException.class, INVALID_CLASS_MESSAGE, new List<String>{ typeName });

        return instantiate(providedType);
    }

    private static Object instantiate(final Type type) {
        isTrue(type != null, InvalidClassException.class, NULL_PROVIDER_FACTORY_MESSAGE);
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
            InvalidClassException.class,
            INVALID_FACTORY_CLASS_MESSAGE,
            new List<String>{ typeName, token }
        );

        return (Factory) raw;
    }

    private static Map<String, MetadataModuleDefinition> normalizeModuleDefinitions(
        final Map<String, DI_Module__mdt> metadataByDeveloperName
    ) {
        Map<String, MetadataModuleDefinition> definitions = new Map<String, MetadataModuleDefinition>();
        for (String developerName : metadataByDeveloperName.keySet()) {
            DI_Module__mdt row = metadataByDeveloperName.get(developerName);
            definitions.put(
                developerName,
                new MetadataModuleDefinition(
                    row.DeveloperName ?? developerName,
                    row.ModuleClass__c,
                    row.IsActive__c,
                    row.IsGlobal__c
                )
            );
        }
        return definitions;
    }

    private static Map<String, MetadataModuleDefinition> normalizeModuleDefinitions(
        final Iterable<DI_Module__mdt> metadata
    ) {
        if (metadata == null) {
            return null;
        }
        Map<String, DI_Module__mdt> metadataByDeveloperName = new Map<String, DI_Module__mdt>();
        for (DI_Module__mdt row : metadata) {
            String developerName = row.DeveloperName ?? row.ModuleClass__c;
            metadataByDeveloperName.put(developerName, row);
        }
        return normalizeModuleDefinitions(metadataByDeveloperName);
    }

    private static Map<String, ProviderDefinition> normalizeProviderDefinitions(
        final Map<String, DI_Provider__mdt> metadataByDeveloperName
    ) {
        if (metadataByDeveloperName == null) {
            return null;
        }
        Map<String, ProviderDefinition> definitions = new Map<String, ProviderDefinition>();
        for (String developerName : metadataByDeveloperName.keySet()) {
            DI_Provider__mdt row = metadataByDeveloperName.get(developerName);
            definitions.put(
                developerName,
                new ProviderDefinition(
                    row.DeveloperName ?? developerName,
                    row.Type__c,
                    row.Value__c,
                    row.Args__c,
                    row.Scope__c,
                    row.IsActive__c
                )
            );
        }
        return definitions;
    }

    private static void isTrue(final Boolean condition, final Type exceptionType, final String message) {
        if (condition ?? false) {
            return;
        }
        throw createException(exceptionType, message);
    }

    private static void isTrue(
        final Boolean condition,
        final Type exceptionType,
        final String messageTemplate,
        final List<String> arguments
    ) {
        if (condition ?? false) {
            return;
        }
        throw createException(exceptionType, String.format(messageTemplate, arguments));
    }

    private static void isTrue(
        final Boolean condition,
        final Type exceptionType,
        final String messageTemplate,
        final String argument
    ) {
        if (condition ?? false) {
            return;
        }
        throw createException(exceptionType, String.format(messageTemplate, new List<String>{ argument }));
    }

    private static void isTrue(
        final Boolean condition,
        final Type exceptionType,
        final String messageTemplate,
        final String token,
        final List<String> path
    ) {
        if (condition ?? false) {
            return;
        }
        throw createException(
            exceptionType,
            String.format(messageTemplate, new List<String>{ token, String.join(path, ' -> ') })
        );
    }

    private static Exception createException(final Type exceptionType, final String message) {
        guardExceptionCreationCount++;
        Exception guardException = (Exception) exceptionType.newInstance();
        guardException.setMessage(message);
        return guardException;
    }
    // </editor-fold>

    public enum Scope {
        SINGLETON,
        PROTOTYPE,
        SCOPED
    }

    public enum ResolutionStatus {
        RESOLVED,
        NOT_FOUND,
        AMBIGUOUS
    }

    public enum ResolutionSource {
        LOCAL,
        IMPORTED,
        IMPLICIT_GLOBAL,
        NONE
    }

    public enum ProviderKind {
        CLASS_PROVIDER,
        VALUE_PROVIDER,
        FACTORY_PROVIDER,
        EXISTING_PROVIDER,
        METADATA_PROVIDER
    }

    public enum ProviderConfigurationStatus {
        VALID,
        MISSING_METADATA,
        INACTIVE_METADATA,
        INVALID_METADATA
    }

    private enum ModuleVisibility {
        LOCAL_MODULE,
        GLOBAL_MODULE
    }

    public interface MetadataSource {
        Map<String, MetadataModuleDefinition> getModules();
        Map<String, ProviderDefinition> getProviders();
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

    public abstract inherited sharing class Module {
        protected final String token;
        private ModuleDefinition definition = new ModuleDefinition(
            new Map<String, Provider>(),
            new Set<String>(),
            new Set<ModuleImport>(),
            new Set<ModuleImport>()
        );
        private ApplicationContext context;
        private Boolean isSealed = false;

        protected Module() {
            token = String.valueOf(this).substringBefore(':');
        }

        protected Module(final String token) {
            isTrue(token != null, InvalidModuleException.class, INVALID_MODULE_TOKEN_MESSAGE);

            this.token = token;
        }

        // <editor-fold desc="Module API">
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

        public virtual Provider getProvider(final String token) {
            return getProviderBinding(token).getProvider();
        }

        public virtual ProviderBuilder provide(final Type token) {
            return provide(token?.getName());
        }

        public virtual ProviderBuilder provide(final String token) {
            return new ProviderBuilder(token);
        }

        public String getToken() {
            return token;
        }

        private String getClassName() {
            return String.valueOf(this).substringBefore(':');
        }

        public Boolean hasImport(final String token) {
            for (ModuleImport moduleImport : definition.imports) {
                if (moduleImport.getToken().equals(token)) {
                    return true;
                }
            }
            return false;
        }

        public Boolean hasProvider(final String token) {
            return definition.providers.containsKey(token);
        }

        public Boolean hasExport(final String token) {
            return definition.exports.contains(token);
        }

        public Boolean equals(final Object obj) {
            if (!(obj instanceof Module)) {
                return false;
            }
            return ((Module) obj).getToken().equals(token);
        }

        public Integer hashCode() {
            return System.hashCode(token);
        }
        // </editor-fold>

        protected virtual Module replace(final Provider newProvider) {
            isTrue(newProvider != null, InvalidProviderException.class, NULL_PROVIDER_MESSAGE);

            String token = newProvider.getToken();
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);
            isTrue(
                hasProvider(token),
                UnknownProviderException.class,
                UNKNOWN_PROVIDER_MESSAGE,
                new List<String>{ token, getToken() }
            );

            Map<String, Provider> replacementProviders = new Map<String, Provider>(definition.providers);
            replacementProviders.put(token, newProvider);
            newProvider.freeze();
            definition = new ModuleDefinition(
                replacementProviders,
                definition.exports,
                definition.imports,
                definition.reexports
            );
            return this;
        }

        protected virtual void register(final ApplicationContext context) {
            ApplicationContext previousContext = this.context;
            ModuleDefinition previousDefinition = definition;
            setContext(context);
            context.pushRegistration(getToken());
            try {
                definition = compileDefinition();
            } catch (Exception exc) {
                definition = previousDefinition;
                this.context = previousContext;
                throw exc;
            } finally {
                context.popRegistration();
            }
        }

        protected Boolean isSealed() {
            return isSealed;
        }

        // <editor-fold desc="Helpers">
        private ApplicationContext getContext() {
            isTrue(context != null, InvalidContextException.class, UNREGISTERED_MODULE_CONTEXT_MESSAGE);
            return context;
        }

        private void setContext(final ApplicationContext context) {
            isTrue(
                this.context == null || this.context === context,
                InvalidModuleException.class,
                MODULE_CONTEXT_MISMATCH_MESSAGE,
                new List<String>{ token }
            );
            this.context = context;
        }

        private void clearContext(final ApplicationContext context) {
            if (this.context === context) {
                this.context = null;
            }
        }

        private void freezeDefinition() {
            for (Provider provider : definition.providers.values()) {
                provider.freeze();
            }
            isSealed = true;
        }

        private ProviderBinding getProviderBinding(final String token) {
            return getProviderBinding(token, true);
        }

        private ProviderBinding getProviderBinding(final String token, final Boolean includeGlobals) {
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);

            ProviderBinding visibleProvider = getContext().getVisibleProviderBinding(this, token);
            if (visibleProvider != null) {
                return visibleProvider;
            }
            isTrue(
                !getContext().hasCompiledGraph(),
                UnknownProviderException.class,
                UNKNOWN_PROVIDER_MESSAGE,
                new List<String>{ token, getToken() }
            );

            return discoverProviderBinding(token, includeGlobals, null, true);
        }

        private BindingExplanation explainProviderBinding(final String token) {
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);

            BindingExplanation explanation = new BindingExplanation();
            if (getContext().hasCompiledGraph() && getContext().getVisibleProviderBinding(this, token) == null) {
                return explanation;
            }
            try {
                discoverProviderBinding(token, true, explanation, false);
            } catch (UnknownProviderException exc) {
                return explanation;
            }
            return explanation;
        }

        private ProviderBinding discoverProviderBinding(
            final String token,
            final Boolean includeGlobals,
            final BindingExplanation explanation,
            final Boolean shouldIndex
        ) {
            // First check local definitions
            if (hasProvider(token)) {
                ProviderBinding localProvider = new ProviderBinding(
                    definition.providers.get(token),
                    getContext().getRegisteredModuleRef(this)
                );
                explanation?.resolve(ResolutionSource.LOCAL, localProvider);
                return shouldIndex
                    ? getContext().indexVisibleProviderBinding(this, token, localProvider)
                    : localProvider;
            }

            // Then check imported and re-exported modules
            Set<ModuleImport> searchScope = new Set<ModuleImport>();
            searchScope.addAll(definition.imports);
            searchScope.addAll(definition.reexports);

            ProviderBinding selectedProvider;
            for (ModuleImport moduleImport : searchScope) {
                Module module = getContext().resolveImport(moduleImport);
                if (!module.hasExport(token)) {
                    continue;
                }
                ProviderBinding provider;
                if (explanation == null) {
                    provider = module.getProviderBinding(token);
                } else {
                    BindingExplanation importedExplanation = module.explainProviderBinding(token);
                    if (importedExplanation.status === ResolutionStatus.AMBIGUOUS) {
                        explanation.ambiguous(importedExplanation);
                        return null;
                    }
                    provider = importedExplanation.binding;
                    isTrue(
                        provider != null,
                        UnknownExportException.class,
                        UNKNOWN_EXPORT_MESSAGE,
                        new List<String>{ token, module.getToken() }
                    );
                }
                if (selectedProvider == null) {
                    selectedProvider = provider;
                    continue;
                }
                if (selectedProvider.getOwner() !== provider.getOwner()) {
                    if (explanation != null) {
                        explanation.ambiguous(selectedProvider, provider);
                        return null;
                    }
                }
                isTrue(
                    selectedProvider.getOwner() === provider.getOwner(),
                    InvalidProviderException.class,
                    AMBIGUOUS_IMPORTED_PROVIDER_MESSAGE,
                    new List<String>{
                        token,
                        getToken(),
                        selectedProvider.getOwner().getModule().getToken(),
                        provider.getOwner().getModule().getToken()
                    }
                );
            }
            if (selectedProvider != null) {
                explanation?.resolve(ResolutionSource.IMPORTED, selectedProvider);
                return shouldIndex
                    ? getContext().indexVisibleProviderBinding(this, token, selectedProvider)
                    : selectedProvider;
            }

            // Finally check implicit global module exports.
            if (includeGlobals) {
                ProviderBinding globalProvider = getContext().getImplicitGlobalProviderBinding(token);
                if (globalProvider != null) {
                    explanation?.resolve(ResolutionSource.IMPLICIT_GLOBAL, globalProvider);
                    return shouldIndex
                        ? getContext().indexVisibleProviderBinding(this, token, globalProvider)
                        : globalProvider;
                }
            }

            throw new UnknownProviderException(
                String.format(UNKNOWN_PROVIDER_MESSAGE, new List<String>{ token, getToken() })
            );
        }

        private ModuleDefinition compileDefinition() {
            Map<String, Provider> candidateProviders = new Map<String, Provider>();
            Set<String> candidateExports = new Set<String>();

            for (Provider provider : providers() ?? new Set<Provider>()) {
                candidateProviders.put(provider.getToken(), provider);
            }

            for (String token : exports() ?? new Set<String>()) {
                isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);
                isTrue(
                    candidateProviders.containsKey(token),
                    UnknownExportException.class,
                    UNKNOWN_EXPORT_MESSAGE,
                    new List<String>{ token, getToken() }
                );

                candidateExports.add(token);
            }

            Set<ModuleImport> candidateImports = new Set<ModuleImport>(imports() ?? new Set<ModuleImport>());
            for (ModuleImport moduleImport : candidateImports) {
                if (moduleImport.isEager) {
                    getContext().resolveImport(moduleImport);
                }
            }

            Set<ModuleImport> candidateReexports = new Set<ModuleImport>(reexports() ?? new Set<ModuleImport>());
            for (ModuleImport reexport : candidateReexports) {
                String reexportToken = reexport.getToken();
                getContext().assertNoCircularReexport(reexportToken);
                Module reexportedModule = getContext().resolveImport(reexport);
                getContext().assertNoCircularReexport(reexportedModule.getToken());
                for (String token : reexportedModule.definition.exports) {
                    candidateExports.add(token);
                }
            }

            return new ModuleDefinition(candidateProviders, candidateExports, candidateImports, candidateReexports);
        }

        // </editor-fold>
    }

    public abstract inherited sharing class Provider {
        protected final String token;
        private Boolean isCommitted = false;
        private Scope scopeType = Scope.SINGLETON;

        private Provider(String token) {
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);

            this.token = token;
        }

        public abstract Object resolve(final Container container, final Object args);

        public virtual Scope getScope() {
            return scopeType;
        }

        public virtual Provider scope(final Scope scopeType) {
            isTrue(scopeType != null, InvalidScopeException.class, NULL_PROVIDER_SCOPE_MESSAGE);
            isTrue(!isCommitted, InvalidProviderException.class, COMMITTED_PROVIDER_SCOPE_MESSAGE);
            this.scopeType = scopeType;
            return this;
        }

        public String getToken() {
            return token;
        }

        public Boolean equals(final Object obj) {
            if (!(obj instanceof Provider)) {
                return false;
            }
            return ((Provider) obj).getToken().equals(token);
        }

        public Integer hashCode() {
            return System.hashCode(token);
        }

        private void freeze() {
            isCommitted = true;
        }

        protected abstract ProviderKind getKind();

        private Scope getConfiguredScope() {
            return scopeType;
        }
    }

    public abstract inherited sharing class Container {
        protected ApplicationContext context;
        protected Container parent;
        protected final List<String> resolutionPath = new List<String>();
        protected Boolean inCall = false;
        private final Integer contextGeneration;
        private ModuleRuntime runtime;
        private Map<String, ResolvedPlan> resolutionMemo;

        protected Container(
            final ApplicationContext context,
            final Container parent,
            final Module module,
            final ModuleVisibility visibility
        ) {
            this.context = context ?? DEFAULT_CONTEXT;
            this.parent = parent;
            this.contextGeneration = this.context.lifecycleGeneration;
            this.runtime = new ModuleRuntime(module, visibility);
        }

        // <editor-fold desc="Resolution API">
        public virtual Object get(final String token, final Object args) {
            isTrue(args == null, InvalidProviderException.class, GET_ARGS_NOT_SUPPORTED_MESSAGE);
            if (inCall) {
                return getInternal(token, args);
            }

            if (resolutionMemo != null) {
                ResolvedPlan plan = resolutionMemo.get(token);
                if (
                    plan != null &&
                    plan.graphRevision == context.graphRevision &&
                    plan.owner === this &&
                    plan.scope == Scope.SINGLETON &&
                    hasSingleton(token)
                ) {
                    validateContextGeneration();
                    return getSingleton(token);
                }
            }

            startResolution();
            try {
                return getInternal(token, args);
            } finally {
                endResolution();
            }
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
            if (inCall) {
                return resolveInternal(token, args);
            }

            startResolution();
            try {
                return resolveInternal(token, args);
            } finally {
                endResolution();
            }
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

        public virtual ResolutionExplanation explain(final String token) {
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);
            validateContextGeneration();

            BindingExplanation bindingExplanation = getRuntimeModule().explainProviderBinding(token);
            Provider provider = bindingExplanation.binding?.getProvider();
            String redirectToken;
            if (provider instanceof ExistingProvider) {
                redirectToken = ((ExistingProvider) provider).getExisting();
            } else if (provider instanceof CustomMetadataTypesProvider) {
                redirectToken = ((CustomMetadataTypesProvider) provider).getExisting(context);
            }

            return new ResolutionExplanation(
                token,
                getRuntimeModule().getToken(),
                bindingExplanation.status,
                bindingExplanation.source,
                bindingExplanation.binding?.getOwner().getRuntimeModule().getToken(),
                provider != null ? getProviderScope(provider) : null,
                redirectToken,
                bindingExplanation.conflictingModules
            );
        }

        public virtual ResolutionExplanation explain(final Type token) {
            return explain(token?.getName());
        }

        public virtual Object inject(final Object instance) {
            validateContextGeneration();
            isTrue(instance instanceof Injectable, InvalidClassException.class, NOT_INJECTABLE_MESSAGE);
            if (inCall) {
                return autowire(instance);
            }

            startResolution();
            try {
                return autowire(instance);
            } finally {
                endResolution();
            }
        }

        public Module getModule() {
            validateContextGeneration();
            return runtime.module;
        }
        // </editor-fold>

        protected abstract Object getInstance(final Provider provider, final Object args);

        protected abstract Boolean hasInCache(final String token);

        protected void validateContextGeneration() {
            isTrue(
                contextGeneration == context.lifecycleGeneration,
                InvalidContextException.class,
                CLEARED_CONTEXT_REFERENCE_MESSAGE
            );
        }

        protected virtual Object getInternal(final String token, final Object args) {
            validateAndAddPath(token);
            try {
                ResolvedPlan plan = memoizedPlan(token);
                if (plan != null) {
                    isTrue(
                        plan.scope !== Scope.PROTOTYPE,
                        InvalidScopeException.class,
                        PROTOTYPE_SCOPE_ERROR_MESSAGE,
                        new List<String>{ token }
                    );
                    return getInstanceFrom(getResolutionContainer(plan.owner), plan.provider, args);
                }
                ProviderBinding binding = getRuntimeModule().getProviderBinding(token);
                Provider provider = binding.getProvider();
                isTrue(
                    getProviderScope(provider) !== Scope.PROTOTYPE,
                    InvalidScopeException.class,
                    PROTOTYPE_SCOPE_ERROR_MESSAGE,
                    new List<String>{ provider.getToken() }
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
                memoizePlan(token, provider, binding.getOwner());
                return getInstanceFrom(resolutionContainer, provider, args);
            } finally {
                popIfMatches(token);
            }
        }

        protected virtual Object resolveInternal(final String token, final Object args) {
            validateAndAddPath(token);
            try {
                ResolvedPlan plan = memoizedPlan(token);
                if (plan != null) {
                    return resolveInstanceFrom(getResolutionContainer(plan.owner), plan.provider, args);
                }
                ProviderBinding binding = getRuntimeModule().getProviderBinding(token);
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
                memoizePlan(token, provider, binding.getOwner());
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
            if (!(instance instanceof Injectable)) {
                return instance;
            }
            ((Injectable) instance).inject(this);
            return instance;
        }

        protected virtual Container getResolutionContainer(final ModuleRef owner) {
            return owner === this ? this : owner;
        }

        protected virtual void validateAndAddPath(final String token) {
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);
            isTrue(
                !resolutionPath.contains(token),
                CircularDependencyException.class,
                CIRCULAR_DEPENDENCY_MESSAGE,
                token,
                resolutionPath
            );

            resolutionPath.add(token);
        }

        // <editor-fold desc="Helpers">
        private void adoptRuntime(final Container source) {
            runtime = source.runtime;
        }

        private Boolean hasSingleton(final String token) {
            return runtime.singletonCache.containsKey(token);
        }

        private Object getSingleton(final String token) {
            return runtime.singletonCache.get(token);
        }

        private void putSingleton(final String token, final Object instance) {
            runtime.singletonCache.put(token, instance);
        }

        private void removeSingleton(final String token) {
            runtime.singletonCache.remove(token);
        }

        private Module getRuntimeModule() {
            return runtime.module;
        }

        private ModuleRuntime getRuntime() {
            return runtime;
        }

        private ModuleVisibility getVisibility() {
            return runtime.visibility;
        }

        private void clearSingletons() {
            runtime.singletonCache.clear();
        }

        private void enableResolutionMemo() {
            resolutionMemo = new Map<String, ResolvedPlan>();
        }

        private ResolvedPlan memoizedPlan(final String token) {
            if (resolutionMemo == null) {
                return null;
            }
            ResolvedPlan plan = resolutionMemo.get(token);
            if (plan == null) {
                return null;
            }
            if (plan.graphRevision != context.graphRevision) {
                memoRevisionMissCount++;
                return null;
            }
            return plan;
        }

        private void memoizePlan(final String token, final Provider provider, final ModuleRef owner) {
            if (resolutionMemo == null) {
                return;
            }
            if (
                provider instanceof ClassProvider ||
                provider instanceof ValueProvider ||
                provider instanceof FactoryProvider
            ) {
                resolutionMemo.put(
                    token,
                    new ResolvedPlan(provider, owner, provider.getScope(), context.graphRevision)
                );
            }
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

        private void startResolution() {
            validateContextGeneration();
            context.open();
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
        // </editor-fold>
    }

    public inherited sharing class CustomMetadataSource implements MetadataSource {
        public Map<String, MetadataModuleDefinition> getModules() {
            return normalizeModuleDefinitions(DI_Module__mdt.getAll());
        }

        public Map<String, ProviderDefinition> getProviders() {
            return normalizeProviderDefinitions(DI_Provider__mdt.getAll());
        }
    }

    public class MetadataModuleDefinition {
        public final String developerName;
        public final String moduleClass;
        public final Boolean isActive;
        public final Boolean isGlobal;

        public MetadataModuleDefinition(
            final String developerName,
            final String moduleClass,
            final Boolean isActive,
            final Boolean isGlobal
        ) {
            this.developerName = developerName;
            this.moduleClass = moduleClass;
            this.isActive = isActive;
            this.isGlobal = isGlobal;
        }
    }

    public class ProviderDefinition {
        public final String developerName;
        public final String type;
        public final String value;
        public final String args;
        public final String scope;
        public final Boolean isActive;

        public ProviderDefinition(
            final String developerName,
            final String type,
            final String value,
            final String args,
            final String scope,
            final Boolean isActive
        ) {
            this.developerName = developerName;
            this.type = type;
            this.value = value;
            this.args = args;
            this.scope = scope;
            this.isActive = isActive;
        }
    }

    public class ResolutionExplanation {
        public final String token;
        public final String requestingModule;
        public final ResolutionStatus status;
        public final ResolutionSource source;
        public final String ownerModule;
        public final Scope declaredScope;
        public final String redirectToken;
        public final List<String> conflictingModules;

        private ResolutionExplanation(
            final String token,
            final String requestingModule,
            final ResolutionStatus status,
            final ResolutionSource source,
            final String ownerModule,
            final Scope declaredScope,
            final String redirectToken,
            final List<String> conflictingModules
        ) {
            this.token = token;
            this.requestingModule = requestingModule;
            this.status = status;
            this.source = source;
            this.ownerModule = ownerModule;
            this.declaredScope = declaredScope;
            this.redirectToken = redirectToken;
            this.conflictingModules = new List<String>(conflictingModules);
        }
    }

    public class ContextDescription {
        public final Boolean isCompiled;
        public final List<ModuleDescription> modules;

        private ContextDescription(final Boolean isCompiled, final List<ModuleDescription> modules) {
            this.isCompiled = isCompiled;
            this.modules = new List<ModuleDescription>(modules);
        }
    }

    public class ModuleDescription {
        public final String token;
        public final Boolean isGlobal;
        public final List<String> metadataAliases;
        public final List<ProviderDescription> providers;
        public final List<String> exports;
        public final List<ModuleImportDescription> imports;
        public final List<ModuleImportDescription> reexports;

        private ModuleDescription(
            final String token,
            final Boolean isGlobal,
            final List<String> metadataAliases,
            final List<ProviderDescription> providers,
            final List<String> exports,
            final List<ModuleImportDescription> imports,
            final List<ModuleImportDescription> reexports
        ) {
            this.token = token;
            this.isGlobal = isGlobal;
            this.metadataAliases = new List<String>(metadataAliases);
            this.providers = new List<ProviderDescription>(providers);
            this.exports = new List<String>(exports);
            this.imports = new List<ModuleImportDescription>(imports);
            this.reexports = new List<ModuleImportDescription>(reexports);
        }
    }

    public class ProviderDescription {
        public final String token;
        public final ProviderKind kind;
        public final ProviderConfigurationStatus configurationStatus;
        public final Scope declaredScope;
        public final String redirectToken;
        public final Boolean isExported;

        private ProviderDescription(
            final String token,
            final ProviderKind kind,
            final ProviderConfigurationStatus configurationStatus,
            final Scope declaredScope,
            final String redirectToken,
            final Boolean isExported
        ) {
            this.token = token;
            this.kind = kind;
            this.configurationStatus = configurationStatus;
            this.declaredScope = declaredScope;
            this.redirectToken = redirectToken;
            this.isExported = isExported;
        }
    }

    public class ModuleImportDescription {
        public final String token;
        public final Boolean isEager;
        public final String metadataAlias;

        private ModuleImportDescription(final String token, final Boolean isEager, final String metadataAlias) {
            this.token = token;
            this.isEager = isEager;
            this.metadataAlias = metadataAlias;
        }
    }

    public virtual class ApplicationContext {
        private final Map<String, ModuleRef> moduleRegistry = new Map<String, ModuleRef>();
        private final Map<String, ModuleRef> globalModuleRegistry = new Map<String, ModuleRef>();
        private final Map<String, ProviderBinding> globalProviderBindings = new Map<String, ProviderBinding>();
        private final Map<String, Map<String, ProviderBinding>> visibleProvidersByModuleKey = new Map<String, Map<String, ProviderBinding>>();
        private final List<String> moduleRegistrationPath = new List<String>();
        private final MetadataState metadata;

        @TestVisible
        private Boolean hasGlobalLoadBeenAttempted = false;
        private Integer graphRevision = 0;
        private Integer globalBindingIndexRevision = -1;
        private Boolean hasGlobalLoadFailed = false;
        private Boolean isCompiled = false;
        private Boolean isLoadingGlobalModules = false;
        private Boolean isOpen = false;
        private Integer lifecycleGeneration = 0;

        private final Map<String, ModuleRef> globalRegistry {
            get {
                if (!hasGlobalLoadBeenAttempted && !isLoadingGlobalModules) {
                    loadGlobalModules();
                }
                return globalModuleRegistry;
            }
        }

        // <editor-fold desc="Context API">
        public ApplicationContext() {
            this(new CustomMetadataSource());
        }

        public ApplicationContext(final MetadataSource metadataSource) {
            isTrue(metadataSource != null, InvalidModuleException.class, NULL_METADATA_SOURCE_MESSAGE);
            this.metadata = new MetadataState(metadataSource);
        }

        public virtual ModuleRef getModuleRef(final Module module) {
            isTrue(module != null, InvalidModuleException.class, NULL_MODULE_MESSAGE);

            String token = module.getToken();
            ModuleRef ref = findRegisteredModuleRef(module);
            if (ref == null) {
                return installModule(module, ModuleVisibility.LOCAL_MODULE, isOpen, null);
            }

            isTrue(
                ref.getModule() === module,
                InvalidModuleException.class,
                MODULE_ALREADY_REGISTERED_MESSAGE,
                new List<String>{ token }
            );
            return ref;
        }

        public virtual ModuleRef getModuleRef(final String token) {
            isTrue(token != null, InvalidModuleException.class, INVALID_MODULE_TOKEN_MESSAGE);

            ModuleRef ref = findModuleRef(token);
            if (ref != null) {
                return ref;
            }

            Module module = create(token);
            return findModuleRef(module.getToken()) ??
                installModule(module, ModuleVisibility.LOCAL_MODULE, isOpen, null);
        }

        public virtual ModuleRef getModuleRef(final Type moduleType) {
            return getModuleRef(moduleType?.getName());
        }

        public virtual ModuleRef addModule(final Module module) {
            return installModule(module, ModuleVisibility.LOCAL_MODULE, isOpen, null);
        }

        public virtual ModuleRef addGlobalModule(final Module module) {
            return installModule(module, ModuleVisibility.GLOBAL_MODULE, isOpen, null);
        }

        public virtual ModuleRef getMetadataModuleRef(final String developerName) {
            return getMetadataModuleRef(developerName, isOpen);
        }

        public virtual void replaceProvider(final String moduleToken, final Provider newProvider) {
            isTrue(moduleToken != null, InvalidModuleException.class, INVALID_MODULE_TOKEN_MESSAGE);
            isTrue(newProvider != null, InvalidProviderException.class, NULL_PROVIDER_MESSAGE);

            ModuleRef ref = findExistingModuleRef(moduleToken);
            isTrue(ref != null, UnknownModuleException.class, UNKNOWN_MODULE_MESSAGE, new List<String>{ moduleToken });

            Module module = ref.getModule();
            ModuleDefinition previousDefinition = module.definition;
            try {
                module.replace(newProvider);
                markGraphChanged();
                invalidateLifecycleHandles();
            } catch (Exception exc) {
                module.definition = previousDefinition;
                throw exc;
            }
        }

        public virtual void replaceProvider(final Type moduleToken, final Provider newProvider) {
            replaceProvider(moduleToken?.getName(), newProvider);
        }

        private ModuleRef installModule(
            final Module module,
            final ModuleVisibility visibility,
            final Boolean invalidateHandlesOnSuccess,
            final String metadataAlias
        ) {
            isTrue(module != null, InvalidModuleException.class, NULL_MODULE_MESSAGE);
            if (visibility === ModuleVisibility.LOCAL_MODULE && !isLoadingGlobalModules) {
                globalRegistry.size();
            }

            String token = module.getToken();
            ModuleRef existingRef = findModuleRef(token);
            if (existingRef != null) {
                isTrue(
                    existingRef.isGlobal() == (visibility === ModuleVisibility.GLOBAL_MODULE),
                    InvalidModuleException.class,
                    MODULE_VISIBILITY_CONFLICT_MESSAGE,
                    new List<String>{
                        token,
                        describeVisibility(visibility),
                        describeVisibility(existingRef.getVisibility())
                    }
                );
            }
            isTrue(
                existingRef == null,
                InvalidModuleException.class,
                MODULE_ALREADY_REGISTERED_MESSAGE,
                new List<String>{ token }
            );

            markGraphChanged();
            Map<String, ModuleRef> registry = getRegistry(visibility);
            ModuleDefinition previousDefinition = module.definition;

            ModuleRef ref = new ModuleRef(this, module, visibility);
            ref.addMetadataAlias(metadataAlias);
            registry.put(token, ref);
            try {
                module.register(this);
                if (visibility === ModuleVisibility.GLOBAL_MODULE) {
                    validateGlobalProviderBindings();
                }
                module.freezeDefinition();
                indexMetadataAlias(metadataAlias, token);
                if (invalidateHandlesOnSuccess) {
                    invalidateLifecycleHandles();
                    return findRegisteredModuleRef(module);
                }
                return ref;
            } catch (Exception exc) {
                if (registry.get(token) === ref) {
                    registry.remove(token);
                }
                module.definition = previousDefinition;
                module.clearContext(this);
                if (!String.isBlank(metadataAlias)) {
                    metadata.moduleTokenByAlias.remove(metadataAlias);
                }
                markGraphChanged();
                throw exc;
            }
        }

        public virtual void replaceModule(final String token, final Module newModule) {
            isTrue(newModule != null, InvalidModuleException.class, INVALID_MODULE_REPLACEMENT_MESSAGE);
            isTrue(token != null, InvalidModuleException.class, INVALID_MODULE_TOKEN_MESSAGE);
            isTrue(
                token.equals(newModule.getToken()),
                InvalidModuleException.class,
                MODULE_TOKEN_MISMATCH_MESSAGE,
                new List<String>{ token, newModule.getToken() }
            );

            ModuleRef oldRef = findExistingModuleRef(token);
            isTrue(oldRef != null, UnknownModuleException.class, UNKNOWN_MODULE_MESSAGE, new List<String>{ token });
            Module oldModule = oldRef.getModule();
            String oldRegistryToken = oldRef.registryToken;

            markGraphChanged();
            Map<String, ModuleRef> registry = getRegistry(oldRef.getVisibility());
            ModuleRef newRef = new ModuleRef(this, newModule, oldRef.getVisibility());
            newRef.addMetadataAliases(oldRef.getMetadataAliases());
            ModuleDefinition previousNewDefinition = newModule.definition;
            newRef.registryToken = token;
            Boolean registryChanged = false;
            try {
                newModule.register(this);
                if (!oldRegistryToken.equals(token)) {
                    registry.remove(oldRegistryToken);
                }
                registry.put(token, newRef);
                registryChanged = true;

                if (oldRef.isGlobal()) {
                    validateGlobalProviderBindings();
                }
                newModule.freezeDefinition();
                if (oldModule !== newModule) {
                    oldModule.clearContext(this);
                }
                invalidateLifecycleHandles();
            } catch (Exception exc) {
                if (registryChanged) {
                    registry.remove(token);
                    registry.put(oldRegistryToken, oldRef);
                }
                newModule.definition = previousNewDefinition;
                newModule.clearContext(this);
                markGraphChanged();
                throw exc;
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

        public virtual ModuleImport importMetadataModule(final String developerName) {
            return new ModuleImport(this, developerName, true);
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

        public virtual ContextDescription describe() {
            List<ModuleDescription> modules = new List<ModuleDescription>();
            addModuleDescriptions(modules, moduleRegistry);
            addModuleDescriptions(modules, globalModuleRegistry);
            return new ContextDescription(isCompiled, modules);
        }

        public virtual void clear() {
            markGraphChanged();
            clearModuleContexts(moduleRegistry);
            clearModuleContexts(globalModuleRegistry);
            lifecycleGeneration++;
            moduleRegistry.clear();
            globalModuleRegistry.clear();
            globalProviderBindings.clear();
            metadata.moduleTokenByAlias.clear();
            globalBindingIndexRevision = graphRevision;
            if (metadata.source instanceof MetadataOverrideSource) {
                metadata.source = ((MetadataOverrideSource) metadata.source).delegate;
            }
            hasGlobalLoadBeenAttempted = false;
            hasGlobalLoadFailed = false;
            isOpen = false;
            metadata.moduleDefinitionByDeveloperName = null;
            metadata.providerDefinitionByDeveloperName = null;
        }
        // </editor-fold>

        protected Module resolveImport(final ModuleImport moduleImport) {
            if (moduleImport.cachedModule != null) {
                return getInternalModuleRef(moduleImport.cachedModule).getModule();
            }
            if (moduleImport.isMetadataImport()) {
                return getMetadataModuleRef(moduleImport.getMetadataAlias(), false).getModule();
            }
            return getInternalModuleRef(moduleImport.getToken()).getModule();
        }

        protected Map<String, MetadataModuleDefinition> getModuleDefinitions() {
            if (metadata.moduleDefinitionByDeveloperName != null) {
                return metadata.moduleDefinitionByDeveloperName;
            }

            Map<String, MetadataModuleDefinition> definitions = metadata.source.getModules();
            metadata.moduleDefinitionByDeveloperName = new Map<String, MetadataModuleDefinition>(
                definitions ?? new Map<String, MetadataModuleDefinition>()
            );
            return metadata.moduleDefinitionByDeveloperName;
        }

        protected Map<String, ProviderDefinition> getProviderDefinitions() {
            if (metadata.providerDefinitionByDeveloperName != null) {
                return metadata.providerDefinitionByDeveloperName;
            }

            Map<String, ProviderDefinition> definitions = metadata.source.getProviders();
            metadata.providerDefinitionByDeveloperName = new Map<String, ProviderDefinition>(
                definitions ?? new Map<String, ProviderDefinition>()
            );
            return metadata.providerDefinitionByDeveloperName;
        }

        protected ModuleRef getRegisteredModuleRef(final Module module) {
            ModuleRef ref = findRegisteredModuleRef(module);
            return ref ?? getInternalModuleRef(module);
        }

        protected void assertNoCircularReexport(final String token) {
            isTrue(
                !moduleRegistrationPath.contains(token),
                InvalidModuleException.class,
                CIRCULAR_REEXPORT_MESSAGE,
                token,
                moduleRegistrationPath
            );
        }

        protected void pushRegistration(final String token) {
            moduleRegistrationPath.add(token);
        }

        protected void popRegistration() {
            moduleRegistrationPath.remove(moduleRegistrationPath.size() - 1);
        }

        // <editor-fold desc="Helpers">
        @TestVisible
        private void mockModules(final Iterable<DI_Module__mdt> mockModules) {
            markGraphChanged();
            metadata.moduleDefinitionByDeveloperName = null;
            metadata.moduleTokenByAlias.clear();
            getMetadataOverrideSource().modules = normalizeModuleDefinitions(mockModules);
            hasGlobalLoadBeenAttempted = false;
            hasGlobalLoadFailed = false;
            if (isOpen) {
                invalidateLifecycleHandles();
            }
        }

        @TestVisible
        private void mockProviders(final Map<String, DI_Provider__mdt> providerByDeveloperName) {
            markGraphChanged();
            metadata.providerDefinitionByDeveloperName = null;
            getMetadataOverrideSource().providers = normalizeProviderDefinitions(providerByDeveloperName);
            if (isOpen) {
                invalidateLifecycleHandles();
            }
        }

        private MetadataOverrideSource getMetadataOverrideSource() {
            if (!(metadata.source instanceof MetadataOverrideSource)) {
                metadata.source = new MetadataOverrideSource(metadata.source);
            }
            return (MetadataOverrideSource) metadata.source;
        }

        private ModuleRef getMetadataModuleRef(final String developerName, final Boolean invalidateHandlesOnSuccess) {
            isTrue(
                !String.isBlank(developerName),
                UnknownModuleException.class,
                UNKNOWN_METADATA_MODULE_MESSAGE,
                developerName
            );

            MetadataModuleDefinition definition = getModuleDefinitions().get(developerName);
            isTrue(definition != null, UnknownModuleException.class, UNKNOWN_METADATA_MODULE_MESSAGE, developerName);
            isTrue(
                definition.isActive == true,
                InvalidModuleException.class,
                INACTIVE_METADATA_MODULE_MESSAGE,
                developerName
            );

            if (definition.isGlobal == true && !isLoadingGlobalModules) {
                globalRegistry.size();
                ModuleRef loadedRef = findMetadataModuleRef(developerName);
                if (loadedRef != null) {
                    return loadedRef;
                }
            }
            return installMetadataModule(definition, invalidateHandlesOnSuccess);
        }

        private ModuleRef installMetadataModule(
            final MetadataModuleDefinition definition,
            final Boolean invalidateHandlesOnSuccess
        ) {
            Module module = create(definition.moduleClass);
            ModuleVisibility visibility = definition.isGlobal == true
                ? ModuleVisibility.GLOBAL_MODULE
                : ModuleVisibility.LOCAL_MODULE;
            ModuleRef existingRef = findModuleRef(module.getToken());
            if (existingRef != null) {
                isTrue(
                    existingRef.getVisibility() === visibility,
                    InvalidModuleException.class,
                    MODULE_VISIBILITY_CONFLICT_MESSAGE,
                    new List<String>{
                        module.getToken(),
                        describeVisibility(visibility),
                        describeVisibility(existingRef.getVisibility())
                    }
                );
                isTrue(
                    existingRef.getRuntimeModule().getClassName() == module.getClassName(),
                    InvalidModuleException.class,
                    MODULE_ALREADY_REGISTERED_MESSAGE,
                    new List<String>{ module.getToken() }
                );
                existingRef.addMetadataAlias(definition.developerName);
                indexMetadataAlias(definition.developerName, module.getToken());
                return existingRef;
            }

            return installModule(module, visibility, invalidateHandlesOnSuccess, definition.developerName);
        }

        private ModuleRef findMetadataModuleRef(final String developerName) {
            String token = metadata.moduleTokenByAlias.get(developerName);
            return token != null ? findModuleRef(token) : null;
        }

        private void indexMetadataAlias(final String developerName, final String token) {
            if (!String.isBlank(developerName)) {
                metadata.moduleTokenByAlias.put(developerName, token);
            }
        }

        private Map<String, ModuleRef> getRegistry(final ModuleVisibility visibility) {
            return visibility === ModuleVisibility.GLOBAL_MODULE ? globalModuleRegistry : moduleRegistry;
        }

        private String describeVisibility(final ModuleVisibility visibility) {
            return visibility === ModuleVisibility.GLOBAL_MODULE ? 'global' : 'local';
        }

        private ProviderBinding getVisibleProviderBinding(final Module module, final String token) {
            Map<String, ProviderBinding> visibleProviders = visibleProvidersByModuleKey.get(getModuleKey(module));
            return visibleProviders?.get(token);
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

        private ModuleRef getInternalModuleRef(final Module module) {
            ModuleRef ref = findRegisteredModuleRef(module);
            return ref ?? installModule(module, ModuleVisibility.LOCAL_MODULE, false, null);
        }

        private ModuleRef getInternalModuleRef(final String token) {
            ModuleRef ref = findModuleRef(token);
            if (ref != null) {
                return ref;
            }

            Module module = create(token);
            return findModuleRef(module.getToken()) ??
                installModule(module, ModuleVisibility.LOCAL_MODULE, false, null);
        }

        private ModuleRef findExistingModuleRef(final String token) {
            ModuleRef ref = findModuleRef(token);
            if (ref != null) {
                return ref;
            }

            Type moduleType = Type.forName(token);
            if (moduleType == null) {
                return null;
            }

            Object raw;
            try {
                raw = moduleType.newInstance();
            } catch (Exception exc) {
                return null;
            }

            if (!(raw instanceof Module)) {
                return null;
            }
            return findModuleRef(((Module) raw).getToken());
        }

        private ModuleRef findModuleRef(String token) {
            return moduleRegistry.get(token) ?? globalRegistry.get(token);
        }

        private ModuleRef findRegisteredModuleRef(final Module module) {
            return findModuleRef(module.getToken());
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

        private void open() {
            isOpen = true;
        }

        private void addModuleDescriptions(
            final List<ModuleDescription> descriptions,
            final Map<String, ModuleRef> registry
        ) {
            List<String> registryTokens = new List<String>(registry.keySet());
            registryTokens.sort();
            for (String registryToken : registryTokens) {
                descriptions.add(describeModule(registry.get(registryToken)));
            }
        }

        private ModuleDescription describeModule(final ModuleRef ref) {
            Module module = ref.getRuntimeModule();
            List<String> providerTokens = new List<String>(module.definition.providers.keySet());
            providerTokens.sort();
            List<ProviderDescription> providers = new List<ProviderDescription>();
            for (String providerToken : providerTokens) {
                Provider provider = module.definition.providers.get(providerToken);
                providers.add(describeProvider(module, providerToken, provider));
            }

            List<String> exports = new List<String>(module.definition.exports);
            exports.sort();
            return new ModuleDescription(
                module.getToken(),
                ref.isGlobal(),
                ref.getMetadataAliases(),
                providers,
                exports,
                describeModuleImports(module.definition.imports),
                describeModuleImports(module.definition.reexports)
            );
        }

        private ProviderDescription describeProvider(final Module module, final String token, final Provider provider) {
            ProviderDefinition metadataDefinition;
            ProviderConfigurationStatus configurationStatus = ProviderConfigurationStatus.VALID;
            if (provider instanceof CustomMetadataTypesProvider) {
                metadataDefinition = ((CustomMetadataTypesProvider) provider).findDefinition(this);
                configurationStatus = describeMetadataConfiguration(metadataDefinition);
            }

            return new ProviderDescription(
                token,
                provider.getKind(),
                configurationStatus,
                describeProviderScope(provider, configurationStatus, metadataDefinition),
                describeProviderRedirect(provider, configurationStatus, metadataDefinition),
                module.definition.exports.contains(token)
            );
        }

        private ProviderConfigurationStatus describeMetadataConfiguration(final ProviderDefinition definition) {
            if (definition == null) {
                return ProviderConfigurationStatus.MISSING_METADATA;
            }
            if (definition.isActive != true) {
                return ProviderConfigurationStatus.INACTIVE_METADATA;
            }
            if (!String.isBlank(definition.scope)) {
                try {
                    Scope.valueOf(definition.scope);
                } catch (Exception exc) {
                    return ProviderConfigurationStatus.INVALID_METADATA;
                }
            }
            switch on definition.type {
                when 'Class', 'Value', 'Factory', 'Existing' {
                    return ProviderConfigurationStatus.VALID;
                }
                when else {
                    return ProviderConfigurationStatus.INVALID_METADATA;
                }
            }
        }

        private Scope describeProviderScope(
            final Provider provider,
            final ProviderConfigurationStatus configurationStatus,
            final ProviderDefinition metadataDefinition
        ) {
            if (!(provider instanceof CustomMetadataTypesProvider)) {
                return provider.getScope();
            }
            return configurationStatus === ProviderConfigurationStatus.VALID &&
                !String.isBlank(metadataDefinition.scope)
                ? Scope.valueOf(metadataDefinition.scope)
                : provider.getConfiguredScope();
        }

        private String describeProviderRedirect(
            final Provider provider,
            final ProviderConfigurationStatus configurationStatus,
            final ProviderDefinition metadataDefinition
        ) {
            if (provider instanceof ExistingProvider) {
                return ((ExistingProvider) provider).getExisting();
            }
            if (
                provider instanceof CustomMetadataTypesProvider &&
                configurationStatus === ProviderConfigurationStatus.VALID &&
                metadataDefinition.type == 'Existing'
            ) {
                return metadataDefinition.value;
            }
            return null;
        }

        private List<ModuleImportDescription> describeModuleImports(final Set<ModuleImport> moduleImports) {
            Map<String, ModuleImport> moduleImportByKey = new Map<String, ModuleImport>();
            for (ModuleImport moduleImport : moduleImports) {
                String key = (moduleImport.isMetadataImport() ? 'metadata:' : 'module:') + moduleImport.getToken();
                moduleImportByKey.put(key, moduleImport);
            }

            List<String> keys = new List<String>(moduleImportByKey.keySet());
            keys.sort();
            List<ModuleImportDescription> descriptions = new List<ModuleImportDescription>();
            for (String key : keys) {
                ModuleImport moduleImport = moduleImportByKey.get(key);
                descriptions.add(
                    new ModuleImportDescription(
                        moduleImport.getToken(),
                        moduleImport.isEager,
                        moduleImport.getMetadataAlias()
                    )
                );
            }
            return descriptions;
        }

        private void invalidateLifecycleHandles() {
            lifecycleGeneration++;
            reissueModuleRefs(moduleRegistry);
            reissueModuleRefs(globalModuleRegistry);
            markGraphChanged();
        }

        private void reissueModuleRefs(final Map<String, ModuleRef> registry) {
            Map<String, ModuleRef> previousRefs = new Map<String, ModuleRef>(registry);
            registry.clear();
            for (String registryToken : previousRefs.keySet()) {
                ModuleRef previousRef = previousRefs.get(registryToken);
                ModuleRef ref = new ModuleRef(this, previousRef.getRuntimeModule(), previousRef.getVisibility());
                ref.addMetadataAliases(previousRef.getMetadataAliases());
                ref.registryToken = registryToken;
                registry.put(registryToken, ref);
            }
        }

        private List<ModuleRef> snapshotModuleRefs(final Map<String, ModuleRef> registry) {
            return new List<ModuleRef>(registry.values());
        }

        private String getModuleKey(final Module module) {
            return getRegisteredModuleRef(module).moduleKey();
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
                InvalidModuleException.class,
                CIRCULAR_MODULE_IMPORT_MESSAGE,
                new List<String>{ module.getToken() }
            );
            compilingModuleKeys.add(moduleKey);
            try {
                Map<String, ProviderBinding> visibleProviders = new Map<String, ProviderBinding>();
                Set<String> localProviderTokens = new Set<String>();
                ModuleRef owner = getRegisteredModuleRef(module);

                for (Provider provider : module.definition.providers.values()) {
                    localProviderTokens.add(provider.getToken());
                    visibleProviders.put(provider.getToken(), new ProviderBinding(provider, owner));
                }

                Set<ModuleImport> searchScope = new Set<ModuleImport>();
                searchScope.addAll(module.definition.imports);
                searchScope.addAll(module.definition.reexports);
                for (ModuleImport moduleImport : searchScope) {
                    Module importedModule = resolveImport(moduleImport);
                    Map<String, ProviderBinding> importedProviders = compileModule(
                        importedModule,
                        compiledProvidersByModuleKey,
                        compilingModuleKeys
                    );
                    for (String token : importedModule.definition.exports) {
                        if (localProviderTokens.contains(token)) {
                            continue;
                        }
                        ProviderBinding provider = importedProviders.get(token);
                        isTrue(
                            provider != null,
                            UnknownExportException.class,
                            UNKNOWN_EXPORT_MESSAGE,
                            new List<String>{ token, importedModule.getToken() }
                        );
                        ProviderBinding selectedProvider = visibleProviders.get(token);
                        if (selectedProvider == null) {
                            visibleProviders.put(token, provider);
                            continue;
                        }
                        isTrue(
                            selectedProvider.getOwner() === provider.getOwner(),
                            InvalidProviderException.class,
                            AMBIGUOUS_IMPORTED_PROVIDER_MESSAGE,
                            new List<String>{
                                token,
                                module.getToken(),
                                selectedProvider.getOwner().getModule().getToken(),
                                provider.getOwner().getModule().getToken()
                            }
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
            Map<String, List<String>> previousMetadataAliasesByToken = snapshotMetadataAliases(globalModuleRegistry);
            Map<String, String> previousMetadataModuleTokenByAlias = new Map<String, String>(
                metadata.moduleTokenByAlias
            );
            Boolean previousLoadAttempted = hasGlobalLoadBeenAttempted;
            isLoadingGlobalModules = true;
            try {
                List<String> developerNames = new List<String>(getModuleDefinitions().keySet());
                developerNames.sort();
                for (String developerName : developerNames) {
                    MetadataModuleDefinition moduleDef = getModuleDefinitions().get(developerName);
                    if (moduleDef.isActive != true || moduleDef.isGlobal != true) {
                        continue;
                    }
                    installMetadataModule(moduleDef, false);
                }
                hasGlobalLoadBeenAttempted = true;
                hasGlobalLoadFailed = false;
            } catch (Exception exc) {
                clearNewModuleContexts(globalModuleRegistry, previousGlobalRegistry);
                globalModuleRegistry.clear();
                globalModuleRegistry.putAll(previousGlobalRegistry);
                restoreMetadataAliases(globalModuleRegistry, previousMetadataAliasesByToken);
                metadata.moduleTokenByAlias.clear();
                metadata.moduleTokenByAlias.putAll(previousMetadataModuleTokenByAlias);
                hasGlobalLoadBeenAttempted = previousLoadAttempted;
                hasGlobalLoadFailed = true;
                markGraphChanged();
                throw exc;
            } finally {
                isLoadingGlobalModules = false;
            }
        }

        private void clearNewModuleContexts(
            final Map<String, ModuleRef> currentRegistry,
            final Map<String, ModuleRef> previousRegistry
        ) {
            for (String token : currentRegistry.keySet()) {
                ModuleRef currentRef = currentRegistry.get(token);
                if (previousRegistry.get(token) !== currentRef) {
                    currentRef.getRuntimeModule().clearContext(this);
                }
            }
        }

        private Map<String, List<String>> snapshotMetadataAliases(final Map<String, ModuleRef> registry) {
            Map<String, List<String>> aliasesByToken = new Map<String, List<String>>();
            for (String token : registry.keySet()) {
                aliasesByToken.put(token, registry.get(token).getMetadataAliases());
            }
            return aliasesByToken;
        }

        private void restoreMetadataAliases(
            final Map<String, ModuleRef> registry,
            final Map<String, List<String>> aliasesByToken
        ) {
            for (String token : aliasesByToken.keySet()) {
                registry.get(token)?.setMetadataAliases(aliasesByToken.get(token));
            }
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
                for (String token : module.definition.exports) {
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
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);

            ProviderBinding provider = module.getProviderBinding(token, false);
            isTrue(
                provider != null,
                UnknownExportException.class,
                UNKNOWN_EXPORT_MESSAGE,
                new List<String>{ token, module.getToken() }
            );

            ProviderBinding existingProvider = globalBindings.get(token);
            String existingModuleToken = existingProvider?.getOwner().getModule().getToken();
            isTrue(
                existingProvider == null || existingProvider.getOwner() === provider.getOwner(),
                InvalidProviderException.class,
                DUPLICATE_GLOBAL_PROVIDER_MESSAGE,
                new List<String>{ token, module.getToken(), existingModuleToken }
            );

            globalBindings.put(token, provider);
        }
        // </editor-fold>
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

        public DynamicModule addImport(final ModuleImport moduleImport) {
            validateConfigurable();
            isTrue(moduleImport != null, InvalidModuleException.class, NULL_MODULE_IMPORT_MESSAGE);

            dynamicImports.add(moduleImport);
            return this;
        }

        public DynamicModule addProvider(final Provider provider) {
            validateConfigurable();
            isTrue(provider != null, InvalidProviderException.class, NULL_PROVIDER_MESSAGE);

            dynamicProviders.put(provider.getToken(), provider);
            return this;
        }

        public DynamicModule addExport(final String token) {
            validateConfigurable();
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);

            dynamicExports.add(token);
            return this;
        }

        public DynamicModule addReexport(final ModuleImport moduleImport) {
            validateConfigurable();
            isTrue(moduleImport != null, InvalidModuleException.class, NULL_MODULE_IMPORT_MESSAGE);

            dynamicReexports.add(moduleImport);
            return this;
        }

        private void validateConfigurable() {
            isTrue(!isSealed(), InvalidModuleException.class, SEALED_DYNAMIC_MODULE_MESSAGE, token);
        }
    }

    public virtual inherited sharing class ProviderBuilder {
        protected final String token;

        protected ProviderBuilder(final String token) {
            isTrue(token != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);

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

    public virtual inherited sharing class ClassProvider extends Provider {
        protected final String typeName;

        public ClassProvider(final String token, final String type) {
            super(token);
            isTrue(
                type != null,
                InvalidProviderException.class,
                INVALID_PROVIDER_TYPE_MESSAGE,
                new List<String>{ token }
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
            isTrue(args == null, InvalidProviderException.class, ARGS_NOT_SUPPORTED_MESSAGE);
            return instantiate(typeName);
        }

        public String getType() {
            return typeName;
        }

        protected override ProviderKind getKind() {
            return ProviderKind.CLASS_PROVIDER;
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
            isTrue(args == null, InvalidProviderException.class, ARGS_NOT_SUPPORTED_MESSAGE);
            return value;
        }

        protected override ProviderKind getKind() {
            return ProviderKind.VALUE_PROVIDER;
        }
    }

    public virtual inherited sharing class FactoryProvider extends Provider {
        protected final Factory factory;

        public FactoryProvider(final String token, final Factory factory) {
            super(token);
            isTrue(factory != null, InvalidProviderException.class, NULL_PROVIDER_FACTORY_MESSAGE);

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

        protected override ProviderKind getKind() {
            return ProviderKind.FACTORY_PROVIDER;
        }
    }

    public virtual inherited sharing class ExistingProvider extends Provider {
        protected final String existing;

        public ExistingProvider(final String token, final String existing) {
            super(token);
            isTrue(existing != null, InvalidProviderException.class, INVALID_PROVIDER_TOKEN_MESSAGE);

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

        public override Object resolve(final Container container, final Object args) {
            throw new InvalidProviderException(INVALID_OPERATION_MESSAGE);
        }

        public String getExisting() {
            return existing;
        }

        protected override ProviderKind getKind() {
            return ProviderKind.EXISTING_PROVIDER;
        }
    }

    public virtual inherited sharing class CustomMetadataTypesProvider extends Provider {
        protected final String developerName;

        // <editor-fold desc="Provider API">
        public CustomMetadataTypesProvider(final String token, final String developerName) {
            super(token);
            isTrue(!String.isBlank(developerName), InvalidProviderException.class, INVALID_DEVELOPER_NAME_MESSAGE);

            this.developerName = developerName;
        }

        public override Scope getScope() {
            return getScope(DEFAULT_CONTEXT);
        }

        public override Object resolve(final Container container, final Object args) {
            ProviderDefinition definition = getDefinition(container.context);
            Scope scopeType = !String.isBlank(definition.scope) ? parseMetadataScope(definition) : super.getScope();
            // Runtime args have the highest priority
            Object factoryArgs = args ?? definition.args;
            String typeName = definition.type;
            String value = definition.value;
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

        public String getExisting() {
            return getExisting(DEFAULT_CONTEXT);
        }
        // </editor-fold>

        protected override ProviderKind getKind() {
            return ProviderKind.METADATA_PROVIDER;
        }

        protected Scope getScope(final ApplicationContext context) {
            ProviderDefinition definition = context.getProviderDefinitions().get(developerName);
            if (String.isBlank(definition?.scope)) {
                return super.getScope();
            }
            return parseMetadataScope(definition);
        }

        protected String getExisting(final ApplicationContext context) {
            ProviderDefinition definition = getDefinition(context);
            return definition.type == 'Existing' ? definition.value : null;
        }

        // <editor-fold desc="Helpers">
        private ProviderDefinition findDefinition(final ApplicationContext context) {
            return context.getProviderDefinitions().get(developerName);
        }

        private ProviderDefinition getDefinition(final ApplicationContext context) {
            ProviderDefinition definition = findDefinition(context);
            isTrue(
                definition != null,
                InvalidProviderException.class,
                MISSING_METADATA_PROVIDER_MESSAGE,
                new List<String>{ token, developerName }
            );
            isTrue(
                definition.isActive,
                InvalidProviderException.class,
                INACTIVE_METADATA_PROVIDER_MESSAGE,
                new List<String>{ token, developerName }
            );
            return definition;
        }

        private Scope parseMetadataScope(final ProviderDefinition definition) {
            try {
                return Scope.valueOf(definition.scope);
            } catch (Exception exc) {
                throw new InvalidProviderException(
                    String.format(
                        INVALID_METADATA_SCOPE_MESSAGE,
                        new List<String>{ definition.scope, token, developerName }
                    )
                );
            }
        }
        // </editor-fold>
    }

    public virtual class ModuleRef extends Container {
        protected String registryToken;

        private ModuleRef(final ApplicationContext context, final Module module, final ModuleVisibility visibility) {
            super(context, null, module, visibility);
            registryToken = module.getToken();
            enableResolutionMemo();
        }

        // <editor-fold desc="Module API">
        public virtual ScopeRef createScope() {
            return createScope(new ScopeContext());
        }

        public virtual ScopeRef createScope(final ScopeContext scopeContext) {
            isTrue(scopeContext != null, InvalidScopeException.class, NULL_SCOPE_CONTEXT_MESSAGE);
            validateContextGeneration();
            return new ScopeRef(this, scopeContext);
        }

        public virtual override Object resolve(final String token, final Object args) {
            return super.resolve(token, args);
        }

        public virtual void clearCache() {
            validateContextGeneration();
            clearSingletons();
        }
        // </editor-fold>

        protected virtual override Object getInstance(final Provider provider, final Object args) {
            Scope providerScope = getProviderScope(provider);
            isTrue(
                providerScope !== Scope.SCOPED,
                InvalidScopeException.class,
                SCOPED_ROOT_ACCESS_ERROR_MESSAGE,
                new List<String>{ provider.getToken() }
            );
            String key = provider.getToken();
            if (providerScope == Scope.SINGLETON && hasSingleton(key)) {
                return getSingleton(key);
            }
            Object instance = newInstance(provider, args);
            if (providerScope == Scope.SINGLETON) {
                putSingleton(key, instance);
            }
            try {
                return autowire(instance);
            } catch (Exception e) {
                if (providerScope == Scope.SINGLETON) {
                    removeSingleton(key);
                }
                throw e;
            }
        }

        protected override Object resolveInstance(final Provider provider, final Object args) {
            isTrue(
                getProviderScope(provider) !== Scope.SCOPED,
                InvalidScopeException.class,
                SCOPED_ROOT_ACCESS_ERROR_MESSAGE,
                new List<String>{ provider.getToken() }
            );
            return super.resolveInstance(provider, args);
        }

        protected override Boolean hasInCache(final String token) {
            return hasSingleton(token);
        }

        protected override void validateAndAddPath(String token) {
            if (hasInCache(token)) {
                return;
            }
            super.validateAndAddPath(token);
        }

        protected override Object getInternal(final String token, final Object args) {
            return super.getInternal(token, args);
        }

        protected override Object resolveInternal(final String token, final Object args) {
            return super.resolveInternal(token, args);
        }

        private Boolean isGlobal() {
            return getVisibility() === ModuleVisibility.GLOBAL_MODULE;
        }

        private String moduleKey() {
            return (isGlobal() ? 'global:' : 'local:') + getRuntimeModule().getToken();
        }

        private void addMetadataAlias(final String metadataAlias) {
            getRuntime().addMetadataAlias(metadataAlias);
        }

        private void addMetadataAliases(final List<String> metadataAliases) {
            getRuntime().addMetadataAliases(metadataAliases);
        }

        private List<String> getMetadataAliases() {
            return getRuntime().getMetadataAliases();
        }

        private void setMetadataAliases(final List<String> metadataAliases) {
            getRuntime().setMetadataAliases(metadataAliases);
        }
    }

    public virtual class ScopeContext {
        private final Map<String, Map<String, Object>> scopedCacheByOwner = new Map<String, Map<String, Object>>();
        private ApplicationContext context;
        private Integer graphRevision;
        private Integer generation = 0;

        // <editor-fold desc="Scope API">
        public virtual void clear() {
            scopedCacheByOwner.clear();
            graphRevision = context?.graphRevision;
            generation++;
        }
        // </editor-fold>

        // <editor-fold desc="Helpers">
        private void bind(final ApplicationContext context) {
            isTrue(
                this.context == null || this.context === context,
                InvalidScopeException.class,
                SCOPE_CONTEXT_MISMATCH_MESSAGE
            );
            if (this.context == null) {
                this.context = context;
                graphRevision = context.graphRevision;
            }
        }

        private void synchronize() {
            if (graphRevision != context.graphRevision) {
                clear();
            }
        }

        private void acceptCurrentRevision() {
            graphRevision = context.graphRevision;
        }

        private Boolean contains(final Module ownerModule, final String providerToken) {
            Map<String, Object> scopedCache = scopedCacheByOwner.get(getOwnerKey(ownerModule));
            return scopedCache != null && scopedCache.containsKey(providerToken);
        }

        private Object get(final Module ownerModule, final String providerToken) {
            Map<String, Object> scopedCache = scopedCacheByOwner.get(getOwnerKey(ownerModule));
            return scopedCache?.get(providerToken);
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
            scopedCache?.remove(providerToken);
        }

        private String getOwnerKey(final Module ownerModule) {
            return context.getModuleKey(ownerModule);
        }
        // </editor-fold>
    }

    public virtual class ScopeRef extends Container {
        protected final ScopeContext scopeContext;
        protected final Map<String, ScopeRef> ownerScopes = new Map<String, ScopeRef>();
        private Integer scopeGeneration;

        protected ScopeRef(final ModuleRef parent, final ScopeContext scopeContext) {
            super(parent.context, parent, parent.getModule(), parent.getVisibility());
            adoptRuntime(parent);
            this.scopeContext = scopeContext;
            scopeContext.bind(context);
            scopeGeneration = scopeContext.generation;
        }

        // <editor-fold desc="Scope API">
        public override Object get(final String token, final Object args) {
            validateContextGeneration();
            Boolean isTopLevelResolution = !inCall;
            if (isTopLevelResolution) {
                synchronizeScopeContext();
            }
            try {
                return super.get(token, args);
            } finally {
                if (isTopLevelResolution) {
                    scopeContext.acceptCurrentRevision();
                }
            }
        }

        public override Object resolve(final String token, final Object args) {
            validateContextGeneration();
            Boolean isTopLevelResolution = !inCall;
            if (isTopLevelResolution) {
                synchronizeScopeContext();
            }
            try {
                return super.resolve(token, args);
            } finally {
                if (isTopLevelResolution) {
                    scopeContext.acceptCurrentRevision();
                }
            }
        }

        public virtual void clearCache() {
            validateContextGeneration();
            scopeContext.clear();
            ownerScopes.clear();
            scopeGeneration = scopeContext.generation;
        }
        // </editor-fold>

        protected virtual override Object getInstance(final Provider provider, final Object args) {
            if (getProviderScope(provider) !== Scope.SCOPED) {
                return parent.getInstance(provider, args);
            }

            String key = provider.getToken();
            Module ownerModule = getModule();
            if (scopeContext.contains(ownerModule, key)) {
                return scopeContext.get(ownerModule, key);
            }
            Object instance = newInstance(provider, args);
            scopeContext.put(ownerModule, key, instance);
            try {
                return autowire(instance);
            } catch (Exception e) {
                scopeContext.remove(ownerModule, key);
                throw e;
            }
        }

        protected override Object getInternal(final String token, final Object args) {
            return super.getInternal(token, args);
        }

        protected override Object resolveInternal(final String token, final Object args) {
            return super.resolveInternal(token, args);
        }

        protected override Boolean hasInCache(final String token) {
            return scopeContext.contains(getModule(), token);
        }

        protected override Container getResolutionContainer(final ModuleRef owner) {
            if (owner === parent) {
                return this;
            }

            String ownerScopeKey = owner.moduleKey();
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

        // <editor-fold desc="Helpers">
        private void synchronizeScopeContext() {
            scopeContext.synchronize();
            if (scopeGeneration != scopeContext.generation) {
                ownerScopes.clear();
                scopeGeneration = scopeContext.generation;
            }
        }
        // </editor-fold>
    }

    public virtual class ModuleImport {
        protected ApplicationContext context;
        protected final String token;
        protected Boolean isEager = false;
        private final Boolean metadataImport;
        protected Module cachedModule;

        protected ModuleImport(final String token) {
            this(DEFAULT_CONTEXT, token, false);
        }

        protected ModuleImport(final ApplicationContext context, final String token) {
            this(context, token, false);
        }

        private ModuleImport(final ApplicationContext context, final String token, final Boolean metadataImport) {
            isTrue(token != null, InvalidModuleException.class, INVALID_MODULE_TOKEN_MESSAGE);

            this.context = context ?? DEFAULT_CONTEXT;
            this.token = token;
            this.metadataImport = metadataImport;
        }

        protected ModuleImport(final Module module) {
            this(DEFAULT_CONTEXT, module);
        }

        protected ModuleImport(final ApplicationContext context, final Module module) {
            isTrue(module != null, InvalidModuleException.class, NULL_MODULE_MESSAGE);

            this.context = context ?? DEFAULT_CONTEXT;
            token = module.getToken();
            metadataImport = false;
            cachedModule = module;
        }

        public virtual ModuleImport immediately() {
            isEager = true;
            return this;
        }

        public virtual Module resolve() {
            return context.resolveImport(this);
        }

        public String getToken() {
            return token;
        }

        private Boolean isMetadataImport() {
            return metadataImport;
        }

        private String getMetadataAlias() {
            return metadataImport ? token : null;
        }

        public Boolean equals(Object obj) {
            if (!(obj instanceof ModuleImport)) {
                return false;
            }
            ModuleImport other = (ModuleImport) obj;
            return other.getToken().equals(token) && other.isMetadataImport() == metadataImport;
        }

        public Integer hashCode() {
            return System.hashCode((metadataImport ? 'metadata:' : 'module:') + token);
        }
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
    public virtual class InvalidContextException extends DiException {
    }
    public virtual class CircularDependencyException extends DiException {
    }

    private class BindingExplanation {
        private ResolutionStatus status = ResolutionStatus.NOT_FOUND;
        private ResolutionSource source = ResolutionSource.NONE;
        private ProviderBinding binding;
        private final List<String> conflictingModules = new List<String>();

        private void resolve(final ResolutionSource source, final ProviderBinding binding) {
            status = ResolutionStatus.RESOLVED;
            this.source = source;
            this.binding = binding;
        }

        private void ambiguous(final ProviderBinding left, final ProviderBinding right) {
            status = ResolutionStatus.AMBIGUOUS;
            source = ResolutionSource.IMPORTED;
            addConflict(left);
            addConflict(right);
        }

        private void ambiguous(final BindingExplanation nestedExplanation) {
            status = ResolutionStatus.AMBIGUOUS;
            source = ResolutionSource.IMPORTED;
            conflictingModules.addAll(nestedExplanation.conflictingModules);
        }

        private void addConflict(final ProviderBinding provider) {
            String ownerToken = provider.getOwner().getRuntimeModule().getToken();
            if (!conflictingModules.contains(ownerToken)) {
                conflictingModules.add(ownerToken);
            }
        }
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

    private class ModuleDefinition {
        private final Map<String, Provider> providers;
        private final Set<String> exports;
        private final Set<ModuleImport> imports;
        private final Set<ModuleImport> reexports;

        private ModuleDefinition(
            final Map<String, Provider> providers,
            final Set<String> exports,
            final Set<ModuleImport> imports,
            final Set<ModuleImport> reexports
        ) {
            this.providers = new Map<String, Provider>(providers);
            this.exports = new Set<String>(exports);
            this.imports = new Set<ModuleImport>(imports);
            this.reexports = new Set<ModuleImport>(reexports);
        }
    }

    private class MetadataOverrideSource implements MetadataSource {
        private final MetadataSource delegate;
        private Map<String, MetadataModuleDefinition> modules;
        private Map<String, ProviderDefinition> providers;

        private MetadataOverrideSource(final MetadataSource delegate) {
            this.delegate = delegate;
        }

        public Map<String, MetadataModuleDefinition> getModules() {
            return modules ?? delegate.getModules();
        }

        public Map<String, ProviderDefinition> getProviders() {
            return providers ?? delegate.getProviders();
        }
    }

    private class MetadataState {
        private final Map<String, String> moduleTokenByAlias = new Map<String, String>();
        private MetadataSource source;
        private Map<String, MetadataModuleDefinition> moduleDefinitionByDeveloperName;
        private Map<String, ProviderDefinition> providerDefinitionByDeveloperName;

        private MetadataState(final MetadataSource source) {
            this.source = source;
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

    private class ModuleRuntime {
        private final Module module;
        private final ModuleVisibility visibility;
        private final Set<String> metadataAliases = new Set<String>();
        private final Map<String, Object> singletonCache = new Map<String, Object>();

        private ModuleRuntime(final Module module, final ModuleVisibility visibility) {
            isTrue(module != null, InvalidModuleException.class, NULL_MODULE_MESSAGE);
            this.module = module;
            this.visibility = visibility;
        }

        private void addMetadataAlias(final String metadataAlias) {
            if (!String.isBlank(metadataAlias)) {
                metadataAliases.add(metadataAlias);
            }
        }

        private void addMetadataAliases(final List<String> metadataAliases) {
            this.metadataAliases.addAll(metadataAliases);
        }

        private List<String> getMetadataAliases() {
            List<String> aliases = new List<String>(metadataAliases);
            aliases.sort();
            return aliases;
        }

        private void setMetadataAliases(final List<String> metadataAliases) {
            this.metadataAliases.clear();
            this.metadataAliases.addAll(metadataAliases);
        }
    }

    private class ResolvedPlan {
        private final Provider provider;
        private final ModuleRef owner;
        private final Scope scope;
        private final Integer graphRevision;

        private ResolvedPlan(
            final Provider provider,
            final ModuleRef owner,
            final Scope scope,
            final Integer graphRevision
        ) {
            this.provider = provider;
            this.owner = owner;
            this.scope = scope;
            this.graphRevision = graphRevision;
        }
    }
}
