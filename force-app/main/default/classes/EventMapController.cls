public with sharing class EventMapController {
    @AuraEnabled(cacheable=true)
    public static List<Event__c> getOngoingEvents() {
        Date today = Date.today();
        return [
            SELECT Id, Name, Start_Date__c, End_Date__c,
                   Location__Latitude__s, Location__Longitude__s
            FROM Event__c
            WHERE Start_Date__c <= :today AND End_Date__c >= :today
            AND Location__Latitude__s != NULL AND Location__Longitude__s != NULL
        ];
    }
}
