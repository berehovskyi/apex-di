# Reference Guide

## Core

### [Di](core\Di.md)

`Di` is the single public facade:
it organizes code into modules, binds tokens to providers, and resolves services through
module-aware containers. Static methods delegate to a shared default `ApplicationContext` ;
use `createContext()` to isolate independent graphs in the same transaction.

Designed for Apex's transaction model: module setup runs inside one transaction and provider
instances are cached only within it. Durable configuration lives in `DI_Module__mdt` and
`DI_Provider__mdt` , read only through the default `CustomMetadataSource` .

## Custom Objects

### [DI_Module\_\_mdt](custom-objects\DI_Module__mdt.md)

Defines Apex DI modules selected by metadata. Global modules are loaded automatically; local modules are installed only through an explicit metadata module import or reference.

### [DI_Provider\_\_mdt](custom-objects\DI_Provider__mdt.md)

Defines a dependency injection provider binding. Records of this type allow for configuring service implementations, values, or factories without changing Apex code.
