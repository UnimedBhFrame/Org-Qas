public without sharing class PostChatter{

	/*public static ConnectApi.BatchResult post(Id idRegistro, List<Id> idsUsuarios, String msg, Boolean visibleForAllUsers){
		//Id subjectId = (Id) sObj.get('Id');
		// Id mentionSegmentInputId = (Id) sObj.get('OwnerId');
		Map<Id, List<Id>> mapaIdUsuario = new Map<Id, List<Id>>();
		mapaIdUsuario.put(idRegistro, idsUsuarios);

		Map<Id, String> mapMsg = new Map<Id, String>();
		mapMsg.put(idRegistro, msg);

		return (PostForUsers(mapaIdUsuario, mapMsg, visibleForAllUsers)[0]);
	}*/

	public static ConnectApi.BatchResult[] PostForUsers(Map<Id, List<Id>> mapaIdUsuario, Map<Id, String> mapMsg, Boolean visibleForAllUsers){
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        System.debug('mapaIdUsuario'+mapaIdUsuario);
        System.debug('mapMsg'+mapMsg);
		for (Id idObjeto : mapaIdUsuario.keySet()){

			ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
			ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
			ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            List<Id> usuarios = mapaIdUsuario.get(idObjeto);
            System.debug('usuarios'+usuarios);
			for (Id usuario : usuarios){
				ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
				mentionSegmentInput.id = usuario;
				messageBodyInput.messageSegments.add(mentionSegmentInput);

				ConnectApi.TextSegmentInput textsi = new ConnectApi.TextSegmentInput();
				textsi.Text = ' ';
				messageBodyInput.messageSegments.add(textsi);
            }
            
			textSegmentInput.text = '\n' + mapMsg.get(idObjeto);
			messageBodyInput.messageSegments.add(textSegmentInput);

			feedItemInput.body = messageBodyInput;
			feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
			feedItemInput.subjectId = idObjeto;
			feedItemInput.Visibility = visibleForAllUsers ? ConnectApi.FeedItemVisibilityType.ALLUSERS : ConnectApi.FeedItemVisibilityType.INTERNALUSERS;

			ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
			batchInputs.add(batchInput);
            System.debug('batchInput'+batchInput);
        }
        
		return Test.isRunningTest() ? null : ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
	}
}