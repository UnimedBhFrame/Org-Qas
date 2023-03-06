global without sharing class MovimentacaoUpdateBatch implements Database.Batchable<SObject> {
    // construtor da classe com controle de paginação
    public MovimentacaoUpdateBatch() {
    }

    // lsita o escopo de trabalho (movimentações) da classe batch
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, Lead__c, CPFCNPJ__c, CPFTitular__c
                FROM Movimentacao__c WHERE CPFCNPJ__c != null
                /*WHERE Lead__c = NULL AND CPFCNPJ__c != NULL*/
            ]
        );
    }

    // executa as regras da classe batch
    global void execute(Database.BatchableContext bc, List<Movimentacao__c> scope) {
        // monta o mapa das movimentações com o número de documento
        Map<String, List<Movimentacao__c>> scopeMap = getScopeMap(scope);

        // monta o mapa dos leads com o número de documento
        Map<String, Lead> leadMap = getLeadMap(scopeMap.keyset());

        // itera para encontrar o lead para a movimentação
        List<Movimentacao__c> recordsToUpdate = new List<Movimentacao__c>();
        for (String document : scopeMap.keyset()) {
            if (leadMap.containsKey(document)) {
                for(Movimentacao__c movCurrent : scopeMap.get(document)){

                    Movimentacao__c movimentacaoRecord = movCurrent;
                    movimentacaoRecord.Lead__c = leadMap.get(document).Id;
                    recordsToUpdate.add(movimentacaoRecord);

                }
            }
        }

        // se possui movimentação ajustada, atualiza no banco de dados
        if (!recordsToUpdate.isEmpty()) {
            Database.update(recordsToUpdate, true);
        }
    }

    // executa assim que a classe é finalizada
    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'finish execution of MovimentacaoUpdateBatch');
    }

    // gera o mapa das movimentações com o número de documento
    private Map<String, List<Movimentacao__c>> getScopeMap(List<Movimentacao__c> scope) {
        Map<String, List<Movimentacao__c>> scopeMap = new Map<String, List<Movimentacao__c>>();
        for (Movimentacao__c movimentacaoRecord : scope) {
            // if (
            //     movimentacaoRecord.CPFCNPJ__c.length() == 14 &&
            //     movimentacaoRecord.CPFTitular__c != null &&
            //     movimentacaoRecord.CPFTitular__c.length() == 11
            // ) {
            //     scopeMap.put(
            //         documentFormatter(movimentacaoRecord.CPFTitular__c),
            //         movimentacaoRecord
            //     );
            // } else {
            //     scopeMap.put(documentFormatter(movimentacaoRecord.CPFCNPJ__c), movimentacaoRecord);
            // }

            if(String.isNotBlank(movimentacaoRecord.CPFCNPJ__c)){
                String documentFormatted = documentFormatter(movimentacaoRecord.CPFCNPJ__c);

                if(!scopeMap.containsKey(documentFormatted)){
                    scopeMap.put(documentFormatted, new List<Movimentacao__c>());
                }
                scopeMap.get(documentFormatted).add(movimentacaoRecord);
                
                // if(String.isNotBlank(movimentacaoRecord.CPFTitular__c) && scopeMap.containsKey(documentFormatter(movimentacaoRecord.CPFTitular__c))){
                //     scopeMap.remove(documentFormatter(movimentacaoRecord.CPFTitular__c));
                // }
            }
        }
        return scopeMap;
    }

    // gera o mapa dos leads com o número de documento
    private Map<String, Lead> getLeadMap(Set<String> documents) {
        Map<String, Lead> leadsMap = new Map<String, Lead>();

        Database.QueryLocator queryLocator = Database.getQueryLocator(
            [
                SELECT id, CPF__c, CNPJ__c
                FROM Lead
                WHERE CPF__c IN :documents OR CNPJ__c IN :documents
            ]
        );

        Database.QueryLocatorIterator iterator = queryLocator.iterator();

        while (iterator.hasNext()) {
            Lead leadRecord = (Lead) iterator.next();
            if (leadRecord.CPF__c != null) {
                leadsMap.put(leadRecord.CPF__c, leadRecord);
            } else {
                leadsMap.put(leadRecord.CNPJ__c, leadRecord);
            }
        }

        return leadsMap;
    }

    // aplica a formatação do CPF ou CNPJ
    private string documentFormatter(string document) {
        if (document.length() == 14) {
            return String.format(
                '{0}.{1}.{2}/{3}-{4}',
                new List<String>{
                    document.substring(0, 2),
                    document.substring(2, 5),
                    document.substring(5, 8),
                    document.substring(8, 12),
                    document.substring(12)
                }
            );
        } else {
            return String.format(
                '{0}.{1}.{2}-{3}',
                new List<String>{
                    document.substring(0, 3),
                    document.substring(3, 6),
                    document.substring(6, 9),
                    document.substring(9)
                }
            );
        }
    }
}