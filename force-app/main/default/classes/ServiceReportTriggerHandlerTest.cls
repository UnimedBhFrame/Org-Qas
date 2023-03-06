@isTest
public class ServiceReportTriggerHandlerTest {

    @testSetup
    static void setup(){

        Lead ld = new Lead(
            LastName = 'MyLead',
            MobilePhone = '31988887777',
            Status = 'Captação',
            Email = 'mylead@email.com.br.test',
            NumeroVidas__c = 1/*,
            Email__c = 'mylead@email.com.br.test'*/
        );
        insert ld;

        WorkOrder wo = new WorkOrder(
            Status = 'New',
            Lead__c = ld.Id
        );
        insert wo;

        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Lead__c = ld.Id,       
            Status = 'New'
        );
        insert woli;
    }

    @isTest
    static void finishWorkOderLineItem(){
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];

        ServiceReport sr = new ServiceReport();
        //sr.ContentVersionDocumentId = documents[0].Id ;
        sr.DocumentBody = Blob.valueOf('Test Content') ; 
        sr.DocumentContentType ='application/pdf';
        sr.DocumentName='Test';
        sr.ParentId = woli.Id ; 

        Test.startTest();
        insert sr;
        Test.stopTest();

    }
}