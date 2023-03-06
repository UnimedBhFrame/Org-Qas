public without sharing class IntegracaoServiceReportService {
    
    /*private static IntegracaoServiceReportService instance = null;
    
    public static IntegracaoServiceReportService getInstance() {
        if (instance == null) {
            instance = new IntegracaoServiceReportService();
        }
        
        return instance;
    }*/

    private static final EmailTemplate templateAtaVisita = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'AtaVisita' LIMIT 1];
    private static final EmailTemplate templateAtaImplantacao = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'AtaImplantacao' LIMIT 1];
    private static final EmailTemplate templateAtaClienteAusente = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'AtaClienteAusente' LIMIT 1];
    private static final List<EmailRecebimentoAta__mdt> emailRecebimentoAta = [SELECT Id, Email__c FROM EmailRecebimentoAta__mdt];
    private static final List<EnvioAtaEmail__mdt> envioAtaEmail = [SELECT Id, RecordTypeDeveloperName__c, EmailTemplateDeveloperName__c FROM EnvioAtaEmail__mdt];

    private static Map<String, String> mapAtaModeloEmail;

    @future(callout=true)
    public static void createServiceReport(List<String> woliIds){
        ServiceReportRequest request = new ServiceReportRequest();
        request.inputs = new List<ServiceReportRequest.Input>();

        for(String Id : woliIds){
            ServiceReportRequest.Input input = new ServiceReportRequest.Input();
            input.entityId = Id;

            request.inputs.add(input);
        }

        RestResponse response = IntegracaoServiceReportRest.getInstance().createServiceReport(JSON.serialize(request));

        if ((response.getStatusCode()/100) == 2){
            sendEmailServiceReport(woliIds);
        }   
    }

    public static void sendEmailServiceReport(List<String> woliIds){
        List<WorkOrderLineItem> wolis = [SELECT Id, WorkOrderId, Lead__c, RecordTypeId, RecordType.DeveloperName FROM WorkOrderLineItem WHERE Id IN : woliIds AND Lead__c != null AND WorkOrderId != null];       
        
        Set<Id> leadIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        for(WorkOrderLineItem woli : wolis){
            if(woli.Lead__c != null){
                leadIds.add(woli.Lead__c);
            }
            if(woli.WorkOrderId != null){
                woIds.add(woli.WorkOrderId);
            }
        }

        //Mapear Lead vinculador as WorkOrderLineItems
        Map<Id, Lead> mapLead = new Map<Id, Lead>([SELECT Id, Email, Street, Numero__c, Bairro__c, City, State, Country, PostalCode, NumeroVidas__c FROM Lead WHERE Id IN :leadIds]);

        //Mapear WorkOrder vinculador as WorkOrderLineItems
        Map<Id, WorkOrder> mapWorkOrder = new Map<Id, WorkOrder>([SELECT Id, Status, EmailsInteressados__c, OwnerId FROM WorkOrder WHERE Id IN :woIds]);

        //Pegar os ServiceReports vinculados as WorkOrderLineItem
        List<ServiceReport> sreports = [SELECT Id, ParentId, DocumentBody, ContentVersionDocumentId, Template FROM ServiceReport WHERE ParentId IN :wolis];
        
        Map<Id, ServiceReport> mapWoliSreport = new Map<Id, ServiceReport>();
        for(ServiceReport sr : sreports){
            mapWoliSreport.put(sr.ParentId, sr);
        }

        //Separa as Atas permitidas
        Set<String> atasPermitidasDeveloperName = new Set<String>();
        for(EnvioAtaEmail__mdt envio : envioAtaEmail){
            atasPermitidasDeveloperName.add(envio.RecordTypeDeveloperName__c);
        }


        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(WorkOrderLineItem woli : wolis){

            //Verifica se a WorkOrderLineItem é permitida para o envio
            if(atasPermitidasDeveloperName.contains(woli.RecordType.DeveloperName)){
                List<Messaging.EmailFileAttachment> attachs = new List<Messaging.EmailFileAttachment>();

                if(mapWoliSreport.keySet().contains(woli.Id)){
                    attachs.add(prepareAttachment(mapWoliSreport.get(woli.Id)));
                }

                if(attachs.size() > 0){
                    Messaging.SingleEmailMessage mail = prepareEmail(mapLead.get(woli.Lead__c), mapWorkOrder.get(woli.WorkOrderId), attachs, mapWoliSreport.get(woli.Id).ContentVersionDocumentId, woli.RecordType.DeveloperName);
                    if(mail != null){
                        mails.add(mail);
                    }
                }
            }
        }

        try{
            List<Messaging.SendEmailResult> sendEmailResult = Messaging.sendEmail(mails);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }

    public static Messaging.EmailFileAttachment prepareAttachment(ServiceReport sr){
        Datetime dateT = System.now();

        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        String attachName = 'ata_visita' + dateT.format('YYYYMMddHHmmss') + '.pdf';
        attach.setFileName(attachName);
        attach.setBody(sr.DocumentBody);

        return attach;
    }

    public static Messaging.SingleEmailMessage prepareEmail(Lead ld, WorkOrder wo, List<Messaging.EmailFileAttachment> attachs, Id contentVersionDocumentId, String recordTypeDeveloperName){
        EmailTemplate template = getTemplate(recordTypeDeveloperName);
        
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();

        //email.setReplyTo(fromaddress);
        //email.setSenderDisplayName(fromaddress);
        Boolean leadWithEmail = ld.Email != null;
        Boolean hasEmailsInteressados = String.isNotBlank(wo.EmailsInteressados__c);
        Boolean lead30Vidas = ld.NumeroVidas__c > 30;

        if(leadWithEmail == false && hasEmailsInteressados == false && lead30Vidas == false){
            return null;
        }
        
        mail.setSaveAsActivity(true);

        if(leadWithEmail) {
            mail.setTargetObjectId(ld.Id);
        }

        if(hasEmailsInteressados){
			List<String> emailsAdicionais = wo.EmailsInteressados__c.split(';');
        	//mail.setToAddresses(emailsAdicionais);
           // mail.setBccAddresses(emailsAdicionais);
            if(leadWithEmail){
                mail.setCcAddresses(emailsAdicionais);
            }else{
                mail.setToAddresses(emailsAdicionais);
            }
        }

        if(lead30Vidas){
            List<String> emailsSuporte = new List<String>();
            for(EmailRecebimentoAta__mdt email : emailRecebimentoAta){
                emailsSuporte.add(email.Email__c);
            }

            if(leadWithEmail || hasEmailsInteressados){
                mail.setBccAddresses(emailsSuporte);
            }else{
                mail.setToAddresses(emailsSuporte);
            }
        }

        
        mail.setTemplateId(template.Id);
        mail.setSubject(template.subject);
        mail.setHtmlBody(template.HtmlValue);
        mail.setPlainTextBody(template.Body);

        
        mail.setEntityAttachments(new List<Id>{contentVersionDocumentId});
        // mail.setFileAttachments(attachs); //remover qualquer coisa

        Id oweaId = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName='UnimedBH']?.Id;
        if ( oweaId != null) {
            mail.setOrgWideEmailAddressId(oweaId);
        }

        String email = [SELECT Id, Email FROM User WHERE Id = :wo.OwnerId]?.Email;
        if(email != null){
            mail.setReplyTo(email);
        }
        
        return mail;
    }

    private static EmailTemplate getTemplate(String recordTypeDeveloperName){

        if(getMapAtaModelo().get(recordTypeDeveloperName) == 'AtaImplantacao'){
            return templateAtaImplantacao;
        }

        if(getMapAtaModelo().get(recordTypeDeveloperName) == 'AtaClienteAusente'){
            return templateAtaClienteAusente;
        }

        return templateAtaVisita;
    }

    private static Map<String, String> getMapAtaModelo(){
        if(mapAtaModeloEmail == null){
            mapAtaModeloEmail = new Map<String, String>();
            for(EnvioAtaEmail__mdt envio : envioAtaEmail){
                mapAtaModeloEmail.put(envio.RecordTypeDeveloperName__c, envio.EmailTemplateDeveloperName__c);
            }
        }

        return mapAtaModeloEmail;
    }
}