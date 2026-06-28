# Apex DI

A modular, NestJS-inspired **Dependency Injection** framework for Salesforce Apex.

---

## Modules

A module is a class that extends `Di.Module`. This base class provides the structure that Apex DI uses to organize and manage your application efficiently.

Every application using Apex DI has at least one module, which serves as the starting point. Apex DI uses this module to build an internal structure that resolves relationships and dependencies between modules and providers. While small applications might only have one module, this is generally not the case. **Modules are highly recommended as an effective way to organize your code.** For most applications, you'll have multiple modules, each encapsulating a closely related set of capabilities.

The `Di.Module` class provides methods that describe the module:

| Method        | Purpose                                                                                                                               |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `providers()` | The providers that will be instantiated by Apex DI and may be shared within this module                                               |
| `imports()`   | The list of imported modules that export the providers required in this module                                                        |
| `exports()`   | The **tokens** of providers that should be available to other modules. You export the token (the `provide` key), not the class itself |
| `reexports()` | Modules whose exports should be re-exported as part of this module's API                                                              |

The module **encapsulates providers by default**. This means you can only inject providers that are either part of the current module or explicitly exported from imported modules. The exported providers from a module essentially serve as the module's public interface or API.

Exported providers are resolved in the context of the module that owns the provider, not the consuming module. The owner controls instantiation, singleton caching, scoped caching, and `Di.Injectable` autowiring visibility. This means an exported provider can inject private dependencies from its owner module, but it cannot see providers imported only by the consumer.

Provider visibility follows a deterministic precedence: local providers override imported providers, imported providers override implicit global providers, and two visible imported providers with the same token are rejected when they have different owners. Re-exporting the same owner through multiple paths is allowed. Global modules likewise cannot publish the same token from different owners.

### Using Modules

**1. Direct Resolution** - Typically used in controllers or entry points:

```apex
public with sharing class AccountController {
    @AuraEnabled
    public static List<Account> getAccounts() {
        Di.ModuleRef ref = Di.getModuleRef(AccountsModule.class);
        AccountService svc = (AccountService) ref.get(AccountService.class);
        return svc.findAll();
    }
}
```

**2. Importing** - Import one module into another to access its exported providers:

```apex
public class SalesModule extends Di.Module {
    public override Set<Di.ModuleImport> imports() {
        return new Set<Di.ModuleImport>{ Di.import(AccountsModule.class) };
    }
    // Now SalesModule can use AccountService (if exported by AccountsModule)
}
```

Imports are lazy by default. Mark an import with `.immediately()` when it must be registered with its owning module:

```apex
public override Set<Di.ModuleImport> imports() {
    return new Set<Di.ModuleImport>{ Di.import(AccountsModule.class).immediately() };
}
```

`.immediately()` only marks the import. Eager resolution occurs when the owning module is registered; calling it on a standalone `ModuleImport` does not mutate an application context.

**3. Dependency Injection** - Implement `Di.Injectable` to receive the container:

```apex
public class OrderService implements Di.Injectable {
    private AccountService accountService;

    public void inject(Di.Container container) {
        this.accountService = (AccountService) container.get(AccountService.class);
    }
}
```

`ModuleRef` instances are created by an application context during registration. They cannot be constructed standalone. Module instances also have strict identity: a different instance with an already-registered token, or the same instance registered in another application context, is rejected.

### Application Contexts

The static `Di` methods use one default `Di.ApplicationContext`. Create explicit contexts when multiple isolated module graphs or metadata sources must coexist in the same transaction:

```apex
Di.ApplicationContext context = Di.createContext();
Di.ModuleRef ref = context.getModuleRef(SalesModule.class);
OrderService service = (OrderService) ref.get(OrderService.class);
```

Each context owns its module registries, singleton runtimes, global bindings, metadata cache, and provider-discovery index. Imports declared with `Di.import(...)` are resolved in the context that owns the importing module.

Provider discovery is incremental and memoized by default. Call `compile()` after registering the graph to eagerly resolve imports, validate visibility, and complete the provider index:

