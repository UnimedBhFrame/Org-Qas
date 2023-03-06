@isTest
public class ServiceAppointmentTriggerHandlerTest {

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
           // Email__c = 'mylead@email.com.br.test',
            NumeroVidas__c = 31
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
    static void checkBusinessHoursTest(){
        ServiceAppointment appt = [SELECT Id FROM ServiceAppointment LIMIT 1];
        appt.Status = 'Scheduled';
        /*update appt;

        appt.Status = 'In Progress';
        update appt;

        Test.startTest();
        appt.Status = 'Completed';
        appt.Venda_Realizada__c = 'Sim';*/
        Test.startTest();
        try{
            update appt;
        }catch(Exception e){
            String message = e.getDmlMessage(0);
            System.debug('message'+message);
            System.assertEquals('O agendamento não pode ser concluído fora do horário de expediente!', message);
        }
        Test.stopTest();

    }
}