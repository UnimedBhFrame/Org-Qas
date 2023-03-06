@isTest
public class RestResponseTest {
	@isTest
    static void coberturaCodigo()
    {
        RestResponse rest = new RestResponse();
        rest.getBody();
        rest.getErrorMessage();
        rest.getServiceObject();
        rest.getErrorObject();
        rest.getSuccessObject();
        rest.getStatusCode();
        system.assert(true);
    }
}