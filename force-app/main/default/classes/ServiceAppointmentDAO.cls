public with sharing class ServiceAppointmentDAO {
    public static List<ServiceAppointment> getByIdAndStatus(Id id, Id resource) {
        List<ServiceAppointment> lst = [SELECT 
        Id, 
        Status, 
        EarliestStartTime, 
        SchedStartTime, 
        ServiceResource__c, 
        ServiceTerritory__c, 
        AtendimentoCallCenter__c 
        FROM ServiceAppointment WHERE Corretora__c =: id AND ServiceResource__c =: resource AND (Status ='Scheduled' OR Status ='In Progress')];

        return lst;
    }

    public static List<ServiceAppointment> getByResource(Id id, Id resource, DateTime dt1, DateTime dt2) {
        List<ServiceAppointment> lst = [SELECT 
        Id, 
        Status, 
        EarliestStartTime, 
        FormattedDate__c,
        AppointmentNumber,
        SchedStartTime, 
        ServiceResource__c, 
        ServiceTerritory__c, 
        AtendimentoCallCenter__c 
        FROM ServiceAppointment WHERE ServiceResource__c =: resource AND (Status ='Scheduled' OR Status ='In Progress') AND  EarliestStartTime >=: dt1 AND  EarliestStartTime <=: dt2];

        return lst;
    }
}