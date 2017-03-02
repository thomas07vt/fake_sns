require "forwardable"
require "faraday"

module FakeSNS
  class DeliverMessage

    extend Forwardable

    def self.call(options)
      new(options).call
    end

    attr_reader :subscription, :message, :config, :request

    def_delegators :subscription, :protocol, :endpoint, :arn

    def initialize(options)
      @subscription = options.fetch(:subscription)
      @message = options.fetch(:message)
      @request = options.fetch(:request)
      @config  = default_config.merge(options.fetch(:config, {}))
    end

    def call
      method_name = protocol.gsub("-", "_")
      if protected_methods.map(&:to_s).include?(method_name)
        send(method_name)
      else
        raise InvalidParameterValue, "Protocol #{protocol} not supported"
      end
    end

    protected

    def sqs
      # TODO Make this work with sqs url and endpoint url
      parts = endpoint.split('/')
      queue_name = parts.pop
      ep = parts.join('/')

      sqs = Aws::SQS::Client.new({
        region: region,
        endpoint: ep,
        access_key_id: config.fetch("access_key_id", 'test'),
        secret_access_key: config.fetch("secret_access_key", 'test')
      })
      queue_url = sqs.get_queue_url(queue_name: queue_name).queue_url
      sqs.send_message(queue_url: queue_url, message_body: message_contents)
    end

    def http
      http_or_https
    end

    def https
      http_or_https
    end

    def email
      pending
    end

    def email_json
      pending
    end

    def sms
      pending
    end

    def application
      pending
    end

    private

    def message_contents
      message.message_for_protocol protocol
    end

    def pending
      puts "Not sending to subscription #{arn}, because protocol #{protocol} has no fake implementation. Message: #{message.id} - #{message_contents.inspect}"
    end

    def http_or_https
      Faraday.new.post(endpoint) do |f|
        f.body = {
          "Type"             => "Notification",
          "MessageId"        => message.id,
          "TopicArn"         => message.topic_arn,
          "Subject"          => message.subject,
          "Message"          => message_contents,
          "Timestamp"        => message.received_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
          "SignatureVersion" => "1",
          "Signature"        => "Fake",
          "SigningCertURL"   => "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-f3ecfb7224c7233fe7bb5f59f96de52f.pem",
          "UnsubscribeURL"   => "", # TODO url to unsubscribe URL on this server
        }.to_json
        f.headers = {
          "x-amz-sns-message-type"     => "Notification",
          "x-amz-sns-message-id"       => message.id,
          "x-amz-sns-topic-arn"        => message.topic_arn,
          "x-amz-sns-subscription-arn" => arn,
        }
      end
    end

    def default_config
      {
        'access_key_id'     => 'test',
        'secret_access_key' => 'test',
        'region'            => 'us-west-1'
      }
    end

    def region
      @config['region']
    end

  end
end
