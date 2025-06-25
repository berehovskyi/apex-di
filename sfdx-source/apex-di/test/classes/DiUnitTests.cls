@IsTest(IsParallel = true)
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class DiUnitTests {
    @IsTest
    static void testGetSingleton() {
        Di.ModuleRef ref = new Di.ModuleRef(new SingleModule());
        Object o1 = ref.get('TestService');
        Object o2 = ref.get('TestService');
        Assert.isTrue(o1 instanceof TestServiceImpl);
        Assert.areEqual(o1, o2);
    }

    @IsTest
    static void testResolveNewInstance() {
        Di.ModuleRef ref = new Di.ModuleRef(new SingleModule());
        Object r1 = ref.resolve('TestService', null);
        Object r2 = ref.resolve('TestService', null);
        Assert.isTrue(r1 instanceof TestServiceImpl);
        Assert.areNotEqual(r1, r2);
    }

    @IsTest
    static void testUseValue() {
        Di.ModuleRef ref = new Di.ModuleRef(new ValueModule());
        Assert.areEqual('hello', ref.get('val'));
        Assert.areEqual('hello', ref.resolve('val'));
    }

    @IsTest
    static void testFactory() {
        Di.ModuleRef ref = new Di.ModuleRef(new FactoryModule());
        Object svc = ref.get('svc');
        Assert.isTrue(svc instanceof TestServiceImpl);
    }

    @IsTest
    static void testFactoryWithArgs() {
        Di.ModuleRef ref = new Di.ModuleRef(new ArgsModule());
        Object out = ref.get('arg', new List<String>{ 'X' });
        Assert.areEqual('arg:X', out);
    }

    @IsTest
    static void testMissingGetThrows() {
        Di.ModuleRef ref = new Di.ModuleRef(new SingleModule());
        try {
            ref.get('unknown');
            Assert.isTrue(false);
        } catch (Di.BindingException ex) {
            Assert.isTrue(ex.getMessage().contains('unknown'));
        }
    }

    @IsTest
    static void testMissingResolveThrows() {
        Di.ModuleRef ref = new Di.ModuleRef(new SingleModule());
        try {
            ref.resolve('unknown', null);
            Assert.isTrue(false);
        } catch (Di.BindingException ex) {
            Assert.isTrue(ex.getMessage().contains('unknown'));
        }
    }

    @IsTest
    static void testPrototypeGetThrows() {
        Di.ModuleRef ref = new Di.ModuleRef(new PrototypeModule());
        try {
            ref.get('p');
            Assert.isTrue(false);
        } catch (Di.BindingException ex) {
            Assert.isTrue(ex.getMessage().contains('prototype'));
        }
    }

    @IsTest
    static void testPrototypeResolveSucceeds() {
        Di.ModuleRef ref = new Di.ModuleRef(new PrototypeModule());
        Object a = ref.resolve('p');
        Object b = ref.resolve('p');
        Assert.isTrue(a instanceof TestServiceImpl);
        Assert.areNotEqual(a, b);
    }

    @IsTest
    static void testLocalExportError() {
        try {
            new Di.ModuleRef(new LocalErrorModule());
            Assert.isTrue(false);
        } catch (Di.BindingException ex) {
            Assert.isTrue(ex.getMessage().contains('missing'));
        }
    }

    @IsTest
    static void testImportModule() {
        Di.ModuleRef ref = new Di.ModuleRef(new ImportModule());
        Assert.areEqual('bar', ref.get('foo'));
    }

    @IsTest
    static void testCircularImports() {
        Di.ModuleRef ref = new Di.ModuleRef(new CircularA());
        Assert.isNotNull(ref);
    }

    @IsTest
    static void testGetTypeOverload() {
        Di.ModuleRef ref = new Di.ModuleRef(new TypeModule());
        Object o = ref.get(TestServiceImpl.class);
        Assert.isTrue(o instanceof TestServiceImpl);
    }

    @IsTest
    static void testResolveTypeOverload() {
        Di.ModuleRef ref = new Di.ModuleRef(new TypeModule());
        Object a = ref.resolve(TestServiceImpl.class);
        Object b = ref.resolve(TestServiceImpl.class);
        Assert.areNotEqual(a, b);
    }

    @IsTest
    static void testInvalidProviderConfig() {
        Di.ModuleRef ref = new Di.ModuleRef(new InvalidConfigModule());
        try {
            ref.resolve('x');
            Assert.isTrue(false);
        } catch (Di.BindingException ex) {
            Assert.isTrue(ex.getMessage().contains('Invalid provider config'));
        }
    }

    @IsTest
    static void testMultiLevelImport() {
        Di.ModuleRef ref = new Di.ModuleRef(new A1Module());
        // 'c' is provided at C1LeafModule, bubbled up through B1Module and A1Module
        Assert.areEqual('valueC', ref.get('c'), 'Multi-level import should surface leaf value');
    }

    @IsTest
    static void testOverrideImport() {
        Di.ModuleRef ref = new Di.ModuleRef(new OverrideModule());
        // BModule provides 'foo'= 'bar', but OverrideModule overrides with 'override'
        Assert.areEqual('override', ref.get('foo'), 'Local provider should override imported one');
    }

    @IsTest
    static void testMultipleImportsMerge() {
        Di.ModuleRef ref = new Di.ModuleRef(new MultiImportModule());
        // Should import both 'foo' from BModule and 'bar' from B2Module
        Assert.areEqual('bar', ref.get('foo'));
        Assert.areEqual('baz', ref.get('bar'));
    }

    @IsTest
    static void testUseTypeByStringName() {
        Di.ModuleRef ref = new Di.ModuleRef(new StringTypeModule());
        Object svc = ref.get('svc');
        Assert.isTrue(svc instanceof TestServiceImpl, 'useType by String class name should instantiate correct type');
    }

    @IsTest
    static void testFactoryResolveProducesNewInstances() {
        Di.ModuleRef ref = new Di.ModuleRef(new FactoryModule());
        Object f1 = ref.resolve('svc');
        Object f2 = ref.resolve('svc');
        Assert.areNotEqual(f1, f2, 'resolve() on factory should always return a new instance');
    }

    @IsTest
    static void testEmptyModuleProducesNoDefinitions() {
        Di.Module empty = new Di.Module();
        new Di.ModuleRef(empty);
        Assert.areEqual(0, empty.getDefinitions().size(), 'Empty module should have zero definitions');
    }

    @IsTest
    static void testImportErrorThrows() {
        try {
            new Di.ModuleRef(new ParentImportErrorModule());
            Assert.isTrue(false, 'Expected import-time binding exception');
        } catch (Di.BindingException ex) {
            Assert.isTrue(ex.getMessage().contains('missing'), 'Error message should mention missing token');
            Assert.isTrue(ex.getMessage().contains('LocalErrorModule'), 'Error should reference the child module name');
        }
    }

    @IsTest
    static void testGetWithTypeAndArgsOverload() {
        Di.ModuleRef ref = new Di.ModuleRef(new ArgsTypeModule());
        Object out = ref.get(TestServiceImpl.class, new List<Object>{ 'Z' });
        Assert.areEqual('arg:Z', out, 'get(Type, args) overload should route through factory');
    }

    @IsTest
    static void testResolveWithTypeAndArgsOverload() {
        Di.ModuleRef ref = new Di.ModuleRef(new ArgsTypeModule());
        Object r1 = ref.resolve(TestServiceImpl.class, new List<Object>{ 'P' });
        Object r2 = ref.resolve(TestServiceImpl.class, new List<Object>{ 'P' });
        Assert.areEqual('arg:P', r1, 'resolve(Type, args) overload first call');
        Assert.areEqual('arg:P', r2, 'resolve(Type, args) overload second call');
    }

    // --- Dummy Service for testing ---
    @SuppressWarnings('PMD.ApexDoc')
    interface TestService {
        String getValue();
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class TestServiceImpl implements TestService {
        public String getValue() { return 'impl'; }
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
    class SingleModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('TestService').useType(TestServiceImpl.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'TestService' };
        }
    }

    class TypeModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide(TestServiceImpl.class).useType(TestServiceImpl.class) };
        }
        public override Set<String> exports() {
            return new Set<String>{ TestServiceImpl.class.getName() };
        }
    }

    class ValueModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('val').useValue('hello') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'val' };
        }
    }

    class FactoryModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('svc').useFactory(new TestFactory()) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'svc' };
        }
    }

    class ArgsModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('arg').useFactory(new ArgsFactory()) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'arg' };
        }
    }

    class LocalErrorModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'missing' };
        }
    }

    class BModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('foo').useValue('bar') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo' };
        }
    }

    class ImportModule extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new BModule() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo' };
        }
    }

    class CircularA extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new CircularB() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    class CircularB extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new CircularC() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    class CircularC extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new CircularA() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    class PrototypeModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('p').useType(TestServiceImpl.class).scope(Di.Scope.PROTOTYPE) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'p' };
        }
    }

    class InvalidConfigModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('x') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'x' };
        }
    }

    class C1LeafModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('c').useValue('valueC') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'c' };
        }
    }

    class B1Module extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new C1LeafModule() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'c' };
        }
    }

    class A1Module extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new B1Module() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'c' };
        }
    }

    class OverrideModule extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new BModule() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('foo').useValue('override') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo' };
        }
    }

    class B2Module extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('bar').useValue('baz') };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'bar' };
        }
    }

    class MultiImportModule extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new BModule(), new B2Module() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>{ 'foo', 'bar' };
        }
    }

    class StringTypeModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide('svc').useType(TestServiceImpl.class.getName()) };
        }
        public override Set<String> exports() {
            return new Set<String>{ 'svc' };
        }
    }

    class ParentImportErrorModule extends Di.Module {
        public override List<Di.Module> imports() {
            return new List<Di.Module>{ new LocalErrorModule() };
        }
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>();
        }
        public override Set<String> exports() {
            return new Set<String>();
        }
    }

    class ArgsTypeModule extends Di.Module {
        public override List<Di.Provider> providers() {
            return new List<Di.Provider>{ provide(TestServiceImpl.class).useFactory(new ArgsFactory()) };
        }
        public override Set<String> exports() {
            return new Set<String>{ TestServiceImpl.class.getName() };
        }
    }
}
