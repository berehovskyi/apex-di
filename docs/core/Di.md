# Di Class

`APIVERSION: 67`
`STATUS: ACTIVE`

`Di` is the single public facade:
it organizes code into modules, binds tokens to providers, and resolves services through
module-aware containers. Static methods delegate to a shared default `ApplicationContext` ;
use `createContext()` to isolate independent graphs in the same transaction.

Designed for Apex's transaction model: module setup runs inside one transaction and provider
instances are cached only within it. Durable configuration lives in `DI_Module__mdt` and
`DI_Provider__mdt` , read only through the default `CustomMetadataSource` .

**See** Di.Module

**See** Di.ApplicationContext

**See** Di.ModuleRef

**See** Di.Provider

## Example

public class AccountsModule extends Di.Module {
public override Set<Di.Provider> providers() {
return new Set<Di.Provider>{
provide(AccountService.class).useClass(StdAccountService.class)
};
}
}

Di.ModuleRef ref = Di.getModuleRef(AccountsModule.class);
AccountService service = (AccountService) ref.get(AccountService.class);

## Methods

### `createContext()`

Creates a new, isolated application context backed by the default Custom Metadata source.
Use it to keep independent module graphs from interfering within one transaction.

#### Signature

```apex
public static ApplicationContext createContext();
```

#### Return Type

**ApplicationContext**

new application context

---

### `createContext(metadataSource)`

Creates a new application context backed by a custom metadata source, for example a test
fake that supplies module and provider definitions without Custom Metadata.

#### Signature

```apex
public static ApplicationContext createContext(MetadataSource metadataSource);
```

#### Parameters

| Name           | Type           | Description                                          |
| -------------- | -------------- | ---------------------------------------------------- |
| metadataSource | MetadataSource | source of normalized module and provider definitions |

#### Return Type

**ApplicationContext**

new application context

#### Throws

InvalidModuleException: when metadataSource is null

---

### `getModuleRef(module)`

Registers the module instance in the default context if it is not already registered and
returns its runtime handle.

#### Signature

```apex
public static ModuleRef getModuleRef(Module module);
```

#### Parameters

| Name   | Type   | Description             |
| ------ | ------ | ----------------------- |
| module | Module | module instance to bind |

#### Return Type

**ModuleRef**

runtime handle for the module

#### Throws

InvalidModuleException: when a different instance is already registered under the same token

---

### `getModuleRef(token)`

Returns the default-context handle for the module token, instantiating and registering the
module class on first use.

#### Signature

```apex
public static ModuleRef getModuleRef(String token);
```

#### Parameters

| Name  | Type   | Description                                |
| ----- | ------ | ------------------------------------------ |
| token | String | module token, typically an Apex class name |

#### Return Type

**ModuleRef**

runtime handle for the module

#### Throws

InvalidModuleException: when token is null or the class is not a Di.Module

UnknownModuleException: when no Apex type matches token

---

### `getModuleRef(moduleType)`

Returns the default-context handle for the module type, registering it on first use. This is
the typical entry point for controllers and trigger handlers.

#### Signature

```apex
public static ModuleRef getModuleRef(Type moduleType);
```

#### Parameters

| Name       | Type | Description  |
| ---------- | ---- | ------------ |
| moduleType | Type | module class |

#### Return Type

**ModuleRef**

runtime handle for the module

#### Throws

InvalidModuleException: when moduleType is null or does not name a Di.Module

UnknownModuleException: when the type cannot be resolved

#### Example

```apex
Di.ModuleRef ref = Di.getModuleRef(AppModule.class);
```

---

### `addModule(module)`

Registers a module locally in the default context and returns its handle. Registering after
resolution has begun invalidates previously issued handles.

#### Signature

```apex
public static ModuleRef addModule(Module module);
```

#### Parameters

| Name   | Type   | Description                 |
| ------ | ------ | --------------------------- |
| module | Module | module instance to register |

#### Return Type

**ModuleRef**

runtime handle for the module

#### Throws

InvalidModuleException: when module is null or conflicts with an existing registration

---

### `addGlobalModule(module)`

Registers a module globally in the default context so its exports become implicit fallback
providers for every module. Use sparingly for infrastructure such as logging or config.

#### Signature

```apex
public static ModuleRef addGlobalModule(Module module);
```

#### Parameters

| Name   | Type   | Description                          |
| ------ | ------ | ------------------------------------ |
| module | Module | module instance to register globally |

#### Return Type

**ModuleRef**

runtime handle for the module

#### Throws

InvalidModuleException: when module is null or conflicts with an existing registration

---

### `getMetadataModuleRef(developerName)`

Resolves the handle for a metadata-selected module by its `DI_Module__mdt` DeveloperName
alias. The alias selects an Apex module class; normal token identity rules then apply.

#### Signature

```apex
public static ModuleRef getMetadataModuleRef(String developerName);
```

#### Parameters

| Name          | Type   | Description                                        |
| ------------- | ------ | -------------------------------------------------- |
| developerName | String | `DI_Module__mdt` DeveloperName of an active module |

#### Return Type

**ModuleRef**

runtime handle for the selected module

#### Throws

InvalidModuleException: when the selected metadata module is inactive or invalid

UnknownModuleException: when no active metadata module matches developerName

---

### `replaceModule(token, newModule)`

Atomically replaces the module registered under token with a new definition, preserving its
visibility and invalidating previously issued handles.

#### Signature

```apex
public static void replaceModule(String token, Module newModule);
```

#### Parameters

| Name      | Type   | Description                    |
| --------- | ------ | ------------------------------ |
| token     | String | token of the module to replace |
| newModule | Module | replacement module definition  |

#### Return Type

**void**

#### Throws

InvalidModuleException: when token or newModule is null

UnknownModuleException: when no module is registered under token

---

### `replaceModule(token, newModule)`

Atomically replaces the module registered under token with a new definition, preserving its
visibility and invalidating previously issued handles.

#### Signature

```apex
public static void replaceModule(Type token, Module newModule);
```

#### Parameters

| Name      | Type   | Description                   |
| --------- | ------ | ----------------------------- |
| token     | Type   | type of the module to replace |
| newModule | Module | replacement module definition |

#### Return Type

**void**

#### Throws

InvalidModuleException: when token or newModule is null

UnknownModuleException: when no module is registered under token

---

### `replaceProvider(moduleToken, newProvider)`

Atomically replaces one provider in a registered module, invalidating previously issued
handles. The provider's own token selects the binding it overrides.

#### Signature

```apex
public static void replaceProvider(String moduleToken, Provider newProvider);
```

#### Parameters

| Name        | Type     | Description                                  |
| ----------- | -------- | -------------------------------------------- |
| moduleToken | String   | token of the module that owns the provider   |
| newProvider | Provider | replacement provider, keyed by its own token |

#### Return Type

**void**

#### Throws

InvalidModuleException: when moduleToken is null

InvalidProviderException: when newProvider is null

UnknownModuleException: when no module is registered under moduleToken

---

### `replaceProvider(moduleToken, newProvider)`

Atomically replaces one provider in a registered module, invalidating previously issued
handles. The provider's own token selects the binding it overrides.

#### Signature

```apex
public static void replaceProvider(Type moduleToken, Provider newProvider);
```

#### Parameters

| Name        | Type     | Description                                  |
| ----------- | -------- | -------------------------------------------- |
| moduleToken | Type     | type of the module that owns the provider    |
| newProvider | Provider | replacement provider, keyed by its own token |

#### Return Type

**void**

#### Throws

InvalidModuleException: when moduleToken is null

InvalidProviderException: when newProvider is null

UnknownModuleException: when no module is registered under moduleToken

---

### `import(module)`

Creates an import marker that binds the module instance into the importing module's graph.
Markers are inert until the owning module is registered.

#### Signature

```apex
public static ModuleImport import(Module module);
```

#### Parameters

| Name   | Type   | Description               |
| ------ | ------ | ------------------------- |
| module | Module | module instance to import |

#### Return Type

**ModuleImport**

import marker

---

### `import(token)`

Creates an import marker for the module identified by token.

#### Signature

```apex
public static ModuleImport import(String token);
```

#### Parameters

| Name  | Type   | Description                   |
| ----- | ------ | ----------------------------- |
| token | String | token of the module to import |

#### Return Type

**ModuleImport**

import marker

---

### `import(token)`

Creates an import marker for the given module type.

#### Signature

```apex
public static ModuleImport import(Type token);
```

#### Parameters

| Name  | Type | Description                  |
| ----- | ---- | ---------------------------- |
| token | Type | type of the module to import |

#### Return Type

**ModuleImport**

import marker

#### Example

```apex
return new Set<Di.ModuleImport>{ Di.import(AccountsModule.class) };
```

---

### `importMetadataModule(developerName)`

Creates an import marker for a metadata-selected module, identified by its `DI_Module__mdt`
DeveloperName alias.

#### Signature

