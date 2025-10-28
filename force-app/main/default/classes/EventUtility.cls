public with sharing class EventUtility {
    @AuraEnabled(cacheable=true)
    public static List<Event__c> getUpcomingEvents() {
        return [SELECT Id, Name, Start_Date__c, End_Date__c, Address__c FROM Event__c WHERE Start_Date__c >= :Date.today()];
    }
} 
