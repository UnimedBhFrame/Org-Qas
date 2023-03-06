public without sharing class RastreioAcessoController {


    @AuraEnabled
    public static void salvarLog(String idRegistro) {
        
        Id id = Id.valueOf(idRegistro);
        String nomeApiObjeto = id.getSObjectType().getDescribe().getName();
        String nomeObjeto = id.getSObjectType().getDescribe().getLabel();
        
        LogAcesso__c log = new LogAcesso__c();
        log.IdRegistro__c = idRegistro;
        log.ObjetoAPI__c = nomeApiObjeto;
        log.Objeto__c = nomeObjeto;
        insert log;
    }

    @AuraEnabled
    public static void salvarLogUtility(String identificador, String objeto, Boolean registro) {
        
        Id idRegistro = registro ? Id.valueOf(identificador) : null;
        String nomeApiObjeto = registro ? idRegistro.getSObjectType().getDescribe().getName() : '';
        String nomeObjeto = registro ? idRegistro.getSObjectType().getDescribe().getLabel() : objeto;
                
        LogAcesso__c log = new LogAcesso__c();
        log.IdRegistro__c = identificador;
        log.ObjetoAPI__c = nomeApiObjeto;
        log.Objeto__c = nomeObjeto;
        insert log;
    }
}