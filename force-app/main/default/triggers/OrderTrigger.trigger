trigger OrderTrigger on Order (before update, before insert) {

    OrderTriggerHandler handler = new OrderTriggerHandler(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            handler.beforeUpdate();
        }
        when BEFORE_INSERT {
            handler.beforeInsert();
        }
        // when AFTER_UPDATE {
        //     handler.afterUpdate();
        // }
    }
}