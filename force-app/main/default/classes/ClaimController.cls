/**
 * Controller for Claim Lightning Web Components
 */
public with sharing class ClaimController {
    
    @AuraEnabled
    public static void approveClaim(Id claimId) {
        try {
            ClaimService.processClaimApproval(claimId);
        } catch(ClaimValidationException e) {
            throw new AuraHandledException(e.getMessage());
        } catch(ClaimProcessingException e) {
            throw new AuraHandledException('Unable to approve claim: ' + e.getMessage());
        } catch(Exception e) {
            ErrorLogService.logError(
                e, 
                claimId, 
                'ClaimController.approveClaim',
                ErrorLogService.Severity.HIGH
            );
            throw new AuraHandledException('An unexpected error occurred');
        }
    }
}