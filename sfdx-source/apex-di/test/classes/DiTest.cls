@IsTest(IsParallel=true)
@SuppressWarnings('PMD.ApexDoc')
private class DiTest {
    private static Integer metadataModuleInstantiationCount = 0;

    static {
        // A private constructor to satisfy the static-only class pattern and improve coverage.
        new Di();
        // Arrange: Clear all DI registries before each test run to ensure isolation.
        Di.clear();
        // Arrange: Mock global modules to prevent unintended loading from metadata in tests.
        Di.mockModules(new List<DI_Module__mdt>());
        // Arrange: Mock providers to prevent unintended loading from metadata in tests.
        Di.mockProviders(new Map<String, DI_Provider__mdt>());
    }

    // <editor-fold desc="Core Providers">
    @IsTest
    static void should_return_same_instance_when_using_singleton_scope() {
        // Arrange: A module with a default (singleton) provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);

        // Act: The provider is requested twice using get().
        Object o1 = ref.get('TestService');
        Object o2 = ref.get('TestService');

        // Assert: Both retrieved objects are the same instance.
        Assert.areEqual(o1, o2, 'Singleton provider should return the same instance on every get() call.');
    }

    @IsTest
    static void should_return_new_instance_when_using_resolve() {
        // Arrange: A module with a singleton provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);

        // Act: The provider is requested twice using resolve().
        Object r1 = ref.resolve('TestService');
        Object r2 = ref.resolve('TestService');

        // Assert: The two retrieved objects are different instances.
        Assert.areNotEqual(r1, r2, 'resolve() should always create a new instance, regardless of scope.');
    }

    @IsTest
    static void should_create_module_ref_when_using_default_application_context() {
        // Arrange: A module instance is registered through the default application context facade.
        SingleModule module = new SingleModule();

        // Act: Request the context-owned runtime handle twice.
        Di.ModuleRef ref = Di.getModuleRef(module);
        Di.ModuleRef repeatedRef = Di.getModuleRef(module);

        // Assert: Registration commits the definition, preserves identity, and reuses one runtime.
        Assert.areEqual(module, ref.getModule());
        Assert.areEqual(ref, repeatedRef);
        Assert.isTrue(ref.get('TestService') instanceof TestServiceImpl);
    }

    @IsTest
    static void should_evict_from_cache_when_injection_fails() {
        // Arrange
        InjectionFailureModule module = new InjectionFailureModule();
        Di.addModule(module);
        Di.ModuleRef ref = Di.getModuleRef(InjectionFailureModule.class);

        // Act: First attempt fails
        try {
            ref.get('BrokenService');
            Assert.fail('Should have thrown exception');
        } catch (Di.DiException e) {
            // Assert: Verify the expected outcome.
            Assert.areEqual('Injection Failed Intentional', e.getMessage());
        }

        // Act: Second attempt should TRY AGAIN usually creating a new instance
        try {
            ref.get('BrokenService');
            Assert.fail('Should have thrown exception on second attempt too');
        } catch (Di.DiException e) {
            Assert.areEqual('Injection Failed Intentional', e.getMessage());
        }

        Assert.areEqual(2, module.factory.injectionAttempts, 'Should attempt injection twice');
        Assert.areEqual(
            2,
            module.factory.instantiationCount,
            'Should instantiate twice, proving the first instance was evicted from cache'
        );
    }

    @IsTest
    static void should_return_new_instance_when_using_prototype_scope() {
        // Arrange: A module with a prototype-scoped provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(PrototypeModule.class);

        // Act: The provider is resolved twice.
        Object a = ref.resolve('p');
        Object b = ref.resolve('p');

        // Assert: The two objects are different instances.
        Assert.areNotEqual(a, b, 'Prototype-scoped providers should return a new instance each time.');
    }

    @IsTest
    static void should_throw_exception_when_getting_prototype_provider() {
        // Arrange: A module with a prototype-scoped provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(PrototypeModule.class);

        // Act: An attempt is made to get() the prototype-scoped provider.
        try {
            ref.get('p');
            Assert.fail('Expected InvalidScopeException was not thrown.');
        } catch (Di.InvalidScopeException ex) {
            // Assert: The correct exception is thrown with a helpful message.
            Assert.isTrue(
                ex.getMessage().contains('Use resolve() method instead'),
                'Exception message should guide the user to use resolve().'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_provider_is_not_found() {
        // Arrange: A module is registered.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);

        // Act: An attempt is made to get an unknown provider.
        try {
            ref.get('unknown');
            Assert.fail('Expected UnknownProviderException was not thrown.');
        } catch (Di.UnknownProviderException ex) {
            // Assert: The correct exception is thrown.
            Assert.isTrue(
                ex.getMessage().contains('Could not find "unknown" provider'),
                'Exception message should identify the missing provider.'
            );
        }
    }
    // </editor-fold>

    // <editor-fold desc="Scoped Lifetimes">
    @IsTest
    static void should_return_same_instance_when_resolving_within_one_scope() {
        // Arrange: Register a module with a SCOPED provider.
        Di.ModuleRef rootContainer = Di.getModuleRef(ScopedModule.class);
        Di.ScopeRef scope = rootContainer.createScope();

        // Act: Get the provider twice from the SAME scope.
        Object instance1 = scope.get(ScopedService.class);
        Object instance2 = scope.get(ScopedService.class);

        // Assert: Both instances are the same because they came from the same scope.
        Assert.areEqual(instance1, instance2, 'Should return the same instance for a provider within the same scope.');
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void should_return_different_instances_when_using_different_scopes() {
        // Arrange: Register a module with a SCOPED provider.
        Di.ModuleRef rootContainer = Di.getModuleRef(ScopedModule.class);
        Di.ScopeRef scope1 = rootContainer.createScope();
        Di.ScopeRef scope2 = rootContainer.createScope();

        // Act: Get the provider from each of the two different scopes.
        Object instance1 = scope1.get(ScopedService.class);
        Object instance2 = scope2.get(ScopedService.class);

        // Assert: The instances are different because they came from different scopes.
        Assert.areNotEqual(
            instance1,
            instance2,
            'Should return different instances for a provider from different scopes.'
        );
    }

    @IsTest
    static void should_not_cache_scoped_provider_when_using_resolve() {
        // Arrange
        Di.clear();
        Di.ModuleRef consumerCtn = Di.getModuleRef(ScopedModule.class);

        // Act
        // 1. Resolve in a scope
        Di.ScopeRef scope1 = consumerCtn.createScope();
        Object instance1 = scope1.get(ScopedService.class);

        // 2. Resolve in a DIFFERENT scope
        Di.ScopeRef scope2 = consumerCtn.createScope();
        Object instance2 = scope2.get(ScopedService.class);

        // Assert
        Assert.areNotEqual(
            instance1,
            instance2,
            'Different scopes should return different instances for SCOPED provider'
        );

        Object resolvedInScope1 = scope1.resolve(ScopedService.class);
        Object resolvedInScope2 = scope1.resolve(ScopedService.class);

        Assert.areNotEqual(
            instance1,
            resolvedInScope1,
            'resolve() in a scope should create a fresh scoped instance instead of using the scope cache.'
        );
        Assert.areNotEqual(
            resolvedInScope1,
            resolvedInScope2,
            'resolve() in a scope should create a fresh scoped instance on each call.'
        );
    }

    @IsTest
    static void should_throw_when_getting_scoped_provider_from_root_module_ref() {
        // Arrange: A root module ref has no active scope cache for SCOPED providers.
        Di.ModuleRef ref = Di.getModuleRef(ScopedModule.class);

        // Act: Root get() should require callers to create an explicit scope.
        try {
            ref.get(ScopedService.class);
            Assert.fail('Expected InvalidScopeException when getting a scoped provider from the root module.');
        } catch (Di.InvalidScopeException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Use createScope() method instead'),
                'Exception message should guide the user to create a scope.'
            );
        }
    }

    @IsTest
    static void should_throw_when_resolving_scoped_provider_from_root_module_ref() {
        // Arrange: A root module ref has no active scope cache for SCOPED providers.
        Di.ModuleRef ref = Di.getModuleRef(ScopedModule.class);

        // Act: Root resolve() should also require callers to create an explicit scope.
        try {
            ref.resolve(ScopedService.class);
            Assert.fail('Expected InvalidScopeException when resolving a scoped provider from the root module.');
        } catch (Di.InvalidScopeException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Use createScope() method instead'),
                'Exception message should guide the user to create a scope.'
            );
        }
    }

    @IsTest
    static void should_evict_scoped_provider_from_cache_when_injection_fails() {
        // Arrange
        ScopedInjectionFailureModule mod = new ScopedInjectionFailureModule();
        Di.ModuleRef ref = Di.addModule(mod);
        Di.ScopeRef scope = ref.createScope();

        // Act: First attempt fails
        try {
            scope.get('BrokenService');
            Assert.fail('Should have thrown DiException');
        } catch (Di.DiException e) {
            // Assert: Verify the expected outcome.
            Assert.areEqual('Injection Failed Intentional', e.getMessage(), 'Should bubble up the injection exception');
        }

        // Act: Second attempt should have evicted the broken instance and try again
        try {
            scope.get('BrokenService');
            Assert.fail('Should have thrown DiException on retry');
        } catch (Di.DiException e) {
            // Success if we get here.
            // We verify that it TRIED to instantiate/inject again.
            // Instantiation count should be 2 because the first one failed during injection (after instantiation) and was evicted.
            // So the second attempt creates a NEW instance.
            Assert.areEqual(2, mod.factory.instantiationCount, 'Should have re-instantiated the service');
            Assert.areEqual(2, mod.factory.injectionAttempts, 'Should have re-attempted injection');
        }
    }

    @IsTest
    static void should_resolve_singleton_dependency_when_requested_from_scope() {
        // Arrange: Register a module with a SCOPED provider that depends on a SINGLETON provider.
        Di.ModuleRef rootContainer = Di.getModuleRef(ScopedWithSingletonDepModule.class);
        Di.ScopeRef scope1 = rootContainer.createScope();
        Di.ScopeRef scope2 = rootContainer.createScope();

        // Act: Resolve the scoped service from two different scopes.
        ScopedWithSingletonDepService service1 = (ScopedWithSingletonDepService) scope1.get(
            ScopedWithSingletonDepService.class
        );
        ScopedWithSingletonDepService service2 = (ScopedWithSingletonDepService) scope2.get(
            ScopedWithSingletonDepService.class
        );

        // Assert: The scoped services themselves are different instances.
        Assert.areNotEqual(service1, service2, 'The parent scoped services should be different instances.');

        // Assert: The injected SINGLETON dependency is the exact same instance in both.
        Assert.isNotNull(service1.singletonDep, 'Singleton dependency should be injected.');
        Assert.areEqual(
            service1.singletonDep,
            service2.singletonDep,
            'The singleton dependency should be the same instance across different scopes.'
        );
    }

    @IsTest
    static void should_throw_when_singleton_depends_on_scoped_provider() {
        // Arrange: A singleton service attempts to capture a scoped dependency.
        Di.ScopeRef scope = Di.getModuleRef(SingletonWithScopedDepModule.class).createScope();

        // Act: Even when requested from a ScopeRef, the singleton is built by the root module.
        try {
            scope.get(SingletonWithScopedDepService.class);
            Assert.fail('Expected InvalidScopeException when a singleton depends on a scoped provider.');
        } catch (Di.InvalidScopeException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Use createScope() method instead'),
                'Exception message should identify the invalid scoped dependency access.'
            );
        }
    }

    @IsTest
    static void should_resolve_prototype_dependency_when_requested_from_scope() {
        // Arrange: Register a module with a SCOPED provider that depends on a PROTOTYPE provider.
        Di.ModuleRef rootContainer = Di.getModuleRef(ScopedWithPrototypeDepModule.class);
        Di.ScopeRef scope = rootContainer.createScope();

        // Act: Resolve the scoped service.
        ScopedWithPrototypeDepService service = (ScopedWithPrototypeDepService) scope.get(
            ScopedWithPrototypeDepService.class
        );
        Object prototypeDep1 = service.prototypeDep;

        // Act: Resolve the prototype dependency again directly from the same scope.
        Object prototypeDep2 = scope.resolve(PrototypeService.class);

        // Assert: The two prototype instances are different, even though resolved from the same scope.
        Assert.isNotNull(prototypeDep1, 'Prototype dependency should be injected.');
        Assert.areNotEqual(prototypeDep1, prototypeDep2, 'Prototype dependencies should always be new instances.');
    }

    @IsTest
    static void should_clear_cache_when_clearing_specific_scope() {
        // Arrange: Register a module and create a scope.
        Di.ModuleRef rootContainer = Di.getModuleRef(ScopedModule.class);
        Di.ScopeRef scope = rootContainer.createScope();

        // Act: Get a scoped provider to populate the scope's cache.
        Object instance1 = scope.get(ScopedService.class);

        // Act: Clear the cache only for that specific scope.
        scope.clearCache();

        // Act: Get the provider again from the same scope.
        Object instance2 = scope.get(ScopedService.class);

        // Assert: A new instance is created, proving the scope's cache was cleared.
        Assert.isNotNull(instance1, 'First instance should not be null.');
        Assert.areNotEqual(instance1, instance2, 'A new instance should be created after clearing the scope cache.');
    }

    @IsTest
    static void should_clear_singleton_cache_when_module_ref_cache_is_cleared() {
        // Arrange: A singleton provider has been cached on the root module ref.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);
        Object first = ref.get('TestService');

        // Act: Clear only this root module ref cache.
        ref.clearCache();
        Object second = ref.get('TestService');

        // Assert: The singleton is rebuilt after clearing the root cache.
        Assert.areNotEqual(first, second, 'Clearing a ModuleRef cache should evict singleton instances.');
    }

    @IsTest
    static void should_invalidate_live_scope_when_scoped_provider_is_replaced() {
        // Arrange: A live scope has cached an instance from the current scoped provider definition.
        ScopedModule module = new ScopedModule();
        Di.ModuleRef moduleRef = Di.addModule(module);
        Di.ScopeRef scope = moduleRef.createScope();
        Object original = scope.get(ScopedService.class);

        // Act: Replace the scoped provider through the owning application context.
        Di.replaceProvider(
            module.getToken(),
            module.provide(ScopedService.class).useClass(ScopedService.class).scope(Di.Scope.SCOPED)
        );

        // Assert: The old scope is stale and a fresh scope receives a new cached instance.
        try {
            scope.get(ScopedService.class);
            Assert.fail('Expected provider replacement to invalidate the held scope.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        Di.ScopeRef freshScope = Di.getModuleRef(module.getToken()).createScope();
        Object replacement = freshScope.get(ScopedService.class);
        Assert.areNotEqual(original, replacement, 'A fresh scope should rebuild after provider replacement.');
        Assert.areEqual(
            replacement,
            freshScope.get(ScopedService.class),
            'The rebuilt scoped instance should remain cached within the fresh scope.'
        );
    }

    @IsTest
    static void should_update_scope_when_module_is_replaced() {
        // Arrange
        Di.clear();
        Di.ModuleRef moduleRef = Di.getModuleRef(ScopeRefIntegrityModule.class);
        Di.ScopeRef scope = moduleRef.createScope();

        // Act: Resolve from the initial module.
        String val1 = (String) scope.resolve('ScopedService');

        // Assert: The initial module supplies the scoped value.
        Assert.areEqual('A', val1, 'Should return value from initial module');

        // Act: Replace the module and try to resolve again from the same scope.
        Di.replaceModule(ScopeRefIntegrityModule.class, new ScopeRefIntegrityReplacementModule());

        // Assert: The existing scope is stale; a fresh scope observes the replacement.
        try {
            scope.resolve('ScopedService');
            Assert.fail('Expected module replacement to invalidate the held scope.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        String val2 = (String) Di.getModuleRef(ScopeRefIntegrityModule.class).createScope().resolve('ScopedService');
        Assert.areEqual('B', val2, 'Should return value from replacement module');
        Assert.areNotEqual(val1, val2, 'Should not return cached value from old module');
    }
    // </editor-fold>

    // <editor-fold desc="Provider Types">
    @IsTest
    static void should_return_configured_value_when_using_value_provider() {
        // Arrange: A module with a ValueProvider is registered.
        Di.ModuleRef ref = Di.getModuleRef(ValueModule.class);

        // Act: The value is requested via get() and resolve().
        Object val1 = ref.get('val');
        Object val2 = ref.resolve('val');

        // Assert: The exact value is returned in both cases.
        Assert.areEqual('hello', val1, 'get() should return the literal value.');
        Assert.areEqual('hello', val2, 'resolve() should also return the literal value.');
    }

    @IsTest
    static void should_create_value_provider_when_token_is_type() {
        // Arrange: Prepare the test scenario.
        // Act: Build a value provider through the public provider-builder boundary.
        Di.Provider provider = new Di.DynamicModule('ValueProviderBuilder')
            .provide(TestService.class)
            .useValue('hello');

        // Assert
        Assert.areEqual('DiTest.TestService', provider.getToken(), 'Token should be the class name.');
        Assert.areEqual('hello', provider.resolve(null, null), 'Should resolve the value.');
    }

    @IsTest
    static void should_create_standalone_value_provider_when_constructed_directly() {
        // Arrange: Prepare the test scenario.
        // Act: Built-in provider definitions can be created without a module or ProviderBuilder.
        Di.ValueProvider provider = new Di.ValueProvider(TestService.class, 'hello');

        // Assert: Standalone providers retain canonical tokens and remain directly executable.
        Assert.areEqual(TestService.class.getName(), provider.getToken());
        Assert.areEqual('hello', provider.resolve(null, null));
    }

    @IsTest
    static void should_return_factory_instance_when_using_factory_provider() {
        // Arrange: A module with a FactoryProvider is registered.
        Di.ModuleRef ref = Di.getModuleRef(FactoryModule.class);

        // Act: The provider is requested.
        Object svc = ref.get('svc');

        // Assert: The returned object is of the type created by the factory.
        Assert.isTrue(svc instanceof TestServiceImpl, 'Factory should produce the correct type.');
    }

    @IsTest
    static void should_create_factory_provider_when_factory_is_type() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act
        Di.Provider provider = builder.useFactory(StringArgsFactory.class);

        // Assert
        Assert.isNotNull(provider, 'Should return a valid provider instance.');
        // We can verify it resolves correctly
        // We need a dummy container since resolve calls factory.newInstance(container, args)
        // Re-using ArgsModule which registers StringArgsFactory but via instance
        // Let's just manually invoke resolve with null container and args - StringArgsFactory doesn't use container
        // Actually StringArgsFactory expects args, let's pass them
        Object result = provider.resolve(null, 'Type');
        Assert.areEqual('arg:Type', result, 'Factory created from type should work correctly.');
    }

    @IsTest
    static void should_create_factory_provider_when_factory_is_string() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act
        Di.Provider provider = builder.useFactory(StringArgsFactory.class.getName());

        // Assert
        Assert.isNotNull(provider, 'Should return a valid provider instance.');
        Object result = provider.resolve(null, 'String');
        Assert.areEqual('arg:String', result, 'Factory created from string should work correctly.');
    }

    @IsTest
    static void should_create_factory_provider_when_using_standalone_overloads() {
        // Arrange: Standalone providers accept Factory, String, and Type definitions with a canonical Type token.
        Di.FactoryProvider instanceFactory = new Di.FactoryProvider(TestService.class, new StringArgsFactory());
        Di.FactoryProvider stringFactory = new Di.FactoryProvider(TestService.class, StringArgsFactory.class.getName());
        Di.FactoryProvider typeFactory = new Di.FactoryProvider(TestService.class, StringArgsFactory.class);

        // Act: Every standalone overload produces an executable provider with the canonical Type token.
        // Assert: Verify the expected outcome.
        Assert.areEqual(TestService.class.getName(), instanceFactory.getToken());
        Assert.areEqual('arg:instance', instanceFactory.resolve(null, 'instance'));
        Assert.areEqual('arg:string', stringFactory.resolve(null, 'string'));
        Assert.areEqual('arg:type', typeFactory.resolve(null, 'type'));
    }

    @IsTest
    static void should_throw_exception_when_factory_string_is_null() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act: Execute the behavior under test.
        try {
            builder.useFactory((String) null);
            Assert.fail('Expected InvalidProviderException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Cannot instantiate class "null"'),
                'Exception message should indicate null class name.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_factory_string_is_invalid() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act: Execute the behavior under test.
        try {
            builder.useFactory('Invalid.Class.Name');
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Cannot instantiate class "Invalid.Class.Name"'),
                'Exception message should indicate missing class.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_factory_type_is_null() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act: Execute the behavior under test.
        try {
            builder.useFactory((Type) null);
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Cannot instantiate class'),
                'Exception message should indicate invalid interface.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_factory_type_is_invalid() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act: Execute the behavior under test.
        try {
            // Using a class that exists but doesn't implement Di.Factory (e.g. TestServiceImpl or String)
            builder.useFactory(NotFactory.class);
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('does not implement the Di.Factory interface'),
                'Exception message should indicate invalid interface.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_factory_type_is_not_instantiable() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act: Execute the behavior under test.
        try {
            // Di.Module is abstract, so it cannot be instantiated
            builder.useFactory(Di.Module.class);
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Cannot instantiate class'),
                'Exception message should indicate instantiation failure.'
            );
        }
    }

    @IsTest
    static void should_pass_arguments_when_resolving_factory_provider() {
        // Arrange: A module with a FactoryProvider that accepts arguments is registered.
        Di.ModuleRef ref = Di.getModuleRef(ArgsModule.class);

        // Act: The provider is resolved with arguments.
        Object out = ref.resolve('arg', new List<String>{ 'X' });

        // Assert: The factory correctly uses the arguments to produce the value.
        Assert.areEqual('arg:X', out, 'Arguments should be passed to and used by the factory.');
    }

    @IsTest
    static void should_throw_when_getting_provider_by_type_with_arguments() {
        // Arrange: A module with a factory provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(ArgsTypeModule.class);

        // Act: get() is the cached path and does not accept runtime arguments.
        try {
            ref.get(TestServiceImpl.class, new List<Object>{ 'Args' });
            Assert.fail('Expected InvalidProviderException when calling get(Type, args).');
        } catch (Di.InvalidProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Use resolve()'),
                'Exception message should guide callers to resolve() for runtime arguments.'
            );
        }
    }

    @IsTest
    static void should_resolve_provider_when_type_and_arguments_are_supplied() {
        // Arrange: A module with a factory provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(ArgsTypeModule.class);

        // Act: The provider is resolved by Type with arguments.
        Object result1 = ref.resolve(TestServiceImpl.class, new List<Object>{ 'R1' });
        Object result2 = ref.resolve(TestServiceImpl.class, new List<Object>{ 'R2' });

        // Assert: The factory produces new instances with the correct values.
        Assert.areEqual('arg:R1', result1, 'First resolve should produce the correct value.');
        Assert.areEqual('arg:R2', result2, 'Second resolve should produce the correct value.');
    }

    @IsTest
    static void should_resolve_provider_when_type_is_supplied_without_arguments() {
        // Arrange: A module with a standard provider is registered using a Type token.
        Di.ModuleRef ref = Di.getModuleRef(TypeModule.class);

        // Act: The provider is resolved by Type.
        Object instance1 = ref.resolve(TestService.class);
        Object instance2 = ref.resolve(TestService.class);

        // Assert: Two different instances of the correct implementation are returned.
        Assert.isTrue(instance1 instanceof TestServiceImpl, 'Resolved instance should be of the correct type.');
        Assert.areNotEqual(instance1, instance2, 'resolve(Type) should return a new instance each time.');
    }

    @IsTest
    static void should_treat_string_tokens_as_exact_case_sensitive_keys_when_resolving() {
        // Arrange: A module with a Type-token provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(TypeModule.class);
        String lowerCaseTypeToken = TestService.class.getName().toLowerCase();

        // Act: Resolve through the canonical Type overload.
        Object canonicalInstance = ref.get(TestService.class);

        // Assert: Type overloads use the canonical Apex type name.
        Assert.isTrue(
            canonicalInstance instanceof TestServiceImpl,
            'Type overloads should resolve through the canonical Type name.'
        );

        // Act: String tokens are exact keys, even when they look like class names.
        try {
            ref.get(lowerCaseTypeToken);
            Assert.fail('Expected UnknownProviderException for a differently cased string token.');
        } catch (Di.UnknownProviderException ex) {
            // Assert: Differently cased string tokens remain unresolved.
            Assert.isTrue(
                ex.getMessage().contains('Could not find "' + lowerCaseTypeToken + '" provider'),
                'String tokens should remain exact and case-sensitive.'
            );
        }
    }

    @IsTest
    static void should_replace_existing_class_provider_when_replacement_uses_type() {
        // Arrange: A module with a standard provider is registered using a Type token.
        Di.ModuleRef ref = Di.getModuleRef(TypeModule.class);

        // Act: The provider is resolved by Type.
        Object instance1 = ref.resolve(TestService.class);

        // Assert: Two different instances of the correct implementation are returned.
        Assert.isTrue(instance1 instanceof TestServiceImpl, 'Resolved instance should be of the correct type.');

        // Act: The provider is replaced through the owning application context.
        Di.Provider newProvider = ref.getModule().provide(TestService.class).useClass(MockService.class);
        Di.replaceProvider(TypeModule.class, newProvider);
        Object instance2 = Di.getModuleRef(TypeModule.class).resolve(TestService.class);

        // Assert: Two different instances of the correct implementation are returned.
        Assert.isTrue(instance2 instanceof MockService, 'Resolved instance should be of the correct type.');
    }

    @IsTest
    static void should_replace_existing_provider_when_token_is_registered() {
        // Arrange: A module is registered with an initial provider.
        Di.ModuleRef ref = Di.getModuleRef(ValueModule.class);
        Assert.areEqual('hello', ref.get('val'), 'Pre-condition: Initial value should be "hello".');

        // Act: The provider is replaced through the owning application context.
        Di.Provider newProvider = ref.getModule().provide('val').useValue('world');
        Di.replaceProvider(ValueModule.class, newProvider);

        // Assert: Getting the provider now returns the new value.
        Assert.areEqual(
            'world',
            Di.getModuleRef(ValueModule.class).get('val'),
            'The provider value should be updated after replacement.'
        );
    }

    @IsTest
    static void should_throw_when_replacing_missing_provider() {
        // Arrange: A module is registered without the replacement token.
        Di.ModuleRef ref = Di.getModuleRef(ValueModule.class);
        Di.Provider missingProvider = ref.getModule().provide('missing').useValue('world');

        // Act: Replacing an absent provider should fail loudly.
        try {
            Di.replaceProvider(ValueModule.class, missingProvider);
            Assert.fail('Expected UnknownProviderException when replacing a missing provider.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Could not find "missing" provider'),
                'Exception message should identify the missing provider token.'
            );
        }

        // Assert: Existing providers remain unchanged after the failed replacement.
        Assert.areEqual('hello', ref.get('val'), 'Existing providers should not be changed by a failed replace.');
    }

    @IsTest
    static void should_not_register_missing_module_when_replacing_provider_by_module_type() {
        // Arrange: A different module has already opened the context.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef heldRef = context.addModule(new SingleModule());
        Assert.isTrue(heldRef.get('TestService') instanceof TestServiceImpl, 'Pre-condition: context is open.');

        // Act: Replacing a provider requires the owner module to already be registered.
        try {
            context.replaceProvider(ValueModule.class, new Di.ValueProvider('val', 'replacement'));
            Assert.fail('Expected UnknownModuleException for replacing a provider on an unregistered module.');
        } catch (Di.UnknownModuleException ex) {
            Assert.isTrue(ex.getMessage().contains(ValueModule.class.getName()));
        }

        // Assert: The failed replacement did not add ValueModule or invalidate the held handle.
        Assert.isTrue(heldRef.get('TestService') instanceof TestServiceImpl);
    }

    @IsTest
    static void should_not_register_missing_module_when_replacing_module_by_type() {
        // Arrange: A different module has already opened the context.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef heldRef = context.addModule(new SingleModule());
        Assert.isTrue(heldRef.get('TestService') instanceof TestServiceImpl, 'Pre-condition: context is open.');

        // Act: Replacing a module requires the target module to already be registered.
        try {
            context.replaceModule(ValueModule.class, new Di.DynamicModule(ValueModule.class.getName()));
            Assert.fail('Expected UnknownModuleException for replacing an unregistered module.');
        } catch (Di.UnknownModuleException ex) {
            Assert.isTrue(ex.getMessage().contains(ValueModule.class.getName()));
        }

        // Assert: The failed replacement did not add ValueModule or invalidate the held handle.
        Assert.isTrue(heldRef.get('TestService') instanceof TestServiceImpl);
    }

    @IsTest
    static void should_not_register_missing_module_when_replacement_token_cannot_resolve_to_module() {
        // Arrange: A different module has already opened the context.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef heldRef = context.addModule(new SingleModule());
        Assert.isTrue(heldRef.get('TestService') instanceof TestServiceImpl, 'Pre-condition: context is open.');

        // Act/Assert: Missing, unconstructable, and non-module type tokens all fail without registration.
        assertUnknownModuleReplacement(context, 'DiTest.DoesNotExistModule');
        assertUnknownModuleReplacement(context, UnconstructableModule.class.getName());
        assertUnknownModuleReplacement(context, NotAModule.class.getName());

        // Assert: Failed lookups did not invalidate the held handle.
        Assert.isTrue(heldRef.get('TestService') instanceof TestServiceImpl);
    }

    @IsTest
    static void should_instantiate_class_when_valid_string_name_is_supplied() {
        // Arrange: A module provides a class using its string name.
        Di.ModuleRef ref = Di.getModuleRef(StringTypeModule.class);

        // Act: The service is requested.
        Object svc = ref.get('svc');

        // Assert: The correct class is instantiated.
        Assert.isTrue(svc instanceof TestServiceImpl, 'The framework should instantiate a class from its string name.');
    }

    @IsTest
    static void should_create_class_provider_when_definition_is_type() {
        // Arrange: Build class providers through String-token/Type-class and Type-token/String-class overloads.
        Di.DynamicModule module = new Di.DynamicModule('ClassProviderBuilder');
        Di.Provider provider1 = module.provide('TestService').useClass(TestServiceImpl.class);
        Di.Provider provider2 = module.provide(TestService.class).useClass('DiTest.TestServiceImpl');

        // Act: Both public builder paths normalize and instantiate the requested class.
        // Assert: Verify the expected outcome.
        Assert.isTrue(provider1.resolve(null, null) instanceof TestServiceImpl);
        Assert.areEqual(TestService.class.getName(), provider2.getToken());
        Assert.isTrue(provider2.resolve(null, null) instanceof TestServiceImpl);
    }

    @IsTest
    static void should_create_class_provider_when_using_standalone_overloads() {
        // Arrange: Build both standalone class-input overloads from one canonical Type token.
        Di.ClassProvider stringType = new Di.ClassProvider(TestService.class, TestServiceImpl.class.getName());
        Di.ClassProvider apexType = new Di.ClassProvider(TestService.class, TestServiceImpl.class);

        // Act: Both standalone providers expose their definitions and instantiate the requested class.
        // Assert: Verify the expected outcome.
        Assert.areEqual(TestServiceImpl.class.getName(), stringType.getType());
        Assert.areEqual(TestServiceImpl.class.getName(), apexType.getType());
        Assert.isTrue(stringType.resolve(null, null) instanceof TestServiceImpl);
        Assert.isTrue(apexType.resolve(null, null) instanceof TestServiceImpl);
    }

    @IsTest
    static void should_resolve_provider_when_using_existing_alias() {
        // Arrange: A module is registered with a provider aliased by another token.
        Di.ModuleRef ref = Di.getModuleRef(ExistingProviderModule.class);

        // Act: The original provider and the alias are retrieved.
        Object original = ref.get('MyLongAndComplexServiceName');
        Object alias = ref.get('MyAlias');

        // Assert: Both tokens resolve to the same singleton instance.
        Assert.isTrue(original instanceof TestServiceImpl, 'Original should be correct type.');
        Assert.areEqual(original, alias, 'Alias should resolve to the same instance as the original provider.');
    }

    @IsTest
    static void should_create_existing_provider_when_using_standalone_overloads() {
        // Arrange: Configure standalone aliases through String/Type constructor combinations.
        Di.DynamicModule module = new Di.DynamicModule('ExistingProviderOverloads');
        Di.ExistingProvider stringAlias = new Di.ExistingProvider('StringAlias', MockService.class);
        Di.ExistingProvider typeStringAlias = new Di.ExistingProvider(TestService.class, 'OtherService');
        Di.ExistingProvider typeAlias = new Di.ExistingProvider(TestServiceImpl.class, MockService.class);
        module
            .addProvider(module.provide(MockService.class).useClass(MockService.class))
            .addProvider(module.provide('OtherService').useClass(MockService.class))
            .addProvider(stringAlias)
            .addProvider(typeStringAlias)
            .addProvider(typeAlias);
        Di.ModuleRef ref = Di.addModule(module);

        // Act: Definitions remain inspectable and redirect through normal container resolution.
        // Assert: Verify the expected outcome.
        Assert.areEqual(MockService.class.getName(), stringAlias.getExisting());
        Assert.areEqual('OtherService', typeStringAlias.getExisting());
        Assert.areEqual(MockService.class.getName(), typeAlias.getExisting());
        Assert.areEqual(ref.get(MockService.class), ref.get('StringAlias'));
        Assert.areEqual(ref.get('OtherService'), ref.get(TestService.class));
        Assert.areEqual(ref.get(MockService.class), ref.get(TestServiceImpl.class));
    }
    // </editor-fold>

    // <editor-fold desc="Circular Dependencies">
    @IsTest
    static void should_throw_exception_when_existing_alias_is_circular() {
        // Arrange: A module is registered with a circular alias dependency (A -> B -> A).
        Di.ModuleRef ref = Di.getModuleRef(CircularExistingProviderModule.class);

        // Act: An attempt to get either provider should throw a CircularDependencyException.
        try {
            ref.get('AliasA');
            Assert.fail('Expected CircularDependencyException was not thrown.');
        } catch (Di.CircularDependencyException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Circular dependency detected'),
                'Exception message should indicate a cycle.'
            );
        }
    }

    @IsTest
    static void should_detect_circular_dependency_when_aliases_form_cycle() {
        // Arrange: Get the container for the alias-based cycle.
        Di.ModuleRef container = Di.getModuleRef(AliasCircularAModule.class);

        // Act: The framework should correctly detect this cycle.
        try {
            container.get('AliasA');
            Assert.fail('Expected a Di.CircularDependencyException but no exception was thrown.');
        } catch (Di.CircularDependencyException e) {
            // Assert: This is the correct behavior. The framework is robust for this case.
            Assert.isTrue(
                e.getMessage().contains('Resolution path: AliasA -> ProviderB -> AliasA'),
                'The exception message should show the full resolution path.'
            );
        } catch (Exception e) {
            Assert.fail(
                'Expected a Di.CircularDependencyException, but a different exception was thrown: ' + e.getTypeName()
            );
        }
    }

    @IsTest
    static void should_detect_circular_dependency_when_factories_form_cycle() {
        // Arrange: Get the container for the factory-based cycle.
        Di.ModuleRef container = Di.getModuleRef(FactoryCircularAModule.class);

        // Act: Attempt to resolve the circular dependency.
        try {
            container.get(ServiceA.class);
            Assert.fail('Expected a Di.CircularDependencyException but no exception was thrown.');
        } catch (Di.CircularDependencyException e) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                e.getMessage().contains('Circular dependency detected for provider "DiTest.ServiceA"'),
                'The exception message should correctly identify the circular dependency.'
            );
            Assert.isTrue(
                e.getMessage().contains('Resolution path: DiTest.ServiceA -> DiTest.ServiceB -> DiTest.ServiceA'),
                'The exception message should show the full resolution path.'
            );
        } catch (Exception e) {
            Assert.fail(
                'Expected a Di.CircularDependencyException, but a different exception was thrown: ' + e.getTypeName()
            );
        }
    }

