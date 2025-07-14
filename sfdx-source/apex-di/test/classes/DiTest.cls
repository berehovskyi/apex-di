@IsTest(IsParallel=true)
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc, PMD.CyclomaticComplexity')
private class DiTest {
    // A private constructor to satisfy the static-only class pattern and improve coverage.
    static {
        new Di();
    }

    //=========================================================================
    // Setup Method
    //=========================================================================
    @TestSetup
    static void setup() {
        // Arrange: Clear all DI registries before each test run to ensure isolation.
        Di.clear();
        // Arrange: Mock global modules to prevent unintended loading from metadata in tests.
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());
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
    // Provider Types (Value, Factory, Class)
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
    static void should_return_instance_from_factory_for_factory_provider() {
        // Arrange: A module with a FactoryProvider is registered.
        Di.ModuleRef ref = Di.getModuleRef(FactoryModule.class);

        // Act: The provider is requested.
        Object svc = ref.get('svc');

        // Assert: The returned object is of the type created by the factory.
        Assert.isTrue(svc instanceof TestServiceImpl, 'Factory should produce the correct type.');
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
        String providerType1 = provider1.type;
        String providerType2 = provider2.type;

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

        // Assert: The locally defined provider takes precedence.
        Assert.areEqual('override', val, 'Local provider should always override an imported one.');
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

    //=========================================================================
    // Dynamic Module Tests
    //=========================================================================
    @IsTest
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
    static void should_throw_exception_for_unsupported_provider_type() {
        // Arrange: A module uses a custom, unsupported provider type.
        Di.ModuleRef ref = Di.getModuleRef(InvalidProviderTypeModule.class);

        // Act & Assert: An attempt to get the provider throws the correct configuration error.
        try {
            ref.get('invalid');
            Assert.fail('Expected InvalidProviderException for unsupported provider type.');
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Invalid provider configuration'),
                'Error should indicate an invalid provider config.'
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
    static void should_throw_exception_when_replacing_module_with_scope_mismatch() {
        // Arrange: A local module is registered.
        Di.addModule(new SingleModule());
        Di.DynamicModule globalReplacement = new Di.DynamicModule(new SingleModule().getToken()).setGlobal();

        // Act: An attempt is made to replace the local module with a global one.
        try {
            Di.replaceModule(SingleModule.class, globalReplacement);
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

    // --- Factory Implementations ---
    public class TestFactory implements Di.Factory {
        public Object newInstance(Di.ModuleRef ref, Object args) {
            return new TestServiceImpl();
        }
    }
    public class ArgsFactory implements Di.Factory {
        public Object newInstance(Di.ModuleRef ref, Object args) {
            return 'arg:' + (args != null ? ((List<Object>) args)[0] : '');
        }
    }
    public class InternalConsumerFactory implements Di.Factory {
        public Object newInstance(Di.ModuleRef ref, Object args) {
            return ref.get('foo');
        }
    }
    public class DependentProviderFactory implements Di.Factory {
        public Object newInstance(Di.ModuleRef ref, Object args) {
            String importedValue = (String) ref.get('val');
            return 'depends on ' + importedValue;
        }
    }

    // --- Injectable Implementation ---
    public class FooInjectable implements Di.Injectable {
        public Boolean wasInjected = false;
        public void inject(final Di.ModuleRef c) {
            wasInjected = true;
        }
    }

    // --- Basic Module Definitions ---
    public class EmptyModule extends Di.Module {
    }
    public class SingleModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('TestService').useClass(TestServiceImpl.class) };
        }
    }
    public class PrototypeModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('p').useClass(TestServiceImpl.class).scope(Di.Scope.PROTOTYPE) };
        }
    }
    public class ValueModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('val').useValue('hello') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'val' };
        }
    }
    public class FactoryModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('svc').useFactory(new TestFactory()) };
        }
    }
    public class ArgsModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('arg').useFactory(new ArgsFactory()) };
        }
    }
    public class StringTypeModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('svc').useClass('DiTest.TestServiceImpl') };
        }
    }
    public class InjectableModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(FooInjectable.class).useClass(FooInjectable.class) };
        }
    }
    public class TypeModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(TestService.class).useClass(TestServiceImpl.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ TestService.class.getName() };
        }
    }
    public class ArgsTypeModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(TestServiceImpl.class).useFactory(new ArgsFactory()) };
        }
        public override Set<String> exports() {
            return new Set<String>{ TestServiceImpl.class.getName() };
        }
    }

    // --- Modules for Import/Export Tests ---
    public class BModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('foo').useValue('bar') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo' };
        }
    }
    public class InternalConsumerModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(BModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('internal').useFactory(new InternalConsumerFactory()) };
        }
    }
    public class OverrideModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(BModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('foo').useValue('override') };
        }
    }

    // --- Modules for Error Condition Tests ---
    public class LocalErrorModule extends Di.Module {
        public override Set<String> exports() {
            return new Set<String>{ 'missing' };
        }
    }
    public class AbstractProviderModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('abs').useClass(AbstractService.class) };
        }
    }
    public class CircularA extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularB.class) };
        }
    }
    public class CircularB extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularC.class) };
        }
    }
    public class CircularC extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularA.class) };
        }
    }
    public class ReplacementModule extends Di.Module {
        public ReplacementModule() {
            super('SingleModule');
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('TestService').useValue('replaced') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'TestService' };
        }
    }
    public class LazyConsumerModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ValueModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('dependentVal').useFactory(new DependentProviderFactory()) };
        }
    }
    public class ImmediateConsumerModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(ValueModule.class).immediately() };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('dependentVal').useFactory(new DependentProviderFactory()) };
        }
    }
    public class LazyErrorConsumerModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import('NonExistent.Module') };
        }
    }

    // --- Modules for Global CMT Tests ---
    public class CmtGlobalModule extends Di.Module {
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
    public class OverrideGlobalModule extends Di.Module {
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
    public class LocalOverrideModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('val').useValue('local') };
        }
    }
    public class SelfImportingModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(SelfImportingModule.class) };
        }
    }
    public class InvalidProvider extends Di.Provider {
        public InvalidProvider() {
            super('invalid');
        }
    }
    public class InvalidProviderTypeModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ new InvalidProvider() };
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
            this.wasPaid = true;
            return true;
        }
        public Boolean wasCalled() {
            return this.wasPaid;
        }
    }
    public class ShippingService implements IShippingService {
        public Boolean wasShipped = false;
        public Boolean shipOrder(String orderId) {
            this.wasShipped = true;
            return true;
        }
        public Boolean wasShipped() {
            return this.wasShipped;
        }
    }
    public class NotificationService implements INotificationService {
        public Boolean wasSent = false;
        public Boolean sendConfirmation(String orderId) {
            this.wasSent = true;
            return true;
        }
        public Boolean wasSent() {
            return this.wasSent;
        }
    }
    public class OrderService implements Di.Injectable {
        public IPaymentService paymentService { get; private set; }
        public IShippingService shippingService { get; private set; }
        public INotificationService notificationService { get; private set; }
        public void inject(Di.ModuleRef ref) {
            this.paymentService = (IPaymentService) ref.get(IPaymentService.class);
            this.shippingService = (IShippingService) ref.get(IShippingService.class);
            this.notificationService = (INotificationService) ref.get(INotificationService.class);
        }
        public Boolean processOrder(String orderId, Decimal amount) {
            Boolean paymentOk = this.paymentService.processPayment(amount);
            if (paymentOk) {
                this.shippingService.shipOrder(orderId);
                this.notificationService.sendConfirmation(orderId);
                return true;
            }
            return false;
        }
    }
    // --- Modules for Order Processing Scenario ---
    public class PaymentModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(IPaymentService.class).useClass(PaymentService.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ IPaymentService.class.getName() };
        }
    }
    public class ShippingModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(IShippingService.class).useClass(ShippingService.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ IShippingService.class.getName() };
        }
    }
    public class NotificationModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(INotificationService.class).useClass(NotificationService.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ INotificationService.class.getName() };
        }
    }
    public class OrderProcessingModule extends Di.Module {
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
        public void inject(Di.ModuleRef ref) {
            try {
                this.newCheckoutFlag = (Boolean) ref.get('EnableNewCheckout');
            } catch (Di.UnknownProviderException e) {
                this.newCheckoutFlag = false; // Default to false if provider doesn't exist
            }
        }
        public Boolean isNewCheckoutEnabled() {
            return this.newCheckoutFlag;
        }
    }
    public class AppModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import('FeatureFlags') };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(UserExperienceService.class).useClass(UserExperienceService.class) };
        }
    }
}
