
/**
 * Test class for ClaimFraudDetectionService
 *
 * @description Covers high-risk claim detection, fraud score rules, external API integration, and error handling
 */
@isTest
private class ClaimFraudDetectionServiceTest {

	@TestSetup
	static void setup() {
		// Create 5 claims with varying amounts and statuses
		List<Claim__c> claims = TestDataFactory.createBulkClaims(5, 10000, 'New');
		insert claims;
	}

	@isTest
	static void testHighRiskClaimDetection_SetsFlag() {
		// Setup: Create a claim with high internal and external scores
		Claim__c claim = TestDataFactory.createClaim(20000, 'New');
		insert claim;

		// Mock external API to return high score
		Test.setMock(HttpCalloutMock.class, new FraudDetectionMock(60));

		List<Claim__c> claims = [SELECT Id, Fraud_Score__c, External_Fraud_Score__c, Is_High_Risk__c FROM Claim__c WHERE Id = :claim.Id];

		Test.startTest();
		ClaimFraudDetectionService.evaluateFraudRisk(claims);
		Test.stopTest();

		claim = [SELECT Fraud_Score__c, External_Fraud_Score__c, Is_High_Risk__c FROM Claim__c WHERE Id = :claim.Id];
		System.assertEquals(true, claim.Is_High_Risk__c, 'High risk flag should be set');
		System.assert(claim.Fraud_Score__c > 0, 'Internal fraud score should be set');
		System.assert(claim.External_Fraud_Score__c == 60, 'External fraud score should match mock');
	}

	@isTest
	static void testFraudScoreRule_HighAmount() {
		Claim__c claim = TestDataFactory.createClaim(15000, 'New');
		insert claim;
		Test.setMock(HttpCalloutMock.class, new FraudDetectionMock(10));
		List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Id = :claim.Id];
		Test.startTest();
		ClaimFraudDetectionService.evaluateFraudRisk(claims);
		Test.stopTest();
		claim = [SELECT Fraud_Score__c FROM Claim__c WHERE Id = :claim.Id];
		System.assert(claim.Fraud_Score__c >= 30, 'High amount rule should add 30 to score');
	}

	@isTest
	static void testFraudScoreRule_MultipleClaims() {
		Claim__c claim = TestDataFactory.createClaim(5000, 'New');
		claim.Number_of_Claims__c = 5;
		update claim;
		Test.setMock(HttpCalloutMock.class, new FraudDetectionMock(10));
		List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Id = :claim.Id];
		Test.startTest();
		ClaimFraudDetectionService.evaluateFraudRisk(claims);
		Test.stopTest();
		claim = [SELECT Fraud_Score__c FROM Claim__c WHERE Id = :claim.Id];
		System.assert(claim.Fraud_Score__c >= 20, 'Multiple claims rule should add 20 to score');
	}

	@isTest
	static void testFraudScoreRule_OldClaim() {
		Claim__c claim = TestDataFactory.createClaim(5000, 'New');
		claim.Claim_Date__c = System.today().addDays(-40);
		update claim;
		Test.setMock(HttpCalloutMock.class, new FraudDetectionMock(10));
		List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Id = :claim.Id];
		Test.startTest();
		ClaimFraudDetectionService.evaluateFraudRisk(claims);
		Test.stopTest();
		claim = [SELECT Fraud_Score__c FROM Claim__c WHERE Id = :claim.Id];
		System.assert(claim.Fraud_Score__c >= 10, 'Old claim rule should add 10 to score');
	}

	@isTest
	static void testExternalApiIntegration_MockScore() {
		Claim__c claim = TestDataFactory.createClaim(8000, 'New');
		insert claim;
		Test.setMock(HttpCalloutMock.class, new FraudDetectionMock(42));
		List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Id = :claim.Id];
		Test.startTest();
		ClaimFraudDetectionService.evaluateFraudRisk(claims);
		Test.stopTest();
		claim = [SELECT External_Fraud_Score__c FROM Claim__c WHERE Id = :claim.Id];
		System.assertEquals(42, claim.External_Fraud_Score__c, 'External fraud score should match mock');
	}

	@isTest
	static void testErrorHandling_InvalidClaim_ThrowsException() {
		Claim__c claim = new Claim__c(); // Missing required fields
		insert claim;
		Test.setMock(HttpCalloutMock.class, new FraudDetectionMock(10));
		List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Id = :claim.Id];
		Boolean thrown = false;
		Test.startTest();
		try {
			ClaimFraudDetectionService.evaluateFraudRisk(claims);
		} catch (Exception e) {
			thrown = true;
		}
		Test.stopTest();
		System.assert(thrown, 'Exception should be thrown for invalid claim');
	}

	@isTest
	static void testBulkHighRiskDetection_200Records() {
		List<Claim__c> claims = TestDataFactory.createBulkClaims(200, 25000, 'New');
		insert claims;
		Test.setMock(HttpCalloutMock.class, new FraudDetectionMock(50));
		List<Claim__c> insertedClaims = [SELECT Id FROM Claim__c WHERE Id IN :claims];
		Test.startTest();
		ClaimFraudDetectionService.evaluateFraudRisk(insertedClaims);
		Test.stopTest();
		List<Claim__c> processedClaims = [SELECT Is_High_Risk__c FROM Claim__c WHERE Id IN :claims];
		for (Claim__c claim : processedClaims) {
			System.assertEquals(true, claim.Is_High_Risk__c, 'All claims should be flagged high risk');
		}
	}

	// Mock for external fraud detection API
	private class FraudDetectionMock implements HttpCalloutMock {
		private Integer fraudScore;
		public FraudDetectionMock(Integer score) {
			this.fraudScore = score;
		}
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"fraudScore":' + fraudScore + '}');
			return res;
		}
	}
}