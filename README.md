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

**3. Dependency Injection** - Implement `Di.Injectable` to receive the container:

```apex
public class OrderService implements Di.Injectable {
    private AccountService accountService;

    public void inject(Di.Container container) {
        this.accountService = (AccountService) container.get(AccountService.class);
    }
}
```

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

---

## Global Modules

If you have to import the same set of modules everywhere, it can get tedious. When you want to provide a set of providers which should be available everywhere out-of-the-box (e.g., logging, database connections, etc.), make the module **global**.

```apex
public class LoggingModule extends Di.Module {
    public override Boolean isGlobal() {
        return true;
    }

    public override Set<Di.Provider> providers() {
        return new Set<Di.Provider>{ provide(ILogger.class).useClass(ConsoleLogger.class) };
    }

    public override Set<String> exports() {
        return new Set<String>{ ILogger.class.getName() };
    }
}
```

Global modules should be registered only once. In the above example, the `ILogger` provider will be ubiquitous, and modules that wish to inject the service will not need to import the `LoggingModule` in their `imports()`.

You can also define global modules via Custom Metadata (`DI_GlobalModule__mdt`) with `ModuleClass__c` and `IsActive__c` fields. `ModuleClass__c` should contain the fully qualified Apex class name, such as `MyNamespace__LoggingModule` or `OuterClass.InnerModule`.

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

This module can be updated and refreshed after registration:

```apex
// Later: update configuration
dbModule.addProvider(dbModule.provide('ConnectionString').useValue('new-connection'));
ref.refresh();
```

For global dynamic modules, `refresh()` republishes the module's current computed exports and clears module caches so consumers do not keep stale singleton instances.

If you want to register a dynamic module in the global scope:

```apex
dbModule.setGlobal();
```

> **Warning**: As mentioned above, making everything global is not a good design decision.

---

## Providers

Providers tell the framework how to create your objects. They map a **token** (a string or Type) to a concrete implementation.

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

> **Note**: Only factory providers support runtime arguments via `get(token, args)` or `resolve(token, args)`.

### useExisting

Creates an alias to another provider. The alias respects the target's scope.

```apex
provide('Logger').useExisting(ILogger.class);
```

If the target provider is `PROTOTYPE`, use `resolve()` instead of `get()`. Native and metadata-backed `Existing` aliases follow the same target-scope behavior.

### useMetadata

Resolves a provider from `DI_Provider__mdt` custom metadata by `DeveloperName`.

```apex
provide('EmailService').useMetadata('EmailService_Config');
```

Invalid metadata configuration is surfaced as framework exceptions. For example, an invalid `Scope__c` value raises `Di.InvalidProviderException` with the provider token and metadata record name.

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

| Scope       | Behavior                                                         |
| ----------- | ---------------------------------------------------------------- |
| `SINGLETON` | One instance per owning `ModuleRef` (default)                    |
| `PROTOTYPE` | New instance on every `resolve()` call                           |
| `SCOPED`    | One instance per active `ScopeRef` or owner scope (Unit of Work) |

```apex
provide(UnitOfWork.class).useClass(UnitOfWork.class).scope(Di.Scope.SCOPED);
```

### Creating a Scope

```apex
Di.ModuleRef root = Di.getModuleRef(SalesModule.class);
Di.ScopeRef scope = root.createScope();

// Within this scope, SCOPED providers share instances
UnitOfWork uow1 = (UnitOfWork) scope.get(UnitOfWork.class);
UnitOfWork uow2 = (UnitOfWork) scope.get(UnitOfWork.class);
Assert.areEqual(uow1, uow2); // Same instance
```

Use `createScope()` before resolving `SCOPED` providers with `get()`. Calling root `ModuleRef.get()` for a scoped provider raises `Di.InvalidScopeException`; root `resolve()` remains available for an uncached one-off instance.

---

## Installation

Copy `Di.cls` and optionally the `DI_Provider__mdt` and `DI_GlobalModule__mdt` custom metadata types into your Salesforce project.

Local tooling is npm-based:

```bash
npm ci
npm run prettier:apex:check
npm run sfca:check
```

Salesforce test commands require an authenticated/default org unless a `--target-org` is supplied explicitly.

---

## Testing

Isolate tests from metadata by mocking global modules and providers.

```apex
@IsTest
static void testIsolation() {
    Di.clear();
    Di.mockGlobalModules(new List<DI_GlobalModule__mdt>());
    Di.mockProviders(new Map<String, DI_Provider__mdt>());

    // Your test code with clean DI state
}
```
