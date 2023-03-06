@isTest
public class ServicePointGroupComponentControllerTest {

    @testSetup
    static void setup(){

        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Name = 'User1',
            ResourceType = 'T'
        );
        insert rsc;

        DistribuicaoVisita__c dv = new DistribuicaoVisita__c(
            PessoaFisica__c = true,
            PessoaJuridica__c = true,
            Name = 'Primeira Distribuicao',
            NumeroVidas__c = 31
        );
        insert dv;

        MembroDistribuicaoVisita__c mdv = new MembroDistribuicaoVisita__c(
            ServiceResource__c = rsc.Id,
            DistribuicaoVisita__c = dv.Id
        );
        insert mdv;
    }

    @isTest
    static void getAbsenceTypeTest(){
        Test.startTest();
        Map<String, String> response = ServicePointGroupComponentController.getAbsenceType();
        Test.stopTest();
    }

    @isTest
    static void getResourceAbsenceTest(){
        DistribuicaoVisita__c dv = [SELECT Id FROM DistribuicaoVisita__c LIMIT 1];
        MembroDistribuicaoVisita__c mdv = [SELECT Id FROM MembroDistribuicaoVisita__c LIMIT 1];

        Test.startTest();
        List<ResourceAbsence> response1 = ServicePointGroupComponentController.getResourceAbsence(dv.Id);
        List<ResourceAbsence> response2 = ServicePointGroupComponentController.getResourceAbsence(mdv.Id);
        Test.stopTest();
    }

    @isTest
    static void saveAbscences(){
        DistribuicaoVisita__c dv = [SELECT Id FROM DistribuicaoVisita__c LIMIT 1];
        MembroDistribuicaoVisita__c mdv = [SELECT Id FROM MembroDistribuicaoVisita__c LIMIT 1];


        Test.startTest();
        String result1 = ServicePointGroupComponentController.saveAbscences(dv.Id, 'Almoço', Datetime.now(), Datetime.now().addHours(1), 'Descrição');
        String result2 = ServicePointGroupComponentController.saveAbscences(mdv.Id, 'Almoço', Datetime.now().addDays(1), Datetime.now().addDays(1).addHours(1), 'Descrição');
        Test.stopTest();

    }
}