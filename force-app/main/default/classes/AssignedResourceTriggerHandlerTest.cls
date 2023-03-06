@isTest
public class AssignedResourceTriggerHandlerTest {

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
        
        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = u.Id,
            Name = 'User',
            ResourceType = 'T',
            TelefoneConsultor__c = '123456789'
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
            ServiceResource__c = rsc.Id
        );
        insert appt1;

        ServiceAppointment appt2 = new ServiceAppointment(
            ParentRecordId = wo.Id,
            EarliestStartTime = System.now().addDays(7),
            DueDate = System.now().addDays(8),
            SchedStartTime = System.now().addDays(7),
            SchedEndTime = System.now().addDays(8),
            ServiceTerritoryId = terr.Id,
            ServiceResource__c = rsc.Id
        );
        insert appt2;

    }

    @isTest
    static void followWorkOrderTest(){
        List<ServiceAppointment> appts = [SELECT Id FROM ServiceAppointment];
        ServiceResource rsc = [SELECT Id FROM ServiceResource LIMIT 1];
        
        system.debug('111111111111111: ' + rsc);

        AssignedResource ar1 = new AssignedResource();
        ar1.ServiceAppointmentId = appts[0].Id;
        ar1.ServiceResourceId = rsc.Id;

        AssignedResource ar2 = new AssignedResource();
        ar2.ServiceAppointmentId = appts[1].Id;
        ar2.ServiceResourceId = rsc.Id;
        
        Test.startTest();
        insert ar1;
        insert ar2;
        Test.stopTest();
    }
}