```apex
Di.ApplicationContext context = Di.createContext();
Di.ModuleRef ref = context.getModuleRef(SalesModule.class);
context.compile();
```

Compiled graphs require acyclic module imports. Graph mutations invalidate compiled and incremental bindings; resolution returns to lazy discovery until `compile()` is called again.

The first top-level `get()` / `resolve()` opens an application context lifecycle. Setup-time module additions before that point keep their issued handles valid. Successful external graph mutations after that point, such as `addModule`, `replaceProvider`, metadata mock changes in tests, or `replaceModule`, invalidate previously issued `ModuleRef` and `ScopeRef` handles. Reacquire refs/scopes from the context after a mutation. Framework-controlled lazy import/global discovery during resolution remains handle-safe.

---

## Feature Modules

In our example, the `AccountService` is specific to the accounts domain. It makes sense to group it into a feature module. A feature module organizes code relevant to a specific feature, helping to maintain clear boundaries and better organization. This is particularly important as the application or team grows, and it aligns with SOLID principles.

Let's create the `AccountsModule`:

```apex
public class AccountsModule extends Di.Module {
    public override Set<Di.Provider> providers() {
        return new Set<Di.Provider>{ provide(AccountService.class).useClass(AccountService.class) };
    }
}
```

Above, we defined the `AccountsModule` in its own class. The last thing we need to do is import this module into the module that needs it:

```apex
public class SalesModule extends Di.Module {
    public override Set<Di.ModuleImport> imports() {
        return new Set<Di.ModuleImport>{ Di.import(AccountsModule.class) };
    }
}
```

---

## Shared Modules

In Apex DI, modules are singletons by default, so you can share the same instance of any provider between multiple modules effortlessly.

Every module is automatically a shared module. Once created, it can be reused by any module. Let's imagine that we want to share an instance of the `CacheService` between several other modules. In order to do that, we first need to **export** the `CacheService` provider by adding it to the module's `exports()`:

```apex
public class CachingModule extends Di.Module {
    public override Set<Di.Provider> providers() {
        return new Set<Di.Provider>{ provide(ICacheService.class).useClass(CacheService.class) };
    }

    public override Set<String> exports() {
        return new Set<String>{ ICacheService.class.getName() };
    }
}
```

Now any module that imports the `CachingModule` has access to the `ICacheService` and will share the same instance with all other modules that import it as well.

Singleton sharing is owner-based. If two consumers import the same exported singleton, both consumers resolve through the exporting module's cache. The same ownership rule applies to global providers.

If we were to directly register the `CacheService` in every module that requires it, each module would get its own separate instance. This leads to increased memory usage and could cause unexpected behavior, such as state inconsistency if the service maintains any internal state.

By encapsulating the service inside a module and exporting it, we ensure that the same instance is reused across all modules that import it. This is one of the key benefits of modularity and dependency injection, allowing services to be efficiently shared throughout the application.

---

## Module Re-exporting

As seen above, modules can export their internal providers. In addition, they can **re-export modules that they import**. In the example below, the `CommonModule` is both imported into and exported from the `CoreModule`, making it available for other modules which import `CoreModule`.

```apex
public class CoreModule extends Di.Module {
    public override Set<Di.ModuleImport> imports() {
        return new Set<Di.ModuleImport>{ Di.import(CommonModule.class) };
    }

    public override Set<Di.ModuleImport> reexports() {
        return new Set<Di.ModuleImport>{ Di.import(CommonModule.class) };
    }
}
```

Re-exports are transitive and preserve the original provider owner. Circular re-export graphs and exports that do not resolve to a declared or re-exported provider are rejected during module registration.

---

## Global Modules

If you have to import the same set of modules everywhere, it can get tedious. When you want to provide a set of providers which should be available everywhere out-of-the-box (e.g., logging, database connections, etc.), make the module **global**.

