public class TempoMedio {
    
    DocumentosProposta__c proposta = [SELECT id, Tempo_emiss_o_proposta__c, FORMAT(CreatedDate),FORMAT(Cotacoes__r.CreatedDate),Dias__c from DocumentosProposta__c LIMIT 5];
    Cotacoes__c cotacao = [select id,name,format(CreatedDate)from Cotacoes__c LIMIT 5];
	
    DateTime propostadata = Date.valueOf(proposta.CreatedDate); 
    DateTime CotacaoData = Date.valueOf(cotacao.CreatedDate);
    integer Days = Integer.valueOf((CotacaoData.getTime() - propostadata.getTime())/(1000*60*60*24));
    
    
    //somar todos os minutos e dividir pelos dias
    //por exe soma todos os tempo emissão proposta e divide pelo campo tempo emissao proposta
    
}