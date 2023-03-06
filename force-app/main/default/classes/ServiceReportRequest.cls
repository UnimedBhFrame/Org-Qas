public class ServiceReportRequest {
    public List<ServiceReportRequest.Input> inputs;

	public class Input {
		public String entityId;	//0WOxx000000001E
		public List<ServiceReportRequest.Signature> signatures;
		public String templateId;	//0SLR00000004DBFOA2
    }
    
	public class Signature {
		public String data;	//Base64 code for the captured signature image
		public String contentType;	//image/png
		public String name;	//Customer Signature
		public String signatureType;	//Customer
		public String place;	//San Francisco
		public String signedBy;	//John Doe
		public String signedDate;	//Thu Jul 13 22:34:43 GMT 2017
    }
    
}