```apex
public static ModuleImport importMetadataModule(String developerName);
```

#### Parameters

| Name          | Type   | Description                                            |
| ------------- | ------ | ------------------------------------------------------ |
| developerName | String | `DI_Module__mdt` DeveloperName of the module to import |

#### Return Type

**ModuleImport**

import marker

---

### `clear()`

Clears the default context: removes all registered modules, metadata overrides, and caches,
and starts a new lifecycle generation that invalidates previously issued handles.

#### Signature

```apex
public static void clear();
```

#### Return Type

**void**

---

### `describe()`

Returns a deterministic, defensively-copied snapshot of the default context's registered
modules and providers without instantiating any provider.

#### Signature

```apex
public static ContextDescription describe();
```

#### Return Type

**ContextDescription**

snapshot of the current graph

## Classes

### Module Class

Base class for modules. Extend it to group a cohesive set of providers and declare which are
visible to other modules through `imports()` , `providers()` , `exports()` , and `reexports()` .
Providers are private to their declaring module unless exported and imported.

A module is identified by a token: its Apex class name by default, or a custom token passed
to the constructor. Register a module with `Di.getModuleRef()` , `addModule()` , or
`addGlobalModule()` .

**See** Di.DynamicModule

**See** Di.ModuleRef

#### Example

public class AccountsModule extends Di.Module {
public override Set<Di.Provider> providers() {
return new Set<Di.Provider>{ provide(AccountService.class).useClass(AccountService.class) };
}
public override Set<String> exports() {
return new Set<String>{ AccountService.class.getName() };
}
}

#### Methods

##### `imports()`

Override to declare the modules whose exported providers this module can resolve. Returns
no imports by default.

###### Signature

```apex
public virtual Set<ModuleImport> imports();
```

###### Return Type

**Set<ModuleImport>**

import markers for modules this module depends on

---

##### `providers()`

Override to declare the providers this module owns. Returns no providers by default.

###### Signature

```apex
public virtual Set<Provider> providers();
```

###### Return Type

**Set<Provider>**

providers owned by this module

---

##### `exports()`

Override to declare the provider tokens this module exposes as its public API. Returns no
exports by default.

###### Signature

```apex
public virtual Set<String> exports();
```

###### Return Type

**Set<String>**

exported provider tokens

---

##### `reexports()`

Override to re-expose the exports of imported modules as this module's own. Returns
nothing by default.

###### Signature

```apex
public virtual Set<ModuleImport> reexports();
```

###### Return Type

**Set<ModuleImport>**

import markers whose exports are re-exported

---

##### `getProvider(token)`

Returns the provider definition bound to the token within this registered module, without
instantiating it.

###### Signature

```apex
public virtual Provider getProvider(String token);
```

###### Parameters

| Name  | Type   | Description    |
| ----- | ------ | -------------- |
| token | String | provider token |

###### Return Type

**Provider**

provider definition bound to token

###### Throws

InvalidContextException: when the module is not registered in a context

UnknownProviderException: when no visible provider matches token

---

##### `provide(token)`

Starts a fluent provider definition for the given type token. Use it inside `providers()` .

###### Signature

```apex
public virtual ProviderBuilder provide(Type token);
```

###### Parameters

| Name  | Type | Description         |
| ----- | ---- | ------------------- |
| token | Type | provider type token |

###### Return Type

**ProviderBuilder**

provider builder for token

###### Example

```apex
provide(ILogger.class).useClass(ConsoleLogger.class);
```

---

##### `provide(token)`

Starts a fluent provider definition for the given string token. Use it for configuration
keys or deliberate aliases.

###### Signature

```apex
public virtual ProviderBuilder provide(String token);
```

###### Parameters

| Name  | Type   | Description           |
| ----- | ------ | --------------------- |
| token | String | provider string token |

###### Return Type

**ProviderBuilder**

provider builder for token

---

##### `getToken()`

Returns this module's token.

###### Signature

```apex
public String getToken();
```

###### Return Type

**String**

module token

---

##### `hasImport(token)`

Returns whether this module declares an import for the given module token.

###### Signature

```apex
public Boolean hasImport(String token);
```

###### Parameters

| Name  | Type   | Description           |
| ----- | ------ | --------------------- |
| token | String | imported module token |

###### Return Type

**Boolean**

true when this module imports token

---

##### `hasProvider(token)`

Returns whether this module owns a provider for the given token.

###### Signature

```apex
public Boolean hasProvider(String token);
```

###### Parameters

| Name  | Type   | Description    |
| ----- | ------ | -------------- |
| token | String | provider token |

###### Return Type

**Boolean**

true when this module declares a provider for token

---

##### `hasExport(token)`

Returns whether this module exports the given provider token.

###### Signature

```apex
public Boolean hasExport(String token);
```

###### Parameters

| Name  | Type   | Description    |
| ----- | ------ | -------------- |
| token | String | provider token |

###### Return Type

**Boolean**

true when token is exported

---

##### `equals(obj)`

Compares modules by token: two modules are equal when their tokens match.

###### Signature

```apex
public Boolean equals(Object obj);
```

###### Parameters

| Name | Type   | Description       |
| ---- | ------ | ----------------- |
| obj  | Object | object to compare |

###### Return Type

**Boolean**

true when obj is a module with the same token

---

##### `hashCode()`

Returns a token-based hash code consistent with `equals()` .

###### Signature

```apex
public Integer hashCode();
```

###### Return Type

**Integer**

hash code derived from the module token

### Provider Class

Base class for the built-in provider strategies ( `ClassProvider` , `ValueProvider` ,
`FactoryProvider` , `ExistingProvider` , `CustomMetadataTypesProvider` ). A provider maps a
token to a creation strategy and a `Scope` . The model is closed: custom construction belongs
in a `Di.Factory` , not a custom subclass.

Build providers fluently with `Module.provide(token).use*()` , or instantiate the concrete
provider classes directly for replacement or focused tests.

**See** Di.ProviderBuilder

**See** Di.Factory

#### Methods

##### `resolve(container, args)`

Produces the instance for the bound token. Called by the container, not by application
code; resolve providers through `Container.get()` or `Container.resolve()` .

###### Signature

```apex
public abstract Object resolve(Container container, Object args);
```

###### Parameters

| Name      | Type      | Description                                            |
| --------- | --------- | ------------------------------------------------------ |
| container | Container | owning container that supplies collaborating providers |
| args      | Object    | runtime arguments, supported only by factory providers |

###### Return Type

**Object**

resolved instance

---

##### `getScope()`

Returns this provider's lifetime.

###### Signature

```apex
public virtual Scope getScope();
```

###### Return Type

**Scope**

configured scope

---

##### `scope(scopeType)`

Sets this provider's lifetime. Configure scope before registration; a committed provider
rejects further changes.

###### Signature

```apex
public virtual Provider scope(Scope scopeType);
```

###### Parameters

| Name      | Type  | Description        |
| --------- | ----- | ------------------ |
| scopeType | Scope | lifetime to assign |

###### Return Type

**Provider**

this provider for fluent chaining

###### Throws

InvalidScopeException: when scopeType is null

InvalidProviderException: when the provider is already committed

###### Example

```apex
provide(UnitOfWork.class).useClass(UnitOfWork.class).scope(Di.Scope.SCOPED);
```

---

##### `getToken()`

Returns the token this provider is bound to.

###### Signature

```apex
public String getToken();
```

###### Return Type

**String**

provider token

---

##### `equals(obj)`

Compares providers by token: two providers are equal when their tokens match.

###### Signature

```apex
public Boolean equals(Object obj);
```

###### Parameters

| Name | Type   | Description       |
| ---- | ------ | ----------------- |
| obj  | Object | object to compare |

###### Return Type

**Boolean**

true when obj is a provider with the same token

---

##### `hashCode()`

Returns a token-based hash code consistent with `equals()` .

###### Signature

```apex
public Integer hashCode();
```

###### Return Type

**Integer**

hash code derived from the provider token

### Container Class

Base class for dependency resolution. Exposes the resolution API — `get()` , `resolve()` ,
`tryGet()` , `tryResolve()` , `inject()` , and the `explain()` diagnostic — shared by the root
`ModuleRef` and short-lived `ScopeRef` . Resolution is owner-aware: an exported provider
resolves in its owner module's context.

**See** Di.ModuleRef

**See** Di.ScopeRef

#### Methods

##### `get(token, args)`

Returns the cached instance for the token. `get()` is the cached retrieval path: it
reuses the singleton (or scoped, within a `ScopeRef` ) instance and rejects runtime
arguments.

###### Signature

```apex
public virtual Object get(String token, Object args);
```

###### Parameters

| Name  | Type   | Description                                                                  |
| ----- | ------ | ---------------------------------------------------------------------------- |
| token | String | provider token to resolve                                                    |
| args  | Object | must be null; runtime arguments are supported only by `resolve(token, args)` |

###### Return Type

