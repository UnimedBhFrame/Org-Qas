@isTest
public class VinculacaoMovimentacaoMetaBatchTest {
    

    @testSetup
    static void setup(){
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE '%Admin%' LIMIT 1]; 
    	User u = new User(
            Alias = 'standt', 
            Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', 
            FirstName='Roberto',
            LastName='Oliveira de Cardoso', 
            LanguageLocaleKey='en_US',        
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='testusertest@testorgtest.com'
        );
        insert u;


        Meta__c meta = new Meta__c(
            Email__c = 'standarduser@testorg.com',
            Ano__c = Datetime.now().format('YYYY'),
            Competencia__c = VinculacaoMovimentacaoMetaBatch.getMonthBR(Datetime.now().month())
        );
        insert meta;


        Movimentacao__c mov = new Movimentacao__c(
            Competencia__c = Date.today(),
            NomeVendedor__c = 'ROBERTO OLIVEIRA DE CARDOSO',
            CanalComercializador__c = 'VENDAS LJ PROPRIA LAGOA SANTA'
        );
        insert mov;

    }

    @isTest
    static void setMovimentacaoTest(){
        Test.startTest();
        Database.executeBatch(new VinculacaoMovimentacaoMetaBatch(), 200);
        Test.stopTest();
    }
}