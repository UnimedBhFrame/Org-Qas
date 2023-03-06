@isTest
public class VinculacaoLeadMetaBatchTest {
    
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

        Lead ld = new Lead(
            OwnerId = u.Id,
            LastName = 'MyLead',
            MobilePhone = '31988887777',
            Status = 'Captação',
            Email = 'mylead@email.com.br.test',
            CPF__c = '377.527.140-62',
           // Email__c = 'mylead@email.com.br.test',
            DataVigencia__c = Date.today(),
            NumeroVidas__c = 10,
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PessoaFisica').getRecordTypeId()
        );
        insert ld;

        Meta__c meta = new Meta__c(
            Email__c = 'standarduser@testorg.com',
            Ano__c = Datetime.now().format('YYYY'),
            Competencia__c = VinculacaoLeadMetaBatch.getMonthBR(Datetime.now().format('MM'))

        );
        insert meta;
        
    }

    @isTest
    static void setLeadTest(){
        Meta__c meta = [SELECT Id, IdExterno__c FROM Meta__c];
        System.debug(meta);

        Test.startTest();
        Database.executeBatch(new VinculacaoLeadMetaBatch(), 200);
        Test.stopTest();
    }
}