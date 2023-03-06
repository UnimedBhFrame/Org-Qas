public without sharing class ServiceAppointmentTriggerHandler extends TriggerHandler {
    public override void beforeInsert(){
        ServiceAppointmentDomain.getInstance().copyLeadFromWorkOrder((List<ServiceAppointment>) Trigger.new);
    }

    public override void beforeUpdate() {
        ServiceAppointmentDomain.getInstance().copyLeadFromWorkOrder((List<ServiceAppointment>) Trigger.new);
    }

    public override void afterUpdate(){
        ServiceAppointmentDomain.getInstance().sendEmail((List<ServiceAppointment>) Trigger.new, (Map<Id, ServiceAppointment>) Trigger.oldMap);
        ServiceAppointmentDomain.getInstance().setPrimeiraVisitaRealizadaLead((List<ServiceAppointment>) Trigger.new, (Map<Id, ServiceAppointment>) Trigger.oldMap);
        ServiceAppointmentDomain.getInstance().updateOwner((List<ServiceAppointment>) Trigger.new, (Map<Id, ServiceAppointment>) Trigger.oldMap);
        ServiceAppointmentDomain.getInstance().cancelParentWorkOrder((List<ServiceAppointment>) Trigger.new, (Map<Id, ServiceAppointment>) Trigger.oldMap);
    }
}