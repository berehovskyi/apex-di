@IsTest(IsParallel=true)
@SuppressWarnings('PMD.ApexDoc')
private class DiTest {
    static {
        // A private constructor to satisfy the static-only class pattern and improve coverage.
        new Di();
        // Arrange: Clear all DI registries before each test run to ensure isolation.
        Di.clear();
        // Arrange: Mock global modules to prevent unintended loading from metadata in tests.
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());
        // Arrange: Mock providers to prevent unintended loading from metadata in tests.
        Di.mockProviders(new Map<String, DI_Provider__mdt>());
    }

    //=========================================================================
    // Core Provider Tests (get, resolve, scopes)
    //=========================================================================
    @IsTest
    static void should_return_same_instance_for_singleton_scope() {
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
    static void should_evict_from_cache_on_injection_failure() {
        // Arrange
        InjectionFailureModule module = new InjectionFailureModule();
        Di.addModule(module);
        Di.ModuleRef ref = Di.getModuleRef(InjectionFailureModule.class);

        // Act 1: First attempt fails
        try {
            ref.get('BrokenService');
            Assert.fail('Should have thrown exception');
        } catch (Di.DiException e) {
            Assert.areEqual('Injection Failed Intentional', e.getMessage());
        }

        // Act 2: Second attempt should TRY AGAIN usually creating a new instance
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
    static void should_return_new_instance_for_prototype_scope() {
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

    //=========================================================================
    // Core SCOPED Lifetime Tests
    //=========================================================================
    @IsTest
    static void should_return_same_instance_within_one_scope() {
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
    static void should_return_different_instances_for_different_scopes() {
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
    static void should_not_cache_scoped_provider() {
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

        Object instanceRoot = consumerCtn.get(ScopedService.class);
        Object instanceRoot2 = consumerCtn.get(ScopedService.class);

        Assert.areNotEqual(instance1, instanceRoot, 'Scoped instance should not define Root instance');
        Assert.areNotEqual(
            instanceRoot,
            instanceRoot2,
            'Scoped provider resolved from Root should return new instances if not strictly singleton?'
        );
    }

    @IsTest
    static void should_evict_scoped_provider_from_cache_on_injection_failure() {
        // Arrange
        ScopedInjectionFailureModule mod = new ScopedInjectionFailureModule();
        Di.ModuleRef ref = Di.addModule(mod);
        Di.ScopeRef scope = ref.createScope();

        // Act 1: First attempt fails
        try {
            scope.get('BrokenService');
            Assert.fail('Should have thrown DiException');
        } catch (Di.DiException e) {
            Assert.areEqual('Injection Failed Intentional', e.getMessage(), 'Should bubble up the injection exception');
        }

        // Act 2: Second attempt should have evicted the broken instance and try again
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
    static void should_resolve_singleton_dependency_from_a_scope() {
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
    static void should_resolve_prototype_dependency_from_a_scope() {
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
    static void should_clear_cache_for_a_specific_scope() {
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
    static void should_update_scope_when_module_is_replaced() {
        // Arrange
        Di.clear();
        Di.ModuleRef moduleRef = Di.getModuleRef(ScopeRefIntegrityModule.class);
        Di.ScopeRef scope = moduleRef.createScope();

        // Act & Assert 1: Initial resolution
        String val1 = (String) scope.resolve('ScopedService');
        Assert.areEqual('A', val1, 'Should return value from initial module');

        // Act 2: Replace Module
        Di.replaceModule(ScopeRefIntegrityModule.class, new ScopeRefIntegrityReplacementModule());

        // Act & Assert 3: Resolve again from SAME scope
        // This is the CRUX: The scope should now see the NEW module definition because we fixed ScopeRef
        String val2 = (String) scope.resolve('ScopedService');

        Assert.areEqual('B', val2, 'Should return value from replacement module');
        Assert.areNotEqual(val1, val2, 'Should not return cached value from old module');
    }

    //=========================================================================
    // Provider Types (Value, Factory, Class, Existing, Metadata)
    //=========================================================================
    @IsTest
    static void should_return_configured_value_for_value_provider() {
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
    static void should_create_value_provider_from_type() {
        // Act
        Di.ValueProvider provider = new Di.ValueProvider(TestService.class, 'hello');

        // Assert
        Assert.areEqual('DiTest.TestService', provider.getToken(), 'Token should be the class name.');
        Assert.areEqual('hello', provider.resolve(null, null), 'Should resolve the value.');
    }

    @IsTest
    static void should_return_instance_from_factory_for_factory_provider() {
        // Arrange: A module with a FactoryProvider is registered.
        Di.ModuleRef ref = Di.getModuleRef(FactoryModule.class);

        // Act: The provider is requested.
        Object svc = ref.get('svc');

        // Assert: The returned object is of the type created by the factory.
        Assert.isTrue(svc instanceof TestServiceImpl, 'Factory should produce the correct type.');
    }

    @IsTest
    static void should_create_factory_provider_from_type() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act
        Di.FactoryProvider provider = builder.useFactory(StringArgsFactory.class);

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
    static void should_create_factory_provider_from_string() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act
        Di.FactoryProvider provider = builder.useFactory(StringArgsFactory.class.getName());

        // Assert
        Assert.isNotNull(provider, 'Should return a valid provider instance.');
        Object result = provider.resolve(null, 'String');
        Assert.areEqual('arg:String', result, 'Factory created from string should work correctly.');
    }

    @IsTest
    static void should_create_factory_provider_from_various_overloads() {
        // Act & Assert
        Assert.isNotNull(
            new Di.FactoryProvider(TestService.class, new StringArgsFactory()),
            'Should create from Type token and Factory instance.'
        );
        Assert.isNotNull(
            new Di.FactoryProvider(TestService.class, StringArgsFactory.class.getName()),
            'Should create from Type token and String factory type.'
        );
        Assert.isNotNull(
            new Di.FactoryProvider(TestService.class, StringArgsFactory.class),
            'Should create from Type token and Type factory type.'
        );
    }

    @IsTest
    static void should_throw_exception_for_null_factory_string() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act & Assert
        try {
            builder.useFactory((String) null);
            Assert.fail('Expected InvalidProviderException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot instantiate class "null"'),
                'Exception message should indicate null class name.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_for_invalid_factory_string() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act & Assert
        try {
            builder.useFactory('Invalid.Class.Name');
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot instantiate class "Invalid.Class.Name"'),
                'Exception message should indicate missing class.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_for_null_factory_type() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act & Assert
        try {
            builder.useFactory((Type) null);
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot instantiate class'),
                'Exception message should indicate invalid interface.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_for_invalid_factory_type() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act & Assert
        try {
            // Using a class that exists but doesn't implement Di.Factory (e.g. TestServiceImpl or String)
            builder.useFactory(NotFactory.class);
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            Assert.isTrue(
                ex.getMessage().contains('does not implement the Di.Factory interface'),
                'Exception message should indicate invalid interface.'
            );
        }
    }

    @IsTest
    static void should_throw_exception_for_non_instantiable_factory_type() {
        // Arrange
        Di.ProviderBuilder builder = new Di.DynamicModule('TestFactory').provide('TestFactory');

        // Act & Assert
        try {
            // Di.Module is abstract, so it cannot be instantiated
            builder.useFactory(Di.Module.class);
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot instantiate class'),
                'Exception message should indicate instantiation failure.'
            );
        }
    }

    @IsTest
    static void should_pass_arguments_to_factory_provider() {
        // Arrange: A module with a FactoryProvider that accepts arguments is registered.
        Di.ModuleRef ref = Di.getModuleRef(ArgsModule.class);

        // Act: The provider is requested with arguments.
        Object out = ref.get('arg', new List<String>{ 'X' });

        // Assert: The factory correctly uses the arguments to produce the value.
        Assert.areEqual('arg:X', out, 'Arguments should be passed to and used by the factory.');
    }

    @IsTest
    static void should_get_provider_by_type_with_arguments() {
        // Arrange: A module with a factory provider is registered.
        Di.ModuleRef ref = Di.getModuleRef(ArgsTypeModule.class);

        // Act: The provider is requested by Type with arguments.
        Object result = ref.get(TestServiceImpl.class, new List<Object>{ 'Args' });

        // Assert: The factory receives the arguments and produces the correct value.
        Assert.areEqual('arg:Args', result, 'get(Type, args) should resolve the correct provider and pass arguments.');
    }

    @IsTest
    static void should_resolve_provider_by_type_with_arguments() {
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
    static void should_resolve_provider_by_type_without_arguments() {
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
    static void should_replace_existing_class_provider() {
        // Arrange: A module with a standard provider is registered using a Type token.
        Di.ModuleRef ref = Di.getModuleRef(TypeModule.class);

        // Act: The provider is resolved by Type.
        Object instance1 = ref.resolve(TestService.class);

        // Assert: Two different instances of the correct implementation are returned.
        Assert.isTrue(instance1 instanceof TestServiceImpl, 'Resolved instance should be of the correct type.');

        // Act: The provider is replaced with a new ValueProvider.
        Di.Provider newProvider = new Di.ClassProvider(TestService.class, MockService.class);
        ref.replace(newProvider);
        Object instance2 = ref.resolve(TestService.class);

        // Assert: Two different instances of the correct implementation are returned.
        Assert.isTrue(instance2 instanceof MockService, 'Resolved instance should be of the correct type.');
    }

    @IsTest
    static void should_replace_existing_provider() {
        // Arrange: A module is registered with an initial provider.
        Di.ModuleRef ref = Di.getModuleRef(ValueModule.class);
        Assert.areEqual('hello', ref.get('val'), 'Pre-condition: Initial value should be "hello".');

        // Act: The provider is replaced with a new ValueProvider.
        Di.Provider newProvider = new Di.ValueProvider('val', 'world');
        ref.replace(newProvider);

        // Assert: Getting the provider now returns the new value.
        Assert.areEqual('world', ref.get('val'), 'The provider value should be updated after replacement.');
    }

    @IsTest
    static void should_instantiate_class_by_string_name() {
        // Arrange: A module provides a class using its string name.
        Di.ModuleRef ref = Di.getModuleRef(StringTypeModule.class);

        // Act: The service is requested.
        Object svc = ref.get('svc');

        // Assert: The correct class is instantiated.
        Assert.isTrue(svc instanceof TestServiceImpl, 'The framework should instantiate a class from its string name.');
    }

    @IsTest
    static void should_create_class_provider_from_type() {
        // Arrange: A provider is created using the Type constructor overload.
        Di.ClassProvider provider1 = new Di.ClassProvider('TestService', TestServiceImpl.class);
        Di.ClassProvider provider2 = new Di.ClassProvider(TestService.class, 'DiTest.TestServiceImpl');

        // Act: The type property of the provider is inspected.
        String providerType1 = provider1.getType();
        String providerType2 = provider2.getType();

        // Assert: The type property correctly stores the string name of the class.
        Assert.areEqual(
            TestServiceImpl.class.getName(),
            providerType1,
            'ClassProvider should correctly store the type name.'
        );
        Assert.areEqual(
            TestServiceImpl.class.getName(),
            providerType2,
            'ClassProvider should correctly store the type name.'
        );
    }

    @IsTest
    static void should_create_class_provider_from_various_overloads() {
        // Act & Assert
        Assert.areEqual(
            'TestServiceImpl',
            new Di.ClassProvider(TestService.class, 'TestServiceImpl').getType(),
            'Should create from Type token and String type.'
        );
        Assert.areEqual(
            'DiTest.TestServiceImpl',
            new Di.ClassProvider(TestService.class, TestServiceImpl.class).getType(),
            'Should create from Type token and Type type.'
        );
    }

    @IsTest
    static void should_resolve_provider_using_existing_alias() {
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
    static void should_create_existing_provider_from_various_overloads() {
        // Act & Assert
        Assert.areEqual(
            'DiTest.MockService',
            new Di.ExistingProvider('TestService', MockService.class).getExisting(),
            'Should create from String token and Type existing.'
        );
        Assert.areEqual(
            'OtherService',
            new Di.ExistingProvider(TestService.class, 'OtherService').getExisting(),
            'Should create from Type token and String existing.'
        );
        Assert.areEqual(
            'DiTest.MockService',
            new Di.ExistingProvider(TestService.class, MockService.class).getExisting(),
            'Should create from Type token and Type existing.'
        );
    }

    //=========================================================================
    // Circular Dependencies
    //=========================================================================
    @IsTest
    static void should_throw_exception_for_circular_existing_alias() {
        // Arrange: A module is registered with a circular alias dependency (A -> B -> A).
        Di.ModuleRef ref = Di.getModuleRef(CircularExistingProviderModule.class);

        // Act & Assert: An attempt to get either provider should throw a CircularDependencyException.
        try {
            ref.get('AliasA');
            Assert.fail('Expected CircularDependencyException was not thrown.');
        } catch (Di.CircularDependencyException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Circular dependency detected'),
                'Exception message should indicate a cycle.'
            );
        }
    }

    @IsTest
    static void should_correctly_detect_alias_based_circular_dependency() {
        // Arrange: Get the container for the alias-based cycle.
        Di.ModuleRef container = Di.getModuleRef(AliasCircularAModule.class);

        // Act & Assert: The framework should correctly detect this cycle.
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
    static void should_detect_factory_based_circular_dependency() {
        // Arrange: Get the container for the factory-based cycle.
        Di.ModuleRef container = Di.getModuleRef(FactoryCircularAModule.class);

        // Act & Assert: Attempt to resolve the circular dependency.
        try {
            container.get(ServiceA.class);
            Assert.fail('Expected a Di.CircularDependencyException but no exception was thrown.');
        } catch (Di.CircularDependencyException e) {
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
    static void should_resolve_prototype_provider_using_existing_alias() {
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

        // Act & Assert: An attempt to get() the prototype-scoped alias should fail,
        // because get() is not allowed on prototype scopes.
        try {
            ref.get('AliasService');
            Assert.fail('Expected InvalidScopeException was not thrown. This confirms the bug.');
        } catch (Di.InvalidScopeException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Use resolve() method instead'),
                'Exception message should guide the user to use resolve().'
            );
        } catch (Exception e) {
            Assert.fail('An unexpected exception was thrown: ' + e.getMessage());
        }
    }

    @IsTest
    static void should_resolve_circular_dependency_without_forward_ref() {
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

    //=========================================================================
    // Metadata Provider Tests
    //=========================================================================
    @IsTest
    static void should_resolve_class_provider_from_mocked_metadata() {
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
    static void should_resolve_value_provider_from_metadata() {
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
    static void should_resolve_factory_provider_from_metadata_with_args() {
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
    static void should_resolve_existing_provider_from_metadata() {
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
    static void should_respect_prototype_scope_in_existing_provider() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(MetadataProtoAliasModule.class);

        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'AliasProtoProvider',
            Type__c = 'Existing',
            Value__c = 'PrototypeService',
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'AliasProtoProvider' => mockMdt });

        // Act & Assert
        Object inst1 = ref.resolve('AliasService');
        Object inst2 = ref.resolve('AliasService');

        Assert.areNotEqual(inst1, inst2, 'Existing provider pointing to Prototype should return new instances.');
    }

    @IsTest
    static void should_throw_exception_for_invalid_provider_type_in_metadata() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(MetadataModule.class);
        DI_Provider__mdt mockMdt = new DI_Provider__mdt(
            DeveloperName = 'InvalidProvider',
            Type__c = 'InvalidType', // This is not a valid provider type
            Value__c = 'any',
            IsActive__c = true
        );
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'InvalidProvider' => mockMdt });

        // Act & Assert
        try {
            ref.get('InvalidValue');
            Assert.fail('Expected InvalidProviderException was not thrown for invalid metadata type.');
        } catch (Di.InvalidProviderException e) {
            Assert.isTrue(
                e.getMessage().contains('Invalid provider configuration'),
                'Exception message should indicate an invalid configuration.'
            );
        }
    }

    @IsTest
    static void should_reset_metadata_cache_on_clear() {
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

        // Act 1: Load the first mock and resolve it. This should populate the static cache in Di.cls.
        Di.mockProviders(new Map<String, DI_Provider__mdt>{ 'ConfigurableService' => mockMdt1 });
        Object result1 = ref.resolve(IMetadataService.class);

        // Act 2: Clear the framework state. This SHOULD clear the static cache.
        Di.clear();

        // Act 3: Load the second mock and resolve it.
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
    static void should_respect_scope_defined_in_metadata() {
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
    static void should_respect_prototype_scope_in_metadata() {
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

    //=========================================================================
    // Arguments & Caching
    //=========================================================================
    @IsTest
    static void should_bypass_cache_with_args() {
        // Arrange
        Di.clear();
        Di.ModuleRef consumerCtn = Di.getModuleRef(ArgsValidationModule.class);

        // Act & Assert
        // 1. Resolve with Args "A"
        Object instanceA = consumerCtn.get('SingletonArgsFactory', 'A');
        Assert.areEqual('A', instanceA, 'Should return args as instance');

        // 2. Resolve with Args "B"
        Object instanceB = consumerCtn.get('SingletonArgsFactory', 'B');
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
        Object instanceC = consumerCtn.get('SingletonArgsFactory', 'C');
        Assert.areEqual('C', instanceC, 'Should bypass cache even if cache is populated');
    }

    @IsTest
    static void should_throw_on_args_to_non_factory() {
        // Arrange
        Di.clear();
        Di.ModuleRef consumerCtn = Di.getModuleRef(ArgsValidationModule.class);

        // Act & Assert
        // 1. ClassProvider
        try {
            consumerCtn.get('ClassProvider', 'someArgs');
            Assert.fail('Should throw exception when passing args to ClassProvider');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, Di.DiException.class, 'Should throw DiException');
            // Optionally check message if we define specific message
        }

        // 2. ValueProvider
        try {
            consumerCtn.get('ValueProvider', 'someArgs');
            Assert.fail('Should throw exception when passing args to ValueProvider');
        } catch (Exception e) {
            Assert.isNotNull(e, 'Exception should be thrown for ValueProvider with args');
        }

        // 3. ExistingProvider
        try {
            consumerCtn.get('ExistingProvider', 'someArgs');
            Assert.fail('Should throw exception when passing args to ExistingProvider');
        } catch (Exception e) {
            Assert.isNotNull(e, 'Exception should be thrown for ExistingProvider with args');
        }
    }

    //=========================================================================
    // Module System (Imports, Exports, Overrides)
    //=========================================================================
    @IsTest
    static void should_resolve_provider_for_internal_use_from_imported_module() {
        // Arrange: A module that imports another module is registered.
        Di.ModuleRef ref = Di.getModuleRef(InternalConsumerModule.class);

        // Act: The module's internal method, which uses an imported provider, is called.
        Object val = ref.get('internal');

        // Assert: The provider from the imported module was resolved and used successfully.
        Assert.areEqual('bar', val, 'Module should be able to use providers from its imports.');
    }

    @IsTest
    static void should_allow_local_provider_to_override_imported_provider() {
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
    static void should_share_singleton_export_between_multiple_importing_modules() {
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
    static void should_resolve_exported_provider_with_private_dependency_from_owner_module() {
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
    static void should_resolve_exported_provider_and_alias_through_owner_context() {
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
    static void should_not_resolve_exported_provider_with_consumer_only_dependency() {
        // Arrange: The owner exports a facade, while the consumer separately imports the facade dependency.
        Di.ModuleRef consumerRef = Di.getModuleRef(ConsumerOnlyDependencyConsumerModule.class);

        // Act & Assert: Exported providers should not inherit the consumer module's import visibility.
        try {
            consumerRef.get(ExportedConsumerOnlyFacade.class);
            Assert.fail('Expected UnknownProviderException was not thrown.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains(ConsumerOnlyDependencyService.class.getName()),
                'The exported provider should not see dependencies imported only by its consumer.'
            );
        }
    }

    @IsTest
    static void should_scope_exported_provider_within_importing_scope() {
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
    static void should_handle_circular_imports_gracefully() {
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
            Di.addModule(failingModule);
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
        Di.DynamicModule validRetry = new Di.DynamicModule(failedToken).setGlobal();
        validRetry.addProvider(validRetry.provide('globalRetryValue').useValue('registered'))
            .addExport('globalRetryValue');
        Di.addModule(validRetry);

        // Assert: The failed global attempt did not poison the global module registry.
        Assert.areEqual(
            'registered',
            Di.getModuleRef(EmptyModule.class).get('globalRetryValue'),
            'A failed global registration should not block a clean retry with the same module token.'
        );
    }

    @IsTest
    static void should_get_module_ref_by_instance() {
        // Arrange: A module instance is created but not yet registered.
        Di.Module mod = new ValueModule();

        // Act: The module reference is retrieved using the instance itself.
        Di.ModuleRef ref = Di.getModuleRef(mod);

        // Assert: The module is now registered and its providers are resolvable.
        Assert.isNotNull(ref, 'getModuleRef by instance should return a valid reference.');
        Assert.areEqual('hello', ref.get('val'), 'Provider should be resolvable from module registered by instance.');
    }

    @IsTest
    static void should_return_existing_ref_for_registered_module_instance() {
        // Arrange: A local module and a global module are registered.
        Di.Module localMod = new ValueModule();
        Di.ModuleRef localRef1 = Di.addModule(localMod);
        Di.DynamicModule globalMod = new Di.DynamicModule('G').setGlobal();
        Di.ModuleRef globalRef1 = Di.addModule(globalMod);

        // Act: getModuleRef is called again with the same instances.
        Di.ModuleRef localRef2 = Di.getModuleRef(localMod);
        Di.ModuleRef globalRef2 = Di.getModuleRef(globalMod);

        // Assert: The returned references are the same as the initially registered ones.
        Assert.areEqual(localRef1, localRef2, 'Should return existing ref for local module instance.');
        Assert.areEqual(globalRef1, globalRef2, 'Should return existing ref for global module instance.');
    }

    @IsTest
    static void should_evaluate_module_equality_based_on_token() {
        // Arrange: Create two modules with the same token and one with a different token.
        Di.Module moduleA1 = new Di.DynamicModule('ModuleA');
        Di.Module moduleA2 = new Di.DynamicModule('ModuleA');
        Di.Module moduleB = new Di.DynamicModule('ModuleB');

        // Act & Assert: Check equality and hash code consistency.
        Assert.isTrue(moduleA1.equals(moduleA2), 'Modules with the same token should be equal.');
        Assert.areEqual(moduleA1.hashCode(), moduleA2.hashCode(), 'Hash codes for equal modules should be the same.');
        Assert.isFalse(moduleA1.equals(moduleB), 'Modules with different tokens should not be equal.');
        Assert.isFalse(moduleA1.equals('some string'), 'Module should not be equal to an object of a different type.');
        Assert.isFalse(moduleA1.equals(null), 'Module should not be equal to null.');
    }

    @IsTest
    static void should_correctly_report_has_provider_import_and_export() {
        // Arrange: Get modules with different configurations to test each method.
        Di.Module modWithImport = Di.getModuleRef(InternalConsumerModule.class).getModule();
        Di.Module modWithProvider = Di.getModuleRef(SingleModule.class).getModule();
        Di.Module modWithExport = Di.getModuleRef(ValueModule.class).getModule();

        // Act & Assert: Test hasProvider() for locally defined providers.
        Assert.isTrue(modWithProvider.hasProvider('TestService'), 'Should report having a local provider.');
        Assert.isFalse(
            modWithImport.hasProvider('foo'),
            'hasProvider should only check local providers, not imported ones.'
        );
        Assert.isFalse(modWithProvider.hasProvider('non_existent'), 'Should report not having a provider.');

        // Act & Assert: Test hasImport().
        Assert.isTrue(modWithImport.hasImport(BModule.class.getName()), 'Should report having an import.');
        Assert.isFalse(modWithProvider.hasImport(BModule.class.getName()), 'Should report not having an import.');

        // Act & Assert: Test hasExport().
        Assert.isTrue(modWithExport.hasExport('val'), 'Should report having an export.');
        Assert.isFalse(modWithImport.hasExport('foo'), 'Should report not having an export.');
    }

    //=========================================================================
    // Module Re-Exporting Tests
    //=========================================================================
    @IsTest
    static void should_resolve_provider_from_reexported_module() {
        // Arrange: ModuleA imports ModuleB, which imports and re-exports ModuleC.
        Di.ModuleRef ref = Di.getModuleRef(ReexportConsumerModule.class);

        // Act: A provider from the deepest module (ModuleC) is requested from the top-level module.
        Object val = ref.get('serviceC');

        // Assert: The provider is resolved successfully because ModuleB re-exported ModuleC.
        Assert.areEqual('c-service', val, 'Provider should be visible through a re-exporting module.');
    }

    @IsTest
    static void should_not_resolve_provider_if_not_reexported() {
        // Arrange: ModuleA imports ModuleB, which imports but does NOT re-export ModuleC.
        Di.ModuleRef ref = Di.getModuleRef(NonReexportConsumerModule.class);

        // Act & Assert: An attempt to get a provider from ModuleC should fail.
        try {
            ref.get('serviceC');
            Assert.fail('Expected UnknownProviderException was not thrown.');
        } catch (Di.UnknownProviderException ex) {
            // This is expected because ModuleB encapsulates ModuleC's providers.
            Assert.isTrue(
                ex.getMessage().contains('Could not find "serviceC" provider'),
                'Provider should not be visible without being re-exported.'
            );
        }
    }

    @IsTest
    static void should_reexport_from_dynamic_module() {
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
    static void should_resolve_provider_through_transitive_reexport() {
        // Arrange: A consumer imports a reexporter that reexports another reexporting module.
        Di.ModuleRef ref = Di.getModuleRef(TransitiveReexportConsumerModule.class);

        // Act: A provider from the deepest module is requested from the top-level consumer.
        Object val = ref.get('serviceD');

        // Assert: Computed exports should flow through more than one reexport layer.
        Assert.areEqual('d-service', val, 'Provider should be visible through transitive reexports.');
    }

    @IsTest
    static void should_detect_circular_reexports_during_registration() {
        // Arrange / Act: A pair of modules reexport each other.
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

    //=========================================================================
    // Lazy vs. Eager Imports
    //=========================================================================
    @IsTest
    static void should_delay_module_resolution_for_lazy_import() {
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
    static void should_resolve_module_immediately_for_immediate_import() {
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
    static void should_throw_exception_at_runtime_for_missing_lazy_import() {
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
    static void should_throw_exception_on_immediately_call_for_missing_import() {
        // Arrange: An import for a non-existent module is created.
        Di.ModuleImport invalidImport = Di.import('NonExistent.Module');

        // Act: The immediately() method is called, which triggers immediate resolution.
        try {
            invalidImport.immediately();
            Assert.fail('Expected UnknownModuleException was not thrown.');
        } catch (Di.UnknownModuleException ex) {
            // Assert: The exception is thrown during the immediately() call.
            Assert.isTrue(
                ex.getMessage().contains('Cannot find module "NonExistent.Module"'),
                'Error should be thrown on immediately() call.'
            );
        }
    }

    @IsTest
    static void should_resolve_immediately_for_module_instance_import() {
        // Arrange: A module instance is created and used in an immediate import.
        Di.Module mod = new ValueModule();
        Di.ModuleImport moduleImport = Di.import(mod).immediately();

        // Act: The provider is fetched from the resolved module.
        Object val = moduleImport.resolve().getProvider('val');

        // Assert: The provider is resolved correctly.
        Assert.isNotNull(val, 'Provider should be available from an immediate import of a module instance.');
    }

    @IsTest
    static void should_evaluate_module_import_equality_with_other_types() {
        // Arrange: A module import is created.
        Di.ModuleImport importA = Di.import('ModuleA');

        // Act & Assert: Check equality against null and other object types.
        Assert.isFalse(importA.equals(null), 'ModuleImport should not be equal to null.');
        Assert.isFalse(importA.equals('some string'), 'ModuleImport should not be equal to a string.');
    }

    @IsTest
    static void should_evaluate_module_import_equality_based_on_token() {
        // Arrange: Create two imports with the same token and one with a different token.
        Di.ModuleImport importA1 = Di.import('ModuleA');
        Di.ModuleImport importA2 = Di.import(new Di.DynamicModule('ModuleA'));
        Di.ModuleImport importB = Di.import('ModuleB');

        // Act & Assert: Check equality based on the resolved token.
        Assert.isTrue(importA1.equals(importA2), 'ModuleImports with the same token should be equal.');
        Assert.isFalse(importA1.equals(importB), 'ModuleImports with different tokens should not be equal.');
    }

    //=========================================================================
    // Global Modules
    //=========================================================================
    @IsTest
    static void should_load_and_resolve_provider_from_cmt_global_module() {
        // Arrange: A mock CMT record is created to define a global module.
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = CmtGlobalModule.class.getName(), IsActive__c = true)
            }
        );
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);

        // Act: The consumer requests a provider that only exists in the CMT-defined global module.
        Object val = consumerRef.get('cmtGlobalVal');

        // Assert: The provider is resolved from the global cache loaded from the mocked CMT.
        Assert.areEqual('helloFromCmt', val, 'Consumer should find providers from CMT global modules.');
    }

    @IsTest
    static void should_rollback_and_retry_global_metadata_load_after_failure() {
        // Arrange: A consumer exists before global metadata loading is triggered.
        Di.ModuleRef consumerRef = Di.addModule(new EmptyModule());
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = CmtGlobalModule.class.getName(), IsActive__c = true),
                new DI_GlobalModule__mdt(ModuleClass__c = 'DiTest.MissingGlobalModule', IsActive__c = true)
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
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = CmtGlobalModule.class.getName(), IsActive__c = true)
            }
        );
        Di.getModuleRef(CmtGlobalModule.class.getName());

        // Assert: The corrected global metadata is now visible.
        Assert.areEqual('helloFromCmt', consumerRef.get('cmtGlobalVal'), 'Global loading should retry after failure.');
    }

    @IsTest
    static void should_prioritize_local_provider_over_global_provider() {
        // Arrange: A global module is defined via mocked CMT, and a local module provides a conflicting token.
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = OverrideGlobalModule.class.getName(), IsActive__c = true)
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
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = CmtGlobalModule.class.getName(), IsActive__c = true)
            }
        );
        Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal');

        // Act: An attempt is made to add another global module with the same token programmatically.
        try {
            Di.addModule(new CmtGlobalModule());
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
    static void should_return_existing_ref_for_registered_global_module_by_token() {
        // Arrange: A global module is loaded via CMT mock, and its ref is retrieved once to ensure it's in the registry.
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = CmtGlobalModule.class.getName(), IsActive__c = true)
            }
        );
        Di.ModuleRef ref1 = Di.getModuleRef(CmtGlobalModule.class.getName());

        // Act: The module reference is requested a second time using the same string token.
        Di.ModuleRef ref2 = Di.getModuleRef(CmtGlobalModule.class.getName());

        // Assert: The same ModuleRef instance is returned, hitting the `globalRegistry.get(token)` line.
        Assert.areEqual(ref1, ref2, 'Should return the existing ModuleRef from the global registry.');
    }

    @IsTest
    static void should_expose_reexported_providers_globally() {
        // Arrange: A global module re-exports the ValueModule's 'val' provider.
        // It does NOT explicitly list it in exports(), relying on re-export logic.
        Di.addModule(new GlobalReexportModule());

        // Act: A consumer requests the re-exported global provider.
        Di.ModuleRef consumer = Di.getModuleRef(EmptyModule.class);
        Object val = consumer.get('val');

        // Assert: The provider should be resolvable globally.
        Assert.areEqual('hello', val, 'Global modules should expose re-exported providers to the global scope.');
    }

    @IsTest
    static void should_reset_loading_flag_on_clear() {
        // Arrange: Mock and Load
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(DeveloperName = 'M', ModuleClass__c = 'DiTest.EmptyModule')
            }
        );
        Di.getModuleRef(EmptyModule.class);

        Assert.isTrue(Di.hasGlobalLoadBeenAttempted, 'Should be true after load');

        // Act
        Di.clear();

        // Assert: The flag MUST be reset to false to allow subsequent loads (e.g., from real metadata)
        Assert.isFalse(Di.hasGlobalLoadBeenAttempted, 'Should be reset to false after clear()');
    }

    @IsTest
    static void should_remove_reexported_providers_on_module_replacement() {
        // Arrange: Start with a global module that re-exports 'val'
        Di.addModule(new GlobalReexportModule());

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
            consumer.get('val');
            Assert.fail('Should have thrown UnknownProviderException because val should be removed from global scope');
        } catch (Di.UnknownProviderException e) {
            Assert.isNotNull(e, 'Expected UnknownProviderException');
        }
    }

    //=========================================================================
    // Dynamic Module Tests
    //=========================================================================
    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
    static void should_build_module_with_dynamic_providers_and_exports() {
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
    static void should_build_module_with_dynamic_imports() {
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
    static void should_use_cached_module_instance_for_import() {
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
    static void should_register_dynamic_module_as_global() {
        // Arrange: A dynamic module is configured and marked as global.
        Di.DynamicModule dynGlobal = new Di.DynamicModule('MyDynamicGlobal');
        dynGlobal.setGlobal()
            .addProvider(dynGlobal.provide('dynGlobalVal').useValue('is-global'))
            .addExport('dynGlobalVal');
        Di.addModule(dynGlobal);
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);

        // Act: A separate consumer module requests the provider from the dynamic global module.
        Object val = consumerRef.get('dynGlobalVal');

        // Assert: The provider is resolved from the global cache.
        Assert.areEqual('is-global', val, 'Provider from dynamic global module should be globally available.');
    }

    @IsTest
    static void should_update_global_dynamic_module_exports_when_refreshed() {
        // Arrange: A global dynamic module is registered with one exported provider.
        Di.DynamicModule dynGlobal = new Di.DynamicModule('RefreshableGlobalDynamic').setGlobal();
        dynGlobal.addProvider(dynGlobal.provide('globalRefreshValue').useValue('initial'))
            .addExport('globalRefreshValue');
        Di.ModuleRef globalRef = Di.addModule(dynGlobal);
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);
        Assert.areEqual('initial', consumerRef.get('globalRefreshValue'), 'Pre-condition: global export is visible.');

        // Act: Existing and newly exported global providers are changed, then the global module is refreshed.
        dynGlobal.addProvider(dynGlobal.provide('globalRefreshValue').useValue('updated'));
        dynGlobal.addProvider(dynGlobal.provide('globalRefreshAdded').useValue('added'))
            .addExport('globalRefreshAdded');
        globalRef.refresh();

        // Assert: Global consumers should see the refreshed export map and provider bindings.
        Assert.areEqual(
            'updated',
            consumerRef.get('globalRefreshValue'),
            'Existing global exports should point to the refreshed provider binding.'
        );
        Assert.areEqual(
            'added',
            consumerRef.get('globalRefreshAdded'),
            'New exports from refreshed global modules should become globally visible.'
        );
    }

    @IsTest
    static void should_update_container_when_dynamic_module_is_refreshed() {
        // Arrange: A dynamic module is registered, initially without a specific provider.
        Di.DynamicModule dyn = new Di.DynamicModule('RefreshableModule');
        Di.ModuleRef ref = Di.addModule(dyn);
        try {
            ref.get('newValue');
            Assert.fail('Provider should not exist before being added and refreshed.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Could not find "newValue" provider'),
                'The initial exception message should be correct.'
            );
        }

        // Act: A new provider is added to the module instance, and the container is refreshed.
        dyn.addProvider(dyn.provide('newValue').useValue('refreshed'));
        dyn.addExport('newValue');
        ref.refresh();

        // Assert: The new provider is now available through the original module reference.
        Assert.areEqual('refreshed', ref.get('newValue'), 'Provider should be available after refresh.');
    }

    @IsTest
    static void should_evaluate_provider_equality_based_on_token() {
        // Arrange: Create two different provider types with the same token, and one with a different token.
        Di.Provider providerA1 = new Di.ValueProvider('tokenA', 'value');
        Di.Provider providerA2 = new Di.ClassProvider('tokenA', 'SomeType');
        Di.Provider providerB = new Di.ValueProvider('tokenB', 'value');

        // Act & Assert: Check equality based on the token.
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

    //=========================================================================
    // Edge Cases and Error Handling
    //=========================================================================
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
    static void should_call_inject_method_on_injectable_class() {
        // Arrange: A module provides a class that implements the Injectable interface.
        Di.ModuleRef ref = Di.getModuleRef(InjectableModule.class);

        // Act: The provider is requested, which triggers its instantiation.
        FooInjectable instance = (FooInjectable) ref.get(FooInjectable.class);

        // Assert: The inject() method on the class was called.
        Assert.isTrue(instance.wasInjected, 'The inject() method should be called after instantiation.');
    }

    @IsTest
    static void should_manually_inject_dependencies() {
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
    static void should_throw_exception_on_manual_injection_of_non_injectable() {
        // Arrange
        Di.ModuleRef ref = Di.getModuleRef(InjectableModule.class);
        Object nonInjectable = new TestServiceImpl(); // Implements TestService, NOT Injectable

        // Act & Assert
        try {
            ref.inject(nonInjectable);
            Assert.fail('Expected InvalidClassException was not thrown.');
        } catch (Di.InvalidClassException ex) {
            Assert.isTrue(
                ex.getMessage().contains('implement the Di.Injectable interface'),
                'Exception message should warn about missing interface.'
            );
        }
    }

    @IsTest
    static void should_clear_all_registries_and_caches() {
        // Arrange: A local module is added and a global module is loaded and verified.
        Di.addModule(new ValueModule());
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = CmtGlobalModule.class.getName(), IsActive__c = true)
            }
        );
        Assert.areEqual(
            'helloFromCmt',
            Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal'),
            'Pre-condition: global provider must be available.'
        );

        // Act: The clear() method is called.
        Di.clear();
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

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
    static void should_replace_module_and_update_providers() {
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
    static void should_refresh_existing_module_ref_when_local_module_is_replaced() {
        // Arrange: A local module ref is held before the module is replaced.
        SingleModule module = new SingleModule();
        Di.ModuleRef ref = Di.addModule(module);
        Assert.isTrue(ref.get('TestService') instanceof TestServiceImpl);
        Di.DynamicModule replacement = new Di.DynamicModule(module.getToken());
        replacement.addProvider(replacement.provide('TestService').useValue('replaced')).addExport('TestService');

        // Act: The module is replaced while the old ref is still in use.
        Di.replaceModule(module.getToken(), replacement);

        // Assert: The old ref observes the replacement instead of serving stale providers/cache.
        Object result = ref.get('TestService');
        Assert.isTrue(result instanceof String, 'Existing refs should observe local module replacement.');
        Assert.areEqual('replaced', (String) result, 'Existing refs should serve replacement providers.');
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

        // Assert: Dependent singleton caches are invalidated after local replacement.
        Assert.areEqual(
            'depends on replaced',
            consumerRef.get('dependentVal'),
            'Dependent singleton providers should be rebuilt after local module replacement.'
        );
    }

    @IsTest
    static void should_reject_module_replacement_with_mismatched_token() {
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
    static void should_throw_exception_when_replacing_module_with_scope_mismatch() {
        // Arrange: A local module is registered.
        SingleModule module = new SingleModule();
        Di.addModule(module);
        Di.DynamicModule globalReplacement = new Di.DynamicModule(module.getToken()).setGlobal();

        // Act: An attempt is made to replace the local module with a global one.
        try {
            Di.replaceModule(module.getToken(), globalReplacement);
            Assert.fail('Expected InvalidModuleException was not thrown.');
        } catch (Di.InvalidModuleException ex) {
            // Assert: The correct exception is thrown.
            Assert.isTrue(
                ex.getMessage().contains('must have the same scope'),
                'Error should indicate a scope mismatch.'
            );
        }
    }

    @IsTest
    static void should_replace_global_module_and_update_global_providers() {
        // Arrange: A global module is loaded via CMT mock and its provider is verified.
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = CmtGlobalModule.class.getName(), IsActive__c = true)
            }
        );
        Assert.areEqual('helloFromCmt', Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal'));
        Di.DynamicModule newGlobalModule = new Di.DynamicModule(CmtGlobalModule.class.getName()).setGlobal();
        newGlobalModule.addProvider(newGlobalModule.provide('cmtGlobalVal').useValue('new-value'));
        newGlobalModule.addExport('cmtGlobalVal');

        // Act: The global module is replaced.
        Di.replaceModule(CmtGlobalModule.class.getName(), newGlobalModule);

        // Assert: The global provider now returns the value from the new module.
        Assert.areEqual('new-value', Di.getModuleRef(EmptyModule.class).get('cmtGlobalVal'));
    }

    @IsTest
    static void should_ignore_inactive_cmt_global_modules() {
        // Arrange: A global module is defined as inactive in a mocked CMT record.
        Di.mockGlobalModules(
            new List<DI_GlobalModule__mdt>{
                new DI_GlobalModule__mdt(ModuleClass__c = CmtGlobalModule.class.getName(), IsActive__c = false)
            }
        );
        Di.ModuleRef consumerRef = Di.getModuleRef(EmptyModule.class);

        // Act & Assert: An attempt to get the provider from the inactive module throws an exception.
        try {
            consumerRef.get('cmtGlobalVal');
            Assert.fail('Expected provider from inactive global module to be unavailable.');
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('Could not find "cmtGlobalVal" provider'));
        }
    }

    @IsTest
    static void should_throw_exception_when_creating_abstract_module() {
        // Arrange: An abstract module class that cannot be instantiated.
        // Act & Assert: Attempting to get a ref to this module should fail.
        try {
            Di.getModuleRef(AbstractTestModule.class);
            Assert.fail('Expected InvalidModuleException was not thrown.');
        } catch (Di.InvalidModuleException e) {
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

        // Act & Assert: Directly calling resolve() on an ExistingProvider should be disallowed.
        try {
            provider.resolve(ref, null);
            Assert.fail('Expected InvalidProviderException was not thrown.');
        } catch (Di.InvalidProviderException e) {
            // This confirms the defensive exception in ExistingProvider.resolve() is working.
            Assert.isTrue(
                e.getMessage().contains('This operation is not supported'),
                'Exception message should indicate the operation is invalid for this provider type.'
            );
        }
    }

    //=========================================================================
    // Integration Scenarios
    //=========================================================================
    @IsTest
    static void should_process_order_using_injected_services() {
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
    static void should_dynamically_configure_and_refresh_a_feature_flag_module() {
        // Arrange: A dynamic module for feature flags is registered, initially empty.
        Di.DynamicModule featureFlagsModule = new Di.DynamicModule('FeatureFlags');
        Di.ModuleRef featureFlagsRef = Di.addModule(featureFlagsModule);
        Di.ModuleRef appRef = Di.getModuleRef(AppModule.class);
        UserExperienceService uxService = (UserExperienceService) appRef.get(UserExperienceService.class);
        Assert.isFalse(uxService.isNewCheckoutEnabled(), 'Pre-condition: New checkout should be disabled initially.');

        // Act: A feature flag is enabled at runtime, and the module container is refreshed.
        featureFlagsModule.addProvider(featureFlagsModule.provide('EnableNewCheckout').useValue(true));
        featureFlagsModule.addExport('EnableNewCheckout');
        featureFlagsRef.refresh();
        appRef.refresh(); // Refresh the dependent module to clear its cache

        // Assert: The service now correctly reflects the enabled feature flag.
        UserExperienceService newUxService = (UserExperienceService) appRef.get(UserExperienceService.class);
        Assert.isTrue(
            newUxService.isNewCheckoutEnabled(),
            'New checkout should be enabled after refreshing the feature flag module.'
        );
    }

    @IsTest
    static void should_provide_short_alias_for_long_service_name() {
        // Arrange: The main application module is registered, which uses an alias internally.
        Di.ModuleRef ref = Di.getModuleRef(AppWithAliasModule.class);
        EmailService emailService = (EmailService) ref.get(EmailService.class);

        // Act: The high-level service method is called.
        String result = emailService.sendWelcomeEmail('test@example.com');

        // Assert: The result confirms that the aliased dependency was correctly injected and used.
        Assert.areEqual('Email sent via Mandrill to test@example.com', result);
    }

    @IsTest
    static void should_isolate_state_in_trigger_handler_simulation() {
        // Arrange: Register the module for our simulation.
        Di.ModuleRef rootContainer = Di.getModuleRef(RecordProcessorModule.class);

        // Act & Assert for Record 1
        // --- Start Unit of Work 1 ---
        Di.ScopeRef scope1 = rootContainer.createScope();
        RecordProcessor processor1 = (RecordProcessor) scope1.resolve(RecordProcessor.class);
        processor1.process('Record-001');
        // The logger is retrieved from the same scope to check its state.
        StatefulLogger logger1 = (StatefulLogger) scope1.get(StatefulLogger.class);
        Assert.areEqual(1, logger1.getMessages().size(), 'Logger 1 should have 1 message.');
        Assert.isTrue(logger1.getMessages()[0].contains('Record-001'), 'Logger 1 message should be for Record-001.');
        // --- End Unit of Work 1 ---

        // Act & Assert for Record 2
        // --- Start Unit of Work 2 ---
        Di.ScopeRef scope2 = rootContainer.createScope();
        RecordProcessor processor2 = (RecordProcessor) scope2.resolve(RecordProcessor.class);
        processor2.process('Record-002');
        StatefulLogger logger2 = (StatefulLogger) scope2.get(StatefulLogger.class);
        Assert.areEqual(1, logger2.getMessages().size(), 'Logger 2 should have 1 message.');
        Assert.isTrue(logger2.getMessages()[0].contains('Record-002'), 'Logger 2 message should be for Record-002.');
        // --- End Unit of Work 2 ---

        // Final Assert: Ensure the loggers were different instances.
        Assert.areNotEqual(logger1, logger2, 'Loggers from different scopes should be different instances.');
    }

    //=========================================================================
    // Test-Specific Inner Classes
    //=========================================================================
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
    public class OverrideModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(BModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('foo').useValue('override') };
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
        public override Boolean isGlobal() {
            return true;
        }
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
    public class LazyErrorConsumerModule extends EmptyModule {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import('NonExistent.Module') };
        }
    }

    // --- Modules for Global CMT Tests ---
    public class CmtGlobalModule extends EmptyModule {
        public override Boolean isGlobal() {
            return true;
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('cmtGlobalVal').useValue('helloFromCmt') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'cmtGlobalVal' };
        }
    }
    public class OverrideGlobalModule extends EmptyModule {
        public override Boolean isGlobal() {
            return true;
        }
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
        public GlobalReexportModule() {
            isGlobal = true;
        }
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
            isGlobal = true;
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
}
