global class VinculacaoMovimentacaoMetaBatch implements Database.Batchable<sObject>{
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

    private static final List<String> lojas = new List<String>{
        'PLANOMED',
        'BH',
        'BETIM',
        'SANTA LUZIA',
        'LAGOA SANTA',
        'SANTA BARBARA',
        'PEDRO LEOPOLDO',
        'PLANOVENDAS',
        'SALUTIA',
        'UNISAUDE'
    };

    // Exceção I
    private static final List<String> canaisExc1 = new List<String>{
        'E-COMMERCE'
    };

    private static final List<String> canaisExc2 = new List<String>{
        'SINDLOJAS',
        'ADMINISTRADORAS'
    };

    // Exceção II
    private static final List<String> canaisExc3 = new List<String>{
        'LOJAS AUTORIZADAS',
        'LOJAS PRÓPRIAS'
    };

    private static final List<String> lojasExc1 = new List<String>{
        'BETIM',
        'SANTA LUZIA',
        'LAGOA SANTA',
        'PEDRO LEOPOLDO'
    };

    static private final String CARGO_GERENTE_LOWER_CASE = 'gerente';
    private static final String LOJA_INTERIOR_LOWER_CASE = 'interior';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [SELECT 
            Id,
            OwnerId,
            Owner.Name,
            CreatedDate,
            Competencia__c,
            NomeIndividuo__c,
            NomeVendedor__c,
            Loja__c,
            Canal__c
            FROM
            Movimentacao__c
            WHERE Meta__c = null 
            AND IDSupervisor__c = null
            AND IDMetaCoordenador__c = null 
            AND IDMetaCoordenadorDesafio__c = null
            AND IDMetaGerente__c = null 
            AND IDMetaGerenteDesafio__c = null
            AND NomeVendedor__c != null
            // WHERE (Meta__c = null OR CreatedDate >= :Datetime.now().addDays(-1)) AND NomeVendedor__c != null
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<Movimentacao__c> movs) {

        Map<Id, String> mapMovExternal = new Map<Id, String>();
        Map<Id, String> mapMovExternalLoja = new Map<Id, String>();

        // Exceção I
        Map<Id, String> mapMovExternalCanalExc1 = new Map<Id, String>();
        Map<Id, String> mapMovExternalCanalExc2 = new Map<Id, String>();


        // Exceção II
        Map<Id, String> mapMovExternalCanalExcCoord = new Map<Id, String>();
        Map<Id, String> mapMovExternalLojaInteriorExc = new Map<Id, String>();

        for(Movimentacao__c mov : movs){
            Date onlyDate = mov.Competencia__c;
            Datetime dt = Datetime.newInstance(onlyDate.year(), onlyDate.month(), onlyDate.day(), 0, 0, 0);

            if(mov.OwnerId.getsObjectType().getDescribe().getName() == 'User'){
                String externalId = dt.format('YYYY') + getMonthBR(dt.month()) + mov.NomeVendedor__c.replace(' ','').toLowerCase();
                mapMovExternal.put(mov.Id, externalId);
            }

            if(String.isNotBlank(mov.Loja__c) && lojas.contains(mov.Loja__c)){
                String externalId = dt.format('YYYY') + getMonthBR(dt.month()) + mov.Loja__c.replace(' ','').toLowerCase();
                mapMovExternalLoja.put(mov.Id, externalId);
            }

            // Exceção I

            if(String.isNotBlank(mov.Canal__c) && canaisExc1.contains(mov.Canal__c)){
                String externalId = dt.format('YYYY') + getMonthBR(dt.month()) + mov.Canal__c.replace(' ','').toLowerCase();
                mapMovExternalCanalExc1.put(mov.Id, externalId);
            }

            if(String.isNotBlank(mov.Canal__c) && canaisExc2.contains(mov.Canal__c)){      
                String externalId = dt.format('YYYY') + getMonthBR(dt.month()) + CARGO_GERENTE_LOWER_CASE;
                mapMovExternalCanalExc2.put(mov.Id, externalId);
            }


            // Exceção II
            if(String.isNotBlank(mov.Canal__c) && canaisExc3.contains(mov.Canal__c)){
                String externalId = dt.format('YYYY') + getMonthBR(dt.month()) + mov.Canal__c.replace(' ','').toLowerCase();
                mapMovExternalCanalExcCoord.put(mov.Id, externalId);
            }

            if(String.isNotBlank(mov.Loja__c) && lojasExc1.contains(mov.Loja__c)){
                String externalId = dt.format('YYYY') + getMonthBR(dt.month()) + LOJA_INTERIOR_LOWER_CASE;
                mapMovExternalLojaInteriorExc.put(mov.Id, externalId);
            }

        }

        List<Meta__c> metas = [SELECT Id, IdExternoMovimentacao__c, Ano__c, Competencia__c, IDSupervisor__c, IDCoordenador__c, IDGerente__c FROM Meta__c WHERE IdExternoMovimentacao__c IN :mapMovExternal.values()];
        
        Map<String, Meta__c> mapMetas = new Map<String, Meta__c>();
        for(Meta__c meta : metas){
            mapMetas.put(meta.IdExternoMovimentacao__c, meta);
        }

        // Loja__c de Movimentação tem que ser comparado no Cargo__c de Meta, afim de garantir o vinculos somente daquele loja especifica
        // List<Meta__c> metasLoja = [SELECT Id, IdExternoLoja__c FROM Meta__c WHERE IdExternoLoja__c IN :mapMovExternalLoja.values()];
        List<Meta__c> metasLoja = [SELECT Id, IdExternoCargo__c, IdExternoLoja__c FROM Meta__c WHERE IdExternoCargo__c IN :mapMovExternalLoja.values()];
        Map<String, Meta__c> mapMetasLojas = new Map<String, Meta__c>();
        for(Meta__c meta : metasLoja){
            // mapMetasLojas.put(meta.IdExternoLoja__c, meta);
             mapMetasLojas.put(meta.IdExternoCargo__c, meta);
        }

        List<Movimentacao__c> movsToUpdate = new List<Movimentacao__c>();
        for(Id movId : mapMovExternal.keySet()){
            Movimentacao__c movToUpdate = new Movimentacao__c(
                Id = movId,
                Meta__c = mapMetas.get(mapMovExternal.get(movId))?.Id,
                IdMetaLoja__c = mapMetasLojas.get(mapMovExternalLoja.get(movId))?.Id
            );

            movsToUpdate.add(movToUpdate);
        }

        List<Database.SaveResult> SR = Database.update(movsToUpdate, false);

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

                mapMetaWithSupervisor.put(meta.IdExternoMovimentacao__c, IdExternoSupervisor);
                mapMetaWithCoordenador.put(meta.IdExternoMovimentacao__c, IdExternoCoordenador);
                mapMetaWithGerente.put(meta.IdExternoMovimentacao__c, IdExternoGerente);

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

            movsToUpdate = new List<Movimentacao__c>();
            for(Id movId : mapMovExternal.keySet()){

                String IdExternoMovimentacao = mapMetas.get(mapMovExternal.get(movId))?.IdExternoMovimentacao__c;

                String IdExternoSupervisor = mapMetaWithSupervisor.get(IdExternoMovimentacao);
                String IdExternoCoordenador = mapMetaWithCoordenador.get(IdExternoMovimentacao);
                String IdExternoGerente = mapMetaWithGerente.get(IdExternoMovimentacao);

                Movimentacao__c movToUpdate = new Movimentacao__c();
                movToUpdate.Id = movId;

                movToUpdate.IDSupervisor__c = mapMetasOthers.get(IdExternoSupervisor)?.Id;

                movToUpdate.IDMetaCoordenador__c = mapMetasOthers.get(IdExternoCoordenador)?.Id;
                movToUpdate.IDMetaCoordenadorDesafio__c = mapMetasOthersDesafio.get(IdExternoCoordenador)?.Id;

                movToUpdate.IDMetaGerente__c = mapMetasOthers.get(IdExternoGerente)?.Id;
                movToUpdate.IDMetaGerenteDesafio__c = mapMetasOthersDesafio.get(IdExternoGerente)?.Id;

                movsToUpdate.add(movToUpdate);
            }

            List<Database.SaveResult> SR2 = Database.update(movsToUpdate, false);
            
        }catch(Exception e){
            System.debug(e.getMessage());
        }


        // Exceção I
        try{
            List<Meta__c> metasCanal = [SELECT Id, IdExternoCanal__c, Ano__c, Competencia__c, IDGerente__c FROM Meta__c WHERE IdExternoCanal__c IN :mapMovExternalCanalExc1.values()];
            Map<String, Meta__c> mapMetasCanal = new Map<String, Meta__c>();
            for(Meta__c meta : metasCanal){
                mapMetasCanal.put(meta.IdExternoCanal__c, meta);
            }

            Map<String, String> mapMetaWithGerente = new Map<String, String>();

            Set<String> mapExternals = new Set<String>();
            for(Meta__c meta : mapMetasCanal.values()){
                String IdExternoGerente = meta.Ano__c + meta.Competencia__c + meta.IDGerente__c;

                mapMetaWithGerente.put(meta.IdExternoCanal__c, IdExternoGerente);
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

            movsToUpdate = new List<Movimentacao__c>();
            for(Id movId : mapMovExternalCanalExc1.keySet()){

                Id metaId = mapMetasCanal.get(mapMovExternalCanalExc1.get(movId))?.Id;
                String IdExternoCanal = mapMetasCanal.get(mapMovExternalCanalExc1.get(movId))?.IdExternoCanal__c;

                String IdExternoGerente = mapMetaWithGerente.get(IdExternoCanal);

                Movimentacao__c movToUpdate = new Movimentacao__c();
                movToUpdate.Id = movId;

                //movToUpdate.IDSupervisor__c = mapMetasOthers.get(IdExternoSupervisor)?.Id;

                movToUpdate.IDMetaCoordenador__c = metaId;
                //movToUpdate.IDMetaCoordenadorDesafio__c = mapMetasOthersDesafio.get(IdExternoCoordenador)?.Id;

                movToUpdate.IDMetaGerente__c = mapMetasOthers.get(IdExternoGerente)?.Id;
                movToUpdate.IDMetaGerenteDesafio__c = mapMetasOthersDesafio.get(IdExternoGerente)?.Id;

                movsToUpdate.add(movToUpdate);
            }

            List<Database.SaveResult> SR2 = Database.update(movsToUpdate, false);

        }catch(Exception e){
            System.debug(e.getMessage());
        }


        try{
            List<Meta__c> metasOthers = [SELECT Id, IdExternoCargo__c, MetaDesafio__c, Ano__c, Competencia__c, IDSupervisor__c, IDCoordenador__c, IDGerente__c FROM Meta__c WHERE IdExternoCargo__c IN :mapMovExternalCanalExc2.values()];
        
            Map<String, Meta__c> mapMetasOthers = new Map<String, Meta__c>();
            Map<String, Meta__c> mapMetasOthersDesafio = new Map<String, Meta__c>();
            for(Meta__c meta : metasOthers){
                if(meta.MetaDesafio__c){
                    mapMetasOthersDesafio.put(meta.IdExternoCargo__c, meta);
                }else{
                    mapMetasOthers.put(meta.IdExternoCargo__c, meta);
                }
            }
    
            List<Movimentacao__c> movsToUpdate2 = new List<Movimentacao__c>();
            for(Id movId : mapMovExternalCanalExc2.keySet()){
                Movimentacao__c movToUpdate = new Movimentacao__c(
                    Id = movId,
                    IDMetaGerente__c = mapMetasOthers.get(mapMovExternalCanalExc2.get(movId))?.Id,
                    IDMetaGerenteDesafio__c = mapMetasOthersDesafio.get(mapMovExternalCanalExc2.get(movId))?.Id
                );
    
                movsToUpdate2.add(movToUpdate);
            }
    
            List<Database.SaveResult> SR2 = Database.update(movsToUpdate2, false);
        }catch(Exception e){
            System.debug(e.getMessage());
        }


        // Exceção II
        try{
            List<Meta__c> metasOthers = [SELECT Id, IdExternoCargo__c, MetaDesafio__c, Ano__c, Competencia__c, IDSupervisor__c, IDCoordenador__c, IDGerente__c FROM Meta__c WHERE IdExternoCanal__c IN :mapMovExternalCanalExcCoord.values()];
        
            Map<String, Meta__c> mapMetasOthers = new Map<String, Meta__c>();
            Map<String, Meta__c> mapMetasOthersDesafio = new Map<String, Meta__c>();
            for(Meta__c meta : metasOthers){
                if(meta.MetaDesafio__c){
                    mapMetasOthersDesafio.put(meta.IdExternoCargo__c, meta);
                }else{
                    mapMetasOthers.put(meta.IdExternoCargo__c, meta);
                }
            }
    
            List<Movimentacao__c> movsToUpdate2 = new List<Movimentacao__c>();
            for(Id movId : mapMovExternalCanalExcCoord.keySet()){
                Movimentacao__c movToUpdate = new Movimentacao__c(
                    Id = movId,
                    IDMetaCoordenador__c = mapMetasOthers.get(mapMovExternalCanalExcCoord.get(movId))?.Id,
                    IDMetaCoordenadorDesafio__c = mapMetasOthersDesafio.get(mapMovExternalCanalExcCoord.get(movId))?.Id
                );
    
                movsToUpdate2.add(movToUpdate);
            }
    
            List<Database.SaveResult> SR2 = Database.update(movsToUpdate2, false);
        }catch(Exception e){
            System.debug(e.getMessage());
        }

        try{
            List<Meta__c> metasOthers = [SELECT Id, IdExternoLoja__c, MetaDesafio__c, Ano__c, Competencia__c, IDSupervisor__c, IDCoordenador__c, IDGerente__c FROM Meta__c WHERE IdExternoLoja__c IN :mapMovExternalLojaInteriorExc.values()];
        
            Map<String, Meta__c> mapMetasOthers = new Map<String, Meta__c>();
            for(Meta__c meta : metasOthers){
                mapMetasOthers.put(meta.IdExternoLoja__c, meta);
            }
    
            List<Movimentacao__c> movsToUpdate2 = new List<Movimentacao__c>();
            for(Id movId : mapMovExternalLojaInteriorExc.keySet()){
                Movimentacao__c movToUpdate = new Movimentacao__c(
                    Id = movId,
                    IDSupervisor__c = mapMetasOthers.get(mapMovExternalLojaInteriorExc.get(movId))?.Id
                );
    
                movsToUpdate2.add(movToUpdate);
            }
    
            List<Database.SaveResult> SR2 = Database.update(movsToUpdate2, false);
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