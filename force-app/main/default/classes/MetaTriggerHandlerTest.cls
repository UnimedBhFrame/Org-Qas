@isTest
public class MetaTriggerHandlerTest {
    
    @testSetup
    static void setup(){
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE '%Admin%' LIMIT 1]; 
    	User u = new User(
            Alias = 'standt', 
            Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US',        
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='testusertest@testorgtest.com'
        );
        insert u;
        
    }

    @isTest
    static void setUserTest(){
        Meta__c meta = new Meta__c(
            Email__c = 'standarduser@testorg.com'
        );

        Test.startTest();
        insert meta;
        Test.stopTest();
    }
}