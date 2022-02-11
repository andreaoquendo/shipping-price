public with sharing class OrderHelper {
    public OrderHelper() {}

    /*
    ** Faz a verificação do Status do Pedido caso haja pedido de atualização.
    ** Retorna: Lista de Pedidos a serem atualizados.
    */
    public static List<Order> checkStatus(Map<Id, Order> oldMap, Map<Id, Order> newMap){
        
        List<Order> updatedList = new List<Order>();

        for(Order newOrder : newMap.values()){
            Order oldOrder = oldMap.get(newOrder.Id);

            checkClient(oldOrder, newOrder);

            if(oldOrder.Status == 'Draft' && newOrder.Status != 'Draft')
                continue;

            if(newOrder.Status != 'Draft')
                newOrder.addError(Label.OrderCannotBeChanged);
            
        }

        return updatedList;
    }

    /*
    ** Faz a verificação se o Cliente foi atualizado, e adiciona um erro caso haja.
    ** Retorno (Boolean): TRUE se o Cliente foi atualizado, FALSE se o Cliente não foi atualizado.
    */
    public static Boolean checkClient(Order oldOrder, Order newOrder){

        if(oldOrder.AccountId != newOrder.AccountId){
            newOrder.addError(Label.ClientCannotBeChanged);
            return true;
        }
        return false;
    }

    public static List<Order> searchFreight(List<Order> orderList){

        Set<Id> accountIds = new Set<Id>();
        Set<String> cepLocations = new Set<String>();
        Set<Id> cityLocations = new Set<Id>();
        Set<Id> stateLocations = new Set<Id>();

        /* Queremos agora as localidades de cada um */
        for(Order order : orderList)
            accountIds.add(order.AccountId);

        List<Account> accountList = [
            SELECT Id, CEP__c, City__c
            FROM Account
            WHERE Id IN: accountIds
        ];

        for(Account account : accountList){
            cepLocations.add(account.CEP__c);
            cityLocations.add(account.City__c);
        }

        Map<Id, City__c> stateByCity = new Map<Id, City__c>([
            SELECT Id, State__c
            FROM City__c
            WHERE Id IN: cityLocations
        ]);

        // // Pega todos os voos possíveis
        List<Freight__c> freightList = checkAvailableFreights(cepLocations, cityLocations);
        
        Map<Id, AggregateResult> totalAmountsMap = totalAmounts(orderList);

        // Lista de Freights por Centro de Distribuição
        Map<Id, List<Freight__c>> distributionCenterList = new Map<Id, List<Freight__c>>();
        // Lista de localidades dos Freights por Centro de Distribuição -> usado para retornar TEM? SIM : NÃO
        Map<Id, Set<String>> DCDictionary = new Map<Id, Set<String>>();
        // Freight alocado para cada Id - não rola kkkkk my bad af
        Map<String, Freight__c> freightsById = new Map<String, Freight__c>();

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, CEP__c, City__c
            FROM Account
            WHERE Id IN: accountIds
        ]);
       
        // Percorre todos os fretes colocando eles numa lista de centros de distribuição.
        for(Freight__c freight : freightList){

            Set<String> locations = new Set<String>();
            // procura o Id do DistributionCenter__c no distributionCenterList
            if(!distributionCenterList.containsKey(freight.DistributionCenter__c)){
                List<Freight__c> freightsByDistributionCenter = new List<Freight__c>{ freight };           
                distributionCenterList.put(freight.DistributionCenter__c, freightsByDistributionCenter);
            } else 
                distributionCenterList.get(freight.DistributionCenter__c).add(freight);
            
            if(!distributionCenterList.containsKey(freight.DistributionCenter__c)){
                List<Freight__c> freightsByDistributionCenter = new List<Freight__c>{ freight };           
                distributionCenterList.put(freight.DistributionCenter__c, freightsByDistributionCenter);
            } else 
                distributionCenterList.get(freight.DistributionCenter__c).add(freight);

            // antes usava o contains mas vou ignorar isto por enquanto
            if(freight.CEP__c != null)
                locations.add(freight.CEP__c);
            if(freight.City__c != null) {
                locations.add(String.valueOf(freight.City__c));
            } 
            if(freight.State__c != null){
                locations.add(String.valueOf(freight.State__c));
            }

            if(!DCDictionary.containsKey(freight.DistributionCenter__c))
                DCDictionary.put(freight.DistributionCenter__c, locations); 
            else
                DCDictionary.get(freight.DistributionCenter__c).addAll(locations);      
        }

        Map<Id, Freight__c> priceList = new Map<Id, Freight__c>();
        Decimal actualValue = 0.00;
        // Não faria sentido ele ter fretes diferentes para a mesma localidade, verdade?
        
        for(Order order : orderList){

            // if(totalAmountsMap.containsKey(order.Id)){
            //     order.Description = 'hey';
            // }
            actualValue = 0.00;
            Freight__c selectedFreight = null;

            for(Id distributionCenter : distributionCenterList.keySet()){
                if(DCDictionary.get(distributionCenter).contains(accountMap.get(order.AccountId).CEP__c)){
                    for(Freight__c freight : distributionCenterList.get(distributionCenter)){
                        if(freight.CEP__c == accountMap.get(order.AccountId).CEP__c){
                            selectedFreight = freight;
                            break;
                        }
                    }
                } 
                else if(DCDictionary.get(distributionCenter).contains(String.valueOf(accountMap.get(order.AccountId).City__c))){
                    for(Freight__c freight : distributionCenterList.get(distributionCenter)){
                        if(String.valueOf(freight.City__c) == accountMap.get(order.AccountId).City__c){
                            selectedFreight = freight;
                            break;
                        }
                    }
                } 
                else if(DCDictionary.get(distributionCenter).contains(String.valueOf(stateByCity.get(accountMap.get(order.AccountId).City__c).State__c))){
                    for(Freight__c freight : distributionCenterList.get(distributionCenter)){
                        if(String.valueOf(freight.State__c) == String.valueOf(stateByCity.get(accountMap.get(order.AccountId).City__c).State__c)){
                            selectedFreight = freight;
                            break;
                        }
                    }
                } 
        
                if(selectedFreight == null || totalAmountsMap.get(order.Id) == null){
                    continue;
                }
                
                Decimal freightPrice =  getFreightPrice(selectedFreight, totalAmountsMap.get(order.Id));
                if(!priceList.containsKey(order.Id) || ( priceList.containsKey(order.Id) && freightPrice < actualValue)){
                    priceList.put(order.Id, selectedFreight);
                    actualValue = freightPrice;
                } 
                // || ( priceList.containsKey(order.Id) && freightPrice < actualValue)
            }

            order.TotalFreight__c = actualValue;
            if(priceList.get(order.Id) != null) {
                order.Freight__c = priceList.get(order.Id).Id;
                order.DistributionCenter__c = priceList.get(order.Id).DistributionCenter__c;
            }


        }
        
        // System.debug(orderList);
        return orderList;
    }

    public static Decimal getFreightPrice(Freight__c selectedFreight, AggregateResult totalAmounts){

        Map<String, Decimal> amountsMap = new Map<String, Decimal>{
            'TotalQuantity' => 0,
            'TotalVolume' => 0,
            'TotalWeight' => 0
        };

        Map<String, Decimal> freightPriceMap = new Map<String, Decimal>{
            'TotalQuantity' => selectedFreight.FreightBase__c,
            'TotalVolume' => selectedFreight.FreightByVolumn__c,
            'TotalWeight' => selectedFreight.FreightByWeight__c
        };
        
        Decimal bestFreight = 0.0;
        for(String value : amountsMap.keySet()){
            Decimal freight = (Decimal) totalAmounts.get(value);
            if(freightPriceMap.get(value) != null && freight * freightPriceMap.get(value) > bestFreight){
                bestFreight = freight * freightPriceMap.get(value);
            }
        }

        return bestFreight;
    }
    
    /* 
    ** Procura os fretes que se encaixam com os pedidos tratados.
    ** Parâmetros: Lista de Pedidos
    ** Retorno: Lista com todos os fretes que se encaixam em pelo menos um dos parâmetros escolhidos
    */
    public static List<Freight__c> checkAvailableFreights(Set<String> cepLocations, Set<Id> cityLocations){

        // Encontrar todos os fretes disponíveis para as localizações dentro da lista
        // Se fosse possível, eu faria um SELECT pra cada um, mas vai ficar muitos pedidos à base.
        // Mas isso iria ter um O(N²) de complexidade, em média, uma vez que podem ter poucos ou muitos fretes disponíveis
        
        // O que a gente faz pra diminuir a quantidade de vezes que a gente percorre a lista?
        // Uma alternativa é dividir em centros de distribuição. Cada um deles contém uma lista de fretes
        // Cada frete pode ter até 3 indicadores de localidade: CEP, Cidade, Estado.
        // Procurar primeiro um elemento com que o CEP bata.

        // Se tivesse um mapa dizendo só os CEPs e Ids que tem seria muito mais fácil, já que era só dar um .contains
        
        List<City__c> statesByCity = [
            SELECT Id, State__c
            FROM City__c
            WHERE Id IN: cityLocations
        ];

        Set<Id> stateLocations = new Set<Id>();
        for(City__c city: statesByCity){
            stateLocations.add(city.State__c);
        }

        List<Freight__c> freightList = [
            SELECT Id, DistributionCenter__c, CEP__c, City__c, State__c, FreightByWeight__c, FreightByVolumn__c, FreightBase__c
            FROM Freight__c
            WHERE CEP__c IN : cepLocations 
                OR (City__c IN : cityLocations)
                OR (State__c IN : stateLocations)
        ];
        
        return freightList;
    }

    /* 
    ** Parâmetros: Recebe uma lista ordenada por prioridade de fretes e a conta associada a eles.
    ** Retorno: Map de Id do Pedido junto com os valores das suas somas.
    */
    public static Map<Id, AggregateResult> totalAmounts(List<Order> orderList){

        Set<Id> orderIds = new Set<Id>();
        Map<Id, AggregateResult> orderMap= new Map<Id, AggregateResult>();

        for(Order order : orderList)
            orderIds.add(order.Id);
        
        // tanto volume, weight e quantity são (18,0)
        List<AggregateResult> resultList = [
            SELECT OrderId, SUM(Quantity) TotalQuantity, SUM(Volume__c) TotalVolume, SUM(Weight__c) TotalWeight
            FROM OrderItem
            WHERE OrderId IN: orderIds
            GROUP BY OrderId  
        ];

        for(AggregateResult result: resultList){
            orderMap.put((Id)result.get('OrderId'), result);
        }
        
        System.debug(orderMap);
        
        return orderMap;
    }
 }
