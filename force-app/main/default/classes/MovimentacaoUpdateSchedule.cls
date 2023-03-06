global class MovimentacaoUpdateSchedule implements Schedulable {
    global void execute(SchedulableContext context) {
        Database.executeBatch(new MovimentacaoUpdateBatch(), 200);
    }
}