```apex
public class LoggingModule extends Di.Module {
    public override Set<Di.Provider> providers() {
        return new Set<Di.Provider>{ provide(ILogger.class).useClass(ConsoleLogger.class) };
    }

    public override Set<String> exports() {
        return new Set<String>{ ILogger.class.getName() };
    }
}

Di.addGlobalModule(new LoggingModule());
```

Global modules should be registered only once. In the above example, the `ILogger` provider will be ubiquitous, and modules that wish to inject the service will not need to import the `LoggingModule` in their `imports()`.

Global exports act as implicit fallback imports and retain their owning module's visibility and caches. Their binding index is rebuilt atomically after a graph mutation and reused for constant-time lookups until the graph changes again.

Globalness belongs to the registration, not the module class. `addModule()` registers locally, while `addGlobalModule()` registers globally. Replacing a registered module preserves that visibility.

Custom Metadata uses `DI_Module__mdt` with `ModuleClass__c`, `IsActive__c`, and `IsGlobal__c`. `ModuleClass__c` contains the fully qualified Apex class name, such as `MyNamespace.LoggingModule` or `OuterClass.InnerModule`. Active records with `IsGlobal__c = true` are loaded as globals.

Active non-global records are selected explicitly by their `DeveloperName` alias:

```apex
Di.ModuleRef payments = Di.getMetadataModuleRef('Payments');
```

Modules can import the same configured alias without coupling to its selected class:

```apex
public override Set<Di.ModuleImport> imports() {
    return new Set<Di.ModuleImport>{ Di.importMetadataModule('Payments') };
}
```

The metadata alias selects a class but never replaces the module's canonical runtime token.

> **Hint**: Making everything global is not recommended as a design practice. While global modules can help reduce boilerplate, it's generally better to use the `imports()` to make a module's API available to other modules in a controlled and clear way.

---

## Dynamic Modules

Dynamic modules allow you to create modules that can be configured at runtime. This is especially useful when you need to provide flexible, customizable modules where the providers can be created based on certain options or configurations.

```apex
Di.DynamicModule dbModule = new Di.DynamicModule('DatabaseModule');
dbModule.addProvider(dbModule.provide('ConnectionString').useValue('jdbc:salesforce://...'));
dbModule.addExport('ConnectionString');

Di.ModuleRef ref = Di.addModule(dbModule);
```

Successful registration permanently seals the dynamic module definition. To change it, configure a new module with the same token and replace the registered module:

```apex
Di.DynamicModule replacement = new Di.DynamicModule('DatabaseModule');
replacement.addProvider(replacement.provide('ConnectionString').useValue('new-connection'));
replacement.addExport('ConnectionString');

Di.replaceModule('DatabaseModule', replacement);
```

Replacement validates and commits the complete new definition atomically, preserves the existing registration visibility, invalidates provider-binding indexes, and starts a new lifecycle generation so previously issued refs/scopes fail fast instead of serving stale bindings or singleton instances.

If you want to register a dynamic module in the global scope:

```apex
Di.DynamicModule globalDbModule = new Di.DynamicModule('GlobalDatabaseModule');
globalDbModule.addProvider(globalDbModule.provide('ConnectionString').useValue('jdbc:salesforce://...'));
globalDbModule.addExport('ConnectionString');
Di.addGlobalModule(globalDbModule);
```

> **Warning**: As mentioned above, making everything global is not a good design decision.

Configure dynamic modules before registration. After a successful registration, all four structural mutators (`addProvider`, `addImport`, `addExport`, and `addReexport`) reject further changes. Failed registration leaves the candidate editable and retryable. `ApplicationContext.clear()` releases ownership without unsealing the definition, so the same unchanged instance can be registered in another context; reconfiguration requires a new `DynamicModule` instance.

Call graph mutation APIs such as `replaceProvider()`, `replaceModule()`, or `addModule()` only between top-level resolutions, not from `Factory.newInstance()` or `Injectable.inject()`.

Replacing a module requires the replacement to declare exactly the same token and remain in the same local or global registry. The framework rejects mismatched replacements before publishing them.

