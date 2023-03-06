@isTest
public class MovimentacaoUpdateBatchTest {
    @TestSetup
    static void setup() {
        Movimentacao__c movimentacao1 = new Movimentacao__c(CPFCNPJ__c = '39527840015');
        insert movimentacao1;

        Movimentacao__c movimentacao2 = new Movimentacao__c(
            CPFCNPJ__c = '25888784000188',
            CPFTitular__c = '08492756012'
        );
        insert movimentacao2;

        Movimentacao__c movimentacao3 = new Movimentacao__c(CPFCNPJ__c = '37072381000124');
        insert movimentacao3;

        Lead lead1 = new Lead(
            LastName = 'MyLead1',
            MobilePhone = '31988887771',
            Phone = '31988887771',
            Email = 'MyLead1@email.com.br.test',
            CPF__c = '395.278.400-15',
            NumeroVidas__c = 10,
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('PessoaFisica')
                .getRecordTypeId()
        );
        insert lead1;

        Lead lead2 = new Lead(
            LastName = 'MyLead2',
            MobilePhone = '31988887772',
            Phone = '31988887772',
            Email = 'MyLead2@email.com.br.test',
            CPF__c = '084.927.560-12',
            NumeroVidas__c = 10,
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('PessoaFisica')
                .getRecordTypeId()
        );
        insert lead2;

        Lead lead3 = new Lead(
            LastName = 'MyLead3',
            MobilePhone = '31988887773',
            Phone = '31988887773',
            Email = 'MyLead3@email.com.br.test',
            CNPJ__c = '37.072.381/0001-24',
            NumeroVidas__c = 10,
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('PessoaFisica')
                .getRecordTypeId()
        );
        insert lead3;

        Lead lead4 = new Lead(
            LastName = 'MyLead4',
            MobilePhone = '31988887774',
            Phone = '31988887774',
            Email = 'MyLead4@email.com.br.test',
            CNPJ__c = '25.888.784/0001-88',
            NumeroVidas__c = 10,
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('PessoaFisica')
                .getRecordTypeId()
        );
        insert lead4;
    }

    @isTest
    static void testEcecuteMovimentacaoUpdateBatch() {
        Test.startTest();
        Database.executeBatch(new MovimentacaoUpdateBatch());
        Test.stopTest();
    }
}