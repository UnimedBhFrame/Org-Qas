trigger SurveyInvitationTrigger on SurveyInvitation (before insert) {
	new SurveyInvitationTriggerHandler().run();
}