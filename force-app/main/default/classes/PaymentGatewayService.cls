/**
 * Service for payment gateway integration
 */
public class PaymentGatewayService {
    
    private static final String NAMED_CREDENTIAL = 'callout:PaymentGateway';
    private static final Integer TIMEOUT_MS = 30000;
    private static final Integer MAX_RETRIES = 3;
    
    /**
     * Process payment for claim
     */
    public static PaymentResponse processPayment(Claim__c claim) {
        // Input validation
        if(claim == null || claim.Id == null) {
            throw new PaymentGatewayException('Invalid claim provided');
        }
        
        if(claim.ClaimAmount__c == null || claim.ClaimAmount__c <= 0) {
            throw new PaymentGatewayException('Invalid claim amount');
        }
        
        // Build request
        HttpRequest req = buildPaymentRequest(claim);
        
        // Execute (for demo, just return success)
        PaymentResponse response = new PaymentResponse();
        response.success = true;
        response.transactionId = 'TXN-' + String.valueOf(System.currentTimeMillis());
        response.status = 'completed';
        response.message = 'Payment processed successfully';
        
        System.debug('Payment processed: ' + response.transactionId);
        
        return response;
    }
    
    /**
     * Build HTTP request for payment
     */
    private static HttpRequest buildPaymentRequest(Claim__c claim) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/api/v2/payments');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(TIMEOUT_MS);
        
        Map<String, Object> payload = new Map<String, Object>{
            'claimId' => claim.Id,
            'amount' => claim.ClaimAmount__c,
            'currency' => 'USD'
        };
        req.setBody(JSON.serialize(payload));
        
        return req;
    }
    
    /**
     * Payment response wrapper
     */
    public class PaymentResponse {
        public Boolean success;
        public String transactionId;
        public String status;
        public String message;
        public Decimal amountProcessed;
    }
}