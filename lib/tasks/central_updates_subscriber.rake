namespace :message_broker do
  desc 'Consume messages from subscription "central_cartodb_commands"'
  task cartodb_subscribers: [:environment] do |_task, _args|
    include ::LoggerHelper

    message_broker = Carto::Common::MessageBroker.instance
    subscription_name = Carto::Common::MessageBroker::Config.instance.central_commands_subscription
    subscription = message_broker.get_subscription(subscription_name)
    notifications_topic = message_broker.get_topic(:cartodb_central)
    central_user_commands = Carto::Subscribers::CentralUserCommands.new(notifications_topic)

    subscription.register_callback(:update_user,
                                   &central_user_commands.method(:update_user))

    subscription.register_callback(:create_user,
                                   &central_user_commands.method(:create_user))

    subscription.register_callback(:delete_user,
                                   &central_user_commands.method(:delete_user))

    at_exit do
      log_debug(message: 'Stopping subscriber...')
      subscription.stop!
      log_debug(message: 'Done')
    end

    subscription.start
    log_debug(message: 'Consuming messages from subscription')
    sleep
  end
end