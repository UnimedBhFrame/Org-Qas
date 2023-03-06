public without sharing class ExcluiLogsAcessoBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Integer recordsProcessed = 0;
    public Date dataLimite;

    public ExcluiLogsAcessoBatch(Date dataLimite) {

        this.dataLimite = dataLimite;
    }
        
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        return Database.getQueryLocator('SELECT Id FROM LogAcesso__c WHERE CreatedDate < :dataLimite');
    }
    
    public void execute(Database.BatchableContext bc, List<LogAcesso__c> logs) {
        
        List<Database.DeleteResult> results = Database.delete(logs, false);
        for(Database.DeleteResult dr : results) {
            if (dr.isSuccess()) {
                recordsProcessed += 1;
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
       
        System.debug('Registros deletados: ' + recordsProcessed);
    }
}