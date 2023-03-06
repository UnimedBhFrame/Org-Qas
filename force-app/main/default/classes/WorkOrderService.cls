public without sharing class WorkOrderService {

    private static final EmailTemplate templateAtaVisita = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'AtaVisita' LIMIT 1];
    private static final EmailTemplate templateAtaImplantacao = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'AtaImplantacao' LIMIT 1];
    private static final EmailTemplate templateAtaClienteAusente = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'AtaClienteAusente' LIMIT 1];
    private static final List<EmailRecebimentoAta__mdt> emailRecebimentoAta = [SELECT Id, Email__c FROM EmailRecebimentoAta__mdt];
    private static final List<EnvioAtaEmail__mdt> envioAtaEmail = [SELECT Id, RecordTypeDeveloperName__c, EmailTemplateDeveloperName__c FROM EnvioAtaEmail__mdt];

    private static WorkOrderService instance = null;
    private static Map<String, String> mapAtaModeloEmail;

    private Map<Id, Lead> mapLead;
    
    public static WorkOrderService getInstance() {
        if (instance == null) {
            instance = new WorkOrderService();
        }
        
        return instance;
    }

    public void sendEmailServiceReportFromWOLI(List<WorkOrder> wos, Map<Id, Lead> mapLead){
        this.mapLead = mapLead;

        Map<Id, WorkOrder> mapWo = new Map<Id, WorkOrder>(wos);
        Set<Id> woClienteAusente = new Set<Id>();
        //Pegar os WorkOrderLineItem das WorkOrders
        List<WorkOrderLineItem> wolis = [SELECT Id, WorkOrderId, RecordTypeId, RecordType.DeveloperName FROM WorkOrderLineItem WHERE WorkOrderId IN : wos];

        Map<Id, List<WorkOrderLineItem>> mapWoWoli = new Map<Id, List<WorkOrderLineItem>>();
        for(WorkOrderLineItem woli : wolis){
            if(!mapWoWoli.keySet().contains(woli.WorkOrderId)){
                mapWoWoli.put(woli.WorkOrderId, new List<WorkOrderLineItem>());
            }

            mapWoWoli.get(woli.WorkOrderId).add(woli);

            if(woli.RecordType.DeveloperName == 'ClienteAusente'){
                woClienteAusente.add(woli.WorkOrderId);
            }
        }

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
        for(WorkOrder wo : wos){
          //  List<Messaging.EmailFileAttachment> attachs = new List<Messaging.EmailFileAttachment>();

            //Verifica se a WorkOrder tem WorkOrderLineItem
            if(mapWoWoli.containsKey(wo.Id)){
                for(WorkOrderLineItem woli : mapWoWoli.get(wo.Id)){

                    //Verifica se a WorkOrderLineItem é permitida para o envio
                    if(atasPermitidasDeveloperName.contains(woli.RecordType.DeveloperName)){
                        List<Messaging.EmailFileAttachment> attachs = new List<Messaging.EmailFileAttachment>();

                        if(mapWoliSreport.keySet().contains(woli.Id)){
                            attachs.add(prepareAttachment(mapWoliSreport.get(woli.Id)));
                        }

                        if(attachs.size() > 0){
                            Messaging.SingleEmailMessage mail = prepareEmail(wo, attachs, mapWoliSreport.get(woli.Id).ContentVersionDocumentId, woli.RecordType.DeveloperName);
                            if(mail != null){
                            	mails.add(mail);
                            }
                        }
                    }
                }
            }   

           /* if(attachs.size() > 0){
                mails.add(prepareEmail(wo.Lead__c, attachs));
            }*/
        }

        //Prepara para o cliente ausente
        List<ServiceAppointment> appts = [SELECT Id, Description, SchedStartTime, ActualStartTime,ServiceResource__c, Lead__c FROM ServiceAppointment WHERE ParentRecordId IN : woClienteAusente AND Status != 'Rescheduled' AND SchedStartTime != null];
        Set<Id> serviceResourceIds = new Set<Id>();
        for(ServiceAppointment appt : appts){
            serviceResourceIds.add(appt.ServiceResource__c);
        }
        Map<Id, ServiceResource> mapSR = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId, RelatedRecord.Name, RelatedRecord.Email, RelatedRecord.Phone, RelatedRecord.MobilePhone, RelatedRecord.FullPhotoUrl, Foto__c FROM ServiceResource WHERE Id IN :serviceResourceIds]);

        for(ServiceAppointment appt : appts){
            mails.add(prepareEmailClienteAusente(appt, mapSR.get(appt.ServiceResource__c), mapLead.get(appt.Lead__c)));
        }

        try{
            List<Messaging.SendEmailResult> sendEmailResult = Messaging.sendEmail(mails);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
    }

    public Messaging.EmailFileAttachment prepareAttachment(ServiceReport sr){
        Datetime dateT = System.now();

        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        String attachName = 'ata_visita' + dateT.format('YYYYMMddHHmmss') + '.pdf';
        attach.setFileName(attachName);
        attach.setBody(sr.DocumentBody);

        return attach;
    }

    public Messaging.SingleEmailMessage prepareEmail(WorkOrder wo, List<Messaging.EmailFileAttachment> attachs, Id contentVersionDocumentId, String recordTypeDeveloperName){
        EmailTemplate template = getTemplate(recordTypeDeveloperName);
        
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();

        //email.setReplyTo(fromaddress);
        //email.setSenderDisplayName(fromaddress);
        Boolean leadWithEmail = mapLead != null && mapLead.containsKey(wo.Lead__c) && mapLead.get(wo.Lead__c).Email != null;
        Boolean hasEmailsInteressados = String.isNotBlank(wo.EmailsInteressados__c);
        Boolean lead30Vidas = mapLead != null && mapLead.containsKey(wo.Lead__c) && mapLead.get(wo.Lead__c).NumeroVidas__c > 30;

        if(leadWithEmail == false && hasEmailsInteressados == false && lead30Vidas == false){
            return null;
        }
        
        mail.setSaveAsActivity(true);

        if(leadWithEmail) {
            mail.setTargetObjectId(wo.Lead__c);
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

    public Messaging.SingleEmailMessage prepareEmailClienteAusente(ServiceAppointment appt, ServiceResource sresource, Lead recordLead){
        EmailTemplate template = getTemplate('ClienteAusente');

        String description = appt.Description != null ? appt.Description : '';
       // String fotoResource = sresource.RelatedRecord.FullPhotoUrl != null ? sresource.RelatedRecord.FullPhotoUrl : '';
        String fotoResource = sresource.Foto__c != null ? sresource.Foto__c : '';
        String htmlTemplate = template.HtmlValue;
        String emailResource = sresource.RelatedRecord.Email != null ? sresource.RelatedRecord.Email : '';
        String phoneResource = sresource.RelatedRecord.Phone != null ? sresource.RelatedRecord.Phone : '';
        Datetime apptDate = appt.ActualStartTime != null ? appt.ActualStartTime : appt.SchedStartTime;

        String leadAddress = recordLead.Street != null ? recordLead.Street + ' ' : '';
        leadAddress += recordLead.Numero__c != null ? recordLead.Numero__c + ', ': '';
        leadAddress += recordLead.Bairro__c != null ? recordLead.Bairro__c + ', ' : '';
        leadAddress += recordLead.City != null ? recordLead.City + ', ' : '';
        leadAddress += recordLead.PostalCode != null ? recordLead.PostalCode : '';

        htmlTemplate = htmlTemplate.replace('{!ServiceResource.Name}', sresource.RelatedRecord.Name);
        htmlTemplate = htmlTemplate.replace('{!ServiceAppointment.SchedStartTime}', apptDate.format('dd/MM/YYYY') + ' às ' + apptDate.format('HH:mm') + 'hrs');
        htmlTemplate = htmlTemplate.replace('{!ServiceAppointment.Description}', description);
        htmlTemplate = htmlTemplate.replace('{!ServiceResource.FullPhotoUrl}', fotoResource);
        htmlTemplate = htmlTemplate.replace('{!ServiceResource.Email}', emailResource);
        htmlTemplate = htmlTemplate.replace('{!ServiceResource.Phone}', phoneResource);
        htmlTemplate = htmlTemplate.replace('{!Lead.Address}', leadAddress);
                

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        //email.setReplyTo(fromaddress);
        //email.setSenderDisplayName(fromaddress);
        mail.setSaveAsActivity(true);

        if(String.isNotBlank(emailResource)) {
            if(recordLead.Email != null){
                mail.setTargetObjectId(recordLead.Id);
                mail.setBccAddresses(new List<String>{emailResource});
            }else{
                mail.setToAddresses(new List<String>{emailResource});
            }
           
        }

        mail.setTemplateId(template.Id);
        mail.setSubject(template.subject);

        mail.setHtmlBody(htmlTemplate);
        mail.setPlainTextBody(template.Body);

        mail.setReplyTo(emailResource);
        mail.setSenderDisplayName(sresource.RelatedRecord.Name);

        return mail;
    }

    private EmailTemplate getTemplate(String recordTypeDeveloperName){

        if(getMapAtaModelo().get(recordTypeDeveloperName) == 'AtaImplantacao'){
            return templateAtaImplantacao;
        }

        if(getMapAtaModelo().get(recordTypeDeveloperName) == 'AtaClienteAusente'){
            return templateAtaClienteAusente;
        }

        return templateAtaVisita;
    }

    private Map<String, String> getMapAtaModelo(){
        if(mapAtaModeloEmail == null){
            mapAtaModeloEmail = new Map<String, String>();
            for(EnvioAtaEmail__mdt envio : envioAtaEmail){
                mapAtaModeloEmail.put(envio.RecordTypeDeveloperName__c, envio.EmailTemplateDeveloperName__c);
            }
        }

        return mapAtaModeloEmail;
    }

    public void createServiceReportFromWOLI(List<WorkOrder> wos){

        

        List<WorkOrderLineItem> wolis = [SELECT Id, WorkOrderId, RecordTypeId, RecordType.DeveloperName FROM WorkOrderLineItem WHERE WorkOrderId IN : wos];
        //Pegar os ServiceReports vinculados as WorkOrderLineItem

        Map<Id, Integer> mapWoliSR = new Map<Id, Integer>();
        for(WorkOrderLineItem woli : wolis){
            if(woli.RecordType.DeveloperName != 'ClienteAusente'){
                mapWoliSR.put(woli.Id, 0);
            }
        }

        for(ServiceReport sreport : [SELECT Id, ParentId, DocumentBody, ContentVersionDocumentId, Template FROM ServiceReport WHERE ParentId IN :mapWoliSR.keySet()]){
            if(mapWoliSR.containsKey(sreport.ParentId)){
                Integer total = mapWoliSR.get(sreport.ParentId);
                mapWoliSR.put(sreport.ParentId, total + 1);
            }
        }

        List<String> woliIdsCSR = new List<String>();
        for(Id woliId : mapWoliSR.keySet()){
            if(mapWoliSR.get(woliId) == 0){
                woliIdsCSR.add(woliId);
            }
        }

        if(woliIdsCSR.size() > 0){
            IntegracaoServiceReportService.createServiceReport(woliIdsCSR);
        }
    }
}