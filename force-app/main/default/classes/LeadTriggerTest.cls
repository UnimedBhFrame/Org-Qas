@isTest
public class LeadTriggerTest {
    @isTest
    public static void run(){
        Test.startTest();
        Database.SaveResult dsr;
        Lead testLead;
        testLead = new Lead();
        dsr = Database.insert(testLead,false);
        Test.stopTest();
        
    }

}