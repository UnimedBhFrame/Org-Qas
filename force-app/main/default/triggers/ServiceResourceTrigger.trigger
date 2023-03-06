trigger ServiceResourceTrigger on ServiceResource (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new ServiceResourceTriggerHandler().run();
}