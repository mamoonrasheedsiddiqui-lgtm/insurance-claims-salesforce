import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import approveClaim from '@salesforce/apex/ClaimController.approveClaim';

export default class ClaimApproval extends LightningElement {
    @api recordId;
    isLoading = false;
    
    handleApprove() {
        this.isLoading = true;
        
        approveClaim({ claimId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Claim approved successfully', 'success');
                // Refresh the page
                eval("$A.get('e.force:refreshView').fire();");
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    handleReject() {
        // Implementation for rejection
        this.showToast('Info', 'Rejection feature coming soon', 'info');
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}