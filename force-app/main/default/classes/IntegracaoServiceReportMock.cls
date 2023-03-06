@isTest
global class IntegracaoServiceReportMock implements HttpCalloutMock {

    global HTTPResponse respond (HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody('');
        res.setStatusCode(200);
        return res;
    }
}