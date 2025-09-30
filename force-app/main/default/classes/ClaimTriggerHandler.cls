/**
 * Handler for Claim__c trigger
 */
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
        ClaimService.validateClaimAmounts(newClaims);
        ClaimService.assignApprovalLevel(newClaims);
    }
    
    protected override void beforeUpdate() {
        ClaimService.validateClaimAmounts(newClaims);
        ClaimService.validateStatusTransitions(newClaims, oldClaimMap);
    }
    
    protected override void afterUpdate() {
        // Collect approved claims
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