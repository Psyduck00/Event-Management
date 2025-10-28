public with sharing class EventSummaryController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getMonthlyCounts() {
        Date firstDay = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        Date lastDay = firstDay.addMonths(1).addDays(-1);

        Map<String, Integer> summary = new Map<String, Integer>();

        // Count events this month
        Integer totalEvents = [
            SELECT COUNT()
            FROM Event__c
            WHERE Start_Date__c >= :firstDay AND Start_Date__c <= :lastDay
        ];
        summary.put('events', totalEvents);

        // Count attendees registered this month
        Integer totalAttendees = [
            SELECT COUNT()
            FROM Attendee__c
            WHERE CreatedDate >= :firstDay AND CreatedDate <= :lastDay
        ];
        summary.put('attendees', totalAttendees);

        // Count sessions conducted this month
        Integer totalSessions = [
            SELECT COUNT()
            FROM Session__c
            WHERE CreatedDate >= :firstDay AND CreatedDate <= :lastDay
        ];
        summary.put('sessions', totalSessions);

        return summary;
    }
}