**Object**

cached instance bound to token

###### Throws

InvalidProviderException: when args is not null

UnknownProviderException: when no visible provider matches token

InvalidScopeException: when the provider is PROTOTYPE

---

##### `get(token, args)`

Type-token overload of `get(String, Object)` .

###### Signature

```apex
public virtual Object get(Type token, Object args);
```

###### Parameters

| Name  | Type   | Description         |
| ----- | ------ | ------------------- |
| token | Type   | provider type token |
| args  | Object | must be null        |

###### Return Type

**Object**

cached instance bound to token

---

##### `get(token)`

Returns the cached instance for the token.

###### Signature

```apex
public virtual Object get(String token);
```

###### Parameters

| Name  | Type   | Description               |
| ----- | ------ | ------------------------- |
| token | String | provider token to resolve |

###### Return Type

**Object**

cached instance bound to token

###### Throws

UnknownProviderException: when no visible provider matches token

InvalidScopeException: when the provider is PROTOTYPE

---

##### `get(token)`

Returns the cached instance for the type token.

###### Signature

```apex
public virtual Object get(Type token);
```

###### Parameters

| Name  | Type | Description         |
| ----- | ---- | ------------------- |
| token | Type | provider type token |

###### Return Type

**Object**

cached instance bound to token

###### Example

```apex
OrderService svc = (OrderService) ref.get(OrderService.class);
```

---

##### `tryGet(token)`

Optional cached retrieval: returns the cached instance for the token, or null when no
provider is visible. A visible but broken provider still throws — ambiguity, missing
dependencies, invalid metadata, cycles, and scope violations are not suppressed.

###### Signature

```apex
public virtual Object tryGet(String token);
```

###### Parameters

| Name  | Type   | Description               |
| ----- | ------ | ------------------------- |
| token | String | provider token to resolve |

###### Return Type

**Object**

cached instance bound to token, or null when token is not visible

---

##### `tryGet(token)`

Type-token overload of `tryGet(String)` .

###### Signature

```apex
public virtual Object tryGet(Type token);
```

###### Parameters

| Name  | Type | Description         |
| ----- | ---- | ------------------- |
| token | Type | provider type token |

###### Return Type

**Object**

cached instance bound to token, or null when token is not visible

---

##### `resolve(token, args)`

Creates a fresh instance for the token, passing optional runtime arguments to a factory
provider. Returns the singleton for `SINGLETON` providers and a new instance for
`PROTOTYPE` .

###### Signature

```apex
public virtual Object resolve(String token, Object args);
```

###### Parameters

| Name  | Type   | Description                                       |
| ----- | ------ | ------------------------------------------------- |
| token | String | provider token to resolve                         |
| args  | Object | runtime arguments for a factory provider, or null |

###### Return Type

**Object**

resolved instance bound to token

###### Throws

UnknownProviderException: when no visible provider matches token

InvalidProviderException: when args is supplied to a non-factory provider

###### Example

```apex
HttpClient client = (HttpClient) ref.resolve(HttpClient.class, new Map<String, Object>{ 'timeoutMs' => 5000 });
```

---

##### `resolve(token, args)`

Type-token overload of `resolve(String, Object)` .

###### Signature

```apex
public virtual Object resolve(Type token, Object args);
```

###### Parameters

| Name  | Type   | Description                                       |
| ----- | ------ | ------------------------------------------------- |
| token | Type   | provider type token                               |
| args  | Object | runtime arguments for a factory provider, or null |

###### Return Type

**Object**

resolved instance bound to token

---

##### `resolve(token)`

Creates a fresh instance for the token without runtime arguments.

###### Signature

```apex
public virtual Object resolve(String token);
```

###### Parameters

| Name  | Type   | Description               |
| ----- | ------ | ------------------------- |
| token | String | provider token to resolve |

###### Return Type

**Object**

resolved instance bound to token

###### Throws

UnknownProviderException: when no visible provider matches token

---

##### `resolve(token)`

Type-token overload of `resolve(String)` .

###### Signature

```apex
public virtual Object resolve(Type token);
```

###### Parameters

| Name  | Type | Description         |
| ----- | ---- | ------------------- |
| token | Type | provider type token |

###### Return Type

**Object**

resolved instance bound to token

---

##### `tryResolve(token, args)`

Optional fresh resolution: resolves the token with optional runtime arguments, or returns
null when no provider is visible. Like `tryGet()` , a visible but broken provider still
throws.

###### Signature

```apex
public virtual Object tryResolve(String token, Object args);
```

###### Parameters

| Name  | Type   | Description                                       |
| ----- | ------ | ------------------------------------------------- |
| token | String | provider token to resolve                         |
| args  | Object | runtime arguments for a factory provider, or null |

###### Return Type

**Object**

resolved instance bound to token, or null when token is not visible

---

##### `tryResolve(token, args)`

Type-token overload of `tryResolve(String, Object)` .

###### Signature

```apex
public virtual Object tryResolve(Type token, Object args);
```

###### Parameters

| Name  | Type   | Description                                       |
| ----- | ------ | ------------------------------------------------- |
| token | Type   | provider type token                               |
| args  | Object | runtime arguments for a factory provider, or null |

###### Return Type

**Object**

resolved instance bound to token, or null when token is not visible

---

##### `tryResolve(token)`

Optional fresh resolution without runtime arguments.

###### Signature

```apex
public virtual Object tryResolve(String token);
```

###### Parameters

| Name  | Type   | Description               |
| ----- | ------ | ------------------------- |
| token | String | provider token to resolve |

###### Return Type

**Object**

resolved instance bound to token, or null when token is not visible

---

##### `tryResolve(token)`

Type-token overload of `tryResolve(String)` .

###### Signature

```apex
public virtual Object tryResolve(Type token);
```

###### Parameters

| Name  | Type | Description         |
| ----- | ---- | ------------------- |
| token | Type | provider type token |

###### Return Type

**Object**

resolved instance bound to token, or null when token is not visible

---

##### `explain(token)`

Returns structured binding diagnostics for the token without instantiating any provider.
Reports whether it is resolved, missing, or ambiguous; the visibility source; owning
module; declared scope; alias redirect; and conflicting owners.

###### Signature

```apex
public virtual ResolutionExplanation explain(String token);
```

###### Parameters

| Name  | Type   | Description               |
| ----- | ------ | ------------------------- |
| token | String | provider token to explain |

###### Return Type

**ResolutionExplanation**

resolution explanation for token

###### Throws

InvalidProviderException: when token is null

---

##### `explain(token)`

Type-token overload of `explain(String)` .

###### Signature

```apex
public virtual ResolutionExplanation explain(Type token);
```

###### Parameters

| Name  | Type | Description         |
| ----- | ---- | ------------------- |
| token | Type | provider type token |

###### Return Type

**ResolutionExplanation**

resolution explanation for token

---

##### `inject(instance)`

Wires dependencies into an externally created object by calling its `Injectable.inject()` .
Strict: the instance must implement `Di.Injectable` .

###### Signature

```apex
public virtual Object inject(Object instance);
```

###### Parameters

| Name     | Type   | Description                        |
| -------- | ------ | ---------------------------------- |
| instance | Object | object to inject dependencies into |

###### Return Type

**Object**

the same instance, wired

###### Throws

InvalidClassException: when instance does not implement Di.Injectable

###### Example

```apex
OrderService service = new OrderService();
ref.inject(service);
```

---

##### `getModule()`

Returns the module backing this container.

###### Signature

```apex
public Module getModule();
```

###### Return Type

**Module**

backing module

###### Throws

InvalidContextException: when the handle belongs to a cleared lifecycle generation

### CustomMetadataSource Class

Default `MetadataSource` adapter. Normalizes module definitions from `DI_Module__mdt` and
provider definitions from `DI_Provider__mdt` for an `ApplicationContext` . This is the only
production path that reads Custom Metadata rows.

**Implements**

MetadataSource

#### Methods

##### `getModules()`

Returns module definitions normalized from all `DI_Module__mdt` records.

###### Signature

```apex
public Map<String,MetadataModuleDefinition> getModules();
```

###### Return Type

**Map<String,MetadataModuleDefinition>**

module definitions by DeveloperName

---

##### `getProviders()`

Returns provider definitions normalized from all `DI_Provider__mdt` records.

###### Signature

```apex
public Map<String,ProviderDefinition> getProviders();
```

###### Return Type

**Map<String,ProviderDefinition>**

provider definitions by DeveloperName

### MetadataModuleDefinition Class

Normalized definition of a metadata-selected module, decoupled from `DI_Module__mdt` . Supply
these from a custom `MetadataSource` , for example in tests.

#### Fields

##### `developerName`

DeveloperName alias that selects this module.

###### Signature

```apex
public final developerName;
```

###### Type

String

---

##### `moduleClass`

Fully qualified Apex module class name.

###### Signature

```apex
public final moduleClass;
```

###### Type

