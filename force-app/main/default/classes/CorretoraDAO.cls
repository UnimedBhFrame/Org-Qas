public with sharing class CorretoraDAO {
    public static Corretora__c getById(Id id) {
        Corretora__c corretora = [SELECT Id, 
        CelularContato__c, 
        CNPJ__c,
        DataDeAberturaDaCorretora__c,
        DiaAniversarioCorretora__c,
        DiasFaltantesAniversario__c,
        EmailContato__c,
        Endereco__c,
        EnderecoBairro__c,
        EnderecoCep__c,
        EnderecoCidade__c,
        EnderecoComplemento__c,
        EnderecoEstado__c,
        EnderecoLocalizacao__c,
        EnderecoNumero__c,
        EnderecoPais__c,
        EnderecoRua__c,
        MesAniversarioCorretora__c,
        Name,
        NomeContato__c,
        OwnerId,
        ProximoAniversarioCorretora__c,
        SobrenomeContato__c,
        TelefoneContato__c
        FROM Corretora__c WHERE Id =:id];

        return corretora;
    }
}