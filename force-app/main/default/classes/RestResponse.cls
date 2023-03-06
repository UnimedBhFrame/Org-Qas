public class RestResponse implements ResponseParser {

    private Integer statusCode {get;set;}
    private String body {get;set;}
    public String errorMessage {get;set;}
    private Object serviceObject {get;set;}
    private Object errorObject {get;set;}
    private Object successObject {get;set;}

    public RestResponse () {} // construtor vazio para usos em testes

    public RestResponse (HttpResponse response, Type serializerClass, Type serializerClassError, Map<String, String> replacements) {
		System.debug('response');
		System.debug(response);
        this.statusCode = response.getStatusCode();
		System.debug('response.getBody()');
		System.debug(response.getBody());
        String responseBody = response.getBody();   
                      
		//verifica se o status está na faixa de 200-299 (Respostas de Sucesso)        
        if ((response.getStatusCode()/100) != 2) {
            try{
                this.errorMessage = responseBody;
                if (serializerClassError != null) {
                    this.errorObject = JSON.deserialize(errorMessage, serializerClassError);
                } 
            } catch (Exception ex){
                this.errorMessage = 'ERROR '+this.statusCode;
            }
        } else {
            this.body = responseBody;
            if (serializerClass != null && this.body != '' && this.body != 'ERROR') {
                this.serviceObject = JSON.deserialize(body, serializerClass);
            }
        }
    }
        
    public Integer getStatusCode () {
        return this.statusCode;
    }
    
    public String getBody () {
        return this.body;
    }

    public String getErrorMessage () {
        return this.errorMessage;
    }

    public Object getServiceObject () {
        return this.serviceObject;
    }
    
    public Object getErrorObject () {
        return this.errorObject;
    }
    
    public Object getSuccessObject () {
        return this.successObject;
    }
}