public without sharing class ServiceAppointmentService {

    private static final EmailTemplate templateAgendado = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'AgendamentoVisita' LIMIT 1];
    private static final EmailTemplate templateReagendado = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'ReagendamentoVisita' LIMIT 1];
    private static final EmailTemplate templateCancelado = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'CancelamentoVisita' LIMIT 1];
    
    private static ServiceAppointmentService instance = null;
    
    public static ServiceAppointmentService getInstance() {
        if (instance == null) {
            instance = new ServiceAppointmentService();
        }
        
        return instance;
    } 

    public void sendEmail(List<ServiceAppointment> appts){
        Map<Id, ServiceAppointment> mapAppts = new Map<Id, ServiceAppointment>(appts);

        Set<Id> serviceResourceIds = new Set<Id>();
        Set<Id> apptIds = new Set<Id>();
        for(ServiceAppointment appt : appts) {
            serviceResourceIds.add(appt.ServiceResource__c);
            apptIds.add(appt.Corretora__c);
        }

        Map<Id, ServiceResource> mapSR = new Map<Id, ServiceResource>([SELECT Id, TelefoneConsultor__c, RelatedRecordId, RelatedRecord.Name, RelatedRecord.Phone, RelatedRecord.MobilePhone, RelatedRecord.FullPhotoUrl, Foto__c FROM ServiceResource WHERE Id IN :serviceResourceIds]);
        Map<Id, Corretora__c> mapCorretoras = new Map<Id, Corretora__c>([SELECT Id, EmailContato__c FROM Corretora__c WHERE Id IN :apptIds]);

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        for(ServiceAppointment appt : appts) {
            mails.add(prepareEmail(appt, mapSR.get(appt.ServiceResource__c), mapCorretoras.get(appt.Corretora__c)));
        }

        try {
            List<Messaging.SendEmailResult> sendEmailResult = Messaging.sendEmail(mails);
        } catch(Exception e){
            System.debug(e.getMessage());
        }
    }

    public Messaging.SingleEmailMessage prepareEmail(ServiceAppointment appt, ServiceResource sresource, Corretora__c Corretora){
        system.debug('AAAAAAAAAAAAAAA: ' + sresource);
        EmailTemplate template = getTemplate(appt.Reagendamento__c, appt.Status);

        String description = appt.Description != null ? appt.Description : '';
        String htmlTemplate = template.HtmlValue;
        //String phoneResource = sresource.TelefoneConsultor__c != null ? sresource.TelefoneConsultor__c : '';
        String emailResource = 'Teste';//Corretora.EmailContato__c != null ? Corretora.EmailContato__c : '';
        Datetime apptDate = appt.SchedStartTime != null ? appt.SchedStartTime : appt.EarliestStartTime;
        String motivoCancelamento = appt.MotivoCancelamento__c != null ? appt.MotivoCancelamento__c : '';

        htmlTemplate = htmlTemplate.replace('{!ServiceResource.Name}', sresource.RelatedRecord.Name);
        htmlTemplate = htmlTemplate.replace('{!ServiceAppointment.SchedStartTime}', apptDate.format('dd/MM/YYYY HH:mm:ss'));
        htmlTemplate = htmlTemplate.replace('{!ServiceAppointment.Description}', description);
        //htmlTemplate = htmlTemplate.replace('{!ServiceResource.Phone}', phoneResource);
        htmlTemplate = htmlTemplate.replace('{!ServiceResource.Email}', emailResource);
        htmlTemplate = htmlTemplate.replace('{!ServiceAppointment.MotivoCancelamento__c}', motivoCancelamento);   

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSaveAsActivity(true);

        if(String.isNotBlank(emailResource)) {
            mail.setToAddresses(new List<String> {emailResource});
            mail.setTemplateId(template.Id);
            mail.setSubject(template.subject);
            mail.setHtmlBody(htmlTemplate);
            mail.setPlainTextBody(template.Body);
            //mail.setReplyTo(emailResource);
        }

        //Attach Meeting Attachment
        if(appt.Status != 'Canceled') {
            mail.setFileAttachments(new List<Messaging.EmailFileAttachment> {prepareInviteAttachment(apptDate, sresource.RelatedRecord.Name, emailResource)});
        }

        return mail;
    }

    public EmailTemplate getTemplate(Boolean reagendamento, String status){
        if(status == 'Canceled'){
            return templateCancelado;
        }

        if(reagendamento){
            return templateReagendado;
        }

        return templateAgendado;
    }

    public Messaging.EmailFileAttachment prepareInviteAttachment(Datetime dt, String resourceName, String emailResource){
        String startDT = dt.format('YYYYMMdd\'T\'HHmmss\'Z\'');
        String endDT = dt.addHours(1).format('YYYYMMdd\'T\'HHmmss\'Z\'');
        String meetingInviteBody = ''; 
        meetingInviteBody += 'BEGIN:VCALENDAR\n';        
        meetingInviteBody += 'PRODID::-//hacksw/handcal//NONSGML v1.0//EN\n';
        meetingInviteBody += 'VERSION:2.0\n';
        meetingInviteBody += 'CALSCALE:GREGORIAN\n';
        meetingInviteBody += 'METHOD:PUBLISH\n';
        meetingInviteBody += 'X-MS-OLK-FORCEINSPECTOROPEN:TRUE\n';
        meetingInviteBody += 'BEGIN:VEVENT\n';
        meetingInviteBody += 'CLASS:PUBLIC\n';
        meetingInviteBody += 'CREATED:20150126T203709Z\n';        
        meetingInviteBody += 'DTEND;TZID="America/Sao_Paulo":'+endDT+'\n';
        meetingInviteBody += 'DTSTAMP:20150126T203709Z\n';        
        meetingInviteBody += 'DTSTART;TZID="America/Sao_Paulo":'+startDT+'\n';
        meetingInviteBody += 'LAST-MODIFIED:20150126T203709Z\n';
        meetingInviteBody += 'ORGANIZER;CN=' + resourceName + ':mailto:' + emailResource + '\n';
        meetingInviteBody += 'LOCATION:\n';
        meetingInviteBody += 'PRIORITY:5\n';
        meetingInviteBody += 'SEQUENCE:0\n';
        meetingInviteBody += 'SUMMARY:Agendamento de Visita - UnimedBH ('+ resourceName + ')\n';
        meetingInviteBody += 'LANGUAGE=pt-br:Meeting\n';
        meetingInviteBody += 'TRANSP:OPAQUE\n';
        meetingInviteBody += 'X-ALT-DESC;FMTTYPE=text/html:<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN"><HTML><HEAD><META NAME="Generator" CONTENT="MS Exchange Server version 08.00.0681.000"><TITLE></TITLE></HEAD><BODY><!-- Converted from text/plain format --></BODY></HTML>\n';
        meetingInviteBody += 'X-MICROSOFT-CDO-BUSYSTATUS:BUSY\n';
        meetingInviteBody += 'X-MICROSOFT-CDO-IMPORTANCE:1\n';
        meetingInviteBody += 'END:VEVENT\n';
        meetingInviteBody += 'END:VCALENDAR';
        
        //Meeting EmailContato__c Attachment
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.Filename = 'invite.ics'; 
        attach.ContentType = 'text/calendar';     
        attach.Inline = true;     
        attach.Body = Blob.valueOf(meetingInviteBody);

        return attach;
    }
}