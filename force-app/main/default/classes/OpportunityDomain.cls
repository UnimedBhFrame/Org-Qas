public without sharing class OpportunityDomain {
    
    private static OpportunityDomain instance = null;
    
    public static OpportunityDomain getInstance() {
        if (instance == null) {
            instance = new OpportunityDomain();
        }
        
        return instance;
    }

    public void copyToDocId(List<Opportunity> oppts){
        for(Opportunity oppt : oppts){
            if(String.isNotBlank(oppt.CPF__c)){
                oppt.DocId__c = oppt.CPF__c.replaceAll('\\D', '');
            }else
            if(String.isNotBlank(oppt.CNPJ__c)){
                oppt.DocId__c = oppt.CNPJ__c.replaceAll('\\D', '');
            }
        }
    }
}