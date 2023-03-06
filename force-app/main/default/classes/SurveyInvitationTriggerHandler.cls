public without sharing class SurveyInvitationTriggerHandler extends TriggerHandler{
	public override void beforeInsert() {
        relacionarLeadId((List<SurveyInvitation>) Trigger.new);
    }
    
    public void relacionarLeadId(List<SurveyInvitation> sInvs){
        for(SurveyInvitation sInv : sInvs){
            if(String.isNotBlank(sInv.ParticipantId) && sInv.ParticipantId.getsObjectType().getDescribe().getName() == 'Lead'){
                sInv.Lead__c = sInv.ParticipantId;
                sInv.Name = 'Pesquisa - ' + Datetime.now().format('dd/MM/YYYY HH:mm:ss');
            }
        }
    }
}