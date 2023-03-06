trigger ServiceReportTrigger on ServiceReport (after insert) {
    new ServiceReportTriggerHandler().run();
}