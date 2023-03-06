public without sharing class MetaTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(){
        setUser((List<Meta__c>) Trigger.new);
    }

    public void setUser(List<Meta__c> metas){
        Map<String, List<Meta__c>> mapEmailMeta = new  Map<String, List<Meta__c>>();

        for(Meta__c meta: metas){
            if(meta.Email__c != null){
                if(!mapEmailMeta.containsKey(meta.Email__c)){
                    mapEmailMeta.put(meta.Email__c, new List<Meta__c>());
                }
                mapEmailMeta.get(meta.Email__c).add(meta);
            }
        }

        List<User> users = [SELECT Id, Email FROM User WHERE Email IN : mapEmailMeta.keySet()];

        for(User u : users){
            if(mapEmailMeta.containsKey(u.Email)){
                for(Meta__c meta : mapEmailMeta.get(u.Email)){
                    meta.OwnerId = u.Id;
                    meta.Usuario__c = u.Id;
                }
            }
        }
    }
}