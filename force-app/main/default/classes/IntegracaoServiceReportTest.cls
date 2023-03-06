@isTest
public class IntegracaoServiceReportTest {
    
    @TestSetup
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

        WorkOrderLineItem woli1 = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            Lead__c = ld.Id,       
            Status = 'New',
            RecordTypeId = call
        );
        insert woli1;
    }


    @isTest
    static void createServiceReportTest(){
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new IntegracaoServiceReportMock());
        IntegracaoServiceReportService.createServiceReport(new List<String>{woli.Id});
        try{
            new IntegracaoRest().execute(null, null, null, null, null, null);
        }catch(Exception e){
            
        }
        Test.stopTest();
    }

    @isTest
    static void sendEmailServiceReportTest(){
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        ServiceReport sr = new ServiceReport();
        //sr.ContentVersionDocumentId = documents[0].Id ;
        sr.DocumentBody = Blob.valueOf('Test Content') ; 
        sr.DocumentContentType ='application/pdf';
        sr.DocumentName='Test';
        sr.ParentId = woli.Id ; 
        insert sr;

        Test.startTest();
        IntegracaoServiceReportService.sendEmailServiceReport(new List<String>{woli.Id});
        Test.stopTest();
    }
}