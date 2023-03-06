@isTest
public class LeadTriggerHandlerTest {
    @TestSetup
    static void setup(){
        Lead ld = new Lead(
            LastName = 'MyLead',
            MobilePhone = '(31) 98888-7777',
            Status = 'Captação',
            Email = 'mylead@email.com.br.test',
            CPF__c = '113.098.221-47',
           // Email__c = 'mylead@email.com.br.test',
            DataVigencia__c = Date.today(),
            NumeroVidas__c = 10,
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PessoaFisica').getRecordTypeId(),
            PesquisaEnviada__c = true
        );
        
        Lead ldClone = new Lead(
            LastName = 'MyLead',
            MobilePhone = '(31) 98888-7777',
            Status = 'Captação',
            Email = 'mylead@email.com.br.test',
            CPF__c = '113.098.221-47',
           // Email__c = 'mylead@email.com.br.test',
            DataVigencia__c = Date.today(),
            NumeroVidas__c = 10,
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('PessoaFisica').getRecordTypeId(),
            PesquisaEnviada__c = true
        );
        insert ld;
        
        try {
        	insert ldClone;
        }catch (Exception e){
            System.debug('Exception Caught!');
			System.assert(e.getMessage().contains('Lead Duplicado.'));
        }

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
    static void criaCloneTest(){
        Lead ld = [SELECT Id, LastName, MobilePhone, Status, Email, /* Email__c*/ NumeroVidas__c FROM Lead LIMIT 1];

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;

        Test.startTest();
        Lead cloneLd = ld.clone(false, false, false, false);
        ld.MobilePhone = '31988887771';
        ld.LastName = 'MyLeadClone';
        ld.Email = 'mylead@email.com.br.test2';
        ld.CNPJ__c = '39.823.804/0001-26';
        //ld.// Email__c = 'mylead@email.com.br.test2';
        Database.SaveResult sr = Database.insert(cloneLd, dml); 
        Test.stopTest();
    }
    @isTest
    static void sendRelashiopToAccountTest(){
        Lead ld = [SELECT Id, LastName, MobilePhone, Status, Email, /* Email__c*/ NumeroVidas__c FROM Lead LIMIT 1];

        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld.id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Convertido');

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();
    }
}