    @IsTest
    static void should_resolve_prototype_provider_when_using_existing_alias() {
        // Arrange: A module is registered with a PROTOTYPE provider aliased by another token.
        Di.ModuleRef ref = Di.getModuleRef(ExistingPrototypeProviderModule.class);

        // Act: The alias is resolved twice. This covers the resolveInternal path for ExistingProvider.
        Object instance1 = ref.resolve('AliasService');
        Object instance2 = ref.resolve('AliasService');

        // Assert: Both instances are of the correct underlying type.
        Assert.isTrue(instance1 instanceof TestServiceImpl, 'First instance should be the correct type.');
        Assert.isTrue(instance2 instanceof TestServiceImpl, 'Second instance should be the correct type.');

        // Assert: The two instances are different, proving that the PROTOTYPE scope was respected.
        Assert.areNotEqual(instance1, instance2, 'Prototype alias should resolve to a new instance each time.');
    }

    @IsTest
    static void should_throw_exception_when_getting_prototype_alias_to_singleton() {
        // Arrange: A module with a SINGLETON provider ('TestService') is aliased by a
        // PROTOTYPE provider ('AliasService').
        Di.ModuleRef ref = Di.getModuleRef(ExistingPrototypeProviderModule.class);

        // Act: An attempt to get() the prototype-scoped alias should fail,
        // because get() is not allowed on prototype scopes.
        try {
            ref.get('AliasService');
            Assert.fail('Expected InvalidScopeException was not thrown. This confirms the bug.');
        } catch (Di.InvalidScopeException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Use resolve() method instead'),
                'Exception message should guide the user to use resolve().'
            );
        } catch (Exception e) {
            Assert.fail('An unexpected exception was thrown: ' + e.getMessage());
        }
    }

    @IsTest
    static void should_resolve_circular_dependency_when_forward_ref_is_absent() {
        // Arrange: Get the container for the module containing the circular dependency.
        Di.ModuleRef container = Di.getModuleRef(ForwardRefModule.class);
        Exception caughtException;

        // Act: Attempt to resolve the circular dependency.
        // With the two-pass instantiation logic, this should now succeed.
        ForwardRefServiceA instanceA = null;
        try {
            instanceA = (ForwardRefServiceA) container.get(ForwardRefServiceA.class);
        } catch (Exception e) {
            caughtException = e;
        }

        // Assert: No exception was thrown during resolution.
        Assert.isNull(caughtException, 'The framework should have resolved the circular dependency automatically.');

        // Assert: The instances were created and their dependencies were injected correctly.
        Assert.isNotNull(instanceA, 'Instance of ServiceA should not be null.');
        Assert.isNotNull(instanceA.serviceB, 'Injected ServiceB should not be null.');
        Assert.isNotNull(instanceA.serviceB.serviceA, 'Injected ServiceA on ServiceB should not be null.');

        // Assert: The framework correctly injected the same instance back into the cycle.
        Assert.areEqual(
            instanceA,
            instanceA.serviceB.serviceA,
            'The circular dependency should resolve to the same root instance.'
        );
    }
    // </editor-fold>

    // <editor-fold desc="Metadata Providers">
    @IsTest
    static void should_resolve_provider_and_global_module_when_metadata_source_is_injected() {
        // Arrange: One source supplies normalized provider and global-module definitions.
        Di.MetadataSource metadataSource = new InjectedMetadataSource(
            new List<Di.MetadataModuleDefinition>{
                new Di.MetadataModuleDefinition('CmtGlobal', CmtGlobalModule.class.getName(), true, true)
            },
            new Map<String, Di.ProviderDefinition>{
                'StringValueProvider' => new Di.ProviderDefinition(
                    'StringValueProvider',
                    'Value',
                    'injected metadata',
                    null,
                    null,
                    true
                )
            }
        );
        Di.ApplicationContext context = Di.createContext(metadataSource);
        Di.ModuleRef ref = context.getModuleRef(MetadataModule.class);

        // Act: Runtime metadata behavior is sourced entirely through the injected adapter.
        // Assert: Verify the expected outcome.
        Assert.areEqual('injected metadata', ref.get('StringValue'));
        Assert.areEqual('helloFromCmt', ref.get('cmtGlobalVal'));
    }

    @IsTest
    static void should_delegate_to_injected_source_when_metadata_overrides_are_cleared() {
        // Arrange: Test overrides temporarily hide definitions supplied by the injected source.
        Di.ApplicationContext context = Di.createContext(
            new InjectedMetadataSource(
                new List<Di.MetadataModuleDefinition>{
                    new Di.MetadataModuleDefinition('CmtGlobal', CmtGlobalModule.class.getName(), true, true)
                },
                new Map<String, Di.ProviderDefinition>{
                    'StringValueProvider' => new Di.ProviderDefinition(
                        'StringValueProvider',
                        'Value',
                        'delegated metadata',
                        null,
                        null,
                        true
                    )
                }
            )
        );
        context.mockModules(new List<DI_Module__mdt>());
        context.mockProviders(new Map<String, DI_Provider__mdt>());

        // Act: Null test overrides restore delegation to the configured metadata source.
        context.mockModules(null);
        context.mockProviders(null);
        Di.ModuleRef ref = context.getModuleRef(MetadataModule.class);

        // Assert
        Assert.areEqual('delegated metadata', ref.get('StringValue'));
        Assert.areEqual('helloFromCmt', ref.get('cmtGlobalVal'));
    }

    @IsTest
    static void should_snapshot_provider_definitions_when_metadata_source_is_injected() {
        // Arrange: The source exposes a caller-owned mutable map.
        Map<String, Di.ProviderDefinition> definitions = new Map<String, Di.ProviderDefinition>{
            'StringValueProvider' => new Di.ProviderDefinition(
                'StringValueProvider',
                'Value',
                'snapshot',
                null,
                null,
                true
            )
        };
        Di.ApplicationContext context = Di.createContext(
            new InjectedMetadataSource(new List<Di.MetadataModuleDefinition>(), definitions)
        );
        Di.ModuleRef ref = context.getModuleRef(MetadataModule.class);
        Assert.areEqual('snapshot', ref.resolve('StringValue'));

        // Act: Mutate the caller-owned map after the context has loaded its definition snapshot.
        definitions.put(
            'StringValueProvider',
            new Di.ProviderDefinition('StringValueProvider', 'Value', 'mutated', null, null, true)
        );

        // Assert: Context behavior remains deterministic until its metadata state is explicitly reset.
        Assert.areEqual('snapshot', ref.resolve('StringValue'));
    }

    @IsTest
    static void should_resolve_local_module_by_metadata_alias_without_global_visibility() {
        // Arrange: An active local metadata alias selects a module class.
        Di.ApplicationContext context = newTestContext();
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'SelectedLocal',
                    ModuleClass__c = MetadataSelectedModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = false
                )
            }
        );
        Di.ModuleRef consumer = context.getModuleRef(EmptyModule.class);

        // Act: The module is absent from implicit global fallback, then selected explicitly by alias.
        try {
            consumer.get('metadataSelectedValue');
            Assert.fail('Expected a local metadata module to remain unavailable through global fallback.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('metadataSelectedValue'));
        }
        Di.ModuleRef selected = context.getMetadataModuleRef('SelectedLocal');

        // Assert
        Assert.areEqual('selected', selected.get('metadataSelectedValue'));
        try {
            consumer.get('metadataSelectedValue');
            Assert.fail('Expected external metadata installation to invalidate an open-context handle.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        Assert.areEqual(
            new List<String>{ 'SelectedLocal' },
            findModuleDescription(context.describe(), selected.getModule().getToken()).metadataAliases
        );
    }

    @IsTest
    static void should_materialize_metadata_import_without_invalidating_active_handle() {
        // Arrange: A consumer is already open before its lazy metadata import is needed.
        Di.ApplicationContext context = newTestContext();
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'SelectedImport',
                    ModuleClass__c = MetadataSelectedModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = false
                )
            }
        );
        Di.ModuleRef consumer = context.getModuleRef(MetadataImportConsumerModule.class);
        Assert.areEqual('warm', consumer.get('metadataImportWarmup'));

        // Act: Provider discovery installs the metadata-selected import internally after the context opened.
        Object selected = consumer.get('metadataSelectedValue');

        // Assert: Internal lazy discovery does not invalidate the in-flight or retained consumer handle.
        Assert.areEqual('selected', selected);
        Assert.areEqual('warm', consumer.get('metadataImportWarmup'));
        Di.ModuleDescription consumerDescription = findModuleDescription(
            context.describe(),
            consumer.getModule().getToken()
        );
        Assert.areEqual('SelectedImport', consumerDescription.imports[0].metadataAlias);
    }

    @IsTest
    static void should_load_only_global_metadata_modules_during_global_discovery() {
        // Arrange: Metadata contains one global module and one local module with an observable constructor.
        metadataModuleInstantiationCount = 0;
        Di.ApplicationContext context = newTestContext();
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'GlobalSelection',
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                ),
                new DI_Module__mdt(
                    DeveloperName = 'LocalSelection',
                    ModuleClass__c = MetadataConstructionCountingModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = false
                )
            }
        );

        // Act: Global fallback triggers metadata bootstrap.
        Object globalValue = context.getModuleRef(EmptyModule.class).get('cmtGlobalVal');

        // Assert: The local alias is indexed without constructing its module until explicitly selected.
        Assert.areEqual('helloFromCmt', globalValue);
        Assert.areEqual(
            new CmtGlobalModule().getToken(),
            context.getMetadataModuleRef('GlobalSelection').getModule().getToken()
        );
        Assert.areEqual(0, metadataModuleInstantiationCount);
        context.getMetadataModuleRef('LocalSelection');
        Assert.areEqual(1, metadataModuleInstantiationCount);
    }

    @IsTest
    static void should_converge_metadata_aliases_on_one_canonical_module_ref() {
        // Arrange: Two local aliases select the same module class.
        Di.ApplicationContext context = newTestContext();
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'SelectedA',
                    ModuleClass__c = MetadataSelectedModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = false
                ),
                new DI_Module__mdt(
                    DeveloperName = 'SelectedB',
                    ModuleClass__c = MetadataSelectedModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = false
                )
            }
        );

        // Act
        Di.ModuleRef first = context.getMetadataModuleRef('SelectedA');
        Di.ModuleRef second = context.getMetadataModuleRef('SelectedB');

        // Assert: Alias identity remains diagnostic metadata over one canonical registration.
        Assert.areEqual(first, second);
        Assert.areEqual(
            new List<String>{ 'SelectedA', 'SelectedB' },
            findModuleDescription(context.describe(), first.getModule().getToken()).metadataAliases
        );
    }

    @IsTest
    static void should_reject_metadata_and_code_visibility_conflict_for_same_token() {
        // Arrange: Metadata owns a canonical token globally.
        Di.ApplicationContext context = newTestContext();
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'GlobalConflict',
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );

        // Act: Direct code registration attempts to claim the same token locally.
        try {
            context.addModule(new CmtGlobalModule());
            Assert.fail('Expected metadata and code visibility conflict to be rejected.');
        } catch (Di.InvalidModuleException ex) {
            // Assert
            Assert.isTrue(ex.getMessage().contains('already registered as global'));
        }
        Assert.areEqual('helloFromCmt', context.getModuleRef(EmptyModule.class).get('cmtGlobalVal'));
    }

    @IsTest
    static void should_report_missing_and_inactive_metadata_module_aliases() {
        // Arrange: One metadata alias exists but is inactive.
        Di.ApplicationContext context = newTestContext();
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'InactiveModule',
                    ModuleClass__c = MetadataSelectedModule.class.getName(),
                    IsActive__c = false,
                    IsGlobal__c = false
                )
            }
        );
        Integer rejectedAliases = 0;

        // Act and Assert: Missing and inactive aliases fail with distinct diagnostics.
        try {
            context.getMetadataModuleRef('MissingModule');
            Assert.fail('Expected a missing metadata alias to fail.');
        } catch (Di.UnknownModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('MissingModule'));
            rejectedAliases++;
        }
        try {
            context.getMetadataModuleRef('InactiveModule');
            Assert.fail('Expected an inactive metadata alias to fail.');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('inactive'));
            rejectedAliases++;
        }
        Assert.areEqual(2, rejectedAliases);
    }

    @IsTest
    static void should_release_failed_metadata_module_registration_for_retry() {
        // Arrange: A local metadata alias selects a module whose definition cannot compile.
        Di.ApplicationContext context = newTestContext();
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'BrokenSelection',
                    ModuleClass__c = LocalErrorModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = false
                )
            }
        );

        // Act: Registration fails before the alias can be committed.
        try {
            context.getMetadataModuleRef('BrokenSelection');
            Assert.fail('Expected invalid metadata-selected module registration to fail.');
        } catch (Di.UnknownExportException ex) {
            Assert.isTrue(ex.getMessage().contains('missing'));
        }
        Di.DynamicModule retry = new Di.DynamicModule(new LocalErrorModule().getToken());
        retry.addProvider(retry.provide('retry').useValue('recovered'));

        // Assert: The failed candidate released context ownership, registry state, and alias state.
        Assert.areEqual('recovered', context.addModule(retry).get('retry'));
    }

    @IsTest
    static void should_restore_existing_global_aliases_when_metadata_bootstrap_fails() {
        // Arrange: A programmatic global exists before metadata bootstrap is reset with two records.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef globalRef = context.addGlobalModule(new CmtGlobalModule());
        context.addModule(new EmptyModule());
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'AExistingAlias',
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                ),
                new DI_Module__mdt(
                    DeveloperName = 'ZMissingAlias',
                    ModuleClass__c = 'DiTest.MissingMetadataModule',
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );

        // Act: The first row attaches an alias to the existing global, then the second row fails.
        try {
            context.getModuleRef(EmptyModule.class).get('missingAfterBootstrap');
            Assert.fail('Expected global metadata bootstrap to fail atomically.');
        } catch (Di.UnknownModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('MissingMetadataModule'));
        }

        // Assert: Registry rollback also restores metadata aliases on retained runtimes.
        Assert.areEqual(
            new List<String>(),
            findModuleDescription(context.describe(), globalRef.getModule().getToken()).metadataAliases
        );
    }

    @IsTest
    static void should_use_static_metadata_module_facades() {
        // Arrange: The default context has one active local metadata alias.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    DeveloperName = 'StaticSelection',
                    ModuleClass__c = MetadataSelectedModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = false
                )
            }
        );

        // Act
        Di.ModuleRef selected = Di.getMetadataModuleRef('StaticSelection');
        Di.ModuleImport moduleImport = Di.importMetadataModule('StaticSelection');

        // Assert
        Assert.areEqual('selected', selected.get('metadataSelectedValue'));
        Assert.areEqual(selected.getModule(), moduleImport.resolve());
    }

    @IsTest
    static void should_invalidate_existing_refs_when_provider_metadata_is_mocked_after_resolution() {
        // Arrange: A context has resolved metadata-backed value from its initial override.
        Di.ApplicationContext context = newTestContext();
        context.mockProviders(
            new Map<String, DI_Provider__mdt>{
                'StringValueProvider' => new DI_Provider__mdt(
                    DeveloperName = 'StringValueProvider',
                    Type__c = 'Value',
                    Value__c = 'initial metadata',
                    IsActive__c = true
                )
            }
        );
        Di.ModuleRef ref = context.getModuleRef(MetadataModule.class);
        Assert.areEqual('initial metadata', ref.get('StringValue'), 'Pre-condition: metadata value is cached.');

        // Act: Replacing metadata overrides after resolution is an external cold mutation.
        context.mockProviders(
            new Map<String, DI_Provider__mdt>{
                'StringValueProvider' => new DI_Provider__mdt(
                    DeveloperName = 'StringValueProvider',
                    Type__c = 'Value',
                    Value__c = 'updated metadata',
                    IsActive__c = true
                )
            }
        );

        // Assert: The old handle is stale and a fresh handle reads the updated metadata.
        try {
            ref.get('StringValue');
            Assert.fail('Expected metadata override mutation to invalidate the held ref.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        Assert.areEqual('updated metadata', context.getModuleRef(MetadataModule.class).get('StringValue'));
    }

    @IsTest
    static void should_treat_collections_as_empty_when_metadata_source_returns_null() {
        // Arrange: A custom source deliberately returns null collections.
        Di.ApplicationContext context = Di.createContext(new InjectedMetadataSource(null, null));

        // Act: Null provider definitions behave as an empty provider-definition map.
        try {
            context.getModuleRef(MetadataModule.class).get('StringValue');
            Assert.fail('Expected InvalidProviderException for a missing metadata provider definition.');
        } catch (Di.InvalidProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(ex.getMessage().contains('was not found'));
        }

        // Act: Null global definitions behave as an empty global-module collection.
        try {
            context.getModuleRef(EmptyModule.class).get('missingFromNullMetadataSource');
            Assert.fail('Expected UnknownProviderException when the metadata source contains no global modules.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('missingFromNullMetadataSource'));
        }
    }

    @IsTest
    static void should_reject_context_when_metadata_source_is_null() {
        // Arrange: Prepare the test scenario.
        // Act: Execute the behavior under test.
        try {
            Di.createContext((Di.MetadataSource) null);
            Assert.fail('Expected InvalidModuleException for a null metadata source.');
        } catch (Di.InvalidModuleException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(ex.getMessage().contains('null metadata source'));
        }
    }

    @IsTest
    static void should_resolve_class_provider_when_metadata_is_mocked() {
        // Arrange: Define a module that uses the new .useMetadata() method.
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);

        // Arrange: Create a mock DI_Provider__mdt record that defines a Class provider.
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'ConfigurableService',
            Type__c = 'Class',
            Value__c = 'DiTest.MockMetadataServiceImpl',
            IsActive__c = true,
            Scope__c = 'SINGLETON'
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'ConfigurableService' => mockMdt });

        // Act: Resolve the provider. The framework should use the mocked metadata.
        Object service = ref.get(IMetadataService.class);

        // Assert: The instance is from the class specified in the mocked metadata.
        Assert.isTrue(
            service instanceof MockMetadataServiceImpl,
            'The provider should be resolved from the mocked metadata definition.'
        );
    }

    @IsTest
    static void should_resolve_value_provider_when_metadata_defines_value() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'StringValueProvider',
            Type__c = 'Value',
            Value__c = 'hello from metadata',
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'StringValueProvider' => mockMdt });

        // Act
        Object result = ref.get('StringValue');

        // Assert
        Assert.areEqual(
            'hello from metadata',
            result,
            'Should resolve the literal value from the metadata definition.'
        );
    }

    @IsTest
    static void should_resolve_factory_provider_when_metadata_and_arguments_are_supplied() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'FactoryProviderWithArgs',
            Type__c = 'Factory',
            Value__c = 'DiTest.StringArgsFactory',
            Args__c = 'meta-arg',
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'FactoryProviderWithArgs' => mockMdt });

        // Act
        Object result = ref.get('FactoryValue');

        // Assert
        Assert.areEqual(
            'arg:meta-arg',
            result,
            'Factory should be created from metadata and receive args from metadata.'
        );
    }

    @IsTest
    static void should_resolve_existing_provider_when_metadata_defines_alias() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(MetadataExistingModule.class);
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'AliasProvider',
            Type__c = 'Existing',
            Value__c = 'TargetService', // This token must exist in the module
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'AliasProvider' => mockMdt });

        // Act
        Object target = ref.get('TargetService');
        Object alias = ref.get('AliasService');

        // Assert
        Assert.isTrue(target instanceof TestServiceImpl, 'Target service should be of the correct type.');
        Assert.areEqual(target, alias, 'Alias resolved from metadata should point to the same instance as the target.');
    }

    @IsTest
    static void should_read_metadata_scope_when_using_default_context() {
        // Arrange: Mock a metadata alias with explicit scope in the default context.
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'AliasProvider',
            Type__c = 'Existing',
            Value__c = 'TargetService',
            IsActive__c = true,
            Scope__c = 'PROTOTYPE'
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'AliasProvider' => mockMdt });
        Di.CustomMetadataTypesProvider provider = new Di.CustomMetadataTypesProvider('AliasService', 'AliasProvider');

        // Act: Standalone metadata providers expose their normalized definition through the default context.
        // Assert: Verify the expected outcome.
        Assert.areEqual(Di.Scope.PROTOTYPE, provider.getScope(), 'Default context should supply metadata scope.');
        Assert.areEqual(
            'TargetService',
            provider.getExisting(),
            'Default context should supply metadata alias target.'
        );
    }

    @IsTest
    static void should_read_unmocked_metadata_when_using_application_context() {
        // Arrange: Use a context without provider mocks, so it falls through to DI_Provider__mdt.getAll().
        Di.ApplicationContext context = Di.createContext();
        context.mockModules(new List<DI_Module__mdt>());
        Di.ModuleRef ref = context.getModuleRef(MetadataModule.class);

        // Act: No packaged metadata records exist for this test token, so the framework error is raised.
        try {
            ref.get(IMetadataService.class);
            Assert.fail('Expected InvalidProviderException for missing unmocked metadata provider.');
        } catch (Di.InvalidProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('ConfigurableService'),
                'Exception should identify the missing metadata provider developer name.'
            );
        }
    }

    @IsTest
    static void should_respect_prototype_scope_when_metadata_defines_existing_provider() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(MetadataProtoAliasModule.class);

        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'AliasProtoProvider',
            Type__c = 'Existing',
            Value__c = 'PrototypeService',
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'AliasProtoProvider' => mockMdt });

        // Act: Execute the behavior under test.
        Object inst1 = ref.resolve('AliasService');
        Object inst2 = ref.resolve('AliasService');

        // Act: Execute the behavior under test.
        // Assert: Verify the expected outcome.
        Assert.areNotEqual(inst1, inst2, 'Existing provider pointing to Prototype should return new instances.');
    }

    @IsTest
    static void should_throw_when_getting_metadata_existing_alias_to_prototype_provider() {
        // Arrange: A metadata Existing provider points to a prototype-scoped target provider.
        Di.ModuleRef ref = Di.getModuleRef(MetadataProtoAliasModule.class);
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'AliasProtoProvider',
            Type__c = 'Existing',
            Value__c = 'PrototypeService',
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'AliasProtoProvider' => mockMdt });

        // Act: get() should inherit the target provider's prototype guard.
        try {
            ref.get('AliasService');
            Assert.fail('Expected InvalidScopeException for metadata alias to prototype provider.');
        } catch (Di.InvalidScopeException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Use resolve() method instead'),
                'Exception message should guide the user to use resolve().'
            );
        }
    }

    @IsTest
    static void should_throw_when_resolving_metadata_existing_provider_directly() {
        // Arrange: Metadata Existing providers are alias definitions and should only resolve through a container.
        Di.ModuleRef ref = Di.getModuleRef(MetadataProtoAliasModule.class);
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'AliasProtoProvider',
            Type__c = 'Existing',
            Value__c = 'PrototypeService',
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'AliasProtoProvider' => mockMdt });
        Di.Provider provider = ref.getModule().provide('AliasService').useMetadata('AliasProtoProvider');

        // Act: Direct provider resolution is invalid for aliases.
        try {
            provider.resolve(ref, null);
            Assert.fail('Expected InvalidProviderException when directly resolving a metadata Existing provider.');
        } catch (Di.InvalidProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('This operation is not supported'),
                'Exception message should indicate that alias providers are not directly executable.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_metadata_provider_type_is_invalid() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'InvalidProvider',
            Type__c = 'InvalidType', // This is not a valid provider type
            Value__c = 'any',
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'InvalidProvider' => mockMdt });

        // Act: Execute the behavior under test.
        try {
            ref.get('InvalidValue');
            Assert.fail('Expected InvalidProviderException was not thrown for invalid metadata type.');
        } catch (Di.InvalidProviderException e) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                e.getMessage().contains('Invalid provider configuration'),
                'Exception message should indicate an invalid configuration.'
            );
        }
    }

    @IsTest
    static void should_reset_metadata_cache_when_context_is_cleared() {
        // Arrange: Prepare two different mock metadata configurations for the same token.
        DI_Provider__mdt mockMdt1 = new DI_Provider__mdt(
            DeveloperName = 'ConfigurableService',
            Type__c = 'Value',
            Value__c = 'FirstValue',
            IsActive__c = true
        );
        DI_Provider__mdt mockMdt2 = new DI_Provider__mdt(
            DeveloperName = 'ConfigurableService',
            Type__c = 'Value',
            Value__c = 'SecondValue',
            IsActive__c = true
        );

        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);

        // Act: Load the first mock and resolve it. This should populate the static cache in Di.cls.
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'ConfigurableService' => mockMdt1 });
        Object result1 = ref.resolve(IMetadataService.class);

        // Act: Clear the framework state. This SHOULD clear the static cache.
        Di.clear();

        // Act: Load the second mock and resolve it.
        // If the cache was not cleared, this will return 'FirstValue' again.
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'ConfigurableService' => mockMdt2 });
        // We must re-get the module ref because clear() wiped the module registry
        ref = Di.getModuleRef(MetadataModule.class);
        Object result2 = ref.resolve(IMetadataService.class);

        // Assert
        Assert.areEqual('FirstValue', result1, 'Pre-condition: First mock should resolve correctly.');
        Assert.areEqual(
            'SecondValue',
            result2,
            'Post-clear: Second mock should be used, proving the validation cache was reset.'
        );
    }

    @IsTest
    static void should_respect_scope_when_defined_in_metadata() {
        // Arrange: Mock a metadata provider with SCOPED scope.
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'ConfigurableService',
            Type__c = 'Class',
            Value__c = 'DiTest.TestServiceImpl',
            IsActive__c = true,
            Scope__c = 'SCOPED'
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'ConfigurableService' => mockMdt });
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);

        // Act: Create two scopes and resolve the provider from each.
        Di.ScopeRef scope1 = ref.createScope();
        Di.ScopeRef scope2 = ref.createScope();

        // We use the string token because that's how the metadata provider is registered in MetadataModule
        Object instance1 = scope1.get(IMetadataService.class);
        Object instance2 = scope2.get(IMetadataService.class);

        // Assert: They should be different instances (SCOPED).
        Assert.areNotEqual(
            instance1,
            instance2,
            'Metadata-defined SCOPED provider should return different instances for different scopes.'
        );
    }

    @IsTest
    static void should_respect_prototype_scope_when_defined_in_metadata() {
        // Arrange: Mock a metadata provider with PROTOTYPE scope.
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'ConfigurableService',
            Type__c = 'Class',
            Value__c = 'DiTest.TestServiceImpl',
            IsActive__c = true,
            Scope__c = 'PROTOTYPE'
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'ConfigurableService' => mockMdt });
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);

        // Act: Resolve twice from the same container.
        // Note: We use resolve() because get() throws for PROTOTYPE.
        Object instance1 = ref.resolve(IMetadataService.class);
        Object instance2 = ref.resolve(IMetadataService.class);

        // Assert: They should be different instances (PROTOTYPE).
        Assert.areNotEqual(
            instance1,
            instance2,
            'Metadata-defined PROTOTYPE provider should return new instance on every resolve.'
        );
    }

    @IsTest
    static void should_throw_invalid_provider_exception_when_get_uses_invalid_metadata_scope() {
        // Arrange: Mock a metadata provider with an invalid scope string.
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'ConfigurableService',
            Type__c = 'Class',
            Value__c = 'DiTest.TestServiceImpl',
            IsActive__c = true,
            Scope__c = 'NOT_A_SCOPE'
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'ConfigurableService' => mockMdt });
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);

        // Act: get() should wrap invalid metadata scopes in a framework exception.
        try {
            ref.get(IMetadataService.class);
            Assert.fail('Expected InvalidProviderException for invalid metadata scope.');
        } catch (Di.InvalidProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Invalid metadata scope "NOT_A_SCOPE"'),
                'Exception message should identify the invalid metadata scope.'
            );
        }
    }

    @IsTest
    static void should_throw_invalid_provider_exception_when_resolve_uses_invalid_metadata_scope() {
        // Arrange: Mock a metadata provider with an invalid scope string.
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'ConfigurableService',
            Type__c = 'Class',
            Value__c = 'DiTest.TestServiceImpl',
            IsActive__c = true,
            Scope__c = 'NOT_A_SCOPE'
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'ConfigurableService' => mockMdt });
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);

        // Act: resolve() should wrap invalid metadata scopes in a framework exception.
        try {
            ref.resolve(IMetadataService.class);
            Assert.fail('Expected InvalidProviderException for invalid metadata scope.');
        } catch (Di.InvalidProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Invalid metadata scope "NOT_A_SCOPE"'),
                'Exception message should identify the invalid metadata scope.'
            );
        }
    }
    // </editor-fold>

    // <editor-fold desc="Arguments and Caching">
    @IsTest
    static void should_bypass_singleton_cache_when_resolving_with_arguments() {
        // Arrange
        Di.clear();
        Di.ModuleRef consumerCtn = Di.getModuleRef(ArgsValidationModule.class);

        // Act: Execute the behavior under test.
        // 1. Resolve with Args "A"
        Object instanceA = consumerCtn.resolve('SingletonArgsFactory', 'A');
        // Act: Execute the behavior under test.
        // Assert: Verify the expected outcome.
        Assert.areEqual('A', instanceA, 'Should return args as instance');

        // 2. Resolve with Args "B"
        Object instanceB = consumerCtn.resolve('SingletonArgsFactory', 'B');
        Assert.areEqual('B', instanceB, 'Should return new args as instance, bypassing cache');

        // 3. Verify instances are different
        Assert.areNotEqual(instanceA, instanceB, 'Instances with different args should be different');

        // 4. Resolve with NO Args (should use/create Singleton Cache)
        Object instanceNull = consumerCtn.get('SingletonArgsFactory');
        // ArgsFactory returns 'args', so it returns null.
        Assert.isNull(instanceNull, 'Should return null when no args passed');

        // 5. Resolve with NO Args again (should be same cached instance)
        Object instanceNull2 = consumerCtn.get('SingletonArgsFactory');
        Assert.areEqual(instanceNull, instanceNull2, 'Should return cached instance when no args passed');

        // 6. Resolve with Args "C" (should still bypass cache even if cache is populated)
        Object instanceC = consumerCtn.resolve('SingletonArgsFactory', 'C');
        Assert.areEqual('C', instanceC, 'Should bypass cache even if cache is populated');
    }

    @IsTest
    static void should_throw_when_getting_with_arguments() {
        // Arrange
        Di.clear();
        Di.ModuleRef consumerCtn = Di.getModuleRef(ArgsValidationModule.class);

        // Act: Execute the behavior under test.
        try {
            consumerCtn.get('SingletonArgsFactory', 'someArgs');
            Assert.fail('Expected InvalidProviderException when calling get(String, args).');
        } catch (Di.InvalidProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Use resolve()'),
                'Exception message should guide callers to resolve() for runtime arguments.'
            );
        }
    }

    @IsTest
    static void should_throw_when_resolving_non_factory_with_arguments() {
        // Arrange
        Di.clear();
        Di.ModuleRef consumerCtn = Di.getModuleRef(ArgsValidationModule.class);

        // Act: Execute the behavior under test.
        Integer unsupportedArgsAssertions = 0;
        unsupportedArgsAssertions += assertResolveArgsUnsupported(consumerCtn, 'ClassProvider');
        unsupportedArgsAssertions += assertResolveArgsUnsupported(consumerCtn, 'ValueProvider');
        unsupportedArgsAssertions += assertResolveArgsUnsupported(consumerCtn, 'ExistingProvider');
        // Act: Execute the behavior under test.
        // Assert: Verify the expected outcome.
        Assert.areEqual(3, unsupportedArgsAssertions, 'All non-factory providers should reject runtime arguments.');
    }
    // </editor-fold>

    // <editor-fold desc="Module System">
    @IsTest
    static void should_resolve_internal_provider_when_module_is_imported() {
        // Arrange: A module that imports another module is registered.
        Di.ModuleRef ref = Di.getModuleRef(InternalConsumerModule.class);

        // Act: The module's internal method, which uses an imported provider, is called.
        Object val = ref.get('internal');

        // Assert: The provider from the imported module was resolved and used successfully.
        Assert.areEqual('bar', val, 'Module should be able to use providers from its imports.');
    }

    @IsTest
    static void should_allow_local_override_when_import_exports_same_token() {
        // Arrange: A module imports another module but also provides a provider with the same token.
        Di.ModuleRef ref = Di.getModuleRef(OverrideModule.class);

        // Act: The provider with the conflicting token is requested.
        Object val = ref.get('foo');

        // Assert: The value matches the one set in the constructor.
        // If the regression exists, it will likely resolve a NEW instance of ConfigurableModule (via default constructor or similar),
        // which might resolve to 'defaultValue' or null depending on implementation.
        Assert.areEqual('override', val, 'Local provider should always override an imported one.');
    }

    @IsTest
    static void should_reject_provider_when_imports_export_ambiguous_token() {
        // Arrange: A consumer imports two modules that export the same token from different owners.
        Di.ModuleRef ref = Di.getModuleRef(AmbiguousImportConsumerModule.class);

        // Act: The ambiguous token is requested from the consumer.
        try {
            ref.get('ambiguousImportVal');
            Assert.fail('Expected InvalidProviderException for ambiguous imported provider token.');
        } catch (Di.InvalidProviderException ex) {
            // Assert: The error identifies the ambiguous token and context.
            Assert.isTrue(
                ex.getMessage().contains('ambiguousImportVal'),
                'Exception message should identify the ambiguous provider token.'
            );
            Assert.isTrue(
                ex.getMessage().contains('AmbiguousImportConsumerModule'),
                'Exception message should identify the consuming module context.'
            );
        }
    }

    @IsTest
    static void should_allow_duplicate_reexports_when_imports_share_owner() {
        // Arrange: Two imported modules re-export the same provider owned by a shared common module.
        Di.ModuleRef ref = Di.getModuleRef(SharedImportReexportConsumerModule.class);

        // Act: The duplicate visible token is requested from the consumer.
        Object val = ref.get('sharedImportReexportVal');

        // Assert: Identical owner bindings are not ambiguous.
        Assert.areEqual(
            'shared',
            val,
            'Imports should be allowed to expose the same provider when the provider owner is identical.'
        );
    }

    @IsTest
    static void should_reuse_visible_binding_index_when_graph_is_unchanged() {
        // Arrange: A consumer exposes how often its import visibility is traversed.
        Di.ApplicationContext context = newTestContext();
        BindingIndexCountingConsumerModule consumer = new BindingIndexCountingConsumerModule();
        Di.ModuleRef consumerRef = context.addModule(consumer);

        // Act: Resolve the same imported binding twice without mutating the graph.
        Assert.areEqual('hello', consumerRef.get('val'));
        Integer traversalsAfterFirstLookup = consumer.importTraversalCount;
        Assert.areEqual('hello', consumerRef.get('val'));

        // Assert: Dynamic resolution should reuse the context's visible-binding index.
        Assert.areEqual(
            traversalsAfterFirstLookup,
            consumer.importTraversalCount,
            'Repeated imported-provider lookups should not rescan module visibility.'
        );

        // Act: Replace the imported owner provider and resolve through the consumer again.
        Integer traversalsBeforeMutation = consumer.importTraversalCount;
        context.replaceProvider(ValueModule.class, consumer.provide('val').useValue('updated'));
        consumerRef = context.getModuleRef(BindingIndexCountingConsumerModule.class);
        Assert.areEqual('updated', consumerRef.get('val'));
        Integer traversalsAfterMutation = consumer.importTraversalCount;
        Assert.areEqual(
            traversalsBeforeMutation,
            traversalsAfterMutation,
            'Binding invalidation should reuse the committed import snapshot without rerunning declarations.'
        );

        // Assert: The rebuilt binding is reused until another mutation occurs.
        Assert.areEqual('updated', consumerRef.get('val'));
        Assert.areEqual(
            traversalsAfterMutation,
            consumer.importTraversalCount,
            'The rebuilt visible-binding index should remain current until the graph changes again.'
        );
    }

    @IsTest
    static void should_share_singleton_export_when_multiple_modules_import_owner() {
        // Arrange: Two modules import the same exported singleton provider from a shared module.
        Di.ModuleRef leftRef = Di.getModuleRef(SharedSingletonConsumerLeftModule.class);
        Di.ModuleRef rightRef = Di.getModuleRef(SharedSingletonConsumerRightModule.class);

        // Act: Each consumer resolves the exported provider.
        Object leftInstance = leftRef.get(SharedSingletonService.class);
        Object rightInstance = rightRef.get(SharedSingletonService.class);

        // Assert: The singleton belongs to the exporting module and should be shared by all importers.
        Assert.areEqual(
            leftInstance,
            rightInstance,
            'Exported singleton providers should be cached by the owning module, not per importer.'
        );
    }

    @IsTest
    static void should_resolve_private_dependency_when_exported_provider_uses_owner_context() {
        // Arrange: A consumer imports a module that exports a facade but keeps the facade dependency private.
        Di.ModuleRef consumerRef = Di.getModuleRef(PrivateFacadeConsumerModule.class);

        // Act: Resolve the exported facade from the importing module.
        ExportedPrivateFacade facade = (ExportedPrivateFacade) consumerRef.get(ExportedPrivateFacade.class);

        // Assert: The facade should be injected using its owner module context and see private owner providers.
        Assert.areEqual(
            'private-dependency',
            facade.getDependencyValue(),
            'Exported providers should be autowired with their owning module visibility.'
        );
    }

    @IsTest
    static void should_reject_local_and_global_registrations_with_same_canonical_token() {
        // Arrange: A global module owns the canonical token and a private provider dependency.
        Di.addGlobalModule(new TokenCollisionGlobalOwnerModule());
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);

        // Act: A local registration attempts to claim the same canonical token.
        try {
            Di.addModule(new TokenCollisionLocalModule());
            Assert.fail('Expected conflicting module visibility to be rejected.');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('already registered as global'));
        }
        ExportedPrivateFacade facade = (ExportedPrivateFacade) consumerRef.get(ExportedPrivateFacade.class);

        // Assert: The failed collision leaves global owner routing intact.
        Assert.areEqual(
            'private-dependency',
            facade.getDependencyValue(),
            'Global provider ownership should remain intact after rejecting a local collision.'
        );
    }

    @IsTest
    static void should_resolve_export_and_alias_when_owner_context_is_required() {
        // Arrange: Consumers import exported providers owned by other modules.
        Di.ModuleRef privateFacadeConsumerRef = Di.getModuleRef(PrivateFacadeConsumerModule.class);
        Di.ModuleRef aliasConsumerRef = Di.getModuleRef(ExportedAliasConsumerModule.class);

        // Act: Use resolve(), which bypasses singleton caches but must still use owner visibility.
        ExportedPrivateFacade facade = (ExportedPrivateFacade) privateFacadeConsumerRef.resolve(
            ExportedPrivateFacade.class
        );
        Object aliasInstance = aliasConsumerRef.resolve('SharedExportAlias');

        // Assert: Both concrete providers and aliases resolve through the owner container.
        Assert.areEqual(
            'private-dependency',
            facade.getDependencyValue(),
            'resolve() should autowire exported providers with owner visibility.'
        );
        Assert.isTrue(
            aliasInstance instanceof SharedSingletonService,
            'resolve() should preserve owner context when following an exported alias.'
        );
    }

    @IsTest
    static void should_not_resolve_exported_provider_when_dependency_is_consumer_only() {
        // Arrange: The owner exports a facade, while the consumer separately imports the facade dependency.
        Di.ModuleRef consumerRef = Di.getModuleRef(ConsumerOnlyDependencyConsumerModule.class);

        // Act: Exported providers should not inherit the consumer module's import visibility.
        try {
            consumerRef.get(ExportedConsumerOnlyFacade.class);
            Assert.fail('Expected UnknownProviderException was not thrown.');
        } catch (Di.UnknownProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains(ConsumerOnlyDependencyService.class.getName()),
                'The exported provider should not see dependencies imported only by its consumer.'
            );
        }
    }

    @IsTest
    static void should_scope_exported_provider_when_resolved_from_importing_scope() {
        // Arrange: A scoped provider is exported from an imported owner module.
        Di.ScopeRef firstScope = Di.getModuleRef(ScopedExportConsumerModule.class).createScope();
        Di.ScopeRef secondScope = Di.getModuleRef(ScopedExportConsumerModule.class).createScope();

        // Act: Resolve the exported scoped provider twice in one scope and once in another.
        Object firstInstance = firstScope.get(ScopedExportService.class);
        Object repeatedInstance = firstScope.get(ScopedExportService.class);
        Object otherScopeInstance = secondScope.get(ScopedExportService.class);

        // Assert: The provider remains scoped within the logical request, even though its owner module differs.
        Assert.areEqual(
            firstInstance,
            repeatedInstance,
            'Exported scoped providers should be cached inside the active scope.'
        );
        Assert.areNotEqual(
            firstInstance,
            otherScopeInstance,
            'Each scope should receive its own exported scoped provider instance.'
        );
    }

    @IsTest
    static void should_share_scoped_provider_when_module_refs_use_same_scope_context() {
        // Arrange: Two different consumers participate in the same logical unit of work.
        Di.ScopeContext scopeContext = new Di.ScopeContext();
        Di.ModuleRef leftRef = Di.getModuleRef(ScopedExportConsumerLeftModule.class);
        Di.ModuleRef rightRef = Di.getModuleRef(ScopedExportConsumerRightModule.class);

        // Act: Resolve the same exported scoped provider through two different module refs.
        Object leftInstance = leftRef.createScope(scopeContext).get(ScopedExportService.class);
        Object rightInstance = rightRef.createScope(scopeContext).get(ScopedExportService.class);
        Object isolatedInstance = rightRef.createScope(new Di.ScopeContext()).get(ScopedExportService.class);

        // Assert: Shared scope contexts share scoped instances; different contexts do not.
        Assert.areEqual(
            leftInstance,
            rightInstance,
            'A shared ScopeContext should cache scoped providers across module refs in one unit of work.'
        );
        Assert.areNotEqual(
            leftInstance,
            isolatedInstance,
            'A different ScopeContext should receive an isolated scoped provider instance.'
        );
    }

    @IsTest
    static void should_reject_scope_context_when_shared_across_application_contexts() {
        // Arrange: One logical scope is already bound to a module in the left application context.
        Di.ScopeContext scopeContext = new Di.ScopeContext();
        Di.ApplicationContext leftContext = newTestContext();
        Di.ApplicationContext rightContext = newTestContext();
        leftContext.getModuleRef(ScopedModule.class).createScope(scopeContext);

        // Act: Reusing that cache in another isolated graph is rejected.
        try {
            rightContext.getModuleRef(ScopedModule.class).createScope(scopeContext);
            Assert.fail('Expected InvalidScopeException for a cross-context ScopeContext.');
        } catch (Di.InvalidScopeException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('cannot be shared across application contexts'),
                'Error should explain that ScopeContext ownership is application-context-local.'
            );
        }
    }

    @IsTest
    static void should_handle_resolution_gracefully_when_imports_are_circular() {
        // Arrange: Modules with a circular dependency (A -> B -> C -> A) are defined.
        Exception unexpectedEx;

        // Act: An attempt is made to get a provider, which triggers the lazy circular resolution.
        try {
            Di.getModuleRef(CircularA.class).get('any');
        } catch (Exception e) {
            unexpectedEx = e;
        }

        // Assert: No "Maximum stack depth reached" error occurs, it fails with a predictable exception.
        Assert.isTrue(
            unexpectedEx instanceof Di.UnknownProviderException,
            'Resolution should fail cleanly, not with a stack overflow.'
        );
    }

    @IsTest
    static void should_reject_circular_imports_when_compiling_application_context_graph() {
        // Arrange: Compiled graphs validate the whole module import graph up front.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new CircularA());

        // Act: A circular module-import graph is rejected during compile.
        try {
            context.compile();
            Assert.fail('Expected InvalidModuleException for circular module imports.');
        } catch (Di.InvalidModuleException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Circular module import detected'),
                'Compile should reject circular module import graphs.'
            );
            Assert.isTrue(
                ex.getMessage().contains(new CircularA().getToken()) ||
                    ex.getMessage().contains(new CircularB().getToken()) ||
                    ex.getMessage().contains(new CircularC().getToken()),
                'Error should identify one module from the import cycle.'
            );
        }
    }

    @IsTest
    static void should_prevent_recursion_when_registering_self_importing_module() {
        // Arrange: A module that imports itself is defined.
        Exception unexpectedEx;

        // Act: The module is registered. The internal `visited` set should prevent a stack depth error.
        try {
            Di.getModuleRef(SelfImportingModule.class);
        } catch (Exception e) {
            unexpectedEx = e;
        }

        // Assert: No exception is thrown during registration.
        Assert.isNull(unexpectedEx, 'Registering a module that imports itself should not cause a crash.');
    }

    @IsTest
    static void should_throw_exception_when_exporting_unknown_provider() {
        // Arrange: A module attempts to export a token that it does not provide.
        // Act: An attempt is made to register the module.
        try {
            Di.getModuleRef(LocalErrorModule.class);
            Assert.fail('Expected an exception for an unknown export.');
        } catch (Di.UnknownExportException ex) {
            // Assert: The correct exception is thrown because the provider is not in the `providers` array.
            Assert.isTrue(
                ex.getMessage().contains('Cannot export "missing"'),
                'Error should indicate the provider is not registered locally.'
            );
        }
    }

    @IsTest
    static void should_not_keep_module_in_registry_when_registration_fails() {
        // Arrange: A module registration fails because it exports an unknown provider.
        LocalErrorModule failingModule = new LocalErrorModule();
        String failedToken = failingModule.getToken();
        try {
            Di.addGlobalModule(failingModule);
            Assert.fail('Expected an exception for an unknown export.');
        } catch (Di.UnknownExportException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot export "missing"'),
                'Pre-condition: registration should fail before the retry.'
            );
        }

        // Act: Retry registration with a valid module using the same token.
        Di.DynamicModule validRetry = new Di.DynamicModule(failedToken);
        validRetry.addProvider(validRetry.provide('retryValue').useValue('registered')).addExport('retryValue');
        Di.ModuleRef retryRef = Di.addModule(validRetry);

        // Assert: The failed attempt did not poison the module registry.
        Assert.areEqual(
            'registered',
            retryRef.get('retryValue'),
            'A failed registration should not block a clean retry with the same module token.'
        );
    }

    @IsTest
    static void should_not_keep_global_module_in_registry_when_registration_fails() {
        // Arrange: A global module registration fails because it exports an unknown provider.
        GlobalErrorModule failingModule = new GlobalErrorModule();
        String failedToken = failingModule.getToken();
        try {
            Di.addModule(failingModule);
            Assert.fail('Expected an exception for an unknown global export.');
        } catch (Di.UnknownExportException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot export "missingGlobal"'),
                'Pre-condition: global registration should fail before the retry.'
            );
        }

        // Act: Retry registration with a valid global module using the same token.
        Di.DynamicModule validRetry = new Di.DynamicModule(failedToken);
        validRetry.addProvider(validRetry.provide('globalRetryValue').useValue('registered'))
            .addExport('globalRetryValue');
        Di.addGlobalModule(validRetry);

        // Assert: The failed global attempt did not poison the global module registry.
        Assert.areEqual(
            'registered',
            Di.getModuleRef(EmptyModule.class).get('globalRetryValue'),
            'A failed global registration should not block a clean retry with the same module token.'
        );
    }

    @IsTest
    static void should_get_module_ref_when_module_instance_is_supplied() {
        // Arrange: A module instance is created but not yet registered.
        Di.Module mod = new ValueModule();

        // Act: The module reference is retrieved using the instance itself.
        Di.ModuleRef ref = Di.getModuleRef(mod);

        // Assert: The module is now registered and its providers are resolvable.
        Assert.isNotNull(ref, 'getModuleRef by instance should return a valid reference.');
        Assert.areEqual('hello', ref.get('val'), 'Provider should be resolvable from module registered by instance.');
    }

    @IsTest
    static void should_return_existing_ref_when_module_instance_is_registered() {
        // Arrange: A local module and a global module are registered.
        Di.Module localMod = new ValueModule();
        Di.ModuleRef localRef1 = Di.addModule(localMod);
        Di.DynamicModule globalMod = new Di.DynamicModule('G');
        Di.ModuleRef globalRef1 = Di.addGlobalModule(globalMod);

        // Act: getModuleRef is called again with the same instances.
        Di.ModuleRef localRef2 = Di.getModuleRef(localMod);
        Di.ModuleRef globalRef2 = Di.getModuleRef(globalMod);

        // Assert: The returned references are the same as the initially registered ones.
        Assert.areEqual(localRef1, localRef2, 'Should return existing ref for local module instance.');
        Assert.areEqual(globalRef1, globalRef2, 'Should return existing ref for global module instance.');
    }

    @IsTest
    static void should_reject_module_instance_when_token_is_already_registered() {
        // Arrange: One module instance has already claimed its token in the registry.
        ConfigurableModule registered = new ConfigurableModule('registered');
        Di.ModuleRef ref = Di.getModuleRef(registered);

        // Act: A different instance with the same token must not silently reuse the registered ref.
        try {
            Di.getModuleRef(new ConfigurableModule('other'));
            Assert.fail('Expected InvalidModuleException for a distinct module instance with a registered token.');
        } catch (Di.InvalidModuleException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('already been registered'),
                'Exception message should identify the duplicate module token.'
            );
        }

        Assert.areEqual('registered', ref.get('configVal'), 'The original registered module should remain active.');
    }

    @IsTest
    static void should_evaluate_modules_as_equal_when_tokens_match() {
        // Arrange: Create two modules with the same token and one with a different token.
        Di.Module moduleA1 = new Di.DynamicModule('ModuleA');
        Di.Module moduleA2 = new Di.DynamicModule('ModuleA');
        Di.Module moduleB = new Di.DynamicModule('ModuleB');

        // Act: Check equality and hash code consistency.
        // Assert: Verify the expected outcome.
        Assert.isTrue(moduleA1.equals(moduleA2), 'Modules with the same token should be equal.');
        Assert.areEqual(moduleA1.hashCode(), moduleA2.hashCode(), 'Hash codes for equal modules should be the same.');
        Assert.isFalse(moduleA1.equals(moduleB), 'Modules with different tokens should not be equal.');
        Assert.isFalse(moduleA1.equals('some string'), 'Module should not be equal to an object of a different type.');
        Assert.isFalse(moduleA1.equals(null), 'Module should not be equal to null.');
    }

    @IsTest
    static void should_report_graph_membership_when_provider_import_and_export_exist() {
        // Arrange: Get modules with different configurations to test each method.
        Di.Module modWithImport = Di.getModuleRef(InternalConsumerModule.class).getModule();
        Di.Module modWithProvider = Di.getModuleRef(SingleModule.class).getModule();
        Di.Module modWithExport = Di.getModuleRef(ValueModule.class).getModule();

        // Act: Test hasProvider() for locally defined providers.
        // Assert: Verify the expected outcome.
        Assert.isTrue(modWithProvider.hasProvider('TestService'), 'Should report having a local provider.');
        Assert.isFalse(
            modWithImport.hasProvider('foo'),
            'hasProvider should only check local providers, not imported ones.'
        );
        Assert.isFalse(modWithProvider.hasProvider('non_existent'), 'Should report not having a provider.');

        // Act: Test hasImport().
        Assert.isTrue(modWithImport.hasImport(BModule.class.getName()), 'Should report having an import.');
        Assert.isFalse(modWithProvider.hasImport(BModule.class.getName()), 'Should report not having an import.');

        // Act: Test hasExport().
        Assert.isTrue(modWithExport.hasExport('val'), 'Should report having an export.');
        Assert.isFalse(modWithImport.hasExport('foo'), 'Should report not having an export.');
    }
    // </editor-fold>

    // <editor-fold desc="Module Re-exports">
    @IsTest
    static void should_resolve_provider_when_module_is_reexported() {
        // Arrange: ModuleA imports ModuleB, which imports and re-exports ModuleC.
        Di.ModuleRef ref = Di.getModuleRef(ReexportConsumerModule.class);

        // Act: A provider from the deepest module (ModuleC) is requested from the top-level module.
        Object val = ref.get('serviceC');

        // Assert: The provider is resolved successfully because ModuleB re-exported ModuleC.
        Assert.areEqual('c-service', val, 'Provider should be visible through a re-exporting module.');
    }

    @IsTest
    static void should_not_resolve_provider_when_module_is_not_reexported() {
        // Arrange: ModuleA imports ModuleB, which imports but does NOT re-export ModuleC.
        Di.ModuleRef ref = Di.getModuleRef(NonReexportConsumerModule.class);

        // Act: An attempt to get a provider from ModuleC should fail.
        try {
            ref.get('serviceC');
            Assert.fail('Expected UnknownProviderException was not thrown.');
        } catch (Di.UnknownProviderException ex) {
            // Assert: Verify the expected outcome.
            // This is expected because ModuleB encapsulates ModuleC's providers.
            Assert.isTrue(
                ex.getMessage().contains('Could not find "serviceC" provider'),
                'Provider should not be visible without being re-exported.'
            );
        }
    }

    @IsTest
    static void should_reexport_provider_when_dynamic_module_reexports_owner() {
        // Arrange: A dynamic module is configured to import and re-export another module.
        Di.addModule(new ServiceCModule());
        Di.DynamicModule dynamicReexporter = new Di.DynamicModule('DynamicReexporter');
        dynamicReexporter.addImport(Di.import(ServiceCModule.class)).addReexport(Di.import(ServiceCModule.class));
        Di.ModuleRef ref = Di.addModule(dynamicReexporter);

        // Act: The re-exported provider is requested.
        Object val = ref.get('serviceC');

        // Assert: The provider is resolved correctly.
        Assert.areEqual('c-service', val, 'Dynamic modules should support re-exporting.');
    }

    @IsTest
    static void should_resolve_provider_when_reexport_is_transitive() {
        // Arrange: A consumer imports a reexporter that reexports another reexporting module.
        Di.ModuleRef ref = Di.getModuleRef(TransitiveReexportConsumerModule.class);

        // Act: A provider from the deepest module is requested from the top-level consumer.
        Object val = ref.get('serviceD');

        // Assert: Computed exports should flow through more than one reexport layer.
        Assert.areEqual('d-service', val, 'Provider should be visible through transitive reexports.');
    }

    @IsTest
    static void should_detect_circular_reexports_when_module_is_registered() {
        // Arrange: Prepare the test scenario.
        // Arrange / Act: A pair of modules reexport each other.
        // Act: Execute the behavior under test.
        try {
            Di.getModuleRef(CircularReexportAModule.class);
            Assert.fail('Expected InvalidModuleException for circular module reexports.');
        } catch (Di.InvalidModuleException ex) {
            // Assert: The module graph cycle is reported as a framework exception.
            Assert.isTrue(
                ex.getMessage().contains('Circular module reexport detected'),
                'Error should identify the circular reexport.'
            );
        }
    }
    // </editor-fold>

    // <editor-fold desc="Lazy and Compiled Graphs">
    @IsTest
    static void should_delay_module_resolution_when_import_is_lazy() {
        // Arrange: A consumer module lazily imports a module that does not exist yet.
        Di.ModuleRef consumerRef = Di.getModuleRef(LazyConsumerModule.class);

        // Act: The dependency module is added after the consumer.
        Di.addModule(new ValueModule());

        // Assert: The provider that depends on the import can be resolved.
        Assert.areEqual(
            'depends on hello',
            consumerRef.get('dependentVal'),
            'Dependent provider should resolve after its dependency becomes available.'
        );
    }

    @IsTest
    static void should_resolve_module_immediately_when_import_is_eager() {
        // Arrange: The dependency module is registered first.
        Di.addModule(new ValueModule());

        // Act: A module that immediately imports the dependency is registered.
        Di.ModuleRef ref = Di.getModuleRef(ImmediateConsumerModule.class);

        // Assert: The provider that depends on the import is available.
        Assert.areEqual(
            'depends on hello',
            ref.get('dependentVal'),
            'Provider from immediate import should be available.'
        );
    }

    @IsTest
    static void should_throw_exception_when_lazy_import_is_missing_at_runtime() {
        // Arrange: A module lazily imports a non-existent module class.
        Di.ModuleRef ref = Di.getModuleRef(LazyErrorConsumerModule.class);

        // Act: An attempt is made to get a provider from the missing module.
        try {
            ref.get('anyProvider');
            Assert.fail('Expected UnknownModuleException was not thrown.');
        } catch (Di.UnknownModuleException ex) {
            // Assert: The exception is thrown at runtime, on provider access.
            Assert.isTrue(
                ex.getMessage().contains('Cannot find module "NonExistent.Module"'),
                'Error should be thrown on provider access.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_compiling_context_with_missing_lazy_import() {
        // Arrange: A context contains a module with a lazy import for a non-existent module.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new LazyErrorConsumerModule());

        // Act: Compiling the context validates the whole graph before provider resolution.
        try {
            context.compile();
            Assert.fail('Expected UnknownModuleException was not thrown.');
        } catch (Di.UnknownModuleException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Cannot find module "NonExistent.Module"'),
                'Compile should validate lazy imports before runtime provider access.'
            );
        }
    }

    @IsTest
    static void should_resolve_provider_when_application_context_graph_is_compiled() {
        // Arrange: A context contains a consumer and its imported dependency.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new ValueModule());
        context.addModule(new LazyConsumerModule());

        // Act: Compile the graph and resolve through the compiled visibility map.
        context.compile();
        Object resolved = context.getModuleRef(LazyConsumerModule.class).get('dependentVal');

        // Assert
        Assert.areEqual('depends on hello', resolved, 'Compiled graph should preserve imported provider visibility.');
    }

    @IsTest
    static void should_preserve_local_override_when_application_context_graph_is_compiled() {
        // Arrange: A context contains a module with a local provider that overrides an imported token.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new OverrideModule());

        // Act
        context.compile();
        Object resolved = context.getModuleRef(OverrideModule.class).get('foo');

        // Assert
        Assert.areEqual('override', resolved, 'Compiled graph should preserve local provider precedence.');
    }

    @IsTest
    static void should_reject_ambiguous_imports_when_compiling_application_context_graph() {
        // Arrange: A context contains a consumer with two different imported owners for the same token.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new AmbiguousImportConsumerModule());

        // Act: Execute the behavior under test.
        try {
            context.compile();
            Assert.fail('Expected InvalidProviderException for ambiguous imported provider token.');
        } catch (Di.InvalidProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('ambiguousImportVal'),
                'Compile should identify the ambiguous provider token.'
            );
            Assert.isTrue(
                ex.getMessage().contains('AmbiguousImportConsumerModule'),
                'Compile should identify the consuming module context.'
            );
        }
    }

    @IsTest
    static void should_resolve_global_provider_when_application_context_graph_is_compiled() {
        // Arrange: A context has a global metadata module and a local consumer.
        Di.ApplicationContext context = newTestContext();
        context.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );
        context.addModule(new EmptyModule());

        // Act
        context.compile();
        Object resolved = context.getModuleRef(EmptyModule.class).get('cmtGlobalVal');

        // Assert
        Assert.areEqual(
            'helloFromCmt',
            resolved,
            'Compiled graph should expose global providers as fallback bindings.'
        );
    }

    @IsTest
    static void should_autowire_exported_provider_when_compiled_graph_preserves_owner_context() {
        // Arrange: A compiled context contains a consumer of an exported facade with a private owner dependency.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new PrivateFacadeConsumerModule());

        // Act
        context.compile();
        ExportedPrivateFacade facade = (ExportedPrivateFacade) context.getModuleRef(PrivateFacadeConsumerModule.class)
            .get(ExportedPrivateFacade.class);

        // Assert
        Assert.areEqual(
            'private-dependency',
            facade.getDependencyValue(),
            'Compiled graph bindings should preserve owner visibility for exported providers.'
        );
    }

    @IsTest
    static void should_scope_exported_provider_when_application_context_graph_is_compiled() {
        // Arrange: A compiled context contains a consumer of an exported scoped provider.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new ScopedExportConsumerModule());

        // Act
        context.compile();
        Di.ModuleRef consumerRef = context.getModuleRef(ScopedExportConsumerModule.class);
        Di.ScopeRef firstScope = consumerRef.createScope();
        Di.ScopeRef secondScope = consumerRef.createScope();
        Object firstInstance = firstScope.get(ScopedExportService.class);
        Object repeatedInstance = firstScope.get(ScopedExportService.class);
        Object otherScopeInstance = secondScope.get(ScopedExportService.class);

        // Assert
        Assert.areEqual(
            firstInstance,
            repeatedInstance,
            'Compiled graph should keep exported scoped providers cached within the active scope.'
        );
        Assert.areNotEqual(
            firstInstance,
            otherScopeInstance,
            'Compiled graph should keep exported scoped providers isolated across scopes.'
        );
    }

    @IsTest
    static void should_resolve_metadata_alias_when_application_context_graph_is_compiled() {
        // Arrange: A compiled context contains a metadata Existing alias and its local target.
        Di.ApplicationContext context = newTestContext();
        context.mockProviders(
            new Map<String, DI_Provider__mdt>{
                'AliasProvider' => new DI_Provider__mdt(
                    DeveloperName = 'AliasProvider',
                    Type__c = 'Existing',
                    Value__c = 'TargetService',
                    IsActive__c = true
                )
            }
        );
        context.addModule(new MetadataExistingModule());

        // Act
        context.compile();
        Di.ModuleRef ref = context.getModuleRef(MetadataExistingModule.class);
        Object target = ref.get('TargetService');
        Object alias = ref.get('AliasService');

        // Assert
        Assert.isTrue(target instanceof TestServiceImpl, 'Compiled metadata target should resolve normally.');
        Assert.areEqual(
            target,
            alias,
            'Compiled graph should unwrap metadata Existing aliases through the owning module.'
        );
    }

    @IsTest
    static void should_throw_when_compiled_application_context_graph_has_no_provider() {
        // Arrange: A context is compiled with a module that does not expose the requested token.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new ValueModule());
        context.compile();

        // Act: Execute the behavior under test.
        try {
            context.getModuleRef(ValueModule.class).get('missingCompiledProvider');
            Assert.fail('Expected UnknownProviderException for a token missing from the compiled graph.');
        } catch (Di.UnknownProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('missingCompiledProvider'),
                'Compiled graph lookup should reject unknown provider tokens.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_registering_module_with_missing_immediate_import() {
        // Arrange: Prepare the test scenario.
        // Arrange & Act: A module with an immediate import for a non-existent module is registered.
        // Act: Execute the behavior under test.
        try {
            Di.getModuleRef(ImmediateMissingImportModule.class);
            Assert.fail('Expected UnknownModuleException was not thrown.');
        } catch (Di.UnknownModuleException ex) {
            // Assert: The exception is thrown during module registration.
            Assert.isTrue(
                ex.getMessage().contains('Cannot find module "NonExistent.Module"'),
                'Error should be thrown while registering an immediate import.'
            );
        }
    }

    @IsTest
    static void should_resolve_immediately_when_module_instance_import_is_eager() {
        // Arrange: A module instance is created and used in an immediate import.
        Di.Module mod = new ValueModule();
        Di.ModuleImport moduleImport = Di.import(mod).immediately();

        // Act: The provider is fetched from the resolved module.
        Object val = moduleImport.resolve().getProvider('val');

        // Assert: The provider is resolved correctly.
        Assert.isNotNull(val, 'Provider should be available from an immediate import of a module instance.');
    }

    @IsTest
    static void should_not_reregister_module_when_cached_import_is_resolved_repeatedly() {
        // Arrange: A module instance import is created.
        Di.ApplicationContext context = newTestContext();
        RegisterCountingModule mod = new RegisterCountingModule();
        Di.ModuleImport moduleImport = context.import(mod).immediately();
        Assert.areEqual(0, mod.providerBuildCount, 'Pre-condition: import marker should not register standalone.');

        // Act: The same module instance import is resolved repeatedly.
        moduleImport.resolve().getProvider('counted');
        moduleImport.resolve().getProvider('counted');

        // Assert: Cached module instance imports should reuse the registered ModuleRef.
        Assert.areEqual(1, mod.providerBuildCount, 'Cached module imports should not re-register on each lookup.');
    }

    @IsTest
    static void should_evaluate_module_import_as_unequal_when_other_type_is_compared() {
        // Arrange: A module import is created.
        Di.ModuleImport importA = Di.import('ModuleA');

        // Act: Check equality against null and other object types.
        // Assert: Verify the expected outcome.
        Assert.isFalse(importA.equals(null), 'ModuleImport should not be equal to null.');
        Assert.isFalse(importA.equals('some string'), 'ModuleImport should not be equal to a string.');
    }

    @IsTest
    static void should_evaluate_module_imports_as_equal_when_tokens_match() {
        // Arrange: Create two imports with the same token and one with a different token.
        Di.ModuleImport importA1 = Di.import('ModuleA');
        Di.ModuleImport importA2 = Di.import(new Di.DynamicModule('ModuleA'));
        Di.ModuleImport importB = Di.import('ModuleB');

        // Act: Check equality based on the resolved token.
        // Assert: Verify the expected outcome.
        Assert.isTrue(importA1.equals(importA2), 'ModuleImports with the same token should be equal.');
        Assert.isFalse(importA1.equals(importB), 'ModuleImports with different tokens should not be equal.');
    }
    // </editor-fold>

    // <editor-fold desc="Global Modules">
    @IsTest
    static void should_load_and_resolve_provider_when_global_module_is_defined_in_metadata() {
        // Arrange: A mock CMT record is created to define a global module.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);

        // Act: The consumer requests a provider that only exists in the CMT-defined global module.
        Object val = consumerRef.get('cmtGlobalVal');

        // Assert: The provider is resolved from the global cache loaded from the mocked CMT.
        Assert.areEqual('helloFromCmt', val, 'Consumer should find providers from CMT global modules.');
    }

    @IsTest
    static void should_share_global_singleton_when_multiple_consumers_resolve_it() {
        // Arrange: A global module owns and exports a singleton provider.
        Di.addGlobalModule(new GlobalSharedSingletonModule());
        Di.ModuleRef leftRef = Di.getModuleRef(GlobalSingletonConsumerLeftModule.class);
        Di.ModuleRef rightRef = Di.getModuleRef(GlobalSingletonConsumerRightModule.class);

        // Act: Two unrelated consumers resolve the same global provider.
        Object leftInstance = leftRef.get(SharedSingletonService.class);
        Object rightInstance = rightRef.get(SharedSingletonService.class);

        // Assert: Global singletons should be cached by their owning global module, not per consumer.
        Assert.areEqual(
            leftInstance,
            rightInstance,
            'Global singleton providers should be shared by all consumers through the owner module cache.'
        );
    }

    @IsTest
    static void should_reject_global_export_when_token_has_different_owner() {
        // Arrange: One global module already publishes a token.
        Di.addGlobalModule(new DuplicateGlobalExportLeftModule());
        DuplicateGlobalExportRightModule rejectedModule = new DuplicateGlobalExportRightModule();

        // Act: Another global module attempts to publish the same token.
        try {
            Di.addGlobalModule(rejectedModule);
            Assert.fail('Expected InvalidProviderException for duplicate global export token.');
        } catch (Di.InvalidProviderException ex) {
            // Assert: The ambiguity is rejected with a framework exception.
            Assert.isTrue(
                ex.getMessage().contains('duplicateGlobalVal'),
                'Exception message should identify the duplicate provider token.'
            );
            Assert.isTrue(
                ex.getMessage().contains('already exported'),
                'Exception message should explain the global export collision.'
            );
        }

        // Assert: Rejecting the duplicate does not remove the original global binding.
        Assert.areEqual(
            'left',
            Di.getModuleRef(EmptyModule.class).get('duplicateGlobalVal'),
            'Failed duplicate global registration should leave the original export intact.'
        );
        Assert.isFalse(
            rejectedModule.hasProvider('duplicateGlobalVal'),
            'A rejected module instance must not retain an uncommitted provider definition.'
        );
    }

    @IsTest
    static void should_allow_global_reexports_when_bindings_share_owner() {
        // Arrange: Two global modules re-export the same provider owned by a shared common module.
        Di.addGlobalModule(new SharedGlobalReexportLeftModule());

        // Act: The second global module republishes the same owner binding.
        Di.addGlobalModule(new SharedGlobalReexportRightModule());

        // Assert: Identical owner bindings are not ambiguous and remain globally resolvable.
        Assert.areEqual(
            'shared',
            Di.getModuleRef(EmptyModule.class).get('sharedGlobalReexportVal'),
            'Globals should be allowed to re-export the same provider when the provider owner is identical.'
        );
    }

    @IsTest
    static void should_allow_long_class_names_when_global_module_is_stored_in_metadata() {
        // Arrange: Namespaced and inner Apex class names can exceed short text limits.
        Integer moduleClassLength = DI_Module__mdt.ModuleClass__c.getDescribe().getLength();

        // Act: The metadata field should support long fully-qualified class names.
        // Assert: Verify the expected outcome.
        Assert.isTrue(
            moduleClassLength >= 255,
            'ModuleClass__c should allow long namespaced or inner module class names.'
        );
    }

    @IsTest
    static void should_rollback_and_retry_when_global_metadata_load_fails() {
        // Arrange: A consumer exists before global metadata loading is triggered.
        Di.ModuleRef consumerRef = Di.addModule(new EmptyModule());
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                ),
                new DI_Module__mdt(
                    ModuleClass__c = 'DiTest.MissingGlobalModule',
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );

        // Act: Global loading fails after the first global module row has already been processed.
        try {
            Di.getModuleRef(CmtGlobalModule.class.getName());
            Assert.fail('Expected UnknownModuleException for the invalid global module row.');
        } catch (Di.UnknownModuleException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot find module "DiTest.MissingGlobalModule"'),
                'Pre-condition: global load should fail on the invalid metadata row.'
            );
        }

        // Assert: The failed load did not leave partially published global providers behind.
        try {
            consumerRef.get('cmtGlobalVal');
            Assert.fail('Failed global metadata loading should not publish partial providers.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Could not find "cmtGlobalVal" provider'),
                'Partially loaded global providers should be rolled back.'
            );
        }

        // Act: Corrected metadata in the same transaction should retry and load successfully.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );
        Di.getModuleRef(CmtGlobalModule.class.getName());

        // Assert: The corrected global metadata is now visible through a fresh handle.
        Assert.areEqual(
            'helloFromCmt',
            Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal'),
            'Global loading should retry after failure.'
        );
    }

    @IsTest
    static void should_prioritize_local_provider_when_global_token_conflicts() {
        // Arrange: A global module is defined via mocked CMT, and a local module provides a conflicting token.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = OverrideGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );
        Di.ModuleRef localRef = Di.getModuleRef(LocalOverrideModule.class);

        // Act: The local module requests the conflicting provider.
        Object val = localRef.get('val');

        // Assert: The local provider is returned.
        Assert.areEqual('local', val, 'Local providers must override global ones.');
    }

    @IsTest
    static void should_throw_exception_when_adding_duplicate_global_module() {
        // Arrange: A global module is added via mocked CMT, and its providers are resolved to trigger loading.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );
        Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal');

        // Act: An attempt is made to add another global module with the same token programmatically.
        try {
            Di.addGlobalModule(new CmtGlobalModule());
            Assert.fail('Expected InvalidModuleException was not thrown.');
        } catch (Di.InvalidModuleException ex) {
            // Assert: The correct exception is thrown.
            Assert.isTrue(
                ex.getMessage().contains('already been registered'),
                'Error message should indicate a duplicate registration.'
            );
        }
    }

    @IsTest
    static void should_return_existing_ref_when_global_module_token_is_registered() {
        // Arrange: A global module is loaded via CMT mock, and its ref is retrieved once to ensure it's in the registry.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );
        Di.ModuleRef ref1 = Di.getModuleRef(CmtGlobalModule.class.getName());

        // Act: The module reference is requested a second time using the same string token.
        Di.ModuleRef ref2 = Di.getModuleRef(CmtGlobalModule.class.getName());

        // Assert: The same ModuleRef instance is returned, hitting the `globalRegistry.get(token)` line.
        Assert.areEqual(ref1, ref2, 'Should return the existing ModuleRef from the global registry.');
    }

    @IsTest
    static void should_reject_distinct_global_instance_when_metadata_token_is_registered() {
        // Arrange: A global module is defined via CMT mock, but lookup passes a separate equivalent instance.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );

        // Act: The graph-owned CMT instance should not be replaced or ignored by a distinct instance.
        try {
            Di.getModuleRef(new CmtGlobalModule());
            Assert.fail(
                'Expected InvalidModuleException for a distinct global module instance with a registered token.'
            );
        } catch (Di.InvalidModuleException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('already been registered'),
                'Exception message should identify the duplicate global module token.'
            );
        }
    }

    @IsTest
    static void should_expose_provider_globally_when_global_module_reexports_it() {
        // Arrange: A global module re-exports the ValueModule's 'val' provider.
        // It does NOT explicitly list it in exports(), relying on re-export logic.
        Di.addGlobalModule(new GlobalReexportModule());

        // Act: A consumer requests the re-exported global provider.
        Di.ModuleRef consumer = Di.getModuleRef(EmptyModule.class);
        Object val = consumer.get('val');

        // Assert: The provider should be resolvable globally.
        Assert.areEqual('hello', val, 'Global modules should expose re-exported providers to the global scope.');
    }

    @IsTest
    static void should_reset_global_loading_flag_when_context_is_cleared() {
        // Arrange: Mock and Load
        Di.mockModules(
            new List<DI_Module__mdt>{ new DI_Module__mdt(DeveloperName = 'M', ModuleClass__c = 'DiTest.EmptyModule') }
        );
        Di.getModuleRef(EmptyModule.class);

        Assert.isTrue(Di.hasGlobalLoadBeenAttempted, 'Should be true after load');

        // Act
        Di.clear();

        // Assert: The flag MUST be reset to false to allow subsequent loads (e.g., from real metadata)
        Assert.isFalse(Di.hasGlobalLoadBeenAttempted, 'Should be reset to false after clear()');
    }

    @IsTest
    static void should_remove_reexported_providers_when_global_module_is_replaced() {
        // Arrange: Start with a global module that re-exports 'val'
        Di.addGlobalModule(new GlobalReexportModule());

        Di.ModuleRef consumer = Di.getModuleRef(EmptyModule.class);
        Assert.areEqual('hello', consumer.get('val'), 'Should resolve re-exported global provider initially');

        // Act: Replace with a module that exports NOTHING
        // Logic:
        // 1. replaceModule calls oldModule.exports() -> returns EMPTY (for GlobalReexportModule)
        // 2. It FAILS to remove 'val' from GLOBAL_PROVIDERS
        // 3. It adds new module exports (empty)
        // 4. 'val' remains global
        Di.replaceModule(GlobalReexportModule.class, new GlobalReexportModule2());

        // Assert: The 'val' provider should be GONE from global scope.
        try {
            Di.getModuleRef(EmptyModule.class).get('val');
            Assert.fail('Should have thrown UnknownProviderException because val should be removed from global scope');
        } catch (Di.UnknownProviderException e) {
            Assert.isNotNull(e, 'Expected UnknownProviderException');
        }
    }
    // </editor-fold>

    // <editor-fold desc="Dynamic Modules">
    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void should_build_module_when_dynamic_providers_and_exports_are_configured() {
        // Arrange: A dynamic module is configured with providers and exports.
        Di.DynamicModule dyn = new Di.DynamicModule('MyDynamicModule');
        dyn.addProvider(dyn.provide('dynamicVal').useValue('dynamic')).addExport('dynamicVal');
        Di.ModuleRef ref = Di.addModule(dyn);

        // Act: The dynamically defined provider is requested.
        Object val = ref.get('dynamicVal');

        // Assert: The provider is resolved correctly.
        Assert.areEqual('dynamic', val, 'Provider defined dynamically should be resolved.');
    }

    @IsTest
    static void should_build_module_when_dynamic_imports_are_configured() {
        // Arrange: A dynamic module is configured with an import.
        Di.DynamicModule dyn = new Di.DynamicModule('MyDynamicImporter');
        dyn.addImport(Di.import(ValueModule.class));
        Di.addModule(new ValueModule()); // Add the dependency
        Di.ModuleRef ref = Di.addModule(dyn);

        // Act: A provider from the imported module is requested.
        Object val = ref.get('val');

        // Assert: The provider is resolved correctly through the dynamic import.
        Assert.areEqual('hello', val, 'Provider from dynamically imported module should be resolved.');
    }

    @IsTest
    static void should_use_cached_module_instance_when_dynamic_module_imports_instance() {
        // Arrange: Create a module instance and configure it with a specific value.
        ConfigurableModule configModule = new ConfigurableModule('configuredValue');

        // Arrange: valid that we are wrapping it in a ModuleImport with the cached instance
        Di.ModuleImport modImport = Di.import(configModule);

        // Act: Create a dynamic module that imports this SPECIFIC instance
        Di.DynamicModule consumer = new Di.DynamicModule('ConsumerModule');
        consumer.addImport(modImport);

        Di.ModuleRef consumerRef = Di.addModule(consumer);

        // Act: Resolve the provider. It should use the value from the 'configModule' instance we passed.
        Object val = consumerRef.get('configVal');

        // Assert: The value matches the one set in the constructor.
        // If the regression exists, it will likely resolve a NEW instance of ConfigurableModule (via default constructor or similar),
        // which might resolve to 'defaultValue' or null depending on implementation.
        Assert.areEqual(
            'configuredValue',
            val,
            'Should use the pre-configured module instance provided to Di.import()'
        );
    }

    @IsTest
    static void should_register_dynamic_module_when_marked_global() {
        // Arrange: A dynamic module is configured and marked as global.
        Di.DynamicModule dynGlobal = new Di.DynamicModule('MyDynamicGlobal');
        dynGlobal.addProvider(dynGlobal.provide('dynGlobalVal').useValue('is-global')).addExport('dynGlobalVal');
        Di.addGlobalModule(dynGlobal);
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);

        // Act: A separate consumer module requests the provider from the dynamic global module.
        Object val = consumerRef.get('dynGlobalVal');

        // Assert: The provider is resolved from the global cache.
        Assert.areEqual('is-global', val, 'Provider from dynamic global module should be globally available.');
    }

    @IsTest
    static void should_reject_all_dynamic_module_mutations_after_successful_registration() {
        // Arrange: A fully configured dynamic module has committed successfully.
        Di.DynamicModule module = new Di.DynamicModule('SealedDynamicModule');
        module.addProvider(module.provide('sealedValue').useValue('stable')).addExport('sealedValue');
        Di.addModule(module);
        Integer rejectedMutationCount = 0;

        // Act and Assert: Every public structural mutator rejects the sealed declaration.
        try {
            module.addProvider(module.provide('lateProvider').useValue('late'));
            Assert.fail('Expected addProvider() to reject a sealed module.');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('sealed'));
            rejectedMutationCount++;
        }
        try {
            module.addImport(Di.import(ValueModule.class));
            Assert.fail('Expected addImport() to reject a sealed module.');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('sealed'));
            rejectedMutationCount++;
        }
        try {
            module.addExport('lateProvider');
            Assert.fail('Expected addExport() to reject a sealed module.');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('sealed'));
            rejectedMutationCount++;
        }
        try {
            module.addReexport(Di.import(ValueModule.class));
            Assert.fail('Expected addReexport() to reject a sealed module.');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('sealed'));
            rejectedMutationCount++;
        }
        Assert.areEqual(4, rejectedMutationCount, 'Every DynamicModule mutator should share the seal contract.');
    }

    @IsTest
    static void should_keep_dynamic_module_sealed_when_context_is_cleared_and_allow_unchanged_reregistration() {
        // Arrange: A committed dynamic declaration is released by clearing its first context.
        Di.ApplicationContext firstContext = Di.createContext();
        Di.DynamicModule module = new Di.DynamicModule('ReusableSealedDynamicModule');
        module.addProvider(module.provide('reusableValue').useValue('stable')).addExport('reusableValue');
        firstContext.addModule(module);
        firstContext.clear();

        // Act: Ownership release permits unchanged registration in another context.
        Di.ApplicationContext secondContext = Di.createContext();
        Di.ModuleRef secondRef = secondContext.addModule(module);

        // Assert: The declaration remains usable but cannot be reconfigured after clear().
        Assert.areEqual('stable', secondRef.get('reusableValue'));
        try {
            module.addProvider(module.provide('lateValue').useValue('late'));
            Assert.fail('Expected clear() not to reopen a sealed dynamic declaration.');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('sealed'));
        }
    }

    @IsTest
    static void should_keep_dynamic_module_editable_and_retryable_after_failed_registration() {
        // Arrange: An eager import is missing when a dynamic module first attempts registration.
        Di.ApplicationContext context = Di.createContext();
        Di.DynamicModule module = new Di.DynamicModule('RetryableDynamicModule');
        module.addImport(context.import('RetryableMissingImport').immediately());
        try {
            context.addModule(module);
            Assert.fail('Expected registration to fail while the eager import is missing.');
        } catch (Di.UnknownModuleException ex) {
            Assert.isTrue(ex.getMessage().contains('RetryableMissingImport'));
        }

        // Act: The still-editable candidate is corrected and retried.
        module.addProvider(module.provide('retryValue').useValue('corrected')).addExport('retryValue');
        context.addModule(new Di.DynamicModule('RetryableMissingImport'));
        Di.ModuleRef ref = context.addModule(module);

        // Assert: Failed registration did not seal or poison the candidate.
        Assert.areEqual('corrected', ref.get('retryValue'));
    }

    @IsTest
    static void should_release_replacement_candidate_context_when_registration_fails() {
        // Arrange: One context owns the valid original definition.
        Di.ApplicationContext firstContext = Di.createContext();
        Di.DynamicModule original = new Di.DynamicModule('FailedReplacementCandidate');
        original.addProvider(original.provide('stableReplacementValue').useValue('stable'))
            .addExport('stableReplacementValue');
        firstContext.addModule(original);
        Di.DynamicModule replacement = new Di.DynamicModule(original.getToken());
        replacement.addExport('missingReplacementExport');

        // Act: Candidate registration fails before registry publication.
        try {
            firstContext.replaceModule(original.getToken(), replacement);
            Assert.fail('Expected invalid replacement registration to fail.');
        } catch (Di.UnknownExportException ex) {
            Assert.isTrue(ex.getMessage().contains('missingReplacementExport'));
        }

        // Assert: The original survives and the failed candidate can be corrected and registered elsewhere.
        Assert.areEqual('stable', firstContext.getModuleRef(original.getToken()).get('stableReplacementValue'));
        replacement.addProvider(replacement.provide('missingReplacementExport').useValue('corrected'));
        Di.ApplicationContext secondContext = Di.createContext();
        Assert.areEqual('corrected', secondContext.addModule(replacement).get('missingReplacementExport'));
    }

    @IsTest
    static void should_update_global_dynamic_module_exports_when_replaced() {
        // Arrange: A global dynamic module is registered with one exported provider.
        Di.DynamicModule dynGlobal = new Di.DynamicModule('RefreshableGlobalDynamic');
        dynGlobal.addProvider(dynGlobal.provide('globalRefreshValue').useValue('initial'))
            .addExport('globalRefreshValue');
        Di.addGlobalModule(dynGlobal);
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);
        Assert.areEqual('initial', consumerRef.get('globalRefreshValue'), 'Pre-condition: global export is visible.');

        // Act: A new same-token module replaces the committed global definition.
        Di.DynamicModule replacement = new Di.DynamicModule(dynGlobal.getToken());
        replacement.addProvider(replacement.provide('globalRefreshValue').useValue('updated'));
        replacement.addProvider(replacement.provide('globalRefreshAdded').useValue('added'))
            .addExport('globalRefreshAdded');
        replacement.addExport('globalRefreshValue');
        Di.replaceModule(dynGlobal.getToken(), replacement);

        // Assert: Fresh global consumers should see the replacement export map and provider bindings.
        consumerRef = Di.getModuleRef(EmptyModule.class);
        Assert.areEqual(
            'updated',
            consumerRef.get('globalRefreshValue'),
            'Existing global exports should point to the replacement provider binding.'
        );
        Assert.areEqual(
            'added',
            consumerRef.get('globalRefreshAdded'),
            'New exports from replacement global modules should become globally visible.'
        );
    }

    @IsTest
    static void should_restore_global_module_definition_when_replacement_validation_fails() {
        // Arrange: Two global modules own distinct exports.
        Di.DynamicModule originalModule = new Di.DynamicModule('AtomicRefreshGlobal');
        originalModule.addProvider(originalModule.provide('atomicRefreshValue').useValue('stable'))
            .addExport('atomicRefreshValue');
        Di.ModuleRef originalRef = Di.addGlobalModule(originalModule);
        Di.DynamicModule conflictOwner = new Di.DynamicModule('AtomicRefreshConflictOwner');
        conflictOwner.addProvider(conflictOwner.provide('atomicRefreshConflict').useValue('owner'))
            .addExport('atomicRefreshConflict');
        Di.addGlobalModule(conflictOwner);
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);
        Assert.areEqual('stable', consumerRef.get('atomicRefreshValue'));

        // Act: A same-token replacement attempts to claim another global owner's export.
        Di.DynamicModule replacement = new Di.DynamicModule(originalModule.getToken());
        replacement.addProvider(replacement.provide('atomicRefreshValue').useValue('replacement'))
            .addExport('atomicRefreshValue');
        replacement.addProvider(replacement.provide('atomicRefreshConflict').useValue('candidate'))
            .addExport('atomicRefreshConflict');
        try {
            Di.replaceModule(originalModule.getToken(), replacement);
            Assert.fail('Expected InvalidProviderException for a conflicting global replacement.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('atomicRefreshConflict'));
        }

        // Assert: Both previously committed definitions and global bindings remain intact.
        Assert.isFalse(originalRef.getModule().hasProvider('atomicRefreshConflict'));
        Assert.areEqual('stable', consumerRef.get('atomicRefreshValue'));
        Assert.areEqual('owner', consumerRef.get('atomicRefreshConflict'));
    }

    @IsTest
    static void should_update_global_export_when_global_provider_is_replaced() {
        // Arrange: A global module exports a provider, and a consumer resolves it through the global fallback.
        Di.DynamicModule dynGlobal = new Di.DynamicModule('ReplaceableGlobalDynamic');
        dynGlobal.addProvider(dynGlobal.provide('globalReplaceValue').useValue('initial'))
            .addExport('globalReplaceValue');
        Di.addGlobalModule(dynGlobal);
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);
        Assert.areEqual('initial', consumerRef.get('globalReplaceValue'), 'Pre-condition: global export is visible.');

        // Act: Replace the provider on the owning global module.
        Di.replaceProvider(dynGlobal.getToken(), dynGlobal.provide('globalReplaceValue').useValue('updated'));

        // Assert: Global fallback should resolve the current owner provider, not a stale published binding.
        Assert.areEqual(
            'updated',
            Di.getModuleRef(EmptyModule.class).get('globalReplaceValue'),
            'Global fallback should behave like an implicit import and observe provider replacement.'
        );
    }

    @IsTest
    static void should_reuse_global_binding_index_when_graph_is_unchanged() {
        // Arrange: A global re-export exposes a traversal counter for binding-index construction.
        GlobalBindingIndexCountingModule globalModule = new GlobalBindingIndexCountingModule();
        Di.addGlobalModule(globalModule);
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);

        // Act: Resolve the same global binding twice without mutating the graph.
        Assert.areEqual('shared', consumerRef.get('sharedGlobalReexportVal'));
        Integer traversalsAfterFirstLookup = globalModule.bindingTraversalCount;
        Assert.areEqual('shared', consumerRef.get('sharedGlobalReexportVal'));

        // Assert: A current global binding index should be reused instead of rebuilding per lookup.
        Assert.areEqual(
            traversalsAfterFirstLookup,
            globalModule.bindingTraversalCount,
            'Repeated global lookups should reuse the current context-owned binding index.'
        );

        // Act: Mutate the local owner behind the global re-export and resolve again.
        Integer traversalsBeforeMutation = globalModule.bindingTraversalCount;
        Di.replaceProvider(
            SharedGlobalReexportCommonModule.class,
            globalModule.provide('sharedGlobalReexportVal').useValue('updated')
        );
        consumerRef = Di.getModuleRef(EmptyModule.class);
        Assert.areEqual('updated', consumerRef.get('sharedGlobalReexportVal'));
        Integer traversalsAfterMutation = globalModule.bindingTraversalCount;
        Assert.areEqual(
            traversalsBeforeMutation,
            traversalsAfterMutation,
            'Global index invalidation should reuse committed re-export definitions.'
        );

        // Assert: The rebuilt index is also reused until another graph mutation occurs.
        Assert.areEqual('updated', consumerRef.get('sharedGlobalReexportVal'));
        Assert.areEqual(
            traversalsAfterMutation,
            globalModule.bindingTraversalCount,
            'The rebuilt global binding index should remain current until the graph changes again.'
        );
    }

    @IsTest
    static void should_require_fresh_ref_when_dynamic_module_is_replaced() {
        // Arrange: A dynamic module is registered, initially without a specific provider.
        Di.DynamicModule dyn = new Di.DynamicModule('RefreshableModule');
        Di.ModuleRef ref = Di.addModule(dyn);
        try {
            ref.get('newValue');
            Assert.fail('Provider should not exist before the module is replaced.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Could not find "newValue" provider'),
                'The initial exception message should be correct.'
            );
        }

        // Act: A new same-token module definition replaces the original.
        Di.DynamicModule replacement = new Di.DynamicModule(dyn.getToken());
        replacement.addProvider(replacement.provide('newValue').useValue('replaced')).addExport('newValue');
        Di.replaceModule(dyn.getToken(), replacement);

        // Assert: The held reference is stale; a fresh handle resolves the replacement.
        try {
            ref.get('newValue');
            Assert.fail('Expected replacement to invalidate the held module ref.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        Assert.areEqual(
            'replaced',
            Di.getModuleRef(dyn.getToken()).get('newValue'),
            'Provider should be available through a fresh handle after replacement.'
        );
    }

    @IsTest
    static void should_evaluate_providers_as_equal_when_tokens_match() {
        // Arrange: Create two different provider types with the same token, and one with a different token.
        Di.DynamicModule module = new Di.DynamicModule('ProviderEquality');
        Di.Provider providerA1 = module.provide('tokenA').useValue('value');
        Di.Provider providerA2 = module.provide('tokenA').useClass('SomeType');
        Di.Provider providerB = module.provide('tokenB').useValue('value');

        // Act: Check equality based on the token.
        // Assert: Verify the expected outcome.
        Assert.isTrue(
            providerA1.equals(providerA2),
            'Providers with the same token should be equal, regardless of type.'
        );
        Assert.isFalse(providerA1.equals(providerB), 'Providers with different tokens should not be equal.');
        Assert.isFalse(
            providerA1.equals('some string'),
            'Provider should not be equal to an object of a different type.'
        );
        Assert.isFalse(providerA1.equals(null), 'Provider should not be equal to null.');
    }
    // </editor-fold>

    // <editor-fold desc="Errors and Context Isolation">
    @IsTest
    static void should_throw_exception_when_instantiating_abstract_class() {
        // Arrange: A module attempts to provide an abstract class.
        Di.ModuleRef ref = Di.getModuleRef(AbstractProviderModule.class);

        // Act: An attempt is made to get the provider.
        try {
            ref.get('abs');
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            // Assert: The correct exception is thrown with a helpful message.
            Assert.isTrue(
                ex.getMessage().contains('public no-argument constructor'),
                'Error message should detail instantiation failure.'
            );
        }
    }

    @IsTest
    static void should_call_inject_when_provider_is_injectable() {
        // Arrange: A module provides a class that implements the Injectable interface.
        Di.ModuleRef ref = Di.getModuleRef(InjectableModule.class);

        // Act: The provider is requested, which triggers its instantiation.
        FooInjectable instance = (FooInjectable) ref.get(FooInjectable.class);

        // Assert: The inject() method on the class was called.
        Assert.isTrue(instance.wasInjected, 'The inject() method should be called after instantiation.');
    }

    @IsTest
    static void should_inject_dependencies_when_container_inject_is_called() {
        // Arrange
        // We need a container. We can use any valid module ref.
        Di.ModuleRef ref = Di.getModuleRef(InjectableModule.class);
        FooInjectable instance = new FooInjectable();

        // Pre-assert: inject has not been called
        Assert.isFalse(instance.wasInjected, 'Pre-condition: inject() should not have been called yet.');

        // Act
        Object result = ref.inject(instance);

        // Assert
        Assert.isTrue(instance.wasInjected, 'The inject() method should be called after manual injection.');
        Assert.areEqual(instance, result, 'inject() should return the injected instance.');
    }

    @IsTest
    static void should_inject_without_restarting_resolution_when_factory_calls_container_inject() {
        // Arrange: A factory manually injects an object while its provider resolution is already active.
        Di.ModuleRef ref = Di.getModuleRef(NestedInjectModule.class);

        // Act: Resolve the factory provider.
        FooInjectable instance = (FooInjectable) ref.get('NestedInject');

        // Assert: Nested inject() uses the active resolution context and still autowires the instance.
        Assert.isTrue(instance.wasInjected, 'Nested inject() should autowire inside the active resolution.');
    }

    @IsTest
    static void should_throw_exception_when_manual_injection_targets_non_injectable() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(InjectableModule.class);
        Object nonInjectable = new TestServiceImpl(); // Implements TestService, NOT Injectable

        // Act: Execute the behavior under test.
        try {
            ref.inject(nonInjectable);
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('implement the Di.Injectable interface'),
                'Exception message should warn about missing interface.'
            );
        }
    }

    @IsTest
    static void should_clear_registries_and_caches_when_di_is_cleared() {
        // Arrange: A local module is added and a global module is loaded and verified.
        Di.addModule(new ValueModule());
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );
        Assert.areEqual(
            'helloFromCmt',
            Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal'),
            'Pre-condition: global provider must be available.'
        );

        // Act: The clear() method is called.
        Di.clear();
        Di.mockModules(new List<DI_Module__mdt>());

        // Assert: After clearing, getting the global provider fails.
        Di.ModuleRef ref = Di.getModuleRef(EmptyModule.class);
        try {
            ref.get('cmtGlobalVal');
            Assert.fail('Global provider should not exist after clear.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Could not find "cmtGlobalVal" provider'),
                'Global cache should be empty.'
            );
        }
    }

    @IsTest
    static void should_reject_resolution_when_module_ref_belongs_to_cleared_context() {
        // Arrange: A context has issued root and scoped handles for a registered module.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef staleRef = context.addModule(new ValueModule());
        Di.ScopeRef staleScope = staleRef.createScope();
        Assert.areEqual('hello', staleRef.get('val'), 'Pre-condition: root handle should resolve before clear.');
        Assert.areEqual('hello', staleScope.get('val'), 'Pre-condition: scoped handle should resolve before clear.');

        // Act: Clearing the context invalidates every handle it previously issued.
        context.clear();

        // Assert: Previously issued root and scoped handles reject resolution.
        try {
            staleRef.get('val');
            Assert.fail('Expected stale ModuleRef resolution to be rejected after context clear.');
        } catch (Di.DiException ex) {
            Assert.isTrue(
                ex.getMessage().contains('application context was cleared'),
                'Error should explain that the ModuleRef belongs to a cleared context generation.'
            );
        }

        try {
            staleScope.get('val');
            Assert.fail('Expected stale ScopeRef resolution to be rejected after context clear.');
        } catch (Di.DiException ex) {
            Assert.isTrue(
                ex.getMessage().contains('application context was cleared'),
                'Error should explain that the ScopeRef belongs to a cleared context generation.'
            );
        }

        try {
            staleRef.getModule();
            Assert.fail('Expected stale ModuleRef module access to be rejected after context clear.');
        } catch (Di.DiException ex) {
            Assert.isTrue(
                ex.getMessage().contains('application context was cleared'),
                'Error should explain that the ModuleRef cannot expose a module from a cleared generation.'
            );
        }

        // Assert: The ApplicationContext itself remains reusable and issues valid handles for its new generation.
        Di.ModuleRef currentRef = context.addModule(new ValueModule());
        Assert.areEqual('hello', currentRef.get('val'), 'A newly issued handle should resolve after context reuse.');
    }

    @IsTest
    static void should_reject_provider_lookup_via_module_from_cleared_context() {
        // Arrange: A caller retains the registered module instance independently of its ModuleRef.
        Di.ApplicationContext context = newTestContext();
        ValueModule module = new ValueModule();
        context.addModule(module);
        Assert.areEqual(
            'val',
            module.getProvider('val').getToken(),
            'Pre-condition: registered module should resolve providers.'
        );

        // Act: Clearing the owner context makes the retained module instance stale until it is explicitly re-registered.
        context.clear();

        // Assert: Provider lookup cannot fall back to and mutate the default application context.
        try {
            module.getProvider('val');
            Assert.fail('Expected provider lookup through a module from a cleared context to be rejected.');
        } catch (Di.DiException ex) {
            Assert.isTrue(
                ex.getMessage().contains('application context was cleared'),
                'Error should explain that the retained module belongs to a cleared context generation.'
            );
        }
    }

    @IsTest
    static void should_reject_held_module_ref_after_external_module_replacement() {
        // Arrange: A caller holds a root handle before replacing the module definition.
        Di.ApplicationContext context = newTestContext();
        SingleModule module = new SingleModule();
        Di.ModuleRef heldRef = context.addModule(module);
        Assert.isTrue(heldRef.get('TestService') instanceof TestServiceImpl, 'Pre-condition: original ref resolves.');
        Di.DynamicModule replacement = new Di.DynamicModule(module.getToken());
        replacement.addProvider(replacement.provide('TestService').useValue('replaced')).addExport('TestService');

        // Act: Replacing the module is an external cold mutation.
        context.replaceModule(module.getToken(), replacement);

        // Assert: The previously issued handle is stale and the caller must reacquire.
        try {
            heldRef.get('TestService');
            Assert.fail('Expected the held ModuleRef to be invalidated by external module replacement.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(
                ex.getMessage().contains('application context'),
                'Error should explain that the held reference belongs to an old context generation.'
            );
        }
        Assert.areEqual(
            'replaced',
            context.getModuleRef(module.getToken()).get('TestService'),
            'A freshly issued handle should resolve the replacement module.'
        );
    }

    @IsTest
    static void should_reject_held_scope_ref_after_external_module_replacement() {
        // Arrange: A scoped handle resolves against the original module definition.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef ref = context.getModuleRef(ScopeRefIntegrityModule.class);
        Di.ScopeRef heldScope = ref.createScope();
        Assert.areEqual('A', heldScope.resolve('ScopedService'), 'Pre-condition: scope resolves original value.');

        // Act: Replacing the owner module is an external cold mutation.
        context.replaceModule(ScopeRefIntegrityModule.class, new ScopeRefIntegrityReplacementModule());

        // Assert: The held scope does not self-heal across the mutation boundary.
        try {
            heldScope.resolve('ScopedService');
            Assert.fail('Expected the held ScopeRef to be invalidated by external module replacement.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(
                ex.getMessage().contains('application context'),
                'Error should explain that the held scope belongs to an old context generation.'
            );
        }
        Assert.areEqual(
            'B',
            context.getModuleRef(ScopeRefIntegrityModule.class).createScope().resolve('ScopedService'),
            'A freshly issued scope should resolve the replacement value.'
        );
    }

    @IsTest
    static void should_reject_held_refs_when_public_get_module_ref_adds_module_after_resolution() {
        // Arrange: A root handle has already performed a top-level resolution, opening the context.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef heldRef = context.addModule(new SingleModule());
        Assert.isTrue(heldRef.get('TestService') instanceof TestServiceImpl, 'Pre-condition: context is open.');

        // Act: Publicly requesting a missing module after the context is open is an external cold mutation.
        Di.ModuleRef addedRef = context.getModuleRef(ValueModule.class);

        // Assert: The old handle is stale, while freshly issued handles remain valid.
        try {
            heldRef.get('TestService');
            Assert.fail('Expected the held ModuleRef to be invalidated by post-open module addition.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(
                ex.getMessage().contains('application context'),
                'Error should explain that public post-open module addition invalidates old handles.'
            );
        }
        Assert.areEqual('hello', addedRef.get('val'), 'The newly added module handle should be valid.');
        Assert.isTrue(
            context.getModuleRef(SingleModule.class).get('TestService') instanceof TestServiceImpl,
            'A freshly issued handle for the original module should remain valid.'
        );
    }

    @IsTest
    static void should_keep_module_refs_valid_when_modules_are_added_before_resolution() {
        // Arrange: Multiple modules are added during the setup phase before any top-level resolution.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef singleRef = context.addModule(new SingleModule());
        Di.ModuleRef valueRef = context.addModule(new ValueModule());

        // Act and Assert: Setup-time additions do not invalidate handles issued before the context opens.
        Assert.isTrue(singleRef.get('TestService') instanceof TestServiceImpl);
        Assert.areEqual('hello', valueRef.get('val'));
    }

    @IsTest
    static void should_keep_module_ref_valid_when_lazy_import_is_discovered_during_resolution() {
        // Arrange: The consumer is registered, but its imported ValueModule is not registered yet.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef consumerRef = context.addModule(new LazyConsumerModule());

        // Act: Resolving the consumer lazily materializes its import inside the active resolution.
        Object first = consumerRef.get('dependentVal');
        Object second = consumerRef.get('dependentVal');

        // Assert: Internal lazy discovery updates indexes only and does not invalidate the active handle.
        Assert.areEqual('depends on hello', first);
        Assert.areEqual(first, second, 'The same handle should remain valid after lazy import discovery.');
    }

    @IsTest
    static void should_isolate_local_modules_when_application_contexts_are_distinct() {
        // Arrange: Two application contexts register the same module token independently.
        Di.ApplicationContext leftContext = newTestContext();
        Di.ApplicationContext rightContext = newTestContext();
        leftContext.addModule(new SingleModule());
        rightContext.addModule(new SingleModule());

        // Act: Only the left context replaces the module.
        leftContext.replaceModule(SingleModule.class, new ReplacementModule());

        // Assert: The replacement is visible only in the left context.
        Assert.areEqual(
            'replaced',
            leftContext.getModuleRef(SingleModule.class).get('TestService'),
            'Left context should see its replacement.'
        );
        Assert.isTrue(
            rightContext.getModuleRef(SingleModule.class).get('TestService') instanceof TestServiceImpl,
            'Right context should keep its own original module.'
        );
    }

    @IsTest
    static void should_reject_module_instance_when_registered_in_multiple_contexts() {
        // Arrange: The same module instance is already owned by the left context.
        Di.ApplicationContext leftContext = newTestContext();
        Di.ApplicationContext rightContext = newTestContext();
        LazyConsumerModule consumer = new LazyConsumerModule();
        Di.ModuleRef leftRef = leftContext.addModule(consumer);
        Assert.areEqual(
            'depends on hello',
            leftRef.resolve('dependentVal'),
            'Pre-condition: left context should own the consumer module.'
        );

        // Act: A second context must not steal the module instance.
        try {
            rightContext.addModule(consumer);
            Assert.fail('Expected InvalidModuleException for a module instance already bound to another context.');
        } catch (Di.InvalidModuleException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('already registered in another application context'),
                'Error should explain the context ownership violation.'
            );
        }

        Assert.areEqual(
            'depends on hello',
            leftRef.resolve('dependentVal'),
            'Original context binding should remain intact.'
        );
    }

    @IsTest
    static void should_isolate_global_metadata_mocks_when_contexts_are_distinct() {
        // Arrange: Only the left context has a mocked global module.
        Di.ApplicationContext leftContext = newTestContext();
        Di.ApplicationContext rightContext = newTestContext();
        leftContext.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );

        // Act: The left context can resolve the mocked global provider.
        Assert.areEqual(
            'helloFromCmt',
            leftContext.getModuleRef(EmptyModule.class).get('cmtGlobalVal'),
            'Left context should load its mocked global module.'
        );

        // Act: The right context remains isolated from the left context's mock.
        try {
            rightContext.getModuleRef(EmptyModule.class).get('cmtGlobalVal');
            Assert.fail('Expected UnknownProviderException in the context without mocked globals.');
        } catch (Di.UnknownProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(
                ex.getMessage().contains('Could not find "cmtGlobalVal" provider'),
                'Right context should not see globals loaded by the left context.'
            );
        }
    }

    @IsTest
    static void should_resolve_imports_when_application_context_owns_consumer() {
        // Arrange: The default context and an application context register different modules under ValueModule's token.
        Di.clear();
        Di.mockModules(new List<DI_Module__mdt>());
        Di.mockProviders(new Map<String, DI_Provider__mdt>());
        Di.addModule(new ValueModule());
        Di.ApplicationContext context = newTestContext();
        Di.DynamicModule contextValueModule = new Di.DynamicModule(ValueModule.class.getName());
        contextValueModule.addProvider(contextValueModule.provide('val').useValue('context-replaced'));
        contextValueModule.addExport('val');
        context.addModule(contextValueModule);

        // Act: The same consumer module is resolved through each context.
        Object defaultValue = Di.getModuleRef(LazyConsumerModule.class).get('dependentVal');
        Object contextValue = context.getModuleRef(LazyConsumerModule.class).get('dependentVal');

        // Assert: Imports use the context that owns the consuming module, not the static default context.
        Assert.areEqual('depends on hello', defaultValue, 'Default context should use its own ValueModule.');
        Assert.areEqual(
            'depends on context-replaced',
            contextValue,
            'ApplicationContext imports should resolve inside that same context.'
        );
    }

    @IsTest
    static void should_update_providers_when_module_is_replaced() {
        // Arrange: An initial module is registered.
        Di.addModule(new SingleModule());
        Assert.isTrue(Di.getModuleRef(SingleModule.class).get('TestService') instanceof TestServiceImpl);

        // Act: The module is replaced with a new implementation.
        Di.replaceModule(SingleModule.class, new ReplacementModule());
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);

        // Assert: Getting the provider returns the instance from the new module.
        Assert.areEqual('replaced', ref.get('TestService'), 'Provider should come from the replacement module.');
    }

    @IsTest
    static void should_reject_existing_module_ref_when_local_module_is_replaced() {
        // Arrange: A local module ref is held before the module is replaced.
        SingleModule module = new SingleModule();
        Di.ModuleRef ref = Di.addModule(module);
        Assert.isTrue(ref.get('TestService') instanceof TestServiceImpl);
        Di.DynamicModule replacement = new Di.DynamicModule(module.getToken());
        replacement.addProvider(replacement.provide('TestService').useValue('replaced')).addExport('TestService');

        // Act: The module is replaced while the old ref is still in use.
        Di.replaceModule(module.getToken(), replacement);

        // Assert: The old ref is stale and a fresh ref serves replacement providers.
        try {
            ref.get('TestService');
            Assert.fail('Expected local module replacement to invalidate the existing ref.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        Assert.areEqual(
            'replaced',
            Di.getModuleRef(module.getToken()).get('TestService'),
            'Fresh refs should serve replacement providers.'
        );
    }

    @IsTest
    static void should_issue_fresh_singleton_runtime_when_module_is_replaced() {
        // Arrange: Hold the original ref before replacing its module with another singleton provider definition.
        SingleModule module = new SingleModule();
        Di.ModuleRef heldRef = Di.addModule(module);
        Di.DynamicModule replacement = new Di.DynamicModule(module.getToken());
        replacement.addProvider(replacement.provide('TestService').useClass(TestServiceImpl.class));

        // Act: Resolve through a fresh registry ref after replacement.
        Di.replaceModule(module.getToken(), replacement);
        Di.ModuleRef registeredRef = Di.getModuleRef(module.getToken());
        Object registeredInstance = registeredRef.get('TestService');

        // Assert: The old ref is stale and the fresh ref owns a stable singleton runtime.
        try {
            heldRef.get('TestService');
            Assert.fail('Expected module replacement to invalidate the held ref.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        Assert.areEqual(
            registeredInstance,
            registeredRef.get('TestService'),
            'Fresh replacement refs should cache singleton providers in their own current runtime.'
        );
    }

    @IsTest
    static void should_clear_dependent_singleton_caches_when_local_module_is_replaced() {
        // Arrange: A consumer singleton is cached from an imported local module value.
        ValueModule valueModule = new ValueModule();
        Di.addModule(valueModule);
        Di.ModuleRef consumerRef = Di.getModuleRef(LazyConsumerModule.class);
        Assert.areEqual('depends on hello', consumerRef.get('dependentVal'), 'Pre-condition: value should be cached.');
        Di.DynamicModule replacement = new Di.DynamicModule(valueModule.getToken());
        replacement.addProvider(replacement.provide('val').useValue('replaced')).addExport('val');

        // Act: The imported local module is replaced.
        Di.replaceModule(valueModule.getToken(), replacement);

        // Assert: The old consumer handle is stale; a fresh one observes the replacement.
        try {
            consumerRef.get('dependentVal');
            Assert.fail('Expected local module replacement to invalidate dependent consumer refs.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        Assert.areEqual(
            'depends on replaced',
            Di.getModuleRef(LazyConsumerModule.class).get('dependentVal'),
            'Dependent singleton providers should be rebuilt after local module replacement.'
        );
    }

    @IsTest
    static void should_reject_provider_scope_mutation_after_registration() {
        // Arrange: A provider is committed into a registered module and cached as a singleton.
        Di.ClassProvider provider = new Di.ClassProvider('immutableScope', TestServiceImpl.class);
        Di.DynamicModule module = new Di.DynamicModule('ImmutableProviderModule');
        module.addProvider(provider).addExport('immutableScope');
        Di.ModuleRef ref = Di.addModule(module);
        Object original = ref.get('immutableScope');

        // Act: Mutating the public provider object must not mutate the committed graph.
        try {
            provider.scope(Di.Scope.PROTOTYPE);
            Assert.fail('Expected committed provider scope mutation to be rejected.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('committed'), 'Exception should explain provider immutability.');
        }

        // Assert: The committed provider remains a singleton with its original cached instance.
        Assert.areEqual(Di.Scope.SINGLETON, module.getProvider('immutableScope').getScope());
        Assert.areEqual(original, ref.get('immutableScope'));
    }

    @IsTest
    static void should_release_replaced_module_instance_for_another_context() {
        // Arrange: One context owns a local module instance.
        Di.ApplicationContext leftContext = Di.createContext();
        Di.ApplicationContext rightContext = Di.createContext();
        Di.DynamicModule original = new Di.DynamicModule('ReleasedReplacementModule');
        original.addProvider(original.provide('replacementOwnership').useValue('original'));
        leftContext.addModule(original);
        Di.DynamicModule replacement = new Di.DynamicModule(original.getToken());
        replacement.addProvider(replacement.provide('replacementOwnership').useValue('replacement'));

        // Act: The left context commits a distinct replacement, then the original is registered elsewhere.
        leftContext.replaceModule(original.getToken(), replacement);
        Di.ModuleRef rightRef = rightContext.addModule(original);

        // Assert: Successful replacement releases only the superseded module instance.
        Assert.areEqual('replacement', leftContext.getModuleRef(original.getToken()).get('replacementOwnership'));
        Assert.areEqual('original', rightRef.get('replacementOwnership'));
    }

    @IsTest
    static void should_throw_framework_exception_when_resolution_token_is_null() {
        // Arrange: A valid root module reference receives invalid String and Type tokens.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);

        // Act and Assert: Every public get/resolve overload rejects null before path mutation.
        Integer rejectedCallCount = 0;
        try {
            ref.get((String) null);
            Assert.fail('Expected get(String) to reject a null provider token.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('cannot be null'));
            rejectedCallCount++;
        }
        try {
            ref.resolve((String) null);
            Assert.fail('Expected resolve(String) to reject a null provider token.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('cannot be null'));
            rejectedCallCount++;
        }
        try {
            ref.get((Type) null);
            Assert.fail('Expected get(Type) to reject a null provider token.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('cannot be null'));
            rejectedCallCount++;
        }
        try {
            ref.resolve((Type) null);
            Assert.fail('Expected resolve(Type) to reject a null provider token.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('cannot be null'));
            rejectedCallCount++;
        }
        Assert.areEqual(4, rejectedCallCount, 'Every null-token overload should reject the call consistently.');
    }

    @IsTest
    static void should_reject_null_provider_scope() {
        // Arrange: A standalone provider has the valid default singleton scope.
        Di.Provider provider = new Di.ClassProvider('nullScope', TestServiceImpl.class);

        // Act: Null is not a valid provider lifetime.
        try {
            provider.scope(null);
            Assert.fail('Expected null provider scope to be rejected.');
        } catch (Di.InvalidScopeException ex) {
            Assert.isTrue(
                ex.getMessage().contains('cannot be null'),
                'Exception should identify the invalid null scope.'
            );
        }

        // Assert: Failed configuration leaves the original scope unchanged.
        Assert.areEqual(Di.Scope.SINGLETON, provider.getScope());
    }

    @IsTest
    static void should_reject_conflicting_programmatic_module_visibility() {
        // Arrange: A canonical module token is committed to the local registry.
        Di.DynamicModule localModule = new Di.DynamicModule('RegisteredVisibilityModule');
        localModule.addProvider(localModule.provide('registeredLocal').useValue('local'));
        Di.ModuleRef ref = Di.addModule(localModule);

        // Act: A global registration attempts to claim the same canonical token.
        try {
            Di.addGlobalModule(new Di.DynamicModule(localModule.getToken()));
            Assert.fail('Expected conflicting module visibility to be rejected.');
        } catch (Di.InvalidModuleException ex) {
            // Assert: Visibility is registration-owned and unique per token.
            Assert.isTrue(ex.getMessage().contains('already registered as local'));
        }
        Assert.areEqual('local', ref.get('registeredLocal'));
    }

    @IsTest
    static void should_construct_guard_exception_only_when_validation_fails() {
        // Arrange: Capture the lazy-guard counter before a normal hot-path resolution.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);
        Integer initialCreationCount = Di.guardExceptionCreationCount;

        // Act: Successful guard checks should not construct discarded exception objects.
        ref.get('TestService');
        ref.get('TestService');

        // Assert: Happy-path resolution allocates no guard exceptions.
        Assert.areEqual(initialCreationCount, Di.guardExceptionCreationCount);

        // Act: A failing guard constructs exactly the exception that is thrown.
        try {
            ref.get((String) null);
            Assert.fail('Expected a null provider token to fail validation.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('cannot be null'));
        }

        // Assert: Exception construction is lazy and failure-driven.
        Assert.areEqual(initialCreationCount + 1, Di.guardExceptionCreationCount);
    }

    @IsTest
    static void should_clear_dependent_singleton_caches_when_provider_is_replaced() {
        // Arrange: A consumer singleton captures an imported owner value.
        ValueModule valueModule = new ValueModule();
        Di.addModule(valueModule);
        Di.ModuleRef consumerRef = Di.getModuleRef(LazyConsumerModule.class);
        Assert.areEqual('depends on hello', consumerRef.get('dependentVal'));

        // Act: Replace only the imported provider through the owning application context.
        Di.replaceProvider(ValueModule.class, valueModule.provide('val').useValue('provider-replaced'));

        // Assert: The old consumer handle is stale and a fresh one observes the replacement.
        try {
            consumerRef.get('dependentVal');
            Assert.fail('Expected provider replacement to invalidate the held consumer ref.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        Assert.areEqual(
            'depends on provider-replaced',
            Di.getModuleRef(LazyConsumerModule.class).get('dependentVal'),
            'Dependent singleton providers should rebuild after provider replacement.'
        );
    }

    @IsTest
    static void should_reject_module_replacement_when_token_is_mismatched() {
        // Arrange: A replacement module is configured with a token that does not match the target module.
        SingleModule module = new SingleModule();
        Di.ModuleRef ref = Di.addModule(module);
        Di.DynamicModule replacement = new Di.DynamicModule('DifferentModuleToken');
        replacement.addProvider(replacement.provide('TestService').useValue('replaced')).addExport('TestService');

        // Act: The replacement is rejected before it can be registered under the wrong key.
        try {
            Di.replaceModule(module.getToken(), replacement);
            Assert.fail('Expected InvalidModuleException for a mismatched replacement token.');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(
                ex.getMessage().contains('must match'),
                'Error should explain that replacement module tokens must match.'
            );
        }

        // Assert: The failed replacement did not disturb the original module.
        Assert.isTrue(ref.get('TestService') instanceof TestServiceImpl, 'Original module should remain active.');
    }

    @IsTest
    static void should_preserve_registration_visibility_when_module_is_replaced() {
        // Arrange: A global module is registered independently of its declaration.
        Di.DynamicModule module = new Di.DynamicModule('VisibilityReplacementModule');
        module.addProvider(module.provide('visible').useValue('before')).addExport('visible');
        Di.addGlobalModule(module);
        Di.DynamicModule replacement = new Di.DynamicModule(module.getToken());
        replacement.addProvider(replacement.provide('visible').useValue('after')).addExport('visible');

        // Act: Replacement supplies only a definition; the registration retains global visibility.
        Di.replaceModule(module.getToken(), replacement);

        // Assert
        Assert.areEqual('after', Di.getModuleRef(EmptyModule.class).get('visible'));
    }

    @IsTest
    static void should_update_global_providers_when_global_module_is_replaced() {
        // Arrange: A global module is loaded via CMT mock and its provider is verified.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = true,
                    IsGlobal__c = true
                )
            }
        );
        Assert.areEqual('helloFromCmt', Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal'));
        Di.DynamicModule newGlobalModule = new Di.DynamicModule(CmtGlobalModule.class.getName());
        newGlobalModule.addProvider(newGlobalModule.provide('cmtGlobalVal').useValue('new-value'));
        newGlobalModule.addExport('cmtGlobalVal');

        // Act: The global module is replaced.
        Di.replaceModule(CmtGlobalModule.class.getName(), newGlobalModule);

        // Assert: The global provider now returns the value from the new module.
        Assert.areEqual('new-value', Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal'));
    }

    @IsTest
    static void should_rollback_global_module_replacement_when_exports_conflict() {
        // Arrange: Two global modules own distinct exports.
        Di.DynamicModule original = new Di.DynamicModule('ReplacementRollbackGlobal');
        original.addProvider(original.provide('replacementRollbackValue').useValue('original'))
            .addExport('replacementRollbackValue');
        Di.addGlobalModule(original);
        Di.DynamicModule conflictOwner = new Di.DynamicModule('ReplacementConflictGlobal');
        conflictOwner.addProvider(conflictOwner.provide('replacementConflictValue').useValue('owner'))
            .addExport('replacementConflictValue');
        Di.addGlobalModule(conflictOwner);

        // Act: A same-token replacement attempts to claim the other global module's export.
        Di.DynamicModule replacement = new Di.DynamicModule(original.getToken());
        replacement.addProvider(replacement.provide('replacementRollbackValue').useValue('replacement'))
            .addProvider(replacement.provide('replacementConflictValue').useValue('conflict'))
            .addExport('replacementRollbackValue')
            .addExport('replacementConflictValue');
        try {
            Di.replaceModule(original.getToken(), replacement);
            Assert.fail('Expected InvalidProviderException for a conflicting global replacement.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains('replacementConflictValue'),
                'Exception should identify the conflicting global export.'
            );
        }

        // Assert: The rejected replacement leaves both original global bindings intact.
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);
        Assert.areEqual('original', consumerRef.get('replacementRollbackValue'));
        Assert.areEqual('owner', consumerRef.get('replacementConflictValue'));
        Assert.isFalse(
            replacement.hasProvider('replacementRollbackValue'),
            'A rejected replacement instance must not retain its candidate definition.'
        );
    }

    @IsTest
    static void should_ignore_global_module_when_metadata_is_inactive() {
        // Arrange: A global module is defined as inactive in a mocked CMT record.
        Di.mockModules(
            new List<DI_Module__mdt>{
                new DI_Module__mdt(
                    ModuleClass__c = CmtGlobalModule.class.getName(),
                    IsActive__c = false,
                    IsGlobal__c = true
                )
            }
        );
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);

        // Act: An attempt to get the provider from the inactive module throws an exception.
        try {
            consumerRef.get('cmtGlobalVal');
            Assert.fail('Expected provider from inactive global module to be unavailable.');
        } catch (Di.UnknownProviderException ex) {
            // Assert: Verify the expected outcome.
            Assert.isTrue(ex.getMessage().contains('Could not find "cmtGlobalVal" provider'));
        }
    }

    @IsTest
    static void should_throw_exception_when_creating_abstract_module() {
        // Arrange: An abstract module class that cannot be instantiated.
        // Act: Attempting to get a ref to this module should fail.
        try {
            Di.getModuleRef(AbstractTestModule.class);
            Assert.fail('Expected InvalidModuleException was not thrown.');
        } catch (Di.InvalidModuleException e) {
            // Assert: Verify the expected outcome.
            // This confirms the new try-catch block in Di.create() is working.
            Assert.isTrue(
                e.getMessage().contains('has a public no-argument constructor'),
                'Exception message should indicate an instantiation failure.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_when_resolving_existing_provider_directly() {
        // Arrange: Get a module that contains an ExistingProvider.
        Di.ModuleRef ref = Di.getModuleRef(ExistingProviderModule.class);
        Di.Module module = ref.getModule();
        Di.Provider provider = module.getProvider('MyAlias');

        // Act: Directly calling resolve() on an ExistingProvider should be disallowed.
        try {
            provider.resolve(ref, null);
            Assert.fail('Expected InvalidProviderException was not thrown.');
        } catch (Di.InvalidProviderException e) {
            // Assert: Verify the expected outcome.
            // This confirms the defensive exception in ExistingProvider.resolve() is working.
            Assert.isTrue(
                e.getMessage().contains('This operation is not supported'),
                'Exception message should indicate the operation is invalid for this provider type.'
            );
        }
    }
    // </editor-fold>

    // <editor-fold desc="Integration Scenarios">
    @IsTest
    static void should_process_order_when_services_are_injected() {
        // Arrange: Register the main OrderProcessingModule, which internally imports all its dependencies.
        // This simulates a real application where you only bootstrap the top-level module.
        Di.ModuleRef ref = Di.getModuleRef(OrderProcessingModule.class);
        OrderService orderService = (OrderService) ref.get(OrderService.class);

        // Act: Execute the business logic that relies on multiple injected services.
        Boolean wasProcessed = orderService.processOrder('order-123', 99.99);

        // Assert: Verify that the high-level operation succeeded and that each injected service performed its task.
        Assert.isTrue(wasProcessed, 'Order processing should complete successfully.');
        Assert.isTrue(orderService.paymentService.wasCalled(), 'PaymentService should have been called.');
        Assert.isTrue(orderService.shippingService.wasShipped(), 'ShippingService should have been called.');
        Assert.isTrue(orderService.notificationService.wasSent(), 'NotificationService should have been called.');
    }

    @IsTest
    static void should_update_feature_flag_when_dynamic_module_is_replaced() {
        // Arrange: A dynamic module for feature flags is registered, initially empty.
        Di.DynamicModule featureFlagsModule = new Di.DynamicModule('FeatureFlags');
        Di.addModule(featureFlagsModule);
        Di.ModuleRef appRef = Di.getModuleRef(AppModule.class);
        UserExperienceService uxService = (UserExperienceService) appRef.get(UserExperienceService.class);
        Assert.isFalse(uxService.isNewCheckoutEnabled(), 'Pre-condition: New checkout should be disabled initially.');

        // Act: A new same-token module definition enables the feature flag.
        Di.DynamicModule replacement = new Di.DynamicModule(featureFlagsModule.getToken());
        replacement.addProvider(replacement.provide('EnableNewCheckout').useValue(true));
        replacement.addExport('EnableNewCheckout');
        Di.replaceModule(featureFlagsModule.getToken(), replacement);

        // Assert: The old app handle is stale and a fresh one reflects the enabled feature flag.
        try {
            appRef.get(UserExperienceService.class);
            Assert.fail('Expected feature-flag replacement to invalidate the held app ref.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
        UserExperienceService newUxService = (UserExperienceService) Di.getModuleRef(AppModule.class)
            .get(UserExperienceService.class);
        Assert.isTrue(
            newUxService.isNewCheckoutEnabled(),
            'New checkout should be enabled after replacing the feature flag module.'
        );
    }

    @IsTest
    static void should_provide_short_alias_when_service_name_is_long() {
        // Arrange: The main application module is registered, which uses an alias internally.
        Di.ModuleRef ref = Di.getModuleRef(AppWithAliasModule.class);
        EmailService emailService = (EmailService) ref.get(EmailService.class);

        // Act: The high-level service method is called.
        String result = emailService.sendWelcomeEmail('test@example.com');

        // Assert: The result confirms that the aliased dependency was correctly injected and used.
        Assert.areEqual('Email sent via Mandrill to test@example.com', result);
    }

    @IsTest
    static void should_isolate_state_when_trigger_handlers_use_distinct_scopes() {
        // Arrange: Register the module for our simulation.
        Di.ModuleRef rootContainer = Di.getModuleRef(RecordProcessorModule.class);

        // Act: Record 1
        // --- Start Unit of Work 1 ---
        Di.ScopeRef scope1 = rootContainer.createScope();
        RecordProcessor processor1 = (RecordProcessor) scope1.resolve(RecordProcessor.class);
        processor1.process('Record-001');
        // The logger is retrieved from the same scope to check its state.
        StatefulLogger logger1 = (StatefulLogger) scope1.get(StatefulLogger.class);
        Assert.areEqual(1, logger1.getMessages().size(), 'Logger 1 should have 1 message.');
        Assert.isTrue(logger1.getMessages()[0].contains('Record-001'), 'Logger 1 message should be for Record-001.');
        // --- End Unit of Work 1 ---

        // Act: Record 2
        // --- Start Unit of Work 2 ---
        Di.ScopeRef scope2 = rootContainer.createScope();
        RecordProcessor processor2 = (RecordProcessor) scope2.resolve(RecordProcessor.class);
        processor2.process('Record-002');
        StatefulLogger logger2 = (StatefulLogger) scope2.get(StatefulLogger.class);
        Assert.areEqual(1, logger2.getMessages().size(), 'Logger 2 should have 1 message.');
        Assert.isTrue(logger2.getMessages()[0].contains('Record-002'), 'Logger 2 message should be for Record-002.');
        // --- End Unit of Work 2 ---

        // Assert: Ensure the loggers were different instances.
        Assert.areNotEqual(logger1, logger2, 'Loggers from different scopes should be different instances.');
    }
    // </editor-fold>

    // <editor-fold desc="Resolution diagnostics">
    @IsTest
    static void should_explain_local_provider_without_instantiating_it() {
        // Arrange: A local factory provider exposes an observable instantiation counter.
        InjectionFailureModule module = new InjectionFailureModule();
        Di.ModuleRef ref = Di.addModule(module);

        // Act: Explain the provider binding without resolving it.
        Di.ResolutionExplanation explanation = ref.explain('BrokenService');

        // Assert: Binding details are structured and the provider was not instantiated.
        Assert.areEqual(Di.ResolutionStatus.RESOLVED, explanation.status);
        Assert.areEqual(Di.ResolutionSource.LOCAL, explanation.source);
        Assert.areEqual('BrokenService', explanation.token);
        Assert.areEqual(module.getToken(), explanation.requestingModule);
        Assert.areEqual(module.getToken(), explanation.ownerModule);
        Assert.areEqual(Di.Scope.SINGLETON, explanation.declaredScope);
        Assert.isNull(explanation.redirectToken);
        Assert.areEqual(0, explanation.conflictingModules.size());
        Assert.areEqual(0, module.factory.instantiationCount, 'explain() must not instantiate providers.');
    }

    @IsTest
    static void should_explain_imported_provider_owner_from_type_token() {
        // Arrange: A consumer imports an exported facade owned by another module.
        Di.ModuleRef consumer = Di.getModuleRef(PrivateFacadeConsumerModule.class);

        // Act: Explain through the Type overload.
        Di.ResolutionExplanation explanation = consumer.explain(ExportedPrivateFacade.class);

        // Assert: The explanation preserves the consumer-relative source and defining owner.
        Assert.areEqual(Di.ResolutionStatus.RESOLVED, explanation.status);
        Assert.areEqual(Di.ResolutionSource.IMPORTED, explanation.source);
        Assert.areEqual(consumer.getModule().getToken(), explanation.requestingModule);
        Assert.areEqual(new PrivateFacadeOwnerModule().getToken(), explanation.ownerModule);
        Assert.areEqual(Di.Scope.SINGLETON, explanation.declaredScope);
    }

    @IsTest
    static void should_explain_implicit_global_provider() {
        // Arrange: A global module exports a value to an unrelated consumer.
        OverrideGlobalModule globalModule = new OverrideGlobalModule();
        Di.addGlobalModule(globalModule);
        Di.ModuleRef consumer = Di.getModuleRef(EmptyModule.class);

        // Act: Explain the globally visible token.
        Di.ResolutionExplanation explanation = consumer.explain('val');

        // Assert: Global fallback and ownership are explicit.
        Assert.areEqual(Di.ResolutionStatus.RESOLVED, explanation.status);
        Assert.areEqual(Di.ResolutionSource.IMPLICIT_GLOBAL, explanation.source);
        Assert.areEqual(globalModule.getToken(), explanation.ownerModule);
        Assert.areEqual(Di.Scope.SINGLETON, explanation.declaredScope);
    }

    @IsTest
    static void should_explain_existing_provider_redirect() {
        // Arrange: A module declares an ExistingProvider alias.
        Di.ModuleRef ref = Di.getModuleRef(ArgsValidationModule.class);

        // Act: Explain the alias binding without following or instantiating its target.
        Di.ResolutionExplanation explanation = ref.explain('ExistingProvider');

        // Assert: The redirect remains explicit instead of reporting a misleading terminal scope.
        Assert.areEqual(Di.ResolutionStatus.RESOLVED, explanation.status);
        Assert.areEqual(Di.ResolutionSource.LOCAL, explanation.source);
        Assert.areEqual('ClassProvider', explanation.redirectToken);
        Assert.areEqual(Di.Scope.SINGLETON, explanation.declaredScope);
    }

    @IsTest
    static void should_explain_metadata_existing_provider_redirect() {
        // Arrange: Metadata configures a provider as an Existing alias.
        Di.mockProviders(
            new Map<String, DI_Provider__mdt>{
                'AliasProvider' => new DI_Provider__mdt(
                    DeveloperName = 'AliasProvider',
                    Type__c = 'Existing',
                    Value__c = 'TargetService',
                    IsActive__c = true
                )
            }
        );
        Di.ModuleRef ref = Di.getModuleRef(MetadataExistingModule.class);

        // Act: Explain the metadata-backed alias without resolving its target.
        Di.ResolutionExplanation explanation = ref.explain('AliasService');

        // Assert: Metadata normalization contributes the redirect and declared scope.
        Assert.areEqual(Di.ResolutionStatus.RESOLVED, explanation.status);
        Assert.areEqual(Di.ResolutionSource.LOCAL, explanation.source);
        Assert.areEqual('TargetService', explanation.redirectToken);
        Assert.areEqual(Di.Scope.SINGLETON, explanation.declaredScope);
    }

    @IsTest
    static void should_explain_ambiguous_imports_without_throwing() {
        // Arrange: Two imported modules export the same token from different owners.
        Di.ModuleRef consumer = Di.getModuleRef(AmbiguousImportConsumerModule.class);

        // Act: Explain the ambiguous token.
        Di.ResolutionExplanation explanation = consumer.explain('ambiguousImportVal');

        // Assert: Both conflicting owners are reported structurally rather than thrown as prose.
        Assert.areEqual(Di.ResolutionStatus.AMBIGUOUS, explanation.status);
        Assert.areEqual(Di.ResolutionSource.IMPORTED, explanation.source);
        Assert.isNull(explanation.ownerModule);
        Assert.isNull(explanation.declaredScope);
        Assert.isTrue(explanation.conflictingModules.contains(new AmbiguousImportLeftModule().getToken()));
        Assert.isTrue(explanation.conflictingModules.contains(new AmbiguousImportRightModule().getToken()));
    }

    @IsTest
    static void should_explain_ambiguity_through_reexport_without_throwing() {
        // Arrange: A consumer imports a module that re-exports two conflicting owners.
        Di.ModuleRef consumer = Di.getModuleRef(AmbiguousReexportConsumerModule.class);

        // Act: Explain the token whose ambiguity occurs inside the imported module.
        Di.ResolutionExplanation explanation = consumer.explain('ambiguousImportVal');

        // Assert: Nested ambiguity remains structured at the original consumer boundary.
        Assert.areEqual(Di.ResolutionStatus.AMBIGUOUS, explanation.status);
        Assert.areEqual(Di.ResolutionSource.IMPORTED, explanation.source);
        Assert.isTrue(explanation.conflictingModules.contains(new AmbiguousImportLeftModule().getToken()));
        Assert.isTrue(explanation.conflictingModules.contains(new AmbiguousImportRightModule().getToken()));
    }

    @IsTest
    static void should_explain_missing_provider_without_throwing() {
        // Arrange: A module has no visible provider for the requested token.
        Di.ModuleRef ref = Di.getModuleRef(LazyConsumerModule.class);

        // Act: Explain the missing token.
        Di.ResolutionExplanation explanation = ref.explain('missingProvider');

        // Assert: Absence is represented as data with no invented owner or scope.
        Assert.areEqual(Di.ResolutionStatus.NOT_FOUND, explanation.status);
        Assert.areEqual(Di.ResolutionSource.NONE, explanation.source);
        Assert.areEqual('missingProvider', explanation.token);
        Assert.isNull(explanation.ownerModule);
        Assert.isNull(explanation.declaredScope);
        Assert.areEqual(0, explanation.conflictingModules.size());
    }

    @IsTest
    static void should_not_open_context_lifecycle_when_explaining_provider() {
        // Arrange: A context has a consumer whose imported provider has not been discovered yet.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef consumer = context.getModuleRef(LazyConsumerModule.class);

        // Act: Explain the lazy import, then continue setup by registering another module.
        Di.ResolutionExplanation explanation = consumer.explain('val');
        context.addModule(new SingleModule());

        // Assert: Explanation may discover imports but must not turn later setup into a cold mutation.
        Assert.areEqual(Di.ResolutionStatus.RESOLVED, explanation.status);
        Assert.areEqual(Di.ResolutionSource.IMPORTED, explanation.source);
        Assert.areEqual('hello', (String) consumer.get('val'));
    }

    @IsTest
    static void should_honor_compiled_graph_miss_when_explaining_provider() {
        // Arrange: A compiled context has no visible binding for the requested token.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef ref = context.getModuleRef(EmptyModule.class);
        context.compile();

        // Act: Explain a token absent from the compiled binding index.
        Di.ResolutionExplanation explanation = ref.explain('compiledMissingProvider');

        // Assert: Diagnostics preserve the compiled graph's closed-world miss.
        Assert.areEqual(Di.ResolutionStatus.NOT_FOUND, explanation.status);
        Assert.areEqual(Di.ResolutionSource.NONE, explanation.source);
        Assert.isNull(explanation.ownerModule);
    }

    @IsTest
    static void should_reject_explanation_from_stale_module_ref() {
        // Arrange: A context-owned handle is invalidated by clearing its context.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef staleRef = context.getModuleRef(SingleModule.class);
        context.clear();

        // Act: Attempt to explain through the stale handle.
        try {
            staleRef.explain('TestService');
            Assert.fail('Expected InvalidContextException for a stale diagnostic handle.');
        } catch (Di.InvalidContextException ex) {
            // Assert: Diagnostics honor the same lifecycle boundary as resolution.
            Assert.isTrue(ex.getMessage().contains('application context'));
        }
    }
    // </editor-fold>

    // <editor-fold desc="Graph description">
    @IsTest
    static void should_describe_only_registered_graph_without_instantiating_providers() {
        // Arrange: One module has an observable factory and another has an undiscovered lazy import.
        Di.ApplicationContext context = newTestContext();
        InjectionFailureModule factoryModule = new InjectionFailureModule();
        context.addModule(factoryModule);
        context.getModuleRef(LazyConsumerModule.class);

        // Act: Describe the currently registered graph.
        Di.ContextDescription description = context.describe();

        // Assert: The snapshot is deterministic, non-instantiating, and excludes unmaterialized imports.
        Assert.isFalse(description.isCompiled);
        Assert.areEqual(2, description.modules.size());
        Assert.areEqual(0, factoryModule.factory.instantiationCount);
        Assert.isNull(findModuleDescription(description, new ValueModule().getToken()));
        Assert.areEqual(
            Di.ProviderKind.FACTORY_PROVIDER,
            findProviderDescription(findModuleDescription(description, factoryModule.getToken()), 'BrokenService').kind
        );
        Assert.areEqual(
            ValueModule.class.getName(),
            findModuleDescription(description, new LazyConsumerModule().getToken()).imports[0].token
        );
        Assert.isFalse(findModuleDescription(description, new LazyConsumerModule().getToken()).imports[0].isEager);
    }

    @IsTest
    static void should_describe_complete_reachable_graph_after_compile() {
        // Arrange: A context contains a module with an unmaterialized import.
        Di.ApplicationContext context = newTestContext();
        context.getModuleRef(LazyConsumerModule.class);

        // Act: Compile the reachable graph before describing it.
        context.compile();
        Di.ContextDescription description = context.describe();

        // Assert: Compilation is explicit and the imported module now appears in the snapshot.
        Assert.isTrue(description.isCompiled);
        Assert.isNotNull(findModuleDescription(description, new LazyConsumerModule().getToken()));
        Assert.isNotNull(findModuleDescription(description, new ValueModule().getToken()));
    }

    @IsTest
    static void should_describe_provider_kinds_scopes_exports_and_redirects() {
        // Arrange: Built-in, custom, metadata, and global provider definitions are registered.
        Di.ApplicationContext context = newTestContext();
        context.mockProviders(
            new Map<String, DI_Provider__mdt>{
                'AliasProvider' => new DI_Provider__mdt(
                    DeveloperName = 'AliasProvider',
                    Type__c = 'Existing',
                    Value__c = 'TargetService',
                    Scope__c = 'PROTOTYPE',
                    IsActive__c = true
                )
            }
        );
        context.addModule(new DescriptionProviderModule());
        context.addModule(new MetadataExistingModule());
        DescriptionGlobalModule globalModule = new DescriptionGlobalModule();
        context.addGlobalModule(globalModule);

        // Act: Snapshot the committed definitions.
        Di.ContextDescription description = context.describe();
        Di.ModuleDescription providerModule = findModuleDescription(
            description,
            new DescriptionProviderModule().getToken()
        );

        // Assert: Provider metadata is useful without exposing values, factories, or instances.
        Assert.areEqual(Di.ProviderKind.CLASS_PROVIDER, findProviderDescription(providerModule, 'class').kind);
        Assert.areEqual(Di.Scope.PROTOTYPE, findProviderDescription(providerModule, 'class').declaredScope);
        Assert.areEqual(Di.ProviderKind.VALUE_PROVIDER, findProviderDescription(providerModule, 'value').kind);
        Assert.areEqual(
            Di.ProviderConfigurationStatus.VALID,
            findProviderDescription(providerModule, 'value').configurationStatus
        );
        Assert.isTrue(findProviderDescription(providerModule, 'value').isExported);
        Assert.areEqual(Di.ProviderKind.FACTORY_PROVIDER, findProviderDescription(providerModule, 'factory').kind);
        Assert.areEqual(Di.ProviderKind.EXISTING_PROVIDER, findProviderDescription(providerModule, 'alias').kind);
        Assert.areEqual('value', findProviderDescription(providerModule, 'alias').redirectToken);
        Assert.areEqual(
            Di.ProviderKind.METADATA_PROVIDER,
            findProviderDescription(
                    findModuleDescription(description, new MetadataExistingModule().getToken()),
                    'AliasService'
                )
                .kind
        );
        Assert.areEqual(
            'TargetService',
            findProviderDescription(
                    findModuleDescription(description, new MetadataExistingModule().getToken()),
                    'AliasService'
                )
                .redirectToken
        );
        Assert.areEqual(
            Di.ProviderConfigurationStatus.VALID,
            findProviderDescription(
                    findModuleDescription(description, new MetadataExistingModule().getToken()),
                    'AliasService'
                )
                .configurationStatus
        );
        Assert.areEqual(
            Di.Scope.PROTOTYPE,
            findProviderDescription(
                    findModuleDescription(description, new MetadataExistingModule().getToken()),
                    'AliasService'
                )
                .declaredScope
        );
        Assert.isTrue(findModuleDescription(description, globalModule.getToken()).isGlobal);
    }

    @IsTest
    static void should_describe_missing_metadata_definition_without_throwing() {
        // Arrange: A registered metadata provider has no matching metadata definition.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new MetadataModule());

        // Act: Describe the malformed metadata-backed graph.
        Di.ProviderDescription provider = findProviderDescription(
            findModuleDescription(context.describe(), new MetadataModule().getToken()),
            IMetadataService.class.getName()
        );

        // Assert: Diagnostics remain available and avoid inventing redirect metadata.
        Assert.areEqual(Di.ProviderKind.METADATA_PROVIDER, provider.kind);
        Assert.areEqual(Di.ProviderConfigurationStatus.MISSING_METADATA, provider.configurationStatus);
        Assert.areEqual(Di.Scope.SINGLETON, provider.declaredScope);
        Assert.isNull(provider.redirectToken);
    }

    @IsTest
    static void should_describe_inactive_metadata_definition_without_throwing() {
        // Arrange: A registered metadata alias points at an inactive definition.
        Di.ApplicationContext context = newTestContext();
        context.mockProviders(
            new Map<String, DI_Provider__mdt>{
                'AliasProvider' => new DI_Provider__mdt(
                    DeveloperName = 'AliasProvider',
                    Type__c = 'Existing',
                    Value__c = 'TargetService',
                    IsActive__c = false
                )
            }
        );
        context.addModule(new MetadataExistingModule());

        // Act: Describe the inactive metadata-backed alias.
        Di.ProviderDescription provider = findProviderDescription(
            findModuleDescription(context.describe(), new MetadataExistingModule().getToken()),
            'AliasService'
        );

        // Assert: Inactive configuration does not prevent graph introspection.
        Assert.areEqual(Di.ProviderKind.METADATA_PROVIDER, provider.kind);
        Assert.areEqual(Di.ProviderConfigurationStatus.INACTIVE_METADATA, provider.configurationStatus);
        Assert.areEqual(Di.Scope.SINGLETON, provider.declaredScope);
        Assert.isNull(provider.redirectToken);
    }

    @IsTest
    static void should_describe_invalid_metadata_definitions_without_throwing() {
        // Arrange: Metadata contains one invalid scope and one unsupported provider type.
        Di.ApplicationContext context = newTestContext();
        context.mockProviders(
            new Map<String, DI_Provider__mdt>{
                'ConfigurableService' => new DI_Provider__mdt(
                    DeveloperName = 'ConfigurableService',
                    Type__c = 'Class',
                    Value__c = TestServiceImpl.class.getName(),
                    Scope__c = 'INVALID_SCOPE',
                    IsActive__c = true
                ),
                'StringValueProvider' => new DI_Provider__mdt(
                    DeveloperName = 'StringValueProvider',
                    Type__c = 'Unsupported',
                    IsActive__c = true
                )
            }
        );
        context.addModule(new MetadataModule());

        // Act: Describe both invalid metadata definitions.
        Di.ModuleDescription module = findModuleDescription(context.describe(), new MetadataModule().getToken());
        Di.ProviderDescription invalidScope = findProviderDescription(module, IMetadataService.class.getName());
        Di.ProviderDescription invalidType = findProviderDescription(module, 'StringValue');

        // Assert: Invalid definitions remain inspectable and use the provider's configured fallback scope.
        Assert.areEqual(Di.ProviderConfigurationStatus.INVALID_METADATA, invalidScope.configurationStatus);
        Assert.areEqual(Di.Scope.SINGLETON, invalidScope.declaredScope);
        Assert.areEqual(Di.ProviderConfigurationStatus.INVALID_METADATA, invalidType.configurationStatus);
        Assert.isNull(invalidType.redirectToken);
    }

    @IsTest
    static void should_describe_import_and_reexport_edges_deterministically() {
        // Arrange: A module declares eager/lazy imports and a re-export in non-sorted order.
        Di.ApplicationContext context = newTestContext();
        context.addModule(new DescriptionEdgesModule());

        // Act: Describe the committed graph edges.
        Di.ModuleDescription module = findModuleDescription(
            context.describe(),
            new DescriptionEdgesModule().getToken()
        );

        // Assert: Edge snapshots are sorted and preserve eager-import metadata.
        Assert.areEqual(2, module.imports.size());
        Assert.areEqual(SingleModule.class.getName(), module.imports[0].token);
        Assert.isTrue(module.imports[0].isEager);
        Assert.areEqual(ValueModule.class.getName(), module.imports[1].token);
        Assert.isFalse(module.imports[1].isEager);
        Assert.areEqual(1, module.reexports.size());
        Assert.areEqual(SharedImportReexportCommonModule.class.getName(), module.reexports[0].token);
        Assert.areEqual('sharedImportReexportVal', module.exports[0]);
    }

    @IsTest
    static void should_return_defensive_description_without_opening_context_lifecycle() {
        // Arrange: A context is still in bootstrap and contains one module handle.
        Di.ApplicationContext context = newTestContext();
        Di.ModuleRef ref = context.getModuleRef(LazyConsumerModule.class);

        // Act: Mutate the returned snapshot, then continue bootstrap registration.
        Di.ContextDescription first = context.describe();
        first.modules.clear();
        context.addModule(new SingleModule());
        Di.ContextDescription second = context.describe();

        // Assert: Snapshot mutation is isolated and describe() did not invalidate the held bootstrap handle.
        Assert.areEqual(0, first.modules.size());
        Assert.areEqual(2, second.modules.size());
        Assert.areEqual('hello', (String) ref.get('val'));
    }

    @IsTest
    static void should_describe_default_application_context_through_static_facade() {
        // Arrange: A module is registered through the default static facade.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);

        // Act: Describe the default application context.
        Di.ContextDescription description = Di.describe();

        // Assert: Static users can inspect the same committed module token.
        Assert.areEqual(ref.getModule().getToken(), description.modules[0].token);
    }
    // </editor-fold>

    // <editor-fold desc="Resolution memo">
    @IsTest
    static void should_return_stable_singleton_across_memoized_lookups() {
        // Arrange: A singleton provider is registered and ready for repeated lookup.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);

        // Act: Resolve once through the slow path, then repeat through the memoized path.
        Object first = ref.get('TestService'); // slow path: resolves, caches singleton, memoizes plan
        Object second = ref.get('TestService'); // memo hit
        Object third = ref.get('TestService');

        // Assert: Memoized lookups preserve singleton identity.
        Assert.isNotNull(first, 'Memoized singleton lookup should resolve an instance.');
        Assert.isTrue(first === second, 'Repeated memoized lookups must return the same singleton instance.');
        Assert.isTrue(second === third, 'Repeated memoized lookups must remain stable.');
    }

    @IsTest
    static void should_return_consistent_value_and_factory_via_memo() {
        // Arrange: Value and factory modules are registered independently.
        Di.ModuleRef valueRef = Di.getModuleRef(ValueModule.class);

        // Act and Assert: Repeated value lookups use the memo without changing the returned value.
        Assert.areEqual('hello', (String) valueRef.get('val'));
        Assert.areEqual('hello', (String) valueRef.get('val'), 'Memoized value lookup must stay consistent.');

        // Arrange: A singleton factory provider is registered.
        Di.ModuleRef factoryRef = Di.getModuleRef(FactoryModule.class);

        // Act: Resolve the factory provider twice.
        Object firstSvc = factoryRef.get('svc');
        Object secondSvc = factoryRef.get('svc');

        // Assert: Memoized factory lookup still respects singleton caching.
        Assert.isTrue(firstSvc === secondSvc, 'Memoized factory singleton must return the same instance.');
    }

    @IsTest
    static void should_keep_prototype_resolve_fresh_and_reject_get_with_memo() {
        // Arrange: A prototype provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(PrototypeModule.class);

        // Act: Resolve twice so the plan can be memoized while instances remain fresh.
        Object first = ref.resolve('p'); // memoizes the plan, returns a fresh instance
        Object second = ref.resolve('p'); // memo hit, still fresh

        // Assert: resolve() stays fresh for prototype providers.
        Assert.isTrue(first !== second, 'PROTOTYPE resolve must stay fresh even when the plan is memoized.');

        // Act: Try to use get() on the same memoized prototype provider.
        try {
            ref.get('p');
            Assert.fail('PROTOTYPE get must still throw when the plan is memoized.');
        } catch (Di.InvalidScopeException ex) {
            // Assert: get() still enforces the prototype scope rule.
            Assert.isTrue(
                ex.getMessage().containsIgnoreCase('prototype'),
                'Exception should explain the prototype rule.'
            );
        }
    }

    @IsTest
    static void should_reject_stale_handle_and_resolve_new_value_after_replacement_with_memo() {
        // Arrange: Resolve a value once so the original handle has a memoized plan.
        Di.ModuleRef ref = Di.getModuleRef(ValueModule.class);
        Assert.areEqual('hello', (String) ref.get('val')); // memoizes the plan for 'val'
        Di.Provider replacement = ref.getModule().provide('val').useValue('replaced');

        // Act: Replace the provider through the application context.
        Di.replaceProvider(ValueModule.class, replacement); // external mutation: bumps generation, reissues handles

        // Assert: The stale handle rejects use instead of serving the old memoized plan.
        try {
            ref.get('val');
            Assert.fail('Stale handle must throw after external mutation, not serve a memoized plan.');
        } catch (Di.InvalidContextException ex) {
            Assert.isTrue(ex.getMessage().contains('application context'));
        }

        // Assert: A freshly issued handle sees the replacement.
        Di.ModuleRef fresh = Di.getModuleRef(ValueModule.class);
        Assert.areEqual('replaced', (String) fresh.get('val'), 'Fresh handle must resolve the replaced value.');
    }

    @IsTest
    static void should_resolve_through_lazy_import_with_memo_enabled() {
        // Arrange: A consumer lazily imports ValueModule during resolution.
        Di.ModuleRef ref = Di.getModuleRef(LazyConsumerModule.class);

        // Act and Assert: The first lookup materializes the import and resolves correctly.
        Assert.areEqual('depends on hello', (String) ref.get('dependentVal'));

        // Act and Assert: Repeated memoized lookups remain correct after discovery settles.
        Assert.areEqual('depends on hello', (String) ref.get('dependentVal'));
        Assert.areEqual('depends on hello', (String) ref.get('dependentVal'));
    }

    @IsTest
    static void should_not_share_memo_entries_across_module_handles() {
        // Arrange: Two module handles expose the same token name from different module definitions.
        Di.ModuleRef valueRef = Di.getModuleRef(ValueModule.class);
        Di.DynamicModule other = new Di.DynamicModule('MemoOtherModule');
        other.addProvider(other.provide('val').useValue('other'));
        Di.ModuleRef otherRef = Di.addModule(other);

        // Act and Assert: Each handle keeps its own memo entry and returns its own provider.
        Assert.areEqual('hello', (String) valueRef.get('val'));
        Assert.areEqual('other', (String) otherRef.get('val'));
        Assert.areEqual('hello', (String) valueRef.get('val'));
        Assert.areEqual('other', (String) otherRef.get('val'));
    }

    @IsTest
    static void should_reject_memoized_plan_built_at_an_earlier_graph_revision() {
        // Arrange: 'dependentVal' is memoized before its nested 'val' lookup lazily installs ValueModule,
        // which bumps the graph revision mid-resolution and leaves the 'dependentVal' plan one revision behind.
        Di.ModuleRef ref = Di.getModuleRef(LazyConsumerModule.class);
        Integer before = Di.memoRevisionMissCount;
        Assert.areEqual('depends on hello', (String) ref.get('dependentVal'));
        Assert.areEqual(before, Di.memoRevisionMissCount, 'First resolution should not reject any plan on revision.');

        // Act: Resolve the same token again; its memoized plan now predates the current graph revision.
        Assert.areEqual('depends on hello', (String) ref.get('dependentVal'));

        // Assert: The graphRevision guard rejected the stale plan and rebuilt it. This would NOT increment
        // if the guard were weakened to ignore the revision and serve the stale entry.
        Assert.areEqual(
            before + 1,
            Di.memoRevisionMissCount,
            'The graphRevision guard must reject a resolution plan built at an earlier revision.'
        );
    }

    @IsTest
    static void should_serve_cached_singleton_consistently_on_repeated_get() {
        // Arrange: Warm a singleton so the module ref has both a memoized plan and a cached instance.
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);
        Object warm = ref.get('TestService');

        // Act: Repeat get() calls that are eligible for the root singleton fast lane.
        Object first = ref.get('TestService');
        Object second = ref.get('TestService');

        // Assert: Repeated lookups return the same cached singleton instance.
        Assert.isTrue(
            first === warm && second === warm,
            'Repeated cached singleton gets must return the same instance.'
        );
    }

    @IsTest
    static void should_resolve_imported_singleton_consistently_through_consumer() {
        // Arrange: A consumer resolves an imported singleton, so the memo owner is not the consumer ref.
        Di.ModuleRef consumer = Di.getModuleRef(LazyConsumerModule.class);

        // Act and Assert: Repeated lookups route to the owner and stay correct.
        Assert.areEqual('hello', (String) consumer.get('val'));
        Assert.areEqual('hello', (String) consumer.get('val'));
    }
    // </editor-fold>

    // <editor-fold desc="Helpers">
    private static Di.ModuleDescription findModuleDescription(final Di.ContextDescription context, final String token) {
        for (Di.ModuleDescription module : context.modules) {
            if (module.token == token) {
                return module;
            }
        }
        return null;
    }

    private static Di.ProviderDescription findProviderDescription(
        final Di.ModuleDescription module,
        final String token
    ) {
        for (Di.ProviderDescription provider : module.providers) {
            if (provider.token == token) {
                return provider;
            }
        }
        return null;
    }

    private static Di.ApplicationContext newTestContext() {
        Di.ApplicationContext context = Di.createContext();
        context.mockModules(new List<DI_Module__mdt>());
        context.mockProviders(new Map<String, DI_Provider__mdt>());
        return context;
    }

    private static Integer assertResolveArgsUnsupported(final Di.ModuleRef ref, final String token) {
        try {
            ref.resolve(token, 'someArgs');
            Assert.fail('Expected InvalidProviderException when resolving non-factory provider with arguments.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Arguments are only supported for FactoryProvider'),
                'Exception message should explain that arguments are factory-only.'
            );
        }
        return 1;
    }

    private static void assertUnknownModuleReplacement(final Di.ApplicationContext context, final String token) {
        try {
            context.replaceModule(token, new Di.DynamicModule(token));
            Assert.fail('Expected UnknownModuleException for replacing an unregistered module.');
        } catch (Di.UnknownModuleException ex) {
            Assert.isTrue(ex.getMessage().contains(token), 'Exception message should identify the missing module.');
        }
    }

    // --- Service Interfaces and Implementations ---
    public interface TestService {
    }
    public class TestServiceImpl implements TestService {
    }
    public class MockService implements TestService {
    }
    public abstract class AbstractService {
    }
    public class ScopedService {
    }
    public class SingletonService {
    }
    public class PrototypeService {
    }
    public class ServiceA {
    }
    public class ServiceB {
    }
    public interface IMetadataService {
    }
    public class MockMetadataServiceImpl implements IMetadataService {
    }
    public class ConstructorFailureException extends Exception {
    }
    public class UnconstructableModule extends Di.Module {
        public UnconstructableModule() {
            throw new ConstructorFailureException();
        }
    }
    public class NotAModule {
    }

    // --- Factory Implementations ---
    public class TestFactory implements Di.Factory {
        public Object newInstance(Di.Container ref, Object args) {
            return new TestServiceImpl();
        }
    }
    public class ArgsFactory implements Di.Factory {
        public Object newInstance(Di.Container ref, Object args) {
            return 'arg:' + (args != null ? ((List<Object>) args)[0] : '');
        }
    }
    public class StringArgsFactory implements Di.Factory {
        public Object newInstance(Di.Container ref, Object args) {
            return 'arg:' + (!String.isBlank((String) args) ? (String) args : '');
        }
    }
    public class InternalConsumerFactory implements Di.Factory {
        public Object newInstance(Di.Container ref, Object args) {
            return ref.get('foo');
        }
    }
    public class NestedInjectFactory implements Di.Factory {
        public Object newInstance(Di.Container ref, Object args) {
            return ref.inject(new FooInjectable());
        }
    }
    public class DependentProviderFactory implements Di.Factory {
        public Object newInstance(Di.Container ref, Object args) {
            String importedValue = (String) ref.get('val');
            return 'depends on ' + importedValue;
        }
    }
    public class FactoryA implements Di.Factory {
        public Object newInstance(Di.Container container, Object args) {
            container.get(ServiceB.class);
            return new ServiceA();
        }
    }
    public class FactoryB implements Di.Factory {
        public Object newInstance(Di.Container container, Object args) {
            container.get(ServiceA.class);
            return new ServiceB();
        }
    }
    public class NotFactory {
        public Object newInstance(Di.Container ref, Object args) {
            return new TestServiceImpl();
        }
    }

    // --- Injectable Implementation ---
    public class FooInjectable implements Di.Injectable {
        public Boolean wasInjected = false;
        public void inject(final Di.Container c) {
            wasInjected = true;
        }
    }
    public class ScopedWithSingletonDepService implements Di.Injectable {
        public SingletonService singletonDep { get; private set; }
        public void inject(Di.Container container) {
            singletonDep = (SingletonService) container.get(SingletonService.class);
        }
    }
    public class SingletonWithScopedDepService implements Di.Injectable {
        public ScopedService scopedDep { get; private set; }
        public void inject(Di.Container container) {
            scopedDep = (ScopedService) container.get(ScopedService.class);
        }
    }
    public class ScopedWithPrototypeDepService implements Di.Injectable {
        public PrototypeService prototypeDep { get; private set; }
        public void inject(Di.Container container) {
            prototypeDep = (PrototypeService) container.resolve(PrototypeService.class);
        }
    }
    public class ForwardRefServiceA implements Di.Injectable {
        public ForwardRefServiceB serviceB { get; private set; }
        public void inject(Di.Container container) {
            // This injection creates the cycle.
            this.serviceB = (ForwardRefServiceB) container.get(ForwardRefServiceB.class);
        }
    }
    public class ForwardRefServiceB implements Di.Injectable {
        public ForwardRefServiceA serviceA { get; private set; }
        public void inject(Di.Container container) {
            // This injection completes the cycle.
            this.serviceA = (ForwardRefServiceA) container.get(ForwardRefServiceA.class);
        }
    }
    public class SharedSingletonService {
    }
    public class ScopedExportService {
    }
    public class PrivateDependencyService {
        public String getValue() {
            return 'private-dependency';
        }
    }
    public class ConsumerOnlyDependencyService {
    }
    public class ExportedPrivateFacade implements Di.Injectable {
        private PrivateDependencyService dependency;
        public void inject(Di.Container container) {
            dependency = (PrivateDependencyService) container.get(PrivateDependencyService.class);
        }
        public String getDependencyValue() {
            return dependency.getValue();
        }
    }
    public class ExportedConsumerOnlyFacade implements Di.Injectable {
        public void inject(Di.Container container) {
            container.get(ConsumerOnlyDependencyService.class);
        }
    }

    // --- Basic Module Definitions ---
    public virtual class EmptyModule extends Di.Module {
    }
    public class SingleModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('TestService').useClass(TestServiceImpl.class) };
        }
    }
    public class PrototypeModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('p').useClass(TestServiceImpl.class).scope(Di.Scope.PROTOTYPE) };
        }
    }
    public class ValueModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('val').useValue('hello') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'val' };
        }
    }
    public class FactoryModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('svc').useFactory(new TestFactory()) };
        }
    }
    public class DescriptionProviderModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide('class').useClass(TestServiceImpl.class).scope(Di.Scope.PROTOTYPE),
                provide('value').useValue('not-exposed-by-description'),
                provide('factory').useFactory(new TestFactory()),
                provide('alias').useExisting('value')
            };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'value' };
        }
    }
    public class DescriptionGlobalModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('descriptionGlobal').useValue('global') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'descriptionGlobal' };
        }
    }
    public class DescriptionEdgesModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{
                Di.import(ValueModule.class),
                Di.import(SingleModule.class).immediately()
            };
        }
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(SharedImportReexportCommonModule.class) };
        }
    }
    public class ArgsModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('arg').useFactory(new ArgsFactory()) };
        }
    }
    public class StringTypeModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('svc').useClass('DiTest.TestServiceImpl') };
        }
    }
    public class InjectableModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(FooInjectable.class).useClass(FooInjectable.class) };
        }
    }
    public class NestedInjectModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('NestedInject').useFactory(new NestedInjectFactory()) };
        }
    }
    public class TypeModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(TestService.class).useClass(TestServiceImpl.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ TestService.class.getName() };
        }
    }
    public class ArgsTypeModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(TestServiceImpl.class).useFactory(new ArgsFactory()) };
        }
        public override Set<String> exports() {
            return new Set<String>{ TestServiceImpl.class.getName() };
        }
    }
    public class ExistingProviderModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide('MyLongAndComplexServiceName').useClass(TestServiceImpl.class),
                provide('MyAlias').useExisting('MyLongAndComplexServiceName')
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class CircularExistingProviderModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide('AliasA').useExisting('AliasB'),
                provide('AliasB').useExisting('AliasA')
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class ScopedModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(ScopedService.class).useClass(ScopedService.class).scope(Di.Scope.SCOPED)
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class ScopedWithSingletonDepModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(SingletonService.class).useClass(SingletonService.class).scope(Di.Scope.SINGLETON),
                provide(ScopedWithSingletonDepService.class)
                    .useClass(ScopedWithSingletonDepService.class)
                    .scope(Di.Scope.SCOPED)
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class SingletonWithScopedDepModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(ScopedService.class).useClass(ScopedService.class).scope(Di.Scope.SCOPED),
                provide(SingletonWithScopedDepService.class)
                    .useClass(SingletonWithScopedDepService.class)
                    .scope(Di.Scope.SINGLETON)
            };
        }
    }
    public class ScopedWithPrototypeDepModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(PrototypeService.class).useClass(PrototypeService.class).scope(Di.Scope.PROTOTYPE),
                provide(ScopedWithPrototypeDepService.class)
                    .useClass(ScopedWithPrototypeDepService.class)
                    .scope(Di.Scope.SCOPED)
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class AliasCircularBModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(AliasCircularAModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('ProviderB').useExisting('AliasA') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'ProviderB' };
        }
    }
    public class AliasCircularAModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(AliasCircularBModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('AliasA').useExisting('ProviderB') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'AliasA' };
        }
    }
    public class FactoryCircularAModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(FactoryCircularBModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(ServiceA.class).useFactory(new FactoryA()) };
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class FactoryCircularBModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(ServiceB.class).useFactory(new FactoryB()) };
        }
        public override Set<String> exports() {
            return new Set<String>{ ServiceB.class.getName() };
        }
    }
    public class ExistingPrototypeProviderModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide('TestService').useClass(TestServiceImpl.class),
                provide('AliasService').useExisting('TestService').scope(Di.Scope.PROTOTYPE)
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class ForwardRefModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(ForwardRefServiceA.class).useClass(ForwardRefServiceA.class),
                provide(ForwardRefServiceB.class).useClass(ForwardRefServiceB.class)
            };
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    // --- Modules for Import/Export Tests ---
    public class BModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('foo').useValue('bar') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo' };
        }
    }
    public class InternalConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(BModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('internal').useFactory(new InternalConsumerFactory()) };
        }
    }
    public class BindingIndexCountingConsumerModule extends EmptyModule {
        public Integer importTraversalCount = 0;
        public override Set<Di.ModuleImport> imports() {
            importTraversalCount++;
            return new Set<Di.ModuleImport>{ Di.import(ValueModule.class) };
        }
    }
    public class OverrideModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(BModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('foo').useValue('override') };
        }
    }
    public class AmbiguousImportLeftModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('ambiguousImportVal').useValue('left') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'ambiguousImportVal' };
        }
    }
    public class AmbiguousImportRightModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('ambiguousImportVal').useValue('right') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'ambiguousImportVal' };
        }
    }
    public class AmbiguousImportConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{
                Di.import(AmbiguousImportLeftModule.class),
                Di.import(AmbiguousImportRightModule.class)
            };
        }
    }
    public class AmbiguousReexportModule extends EmptyModule {
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{
                Di.import(AmbiguousImportLeftModule.class),
                Di.import(AmbiguousImportRightModule.class)
            };
        }
    }
    public class AmbiguousReexportConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(AmbiguousReexportModule.class) };
        }
    }
    public class SharedImportReexportCommonModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('sharedImportReexportVal').useValue('shared') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'sharedImportReexportVal' };
        }
    }
    public class SharedImportReexportLeftModule extends EmptyModule {
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(SharedImportReexportCommonModule.class) };
        }
    }
    public class SharedImportReexportRightModule extends EmptyModule {
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(SharedImportReexportCommonModule.class) };
        }
    }
    public class SharedImportReexportConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{
                Di.import(SharedImportReexportLeftModule.class),
                Di.import(SharedImportReexportRightModule.class)
            };
        }
    }
    public class SharedSingletonOwnerModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(SharedSingletonService.class).useClass(SharedSingletonService.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ SharedSingletonService.class.getName() };
        }
    }
    public class SharedSingletonConsumerLeftModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(SharedSingletonOwnerModule.class) };
        }
    }
    public class SharedSingletonConsumerRightModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(SharedSingletonOwnerModule.class) };
        }
    }
    public class ExportedAliasOwnerModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(SharedSingletonService.class).useClass(SharedSingletonService.class),
                provide('SharedExportAlias').useExisting(SharedSingletonService.class)
            };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'SharedExportAlias' };
        }
    }
    public class ExportedAliasConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ExportedAliasOwnerModule.class) };
        }
    }
    public class ScopedExportOwnerModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(ScopedExportService.class).useClass(ScopedExportService.class).scope(Di.Scope.SCOPED)
            };
        }
        public override Set<String> exports() {
            return new Set<String>{ ScopedExportService.class.getName() };
        }
    }
    public class ScopedExportConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ScopedExportOwnerModule.class) };
        }
    }
    public class ScopedExportConsumerLeftModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ScopedExportOwnerModule.class) };
        }
    }
    public class ScopedExportConsumerRightModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ScopedExportOwnerModule.class) };
        }
    }
    public class PrivateFacadeOwnerModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(PrivateDependencyService.class).useClass(PrivateDependencyService.class),
                provide(ExportedPrivateFacade.class).useClass(ExportedPrivateFacade.class)
            };
        }
        public override Set<String> exports() {
            return new Set<String>{ ExportedPrivateFacade.class.getName() };
        }
    }
    public class PrivateFacadeConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(PrivateFacadeOwnerModule.class) };
        }
    }
    public class TokenCollisionLocalModule extends Di.Module {
        public TokenCollisionLocalModule() {
            super('TokenCollisionModule');
        }
    }
    public class TokenCollisionGlobalOwnerModule extends Di.Module {
        public TokenCollisionGlobalOwnerModule() {
            super('TokenCollisionModule');
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(PrivateDependencyService.class).useClass(PrivateDependencyService.class),
                provide(ExportedPrivateFacade.class).useClass(ExportedPrivateFacade.class)
            };
        }
        public override Set<String> exports() {
            return new Set<String>{ ExportedPrivateFacade.class.getName() };
        }
    }
    public class ConsumerOnlyDependencyModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(ConsumerOnlyDependencyService.class).useClass(ConsumerOnlyDependencyService.class)
            };
        }
        public override Set<String> exports() {
            return new Set<String>{ ConsumerOnlyDependencyService.class.getName() };
        }
    }
    public class ConsumerOnlyDependencyOwnerModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(ExportedConsumerOnlyFacade.class).useClass(ExportedConsumerOnlyFacade.class)
            };
        }
        public override Set<String> exports() {
            return new Set<String>{ ExportedConsumerOnlyFacade.class.getName() };
        }
    }
    public class ConsumerOnlyDependencyConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{
                Di.import(ConsumerOnlyDependencyOwnerModule.class),
                Di.import(ConsumerOnlyDependencyModule.class)
            };
        }
    }

    // --- Modules for Re-Exporting Tests ---
    public class ServiceCModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('serviceC').useValue('c-service') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'serviceC' };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
    }
    public class ReexportingModuleB extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ServiceCModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(ServiceCModule.class) };
        }
    }
    public class NonReexportingModuleB extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ServiceCModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class ReexportConsumerModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ReexportingModuleB.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class NonReexportConsumerModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(NonReexportingModuleB.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class ServiceDModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('serviceD').useValue('d-service') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'serviceD' };
        }
    }
    public class TransitiveReexportMiddleModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ServiceDModule.class) };
        }
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(ServiceDModule.class) };
        }
    }
    public class TransitiveReexportRootModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(TransitiveReexportMiddleModule.class) };
        }
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(TransitiveReexportMiddleModule.class) };
        }
    }
    public class TransitiveReexportConsumerModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(TransitiveReexportRootModule.class) };
        }
    }
    public class CircularReexportAModule extends Di.Module {
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularReexportBModule.class) };
        }
    }
    public class CircularReexportBModule extends Di.Module {
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularReexportAModule.class) };
        }
    }

    // --- Modules for Error Condition Tests ---
    public class LocalErrorModule extends EmptyModule {
        public override Set<String> exports() {
            return new Set<String>{ 'missing' };
        }
    }
    public class GlobalErrorModule extends EmptyModule {
        public override Set<String> exports() {
            return new Set<String>{ 'missingGlobal' };
        }
    }
    public class AbstractProviderModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('abs').useClass(AbstractService.class) };
        }
    }
    public class CircularA extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularB.class) };
        }
    }
    public class CircularB extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularC.class) };
        }
    }
    public class CircularC extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularA.class) };
        }
    }
    public class ReplacementModule extends Di.Module {
        public ReplacementModule() {
            super(SingleModule.class.getName());
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('TestService').useValue('replaced') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'TestService' };
        }
    }
    public class LazyConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ValueModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('dependentVal').useFactory(new DependentProviderFactory()) };
        }
    }
    public class ImmediateConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ValueModule.class).immediately() };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('dependentVal').useFactory(new DependentProviderFactory()) };
        }
    }
    public class ReplacementValueModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('val').useValue('replaced') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'val' };
        }
    }
    public class CachedImportModule extends EmptyModule {
        private Set<Di.ModuleImport> imports;
        public override Set<Di.ModuleImport> imports() {
            if (imports == null) {
                imports = new Set<Di.ModuleImport>{ Di.import(ValueModule.class).immediately() };
            }
            return imports;
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('dependentVal').useFactory(new DependentProviderFactory()) };
        }
    }
    public class RegisterCountingModule extends EmptyModule {
        public Integer providerBuildCount = 0;
        public override Set<Di.Provider> providers() {
            providerBuildCount++;
            return new Set<Di.Provider>{ provide('counted').useValue('registered') };
        }
    }
    public class LazyErrorConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import('NonExistent.Module') };
        }
    }
    public class ImmediateMissingImportModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import('NonExistent.Module').immediately() };
        }
    }

    // --- Modules for Global CMT Tests ---
    public class CmtGlobalModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('cmtGlobalVal').useValue('helloFromCmt') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'cmtGlobalVal' };
        }
    }
    public class GlobalSharedSingletonModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(SharedSingletonService.class).useClass(SharedSingletonService.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ SharedSingletonService.class.getName() };
        }
    }
    public class GlobalSingletonConsumerLeftModule extends EmptyModule {
    }
    public class GlobalSingletonConsumerRightModule extends EmptyModule {
    }
    public class DuplicateGlobalExportLeftModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('duplicateGlobalVal').useValue('left') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'duplicateGlobalVal' };
        }
    }
    public class DuplicateGlobalExportRightModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('duplicateGlobalVal').useValue('right') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'duplicateGlobalVal' };
        }
    }
    public class SharedGlobalReexportCommonModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('sharedGlobalReexportVal').useValue('shared') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'sharedGlobalReexportVal' };
        }
    }
    public class SharedGlobalReexportLeftModule extends EmptyModule {
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(SharedGlobalReexportCommonModule.class) };
        }
    }
    public class SharedGlobalReexportRightModule extends EmptyModule {
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(SharedGlobalReexportCommonModule.class) };
        }
    }
    public class GlobalBindingIndexCountingModule extends EmptyModule {
        public Integer bindingTraversalCount = 0;
        public override Set<Di.ModuleImport> reexports() {
            bindingTraversalCount++;
            return new Set<Di.ModuleImport>{ Di.import(SharedGlobalReexportCommonModule.class) };
        }
    }
    public class OverrideGlobalModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('val').useValue('global') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'val' };
        }
    }
    public class LocalOverrideModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('val').useValue('local') };
        }
    }
    public class SelfImportingModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(SelfImportingModule.class) };
        }
    }
    // --- Modules for Metadata Tests ---
    public class ArgsValidationModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide('ArgsFactory').useFactory(new ArgsValidationFactory()),
                provide('SingletonArgsFactory').useFactory(new ArgsValidationFactory()).scope(Di.Scope.SINGLETON),
                provide('ClassProvider').useClass(ArgsValidationObject.class),
                provide('ValueProvider').useValue('val'),
                provide('ExistingProvider').useExisting('ClassProvider') // Maps to ClassProvider
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    public class ArgsValidationFactory implements Di.Factory {
        public Object newInstance(Di.Container container, Object args) {
            return args;
        }
    }

    public class ArgsValidationObject {
    }
    public class InjectedMetadataSource implements Di.MetadataSource {
        private final Iterable<Di.MetadataModuleDefinition> globalModules;
        private final Map<String, Di.ProviderDefinition> providers;

        public InjectedMetadataSource(
            final Iterable<Di.MetadataModuleDefinition> globalModules,
            final Map<String, Di.ProviderDefinition> providers
        ) {
            this.globalModules = globalModules;
            this.providers = providers;
        }

        public Map<String, Di.MetadataModuleDefinition> getModules() {
            if (globalModules == null) {
                return null;
            }
            Map<String, Di.MetadataModuleDefinition> modules = new Map<String, Di.MetadataModuleDefinition>();
            for (Di.MetadataModuleDefinition definition : globalModules) {
                modules.put(definition.developerName, definition);
            }
            return modules;
        }

        public Map<String, Di.ProviderDefinition> getProviders() {
            return providers;
        }
    }
    public class MetadataModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(IMetadataService.class).useMetadata('ConfigurableService'),
                provide('StringValue').useMetadata('StringValueProvider'),
                provide('FactoryValue').useMetadata('FactoryProviderWithArgs'),
                provide('InvalidValue').useMetadata('InvalidProvider')
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class MetadataSelectedModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('metadataSelectedValue').useValue('selected') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'metadataSelectedValue' };
        }
    }
    public class MetadataImportConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.importMetadataModule('SelectedImport') };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('metadataImportWarmup').useValue('warm') };
        }
    }
    public class MetadataConstructionCountingModule extends EmptyModule {
        public MetadataConstructionCountingModule() {
            metadataModuleInstantiationCount++;
        }
    }
    public class MetadataExistingModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                // The target provider that the metadata will point to
                provide('TargetService').useClass(TestServiceImpl.class),
                // The alias provider that will be configured by metadata
                provide('AliasService').useMetadata('AliasProvider')
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    // --- Services for Order Processing Scenario ---
    public interface IPaymentService {
        Boolean processPayment(Decimal amount);
        Boolean wasCalled();
    }
    public interface IShippingService {
        Boolean shipOrder(String orderId);
        Boolean wasShipped();
    }
    public interface INotificationService {
        Boolean sendConfirmation(String orderId);
        Boolean wasSent();
    }
    public class PaymentService implements IPaymentService {
        public Boolean wasPaid = false;
        public Boolean processPayment(Decimal amount) {
            wasPaid = true;
            return true;
        }
        public Boolean wasCalled() {
            return wasPaid;
        }
    }
    public class ShippingService implements IShippingService {
        public Boolean wasShipped = false;
        public Boolean shipOrder(String orderId) {
            wasShipped = true;
            return true;
        }
        public Boolean wasShipped() {
            return wasShipped;
        }
    }
    public class NotificationService implements INotificationService {
        public Boolean wasSent = false;
        public Boolean sendConfirmation(String orderId) {
            wasSent = true;
            return true;
        }
        public Boolean wasSent() {
            return wasSent;
        }
    }
    public class OrderService implements Di.Injectable {
        public IPaymentService paymentService { get; private set; }
        public IShippingService shippingService { get; private set; }
        public INotificationService notificationService { get; private set; }
        public void inject(Di.Container ref) {
            paymentService = (IPaymentService) ref.get(IPaymentService.class);
            shippingService = (IShippingService) ref.get(IShippingService.class);
            notificationService = (INotificationService) ref.get(INotificationService.class);
        }
        public Boolean processOrder(String orderId, Decimal amount) {
            Boolean paymentOk = paymentService.processPayment(amount);
            if (paymentOk) {
                shippingService.shipOrder(orderId);
                notificationService.sendConfirmation(orderId);
                return true;
            }
            return false;
        }
    }
    // --- Modules for Order Processing Scenario ---
    public class PaymentModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(IPaymentService.class).useClass(PaymentService.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ IPaymentService.class.getName() };
        }
    }
    public class ShippingModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(IShippingService.class).useClass(ShippingService.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ IShippingService.class.getName() };
        }
    }
    public class NotificationModule extends EmptyModule {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(INotificationService.class).useClass(NotificationService.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ INotificationService.class.getName() };
        }
    }
    public class OrderProcessingModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{
                Di.import(PaymentModule.class),
                Di.import(ShippingModule.class),
                Di.import(NotificationModule.class)
            };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(OrderService.class).useClass(OrderService.class) };
        }
    }
    // --- Services and Modules for Feature Flag Scenario ---
    public class UserExperienceService implements Di.Injectable {
        private Boolean newCheckoutFlag = false;
        public void inject(Di.Container ref) {
            try {
                newCheckoutFlag = (Boolean) ref.get('EnableNewCheckout');
            } catch (Di.UnknownProviderException e) {
                newCheckoutFlag = false; // Default to false if provider doesn't exist
            }
        }
        public Boolean isNewCheckoutEnabled() {
            return newCheckoutFlag;
        }
    }
    public class AppModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import('FeatureFlags') };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(UserExperienceService.class).useClass(UserExperienceService.class) };
        }
    }
    // --- Services and Modules for Alias Integration Scenario ---
    public interface ITransactionalEmailSender {
        String send(String recipient, String body);
    }
    public class MandrillEmailService implements ITransactionalEmailSender {
        public String send(String recipient, String body) {
            return 'Email sent via Mandrill to ' + recipient;
        }
    }
    public class EmailService implements Di.Injectable {
        private ITransactionalEmailSender sender;
        public void inject(Di.Container ref) {
            sender = (ITransactionalEmailSender) ref.get('EmailSender');
        }
        public String sendWelcomeEmail(String email) {
            return sender.send(email, 'Welcome!');
        }
    }
    public class AppWithAliasModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(MandrillEmailService.class).useClass(MandrillEmailService.class),
                provide('EmailSender').useExisting(MandrillEmailService.class), // Alias
                provide(EmailService.class).useClass(EmailService.class)
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    public class StatefulLogger {
        private final List<String> messages = new List<String>();
        public void log(String message) {
            messages.add(message);
        }
        public List<String> getMessages() {
            return messages;
        }
    }
    public class RecordProcessor implements Di.Injectable {
        private StatefulLogger logger;
        public void inject(Di.Container container) {
            logger = (StatefulLogger) container.get(StatefulLogger.class);
        }
        public void process(String recordId) {
            logger.log('Processing ' + recordId);
        }
    }
    public class RecordProcessorModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide(StatefulLogger.class).useClass(StatefulLogger.class).scope(Di.Scope.SCOPED),
                provide(RecordProcessor.class).useClass(RecordProcessor.class).scope(Di.Scope.PROTOTYPE)
            };
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }
    // --- Module for Error Condition Tests ---
    public abstract class AbstractTestModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    // --- Helpers for Scope Integrity Scenario ---
    public class ScopeRefIntegrityModule extends Di.Module {
        public ScopeRefIntegrityModule() {
            super(ScopeRefIntegrityModule.class.getName());
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide('ScopedService').useFactory(new StringFactory('A')).scope(Di.Scope.SCOPED)
            };
        }
    }

    public class ScopeRefIntegrityReplacementModule extends Di.Module {
        public ScopeRefIntegrityReplacementModule() {
            super(ScopeRefIntegrityModule.class.getName());
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide('ScopedService').useFactory(new StringFactory('B')).scope(Di.Scope.SCOPED)
            };
        }
    }

    public class StringFactory implements Di.Factory {
        private final String val;
        public StringFactory(String val) {
            this.val = val;
        }
        public Object newInstance(Di.Container c, Object args) {
            return val;
        }
    }

    public class MetadataProtoAliasModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{
                provide('PrototypeService').useClass(TestServiceImpl.class).scope(Di.Scope.PROTOTYPE),
                provide('AliasService').useMetadata('AliasProtoProvider')
            };
        }
    }
    // --- Helpers for Injection Failure Scenario ---
    public class InjectionFailureModule extends Di.Module {
        public BrokenServiceFactory factory = new BrokenServiceFactory();
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('BrokenService').useFactory(factory) };
        }
    }

    public class BrokenServiceFactory implements Di.Factory {
        public Integer instantiationCount = 0;
        public Integer injectionAttempts = 0;
        public Object newInstance(Di.Container c, Object args) {
            instantiationCount++;
            return new BrokenService(this);
        }
    }

    public class BrokenService implements Di.Injectable {
        private final BrokenServiceFactory factory;
        public BrokenService(BrokenServiceFactory factory) {
            this.factory = factory;
        }

        public void inject(Di.Container container) {
            factory.injectionAttempts++;
            throw new Di.DiException('Injection Failed Intentional');
        }
    }

    public class ConfigurableModule extends Di.Module {
        private final String value;
        public ConfigurableModule() {
            this.value = 'defaultValue';
        }
        public ConfigurableModule(String value) {
            this.value = value;
        }

        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('configVal').useValue(value) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'configVal' };
        }
    }

    public class GlobalReexportModule extends Di.Module {
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>{ Di.import(ValueModule.class) };
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    public class GlobalReexportModule2 extends Di.Module {
        public GlobalReexportModule2() {
            super(GlobalReexportModule.class.getName());
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<Di.ModuleImport> reexports() {
            return new Set<Di.ModuleImport>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    public class ScopedInjectionFailureModule extends Di.Module {
        public BrokenServiceFactory factory = new BrokenServiceFactory();
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('BrokenService').useFactory(factory).scope(Di.Scope.SCOPED) };
        }
    }
    // </editor-fold>
}
