trigger OrderItemTrigger on OrderItem (before update, after insert, after update, after delete) {

    OrderItemTriggerHandler handler = new OrderItemTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            handler.beforeUpdate();
        }
        when AFTER_INSERT {
            handler.afterInsert();
        }
        when AFTER_UPDATE{
            handler.afterUpdate();
        }
        when AFTER_DELETE {
            handler.afterDelete();
        }
    }
}