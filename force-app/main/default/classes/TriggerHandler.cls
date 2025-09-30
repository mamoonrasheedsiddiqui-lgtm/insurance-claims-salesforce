/**
 * Base trigger handler class
 * All trigger handlers should extend this class
 */
public virtual class TriggerHandler {
    
    protected Boolean isBefore;
    protected Boolean isAfter;
    protected Boolean isInsert;
    protected Boolean isUpdate;
    protected Boolean isDelete;
    protected Boolean isUndelete;
    
    public TriggerHandler() {
        this.isBefore = Trigger.isBefore;
        this.isAfter = Trigger.isAfter;
        this.isInsert = Trigger.isInsert;
        this.isUpdate = Trigger.isUpdate;
        this.isDelete = Trigger.isDelete;
        this.isUndelete = Trigger.isUndelete;
    }
    
    public void run() {
        if(this.isBefore) {
            if(this.isInsert) {
                this.beforeInsert();
            } else if(this.isUpdate) {
                this.beforeUpdate();
            } else if(this.isDelete) {
                this.beforeDelete();
            }
        } else if(this.isAfter) {
            if(this.isInsert) {
                this.afterInsert();
            } else if(this.isUpdate) {
                this.afterUpdate();
            } else if(this.isDelete) {
                this.afterDelete();
            } else if(this.isUndelete) {
                this.afterUndelete();
            }
        }
    }
    
    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}
}