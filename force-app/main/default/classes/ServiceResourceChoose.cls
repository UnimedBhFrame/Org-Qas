public class ServiceResourceChoose {

    public String resourceId{get; set;}
    public Integer quant {get; set;}
    
    public static ServiceResource getResource(List<ServiceResourceChoose> resourceList){
        
        ServiceResource sr;
        List<ServiceResourceChoose> nsrcl = getResourceChooseList(resourceList);
        if(nsrcl.size() > 1){
            List<ServiceResourceChoose> getComparedResources = compareServicesResources(resourceList);
            //List<ServiceResourceChoose> lastnsrcl = getResourceChooseList(getComparedResources);
            sr = [SELECT Id, Name from ServiceResource Where Id =: getComparedResources[0].resourceId];
        } else {
            sr = [SELECT Id, Name from ServiceResource Where Id =: nsrcl[0].resourceId];
        }
        
        return sr;
    }
    
    //compare the visits if the two services have the same number of visits
    public static List<ServiceResourceChoose> compareServicesResources(List<ServiceResourceChoose> resourceList){
        PeriodoCompetencia__mdt pc;
        if(Test.isRunningTest()){
            pc = ScheduleCampaignControllerFactory.createMetaPeriodo();
        } else {
        	pc = [SELECT DataUltimaCompetencia__c, DiasSucessores__c from PeriodoCompetencia__mdt Limit 1];    
        }
        Date initDate = pc.DataUltimaCompetencia__c;
        Date endDate = initDate.addDays(Integer.valueOf(pc.DiasSucessores__c));

        Integer auxQuant;

        List<ServiceResourceChoose> lsrc = new List<ServiceResourceChoose>();
        ServiceResourceChoose src = new ServiceResourceChoose();

        Map<Id, Integer> mapSRTotal = new Map<Id, Integer>();
        Set<Id> srIds = new Set<Id>();
        for(ServiceResourceChoose resList : resourceList){
            srIds.add(resList.resourceId);

           // if(!mapSRTotal.containsKey(appt.ServiceResource__c)){
                mapSRTotal.put(resList.resourceId, 0);
           // }
        }

        Date dateToday = Date.today();
        Datetime startedDate = Datetime.newInstance(dateToday.year(), dateToday.month(), dateToday.addDays(-1).day(), 0, 0, 0);
        Datetime endedDate = Datetime.newInstance(dateToday.year(), dateToday.month(), dateToday.day(), 23, 59, 59);

        Map<Id, ServiceAppointment> mapWOAppt = new Map<Id, ServiceAppointment>();
        for(ServiceAppointment appt : [SELECT Id, ParentRecordId, ServiceResource__c FROM ServiceAppointment WHERE ServiceResource__c IN :srIds AND Status = 'Scheduled' AND ParentRecordType = 'WorkOrder' AND CreatedDate >= :startedDate AND CreatedDate <= :endedDate/*SchedStartTime >= :Date.today()*/]){
            mapWOAppt.put(appt.ParentRecordId, appt);
        }

        for(WorkOrder wo : [SELECT Id FROM WorkOrder WHERE Id IN : mapWOAppt.keySet() AND (CreatedBy.ProfileId = :System.Label.ProfileId_AtendenteCallCenter OR CreatedBy.ProfileId = :System.Label.ProfileId_Promotor)]){
            if(mapWOAppt.containsKey(wo.Id)){
                ServiceAppointment appt = mapWOAppt.get(wo.Id);
                
                Integer quant = mapSRTotal.get(appt.ServiceResource__c);
                mapSRTotal.put(appt.ServiceResource__c, quant + 1);
            }
        }


        for(Id srId : mapSRTotal.keySet()){
                    
            if(auxQuant == null){
                auxQuant = mapSRTotal.get(srId);
                src.quant = mapSRTotal.get(srId);
                src.resourceId = srId;
            }else{
                if(mapSRTotal.get(srId) < auxQuant){
                    auxQuant = mapSRTotal.get(srId);
                    src.quant = mapSRTotal.get(srId);
                    src.resourceId = srId;
                }
            }            
        }
        
        lsrc.add(src);
        return lsrc;
    }
    
    //get the resource with less visits
    private static List<ServiceResourceChoose> getResourceChooseList(List<ServiceResourceChoose> resourceList){
        
        List<ServiceResourceChoose> nsrcl = new List<ServiceResourceChoose>();
        if(!resourceList.isEmpty()){
            Integer lessNumber = resourceList[0].quant;
            for(ServiceResourceChoose resList : resourceList){
                If(resList.quant < lessNumber){
                    lessNumber = resList.quant;
                }
            }
            
            for(ServiceResourceChoose newresList : resourceList){
                If(newresList.quant == lessNumber){
                    nsrcl.add(newresList);
                }
            }
            System.debug('nsrcl '+nsrcl);
            
        }
        return nsrcl;
    }
}