String

---

##### `isActive`

Whether the module can be selected.

###### Signature

```apex
public final isActive;
```

###### Type

Boolean

---

##### `isGlobal`

Whether the module loads as a global module.

###### Signature

```apex
public final isGlobal;
```

###### Type

Boolean

#### Constructors

##### `MetadataModuleDefinition(developerName, moduleClass, isActive, isGlobal)`

Creates a metadata module definition.

###### Signature

```apex
public MetadataModuleDefinition(String developerName, String moduleClass, Boolean isActive, Boolean isGlobal);
```

###### Parameters

| Name          | Type    | Description                            |
| ------------- | ------- | -------------------------------------- |
| developerName | String  | DeveloperName alias                    |
| moduleClass   | String  | fully qualified Apex module class name |
| isActive      | Boolean | whether the module can be selected     |
| isGlobal      | Boolean | whether the module loads as global     |

### ProviderDefinition Class

Normalized definition of a metadata-backed provider, decoupled from `DI_Provider__mdt` .
Supply these from a custom `MetadataSource` .

#### Fields

##### `developerName`

DeveloperName of the provider configuration.

###### Signature

```apex
public final developerName;
```

###### Type

String

---

##### `type`

Provider kind keyword, for example `Class` , `Value` , `Factory` , or `Existing` .

###### Signature

```apex
public final type;
```

###### Type

String

---

##### `value`

Provider value or target, interpreted per type.

###### Signature

```apex
public final value;
```

###### Type

String

---

##### `args`

Optional serialized runtime arguments.

###### Signature

```apex
public final args;
```

###### Type

String

---

##### `scope`

Declared scope keyword, or null for the default.

###### Signature

```apex
public final scope;
```

###### Type

String

---

##### `isActive`

Whether the provider configuration is active.

###### Signature

```apex
public final isActive;
```

###### Type

Boolean

#### Constructors

##### `ProviderDefinition(developerName, type, value, args, scope, isActive)`

Creates a provider definition.

###### Signature

```apex
public ProviderDefinition(String developerName, String type, String value, String args, String scope, Boolean isActive);
```

###### Parameters

| Name          | Type    | Description                                 |
| ------------- | ------- | ------------------------------------------- |
| developerName | String  | DeveloperName of the provider configuration |
| type          | String  | provider kind keyword                       |
| value         | String  | provider value or target                    |
| args          | String  | optional serialized runtime arguments       |
| scope         | String  | declared scope keyword, or null             |
| isActive      | Boolean | whether the provider is active              |

### ResolutionExplanation Class

Immutable result of `Container.explain()` . Describes how a token would resolve without
instantiating any provider.

**See** Di.ResolutionStatus

**See** Di.ResolutionSource

#### Fields

##### `token`

Token that was explained.

###### Signature

```apex
public final token;
```

###### Type

String

---

##### `requestingModule`

Token of the module the explanation was requested from.

###### Signature

```apex
public final requestingModule;
```

###### Type

String

---

##### `status`

Whether the token is resolved, missing, or ambiguous.

###### Signature

```apex
public final status;
```

###### Type

ResolutionStatus

---

##### `source`

Where the binding becomes visible: local, imported, implicit global, or none.

###### Signature

```apex
public final source;
```

###### Type

ResolutionSource

---

##### `ownerModule`

Token of the module that owns the resolved provider, or null.

###### Signature

```apex
public final ownerModule;
```

###### Type

String

---

##### `declaredScope`

Declared scope of the resolved provider, or null.

###### Signature

```apex
public final declaredScope;
```

###### Type

Scope

---

##### `redirectToken`

Alias target token for alias or metadata-backed providers, or null.

###### Signature

```apex
public final redirectToken;
```

###### Type

String

---

##### `conflictingModules`

Module tokens involved in an ambiguity.

###### Signature

```apex
public final conflictingModules;
```

###### Type

List<String>

### ContextDescription Class

Immutable snapshot of a context's registered modules and providers, returned by `describe()` .

#### Fields

##### `isCompiled`

Whether the context graph has been compiled.

###### Signature

```apex
public final isCompiled;
```

###### Type

Boolean

---

##### `modules`

Descriptions of registered modules.

###### Signature

```apex
public final modules;
```

###### Type

List<ModuleDescription>

### ModuleDescription Class

Immutable snapshot of one registered module within a `ContextDescription` .

#### Fields

##### `token`

Module token.

###### Signature

```apex
public final token;
```

###### Type

String

---

##### `isGlobal`

Whether the module is registered globally.

###### Signature

```apex
public final isGlobal;
```

###### Type

Boolean

---

##### `metadataAliases`

Metadata DeveloperName aliases that select this module.

###### Signature

```apex
public final metadataAliases;
```

###### Type

List<String>

---

##### `providers`

Descriptions of providers owned by this module.

###### Signature

```apex
public final providers;
```

###### Type

List<ProviderDescription>

---

##### `exports`

Exported provider tokens.

###### Signature

```apex
public final exports;
```

###### Type

List<String>

---

##### `imports`

Imported modules.

###### Signature

```apex
public final imports;
```

###### Type

List<ModuleImportDescription>

---

##### `reexports`

Re-exported modules.

###### Signature

```apex
public final reexports;
```

###### Type

List<ModuleImportDescription>

### ProviderDescription Class

Immutable snapshot of one provider within a `ModuleDescription` . Exposes structure only,
never values, factory instances, or caches.

#### Fields

##### `token`

Provider token.

###### Signature

```apex
public final token;
```

###### Type

String

---

##### `kind`

Provider strategy kind.

###### Signature

```apex
public final kind;
```

###### Type

ProviderKind

---

##### `configurationStatus`

Configuration health, reported for metadata-backed providers.

###### Signature

```apex
public final configurationStatus;
```

###### Type

ProviderConfigurationStatus

---

##### `declaredScope`

Declared scope.

###### Signature

```apex
public final declaredScope;
```

###### Type

Scope

---

##### `redirectToken`

Alias target token for alias or metadata-backed providers, or null.

###### Signature

```apex
public final redirectToken;
```

###### Type

String

---

##### `isExported`

Whether the provider is exported by its module.

###### Signature

```apex
public final isExported;
```

###### Type

Boolean

### ModuleImportDescription Class

Immutable snapshot of one module import or re-export within a `ModuleDescription` .

#### Fields

##### `token`

Imported module token.

###### Signature

```apex
public final token;
```

###### Type

String

---

##### `isEager`

Whether the import is marked for eager registration.

###### Signature

```apex
public final isEager;
```

###### Type

Boolean

---

##### `metadataAlias`

Metadata DeveloperName alias when the import is metadata-selected, or null.

###### Signature

```apex
public final metadataAlias;
```

###### Type

String

### ApplicationContext Class

Runtime owner of a module graph: module registries, singleton runtimes, the global-binding
and visible-provider indexes, and metadata cache state. The static `Di` facade delegates to a
shared default context; create explicit contexts with `Di.createContext()` to isolate graphs
or supply a custom metadata source.

The first top-level `get()` or `resolve()` opens the lifecycle; afterwards, successful
external mutations ( `addModule` , `replaceProvider` , `replaceModule` , `clear` ) start a new
generation and invalidate previously issued handles.

**See** Di.ModuleRef

**See** Di.MetadataSource

#### Constructors

##### `ApplicationContext()`

Creates a context backed by the default `CustomMetadataSource` .

###### Signature

```apex
public ApplicationContext();
```

---

##### `ApplicationContext(metadataSource)`

Creates a context backed by a custom metadata source.

###### Signature

```apex
public ApplicationContext(MetadataSource metadataSource);
```

###### Parameters

| Name           | Type           | Description                                          |
| -------------- | -------------- | ---------------------------------------------------- |
| metadataSource | MetadataSource | source of normalized module and provider definitions |

###### Throws

InvalidModuleException: when metadataSource is null

#### Methods

##### `getModuleRef(module)`

Registers the module instance in this context if needed and returns its runtime handle.

###### Signature

```apex
public ModuleRef getModuleRef(Module module);
```

###### Parameters

| Name   | Type   | Description             |
| ------ | ------ | ----------------------- |
| module | Module | module instance to bind |

###### Return Type

**ModuleRef**

runtime handle for the module

###### Throws

InvalidModuleException: when a different instance is already registered under the same token

---

##### `getModuleRef(token)`

Returns this context's handle for the module token, instantiating and registering the
class on first use.

###### Signature

```apex
public ModuleRef getModuleRef(String token);
```

###### Parameters

| Name  | Type   | Description                                |
| ----- | ------ | ------------------------------------------ |
| token | String | module token, typically an Apex class name |

###### Return Type

**ModuleRef**

runtime handle for the module

###### Throws

InvalidModuleException: when token is null or the class is not a Di.Module

UnknownModuleException: when no Apex type matches token

---

##### `getModuleRef(moduleType)`

Returns this context's handle for the module type, registering it on first use.

