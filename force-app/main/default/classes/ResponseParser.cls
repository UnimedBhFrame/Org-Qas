public interface ResponseParser {
    Integer GetStatusCode();
    String GetBody();
    String GetErrorMessage();
    Object GetServiceObject();
}