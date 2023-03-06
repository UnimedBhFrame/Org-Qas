@isTest
private class DemoController2Test {
    @isTest
    static void testGetAppVersion() {
        DemoController2 demo = new DemoController2();
        System.assertEquals(demo.getAppVersion(), '1.0.0');
    }
}