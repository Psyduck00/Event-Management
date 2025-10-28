trigger AttendeeTrigger on Attendee__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AttendeeTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            AttendeeTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
