import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const FIELDS = [
    'Claim__c.ClaimNumber__c',
    'Claim__c.ClaimAmount__c',
    'Claim__c.Status__c',
    'Claim__c.ApprovalLevel__c'
];

export default class ClaimSummary extends LightningElement {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    claim;
    
    get claimNumber() {
        return getFieldValue(this.claim.data, 'Claim__c.ClaimNumber__c');
    }
    
    get claimAmount() {
        return getFieldValue(this.claim.data, 'Claim__c.ClaimAmount__c');
    }
    
    get status() {
        return getFieldValue(this.claim.data, 'Claim__c.Status__c');
    }
    
    get approvalLevel() {
        return getFieldValue(this.claim.data, 'Claim__c.ApprovalLevel__c');
    }
    
    get isUnderReview() {
        return this.status === 'Under Review';
    }
    
    get isApproved() {
        return this.status === 'Approved';
    }
}