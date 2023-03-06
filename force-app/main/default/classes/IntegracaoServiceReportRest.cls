global class IntegracaoServiceReportRest extends IntegracaoRest {

    private static IntegracaoServiceReportRest instance = null;
    
    public static IntegracaoServiceReportRest getInstance() {
        if (instance == null) {
            instance = new IntegracaoServiceReportRest();
        }
        
        return instance;
    }
    
    public RestResponse createServiceReport(String requestBody) {
        
        String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
        String url = salesforceHost + '/services/data/v41.0/actions/standard/createServiceReport';


        HttpResponse response = execute('POST', '', url, requestBody, false, RetornaHeaders());
        return new RestResponse(response, null, null, null);
    }

    public Map <String, String> RetornaHeaders() {
        Map <String, String> headers = new Map <String, String> ();
        headers.put('Content-Type', 'application/json');
        headers.put('Authorization', 'Bearer ' + UserInfo.getSessionId());
        
        System.debug('Headers ' + headers);
        return headers;
    }
}