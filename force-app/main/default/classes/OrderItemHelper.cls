public with sharing class OrderItemHelper {
    public OrderItemHelper() {}

    /*
    ** Faz a verificação do Status do Pedido caso haja pedido de atualização no Item do Pedido.
    ** Possíveis falhas: Caso não haja modificação e seja salvo novamente, ele vai mandar essa mensagem.
    */
    public static List<OrderItem> checkStatus(List<OrderItem> orderItemList){
        
        List<OrderItem> updatedList = new List<OrderItem>();
        Set<Id> orderIds = new Set<Id>();

        for(OrderItem orderItem : orderItemList) {
            orderIds.add(orderItem.OrderId);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, Status
            FROM Order
            WHERE Id IN: orderIds
        ]);

        for(OrderItem orderItem : orderItemList){
            if(orderMap.get(orderItem.OrderId).Status != 'Draft')
                orderItem.addError(Label.OrderItemCannotBeChanged);
        }

        return updatedList;
    }

    public static List<Order> getChangedOrders(List<OrderItem> orderItemList){

        Set<Id> orderIds = new Set<Id>();
        for(OrderItem order : orderItemList){
            orderIds.add(order.OrderId);
        }

        List<Order> orderList = [
            SELECT AccountId, DistributionCenter__c, Freight__c, TotalFreight__c
            FROM Order
            WHERE Id IN: orderIds
        ];

        return orderList;
    }

    public static List<Order> getChangedOrders(Map<Id, OrderItem> oldMap, Map<Id, OrderItem> newMap){
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        for(OrderItem newOrder : newMap.values()){
            OrderItem oldOrder = oldMap.get(newOrder.Id);
            if( newOrder.Quantity != oldOrder.Quantity ||
                newOrder.Volume__c != oldOrder.Volume__c ||
                newOrder.Weight__c != oldOrder.Weight__c
            )
            orderItemList.add(newOrder);
        }

        return getChangedOrders(orderItemList);
    }
}
