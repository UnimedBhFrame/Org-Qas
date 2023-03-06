@isTest
public class OpportunityTriggerHandlerTest {
    
    @TestSetup
    static void setup(){
        
    }

    @isTest
    static void copyToDocId(){
        Opportunity oppt = new Opportunity(
            Name = 'New Oppt',
            CloseDate = Date.today().addDays(10),
            CPF__c = '111.111.111-10',
            StageName = 'Elaboração de proposta'
        );

        Test.startTest();
        insert oppt;
        oppt.CPF__c = null;
        oppt.CNPJ__c = '99.999.999/9999-99';
        update oppt;
        Test.stopTest();
    }
}