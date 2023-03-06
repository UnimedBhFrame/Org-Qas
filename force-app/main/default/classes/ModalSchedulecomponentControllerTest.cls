@isTest
public without sharing class ModalSchedulecomponentControllerTest {
    
    @isTest
    public static void testaController() {

        Lead ld = new Lead();
        ld.FirstName = 'Eduardo';
        ld.LastName = 'Teste';
        ld.Email = 'edt@teste123.com';
        ld.Phone = '(31) 99999-8888';
        ld.HouveAgendamento__c = 'Sim';
        ld.NumeroVidas__c = 1;
        insert ld;

        Test.startTest();
        ModalScheduleComponentController.verificaMostrarModal(ld.Id);
        ModalScheduleComponentController.preencheCampoModal(ld.Id);
        Test.stopTest();

    }
}