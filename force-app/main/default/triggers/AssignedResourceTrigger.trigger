trigger AssignedResourceTrigger on AssignedResource (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new AssignedResourceTriggerHandler().run();
}