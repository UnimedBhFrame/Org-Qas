public without sharing class ModalScheduleComponentController {

    @AuraEnabled
    public static Boolean verificaMostrarModal(String idLead) {

        Boolean mostrar = false;

        Lead ld = [SELECT CreatedDate, HouveAgendamento__c FROM Lead WHERE Id = :idLead];
        
        if (ld.HouveAgendamento__c == 'Sim') {

            Datetime dtCriacao = ld.CreatedDate;
            Datetime agora = System.now();
            Date hoje = agora.date();
            Date dataCriacao = dtCriacao.date();
            Long timeCriacao = dtCriacao.getTime();
            Long timeAgora = agora.getTime();
            Long diffSeg = (timeAgora - timeCriacao)/1000;
            
            if (diffSeg <= 30) {  //simula abrir o modal após criar um registro
                mostrar = true;
            }
        }

        return mostrar;
    }

    @AuraEnabled
    public static void preencheCampoModal(String idLead) {

        Lead lead = new Lead(Id = idLead);
        lead.AbriuModalAgendamento__c = true;
        update lead;
    }
}