public virtual class IntegracaoRest {
    public HttpResponse execute (
        String method, 
        String apiMethod, 
        String endpoint, 
        String body, 
        Boolean compressed,
        Map<String, 
        String> headers
    ) {
        if (
            String.isEmpty(method) || 
            String.isEmpty(endpoint) ||
            (method!= 'GET' && String.isEmpty(body)) ||
            compressed == null ||
            headers == null
        ) {            
            String mensagemErro = 'Os parâmetros informados estão com valor nulo. [' +
                String.format('{0}, {1}, {2}, {3}, {4}', new List<String>{
                    'endpoint: ' + endpoint+'',
                        'method: ' + method+'',
                        'body: ' + body+'',
                        'compressed: ' + compressed+'',
                        'headers: ' + headers+''
                        }) + ']';
            
            System.debug(LoggingLevel.ERROR, mensagemErro); 
            
            throw new IntegracaoRestException('Os parâmetros informados na requisição estão com valor nulo.');
        }
        HttpRequest request;
        HttpResponse response;
        
        
            request = createRequest(method, apiMethod, endpoint, body, compressed, headers);
            
            String mensagemErro = 'Parametros: [' +
                String.format('{0}, {1}, {2}, {3}, {4}', new List<String>{
                    'endpoint: ' + endpoint+'',
                        'method: ' + method+'',
                        'body: ' + body+'',
                        'compressed: ' + compressed+'',
                        'headers: ' + headers+''
                        }) + ']';
			System.debug(LoggingLevel.DEBUG, mensagemErro);
            System.debug(LoggingLevel.DEBUG, 'apiMethod:' + apiMethod);
            System.debug(request);
            System.debug(body);
            Http sender1 = new Http();            
            response = sender1.send(request);
            System.debug('response!!: ' + response);
       
        if (response.getStatusCode() == 401) {
            try {
                Http sender = new Http();
                HttpResponse response2 = sender.send(request);
            } catch (Exception e) {
                            
                System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
                System.debug(LoggingLevel.ERROR, response);
                throw new IntegracaoRestException(e.getMessage());
            }
        }
        System.debug(response.getBody());
        return response;
    }
    
    private HttpRequest createRequest (
        String method, 
        String apiMethod, 
        String endpoint, 
        String body,
        Boolean compressed, 
        Map<String, String> headers
    ) {
        if (
            String.isEmpty(method) ||
            String.isEmpty(endpoint) ||
            (method!= 'GET' && String.isEmpty(body)) ||
            compressed == null
        ) {	
            throw new IntegracaoRestException('Os parâmetros informados na requisição estão com valor inválido.');
        }
        if (headers == null) {
            headers = new Map<String, String>();
        }
                
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setTimeout(120000);
        request.setEndpoint(endpoint + apiMethod);
        if(!String.isEmpty(body)) {
            request.setBody(body);
        }
        request.setCompressed(compressed);
        
        if (method == 'PATCH') {
            System.debug('Era: ' + method + ' mas serei POST');
            request.setMethod('POST');
            //request.setEndpoint(endpoint + apiMethod + '?_HttpMethod=PATCH');
            //request.setHeader('X-HTTP-Method-Override','PATCH');
           	headers.put('X-HTTP-Method-Override','PATCH');
        }
        
        for (String headerKey: headers.keySet()) {
            request.setHeader(headerKey, headers.get(headerKey));
            System.debug('keyHeader: ' + headerKey + ' value ' + headers.get(headerKey));
        }

        return request;
    }
    
    public class IntegracaoRestException extends Exception {}
}