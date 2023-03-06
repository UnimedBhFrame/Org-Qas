@isTest
private class CustomMetadataCallbackTest {

    @isTest static void handleResult() {
        CustomMetadataCallback customMetadataCallback = new CustomMetadataCallback();

        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;

        Metadata.DeployResult result2 = new Metadata.DeployResult();
        result2.status = Metadata.DeployStatus.Failed;

        Test.startTest();
        customMetadataCallback.handleResult(result, null);
        customMetadataCallback.handleResult(result2, null);
        Test.stopTest();
    }

    @isTest static void createUpdateMetadata(){
        Test.startTest();
        CustomMetadataCallback.createUpdateMetadata('AgendamentoDistribuicao__mdt.LojaAutorizada', 'Loja autorizada', 'QuantidadeAtual__c', 0); 
        Test.stopTest();
    }
}