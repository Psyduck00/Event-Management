public with sharing class AttendeeTriggerHandler {
    
    public static void afterInsert(List<Attendee__c> newList) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Session__c> sessionsToUpdate = new List<Session__c>();

        for (Attendee__c att : newList) {

            // Reduce available seat count if session selected
            if (att.Selected_Session__c != null) {
                sessionsToUpdate.add(new Session__c(
                    Id = att.Selected_Session__c,
                    Available_Seats__c = (Integer)null // Placeholder, will adjust below
                ));
            }
        }

        // Reduce session seats in bulk
        adjustSessionSeats(newList, -1); // Decrease seats for new registrations

        // Send all emails together
        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails, false);
        }
    }

    public static void afterUpdate(List<Attendee__c> newList, Map<Id, Attendee__c> oldMap) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        // Sessions to update (for seat changes)
        List<Id> sessionsToUpdateIds = new List<Id>();
        Map<Id, Integer> seatAdjustment = new Map<Id, Integer>();

        for (Attendee__c att : newList) {
            Attendee__c oldAtt = oldMap.get(att.Id);

            // Handle Cancellation
            if (oldAtt.Status__c != 'Cancelled' && att.Status__c == 'Cancelled' && att.Selected_Session__c != null) {
                seatAdjustment.put(att.Selected_Session__c, seatAdjustment.get(att.Selected_Session__c) == null ? 1 : seatAdjustment.get(att.Selected_Session__c) + 1);
                if (att.Email__c != null) {
                    mails.add(buildCancellationEmail(att));
                }
            }

            // Handle Re-confirmation (if status changed back)
            if (oldAtt.Status__c != 'Confirmed' && att.Status__c == 'Confirmed' && att.Email__c != null) {
                mails.add(buildConfirmationEmail(att));
            }
        }

        // Apply seat adjustments
        if (!seatAdjustment.isEmpty()) {
            List<Session__c> sessionsToUpdate = [
                SELECT Id, Available_Seats__c FROM Session__c WHERE Id IN :seatAdjustment.keySet()
            ];
            for (Session__c s : sessionsToUpdate) {
                s.Available_Seats__c += seatAdjustment.get(s.Id);
            }
            update sessionsToUpdate;
        }

        // Send all emails together
        if (!mails.isEmpty()) {
            Messaging.sendEmail(mails, false);
        }
    }

    // Utility: Send Confirmation Email
    private static Messaging.SingleEmailMessage buildConfirmationEmail(Attendee__c att) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { att.Email__c });
        mail.setSubject('Your Event Registration Confirmation');
        mail.setPlainTextBody(
            'Hello ' + att.Name + ',\n\n' +
            'Thank you for registering for our event.\n' +
            'Your attendace has been confirmed.\n\n' +
            'Best regards,\nEvent Management Team'
        );
        return mail;
    }

    // Utility: Send Cancellation Email
    private static Messaging.SingleEmailMessage buildCancellationEmail(Attendee__c att) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { att.Email__c });
        mail.setSubject('Event Registration Cancelled');
        mail.setPlainTextBody(
            'Hello ' + att.Name + ',\n\n' +
            'Your registration for the event has been cancelled.\n' +
            'We’re sorry to see you go. Hope to see you at future events!\n\n' +
            'Best regards,\nEvent Management Team'
        );
        return mail;
    }

    // Utility: Adjust session seats in bulk
    private static void adjustSessionSeats(List<Attendee__c> attendees, Integer delta) {
        Map<Id, Integer> seatChangeMap = new Map<Id, Integer>();

        for (Attendee__c att : attendees) {
            if (att.Selected_Session__c != null) {
                seatChangeMap.put(
                    att.Selected_Session__c,
                    seatChangeMap.get(att.Selected_Session__c) == null ? delta : seatChangeMap.get(att.Selected_Session__c) + delta
                );
            }
        }

        if (!seatChangeMap.isEmpty()) {
            List<Session__c> sessions = [
                SELECT Id, Available_Seats__c FROM Session__c WHERE Id IN :seatChangeMap.keySet()
            ];
            for (Session__c s : sessions) {
                s.Available_Seats__c += seatChangeMap.get(s.Id);
            }
            update sessions;
        }
    }
}
