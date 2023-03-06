@isTest
public without sharing class ExcluiLogsAcessoBatchTest {
    
    @testSetup
    public static void setup() {
        
        LogAcesso__c log = new LogAcesso__c();
        log.IdRegistro__c = 'idTeste';
        log.ObjetoAPI__c = 'objeto';
        log.Objeto__c = 'objeto';
        insert log;
    }
    
    @isTest 
    public static void testarBatch() {
        
        Date hoje = System.today();
		Date dataLimite = hoje.addMonths(1);
        
        Test.startTest();
        ExcluiLogsAcessoBatch elab = new ExcluiLogsAcessoBatch(dataLimite);
        Id batchId = Database.executeBatch(elab);
        Test.stopTest();
        
        List<LogAcesso__c> logs = new List<LogAcesso__c>();
        logs = [SELECT Id FROM LogAcesso__c];
        System.assertEquals(0, logs.size());
    }
}