###### Signature

```apex
public ModuleRef getModuleRef(Type moduleType);
```

###### Parameters

| Name       | Type | Description  |
| ---------- | ---- | ------------ |
| moduleType | Type | module class |

###### Return Type

**ModuleRef**

runtime handle for the module

###### Throws

InvalidModuleException: when moduleType is null or does not name a Di.Module

UnknownModuleException: when the type cannot be resolved

---

##### `addModule(module)`

Registers a module locally in this context and returns its handle.

###### Signature

```apex
public ModuleRef addModule(Module module);
```

###### Parameters

| Name   | Type   | Description                 |
| ------ | ------ | --------------------------- |
| module | Module | module instance to register |

###### Return Type

**ModuleRef**

runtime handle for the module

###### Throws

InvalidModuleException: when module is null or conflicts with an existing registration

---

##### `addGlobalModule(module)`

Registers a module globally in this context so its exports become implicit fallback
providers for every module.

###### Signature

```apex
public ModuleRef addGlobalModule(Module module);
```

###### Parameters

| Name   | Type   | Description                          |
| ------ | ------ | ------------------------------------ |
| module | Module | module instance to register globally |

###### Return Type

**ModuleRef**

runtime handle for the module

###### Throws

InvalidModuleException: when module is null or conflicts with an existing registration

---

##### `getMetadataModuleRef(developerName)`

Resolves the handle for a metadata-selected module by its `DI_Module__mdt` DeveloperName
alias.

###### Signature

```apex
public ModuleRef getMetadataModuleRef(String developerName);
```

###### Parameters

| Name          | Type   | Description                                |
| ------------- | ------ | ------------------------------------------ |
| developerName | String | DeveloperName of an active metadata module |

###### Return Type

**ModuleRef**

runtime handle for the selected module

###### Throws

InvalidModuleException: when the selected metadata module is inactive or invalid

UnknownModuleException: when no active metadata module matches developerName

---

##### `replaceProvider(moduleToken, newProvider)`

Atomically replaces one provider in a registered module, invalidating previously issued
handles. The provider's own token selects the binding it overrides.

###### Signature

```apex
public void replaceProvider(String moduleToken, Provider newProvider);
```

###### Parameters

| Name        | Type     | Description                                  |
| ----------- | -------- | -------------------------------------------- |
| moduleToken | String   | token of the module that owns the provider   |
| newProvider | Provider | replacement provider, keyed by its own token |

###### Return Type

**void**

###### Throws

InvalidModuleException: when moduleToken is null

InvalidProviderException: when newProvider is null

UnknownModuleException: when no module is registered under moduleToken

---

##### `replaceProvider(moduleToken, newProvider)`

Type-token overload of `replaceProvider(String, Provider)` .

###### Signature

```apex
public void replaceProvider(Type moduleToken, Provider newProvider);
```

###### Parameters

| Name        | Type     | Description                                  |
| ----------- | -------- | -------------------------------------------- |
| moduleToken | Type     | type of the module that owns the provider    |
| newProvider | Provider | replacement provider, keyed by its own token |

###### Return Type

**void**

###### Throws

InvalidModuleException: when moduleToken is null

InvalidProviderException: when newProvider is null

UnknownModuleException: when no module is registered under moduleToken

---

##### `replaceModule(token, newModule)`

Atomically replaces the module registered under token with a new definition, preserving
its visibility and invalidating previously issued handles.

###### Signature

```apex
public void replaceModule(String token, Module newModule);
```

###### Parameters

| Name      | Type   | Description                    |
| --------- | ------ | ------------------------------ |
| token     | String | token of the module to replace |
| newModule | Module | replacement module definition  |

###### Return Type

**void**

###### Throws

InvalidModuleException: when token or newModule is null

UnknownModuleException: when no module is registered under token

---

##### `replaceModule(token, newModule)`

Type-token overload of `replaceModule(String, Module)` .

###### Signature

```apex
public void replaceModule(Type token, Module newModule);
```

###### Parameters

| Name      | Type   | Description                   |
| --------- | ------ | ----------------------------- |
| token     | Type   | type of the module to replace |
| newModule | Module | replacement module definition |

###### Return Type

**void**

###### Throws

InvalidModuleException: when token or newModule is null

UnknownModuleException: when no module is registered under token

---

##### `import(module)`

Creates an import marker for the module instance, bound to this context.

###### Signature

```apex
public ModuleImport import(Module module);
```

###### Parameters

| Name   | Type   | Description               |
| ------ | ------ | ------------------------- |
| module | Module | module instance to import |

###### Return Type

**ModuleImport**

import marker

---

##### `import(token)`

Creates an import marker for the module token.

###### Signature

```apex
public ModuleImport import(String token);
```

###### Parameters

| Name  | Type   | Description                   |
| ----- | ------ | ----------------------------- |
| token | String | token of the module to import |

###### Return Type

**ModuleImport**

import marker

---

##### `import(token)`

Creates an import marker for the module type.

###### Signature

```apex
public ModuleImport import(Type token);
```

###### Parameters

| Name  | Type | Description                  |
| ----- | ---- | ---------------------------- |
| token | Type | type of the module to import |

###### Return Type

**ModuleImport**

import marker

---

##### `importMetadataModule(developerName)`

Creates an import marker for a metadata-selected module by its DeveloperName alias.

###### Signature

```apex
public ModuleImport importMetadataModule(String developerName);
```

###### Parameters

| Name          | Type   | Description                           |
| ------------- | ------ | ------------------------------------- |
| developerName | String | DeveloperName of the module to import |

###### Return Type

**ModuleImport**

import marker

---

##### `compile()`

Eagerly resolves lazy imports, validates visibility, and completes the provider index for
every registered module. Optional: resolution works lazily without it. Requires an acyclic
module-import graph.

###### Signature

```apex
public ApplicationContext compile();
```

###### Return Type

**ApplicationContext**

this context for fluent chaining

###### Throws

InvalidModuleException: when the module-import graph contains a cycle

---

##### `describe()`

Returns a deterministic, defensively-copied snapshot of registered modules and providers
without instantiating any provider. Call `compile()` first to include the complete
reachable graph.

###### Signature

```apex
public ContextDescription describe();
```

###### Return Type

**ContextDescription**

snapshot of the current graph

---

##### `clear()`

Clears this context: removes all registered modules, metadata overrides, and caches, and
starts a new lifecycle generation that invalidates previously issued handles.

###### Signature

```apex
public void clear();
```

###### Return Type

**void**

### DynamicModule Class

Module assembled programmatically rather than by subclassing `Module` . Configure it with
`addProvider` , `addImport` , `addExport` , and `addReexport` , then register it with
`addModule()` or `replaceModule()` . Useful for tests and configurable composition. Successful
registration seals it permanently.

#### Example

Di.DynamicModule module = new Di.DynamicModule('CalloutConfigModule');
module.addProvider(module.provide('OrdersApiEndpoint').useValue('callout:OrdersApi/v1'));
module.addExport('OrdersApiEndpoint');
Di.ModuleRef ref = Di.addModule(module);

#### Constructors

##### `DynamicModule(token)`

Creates an unsealed dynamic module with the given token.

###### Signature

```apex
public DynamicModule(String token);
```

###### Parameters

| Name  | Type   | Description  |
| ----- | ------ | ------------ |
| token | String | module token |

###### Throws

InvalidModuleException: when token is null

#### Methods

##### `imports()`

Returns the imports added with `addImport` .

###### Signature

```apex
public override Set<ModuleImport> imports();
```

###### Return Type

**Set<ModuleImport>**

configured imports

---

##### `providers()`

Returns the providers added with `addProvider` .

###### Signature

```apex
public override Set<Provider> providers();
```

###### Return Type

**Set<Provider>**

configured providers

---

##### `exports()`

Returns the export tokens added with `addExport` .

###### Signature

```apex
public override Set<String> exports();
```

###### Return Type

**Set<String>**

configured export tokens

---

##### `reexports()`

Returns the re-exports added with `addReexport` .

###### Signature

```apex
public override Set<ModuleImport> reexports();
```

###### Return Type

**Set<ModuleImport>**

configured re-exports

---

##### `addImport(moduleImport)`

Adds a module import. Allowed only before registration seals the module.

###### Signature

```apex
public DynamicModule addImport(ModuleImport moduleImport);
```

###### Parameters

| Name         | Type         | Description          |
| ------------ | ------------ | -------------------- |
| moduleImport | ModuleImport | import marker to add |

###### Return Type

**DynamicModule**

this module for fluent chaining

###### Throws

InvalidModuleException: when the module is sealed or moduleImport is null

---

##### `addProvider(provider)`

Adds a provider, keyed by its token. Allowed only before registration seals the module.

###### Signature

```apex
public DynamicModule addProvider(Provider provider);
```

###### Parameters

| Name     | Type     | Description     |
| -------- | -------- | --------------- |
| provider | Provider | provider to add |