---

## Providers

Providers tell the framework how to create your objects. They map a **token** (a string or Type) to a concrete implementation.

Use the fluent builder inside modules, or instantiate the public provider classes directly for reuse, replacement, or focused tests:

```apex
Di.DynamicModule module = new Di.DynamicModule('TestModule');
Di.Provider configured = module.provide(TestService.class).useClass(TestServiceImpl.class);
Di.ValueProvider standalone = new Di.ValueProvider('Greeting', 'hello');
```

Provider replacement is owned by the application context:

```apex
Di.ModuleRef ref = Di.getModuleRef(DatabaseModule.class);
DatabaseService first = (DatabaseService) ref.get(DatabaseService.class);

Di.replaceProvider(DatabaseModule.class, new Di.ValueProvider('ConnectionString', 'new-connection'));

// The old ref belongs to the previous lifecycle generation.
Di.ModuleRef freshRef = Di.getModuleRef(DatabaseModule.class);
DatabaseService second = (DatabaseService) freshRef.get(DatabaseService.class);
```

### Token Identity

`Type` overloads canonicalize tokens through `Type.getName()`:

```apex
provide(ILogger.class).useClass(ConsoleLogger.class);
ILogger logger = (ILogger) ref.get(ILogger.class);
```

`String` tokens are exact, case-sensitive keys. `provide('Foo')` and `get('foo')` are different tokens. Prefer `Type` overloads for Apex class/interface tokens, and reserve string tokens for deliberate aliases or configuration keys with stable casing.

### useClass

Binds a token to a class. The framework instantiates the class on demand.

```apex
provide(ILogger.class).useClass(ConsoleLogger.class);
```

### useValue

Binds a token to a literal value. Useful for configuration.

```apex
provide('API_URL').useValue('https://api.example.com');
```

### useFactory

Binds a token to a factory class. Factories receive the container and optional arguments.

```apex
public class HttpClientFactory implements Di.Factory {
    public Object newInstance(Di.Container c, Object args) {
        String baseUrl = (String) c.get('API_URL');
        return new HttpClient(baseUrl);
    }
}

provide(HttpClient.class).useFactory(new HttpClientFactory());
```

> **Note**: Only factory providers support runtime arguments, and arguments must be passed through `resolve(token, args)`. `get(token, args)` always throws because `get()` is the cached retrieval path.

### useExisting

Creates an alias to another provider. The alias respects the target's scope.

```apex
provide('Logger').useExisting(ILogger.class);
```

If the target provider is `PROTOTYPE`, use `resolve()` instead of `get()`. Native and metadata-backed `Existing` aliases follow the same target-scope behavior.

Aliases are redirects in the container graph. Resolve them through `get()` or `resolve()`; calling an `ExistingProvider`'s `resolve()` method directly is invalid.

### useMetadata

Resolves a provider from `DI_Provider__mdt` custom metadata by `DeveloperName`.

```apex
provide('EmailService').useMetadata('EmailService_Config');
```

Invalid metadata configuration is surfaced as framework exceptions. For example, an invalid `Scope__c` value raises `Di.InvalidProviderException` with the provider token and metadata record name.

### Metadata Sources

`Di.CustomMetadataSource` is the default adapter for `DI_Module__mdt` and `DI_Provider__mdt`. Supply a custom `Di.MetadataSource` to isolate an application from Custom Metadata or provide definitions from another source:

```apex
public class AppMetadataSource implements Di.MetadataSource {
    public Map<String, Di.MetadataModuleDefinition> getModules() {
        return new Map<String, Di.MetadataModuleDefinition>();
    }

    public Map<String, Di.ProviderDefinition> getProviders() {
        return new Map<String, Di.ProviderDefinition>();
    }
}

Di.ApplicationContext context = Di.createContext(new AppMetadataSource());
```

The framework core consumes normalized `MetadataModuleDefinition` and `ProviderDefinition` values; only the default adapter reads raw Custom Metadata records.

