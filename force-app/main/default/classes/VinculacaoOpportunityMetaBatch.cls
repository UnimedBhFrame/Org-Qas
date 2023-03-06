global class VinculacaoOpportunityMetaBatch implements Database.Batchable<sObject> {

    public static Map<Integer, String> myMap = new Map<Integer, String>{
        1 => 'Janeiro', 
        2 => 'Fevereiro', 
        3 => 'Março',
        4 => 'Abril', 
        5 => 'Maio', 
        6 => 'Junho',
        7 => 'Julho', 
        8 => 'Agosto', 
        9 => 'Setembro',
        10 => 'Outubro', 
        11 => 'Novembro', 
        12 => 'Dezembro'
    };

    // Exceção II
    private static final List<String> lojasExc1 = new List<String>{
        'BETIM',
        'SANTA LUZIA',
        'LAGOA SANTA',
        'PEDRO LEOPOLDO'
    };

    private static final String LOJA_INTERIOR_LOWER_CASE = 'interior';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT 
            Id,
            OwnerId,
            Owner.Name,
            CreatedDate,
            CompetenciaVigencia__c,
            Loja__c
            FROM
            Opportunity
            WHERE Meta__c = null AND CompetenciaVigencia__c != null
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> oppts) {

        Map<Id, String> mapOpptExternal = new Map<Id, String>();

        // Exceção II
        Map<Id, String> mapMovExternalLojaInteriorExc = new Map<Id, String>();

        //CompetenciaVigencia__c
        for(Opportunity oppt : oppts){
            Date onlyDate = oppt.CompetenciaVigencia__c;
            Datetime dt = Datetime.newInstance(onlyDate.year(), onlyDate.month(), onlyDate.day(), 0, 0, 0);
            
            if(oppt.OwnerId.getsObjectType().getDescribe().getName() == 'User'){
                String externalId = dt.format('YYYY') + getMonthBR(dt.month()) + oppt.OwnerId;
                mapOpptExternal.put(oppt.Id, externalId);
            }

            if(String.isNotBlank(oppt.Loja__c) && lojasExc1.contains(oppt.Loja__c)){
                String externalId = dt.format('YYYY') + getMonthBR(dt.month()) + LOJA_INTERIOR_LOWER_CASE;
                mapMovExternalLojaInteriorExc.put(oppt.Id, externalId);
            }
        }


        //System.debug(mapLeadMetaExternal);

        List<Meta__c> metas = [SELECT Id, IdExterno__c, Ano__c, Competencia__c, IDSupervisor__c, IDCoordenador__c, IDGerente__c FROM Meta__c WHERE IdExterno__c IN :mapOpptExternal.values()];

        Map<String, Meta__c> mapMetas = new Map<String, Meta__c>();
        for(Meta__c meta : metas){
            mapMetas.put(meta.IdExterno__c, meta);
        }

        //System.debug(mapMetas);

        List<Opportunity> opptsToUpdate = new List<Opportunity>();
        for(Id opptId : mapOpptExternal.keySet()){
            Opportunity opptToUpdate = new Opportunity(
                Id = opptId,
                Meta__c = mapMetas.get(mapOpptExternal.get(opptId))?.Id,
                IDSupervisor__c = mapMetas.get(mapOpptExternal.get(opptId))?.IDSupervisor__c,
                IDCoordenador__c = mapMetas.get(mapOpptExternal.get(opptId))?.IDCoordenador__c
            );

            opptsToUpdate.add(opptToUpdate);
        }

        TriggerHandler.bypass(OpportunityTriggerHandler.class);
        List<Database.SaveResult> SR = Database.update(opptsToUpdate, false);
        TriggerHandler.clearBypass(OpportunityTriggerHandler.class);


        //Supervisores, Coordenadores e Gerente
        try{
            Map<String, String> mapMetaWithSupervisor = new Map<String, String>();
            Map<String, String> mapMetaWithCoordenador = new Map<String, String>();
            Map<String, String> mapMetaWithGerente = new Map<String, String>();

            Set<String> mapExternals = new Set<String>();
            for(Meta__c meta : mapMetas.values()){
                String IdExternoSupervisor = meta.Ano__c + meta.Competencia__c + meta.IDSupervisor__c;
                String IdExternoCoordenador = meta.Ano__c + meta.Competencia__c + meta.IDCoordenador__c;
                String IdExternoGerente = meta.Ano__c + meta.Competencia__c + meta.IDGerente__c;

                mapMetaWithSupervisor.put(meta.IdExterno__c, IdExternoSupervisor);
                mapMetaWithCoordenador.put(meta.IdExterno__c, IdExternoCoordenador);
                mapMetaWithGerente.put(meta.IdExterno__c, IdExternoGerente);

                mapExternals.add(IdExternoSupervisor);
                mapExternals.add(IdExternoCoordenador);
                mapExternals.add(IdExternoGerente);
            }

            List<Meta__c> metasOthers = [SELECT Id, IdExterno__c, MetaDesafio__c FROM Meta__c WHERE IdExterno__c IN :mapExternals];
            
            Map<String, Meta__c> mapMetasOthers = new Map<String, Meta__c>();
            Map<String, Meta__c> mapMetasOthersDesafio = new Map<String, Meta__c>();
            for(Meta__c meta : metasOthers){
                if(meta.MetaDesafio__c){
                    mapMetasOthersDesafio.put(meta.IdExterno__c, meta);
                }else{
                    mapMetasOthers.put(meta.IdExterno__c, meta);
                }
            }

            opptsToUpdate = new List<Opportunity>();
            for(Id opptId : mapOpptExternal.keySet()){

                String IdExterno = mapMetas.get(mapOpptExternal.get(opptId))?.IdExterno__c;
                String IdExternoSupervisor = mapMetaWithSupervisor.get(IdExterno);
                String IdExternoCoordenador = mapMetaWithCoordenador.get(IdExterno);
                String IdExternoGerente = mapMetaWithGerente.get(IdExterno);

                Opportunity opptToUpdate = new Opportunity();
                opptToUpdate.Id = opptId;

                opptToUpdate.IDMetaSupervisor__c = mapMetasOthers.get(IdExternoSupervisor)?.Id;

                opptToUpdate.IDMetaCoordenador__c = mapMetasOthers.get(IdExternoCoordenador)?.Id;
                opptToUpdate.IDMetaCoordenadorDesafio__c = mapMetasOthersDesafio.get(IdExternoCoordenador)?.Id;

                opptToUpdate.IDMetaGerente__c = mapMetasOthers.get(IdExternoGerente)?.Id;
                opptToUpdate.IDMetaGerenteDesafio__c = mapMetasOthersDesafio.get(IdExternoGerente)?.Id;

                opptsToUpdate.add(opptToUpdate);
            }

            TriggerHandler.bypass(OpportunityTriggerHandler.class);
            List<Database.SaveResult> SR2 = Database.update(opptsToUpdate, false);
            TriggerHandler.clearBypass(OpportunityTriggerHandler.class);
        }catch(Exception e){
            System.debug(e.getMessage());
        }

        // Exceção II
        try{
            List<Meta__c> metasOthers = [SELECT Id, IdExternoLoja__c, MetaDesafio__c, Ano__c, Competencia__c, IDSupervisor__c, IDCoordenador__c, IDGerente__c FROM Meta__c WHERE IdExternoLoja__c IN :mapMovExternalLojaInteriorExc.values()];
        
            Map<String, Meta__c> mapMetasOthers = new Map<String, Meta__c>();
            for(Meta__c meta : metasOthers){
                mapMetasOthers.put(meta.IdExternoLoja__c, meta);
            }
    
            List<Opportunity> opptsToUpdate2 = new List<Opportunity>();
            for(Id opptId : mapMovExternalLojaInteriorExc.keySet()){
                Opportunity opptToUpdate2 = new Opportunity(
                    Id = opptId,
                    IDMetaSupervisor__c = mapMetasOthers.get(mapMovExternalLojaInteriorExc.get(opptId))?.Id
                );
    
                opptsToUpdate2.add(opptToUpdate2);
            }
    
            List<Database.SaveResult> SR2 = Database.update(opptsToUpdate2, false);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
    }

    global void finish(Database.BatchableContext BC) {
        
    }

    public static String getMonthBR(Integer numberS){
        return myMap.get(numberS);
    }
}