###### Return Type

**DynamicModule**

this module for fluent chaining

###### Throws

InvalidModuleException: when the module is sealed

InvalidProviderException: when provider is null

---

##### `addExport(token)`

Exports a provider token. Allowed only before registration seals the module.

###### Signature

```apex
public DynamicModule addExport(String token);
```

###### Parameters

| Name  | Type   | Description              |
| ----- | ------ | ------------------------ |
| token | String | provider token to export |

###### Return Type

**DynamicModule**

this module for fluent chaining

###### Throws

InvalidModuleException: when the module is sealed

InvalidProviderException: when token is null

---

##### `addReexport(moduleImport)`

Re-exports an imported module's exports. Allowed only before registration seals the
module.

###### Signature

```apex
public DynamicModule addReexport(ModuleImport moduleImport);
```

###### Parameters

| Name         | Type         | Description                |
| ------------ | ------------ | -------------------------- |
| moduleImport | ModuleImport | import marker to re-export |

###### Return Type

**DynamicModule**

this module for fluent chaining

###### Throws

InvalidModuleException: when the module is sealed or moduleImport is null

### ProviderBuilder Class

Fluent builder returned by `Module.provide(token)` . Terminal `use*` methods produce a typed
provider bound to the token; chain `scope()` on the result to set its lifetime.

**See** Di.Provider

#### Methods

##### `useClass(type)`

Binds the token to a class by name.

###### Signature

```apex
public ClassProvider useClass(String type);
```

###### Parameters

| Name | Type   | Description                                    |
| ---- | ------ | ---------------------------------------------- |
| type | String | fully qualified Apex class name to instantiate |

###### Return Type

**ClassProvider**

class provider for the token

---

##### `useClass(type)`

Binds the token to a class.

###### Signature

```apex
public ClassProvider useClass(Type type);
```

###### Parameters

| Name | Type | Description               |
| ---- | ---- | ------------------------- |
| type | Type | Apex class to instantiate |

###### Return Type

**ClassProvider**

class provider for the token

---

##### `useValue(value)`

Binds the token to a literal value.

###### Signature

```apex
public ValueProvider useValue(Object value);
```

###### Parameters

| Name  | Type   | Description                   |
| ----- | ------ | ----------------------------- |
| value | Object | value to return on resolution |

###### Return Type

**ValueProvider**

value provider for the token

---

##### `useFactory(factory)`

Binds the token to a factory instance.

###### Signature

```apex
public FactoryProvider useFactory(Factory factory);
```

###### Parameters

| Name    | Type    | Description                          |
| ------- | ------- | ------------------------------------ |
| factory | Factory | factory that constructs the instance |

###### Return Type

**FactoryProvider**

factory provider for the token

---

##### `useFactory(factoryType)`

Binds the token to a factory by class name.

###### Signature

```apex
public FactoryProvider useFactory(String factoryType);
```

###### Parameters

| Name        | Type   | Description                             |
| ----------- | ------ | --------------------------------------- |
| factoryType | String | fully qualified `Di.Factory` class name |

###### Return Type

**FactoryProvider**

factory provider for the token

---

##### `useFactory(factoryType)`

Binds the token to a factory class.

###### Signature

```apex
public FactoryProvider useFactory(Type factoryType);
```

###### Parameters

| Name        | Type | Description        |
| ----------- | ---- | ------------------ |
| factoryType | Type | `Di.Factory` class |

###### Return Type

**FactoryProvider**

factory provider for the token

---

##### `useExisting(existingToken)`

Aliases the token to another provider token.

###### Signature

```apex
public ExistingProvider useExisting(String existingToken);
```

###### Parameters

| Name          | Type   | Description           |
| ------------- | ------ | --------------------- |
| existingToken | String | target provider token |

###### Return Type

**ExistingProvider**

alias provider for the token

---

##### `useExisting(existingToken)`

Aliases the token to another provider type.

###### Signature

```apex
public ExistingProvider useExisting(Type existingToken);
```

###### Parameters

| Name          | Type | Description          |
| ------------- | ---- | -------------------- |
| existingToken | Type | target provider type |

###### Return Type

**ExistingProvider**

alias provider for the token

---

##### `useMetadata(developerName)`

Binds the token to a `DI_Provider__mdt` configuration by DeveloperName.

###### Signature

```apex
public CustomMetadataTypesProvider useMetadata(String developerName);
```

###### Parameters

| Name          | Type   | Description                      |
| ------------- | ------ | -------------------------------- |
| developerName | String | `DI_Provider__mdt` DeveloperName |

###### Return Type

**CustomMetadataTypesProvider**

metadata provider for the token

### ClassProvider Class

Provider that binds a token to an Apex class and instantiates it on resolution. The class
must have a public no-argument constructor. If the instance implements `Di.Injectable` , it is
wired after construction.

#### Constructors

##### `ClassProvider(token, type)`

Creates a class provider binding a string token to a class name.

###### Signature

```apex
public ClassProvider(String token, String type);
```

###### Parameters

| Name  | Type   | Description                                    |
| ----- | ------ | ---------------------------------------------- |
| token | String | provider token                                 |
| type  | String | fully qualified Apex class name to instantiate |

###### Throws

InvalidProviderException: when token or type is null

---

##### `ClassProvider(token, type)`

Creates a class provider binding a string token to a class.

###### Signature

```apex
public ClassProvider(String token, Type type);
```

###### Parameters

| Name  | Type   | Description               |
| ----- | ------ | ------------------------- |
| token | String | provider token            |
| type  | Type   | Apex class to instantiate |

---

##### `ClassProvider(token, type)`

Creates a class provider binding a type token to a class name.

###### Signature

```apex
public ClassProvider(Type token, String type);
```

###### Parameters

| Name  | Type   | Description                                    |
| ----- | ------ | ---------------------------------------------- |
| token | Type   | provider type token                            |
| type  | String | fully qualified Apex class name to instantiate |

---

##### `ClassProvider(token, type)`

Creates a class provider binding a type token to a class.

###### Signature

```apex
public ClassProvider(Type token, Type type);
```

###### Parameters

| Name  | Type | Description               |
| ----- | ---- | ------------------------- |
| token | Type | provider type token       |
| type  | Type | Apex class to instantiate |

#### Methods

##### `resolve(container, args)`

Instantiates the bound class.

###### Signature

```apex
public override Object resolve(Container container, Object args);
```

###### Parameters

| Name      | Type      | Description                                                   |
| --------- | --------- | ------------------------------------------------------------- |
| container | Container | owning container                                              |
| args      | Object    | must be null; class providers do not accept runtime arguments |

###### Return Type

**Object**

new instance of the bound class

###### Throws

InvalidProviderException: when args is not null

---

##### `getType()`

Returns the bound class name.

###### Signature

```apex
public String getType();
```

###### Return Type

**String**

fully qualified class name

### ValueProvider Class

Provider that binds a token to a literal value and returns it on every resolution. Useful for
configuration, feature flags, and test doubles.

#### Constructors

##### `ValueProvider(token, value)`

Creates a value provider binding a string token to a value.

###### Signature

```apex
public ValueProvider(String token, Object value);
```

###### Parameters

| Name  | Type   | Description                   |
| ----- | ------ | ----------------------------- |
| token | String | provider token                |
| value | Object | value to return on resolution |

###### Throws

InvalidProviderException: when token is null

---

##### `ValueProvider(token, value)`

Creates a value provider binding a type token to a value.

###### Signature

```apex
public ValueProvider(Type token, Object value);
```

###### Parameters

| Name  | Type   | Description                   |
| ----- | ------ | ----------------------------- |
| token | Type   | provider type token           |
| value | Object | value to return on resolution |

#### Methods

##### `resolve(container, args)`

Returns the bound value.

###### Signature

```apex
public override Object resolve(Container container, Object args);
```

###### Parameters

| Name      | Type      | Description                                                   |
| --------- | --------- | ------------------------------------------------------------- |
| container | Container | owning container                                              |
| args      | Object    | must be null; value providers do not accept runtime arguments |

###### Return Type

**Object**

the bound value

###### Throws

InvalidProviderException: when args is not null

### FactoryProvider Class

Provider that delegates construction to a `Di.Factory` . The factory receives the owning
container and optional runtime arguments, so it can resolve collaborators and build
configured instances.

#### Constructors

##### `FactoryProvider(token, factory)`

Creates a factory provider from a factory instance.

###### Signature

```apex
public FactoryProvider(String token, Factory factory);
```

###### Parameters

| Name    | Type    | Description                          |
| ------- | ------- | ------------------------------------ |
| token   | String  | provider token                       |
| factory | Factory | factory that constructs the instance |

###### Throws

InvalidProviderException: when factory is null

---

##### `FactoryProvider(token, factoryType)`

Creates a factory provider from a factory class name.

###### Signature

```apex
public FactoryProvider(String token, String factoryType);
```

