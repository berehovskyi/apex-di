@IsTest(IsParallel = true)
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc, PMD.CyclomaticComplexity')
private class DiTest {
    static {
        new Di();
    }

    @IsTest
    static void testGetSingleton() {
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);
        Object o1 = ref.get('TestService');
        Object o2 = ref.get('TestService');
        Assert.isTrue(o1 instanceof TestServiceImpl);
        Assert.areEqual(o1, o2);
    }

    @IsTest
    static void testResolveNewInstance() {
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);
        Object r1 = ref.resolve('TestService', null);
        Object r2 = ref.resolve('TestService', null);
        Assert.isTrue(r1 instanceof TestServiceImpl);
        Assert.areNotEqual(r1, r2);
    }

    @IsTest
    static void testUseValue() {
        Di.ModuleRef ref = Di.getModuleRef(ValueModule.class);
        Assert.areEqual('hello', ref.get('val'));
        Assert.areEqual('hello', ref.resolve('val'));
    }

    @IsTest
    static void testFactory() {
        Di.ModuleRef ref = Di.getModuleRef(FactoryModule.class);
        Object svc = ref.get('svc');
        Assert.isTrue(svc instanceof TestServiceImpl);
    }

    @IsTest
    static void testFactoryWithArgs() {
        Di.ModuleRef ref = Di.getModuleRef(ArgsModule.class);
        Object out = ref.get('arg', new List<String>{ 'X' });
        Assert.areEqual('arg:X', out);
    }

    @IsTest
    static void testMissingGetThrows() {
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);
        try {
            ref.get('unknown');
            Assert.isTrue(false);
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('unknown'));
            Assert.isTrue(ex.getMessage().contains('Potential solutions'));
        }
    }

    @IsTest
    static void testMissingResolveThrows() {
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);
        try {
            ref.resolve('unknown', null);
            Assert.isTrue(false);
        } catch (Di.UnknownProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('unknown'));
            Assert.isTrue(ex.getMessage().contains('Potential solutions'));
        }
    }

    @IsTest
    static void testPrototypeGetThrows() {
        Di.ModuleRef ref = Di.getModuleRef(PrototypeModule.class);
        try {
            ref.get('p');
            Assert.isTrue(false);
        } catch (Di.InvalidScopeException ex) {
            Assert.isTrue(ex.getMessage().contains('prototype'));
            Assert.isTrue(ex.getMessage().contains('Use resolve() method'));
        }
    }

    @IsTest
    static void testPrototypeResolveSucceeds() {
        Di.ModuleRef ref = Di.getModuleRef(PrototypeModule.class);
        Object a = ref.resolve('p');
        Object b = ref.resolve('p');
        Assert.isTrue(a instanceof TestServiceImpl);
        Assert.areNotEqual(a, b);
    }

    @IsTest
    static void testLocalExportError() {
        try {
            Di.getModuleRef(LocalErrorModule.class);
            Assert.isTrue(false);
        } catch (Di.UnknownExportException ex) {
            Assert.isTrue(ex.getMessage().contains('missing'));
            Assert.isTrue(ex.getMessage().contains('providers'));
        }
    }

    @IsTest
    static void testImportModule() {
        Di.ModuleRef ref = Di.getModuleRef(ImportModule.class);
        Assert.areEqual('bar', ref.get('foo'));
    }

    @IsTest
    static void testCircularImports() {
        Di.ModuleRef ref = Di.getModuleRef(CircularA.class);
        Assert.isNotNull(ref);
    }

    @IsTest
    static void testGetTypeOverload() {
        Di.ModuleRef ref = Di.getModuleRef(TypeModule.class);
        Object o = ref.get(TestService.class);
        Assert.isTrue(o instanceof TestServiceImpl);
    }

    @IsTest
    static void testResolveTypeOverload() {
        Di.ModuleRef ref = Di.getModuleRef(TypeModule.class);
        Object a = ref.resolve(TestService.class);
        Object b = ref.resolve(TestService.class);
        Assert.areNotEqual(a, b);
    }

    @IsTest
    static void testInvalidProviderConfig() {
        try {
            Di.getModuleRef(InvalidConfigModule.class);
            Assert.isTrue(false);
        } catch (Di.InvalidProviderException ex) {
            Assert.isTrue(ex.getMessage().contains('Cannot create provider'));
            Assert.isTrue(ex.getMessage().contains('provider type cannot be null'));
        }
    }

    @IsTest
    static void testMultiLevelImport() {
        Di.ModuleRef ref = Di.getModuleRef(A1Module.class);
        // 'c' is provided at C1LeafModule, bubbled up through B1Module and A1Module
        Assert.areEqual('valueC', ref.get('c'), 'Multi-level import should surface leaf value');
    }

    @IsTest
    static void testOverrideImport() {
        Di.ModuleRef ref = Di.getModuleRef(OverrideModule.class);
        // BModule provides 'foo'= 'bar', but OverrideModule overrides with 'override'
        Assert.areEqual('override', ref.get('foo'), 'Local provider should override imported one');
    }

    @IsTest
    static void testMultipleImportsMerge() {
        Di.ModuleRef ref = Di.getModuleRef(MultiImportModule.class);
        // Should import both 'foo' from BModule and 'bar' from B2Module
        Assert.areEqual('bar', ref.get('foo'));
        Assert.areEqual('baz', ref.get('bar'));
    }

    @IsTest
    static void testUseTypeByStringName() {
        Di.ModuleRef ref = Di.getModuleRef(StringTypeModule.class);
        Object svc = ref.get('svc');
        Assert.isTrue(svc instanceof TestServiceImpl, 'useType by String class name should instantiate correct type');
    }

    @IsTest
    static void testFactoryResolveProducesNewInstances() {
        Di.ModuleRef ref = Di.getModuleRef(FactoryModule.class);
        Object f1 = ref.resolve('svc');
        Object f2 = ref.resolve('svc');
        Assert.areNotEqual(f1, f2, 'resolve() on factory should always return a new instance');
    }

    @IsTest
    static void testEmptyModuleProducesNoDefinitions() {
        Di.ModuleRef ref = Di.getModuleRef(Di.Module.class);
        Assert.areEqual(0, ref.getModule().getProviders().size(), 'Empty module should have zero definitions');
    }

    @IsTest
    static void testImportErrorThrows() {
        try {
            Di.getModuleRef(ParentImportErrorModule.class);
            Assert.isTrue(false, 'Expected import-time exception');
        } catch (Di.UnknownExportException ex) {
            Assert.isTrue(ex.getMessage().contains('missing'), 'Error message should mention missing token');
            Assert.isTrue(ex.getMessage().contains('LocalErrorModule'), 'Error should reference the child module name');
        }
    }

    @IsTest
    static void testGetWithTypeAndArgsOverload() {
        Di.ModuleRef ref = Di.getModuleRef(ArgsTypeModule.class);
        Object out = ref.get(TestServiceImpl.class, new List<Object>{ 'Z' });
        Assert.areEqual('arg:Z', out, 'get(Type, args) overload should route through factory');
    }

    @IsTest
    static void testResolveWithTypeAndArgsOverload() {
        Di.ModuleRef ref = Di.getModuleRef(ArgsTypeModule.class);
        Object r1 = ref.resolve(TestServiceImpl.class, new List<Object>{ 'P' });
        Object r2 = ref.resolve(TestServiceImpl.class, new List<Object>{ 'P' });
        Assert.areEqual('arg:P', r1, 'resolve(Type, args) overload first call');
        Assert.areEqual('arg:P', r2, 'resolve(Type, args) overload second call');
    }

    @IsTest
    static void testReplaceValueProvider() {
        Di.ModuleRef ref = Di.getModuleRef(ValueModule.class);
        Di.Module module = ref.getModule();
        module.replace(new Di.ValueProvider('val', 'newHello'));
        Assert.areEqual('newHello', ref.get('val'), 'replace(String,Object) should update literal values');
    }

    @IsTest
    static void testReplaceProviderOverloadNoOpForUnknownToken() {
        Di.Module module = Di.getModuleRef(ValueModule.class).getModule();

        module.replace(new Di.ValueProvider('other', 'oops'));
        Assert.isFalse(
            module.hasProvider('other'),
            'replace(provider) should do nothing when the token did not already exist'
        );
    }

    @IsTest
    static void testReplaceTypeOverload() {
        Di.ModuleRef ref = Di.getModuleRef(TypeModule.class);
        Di.Module module = ref.getModule();
        module.replace(module.provide(TestService.class).useClass(MockService.class));
        Object svc = ref.get(TestService.class);
        Assert.isTrue(svc instanceof MockService, 'replace(Type, Type) should bind to the new class');
    }

    @IsTest
    static void testReplaceFactoryOverload() {
        Di.ModuleRef ref = Di.getModuleRef(FactoryModule.class);
        Di.Module module = ref.getModule();
        module.replace(new Di.ValueProvider('svc', 'direct'));
        Assert.areEqual('direct', ref.get('svc'), 'replace(String,Factory) overload should override existing factory');
    }

    @IsTest
    static void testModuleConstructorWithExplicitToken() {
        Di.Module m = new Di.DynamicModule('MyCustomToken');
        Assert.areEqual('MyCustomToken', m.getToken(),
            'Explicit-string constructor should set getToken()');
    }

    @IsTest
    static void testHasProviderReflectsDefinitions() {
        // After registration, SingleModule should have 'TestService'
        Di.ModuleRef ref = Di.getModuleRef(SingleModule.class);
        Di.Module m = ref.getModule();
        Assert.isTrue(m.hasProvider('TestService'),
            'hasProvider should return true for a provided token');
        Assert.isFalse(m.hasProvider('NoSuch'),
            'hasProvider should return false when no provider exists');
    }

    @IsTest
    static void testReplaceModuleSwapsGraph() {
        // Arrange: original SingleModule returns TestServiceImpl
        Di.ModuleRef before = Di.getModuleRef(SingleModule.class);
        Object orig = before.get('TestService');
        Assert.isTrue(orig instanceof TestServiceImpl);

        // Act: replace the graph for SingleModule with our ReplacementModule
        Di.replaceModule(SingleModule.class, new ReplacementModule());

        // Assert: new SingleModule graph returns our literal 'replaced'
        Di.ModuleRef after = Di.getModuleRef(SingleModule.class);
        Object got = after.get('TestService');
        Assert.areEqual('replaced', got,
            'replaceModule(Type, Module) should swap out the original module graph');
    }

    @IsTest
    static void testReplaceModuleNullThrows() {
        try {
            Di.replaceModule(SingleModule.class, (Di.Module) null);
            Assert.fail('Expected InvalidModuleException when replacement module is null');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot replace module with null'),
                'Null replacement should trigger INVALID_MODULE_REPLACEMENT'
            );
        }
    }

    @IsTest
    static void testModuleStaticAccessorByType() {
        Di.Module m1 = Di.getModuleRef(ValueModule.class).getModule();
        Di.Module m2 = Di.getModuleRef(ValueModule.class).getModule();
        Assert.areEqual(m2, m1, 'Di.module(Type) should return the same instance as getModuleRef().getModule()');
        Assert.areEqual(
            ValueModule.class.getName().substringAfter('.'),
            m1.getToken(),
            'module(Type) ctor should preset token to the Type\'s name'
        );
    }

    @IsTest
    static void testModuleStaticAccessorByString() {
        String key = ValueModule.class.getName();
        Di.Module m1 = Di.getModuleRef(key).getModule();
        Di.Module m2 = Di.getModuleRef(key).getModule();
        Assert.areEqual(m2, m1, 'Di.module(String) should return the same instance as getModuleRef().getModule()');
        Assert.areEqual(
            key.substringAfter('.'),
            m1.getToken(),
            'module(String) should set token to that exact string'
        );
    }

    @IsTest
    static void testModuleStaticAccessorInvalidStringThrows() {
        try {
            Di.getModuleRef('No.Such.Module');
            Assert.fail('Expected a UnknownModuleException for unknown module name');
        } catch (Exception ex) {
            Assert.isTrue(
                ex instanceof Di.UnknownModuleException,
                'module(String) on unknown name should throw a UnknownModuleException'
            );
            Assert.isTrue(ex.getMessage().contains('Potential solutions'));
        }
    }

    @IsTest
    static void testReplaceModuleByStringSwapsGraph() {
        Di.ModuleRef before = Di.getModuleRef(SingleModule.class);
        Object orig = before.get('TestService');
        Assert.isTrue(orig instanceof TestServiceImpl);

        String key = SingleModule.class.getName();
        Di.replaceModule(key, new ReplacementModule());

        Di.ModuleRef after = Di.getModuleRef(SingleModule.class);
        Object got = after.get('TestService');
        Assert.areEqual('replaced', got, 'replaceModule(String,Module) should overwrite the graph by name');
    }

    @IsTest
    static void testReplaceModuleByStringNullThrows() {
        String key = SingleModule.class.getName();
        try {
            Di.replaceModule(key, (Di.Module) null);
            Assert.fail('Expected a InvalidModuleException when replacement module is null');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(
                ex.getMessage().contains('Cannot replace module with null'),
                'Null-replacement path should trigger INVALID_MODULE_REPLACEMENT'
            );
        }
    }

    @IsTest
    static void testAddModuleAndDuplicateThrows() {
        Di.DynamicModule dyn = new Di.DynamicModule('dyn1');
        dyn.addProvider(dyn.provide('foo').useValue('bar'))
            .addExport('foo');
        // first‐time registration succeeds
        Di.ModuleRef r1 = Di.addModule(dyn);
        Assert.areEqual('dyn1', r1.getModule().getToken());
        // second‐time should blow up
        try {
            Di.addModule(dyn);
            Assert.fail('Expected RuntimeException on duplicate addModule');
        } catch (Di.InvalidModuleException ex) {
            Assert.isTrue(
                ex.getMessage().contains('already been registered'),
                'Duplicate registration should mention MODULE_ALREADY_REGISTERED'
            );
        }
    }

    @IsTest
    static void testGetModuleRefByInstance() {
        Di.DynamicModule dyn = new Di.DynamicModule('dyn2');
        dyn.addProvider(dyn.provide('foo2').useValue('baz'))
            .addExport('foo2');
        Di.ModuleRef r1 = Di.getModuleRef(dyn);
        Di.ModuleRef r2 = Di.getModuleRef('dyn2');
        Assert.areEqual(r1, r2, 'getModuleRef(module) and getModuleRef(token) must return same ModuleRef');
        Assert.areEqual('baz', r2.get('foo2'));
    }

    @IsTest
    static void testDynamicModuleImportsAndProviders() {
        // import an existing module and add a custom provider
        Di.DynamicModule dyn = new Di.DynamicModule('dyn3');
        dyn.addImport(Di.import(ValueModule.class))
            .addProvider(dyn.provide('x').useValue('XYZ'))
            .addExport('x');
        Di.addModule(dyn);

        Di.ModuleRef ref = Di.getModuleRef('dyn3');
        Assert.areEqual('hello', ref.get('val'), 'DynamicModule should pull in imported exports');
        Assert.areEqual('XYZ', ref.get('x'));
    }

    @IsTest
    static void testModuleEqualsAndHashCode() {
        Di.Module mA1 = new Di.DynamicModule('A');
        Di.Module mA2 = new Di.DynamicModule('A');
        Di.Module mB = new Di.DynamicModule('B');
        Assert.isTrue(mA1.equals(mA2));
        Assert.areEqual(mA1.hashCode(), mA2.hashCode());
        Assert.isFalse(mA1.equals(mB));
        Assert.isFalse(mA1.equals(null));
        Assert.isFalse(mA1.equals('string'));
    }

    @IsTest
    static void testProviderEqualsAndHashCode() {
        Di.Provider p1 = new Di.ClassProvider('tok', 'AnyClass');
        Di.Provider p2 = new Di.ValueProvider('tok', 123);
        Di.Provider p3 = new Di.ClassProvider('other', 'Foo');
        Assert.isTrue(p1.equals(p2), 'same token => equal');
        Assert.areEqual(p1.hashCode(), p2.hashCode());
        Assert.isFalse(p1.equals(p3), 'different token => not equal');
    }

    @IsTest
    static void testInjectableSupport() {
        Di.DynamicModule dyn = new Di.DynamicModule('dyn4')
            .addProvider(new Di.ClassProvider('foo', FooInjectable.class))
            .addExport('foo');
        Di.addModule(dyn);

        Di.ModuleRef ref = Di.getModuleRef('dyn4');
        Object o = ref.get('foo');
        Assert.isTrue(o instanceof FooInjectable);
        Assert.isTrue(((FooInjectable) o).wasInjected, 'Injectable.inject() should have been called');
    }

    @IsTest
    static void testGlobalModuleFallback() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        // 1) create & register a *global* module that provides 'foo'
        Di.DynamicModule globalModule = new Di.DynamicModule('GMod')
            .addProvider(new Di.ValueProvider('foo', 'globalVal'))
            .addExport('foo')
            .setGlobal();
        Di.addModule(globalModule);

        // 2) create & register a consumer that has no 'foo' of its own
        Di.DynamicModule consumer = new Di.DynamicModule('CMod');
        Di.ModuleRef cref = Di.addModule(consumer);

        // 3) because 'foo' isn't local, consumer.get('foo') should fall back to the global module
        String got = (String) cref.get('foo');
        System.assertEquals('globalVal', got,
            'Consumer should fall back to the global module\'s foo');
    }

    @IsTest
    static void testGlobalModuleOverrideByLocal() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        // 1) register a global bar
        Di.DynamicModule globalModule = new Di.DynamicModule('GMod2')
            .addProvider(new Di.ValueProvider('bar', 'globalBar'))
            .addExport('bar')
            .setGlobal();
        Di.addModule(globalModule);

        // 2) register a local module that also provides 'bar'
        Di.DynamicModule local = new Di.DynamicModule('LMod')
            .addProvider(new Di.ValueProvider('bar', 'localBar'))
            .addExport('bar');
        Di.addModule(local);

        // 3) local.get('bar') must pick the local one, not the global
        Di.ModuleRef lref = Di.getModuleRef('LMod');
        String val = (String) lref.get('bar');
        System.assertEquals('localBar', val,
            'Local provider should override the global provider of the same token');
    }

    @IsTest
    static void testDuplicateGlobalModuleThrows() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        // register a global module once
        Di.DynamicModule g1 = new Di.DynamicModule('DupG')
            .addProvider(new Di.ValueProvider('x', 1))
            .addExport('x')
            .setGlobal();
        Di.addModule(g1);

        // second registration under the same name must blow up
        try {
            Di.addModule(g1);
            System.assert(false, 'Expected an RuntimeException on duplicate global addModule');
        } catch (Di.InvalidModuleException ex) {
            System.assert(
                ex.getMessage().contains('already been registered'),
                'Duplicate global addModule should throw MODULE_ALREADY_REGISTERED'
            );
        }
    }

    @IsTest
    static void testGetModuleRefByInstanceAndNameForGlobal() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        // registering via getModuleRef(module) should end up in the same slot
        Di.DynamicModule g2 = new Di.DynamicModule('InstG')
            .addProvider(new Di.ValueProvider('p', 'v'))
            .addExport('p')
            .setGlobal();
        // register by instance
        Di.ModuleRef byInst = Di.getModuleRef(g2);
        // then lookup by name
        Di.ModuleRef byName = Di.getModuleRef('InstG');
        System.assertEquals(byInst, byName,
            'getModuleRef(module) and getModuleRef(name) must return the same ModuleRef for globals');
        System.assertEquals('v', byName.get('p'));
    }

    @IsTest
    static void testNonGlobalDoesNotFallBack() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        // register a non-global provider
        Di.DynamicModule ng = new Di.DynamicModule('NGMod')
            .addProvider(new Di.ValueProvider('z', 'zzz'))
            .addExport('z');
        Di.addModule(ng);

        // consumer without z
        Di.DynamicModule c2 = new Di.DynamicModule('C2');
        Di.ModuleRef cref2 = Di.addModule(c2);

        // must NOT find 'z' in a non-global registry
        try {
            cref2.get('z');
            System.assert(false, 'Expected UnknownProviderException since non-global providers should not be visible');
        } catch (Di.UnknownProviderException ex) {
            System.assert(
                ex.getMessage().contains('Could not find'),
                'Should throw a DI UnknownProviderException for missing provider'
            );
        }
    }

    @IsTest
    static void testIsGlobalFlagDefaultsFalse() {
        Di.DynamicModule m = new Di.DynamicModule('M1');
        // newly constructed modules are non-global by default
        Assert.isFalse(m.isGlobal(), 'New module should not be global unless setGlobal() is called');
    }

    @IsTest
    static void testSetGlobalMakesModuleGlobal() {
        Di.DynamicModule m = new Di.DynamicModule('M2').setGlobal();
        Assert.isTrue(m.isGlobal(), 'After calling setGlobal(), isGlobal() must return true');
    }

    @IsTest
    static void testStaticGlobalModuleAccessorByString() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        String key = 'GlobalStat';
        // build & register a global module
        Di.DynamicModule g = new Di.DynamicModule(key);
        g.addProvider(g .provide('foo').useValue('bar'))
            .addExport('foo')
            .setGlobal();
        Di.addModule(g);

        // the static shortcut should return exactly our instance
        Di.Module viaStatic = Di.getModuleRef(key).getModule();
        Di.Module viaRef = Di.getModuleRef(key).getModule();
        Assert.areEqual(viaRef, viaStatic,
            'Di.module(token) must return the same instance as getModuleRef(token).getModule()');
        // and it really is marked global
        Assert.isTrue(viaStatic.isGlobal(), 'Static‐fetched module must preserve its global flag');
        // and its provider works
        Assert.areEqual('bar', Di.getModuleRef(key).get('foo'),
            'Global module fetched via static accessor should resolve its exports');
    }

    @IsTest
    static void testGlobalModuleSingletonBehavior() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        String key = 'GlobalOnce';
        Di.DynamicModule g = new Di.DynamicModule(key);
        g.addProvider(g.provide('x').useValue('X'))
            .addExport('x')
            .setGlobal();
        // first registration
        Di.ModuleRef ref1 = Di.addModule(g);
        // second lookup by name
        Di.ModuleRef ref2 = Di.getModuleRef(key);
        Assert.areEqual(ref1, ref2,
            'Global modules should not be re-instantiated on getModuleRef(token)');
        // and static accessor must match too
        Assert.areEqual(ref1.getModule(), Di.getModuleRef(key).getModule());
    }

    @IsTest
    static void testGlobalFallbackAcrossStaticAccessors() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        // if a non-global consumer fetches a token that exists only in a global,
        // static Di.module() and Di.getModuleRef() must both see it:
        Di.DynamicModule glob = new Di.DynamicModule('FallG');
        glob.addProvider(glob.provide('gVal').useValue('GLOB'))
            .addExport('gVal')
            .setGlobal();
        Di.addModule(glob);

        Di.DynamicModule cons = new Di.DynamicModule('FallC');
        Di.addModule(cons);

        // use the static shortcut on the consumer to get its ModuleRef
        Di.ModuleRef cref = Di.getModuleRef('FallC');
        // asking for 'gVal' falls back to the global
        Assert.areEqual('GLOB', cref.get('gVal'),
            'Consumer obtained via static accessors should still fall back to global exports');
    }

    @IsTest
    static void testMockGlobalModules() {
        // Create mock CMT records
        List<DI_GlobalModule__mdt> mockRecords = new List<DI_GlobalModule__mdt>{
            new DI_GlobalModule__mdt(
                ModuleClass__c = GlobalModule.class.getName(),
                IsActive__c = true
            )
        };
        // Note: In real test, you'd need to construct these properly
        Di.mockGlobalModules(mockRecords);

        // Test that empty mock list prevents CMT loading
        Di.ModuleRef ref = Di.getModuleRef('GlobalModule');
        Assert.isNotNull(ref);
    }

    @IsTest
    static void testAddGlobalModuleRegistersSuccessfully() {
        // Mock CMT to prevent loading
        Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());

        // Now mark it global and register
        Di.DynamicModule g = new Di.DynamicModule('ReallyGlobal').setGlobal();
        g
            .addProvider(g.provide('val').useValue('V'))
            .addExport('val');

        // Should succeed
        Di.ModuleRef globalRef = Di.addModule(g);
        // And subsequent lookup via getModuleRef() yields the same instance
        Di.ModuleRef lookupRef = Di.getModuleRef('ReallyGlobal');
        System.assertEquals(
            globalRef,
            lookupRef,
            'addModule  getModuleRef should return identical ModuleRef'
        );
        // Its export should resolve correctly
        String v = (String) lookupRef.get('val');
        System.assertEquals('V', v, 'Global module export should resolve properly');
    }

    // --- Dummy Service for testing ---
    @SuppressWarnings('PMD.ApexDoc')
    public interface TestService {
        String getValue();
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class TestServiceImpl implements TestService {
        public String getValue() { return 'impl'; }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class MockService implements TestService {
        public String getValue() { return 'mock'; }
    }

    // --- Factory implementations ---
    class TestFactory implements Di.Factory {
        @SuppressWarnings('PMD.ApexDoc')
        public Object newInstance(Di.ModuleRef ref, Object args) {
            return new TestServiceImpl();
        }
    }
    class ArgsFactory implements Di.Factory {
        @SuppressWarnings('PMD.ApexDoc')
        public Object newInstance(Di.ModuleRef ref, Object args) {
            List<Object> arr = (List<Object>) args;
            String prefix = arr != null && !arr.isEmpty() ? '' + arr[0] : '';
            return 'arg:' + prefix;
        }
    }

    // --- Module definitions ---
    public class SingleModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('TestService').useClass(TestServiceImpl.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'TestService' };
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
        public override Set<String> exports() {
            return new Set<String>{ 'svc' };
        }
    }

    public class ArgsModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('arg').useFactory(new ArgsFactory()) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'arg' };
        }
    }

    public class LocalErrorModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'missing' };
        }
    }

    public class BModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('foo').useValue('bar') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo' };
        }
    }

    public class ImportModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(BModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo' };
        }
    }

    public class CircularA extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularB.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    public class CircularB extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularC.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    public class CircularC extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(CircularA.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    public class PrototypeModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('p').useClass(TestServiceImpl.class).scope(Di.Scope.PROTOTYPE) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'p' };
        }
    }

    public class InvalidConfigModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('x').useClass((Type) null) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'x' };
        }
    }

    public class C1LeafModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('c').useValue('valueC') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'c' };
        }
    }

    public class B1Module extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(C1LeafModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'c' };
        }
    }

    public class A1Module extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(B1Module.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'c' };
        }
    }

    public class OverrideModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(BModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('foo').useValue('override') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo' };
        }
    }

    public class B2Module extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('bar').useValue('baz') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'bar' };
        }
    }

    public class MultiImportModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(BModule.class), Di.import(B2Module.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo', 'bar' };
        }
    }

    public class StringTypeModule extends Di.Module {
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('svc').useClass('DiTest.TestServiceImpl') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'svc' };
        }
    }

    public class ParentImportErrorModule extends Di.Module {
        public override Set<Di.ModuleImport> imports() {
            return new Set<Di.ModuleImport>{ Di.import(LocalErrorModule.class) };
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
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

    public class ReplacementModule extends Di.Module {
        public ReplacementModule() {
            super('SingleModule'); // must match the original token
        }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide('TestService').useValue('replaced') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'TestService' };
        }
    }

    public class GlobalModule extends Di.Module {
        public override Boolean isGlobal() { return true; }
        public override Set<Di.Provider> providers() {
            return new Set<Di.Provider>{ provide(TestService.class).useClass(TestServiceImpl.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ TestService.class.getName() };
        }
    }

    public class FooInjectable implements Di.Injectable {
        public Boolean wasInjected = false;
        public void inject(final Di.ModuleRef c) {
            wasInjected = true;
        }
    }

}
