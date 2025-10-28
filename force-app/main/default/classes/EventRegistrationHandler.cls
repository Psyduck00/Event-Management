public with sharing class EventRegistrationHandler {

    // Existing method for Screen Flows/Invocable Actions
    @InvocableMethod(label='Register Attendee')
    public static void registerAttendees(List<Attendee__c> attendees) {
        // We'll reuse the LWC-callable method for the core logic
        registerAttendeeCore(attendees[0]); 
    }

    // New method callable from LWC
    @AuraEnabled
    public static String registerAttendeeFromLWC(String attendeeName, String attendeeEmail, String sessionId) {
        try {
            Attendee__c newAttendee = new Attendee__c(
                Name = attendeeName,
                Email__c = attendeeEmail,
                Selected_Session__c = sessionId
            );
            
            // Call the core logic
            registerAttendeeCore(newAttendee);

            return 'Registration successful!';

        } catch (Exception e) {
            // Return the error message to the LWC
            return 'Error: ' + e.getMessage();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailableEvents() {
        Date today = Date.today();         
        List<Map<String, String>> eventOptions = new List<Map<String, String>>();
        for (Event__c event : [
            SELECT Id, Name, Start_Date__c
            FROM Event__c 
            WHERE Start_Date__c >= :today 
            ORDER BY Name
        ]) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', event.Name);
            option.put('value', event.Id);
            eventOptions.add(option);
        }
        
        return eventOptions;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSessionsByEventId(Id eventId) {
        List<Map<String, String>> sessionOptions = new List<Map<String, String>>();
        
        // Ensure the query is defensive against null/invalid ID
        if (eventId == null) {
            return sessionOptions; // Return empty list
        }
        
        // Assumes Session__c has a lookup/master-detail field to Event__c
        for (Session__c session : [
            SELECT Id, Name, Available_Seats__c 
            FROM Session__c 
            WHERE Event__c = :eventId AND Available_Seats__c > 0
            ORDER BY Name
        ]) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', session.Name + ' (' + (Integer)session.Available_Seats__c + ' seats)');
            option.put('value', session.Id);
            sessionOptions.add(option);
        }
        return sessionOptions;
    }

    // Core registration logic extracted for reuse and clarity
    private static void registerAttendeeCore(Attendee__c attendee) {
        // Query must be outside the loop if this were bulkified, but for 
        // a single attendee (as passed from LWC), it's okay here. 
        // NOTE: For the InvocableMethod, the original code had a SOQL query inside 
        // a loop, which is a Governor Limit risk if the list of attendees is large. 
        // The original InvocableMethod is NOT BULKIFIED.
        
        Session__c session = [
            SELECT Id, Available_Seats__c 
            FROM Session__c 
            WHERE Id = :attendee.Selected_Session__c 
            LIMIT 1
        ];
        
        if (session.Available_Seats__c <= 0) {
            // Throw exception or use error message handling
            throw new AuraHandledException('Session is full. Please choose another.');
        }

        // DML operations
        // session.Available_Seats__c += 2;
        update session;

        attendee.Status__c = 'Registered';
        insert attendee;

        sendConfirmationEmail(attendee);
    }

    private static void sendConfirmationEmail(Attendee__c attendee) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{attendee.Email__c});
        mail.setSubject('Event Registration Confirmation');
        mail.setPlainTextBody('Hi ' + attendee.Name + ',\nYou are registered for the event.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
}