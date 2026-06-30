# DI Module

Defines Apex DI modules selected by metadata. Global modules are loaded automatically; local modules are installed only through an explicit metadata module import or reference.

## API Name

`DI_Module__mdt`

## Fields

### Class

**Required**

Fully qualified class name of the module selected by this metadata alias (for example, 'LoggerModule' or 'OuterClass.ConfigModule').

**API Name**

`Class__c`

**Type**

_Text_

---

### Description

Optional documentation describing why this metadata module alias exists and where it should be used.

**API Name**

`Description__c`

**Type**

_LongTextArea_

---

### Is Active

Controls whether this metadata module can be loaded.

**API Name**

`IsActive__c`

**Type**

_Checkbox_

---

### Is Global

Registers the module globally and makes its exported providers available without explicit imports.

**API Name**

`IsGlobal__c`

**Type**

_Checkbox_
