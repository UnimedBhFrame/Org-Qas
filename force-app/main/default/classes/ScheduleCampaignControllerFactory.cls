@isTest
public class ScheduleCampaignControllerFactory {
        
    public static AgendamentoDistribuicao__mdt createMeta(){
        AgendamentoDistribuicao__mdt ad = new AgendamentoDistribuicao__mdt();
        ad.QuantidadeAtual__c = 10;
        ad.QuantidadePermitida__c = 10;
        ad.Label = 'Loja autorizada';
        return ad;
    }
    
    public static PeriodoCompetencia__mdt createMetaPeriodo(){
        PeriodoCompetencia__mdt pc = new PeriodoCompetencia__mdt();
        pc.DataUltimaCompetencia__c = Date.today();
        pc.DiasSucessores__c = 2;
        pc.Label = 'Periodo Teste';
        return pc;
    }
}