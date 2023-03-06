@isTest
public class WorkOrderTriggerHandlerTest {
    
    @testSetup
    static void setup(){

        Lead ld = new Lead(
            LastName = 'MyLead',
            MobilePhone = '31988887777',
            Status = 'Captação',
            Email = 'mylead@email.com.br.test',
            //Email__c = 'mylead@email.com.br.test',
            NumeroVidas__c = 31
        );
        insert ld;

        WorkOrder wo = new WorkOrder(
            Status = 'New',
            Lead__c = ld.Id,
            EmailsInteressados__c = 'emailtest@email.com.br.test'
        );
        insert wo;

        String call = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByDeveloperName().get('Call').getRecordTypeId();
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
        insert woli2;

        ServiceResource rsc = new ServiceResource(
            IsActive = true,
            RelatedRecordId = UserInfo.getUserId(),
            Name = 'User',
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

    }

    @isTest
    static void finishWorkOderLineItem(){
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        ServiceReport sr = new ServiceReport();
        //sr.ContentVersionDocumentId = documents[0].Id ;
        sr.DocumentBody = Blob.valueOf('Test Content') ; 
        sr.DocumentContentType ='application/pdf';
        sr.DocumentName='Test';
        sr.ParentId = woli.Id ; 
        insert sr;

        Test.startTest();
        wo.Status = 'Completed';
        update wo;
        Test.stopTest();

    }
}