@isTest
public class VinculacaoOpportunityMetaBatchTest {
    
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

        Account acc = new Account(
            Name = 'New Account',
            DataVigencia__c = Date.today(),
            Phone = '(31) 98888-1717'
        );
        insert acc;

        Opportunity oppt = new Opportunity(
            OwnerId = u.Id,
            Name = 'New Oppt',
            CloseDate = Date.today().addDays(10),
            CPF__c = '111.111.111-10',
            StageName = 'Elaboração de proposta',
            AccountId = acc.Id
        );
        insert oppt;

        Meta__c meta = new Meta__c(
            Email__c = 'standarduser@testorg.com',
            Ano__c = Datetime.now().format('YYYY'),
            Competencia__c = VinculacaoOpportunityMetaBatch.getMonthBR(Datetime.now().month())

        );
        insert meta;
        
    }

    @isTest
    static void setOpportunityTest(){
        Test.startTest();
        Database.executeBatch(new VinculacaoOpportunityMetaBatch(), 200);
        Test.stopTest();
    }
}