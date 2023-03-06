@isTest
public class RoleUtilsTest {


    @isTest
    static void getAboveUserTest(){
        
        List<UserRole> roles = [SELECT Id, Name, ParentRoleId FROM UserRole];

        Test.startTest();
        RoleUtils.getAboveUser(roles[0].Id, 2);
        Test.stopTest();
    }
}