public with sharing class OrderTriggerHandler {
    
    List<Order> newRecords {get;set;}
    List<Order> oldRecords {get;set;}
    Map<Id, Order> newMap {get;set;}
    Map<Id, Order> oldMap {get;set;}

    public OrderTriggerHandler(
        List<Order> newRecords, 
        List<Order> oldRecords,
        Map<Id, Order> newMap,
        Map<Id, Order> oldMap
    ) {
        this.newRecords = newRecords;
        this.oldRecords = oldRecords;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    public void beforeUpdate() {
        List<Order> updatedList = OrderHelper.checkStatus(oldMap, newMap);
        // if(!updatedList.isEmpty())
        //     update updatedList;
    }

    public void beforeInsert() {
        List<Order> updatedList = OrderHelper.searchFreight(newRecords);
    }

    // public void afterUpdate() {
    //     List<Order> updatedList = OrderHelper.searchFreight(newRecords);
    //     if(!updatedList.isEmpty())
    //         update updatedList;
    // }
}
