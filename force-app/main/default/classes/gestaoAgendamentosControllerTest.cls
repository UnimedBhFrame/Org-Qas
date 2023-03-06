@isTest
public class gestaoAgendamentosControllerTest {
    @testSetup
    static void setup() {
        Corretora__c co = new Corretora__c(
            Name = 'Corretora Teste',
            CNPJ__c = '12345678900000',
            DataDeAberturaDaCorretora__c = date.today(),
            TelefoneContato__c = '111111111',
            SobrenomeContato__c = 'Teste',
            Endereco__c = 'Teste', 
            EnderecoCidade__c = 'Belo Horizonte',
            EnderecoBairro__c = 'Goiânia'
        );
        insert co;
        
       Corretora__c co2 = new Corretora__c(
            Name = 'Corretora Teste2',
            CNPJ__c = '12345678900001',
            DataDeAberturaDaCorretora__c = date.today(),
            TelefoneContato__c = '111121111',
            SobrenomeContato__c = 'Teste',
            Endereco__c = 'Teste',
            EnderecoCidade__c = 'Belo Horizonte',
            EnderecoBairro__c = 'Goiânia'
        );
        insert co2;
        
        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Name = 'User1',
            ResourceType = 'T'
        );
        insert rsc;
        
        WorkOrder wo = new WorkOrder(
            Status = 'New',
            Corretora__c = co.Id,
            EmailsInteressados__c = 'emailtest@email.com.br.test'
        );
        insert wo;
        
        ServiceAppointment appt = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Corretora__c = co.Id,
            Status = 'Scheduled',
            EarliestStartTime = System.now().addDays(7).addHours(-4),
            DueDate = System.now().addDays(8),
            ActualStartTime = System.now().addDays(7),
            ServiceResource__c = rsc.Id
        );
        insert appt;
        
        ServiceAppointment appt2 = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Scheduled',
            EarliestStartTime = System.now().addDays(7),
            DueDate = System.now().addDays(8),
            ActualStartTime = System.now().addDays(7),
            ServiceResource__c = rsc.Id
        );
        insert appt2;
        
        OperatingHours oh = new OperatingHours(
            Name = 'MyOpHours'
        );
        insert oh;
        
        ServiceTerritory terr = new ServiceTerritory(
            Name = 'Belo Horizonte',
            OperatingHoursId = oh.Id,
            IsActive = true
        );
        insert terr;
    }

    @isTest 
    public static void hasAccessTest() {
        String id = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;

        Test.startTest();
        gestaoAgendamentosController.hasAccess(id);
        Test.stopTest();
    }
    
    @isTest 
    public static void getTerritoryInfoTest() {
        Id co = [SELECT Id FROM Corretora__c LIMIT 1].Id;
        //ServiceResource rsc = [SELECT Id FROM ServiceResource WHERE Name = 'User1' LIMIT 1];
        String id = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;

        Test.startTest();
        gestaoAgendamentosController.getTerritoryInfo(co,id);
        Test.stopTest();
    }
    
    @isTest 
    public static void getTerritoryInfoTest2() {
        Id co2 = [SELECT Id, Name FROM Corretora__c WHERE Name = 'Corretora Teste2' LIMIT 1].Id;
        String id = [SELECT Id, RelatedRecordId FROM ServiceResource LIMIT 1].RelatedRecordId;

        Test.startTest();
        gestaoAgendamentosController.getTerritoryInfo(co2,id);
        Test.stopTest();
    }
    
    @isTest 
    public static void getAppTest() {
        Id co = [SELECT Id, Name FROM Corretora__c WHERE Name = 'Corretora Teste2' LIMIT 1].Id;
        ServiceResource rsc = [SELECT Id FROM ServiceResource WHERE Name = 'User1' LIMIT 1];
       
        Date scheDate = Date.today().addDays(7);
        String scheTime = '5';
        Id us = UserInfo.getUserId();
        
        Test.startTest();
        gestaoAgendamentosController.getApp(co,us,scheDate,scheTime);
        gestaoAgendamentosController.getAvailableSchedule(scheDate,co,us);
        Test.stopTest();
    }
    
    @isTest 
    public static void CRUDTests() {
        Id co = [SELECT Id, Name FROM Corretora__c WHERE Name = 'Corretora Teste2' LIMIT 1].Id;
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceAppointment sa = [SELECT Id, EarliestStartTime FROM ServiceAppointment LIMIT 1];
        
        Id us = UserInfo.getUserId();
        Date scheDate = Date.today().addDays(7);
        String scheTime = '5';
        String mot = 'Cliente ausente';
        String subMot = '';
        
        Test.startTest();
        gestaoAgendamentosController.saveSchedule(co,us,st.Id,scheDate,scheTime,mot);
        gestaoAgendamentosController.saveReschedule(scheDate,scheTime,mot,sa.Id,mot);
        gestaoAgendamentosController.cancelSchedule(sa.Id, mot,subMot);
        Test.stopTest();
    }
}