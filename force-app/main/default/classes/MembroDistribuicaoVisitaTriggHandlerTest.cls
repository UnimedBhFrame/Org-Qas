@isTest
public class MembroDistribuicaoVisitaTriggHandlerTest {
    
    @TestSetup
    static void setup(){
        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Name = 'User',
            ResourceType = 'T'
        );
        insert rsc;

        DistribuicaoVisita__c dist = new DistribuicaoVisita__c(
            Tipo__c = 'Call center',
            NumeroVidas__c = 1,
            Codigo__c = 'PME1',
            Name = 'PME1'
        );
        insert dist;
    }

    @isTest
    static void checkResourceInGroupTest(){
        ServiceResource resource = [SELECT Id FROM ServiceResource LIMIT 1];
        DistribuicaoVisita__c dist = [SELECT Id FROM DistribuicaoVisita__c LIMIT 1];

        MembroDistribuicaoVisita__c membro1 = new MembroDistribuicaoVisita__c();
        membro1.ServiceResource__c = resource.Id;
        membro1.DistribuicaoVisita__c = dist.Id;

        Test.startTest();
        insert membro1;

        try{
            update membro1;
        }catch(Exception e){
            System.assertEquals('A Pessoa já existe como membro nessa Distribuição de Visita.', e.getDmlMessage(0));
        }
        Test.stopTest();
    }
}