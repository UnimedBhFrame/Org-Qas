public without sharing class RoleUtils {

    static Map<Id, Set<Id>> mapRoleUsers = new Map<Id, Set<Id>>();
   // Map<Id, Set<Id>> mapParentChild = new Map<Id, Set<Id>>();
    static Map<Id, Id> mapChildParent = new Map<Id, Id>();

    public static Map<Id, Set<Id>> getRoleUsers(Set<Id> roleIds) {
        List<UserRole> roles = [SELECT Id, Name, ParentRoleId FROM UserRole];
        List<User> users = [SELECT Id, Name, UserRoleId, UserRole.DeveloperName FROM User WHERE UserRoleId != null];

        
        for(User user : users){
            if(!mapRoleUsers.containsKey(user.UserRoleId)){
                mapRoleUsers.put(user.UserRoleId, new Set<Id>());
            }
            mapRoleUsers.get(user.UserRoleId).add(user.Id);
        }

        /*for(UserRole role : roles){
            if(!mapParentChild.containsKey(role.Id)){
                mapParentChild.put(role.Id, new Set<Id>());
            }

            if(role.ParentRoleId != null){
                if(!mapParentChild.containsKey(role.ParentRoleId)){
                    mapParentChild.put(role.ParentRoleId, new Set<Id>());
                }

                mapParentChild.get(role.ParentRoleId).add(role.Id);
            }
        }*/

        for(UserRole role : roles){
            mapChildParent.put(role.Id, role.ParentRoleId);
        }

        Map<Id, Set<Id>> mapRoleAboveUsers = new Map<Id, Set<Id>>();
        for(Id roleId : roleIds){
            mapRoleAboveUsers.put(roleId, getAboveUser(roleId, 2));
        }

        return mapRoleAboveUsers;
    }

    public static Set<Id> getAboveUser(Id roleChildId, Integer tree){
        Set<Id> userIds = new Set<Id>();
        
       /* for(Id parentId : mapParentChild.keySet()){
            if(mapParentChild.get(parentId).contains(roleChildId)){

                userIds.addAll(mapRoleUsers.get(parentId));

                userIds.addAll(getAboveUser(parentId));
            }
        }*/
        if( tree > 0){
            tree--;
            Id parentId = mapChildParent.get(roleChildId);

            if(parentId != null && mapRoleUsers.get(parentId) != null){
                userIds.addAll(mapRoleUsers.get(parentId));
                userIds.addAll(getAboveUser(parentId, tree));
            }
        }

        return userIds;
    }
}