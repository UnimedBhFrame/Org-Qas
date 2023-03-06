public without sharing class AssigedResourceDomain {
    
    private static AssigedResourceDomain instance = null;
    
    public static AssigedResourceDomain getInstance() {
        if (instance == null) {
            instance = new AssigedResourceDomain();
        }
        
        return instance;
    }
    
    
    public void followWorkOrder(List<AssignedResource> ars){
        Set<Id> apptIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();

        for(AssignedResource ar : ars){
            apptIds.add(ar.ServiceAppointmentId);
            resourceIds.add(ar.ServiceResourceId);
        }

        Map<Id, ServiceAppointment> mapServiceAppt = new Map<Id, ServiceAppointment>([SELECT Id, ParentRecordId FROM ServiceAppointment WHERE Id IN : apptIds]);
        Map<Id, ServiceResource> mapServiceResource = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN : resourceIds]);


        /*Verificação do Usuário e a WorkOrder no EntitySubscription*/        
        Set<Id> workOrderIds = new Set<Id>();
        for(ServiceAppointment sa :  mapServiceAppt.values()){
            if(sa.ParentRecordId != null && sa.ParentRecordId.getsObjectType().getDescribe().getName() == 'WorkOrder'){
                workOrderIds.add(sa.ParentRecordId);
            }
        }

        Set<Id> userIds = new Set<Id>();
        for(ServiceResource sr :  mapServiceResource.values()){
            userIds.add(sr.RelatedRecordId);
        }

        List<EntitySubscription> existEntities = [SELECT Id, ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN :workOrderIds AND SubscriberId IN :userIds];
        
        Map<Id, Set<Id>> mapWOrderUsers = new Map<Id, Set<Id>>();
        for(EntitySubscription entity : existEntities){
            if(!mapWOrderUsers.keySet().contains(entity.ParentId)){
                mapWOrderUsers.put(entity.ParentId, new Set<Id>());
            }

            mapWOrderUsers.get(entity.ParentId).add(entity.SubscriberId);
        }
        /*FIM - Verificação do Usuário e a WorkOrder no EntitySubscription*/
        
        
        
        List<EntitySubscription> entities = new List<EntitySubscription>();
      
        for(AssignedResource ar : ars){

            Id workOrderId = mapServiceAppt.get(ar.ServiceAppointmentId).ParentRecordId;
            Id userId = mapServiceResource.get(ar.ServiceResourceId).RelatedRecordId;

            if(workOrderId != null && workOrderId.getsObjectType().getDescribe().getName() == 'WorkOrder' &&
                (mapWOrderUsers.get(workOrderId) == null || !mapWOrderUsers.get(workOrderId).contains(userId))){
                EntitySubscription newEntity = new EntitySubscription();
                newEntity.ParentId = workOrderId;   //Account, Contact, Custom Object...
                newEntity.SubscriberId = userId; //USER ID               
                entities.add(newEntity);
            }
        }

        Database.insert(entities, false);
    }

    public void updateServiceResourceInServiceAppoitment(List<AssignedResource> ars){
        List<ServiceAppointment> appts = new List<ServiceAppointment>();
    
        for(AssignedResource ar : ars){
            ServiceAppointment appt = new ServiceAppointment(
                Id = ar.ServiceAppointmentId,
                ServiceResource__c = ar.ServiceResourceId
            );

            appts.add(appt);
        }

        TriggerHandler.bypass(ServiceAppointmentTriggerHandler.class);
        update appts;
        TriggerHandler.clearBypass(ServiceAppointmentTriggerHandler.class);
    }


    public void setOwnerAsUserServiceResource(List<AssignedResource> ars){
        Set<Id> apptIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();

        for(AssignedResource ar : ars){
            apptIds.add(ar.ServiceAppointmentId);
            resourceIds.add(ar.ServiceResourceId);
        }

        Map<Id, ServiceAppointment> mapServiceAppt = new Map<Id, ServiceAppointment>([SELECT Id, ParentRecordId FROM ServiceAppointment WHERE Id IN : apptIds]);
        Map<Id, ServiceResource> mapServiceResource = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN : resourceIds]);

        List<WorkOrder> wos = new List<WorkOrder>();


        for(AssignedResource ar : ars){
            mapServiceAppt.get(ar.ServiceAppointmentId).OwnerId = mapServiceResource.get(ar.ServiceResourceId).RelatedRecordId;
        
            Id parentRecordId = mapServiceAppt.get(ar.ServiceAppointmentId).ParentRecordId;
            if(parentRecordId.getsObjectType().getDescribe().getName() == 'WorkOrder'){
                WorkOrder wo = new WorkOrder(
                    Id = parentRecordId,
                    OwnerId = mapServiceResource.get(ar.ServiceResourceId).RelatedRecordId
                );

                wos.add(wo);
            }
        }

        TriggerHandler.bypass(ServiceAppointmentTriggerHandler.class);
        update mapServiceAppt.values();
        TriggerHandler.clearBypass(ServiceAppointmentTriggerHandler.class);

        TriggerHandler.bypass(WorkOrderTriggerHandler.class);
        update wos;
        TriggerHandler.clearBypass(WorkOrderTriggerHandler.class);
    }
}