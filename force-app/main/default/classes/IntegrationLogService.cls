/**
 * Service for logging integration attempts
 */
public class IntegrationLogService {
    
    /**
     * Log successful HTTP callout
     */
    public static void logCallout(
        HttpRequest req,
        HttpResponse res,
        Id recordId,
        String integrationName,
        Integer attemptNumber,
        Long durationMs
    ) {
        System.debug(LoggingLevel.INFO,
            '=== INTEGRATION LOG ===' +
            '\nIntegration: ' + integrationName +
            '\nEndpoint: ' + req.getEndpoint() +
            '\nMethod: ' + req.getMethod() +
            '\nStatus Code: ' + res.getStatusCode() +
            '\nAttempt: ' + attemptNumber +
            '\nDuration: ' + durationMs + 'ms' +
            '\nRecord ID: ' + recordId +
            '\n====================='
        );
    }
    
    /**
     * Log failed callout
     */
    public static void logFailedCallout(
        HttpRequest req,
        Id recordId,
        String integrationName,
        Integer attemptNumber,
        String errorMessage
    ) {
        System.debug(LoggingLevel.ERROR,
            '=== FAILED INTEGRATION ===' +
            '\nIntegration: ' + integrationName +
            '\nEndpoint: ' + req.getEndpoint() +
            '\nAttempt: ' + attemptNumber +
            '\nError: ' + errorMessage +
            '\nRecord ID: ' + recordId +
            '\n========================'
        );
    }
}