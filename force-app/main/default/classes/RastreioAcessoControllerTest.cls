@isTest
public without sharing class RastreioAcessoControllerTest {
    
    @isTest
    public static void testarSalvarLog() {

        Lead ld = new Lead();
        ld.FirstName = 'Eduardo';
        ld.LastName = 'Teste';
        ld.Email = 'edt@teste123.com';
        ld.Phone = '(31) 99999-8888';
        insert ld;

        RastreioAcessoController.salvarLog(ld.Id);
        RastreioAcessoController.salvarLogUtility(ld.Id, 'Lead', true);
    }
}