@isTest
public class MapGeographicLeadControllerTest {
    
    @isTest
    static void checkPermissionMapTest(){

        Test.startTest();
        Boolean hasPerm = MapGeographicLeadController.checkPermissionMap();
        Test.stopTest();
    }
    
    @isTest
    static void obtainLeadsTest(){
        
        Date hoje = System.today();
        String dataStr = String.valueOf(hoje);
        
        Test.startTest();
        List<Lead> leads = MapGeographicLeadController.obtainLeads(new List<String>(), new List<String>(), false, new List<String>(), new List<String>(), new List<String>(), dataStr, dataStr);
        Test.stopTest();
    }

    @isTest
    static void obtainLegendsTest(){
        Test.startTest();
        List<LegendaMapaGeografico__mdt> legendas = MapGeographicLeadController.obtainLegends();
        Test.stopTest();
        //tes
    }
    
    @isTest
    public static void testarFiltros() {
        
        String filtros = MapGeographicLeadController.verificarFiltrosAnteriores();
        
        List<String> lista = new List<String>();
        MapGeographicLeadController.salvarFiltros('teste', 'teste', lista, lista, false, lista, lista, lista);
    }
}