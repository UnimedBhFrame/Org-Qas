public without sharing class LeadTriggerHandler extends TriggerHandler {
    
    //TO DO fazer classe de test

    public override void beforeInsert() {
        system.debug('1');
        LeadDomain.getInstance().setProprietarioOriginal((List<Lead>) Trigger.new);
        LeadDomain.getInstance().criaClone((List<Lead>) Trigger.new);

        Set<String> cpfcnpj = new Set<String>();
        Set<Id> ownerIds = new Set<Id>();
        
        for(Lead ld: (List<Lead>)Trigger.new){
            if( String.isNotBlank(ld.CPF__c)){
                cpfcnpj.add(ld.CPF__c.replaceAll('\\D',''));
            }else if(String.isNotBlank(ld.CNPJ__c)){
                cpfcnpj.add(ld.CNPJ__c.replaceAll('\\D',''));
            }
        }

        List<Lead> Leads = [SELECT Id, OwnerId FROM Lead WHERE CPFCNPJ__c IN :cpfcnpj];
       
        for(Lead ld: Leads){
            ownerIds.add(ld.OwnerId);
        }
        
        List<User> Users = [SELECT Id, Canal__c, Name FROM User WHERE Id IN :ownerIds];
        
       System.debug('cpfcnpj: ' + cpfcnpj); 
       System.debug('ownerIds: ' + ownerIds); 
        
        Map<Id, Lead> mapLead = new Map<Id, Lead>(Leads);
        Map<Id, User> mapUser = new Map<Id, User>(Users);
        
        System.debug('mapLead: ' + mapLead); 
        if(mapLead.isEmpty() == false){
            List<Lead> ld = Trigger.new;
            Integer index = 0;
            for(Id key : mapUser.keySet()) {
                User u = mapUser.get(key);
                string linebreak = '------------------------------------------------';
                string errMsg = 'Lead Duplicado. ' + linebreak + ' Proprietário da duplicata: ' + u.Name + ' // Canal: ' + u.Canal__c;
                ld[index].addError(errMsg, true);
                index++;
            }
        }
    }

    public override void beforeUpdate() {
        system.debug('2');
        LeadDomain.getInstance().setProprietarioOriginal((List<Lead>) Trigger.new);
    }

    public override void afterUpdate(){
        system.debug('3');
        LeadDomain.getInstance().sendRelationshipToAccount((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
    }
}