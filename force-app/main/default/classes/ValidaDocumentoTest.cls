@isTest
private class ValidaDocumentoTest {
    
    @isTest
    static void TestCPFVazio() {
        System.assertEquals(false, ValidaDocumento.isValidCPF(''));
    }
    
    @isTest
    static void TestCPFNumeroRepetido() {
        System.assertEquals(false, ValidaDocumento.isValidCPF('00000000000'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('11111111111'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('22222222222'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('33333333333'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('44444444444'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('55555555555'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('66666666666'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('77777777777'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('88888888888'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('99999999999'));
    }
    
    @isTest
    static void TestCPFDigitoInvalido() {
        System.assertEquals(false, ValidaDocumento.isValidCPF('51620903010'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('56370065130'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('49111253430'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('4911125343a'));
        System.assertEquals(false, ValidaDocumento.isValidCPF('00000000600'));
    }
    
    @isTest
    static void TestCPFCorreto() {
        System.assertEquals(true, ValidaDocumento.isValidCPF('91582744300'));//valida os digitos com restos maiores que 9
        System.assertEquals(true, ValidaDocumento.isValidCPF('11634763238'));
        System.assertEquals(true, ValidaDocumento.isValidCPF('04949034227'));
        System.assertEquals(true, ValidaDocumento.isValidCPF('56370065129'));
    }
    
    @isTest
    static void TestCNPJVazio() {
        System.assertEquals(false, ValidaDocumento.isValidCNPJ(''));
    }
    
    @isTest
    static void TestCNPJNumeroRepetido() {
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('00000000000000'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('11111111111111'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('22222222222222'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('33333333333333'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('44444444444444'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('55555555555555'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('66666666666666'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('77777777777777'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('88888888888888'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('99999999999999'));
    }
    
    @isTest
    static void TestCNPJDigitoInvalido() {
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('36737745000186'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('17381249000198'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('05988237000145'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('55082574000149'));
        System.assertEquals(false, ValidaDocumento.isValidCNPJ('5508257400014a'));
    }
    
    @isTest
    static void TestCNPJCorreto() {
        System.assertEquals(true, ValidaDocumento.isValidCNPJ('51194000000100'));//valida os digitos com restos iguais a 0 ou 1
        System.assertEquals(true, ValidaDocumento.isValidCNPJ('36737745000185'));
        System.assertEquals(true, ValidaDocumento.isValidCNPJ('17381249000197'));
        System.assertEquals(true, ValidaDocumento.isValidCNPJ('05988237000146'));
        System.assertEquals(true, ValidaDocumento.isValidCNPJ('55082574000148'));
    }
    
    @isTest
    static void TestFormatarCPF() {
        System.assertEquals('638.932.270-40', ValidaDocumento.formatarCPF('638.932.270-40'));
        System.assertEquals('638.932.270-40', ValidaDocumento.formatarCPF('63893227040'));
    }
    
    @isTest
    static void TestFormatarCNPJ() {
        System.assertEquals('22.938.751/0001-96', ValidaDocumento.formatarCNPJ('22.938.751/0001-96'));
        System.assertEquals('22.938.751/0001-96', ValidaDocumento.formatarCNPJ('22938751000196'));
    }
    
    @isTest
    static void TestFormatarCPFWrongSize() {
        System.assertEquals('123', ValidaDocumento.formatarCPF('123'));
    }
    
    @isTest
    static void TestFormatarCNPJWrongSize() {
        System.assertEquals('123', ValidaDocumento.formatarCNPJ('123'));
    }
    
    
}