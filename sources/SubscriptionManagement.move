module pavan_addr::SubscriptionManagement {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    const E_SUBSCRIPTION_NOT_FOUND: u64 = 1;
    const E_PAYMENT_NOT_DUE: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;

    struct Subscription has store, key {
        service_provider: address,    
        subscriber: address,          
        amount: u64,                  
        cycle_duration: u64,          
        last_payment_time: u64,       
        is_active: bool,              
    }

    public fun create_subscription(
        subscriber: &signer,
        service_provider: address,
        amount: u64,
        cycle_duration: u64
    ) {
        let subscriber_addr = signer::address_of(subscriber);
        let current_time = timestamp::now_seconds();
        
        let subscription = Subscription {
            service_provider,
            subscriber: subscriber_addr,
            amount,
            cycle_duration,
            last_payment_time: current_time,
            is_active: true,
        };
        
        move_to(subscriber, subscription);
    }


    public fun process_payment(subscriber: &signer) acquires Subscription {
        let subscriber_addr = signer::address_of(subscriber);
        assert!(exists<Subscription>(subscriber_addr), E_SUBSCRIPTION_NOT_FOUND);
        
        let subscription = borrow_global_mut<Subscription>(subscriber_addr);
        let current_time = timestamp::now_seconds();
        
        
        let time_since_last_payment = current_time - subscription.last_payment_time;
        assert!(time_since_last_payment >= subscription.cycle_duration, E_PAYMENT_NOT_DUE);
        assert!(subscription.is_active, E_SUBSCRIPTION_NOT_FOUND);
        

        let payment = coin::withdraw<AptosCoin>(subscriber, subscription.amount);
        coin::deposit<AptosCoin>(subscription.service_provider, payment);
        
        subscription.last_payment_time = current_time;
    }

}
