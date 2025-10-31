/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AttendeeTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Event
        Event__c ev = new Event__c(
            Name = '2025 Tech Conference',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(1),
            Address__c = 'Kathmandu',
            Capacity__c = 100
        );
        insert ev;

        // Session
        Session__c sess = new Session__c(
            Name__c = 'AI Workshop',
            Event__c = ev.Id,
            Available_Seats__c = 10
        );
        insert sess;
    }

    @isTest
    static void testAfterInsert() {
        // Get Session
        Session__c sess = [SELECT Id, Available_Seats__c FROM Session__c LIMIT 1];
        Integer initialSeats = sess.Available_Seats__c.intValue();

        // new Attendee
        Attendee__c att = new Attendee__c(
            Name = 'John Doe',
            Email__c = 'john@example.com',
            Status__c = 'Registered',
            Selected_Session__c = sess.Id
        );
        insert att;

        // Verify seats
        sess = [SELECT Available_Seats__c FROM Session__c WHERE Id = :sess.Id];
        System.assertNotEquals(initialSeats, sess.Available_Seats__c, 'Seats should be adjusted after registration.');
    }

    @isTest
    static void testAfterUpdate_ConfirmAndCancel() {
        //Attendee to update
        Session__c sess = [SELECT Id, Available_Seats__c FROM Session__c LIMIT 1];
        Attendee__c att = new Attendee__c(
            Name = 'Jane Doe',
            Email__c = 'jane@example.com',
            Status__c = 'Cancelled',
            Selected_Session__c = sess.Id
        );
        insert att;

        att.Status__c = 'Confirmed';
        update att;

        // Verify confirmation mail 
        Integer beforeCancelSeats = sess.Available_Seats__c.intValue();
        att = [SELECT Id, Status__c, Selected_Session__c, Email__c FROM Attendee__c WHERE Id = :att.Id];
        att.Status__c = 'Cancelled';
        update att;

        // Verify seat increment after cancellation
        sess = [SELECT Available_Seats__c FROM Session__c WHERE Id = :sess.Id];
        System.assert(sess.Available_Seats__c > beforeCancelSeats, 'Available seats should increase after cancellation.');
    }

    @isTest
    static void testBulkUpdate() {
        // Create multiple attendees
        Session__c sess = [SELECT Id FROM Session__c LIMIT 1];

        List<Attendee__c> attendees = new List<Attendee__c>();
        for (Integer i = 0; i < 5; i++) {
            attendees.add(new Attendee__c(
                Name = 'User ' + i,
                Email__c = 'user' + i + '@example.com',
                Status__c = 'Registered',
                Selected_Session__c = sess.Id
            ));
        }
        insert attendees;

        // Bulk update to cancel all
        for (Attendee__c a : attendees) {
            a.Status__c = 'Cancelled';
        }
        update attendees;

        // Assert no errors (coverage of bulk logic)
        System.assertEquals(5, [SELECT COUNT() FROM Attendee__c WHERE Status__c = 'Cancelled']);
    }
}
