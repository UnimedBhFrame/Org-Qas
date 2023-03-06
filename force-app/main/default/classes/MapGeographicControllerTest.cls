@isTest
public class MapGeographicControllerTest {

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
            LastName = 'MyLead',
            MobilePhone = '31988887777',
            Status = 'Captação',
            Email = 'mylead@email.com.br.test',
            NumeroVidas__c = 31/*,
            Email__c = 'mylead@email.com.br.test'*/
        );
        insert ld;
        
        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = u.Id,
            Name = 'User',
            ResourceType = 'T'
        );
        insert rsc;
        
        OperatingHours oh = new OperatingHours(
            Name = 'MyOpHours'
        );
        insert oh;

        ServiceTerritory terr = new ServiceTerritory(
            Name = 'MyTerr',
            OperatingHoursId = oh.Id,
            IsActive = true
        );
        insert terr;
        
        ServiceTerritoryMember mterr = new ServiceTerritoryMember(
            ServiceResourceId = rsc.Id,
            ServiceTerritoryId = terr.Id,
            EffectiveStartDate = System.now(),
            TerritoryType = 'P'
        );
        insert mterr;
        
        WorkOrder wo = new WorkOrder(
            Status = 'New',
            ServiceTerritoryId = terr.Id
        );
        insert wo;

        ServiceAppointment appt1 = new ServiceAppointment(
            ParentRecordId = wo.Id,
            EarliestStartTime = System.now().addDays(7),
            DueDate = System.now().addDays(8),
            SchedStartTime = System.now().addDays(7),
            SchedEndTime = System.now().addDays(8),
            ServiceTerritoryId = terr.Id,
            Carga__c = true,
            Lead__c = ld.Id,
            ServiceResource__c = rsc.Id
        );
        insert appt1;
        
        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = appt1.Id;
        ar1.ServiceResourceId = rsc.Id;
        
        insert ar1;
    }
    
    @isTest
    static void obtainServiceResourceTest(){
        ServiceTerritory terr = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceResource rsc = [SELECT Id FROM ServiceResource LIMIT 1];

        /*ServiceTerritoryMember mterr = new ServiceTerritoryMember(
            ServiceResourceId = rsc.Id,
            ServiceTerritoryId = terr.Id,
            EffectiveStartDate = System.now(),
            TerritoryType = 'P'
        );
        insert terr;*/

        Test.startTest();
        List<ServiceResource> srs = MapGeographicController.obtainServiceResource(true, true, new List<String>{'Consultores'}, new List<String>{'PME1 e Individual'}, terr.Id);
        Test.stopTest();

       // System.assertEquals(1, srs.size());
    }

    @isTest
    static void obtainLocationsTest() {
        
        ServiceResource rsc = [SELECT Id FROM ServiceResource LIMIT 1];
        Date hoje = System.today();
        String dataStr = String.valueOf(hoje);
        
        Test.startTest();
        List<RastreamentoRecursoServico__b> rast = MapGeographicController.obtainLocations(rsc.Id, dataStr, dataStr);
        Test.stopTest();
    }

    @isTest
    static void obtainServiceAppointmentTest() {
        
        ServiceResource rsc = [SELECT Id FROM ServiceResource LIMIT 1];
        Date hoje = System.today();
        String dataStr = String.valueOf(hoje);

        Test.startTest();
        List<ServiceAppointment> appts = MapGeographicController.obtainServiceAppointment(rsc.Id, dataStr, dataStr);
        Test.stopTest();
    }

    @isTest
    static void checkPermissionMapTest(){
        Test.startTest();
        Boolean hasPerm = MapGeographicController.checkPermissionMap();
        Test.stopTest();
    }
    
    @isTest
    public static void testarFiltros() {
        
        List<String> filtros = MapGeographicController.verificarFiltrosAnteriores();
        
        List<String> lista = new List<String>();
        MapGeographicController.salvarFiltros(true, false, lista, lista, 'teste', 'teste', 'teste', 'teste');
    }
}