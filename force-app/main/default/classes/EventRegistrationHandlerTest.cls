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
@IsTest
private class EventRegistrationHandlerTest {

    // create base data
    private static Map<String, Id> setupTestData() {
        Event__c testEvent = new Event__c(
            Name = 'Test Event',
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(2)
        );
        insert testEvent;

        Session__c testSession = new Session__c(
            Name__c = 'Test Session',
            Event__c = testEvent.Id,
            Available_Seats__c = 10
        );
        insert testSession;

        return new Map<String, Id>{
            'eventId' => testEvent.Id,
            'sessionId' => testSession.Id
        };
    }

    // getAvailableEvents()
    @IsTest
    static void testGetAvailableEvents() {
        setupTestData();

        Test.startTest();
        List<Map<String, String>> results = EventRegistrationHandler.getAvailableEvents();
        Test.stopTest();

        System.assert(!results.isEmpty(), 'There should be at least one event returned.');
        System.assert(results[0].containsKey('label'), 'Label key should exist.');
        System.assert(results[0].containsKey('value'), 'Value key should exist.');
    }

    // getSessionsByEventId()
    @IsTest
    static void testGetSessionsByEventId() {
        Map<String, Id> ids = setupTestData();

        Test.startTest();
        List<Map<String, String>> sessions = EventRegistrationHandler.getSessionsByEventId(ids.get('eventId'));
        Test.stopTest();

        System.assertEquals(1, sessions.size(), 'Should return one available session.');
        System.assert(sessions[0].get('label').contains('seats'), 'Label should show seat info.');
    }

    //getSessionsByEventId() with null
    @IsTest
    static void testGetSessionsByEventIdWithNull() {
        Test.startTest();
        List<Map<String, String>> result = EventRegistrationHandler.getSessionsByEventId(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list if eventId is null.');
    }

    //registerAttendeeFromLWC()
    @IsTest
    static void testRegisterAttendeeFromLWC() {
        Map<String, Id> ids = setupTestData();

        Test.startTest();
        String response = EventRegistrationHandler.registerAttendeeFromLWC(
            'John Doe',
            'john@example.com',
            String.valueOf(ids.get('sessionId'))
        );
        Test.stopTest();

        System.assertEquals('Registration successful!', response);
        Attendee__c att = [SELECT Name, Status__c, Email__c FROM Attendee__c LIMIT 1];
        System.assertEquals('Registered', att.Status__c, 'Attendee should be registered.');
    }

    //registerAttendees() (InvocableMethod)
    @IsTest
    static void testRegisterAttendeesInvocable() {
        Map<String, Id> ids = setupTestData();

        Attendee__c att = new Attendee__c(
            Name = 'Jane Doe',
            Email__c = 'jane@example.com',
            Selected_Session__c = ids.get('sessionId')
        );

        Test.startTest();
        EventRegistrationHandler.registerAttendees(new List<Attendee__c>{ att });
        Test.stopTest();

        Attendee__c inserted = [SELECT Id, Status__c FROM Attendee__c WHERE Email__c = 'jane@example.com' LIMIT 1];
        System.assertEquals('Registered', inserted.Status__c);
    }

    //when session is full
    @IsTest
    static void testRegisterAttendeeSessionFull() {
        Map<String, Id> ids = setupTestData();

        // Set session full
        Session__c fullSession = [SELECT Id, Available_Seats__c FROM Session__c WHERE Id = :ids.get('sessionId')];
        fullSession.Available_Seats__c = 0;
        update fullSession;

        Test.startTest();
        String result = EventRegistrationHandler.registerAttendeeFromLWC(
            'Mark Doe',
            'mark@example.com',
            String.valueOf(ids.get('sessionId'))
        );
        Test.stopTest();

        System.assert(result.contains('Error'), 'Should return error for full session.');
    }
}
