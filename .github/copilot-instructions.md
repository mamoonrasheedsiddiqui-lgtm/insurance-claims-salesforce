# GitHub Copilot Instructions for Insurance Claims Management System

## Overview
This file provides explicit instructions to GitHub Copilot for generating code that follows our Salesforce development standards, business rules, and architectural patterns.

---

## Core Principles

When generating any code for this project:

1. **Always follow the patterns** defined in `/docs/` folder
2. **Respect business rules** from `/docs/business-rules.md`
3. **Use error handling patterns** from `/docs/error-handling.md`
4. **Follow integration patterns** from `/docs/integration-patterns.md`
5. **Adhere to best practices** from `/docs/best-practices.md`
6. **Follow testing standards** from `/docs/testing-standards.md`

---

## Business Rules (MANDATORY)

### Claim Approval Thresholds

**ALWAYS apply these thresholds when generating approval logic:**

```apex
// Auto-approval: Claims under $5,000
if(claim.ClaimAmount__c < 5000) {
    claim.ApprovalLevel__c = 'Auto Approved';
    claim.Status__c = 'Approved';
}

// Manager approval: Claims $5,000 - $24,999.99
else if(claim.ClaimAmount__c >= 5000 && claim.ClaimAmount__c < 25000) {
    claim.ApprovalLevel__c = 'Manager';
    claim.Status__c = 'Under Review';
}

// Senior Manager approval: Claims $25,000+
else {
    claim.ApprovalLevel__c = 'Senior Manager';
    claim.Status__c = 'Under Review';
}
```

### Claim Amount Validation

**ALWAYS validate claim amount equals sum of line items:**

```apex
Decimal totalLineItems = 0;
for(ClaimLineItem__c item : claim.ClaimLineItems__r) {
    totalLineItems += item.ItemAmount__c;
}

if(claim.ClaimAmount__c != totalLineItems) {
    throw new ClaimValidationException(
        'Claim amount ($' + claim.ClaimAmount__c + 
        ') must equal sum of line items ($' + totalLineItems + ')'
    );
}
```

### Status Transition Rules

**ALWAYS enforce these status transitions:**

- ✅ New → Under Review (automatic on submission)
- ✅ Under Review → Approved (by authorized approver)
- ✅ Under Review → Rejected (by authorized approver)
- ✅ Approved → Paid (after payment processing)
- ❌ Paid → Any other status (NEVER allowed)
- ❌ Any status → New (NEVER allowed)

---

## Naming Conventions (MANDATORY)

### Classes

**ALWAYS use these patterns:**

| Type | Pattern | Example |
|------|---------|---------|
| Controller | `[Object]Controller` | `ClaimController` |
| Service | `[Object]Service` | `ClaimService`, `PaymentGatewayService` |
| Handler | `[Object]TriggerHandler` | `ClaimTriggerHandler` |
| Utility | `[Purpose]Utility` | `ValidationUtility` |
| Exception | `[Purpose]Exception` | `ClaimValidationException` |
| Test | `[ClassName]Test` | `ClaimServiceTest` |

### Methods

**ALWAYS use verb + noun pattern:**

```apex
// ✅ CORRECT
public static void validateClaimAmount(Claim__c claim)
public static Decimal calculateTotalClaim(List<ClaimLineItem__c> items)
public static void processClaimApproval(Id claimId)

// ❌ INCORRECT
public static void validate(Claim__c c)
public static Decimal calc(List<ClaimLineItem__c> items)
public static void process(Id id)
```

---

## Error Handling Pattern (MANDATORY)

### Standard Error Handling

**ALWAYS use this pattern in service classes:**

```apex
public static void yourMethodName(Id recordId) {
    Savepoint sp = Database.setSavepoint();
    
    try {
        // Input validation
        if(recordId == null) {
            throw new ClaimValidationException('Record ID cannot be null');
        }
        
        // Business logic here
        
    } catch(ClaimValidationException e) {
        Database.rollback(sp);
        ErrorLogService.logError(
            e,
            recordId,
            'ClassName.methodName',
            ErrorLogService.Severity.HIGH
        );
        throw e;
        
    } catch(Exception e) {
        Database.rollback(sp);
        ErrorLogService.logError(
            e,
            recordId,
            'ClassName.methodName',
            ErrorLogService.Severity.CRITICAL
        );
        throw new ClaimProcessingException(
            'Unexpected error: ' + e.getMessage(),
            e
        );
    }
}
```

### Custom Exceptions

**ALWAYS use these custom exception types:**

