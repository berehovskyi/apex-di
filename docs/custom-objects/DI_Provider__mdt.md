# DI Provider

Defines a dependency injection provider binding. Records of this type allow for configuring service implementations, values, or factories without changing Apex code.

## API Name

`DI_Provider__mdt`

## Fields

### Args

A string of arguments to be passed to the newInstance method of a Factory provider. This allows for dynamic, metadata-driven configuration of factories.

**API Name**

`Args__c`

**Type**

_LongTextArea_

---

### Description

Optional documentation describing the purpose of this metadata-backed provider configuration.

**API Name**

`Description__c`

**Type**

_LongTextArea_

---

### Is Active

If checked, this provider definition will be used by the DI framework.

**API Name**

`IsActive__c`

**Type**

_Checkbox_

---

### Scope

(Optional) The lifetime of the provider.

**API Name**

`Scope__c`

**Type**

_Picklist_

#### Possible values are

- SINGLETON
- PROTOTYPE
- SCOPED

---

### Type

**Required**

Defines the kind of provider

**API Name**

`Type__c`

**Type**

_Picklist_

#### Possible values are

- Class
- Existing
- Factory
- Value

---

### Value

The value for the provider. Its meaning depends on the Type\_\_c:

- Class: The full Apex class name of the implementation (e.g., LiveEmailService).
- Value: The literal string value.
- Factory: The full Apex class name of the factory.
- Existing: The token of another provider to alias.

**API Name**

`Value__c`

**Type**

_LongTextArea_
