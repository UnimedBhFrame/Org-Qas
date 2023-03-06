global class VerificacaoJornadaBatch implements Database.Batchable<sObject> {
 
    private Map<Id, List<Id>> mapaIdUsuario = new Map<Id, List<Id>>();
    private Map<Id, String> mapMsg = new Map<Id, String>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT 
            Id,
            StartTime,
            EndTime,
            TimeSheetId,
            TimeSheet.ServiceResourceId,
            TimeSheet.ServiceResource.RelatedRecordId,
            TimeSheet.ServiceResource.RelatedRecord.Name,
            TimeSheet.ServiceResource.RelatedRecord.UserRoleId
            FROM 
            TimeSheetEntry 
            WHERE 
            EndTime = null
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<TimeSheetEntry> timeSheetEntries) {
        
        Map<Id, Id> mapTseRole = new Map<Id, Id>();
        for(TimeSheetEntry tse : timeSheetEntries){
            if(tse.TimeSheet.ServiceResource.RelatedRecord.UserRoleId != null){
                mapTseRole.put(tse.Id, tse.TimeSheet.ServiceResource.RelatedRecord.UserRoleId);
            }
        }

        Map<Id, Set<Id>> mapRoleAboveUsers = RoleUtils.getRoleUsers(new Set<Id>(mapTseRole.values()));

        for(TimeSheetEntry tse : timeSheetEntries){
            tse.EndTime = Datetime.now();
            tse.EncerradoSistema__c = true;

            mapaIdUsuario.put(tse.Id, new List<Id>{tse.TimeSheet.ServiceResource.RelatedRecordId});
            mapMsg.put(tse.Id, 'A jornada de trabalho do dia ' + tse.StartTime.format('dd/MM/YYYY') + ' do usuário ' + tse.TimeSheet.ServiceResource.RelatedRecord.Name + ' foi finalizada automaticamente!');
        
            if(tse.TimeSheet.ServiceResource.RelatedRecord.UserRoleId != null){
                mapaIdUsuario.get(tse.Id).addAll(new List<Id>(mapRoleAboveUsers.get(tse.TimeSheet.ServiceResource.RelatedRecord.UserRoleId)));
            }
        }

        update timeSheetEntries;


        PostChatter.PostForUsers(mapaIdUsuario, mapMsg, true);
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}