public with sharing class EventRegistrationHandler {


    @InvocableMethod(label='Register Attendee')
    public static void registerAttendees(List<Attendee__c> attendees) {
        registerAttendeeCore(attendees[0]); 
    }

    @AuraEnabled
    public static String registerAttendeeFromLWC(String attendeeName, String attendeeEmail, String sessionId) {
        try {
            Attendee__c newAttendee = new Attendee__c(
                Name = attendeeName,
                Email__c = attendeeEmail,
                Selected_Session__c = sessionId
            );
            

            registerAttendeeCore(newAttendee);

            return 'Registration successful!';

        } catch (Exception e) {
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
        

        if (eventId == null) {
            return sessionOptions; // Return empty list
        }
        

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


    private static void registerAttendeeCore(Attendee__c attendee) {
        
        Session__c session = [
            SELECT Id, Available_Seats__c 
            FROM Session__c 
            WHERE Id = :attendee.Selected_Session__c 
            LIMIT 1
        ];
        
        if (session.Available_Seats__c <= 0) {
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