public class CustomMetadataCallback implements Metadata.DeployCallback {
    public void handleResult(Metadata.DeployResult result,
                             Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug('success: '+ result);
        } else {
            // Deployment was not successful
            System.debug('fail: '+ result);
        }
    }
    
    @future
    public static void createUpdateMetadata(String fullName, String label, String field, Integer value){
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        customMetadata.fullName = fullName;
        customMetadata.label = label;
        
        
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
        customField.field = field;
        customField.value = value; 
        customMetadata.values.add(customField);
        
        System.debug('value metadata'+value);
        
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        CustomMetadataCallback callback = new CustomMetadataCallback();

        if(!Test.isRunningTest()){
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
            System.debug('jobId'+jobId);
        }
    } 
}