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
    static void should_instantiate_class_by_string_name() {
        // Arrange: A module provides a class using its string name.
        Di.ModuleRef ref = Di.getModuleRef(StringTypeModule.class);

        // Act: The service is requested.
        Object svc = ref.get('svc');

        // Assert: The correct class is instantiated.
        Assert.isTrue(svc instanceof TestServiceImpl, 'The framework should instantiate a class from its string name.');
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
}