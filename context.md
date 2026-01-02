### Framework Context Summary

This is an advanced, NestJS-inspired Dependency Injection (DI) framework for Apex.

#### Core Components & Principles:

* **`Di.Module`:** An abstract class that serves as a blueprint. Concrete modules must implement `imports()`, `providers()`, and `exports()`.
* **`Di.Container`:** An abstract base class for dependency resolution.
    * **`Di.ModuleRef`:** The root runtime container for a module instance. It is responsible for provider resolution and caching.
    * **`Di.ScopeRef`:** A short-lived, child container created from a `ModuleRef` via `.createScope()`. It enables the "Unit of Work" pattern by providing its own cache for `SCOPED` providers.
* **Providers:** The framework supports multiple provider types:
    * **`useClass`:** Binds a token to a class constructor.
    * **`useValue`:** Binds a token to a literal value.
    * **`useFactory`:** Binds a token to the output of a factory class.
    * **`useExisting`:** Creates an alias for an existing provider token. It **respects the target provider's scope**: if the target is `PROTOTYPE`, the alias behaves as a prototype; if `SINGLETON`, it forces a singleton resolution.
* **Lazy Resolution:** By default, module imports are resolved lazily when a provider is first requested. The `.immediately()` method on a `ModuleImport` can be used to force eager resolution.
* **Scopes:** The framework supports three provider lifetimes:
    * **`SINGLETON` (Default):** A single instance is created and shared for the entire transaction (i.e., for the life of the root `ModuleRef`).
    * **`PROTOTYPE`:** A new instance is created every time it is requested via `.resolve()`.
    * **`SCOPED`:** A single instance is created and shared *within a specific `ScopeRef`*. This is ideal for managing state within a unit of work.

#### Key Architectural Decisions:

* **Encapsulation & Safety:** The framework is architected with a `Container` base class to provide compile-time safety, ensuring that administrative methods like `replace()` and `refresh()` are only available on the root `ModuleRef`.
* **Exports:** A module can export providers defined in its own `providers()` list, or re-export providers from imported modules using `reexports()`.
* **Global Modules:** The framework supports global modules loaded from Custom Metadata. These act as a fallback and their providers are available to all other modules.
* **Dynamic Modules:** `DynamicModule` allows for programmatic configuration but must be fully configured before being registered.
* **Runtime Modification:**
    * `ModuleRef.replace(newProvider)` is the safe way to replace a provider at runtime on the root container.
    * `ModuleRef.refresh()` allows a `DynamicModule` to be re-initialized within the root container.
* **Automatic Circular Dependency Resolution:** The framework can automatically resolve instantiation-time circular dependencies between `Injectable` classes by using a two-pass instantiation process (create blank instance -> cache -> inject dependencies). It will still detect and throw an exception for unresolvable alias-based (`useExisting`) cycles.
* **Scope Integrity & Lazy Refresh:** To ensure consistency when modules are swapped at runtime (e.g., during tests), `ScopeRef` instances employ a **lazy refresh mechanism**. On every resolution, they check if their parent `ModuleRef` in the `Di` registry has changed. If a replacement is detected, `ScopeRef` automatically updates its parent reference and flushes its local "Unit of Work" cache to prevent serving stale dependencies.
