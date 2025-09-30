/**
 * Test class for ClaimService
 */
@isTest
private class ClaimServiceTest {
    
    @isTest
    static void testAssignApprovalLevel_SmallClaim_AutoApproved() {
        // Setup
        Claim__c claim = TestDataFactory.createClaim(3000, 'New');
        List<Claim__c> claims = new List<Claim__c>{ claim };
        
        // Test
        Test.startTest();
        ClaimService.assignApprovalLevel(claims);
        Test.stopTest();
        
        // Verify
        System.assertEquals('Auto Approved', claim.ApprovalLevel__c);
        System.assertEquals('Approved', claim.Status__c);
    }
    
    @isTest
    static void testAssignApprovalLevel_MediumClaim_ManagerApproval() {
        // Setup
        Claim__c claim = TestDataFactory.createClaim(10000, 'New');
        List<Claim__c> claims = new List<Claim__c>{ claim };
        
        // Test
        Test.startTest();
        ClaimService.assignApprovalLevel(claims);
        Test.stopTest();
        
        // Verify
        System.assertEquals('Manager', claim.ApprovalLevel__c);
        System.assertEquals('Under Review', claim.Status__c);
    }
    
    @isTest
    static void testAssignApprovalLevel_LargeClaim_SeniorManagerApproval() {
        // Setup
        Claim__c claim = TestDataFactory.createClaim(30000, 'New');
        List<Claim__c> claims = new List<Claim__c>{ claim };
        
        // Test
        Test.startTest();
        ClaimService.assignApprovalLevel(claims);
        Test.stopTest();
        
        // Verify
        System.assertEquals('Senior Manager', claim.ApprovalLevel__c);
        System.assertEquals('Under Review', claim.Status__c);
    }
    
    @isTest
    static void testValidateClaimAmounts_NegativeAmount_AddError() {
        // Setup
        Claim__c claim = TestDataFactory.createClaim(-100, 'New');
        List<Claim__c> claims = new List<Claim__c>{ claim };
        
        // Test
        Test.startTest();
        ClaimService.validateClaimAmounts(claims);
        Test.stopTest();
        
        // Verify - claim should have error
        System.assert(claim.hasErrors());
    }
    
    @isTest
    static void testAssignApprovalLevel_Bulk200Claims_Success() {
        // Setup
        List<Claim__c> claims = TestDataFactory.createBulkClaims(200, 10000, 'New');
        
        // Test
        Test.startTest();
        ClaimService.assignApprovalLevel(claims);
        Test.stopTest();
        
        // Verify
        System.assertEquals(200, claims.size());
        for(Claim__c claim : claims) {
            System.assertEquals('Manager', claim.ApprovalLevel__c);
        }
    }
}