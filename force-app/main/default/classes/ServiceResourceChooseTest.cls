@isTest
public class ServiceResourceChooseTest {
    
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

        createUser();
    }

    static void createUser(){
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

    	User u2 = new User(
            Alias = 'standt2', 
            Email='standarduser2@testorg.com', 
            EmailEncodingKey='UTF-8', 
            LastName='Testing2', 
            LanguageLocaleKey='en_US',        
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='testusertest2@testorgtest.com'
        );
        insert u2;

        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = u2.Id,
            Name = 'User2',
            ResourceType = 'T'
        );
        insert rsc;

    }

    @isTest
    static void testGetRespurce(){
        List<ServiceResource> srs = [SELECT Id FROM ServiceResource];

        List<ServiceResourceChoose> srcs = new List<ServiceResourceChoose>();

        for(ServiceResource sr : srs){
            ServiceResourceChoose src = new ServiceResourceChoose();
            src.resourceId = sr.Id;
            src.quant = 2;

            srcs.add(src);
        }

        Test.startTest();
        List<ServiceResourceChoose> response = ServiceResourceChoose.compareServicesResources(srcs);
        Test.stopTest();
   }

}