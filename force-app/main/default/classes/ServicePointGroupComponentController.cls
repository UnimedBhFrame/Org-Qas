public with sharing class ServicePointGroupComponentController {
    
    //TO DO fazer classe de TEST

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAbsenceType(){
        Map<String, String> options = new Map<String, String>();
    
        Schema.DescribeFieldResult fieldResult = ResourceAbsence.Type.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                
        for( Schema.PicklistEntry f : ple)
        {
            options.put(f.getLabel(), f.getValue());
        }       
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<ResourceAbsence> getResourceAbsence(Id targetId){
        List<ResourceAbsence> lra;
        String resourceId;
        if(targetId.getsobjecttype().getDescribe().getName().equals('MembroDistribuicaoVisita__c')){
            MembroDistribuicaoVisita__c mgp = [Select Id, ServiceResource__c from MembroDistribuicaoVisita__c Where Id =: targetId];
            resourceId = mgp.ServiceResource__c;
            if(resourceId != null){
                lra = [SELECT Id, Type, Start, End from ResourceAbsence Where ResourceId =: resourceId AND Start >=: Datetime.now() LIMIT 5];
            }
        } else if(targetId.getsobjecttype().getDescribe().getName().equals('DistribuicaoVisita__c')){
            lra = null;
        }

        return lra;
    }

    @AuraEnabled
    public static String saveAbscences(Id targetId, String absReason, Datetime startTime, Datetime endTime, String description){
        String message;
        if(targetId.getsobjecttype().getDescribe().getName().equals('DistribuicaoVisita__c')){
            List<MembroDistribuicaoVisita__c> lmgp = [SELECT Id, ServiceResource__c from MembroDistribuicaoVisita__c Where DistribuicaoVisita__c =: targetId];
            System.debug('lmgp'+lmgp);
            if (!lmgp.isEmpty()) {
                for (MembroDistribuicaoVisita__c mgp : lmgp) {
                    message = saveSingleAbscence(mgp.ServiceResource__c, absReason, startTime, endTime, description);
                }
            } else {
                message = 'ERRO: Sem Corretor Cadastrado';
            }
        } else if(targetId.getsobjecttype().getDescribe().getName().equals('MembroDistribuicaoVisita__c')){
            String resourceId = [SELECT ServiceResource__c from MembroDistribuicaoVisita__c targetId Where Id =: targetId].ServiceResource__c;
            message = saveSingleAbscence(resourceId, absReason, startTime, endTime, description);
        } else {
            message = 'ERRO';
        }
        System.debug('message'+message);
        return message;
    }

    public static String saveSingleAbscence(Id targetId, String absReason, Datetime startTime, Datetime endTime, String description){
        String message;
        ResourceAbsence ra = new ResourceAbsence();
        ra.Type = absReason;
        ra.Start = startTime;
        ra.End = endTime;
        ra.ResourceId = targetId;
        ra.Description = description;
        try {
            insert ra;
            message = 'Sucesso';
        } catch (Exception e) {
            message = 'ERRO: ' + e.getMessage();
        }

        return message;

    }


    
}