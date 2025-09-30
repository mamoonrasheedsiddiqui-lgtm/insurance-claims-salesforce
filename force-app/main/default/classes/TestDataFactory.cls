/**
 * Factory for creating test data
 */
@isTest
public class TestDataFactory {
    
    /**
     * Create a claim with custom values
     */
    public static Claim__c createClaim(Decimal amount, String status) {
        return new Claim__c(
            ClaimAmount__c = amount,
            Status__c = status,
            ClaimDescription__c = 'Test claim description',
            IncidentDate__c = System.today().addDays(-7)
        );
    }
    
    /**
     * Create bulk claims for testing
     */
    public static List<Claim__c> createBulkClaims(
        Integer count, 
        Decimal amount, 
        String status
    ) {
        List<Claim__c> claims = new List<Claim__c>();
        for(Integer i = 0; i < count; i++) {
            claims.add(new Claim__c(
                ClaimAmount__c = amount,
                Status__c = status,
                ClaimDescription__c = 'Bulk test claim ' + i,
                IncidentDate__c = System.today().addDays(-7)
            ));
        }
        return claims;
    }
    
    /**
     * Generate random number for unique identifiers
     */
    public static Integer generateRandomNumber() {
        return Integer.valueOf(Math.random() * 1000000);
    }
}