- `ClaimValidationException` - Business rule violations
- `ClaimProcessingException` - Processing failures
- `PaymentGatewayException` - Payment integration failures
- `FraudDetectionException` - Fraud detection failures
- `IntegrationException` - General integration failures
- `NotificationException` - Notification failures
- `DataAccessException` - Data access issues

### Error Logging

**ALWAYS log errors using ErrorLogService:**

```apex
ErrorLogService.logError(
    exception,
    recordId,
    'ClassName.methodName',
    ErrorLogService.Severity.HIGH
);
```

**NEVER use System.debug for error logging in production code**

---

## Trigger Pattern (MANDATORY)

### One Trigger Per Object

**ALWAYS create triggers using this pattern:**

```apex
// ClaimTrigger.trigger
trigger ClaimTrigger on Claim__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new ClaimTriggerHandler().run();
}
```

### Trigger Handler

**ALWAYS extend TriggerHandler base class:**

```apex
public with sharing class ClaimTriggerHandler extends TriggerHandler {
    
    private List<Claim__c> newClaims;
    private List<Claim__c> oldClaims;
    private Map<Id, Claim__c> newClaimMap;
    private Map<Id, Claim__c> oldClaimMap;
    
    public ClaimTriggerHandler() {
        super();
        this.newClaims = (List<Claim__c>) Trigger.new;
        this.oldClaims = (List<Claim__c>) Trigger.old;
        this.newClaimMap = (Map<Id, Claim__c>) Trigger.newMap;
        this.oldClaimMap = (Map<Id, Claim__c>) Trigger.oldMap;
    }
    
    protected override void beforeInsert() {
        // Call service methods, never put logic directly here
        ClaimService.validateClaimAmounts(newClaims);
        ClaimService.assignApprovalLevel(newClaims);
    }
    
    protected override void afterUpdate() {
        // Collect records that need processing
        List<Claim__c> approvedClaims = new List<Claim__c>();
        for(Claim__c claim : newClaims) {
            Claim__c oldClaim = oldClaimMap.get(claim.Id);
            if(claim.Status__c == 'Approved' && oldClaim.Status__c != 'Approved') {
                approvedClaims.add(claim);
            }
        }
        
        if(!approvedClaims.isEmpty()) {
            ClaimService.processApprovedClaims(approvedClaims);
        }
    }
}
```

---

## Integration Pattern (MANDATORY)

### HTTP Callout Structure

**ALWAYS use this pattern for HTTP callouts:**

```apex
public static ResponseType methodName(Claim__c claim) {
    // Validate input
    if(claim == null || claim.Id == null) {
        throw new IntegrationException('Invalid input');
    }
    
    // Build request
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:NamedCredential/api/endpoint');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setTimeout(30000); // Always set 30 second timeout
    
    // Build payload
    Map<String, Object> payload = new Map<String, Object>{
        'claimId' => claim.Id,
        'amount' => claim.ClaimAmount__c
    };
    req.setBody(JSON.serialize(payload));
    
    // Execute with retry
    Http http = new Http();
    HttpResponse res = http.send(req);
    
    // Log integration
    IntegrationLogService.logCallout(
        req,
        res,
        claim.Id,
        'Integration Name',
        1,
        0
    );
    
    // Handle response
    if(res.getStatusCode() == 200) {
        return (ResponseType)JSON.deserialize(res.getBody(), ResponseType.class);
    } else {
        throw new IntegrationException(
            'Integration failed: ' + res.getStatusCode() + ' - ' + res.getBody()
        );
    }
}
```

### Named Credentials

**ALWAYS use Named Credentials - never hardcode endpoints:**

```apex
// ✅ CORRECT
req.setEndpoint('callout:PaymentGateway/api/v2/payments');

// ❌ WRONG
req.setEndpoint('https://api.payment.com/v2/payments');
```

### Timeout

**ALWAYS set 30-second timeout:**

```apex
req.setTimeout(30000);
```

---

## Testing Standards (MANDATORY)

### Test Class Structure

**ALWAYS structure test classes like this:**

```apex
@isTest
private class ClaimServiceTest {
    
    @TestSetup
    static void setup() {
        // Create common test data using TestDataFactory
        List<Claim__c> claims = TestDataFactory.createBulkClaims(5, 10000, 'New');
        insert claims;
    }
    
    @isTest
    static void testMethodName_Scenario_ExpectedResult() {
        // Setup: Get test data
        Claim__c claim = [SELECT Id FROM Claim__c LIMIT 1];
        
        // Test: Execute within Test boundaries
        Test.startTest();
        ClaimService.methodName(claim.Id);
        Test.stopTest();
        
        // Verify: Assert expected results
        claim = [SELECT Status__c FROM Claim__c WHERE Id = :claim.Id];
        System.assertEquals('Expected', claim.Status__c);
    }
}
```

