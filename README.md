# Apex DI

A modular, NestJS-inspired **Dependency Injection** framework for Salesforce Apex.

Build testable, decoupled applications by defining providers in modules and letting the framework manage instantiation, scoping, and lifecycle.

---

## Installation

Copy `Di.cls` and optionally the `DI_Provider__mdt` and `DI_GlobalModule__mdt` custom metadata types into your Salesforce project.

---

## Quick Start

```apex
// 1. Define a module with providers
public class AppModule extends Di.Module {
    public override Set<Di.Provider> providers() {
        return new Set<Di.Provider>{
            provide(AccountService.class).useClass(AccountService.class)
        };
    }
    public override Set<String> exports() {
        return new Set<String>{ AccountService.class.getName() };
    }
}

// 2. Resolve dependencies
Di.ModuleRef app = Di.getModuleRef(AppModule.class);
AccountService svc = (AccountService) app.get(AccountService.class);
```

---

## Providers

Providers tell the framework *how* to create your objects. They map a **token** (a name or Type) to a concrete implementation.

### useClass

Binds a token to a class. The framework instantiates the class on demand.

```apex
provide(ILogger.class).useClass(ConsoleLogger.class)
```

### useValue

Binds a token to a literal value. Useful for configuration.

```apex
provide('API_URL').useValue('https://api.example.com')
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

provide(HttpClient.class).useFactory(new HttpClientFactory())
```

> **Note**: Only factory providers support runtime arguments via `get(token, args)` or `resolve(token, args)`.

### useExisting

Creates an alias to another provider. The alias respects the target's scope.

```apex
provide('Logger').useExisting(ConsoleLogger.class)
```

### useMetadata

Resolves a provider from `DI_Provider__mdt` custom metadata by `DeveloperName`.

```apex
provide('EmailService').useMetadata('EmailService_Config')
```

---

## Modules

Modules are the containers for your application's logic. They group related code and control what is visible to the rest of the application.

```apex
public class UsersModule extends Di.Module {
    public override Set<Di.Provider> providers() {
        return new Set<Di.Provider>{
            provide(UserRepository.class).useClass(UserRepository.class),
            provide(UserService.class).useClass(UserService.class)
        };
    }

    public override Set<String> exports() {
        // Only UserService is accessible to importing modules
        return new Set<String>{ UserService.class.getName() };
    }
}
```

### Importing Modules

Use `imports()` to compose modules. Exports from imported modules become available.

```apex
public class AppModule extends Di.Module {
    public override Set<Di.ModuleImport> imports() {
        return new Set<Di.ModuleImport>{
            Di.import(UsersModule.class),
            Di.import(OrdersModule.class)
        };
    }
}
```

### Re-exporting

Use `reexports()` to expose providers from imported modules to consumers of *this* module.

```apex
public override Set<String> reexports() {
    return new Set<String>{ UserService.class.getName() };
}
```

### Lazy vs Eager Loading

Imports are resolved lazily by default. Use `.immediately()` for eager loading:

```apex
Di.import(CriticalModule.class).immediately()
```

---

## Scopes

Scopes control instance lifetime.

| Scope | Behavior |
|---|---|
| `SINGLETON` | One instance per `ModuleRef` (default) |
| `PROTOTYPE` | New instance on every `resolve()` call |
| `SCOPED` | One instance per `ScopeRef` (Unit of Work) |

```apex
provide(UnitOfWork.class).useClass(UnitOfWork.class).scope(Di.Scope.SCOPED)
```

### Creating a Scope

```apex
Di.ModuleRef root = Di.getModuleRef(AppModule.class);
Di.ScopeRef scope = root.createScope();

// Within this scope, SCOPED providers share instances
UnitOfWork uow1 = (UnitOfWork) scope.get(UnitOfWork.class);
UnitOfWork uow2 = (UnitOfWork) scope.get(UnitOfWork.class);
Assert.areEqual(uow1, uow2); // Same instance
```

### get() vs resolve()

| Method | Use Case |
|---|---|
| `get(token)` | Returns cached instance (SINGLETON, SCOPED). Throws for PROTOTYPE. |
| `resolve(token)` | Always creates a new instance. |

---

## Dependency Injection

Implement `Di.Injectable` for automatic dependency wiring.

```apex
public class OrderService implements Di.Injectable {
    private UserService userService;
    private ILogger logger;

    public void inject(Di.Container container) {
        this.userService = (UserService) container.get(UserService.class);
        this.logger = (ILogger) container.get(ILogger.class);
    }
}
```

The framework calls `inject()` after instantiation, allowing circular dependencies to be resolved automatically.

---

## Global Modules

Global modules provide fallback providers available to all modules.

**Option 1: Apex**
```apex
public override Boolean isGlobal() {
    return true;
}
```

**Option 2: Custom Metadata**
Create a `DI_GlobalModule__mdt` record with the module class name.

---

## Dynamic Modules

Configure modules programmatically at runtime.

```apex
Di.DynamicModule flags = new Di.DynamicModule('FeatureFlags');
flags.addProvider(flags.provide('EnableBeta').useValue(false));
flags.addExport('EnableBeta');

Di.ModuleRef ref = Di.addModule(flags);

// Later, update configuration
flags.addProvider(flags.provide('EnableBeta').useValue(true));
ref.refresh();
```

---

## Runtime Modification

### Replace a Provider

```apex
Di.ModuleRef ref = Di.getModuleRef(AppModule.class);
ref.replace(provide('API_URL').useValue('https://override.example.com'));
```

### Replace a Module

```apex
Di.replaceModule(AppModule.class, new MockAppModule());
```

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

---

## Design Principles

- **Zero Configuration**: No runtime settings for logging or caching.
- **Fail Fast**: Missing providers throw immediately, not when used.
- **Explicit Exports**: Modules control their public API.
- **Lazy by Default**: Imports are resolved only when needed.
- **Silent & Pure**: No internal logging; shadowing is implicit.