###### Parameters

| Name        | Type   | Description                |
| ----------- | ------ | -------------------------- |
| token       | String | provider token             |
| factoryType | String | fully qualified class name |

###### Throws

InvalidClassException: when factoryType cannot be instantiated as a Di.Factory

---

##### `FactoryProvider(token, factoryType)`

Creates a factory provider from a factory class.

###### Signature

```apex
public FactoryProvider(String token, Type factoryType);
```

###### Parameters

| Name        | Type   | Description    |
| ----------- | ------ | -------------- |
| token       | String | provider token |
| factoryType | Type   | class          |

---

##### `FactoryProvider(token, factory)`

Creates a factory provider from a factory instance, with a type token.

###### Signature

```apex
public FactoryProvider(Type token, Factory factory);
```

###### Parameters

| Name    | Type    | Description                          |
| ------- | ------- | ------------------------------------ |
| token   | Type    | provider type token                  |
| factory | Factory | factory that constructs the instance |

---

##### `FactoryProvider(token, factoryType)`

Creates a factory provider from a factory class name, with a type token.

###### Signature

```apex
public FactoryProvider(Type token, String factoryType);
```

###### Parameters

| Name        | Type   | Description                |
| ----------- | ------ | -------------------------- |
| token       | Type   | provider type token        |
| factoryType | String | fully qualified class name |

---

##### `FactoryProvider(token, factoryType)`

Creates a factory provider from a factory class, with a type token.

###### Signature

```apex
public FactoryProvider(Type token, Type factoryType);
```

###### Parameters

| Name        | Type | Description         |
| ----------- | ---- | ------------------- |
| token       | Type | provider type token |
| factoryType | Type | class               |

#### Methods

##### `resolve(container, args)`

Delegates to the factory's `newInstance` .

###### Signature

```apex
public override Object resolve(Container container, Object args);
```

###### Parameters

| Name      | Type      | Description                                      |
| --------- | --------- | ------------------------------------------------ |
| container | Container | owning container, passed to the factory          |
| args      | Object    | runtime arguments passed to the factory, or null |

###### Return Type

**Object**

instance produced by the factory

### ExistingProvider Class

Alias provider that redirects a token to another provider token. It is a redirect, not an
executable provider: the target's scope and instance behavior apply. Resolve aliases through
the container, not by calling `resolve()` directly.

#### Constructors

##### `ExistingProvider(token, existing)`

Creates an alias from a string token to a target token.

###### Signature

```apex
public ExistingProvider(String token, String existing);
```

###### Parameters

| Name     | Type   | Description           |
| -------- | ------ | --------------------- |
| token    | String | alias token           |
| existing | String | target provider token |

###### Throws

InvalidProviderException: when token or existing is null

---

##### `ExistingProvider(token, existing)`

Creates an alias from a string token to a target type.

###### Signature

```apex
public ExistingProvider(String token, Type existing);
```

###### Parameters

| Name     | Type   | Description          |
| -------- | ------ | -------------------- |
| token    | String | alias token          |
| existing | Type   | target provider type |

---

##### `ExistingProvider(token, existing)`

Creates an alias from a type token to a target token.

###### Signature

```apex
public ExistingProvider(Type token, String existing);
```

###### Parameters

| Name     | Type   | Description           |
| -------- | ------ | --------------------- |
| token    | Type   | alias type token      |
| existing | String | target provider token |

---

##### `ExistingProvider(token, existing)`

Creates an alias from a type token to a target type.

###### Signature

```apex
public ExistingProvider(Type token, Type existing);
```

###### Parameters

| Name     | Type | Description          |
| -------- | ---- | -------------------- |
| token    | Type | alias type token     |
| existing | Type | target provider type |

#### Methods

##### `resolve(container, args)`

Always throws: aliases are redirects resolved by the container, not directly.

###### Signature

```apex
public override Object resolve(Container container, Object args);
```

###### Parameters

| Name      | Type      | Description      |
| --------- | --------- | ---------------- |
| container | Container | owning container |
| args      | Object    | ignored          |

###### Return Type

**Object**

never returns

###### Throws

InvalidProviderException: always

---

##### `getExisting()`

Returns the alias target token.

###### Signature

```apex
public String getExisting();
```

###### Return Type

**String**

target provider token

### CustomMetadataTypesProvider Class

Provider that resolves its configuration from `DI_Provider__mdt` (or a custom
`MetadataSource` ) by DeveloperName at resolution time, then delegates to the matching class,
value, or factory provider. Its scope follows the metadata configuration.

#### Constructors

##### `CustomMetadataTypesProvider(token, developerName)`

Creates a metadata provider bound to a `DI_Provider__mdt` DeveloperName.

###### Signature

```apex
public CustomMetadataTypesProvider(String token, String developerName);
```

###### Parameters

| Name          | Type   | Description    |
| ------------- | ------ | -------------- |
| token         | String | provider token |
| developerName | String | DeveloperName  |

###### Throws

InvalidProviderException: when developerName is blank

#### Methods

##### `getScope()`

Returns the scope declared in metadata for the default context, or the configured scope
when metadata does not specify one.

###### Signature

```apex
public override Scope getScope();
```

###### Return Type

**Scope**

effective scope

---

##### `resolve(container, args)`

Reads the metadata definition and delegates to the matching class, value, or factory
provider.

###### Signature

```apex
public override Object resolve(Container container, Object args);
```

###### Parameters

| Name      | Type      | Description                                                                     |
| --------- | --------- | ------------------------------------------------------------------------------- |
| container | Container | owning container, whose context supplies the metadata definition                |
| args      | Object    | runtime arguments for a factory definition; override metadata args when present |

###### Return Type

**Object**

resolved instance

###### Throws

InvalidProviderException: when the metadata configuration is missing or invalid

---

##### `getExisting()`

Returns the alias target token when the metadata definition is an alias, using the
default context, or null otherwise.

###### Signature

```apex
public String getExisting();
```

###### Return Type

**String**

alias target token, or null

### ModuleRef Class

Root runtime container for a registered module. Created only by an `ApplicationContext`
( `getModuleRef` / `addModule` ), so registration, graph ownership, and singleton caching are
committed together. Adds `createScope()` and cache administration to the `Container`
resolution API. Root resolution rejects scoped providers.

**See** Di.ScopeRef

#### Methods

##### `createScope()`

Creates a child scope with a fresh `ScopeContext` for resolving `SCOPED` providers as one
unit of work.

###### Signature

```apex
public ScopeRef createScope();
```

###### Return Type

**ScopeRef**

new scope handle

---

##### `createScope(scopeContext)`

Creates a child scope that joins a shared `ScopeContext` , so module refs in the same
application context can share `SCOPED` instances within one unit of work.

###### Signature

```apex
public ScopeRef createScope(ScopeContext scopeContext);
```

###### Parameters

| Name         | Type         | Description                  |
| ------------ | ------------ | ---------------------------- |
| scopeContext | ScopeContext | shared scope context to join |

###### Return Type

**ScopeRef**

new scope handle

###### Throws

InvalidScopeException: when scopeContext is null

---

##### `resolve(token, args)`

Creates a fresh instance for the token at the module root. See
`Container.resolve(String, Object)` .

###### Signature

```apex
public override Object resolve(String token, Object args);
```

###### Parameters

| Name  | Type   | Description                                       |
| ----- | ------ | ------------------------------------------------- |
| token | String | provider token to resolve                         |
| args  | Object | runtime arguments for a factory provider, or null |

###### Return Type

**Object**

resolved instance bound to token

---

##### `clearCache()`

Clears this module's singleton cache, forcing singletons to be rebuilt on next
resolution.

###### Signature

```apex
public void clearCache();
```

###### Return Type

**void**

###### Throws

InvalidContextException: when the handle belongs to a cleared lifecycle generation

### ScopeContext Class

Explicit cache for one logical scope (unit of work). `ModuleRef.createScope()` creates a
fresh context; passing the same `ScopeContext` to several module refs lets them share
`SCOPED` instances by owner module and provider token. A scope context binds to one
application context and rejects cross-context reuse.

**See** Di.ScopeRef

#### Example

Di.ScopeContext unitOfWork = new Di.ScopeContext();
Di.ScopeRef salesScope = salesRef.createScope(unitOfWork);
Di.ScopeRef accountsScope = accountsRef.createScope(unitOfWork);

#### Methods

##### `clear()`

Resets the shared unit of work: discards all `SCOPED` instances cached in this context.

###### Signature

```apex
public void clear();
```

###### Return Type

**void**

### ScopeRef Class

Short-lived child container for a unit of work, created by `ModuleRef.createScope()` . Shares
singleton identity with its parent module and caches `SCOPED` providers in its `ScopeContext` .
Overrides the resolution API to synchronize the scope before each top-level call. A successful
external graph mutation makes a held scope stale.

**See** Di.ScopeContext

#### Methods

