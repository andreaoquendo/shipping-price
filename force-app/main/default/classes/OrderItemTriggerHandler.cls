public with sharing class OrderItemTriggerHandler {

    List<OrderItem> newRecords {get;set;}
    List<OrderItem> oldRecords {get;set;}
    Map<Id, OrderItem> newMap {get;set;}
    Map<Id, OrderItem> oldMap {get;set;}

    public OrderItemTriggerHandler(
        List<OrderItem> newRecords, 
        List<OrderItem> oldRecords,
        Map<Id, OrderItem> newMap,
        Map<Id, OrderItem> oldMap
    ) {
        this.newRecords = newRecords;
        this.oldRecords = oldRecords;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    public void beforeUpdate() {
        List<OrderItem> updatedList = OrderItemHelper.checkStatus(newRecords);
    }

    public void afterInsert() {
        List<Order> changedOrders = OrderItemHelper.getChangedOrders(newRecords);
        List<Order> updatedList = OrderHelper.searchFreight(changedOrders);
        if(!updatedList.isEmpty())
            update updatedList;
    }

    public void afterUpdate(){
        List<Order> changedOrders = OrderItemHelper.getChangedOrders(oldMap, newMap);
        List<Order> updatedList = OrderHelper.searchFreight(changedOrders);
        if(!updatedList.isEmpty())
            update updatedList;
    }

    public void afterDelete(){
        List<Order> changedOrders = OrderItemHelper.getChangedOrders(oldRecords);
        List<Order> updatedList = OrderHelper.searchFreight(changedOrders);
        if(!updatedList.isEmpty())
            update updatedList;
    }
    
}