### Always Test

- ✅ Positive scenarios (happy path)
- ✅ Negative scenarios (error handling)
- ✅ Boundary conditions (thresholds)
- ✅ Bulk operations (200 records)
- ✅ Null handling
- ✅ Security (different user roles)

### Use TestDataFactory

**ALWAYS use TestDataFactory for test data:**

```apex
// ✅ CORRECT
Claim__c claim = TestDataFactory.createClaim(10000, 'New');
List<Claim__c> claims = TestDataFactory.createBulkClaims(200, 10000, 'Approved');

// ❌ WRONG
Claim__c claim = new Claim__c(ClaimAmount__c = 10000, ...);
```

### Mock HTTP Callouts

**ALWAYS mock callouts in tests:**

```apex
Test.setMock(HttpCalloutMock.class, PaymentGatewayMock.success());
```

---

## Bulkification (MANDATORY)

### Always Write Bulk-Safe Code

**NEVER put SOQL or DML in loops:**

```apex
// ✅ CORRECT - Bulk pattern
public static void updateClaims(List<Claim__c> claims) {
    Set<Id> claimIds = new Set<Id>();
    for(Claim__c claim : claims) {
        claimIds.add(claim.Id);
    }
    
    // Single SOQL query
    Map<Id, List<ClaimLineItem__c>> itemsByClaim = new Map<Id, List<ClaimLineItem__c>>();
    for(ClaimLineItem__c item : [
        SELECT Claim__c, ItemAmount__c
        FROM ClaimLineItem__c
        WHERE Claim__c IN :claimIds
    ]) {
        if(!itemsByClaim.containsKey(item.Claim__c)) {
            itemsByClaim.put(item.Claim__c, new List<ClaimLineItem__c>());
        }
        itemsByClaim.get(item.Claim__c).add(item);
    }
    
    // Process in memory
    List<Claim__c> toUpdate = new List<Claim__c>();
    for(Claim__c claim : claims) {
        // Business logic
        toUpdate.add(claim);
    }
    
    // Single DML operation
    if(!toUpdate.isEmpty()) {
        update toUpdate;
    }
}

// ❌ WRONG - Not bulk-safe
public static void updateClaims(List<Claim__c> claims) {
    for(Claim__c claim : claims) {
        List<ClaimLineItem__c> items = [
            SELECT ItemAmount__c 
            FROM ClaimLineItem__c 
            WHERE Claim__c = :claim.Id
        ]; // SOQL in loop!
        
        // Process
        update claim; // DML in loop!
    }
}
```

---

## Security (MANDATORY)

### Sharing Keywords

**ALWAYS explicitly declare sharing:**

```apex
// ✅ CORRECT - Default for most classes
public with sharing class ClaimService {
    // Respects sharing rules
}

// ⚠️ USE CAREFULLY - Only when needed
public without sharing class ClaimBatchProcessor {
    // System context - document why needed
}
```

### Field-Level Security

**ALWAYS check FLS before DML:**

```apex
if(!Schema.sObjectType.Claim__c.isCreateable()) {
    throw new ClaimValidationException('Insufficient permissions');
}
```

### SOQL Injection Prevention

**ALWAYS use bind variables:**

```apex
// ✅ CORRECT
List<Claim__c> claims = [
    SELECT Id FROM Claim__c WHERE Status__c = :status
];

// ❌ WRONG
String query = 'SELECT Id FROM Claim__c WHERE Status__c = \'' + status + '\'';
```

---

## Documentation Standards (MANDATORY)

### Class Headers

**ALWAYS include class-level documentation:**

```apex
/**
 * Service class for claim processing business logic
 * 
 * @description Handles validation, approval, and payment processing for claims
 * @author Development Team
 * @date 2024-01-15
 */
public with sharing class ClaimService {
    // Implementation
}
```

### Method Documentation

**ALWAYS document public methods:**

```apex
/**
 * Process claim approval and trigger payment
 * 
 * @param claimId The ID of the claim to approve
 * @throws ClaimValidationException if claim is not in valid state
 * @throws ClaimProcessingException if approval process fails
 */
public static void processClaimApproval(Id claimId) {
    // Implementation
}
```

---

## Lightning Web Components (MANDATORY)

### Component Structure

