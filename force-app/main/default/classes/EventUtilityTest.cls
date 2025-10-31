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
private class EventUtilityTest {

    @IsTest
    static void testGetUpcomingEvents() {

        Event__c pastEvent = new Event__c(
            Name = 'Past Event',
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(-9),
            Address__c = 'Old Venue'
        );

        Event__c upcomingEvent = new Event__c(
            Name = 'Future Event',
            Start_Date__c = Date.today().addDays(5),
            End_Date__c = Date.today().addDays(6),
            Address__c = 'Future Venue'
        );

        insert new List<Event__c>{ pastEvent, upcomingEvent };

        Test.startTest();
        List<Event__c> results = EventUtility.getUpcomingEvents();
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'There should be at least one upcoming event.');
        System.assertEquals('Future Event', results[0].Name, 'Only future events should be returned.');
        System.assert(results[0].Start_Date__c >= Date.today(), 'Returned events should have start date today or later.');
    }
}
