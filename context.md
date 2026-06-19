### Framework Context Summary

This is an advanced, NestJS-inspired Dependency Injection (DI) framework for Apex.

#### Core Components & Principles:

- **`Di.Module`:** An abstract class that serves as a blueprint. Concrete modules must implement `imports()`, `providers()`, and `exports()`.
- **`Di.Container`:** An abstract base class for dependency resolution.
    - **`Di.ModuleRef`:** The root runtime container for a module instance. It is responsible for provider resolution and caching.
    - **`Di.ScopeRef`:** A short-lived, child container created from a `ModuleRef` via `.createScope()`. It enables the "Unit of Work" pattern by providing its own cache for `SCOPED` providers.
    - **`inject()`:** The container exposes a public `inject()` method to manually wire dependencies into objects that implement `Di.Injectable`. Manual `inject()` is strict and throws if the supplied object does not implement `Di.Injectable`; automatic provider autowiring is opportunistic and no-ops for objects that are not `Di.Injectable`.
- **Providers:** The framework supports multiple provider types:
    - **`useClass`:** Binds a token to a class constructor.
    - **`useValue`:** Binds a token to a literal value.
    - **`useFactory`:** Binds a token to the output of a factory class.
    - **`useExisting`:** Creates an alias for an existing provider token. It **respects the target provider's scope**: if the target is `PROTOTYPE`, the alias behaves as a prototype; if `SINGLETON`, it forces a singleton resolution.
- **Token Identity:** `Type` overloads canonicalize tokens through `Type.getName()`. `String` tokens are exact, case-sensitive keys, so `provide('Foo')` and `get('foo')` are different tokens. Prefer `Type` overloads for Apex class/interface tokens, and reserve `String` tokens for deliberate aliases or configuration keys with stable casing.
- **Lazy Resolution:** By default, module imports are resolved lazily when a provider is first requested. The `.immediately()` method on a `ModuleImport` can be used to force eager resolution.
- **Runtime Arguments:** Runtime arguments are supported by `resolve(token, args)`, not `get(token, args)`. `get()` is the cached retrieval path and rejects runtime arguments so singleton/scoped cache semantics stay unambiguous.
- **Scopes:** The framework supports three provider lifetimes:
    - **`SINGLETON` (Default):** A single instance is created and shared for the entire transaction (i.e., for the life of the root `ModuleRef`).
    - **`PROTOTYPE`:** A new instance is created every time it is requested via `.resolve()`.
    - **`SCOPED`:** A single instance is created and shared _within a specific `ScopeRef`_. This is ideal for managing state within a unit of work. Scoped providers require an active `ScopeRef`; root `ModuleRef.get()` and root `ModuleRef.resolve()` both reject scoped providers.

#### Key Architectural Decisions:

- **Encapsulation & Safety:** The framework is architected with a `Container` base class to provide compile-time safety, ensuring that administrative methods like `replace()` and `refresh()` are only available on the root `ModuleRef`.
- **Exports:** A module can export providers defined in its own `providers()` list, or re-export providers from imported modules using `reexports()`.
- **Exported Provider Ownership:** Exported providers are resolved in the context of the module that owns the provider, not the consuming module. The owner module controls instantiation, singleton caching, scoped caching, and `Injectable` autowiring visibility. This means an exported provider can see private providers from its owner module, but it cannot see providers that are imported only by the consumer. For `SCOPED` exports, a consuming `ScopeRef` creates per-owner child scopes so the provider remains scoped to the active logical unit of work while preserving owner-module visibility.
- **Module Instance Identity:** `Di.import(moduleInstance)` and `Di.getModuleRef(moduleInstance)` bind the exact module instance into the registry. If a different module instance with the same token is already registered, the framework rejects it instead of silently reusing or ignoring either instance.
- **Global Modules:** The framework supports global modules loaded from Custom Metadata. These act as a fallback and their providers are available to all other modules.
- **Metadata Aliases:** Custom Metadata `Existing` providers are aliases/redirects in the container graph. They inherit the target provider's scope through normal `get()` / `resolve()` calls and are not directly executable provider instances.
- **Dynamic Modules:** `DynamicModule` allows for programmatic configuration but must be fully configured before being registered.
- **Runtime Modification:**
    - `ModuleRef.replace(newProvider)` is the safe way to replace a provider at runtime on the root container.
    - `ModuleRef.refresh()` allows a `DynamicModule` to be re-initialized within the root container.
- **Tooling & Reproducibility:** Local tooling is npm-based. `npm ci` installs the pinned Prettier dependencies, `npm run prettier:apex:check` checks Apex sources under `sfdx-source/apex-di`, and `npm run sfca:check` / `npm run sfca:check:detail` run Salesforce Code Analyzer against the same workspace with a moderate-severity failure threshold. The Flow analyzer engine is disabled because this package does not ship Flow sources and otherwise requires a local Python install. Salesforce test commands require an authenticated/default org unless a `--target-org` is supplied explicitly.
- **Automatic Circular Dependency Resolution:** The framework can automatically resolve instantiation-time circular dependencies between `Injectable` classes by using a two-pass instantiation process (create blank instance -> cache -> inject dependencies). It will still detect and throw an exception for unresolvable alias-based (`useExisting`) cycles.
- **Scope Integrity & Lazy Refresh:** To ensure consistency when modules are swapped at runtime (e.g., during tests), `ScopeRef` instances employ a **lazy refresh mechanism**. On every resolution, they check if their parent `ModuleRef` in the `Di` registry has changed. If a replacement is detected, `ScopeRef` automatically updates its parent reference and flushes its local "Unit of Work" cache to prevent serving stale dependencies.
- **Zero-Config & Silent Defaults:** The framework operates without complex configuration files or runtime toggles. It is designed to be **logging-free** by default. Shadowing of Global Modules by Local Modules is treated as a standard, implicit override.
- **Extensibility Philosophy:** complex resolution strategies (e.g., SObject-based resolution, flow factories) are delegated to user-implemented `Di.Factory` classes rather than being baked into the core framework.
