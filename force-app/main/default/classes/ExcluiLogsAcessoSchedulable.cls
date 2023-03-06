global without sharing class ExcluiLogsAcessoSchedulable implements Schedulable {

    global void execute(SchedulableContext ctx) {
        
        Date hoje = System.today();
        ConfigLogsAcesso__mdt config = [SELECT MesesManterHistorico__c FROM ConfigLogsAcesso__mdt LIMIT 1];
        Integer meses = config != null && config.MesesManterHistorico__c != null ? Integer.valueOf(config.MesesManterHistorico__c) : 12;
        meses = -meses;
		Date dataLimite = hoje.addMonths(meses);
        
        ExcluiLogsAcessoBatch elab = new ExcluiLogsAcessoBatch(dataLimite);
        Id batchId = Database.executeBatch(elab);
    }
}