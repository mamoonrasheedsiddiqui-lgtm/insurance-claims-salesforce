/**
 * Centralized error logging service
 * All errors should be logged through this service
 */
public class ErrorLogService {
    
    public enum Severity {
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }
    
    /**
     * Log an error with full context
     */
    public static void logError(
        Exception e, 
        Id recordId, 
        String methodContext
    ) {
        logError(e, recordId, methodContext, Severity.MEDIUM);
    }
    
    /**
     * Log an error with severity level
     */
    public static void logError(
        Exception e, 
        Id recordId, 
        String methodContext,
        Severity severity
    ) {
        try {
            // Parse method context
            List<String> contextParts = methodContext.split('\\.');
            String className = contextParts.size() > 0 ? contextParts[0] : 'Unknown';
            String methodName = contextParts.size() > 1 ? contextParts[1] : 'Unknown';
            
            // For demo purposes, use System.debug
            // In production, insert into ErrorLog__c custom object
            System.debug(LoggingLevel.ERROR, 
                '=== ERROR LOG ===' +
                '\nClass: ' + className +
                '\nMethod: ' + methodName +
                '\nSeverity: ' + severity.name() +
                '\nRecord ID: ' + recordId +
                '\nError Message: ' + e.getMessage() +
                '\nStack Trace: ' + e.getStackTraceString() +
                '\n================='
            );
            
            // In production, uncomment this:
            /*
            ErrorLog__c errorLog = new ErrorLog__c(
                ErrorMessage__c = e.getMessage(),
                StackTrace__c = e.getStackTraceString(),
                ClassName__c = className,
                MethodName__c = methodName,
                RecordId__c = recordId,
                ErrorType__c = determineErrorType(e),
                Severity__c = severity.name(),
                Timestamp__c = System.now(),
                User__c = UserInfo.getUserId()
            );
            Database.insert(errorLog, false);
            */
            
        } catch(Exception loggingException) {
            System.debug(LoggingLevel.ERROR, 
                'Failed to log error: ' + loggingException.getMessage());
        }
    }
    
    /**
     * Bulk log multiple errors
     */
    public static void logErrors(List<ErrorLogEntry> entries) {
        for(ErrorLogEntry entry : entries) {
            logError(entry.exceptions, entry.recordId, entry.methodContext, entry.severity);
        }
    }
    
    /**
     * Determine error type from exception
     */
    private static String determineErrorType(Exception e) {
        if(e instanceof ClaimValidationException) {
            return 'Validation';
        } else if(e instanceof IntegrationException || 
                  e instanceof PaymentGatewayException) {
            return 'Integration';
        } else if(e instanceof DmlException) {
            return 'Database';
        } else if(e instanceof ClaimProcessingException) {
            return 'Business Logic';
        }
        return 'Unknown';
    }
    
    /**
     * Wrapper class for bulk error logging
     */
    public class ErrorLogEntry {
        public Exception exceptions;
        public Id recordId;
        public String methodContext;
        public Severity severity;
        
        public ErrorLogEntry(
            Exception ex, 
            Id recId, 
            String context, 
            Severity sev
        ) {
            this.exceptions = ex;
            this.recordId = recId;
            this.methodContext = context;
            this.severity = sev;
        }
    }
}