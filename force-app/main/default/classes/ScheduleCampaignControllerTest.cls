@isTest
public class ScheduleCampaignControllerTest {
    
    @testSetup
    static void setup(){
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE '%Atendente Call Center%' LIMIT 1]; 
    	User u = new User(
            Alias = 'callc', 
            Email='callcenter@testorg.com', 
            EmailEncodingKey='UTF-8', 
            LastName='callcenter', 
            LanguageLocaleKey='en_US',        
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='callcenter@testorgtest.com'
        );
        insert u;

        Lead ld = new Lead(
            LastName = 'MyLead',
            MobilePhone = '31988887777',
            Status = 'Captação',
            Email = 'mylead@email.com.br.test',
           // Email__c = 'mylead@email.com.br.test',
            NumeroVidas__c = 31,
            Bairro__c = 'Centro',
            City = 'Belo Horizonte',
            Atendente__c = 'ALINE QUARESMA DA SILVA'
        );
        System.runAs(u){
            insert ld;
        }

        WorkOrder wo = new WorkOrder(
            Status = 'New',
            Lead__c = ld.Id,
            EmailsInteressados__c = 'emailtest@email.com.br.test'
        );
        System.runAs(u){
            insert wo;
        }

      /*  String call = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName().get('Call').getRecordTypeId();
        String clienteAusente = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName().get('ClienteAusente').getRecordTypeId();

        WorkOrderLineItem woli1 = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Lead__c = ld.Id,       
            Status = 'New',
            RecordTypeId = call
        );
        insert woli1;

        WorkOrderLineItem woli2 = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Lead__c = ld.Id,       
            Status = 'New',
            RecordTypeId = clienteAusente
        );
        insert woli2;*/

        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Name = 'User1',
            ResourceType = 'T'
        );
        insert rsc;

        ServiceAppointment appt = new ServiceAppointment(
            ParentRecordId = wo.Id,
            EarliestStartTime = System.now().addDays(7),
            DueDate = System.now().addDays(8),
            ActualStartTime = System.now().addDays(7),
            ServiceResource__c = rsc.Id
        );
        insert appt;

        Id terrId = createTerritory(rsc.Id);
        createUser(terrId);
        createDistribuicaoVisitas(rsc.Id, terrId);


        List<FormaDistribuicao__c> formasToInsert = new List<FormaDistribuicao__c>();
        formasToInsert.add(new FormaDistribuicao__c(Name='Loja autorizada', QuantidadeAtual__c = 0, QuantidadePermitida__c = 10));
        formasToInsert.add(new FormaDistribuicao__c(Name='Loja própria', QuantidadeAtual__c = 0, QuantidadePermitida__c = 10));
        insert formasToInsert;

    }

    static Id createTerritory(Id srId){
        OperatingHours oh = new OperatingHours(
            Name = 'MyOpHours'
        );
        insert oh;

        createTimeSlots(oh.Id);

        ServiceTerritory terr = new ServiceTerritory(
            Name = 'Belo Horizonte',
            OperatingHoursId = oh.Id,
            IsActive = true
        );
        insert terr;

        ServiceTerritory terr2 = new ServiceTerritory(
            Name = 'Centro',
            OperatingHoursId = oh.Id,
            IsActive = true,
            ParentTerritoryId = terr.Id
        );
        insert terr2;
        
        ServiceTerritoryMember mterr = new ServiceTerritoryMember(
            ServiceResourceId = srId,
            ServiceTerritoryId = terr2.Id,
            EffectiveStartDate = System.now(),
            TerritoryType = 'P'
        );
        insert mterr;


        return terr2.Id;
    }

    static void createTimeSlots(Id OperatingHoursId){

        List<String> days = new List<String>{'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};

        List<TimeSlot> tss = new List<TimeSlot>();

        for(String day : days){
            TimeSlot ts = new TimeSlot(
                OperatingHoursId = OperatingHoursId,
                DayOfWeek = day,
                StartTime = Time.newInstance(0, 0, 0, 0),
                EndTime = Time.newInstance(23, 59, 59, 0)   
            );
            
            tss.add(ts);
        }
        
        insert tss;
    }

    static void createUser(Id terrId){
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

        createDistribuicaoVisitas(rsc.Id, terrId);
    }

    static void createDistribuicaoVisitas(Id srId, Id terrId){
        DistribuicaoVisita__c dv = new DistribuicaoVisita__c(
            PessoaFisica__c = true,
            PessoaJuridica__c = true,
            Name = 'Primeira Distribuicao',
            NumeroVidas__c = 31
        );
        insert dv;

        MembroDistribuicaoVisita__c mdv = new MembroDistribuicaoVisita__c(
            ServiceResource__c = srId,
            DistribuicaoVisita__c = dv.Id
        );
        insert mdv;

        RegionalizacaoDistribuicaoVisita__c rdv = new RegionalizacaoDistribuicaoVisita__c(
            ServiceTerritory__c = terrId,
            DistribuicaoVisita__c = dv.Id
        );
        insert rdv;
    }

    @isTest
    static void getTerritoryInfo(){

        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        Map <String, Object> response = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());
        Test.stopTest();

    }

    /*
    @isTest
    static void getTerritoryInfo2(){

        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        ServiceAppointment appt = [SELECT Id FROM ServiceAppointment LIMIT 1];

        appt.SchedStartTime = System.now().addDays(7);
        appt.SchedEndTime = System.now().addDays(8);
        appt.Status = 'Scheduled';

        update appt;

        Test.startTest();
        Map <String, Object> response = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());
        Test.stopTest();

    }
*/

    @isTest
    static void getTerritoryInfo3(){
        User u = [SELECT Id FROM User WHERE Email = 'standarduser@testorg.com' LIMIT 1];
        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        System.runas(u) 
		{
            Map <String, Object> response = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());
            delete [SELECT Id FROM DistribuicaoVisita__c];
            Map <String, Object> response2 = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());
        }
        Test.stopTest();

    }

    @isTest
    static void getTerritoryInfo4(){

        delete [SELECT Id FROM FormaDistribuicao__c];

        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        Map <String, Object> response = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());
        Test.stopTest();

    }

    @isTest
    static void getTerritoryInfoRisco(){

        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        ServiceTerritory terr = [SELECT Id FROM ServiceTerritory LIMIT 1];
        

        Test.startTest();
        terr.LocalDificilAcesso__c = true;
        update terr;

        Map <String, Object> response1 = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());

        terr.LocalDificilAcesso__c = false;
        terr.Risco__c = true;
        update terr;

        Map <String, Object> response2 = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());

        terr.LocalDificilAcesso__c = true;
        update terr;

        Map <String, Object> response3 = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());
        Test.stopTest();

    }

    @isTest
    static void getTerritoryInfoTerritoryNotFound(){

        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        ServiceTerritory terr = [SELECT Id FROM ServiceTerritory LIMIT 1];
        delete terr;

        Test.startTest();
        Map <String, Object> response = ScheduleCampaignController.getTerritoryInfo(ld.Id, true, new List<String>());
        Test.stopTest();

    }


    /*
    @isTest
    static void getAvailableResource(){
        List<ServiceResource> srs = [SELECT Id, RelatedRecordId FROM ServiceResource];
        ServiceAppointment appt = [SELECT Id FROM ServiceAppointment LIMIT 1];

        appt.SchedStartTime = System.now().addDays(7);
        appt.SchedEndTime = System.now().addDays(8);
        appt.Status = 'Scheduled';
        update appt;

        Test.startTest();
        ServiceResource sr = ScheduleCampaignController.getAvailableResource(srs);
        Test.stopTest();
    }
*/


    @isTest
    static void getNotAvailableDate(){
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name = 'User1' LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];

        DateTime td = Datetime.now().addDays(7);
        DateTime compareInitDate = DateTime.newInstance(td.year(), td.month(), td.day(), 0, 0, 0);

        ResourceAbsence sa = new ResourceAbsence(
            ResourceId = sr.Id,
            Start = compareInitDate,
            End = compareInitDate.addDays(1),
            Type = 'Almoço'
        );

        Test.startTest();
        List<String> listString1 = ScheduleCampaignController.getNotAvailableDate(sr.Id, td.date(), st.Id);
        insert sa;
        List<String> listString2 = ScheduleCampaignController.getNotAvailableDate(sr.Id, td.date(), st.Id);
        Test.stopTest();
    }

    @isTest
    static void saveSchedule(){
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name = 'User1' LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];

        Test.startTest();
        Map<String, Object> response = ScheduleCampaignController.saveSchedule(ld.Id, sr.Id, st.Id, Date.today().addDays(10), 15, 0, 'description', 'ALINE QUARESMA DA SILVA', false, 'historico');
        Test.stopTest();
    }

    @isTest
    static void getRescheduleoptions(){
        Test.startTest();
        Map<String, String> response = ScheduleCampaignController.getRescheduleoptions();
        Test.stopTest();
    }

    @isTest
    static void reSaveSchedule(){
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        ServiceResource sr = [SELECT Id FROM ServiceResource WHERE Name = 'User1' LIMIT 1];
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        sa.SchedStartTime = System.now().addDays(7);
        sa.SchedEndTime = System.now().addDays(8);
        sa.Status = 'Scheduled';
        update sa;

        Test.startTest();
        Map<String, Object> response = ScheduleCampaignController.reSaveSchedule(ld.Id, sr.Id, st.Id, Date.today().addDays(10), 15, 0, 'description', sa.Id, 'Cliente Ausente');
        Test.stopTest();

    }

    @isTest
    static void cancelSchedule(){

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        sa.SchedStartTime = System.now().addDays(7);
        sa.SchedEndTime = System.now().addDays(8);
        sa.Status = 'Scheduled';
        update sa;

        Test.startTest();
        ScheduleCampaignController.cancelSchedule(sa.Id, 'Cliente ausente', null);
        Test.stopTest();

    }

    @isTest
    static void getPermissionAgendamentoSabado(){
        Test.startTest();
        ScheduleCampaignController.getPermissionAgendamentoSabado();
        Test.stopTest();
    }

    @isTest
    static void getNotAvailableTime(){
        ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];


        Test.startTest();
        ScheduleCampaignController.getNotAvailableTime(Date.today(), sr.Id);
        Test.stopTest();
    }
}