---

## Dependency Injection

Implement `Di.Injectable` for automatic dependency wiring. The framework calls `inject()` after instantiation:

```apex
public class OrderService implements Di.Injectable {
    private AccountService accountService;
    private ILogger logger;

    public void inject(Di.Container container) {
        this.accountService = (AccountService) container.get(AccountService.class);
        this.logger = (ILogger) container.get(ILogger.class);
    }
}
```

This two-phase instantiation allows circular dependencies to be resolved automatically.

---

## Manual Injection

You can manually trigger dependency injection on an object that implements `Di.Injectable` using the `inject()` method on the container. This is useful when you have objects created outside of the DI container (e.g., in legacy code or framework-instantiated classes) but still want to populate their dependencies.

```apex
Di.ModuleRef ref = Di.getModuleRef(MyModule.class);
MyService service = new MyService();

// Manually inject dependencies
ref.inject(service);
```

Manual `inject()` is strict and throws if the supplied object does not implement `Di.Injectable`. Automatic provider autowiring is opportunistic and no-ops for objects that are not `Di.Injectable`.

---

## Scopes

Scopes control instance lifetime.

| Scope       | Behavior                                                 |
| ----------- | -------------------------------------------------------- |
| `SINGLETON` | One instance per owning module runtime (default)         |
| `PROTOTYPE` | New instance on every `resolve()` call                   |
| `SCOPED`    | One instance per active logical scope and provider owner |

```apex
provide(UnitOfWork.class).useClass(UnitOfWork.class).scope(Di.Scope.SCOPED);
```

Configure scope before registration. A committed provider rejects later `scope(...)` changes, and `null` is never a valid scope.

### Creating a Scope

```apex
Di.ModuleRef root = Di.getModuleRef(SalesModule.class);
Di.ScopeRef scope = root.createScope();

// Within this scope, SCOPED providers share instances
UnitOfWork uow1 = (UnitOfWork) scope.get(UnitOfWork.class);
UnitOfWork uow2 = (UnitOfWork) scope.get(UnitOfWork.class);
Assert.areEqual(uow1, uow2); // Same instance
```

Use `createScope()` before resolving `SCOPED` providers. Both root `ModuleRef.get()` and root `ModuleRef.resolve()` reject scoped providers with `Di.InvalidScopeException`. Within a scope, `get()` caches the scoped instance and `resolve()` creates a fresh instance. A singleton must not depend on a scoped provider because singleton construction occurs at the root.

Share one `ScopeContext` across module refs when they participate in the same logical unit of work:

```apex
Di.ScopeContext unitOfWork = new Di.ScopeContext();
Di.ScopeRef salesScope = salesRef.createScope(unitOfWork);
Di.ScopeRef accountsScope = accountsRef.createScope(unitOfWork);
```

A `ScopeContext` belongs to one `ApplicationContext`. It caches scoped instances by provider owner and token. Successful external graph mutations invalidate held `ScopeRef` handles; internal lazy graph discovery remains safe for the active scope. `unitOfWork.clear()` explicitly resets the entire shared scope; clearing any participant also resets that shared unit of work.

---

## Installation

Deploy `sfdx-source/apex-di/main` as one metadata unit. `Di.cls` references the included `DI_Provider__mdt` and `DI_Module__mdt` types, so copying only the Apex class is not sufficient.

Local tooling is npm-based:

```bash
npm ci
npm run prettier:apex:check
npm run sfca:check
```

Salesforce test commands require an authenticated/default org unless a `--target-org` is supplied explicitly.

---

## Testing

Prefer a fresh `ApplicationContext` with an injected `MetadataSource` for isolated tests. Tests that exercise the default Custom Metadata adapter can use the `@TestVisible` mock helpers:

```apex
@IsTest
static void testIsolation() {
    Di.clear();
    Di.mockModules(new List<DI_Module__mdt>());
    Di.mockProviders(new Map<String, DI_Provider__mdt>());

    // Your test code with clean DI state
}
```
