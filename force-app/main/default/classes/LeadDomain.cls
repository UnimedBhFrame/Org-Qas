public without sharing class LeadDomain {
    
    private static LeadDomain instance = null;
    
    public static LeadDomain getInstance() {
        if (instance == null) {
            instance = new LeadDomain();
        }
        
        return instance;
    }
    
    public void setProprietarioOriginal(List<Lead> leads){
        
        for(Lead l : leads){
            if(l.OwnerId != null && l.OwnerId.getsObjectType().getDescribe().getName() == 'User' && l.ProprietarioOriginal__c == null){
                l.ProprietarioOriginal__c = l.OwnerId;
            }
        }
    }
    public void criaClone(List<Lead> leads){
        List<Lead> toUpdate = new List<Lead>();
        for (Lead l : leads){
            if(l.isClone()){
                l.LeadPai__c = l.getCloneSourceId();
                
                Lead ld = new Lead(
                	Id = l.getCloneSourceId(),
                    Status = 'Entrada de terceiros'
                );
                
                toUpdate.add(ld);
            }
        }
        
        TriggerHandler.bypass(LeadTriggerHandler.class);
        Database.update(toUpdate, false);
        TriggerHandler.clearBypass(LeadTriggerHandler.class);
    }

    public void sendRelationshipToAccount(List<Lead> leads, Map<Id, Lead> oldLeads){
        List<Lead> leadConverteds = new List<Lead>();

        for(Lead ld : leads){
            if(ld.Status == 'Convertido' && oldLeads.get(ld.Id).Status != 'Convertido' && ld.ConvertedAccountId != null){
                leadConverteds.add(ld);
            }
        }

        if(!leadConverteds.isEmpty()){
            LeadService.getInstance().sendRelationshipToAccount(leadConverteds);
        }

    }
}