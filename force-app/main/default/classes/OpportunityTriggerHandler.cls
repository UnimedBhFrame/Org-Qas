public without sharing class OpportunityTriggerHandler extends TriggerHandler{

    public override void beforeInsert(){
        OpportunityDomain.getInstance().copyToDocId((List<Opportunity>) Trigger.new);
    }

    public override void beforeUpdate() {
        OpportunityDomain.getInstance().copyToDocId((List<Opportunity>) Trigger.new);
        checkStageNameNull((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    //Verificação para integração
    public void checkStageNameNull(List<Opportunity> oppts, Map<Id, Opportunity> mapOppt){

        for(Opportunity oppt : oppts){
            if(String.isBlank(oppt.StageName) && String.isNotBlank(mapOppt.get(oppt.Id).StageName)){
                oppt.StageName = mapOppt.get(oppt.Id).StageName;
            }
        }
    }
}