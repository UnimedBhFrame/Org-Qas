trigger MetaTrigger on Meta__c (before insert) {
    new MetaTriggerHandler().run();
}