##### `get(token, args)`

Returns the cached instance for the token within this scope, synchronizing the scope
first. See `Container.get(String, Object)` .

###### Signature

```apex
public override Object get(String token, Object args);
```

###### Parameters

| Name  | Type   | Description               |
| ----- | ------ | ------------------------- |
| token | String | provider token to resolve |
| args  | Object | must be null              |

###### Return Type

**Object**

cached instance bound to token

---

##### `resolve(token, args)`

Creates a fresh instance for the token within this scope, synchronizing the scope first.
See `Container.resolve(String, Object)` .

###### Signature

```apex
public override Object resolve(String token, Object args);
```

###### Parameters

| Name  | Type   | Description                                       |
| ----- | ------ | ------------------------------------------------- |
| token | String | provider token to resolve                         |
| args  | Object | runtime arguments for a factory provider, or null |

###### Return Type

**Object**

resolved instance bound to token

---

##### `tryGet(token)`

Optional cached retrieval within this scope, or null when the token is not visible. See
`Container.tryGet(String)` .

###### Signature

```apex
public override Object tryGet(String token);
```

###### Parameters

| Name  | Type   | Description               |
| ----- | ------ | ------------------------- |
| token | String | provider token to resolve |

###### Return Type

**Object**

cached instance bound to token, or null when token is not visible

---

##### `tryResolve(token, args)`

Optional fresh resolution within this scope, or null when the token is not visible. See
`Container.tryResolve(String, Object)` .

###### Signature

```apex
public override Object tryResolve(String token, Object args);
```

###### Parameters

| Name  | Type   | Description                                       |
| ----- | ------ | ------------------------------------------------- |
| token | String | provider token to resolve                         |
| args  | Object | runtime arguments for a factory provider, or null |

###### Return Type

**Object**

resolved instance bound to token, or null when token is not visible

---

##### `clearCache()`

Clears this scope's `SCOPED` instances and child owner scopes, resetting the unit of
work.

###### Signature

```apex
public void clearCache();
```

###### Return Type

**void**

###### Throws

InvalidContextException: when the handle belongs to a cleared lifecycle generation

### ModuleImport Class

Marker that records an intent to import a module into another module's graph. Created by
`Di.import()` / `Module.import()` and `importMetadataModule()` . Inert until its owning module
is registered; `.immediately()` requests eager registration.

**See** Di.Module

#### Methods

##### `immediately()`

Marks this import for eager registration when its owning module is registered, instead of
lazy resolution on first use. A no-op on a standalone marker.

###### Signature

```apex
public ModuleImport immediately();
```

###### Return Type

**ModuleImport**

this marker for fluent chaining

---

##### `resolve()`

Resolves and returns the imported module, registering it in the bound context if needed.

###### Signature

```apex
public Module resolve();
```

###### Return Type

**Module**

the imported module

---

##### `getToken()`

Returns the imported module's token.

###### Signature

```apex
public String getToken();
```

###### Return Type

**String**

module token

---

##### `equals(obj)`

Compares imports by token and metadata-import flag.

###### Signature

```apex
public Boolean equals(Object obj);
```

###### Parameters

| Name | Type   | Description       |
| ---- | ------ | ----------------- |
| obj  | Object | object to compare |

###### Return Type

**Boolean**

true when obj is an equivalent import

---

##### `hashCode()`

Returns a hash code consistent with `equals()` .

###### Signature

```apex
public Integer hashCode();
```

###### Return Type

**Integer**

hash code for this import

### DiException Class

Base class for all framework exceptions. Catch it to handle any Apex DI error.

### InvalidModuleException Class

Thrown when a module token, instance, or registration is invalid, missing, or conflicting.

### UnknownModuleException Class

Thrown when a module token does not resolve to a registered or instantiable module.

### UnknownProviderException Class

Thrown when no visible provider matches a requested token.

### UnknownExportException Class

Thrown when a module exports or re-exports a token it does not provide.

### InvalidProviderException Class

Thrown when a provider is misconfigured or misused, including ambiguous bindings and runtime
arguments passed to a non-factory provider.

### InvalidClassException Class

Thrown when a class or factory cannot be instantiated or is not the expected type.

### InvalidScopeException Class

Thrown on scope violations, such as a null scope, getting a prototype, or resolving a scoped
provider at the module root.

### InvalidContextException Class

Thrown when a handle from a cleared or superseded lifecycle generation is used.

### CircularDependencyException Class

Thrown when an unresolvable circular dependency is detected during resolution or compilation.

## Enums

### Scope Enum

Provider lifetime. Controls how long a resolved instance is reused.

#### Values

| Value     | Description                                                               |
| --------- | ------------------------------------------------------------------------- |
| SINGLETON | One instance per owning module runtime, shared for the whole transaction. |
| PROTOTYPE | A new instance on every call.                                             |
| SCOPED    | One instance per active scope and provider owner.                         |

### ResolutionStatus Enum

Outcome of binding discovery reported by `Container.explain()` .

#### Values

| Value     | Description                                                             |
| --------- | ----------------------------------------------------------------------- |
| RESOLVED  | The token resolves to exactly one visible provider.                     |
| NOT_FOUND | No visible provider declares the token.                                 |
| AMBIGUOUS | Two or more imported providers from different owners declare the token. |

### ResolutionSource Enum

Where a resolved binding becomes visible to the requesting module, reported by `explain()` .

#### Values

| Value           | Description                                          |
| --------------- | ---------------------------------------------------- |
| LOCAL           | Declared in the requesting module's own providers.   |
| IMPORTED        | Exported by an imported or re-exported module.       |
| IMPLICIT_GLOBAL | Provided by a global module as an implicit fallback. |
| NONE            | No binding was found.                                |

### ProviderKind Enum

Discriminator for the five built-in provider strategies, reported by `describe()` .

#### Values

| Value             | Description                                    |
| ----------------- | ---------------------------------------------- |
| CLASS_PROVIDER    | Binds a token to a class constructor ( ).      |
| VALUE_PROVIDER    | Binds a token to a literal value ( ).          |
| FACTORY_PROVIDER  | Binds a token to a output ( ).                 |
| EXISTING_PROVIDER | Aliases a token to another provider token ( ). |
| METADATA_PROVIDER | Resolves provider configuration from ( ).      |

### ProviderConfigurationStatus Enum

Configuration health of a provider, reported by `describe()` for metadata-backed providers.

#### Values

| Value             | Description                                     |
| ----------------- | ----------------------------------------------- |
| VALID             | Provider configuration is present and usable.   |
| MISSING_METADATA  | A referenced record does not exist.             |
| INACTIVE_METADATA | The referenced record is inactive.              |
| INVALID_METADATA  | The referenced record is present but malformed. |

## Interfaces

### MetadataSource Interface

Supplies normalized module and provider definitions to an `ApplicationContext` . Implement it
to feed definitions from somewhere other than Custom Metadata, such as a test fake. The
default `CustomMetadataSource` is the only adapter that reads `DI_Module__mdt` and
`DI_Provider__mdt` .

**See** Di.CustomMetadataSource

#### Methods

##### `getModules()`

Returns metadata module definitions keyed by DeveloperName alias.

###### Signature

```apex
public Map<String,MetadataModuleDefinition> getModules();
```

###### Return Type

**Map<String,MetadataModuleDefinition>**

module definitions by DeveloperName

---

##### `getProviders()`

Returns metadata provider definitions keyed by DeveloperName.

###### Signature

```apex
public Map<String,ProviderDefinition> getProviders();
```

###### Return Type

**Map<String,ProviderDefinition>**

provider definitions by DeveloperName

### Factory Interface

Creates instances for a `useFactory` provider. Implement it to encapsulate construction that
needs other providers, runtime arguments, or conditional logic.

#### Example

public class HttpClientFactory implements Di.Factory {
public Object newInstance(Di.Container container, Object args) {
return new HttpClient((String) container.get('API_URL'));
}
}

#### Methods

##### `newInstance(ref, args)`

Builds the instance for the bound token.

###### Signature

```apex
public Object newInstance(Container ref, Object args);
```

###### Parameters

| Name | Type      | Description                                                  |
| ---- | --------- | ------------------------------------------------------------ |
| ref  | Container | container to resolve collaborating providers from            |
| args | Object    | runtime arguments passed to `resolve(token, args)` , or null |

###### Return Type

**Object**

constructed instance

### Injectable Interface

Receives dependencies after construction. Automatic autowiring calls `inject()` after a class
provider is built, and `Container.inject()` wires externally created objects. Enables
two-phase construction for circular references between singleton class providers.

#### Methods

##### `inject(container)`

Resolves and assigns dependencies. Called once, immediately after instantiation.

###### Signature

```apex
public void inject(Container container);
```

###### Parameters

| Name      | Type      | Description                            |
| --------- | --------- | -------------------------------------- |
| container | Container | container to resolve dependencies from |

###### Return Type

**void**