**ALWAYS structure LWC files like this:**

```javascript
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import apexMethod from '@salesforce/apex/ControllerName.methodName';

// Define fields
const FIELDS = [
    'Claim__c.ClaimNumber__c',
    'Claim__c.ClaimAmount__c',
    'Claim__c.Status__c'
];

export default class ComponentName extends LightningElement {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record;
    
    // Getters for template
    get fieldValue() {
        return this.record.data?.fields.FieldName__c.value;
    }
    
    // Event handlers
    handleAction() {
        apexMethod({ param: this.recordId })
            .then(result => {
                this.showToast('Success', 'Action completed', 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
```

---

## Code Generation Guidelines

### When Generating Apex Classes

1. **Start with class declaration:**
   - Include appropriate sharing keyword
   - Add class-level documentation

2. **Add constants at top:**
   - Use UPPER_SNAKE_CASE
   - Group related constants

3. **Organize methods logically:**
   - Public methods first
   - Private methods last
   - Group related methods together

4. **Include error handling:**
   - Use try-catch blocks
   - Log errors with ErrorLogService
   - Use appropriate custom exceptions

5. **Write bulk-safe code:**
   - Support 200 records minimum
   - No SOQL/DML in loops
   - Use collections efficiently

### When Generating Test Classes

1. **Use @TestSetup** for common data
2. **Use TestDataFactory** for all test data
3. **Include Test.startTest() and Test.stopTest()**
4. **Mock all HTTP callouts**
5. **Test bulk operations (200 records)**
6. **Assert expected results explicitly**

### When Generating Triggers

1. **Create one trigger per object**
2. **Call handler class immediately**
3. **Never put business logic in trigger**
4. **Include all trigger contexts**

### When Generating Integration Code

1. **Use Named Credentials**
2. **Set 30-second timeout**
3. **Log all callouts with IntegrationLogService**
4. **Implement retry logic for failures**
5. **Handle all response codes**

---

## Anti-Patterns to AVOID

### ❌ NEVER DO THESE

```apex
// ❌ SOQL in loops
for(Claim__c claim : claims) {
    List<ClaimLineItem__c> items = [SELECT Id FROM ClaimLineItem__c WHERE Claim__c = :claim.Id];
}

// ❌ DML in loops
for(Claim__c claim : claims) {
    update claim;
}

// ❌ Hardcoded IDs
Claim__c claim = [SELECT Id FROM Claim__c WHERE Id = '001XXXXXXXXXXXXXXX'];

// ❌ Hardcoded endpoints
req.setEndpoint('https://api.example.com/endpoint');

// ❌ No error handling
public static void method() {
    // No try-catch!
    update claims;
}

// ❌ Generic exceptions
throw new Exception('Error');

// ❌ System.debug for errors
catch(Exception e) {
    System.debug(e); // Use ErrorLogService instead!
}

// ❌ No sharing keyword
public class MyClass { } // Always specify sharing!

// ❌ String concatenation in SOQL
String query = 'SELECT Id FROM Claim__c WHERE Status__c = \'' + status + '\'';
```

---

## Summary: Generate Code That...

✅ Follows the trigger handler pattern
✅ Uses custom exceptions from our exception hierarchy
✅ Logs errors with ErrorLogService
✅ Applies business rules from docs/business-rules.md
✅ Follows naming conventions
✅ Is bulk-safe (supports 200+ records)
✅ Uses Named Credentials for integrations
✅ Includes proper error handling with savepoints
✅ Has complete test coverage with TestDataFactory
✅ Uses `with sharing` by default
✅ Includes method documentation
✅ Validates inputs before processing
✅ Uses bind variables in SOQL
✅ Sets appropriate timeouts for callouts

---

## Reference Files

For detailed information, always refer to:

- `/docs/architecture.md` - System architecture and design patterns
- `/docs/business-rules.md` - Business rules and validation logic
- `/docs/data-model.md` - Object structure and relationships
- `/docs/error-handling.md` - Error handling patterns
- `/docs/integration-patterns.md` - External system integration patterns
- `/docs/best-practices.md` - Coding standards and best practices
- `/docs/testing-standards.md` - Testing patterns and requirements

---

## When in Doubt

1. **Check the docs folder first** for existing patterns
2. **Look at similar classes** in the codebase for reference
3. **Follow the principle of least surprise** - code should be predictable
4. **Prioritize code readability** over cleverness
5. **Default to explicit rather than implicit**

**Remember: Consistency is more important than perfection. Follow the established patterns even if you could write it differently.**